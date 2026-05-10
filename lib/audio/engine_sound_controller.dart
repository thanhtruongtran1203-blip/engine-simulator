import 'dart:async';
import 'package:just_audio/just_audio.dart';

class EngineSoundController {
  final AudioPlayer _startPlayer = AudioPlayer();
  final AudioPlayer _idlePlayer  = AudioPlayer();

  bool isRunning = false;
  bool _isMisfiringLight = false;   // injector
  bool _isMisfiringStrong = false;  // coil
  StreamSubscription? _startSub;

  Future<void> init() async {
    await _startPlayer.setAsset('assets/sounds/sound_engine_start.mp3');
    await _idlePlayer.setAsset('assets/sounds/sound_engine_idle.mp3');

    await _idlePlayer.setLoopMode(LoopMode.one);
    await _startPlayer.setVolume(0.5); // 🔻 giảm start
    await _idlePlayer.setVolume(1.0);  // 🔺 tăng idle

    await _idlePlayer.load(); // preload
  }

  // 🚀 START
  Future<void> start() async {
    isRunning = true;

    await _startPlayer.seek(Duration.zero);
    await _startPlayer.play();

    _startSub?.cancel();
    _startSub = _startPlayer.playerStateStream.listen((state) async {
      if (!isRunning) return;

      if (state.processingState == ProcessingState.completed) {
        await _startIdleSmooth();
      }
    });
  }

  // 🔁 IDLE (fade mượt)
  Future<void> _startIdleSmooth() async {
    await _idlePlayer.setVolume(0);
    await _idlePlayer.seek(Duration.zero);
    await _idlePlayer.play();

    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 15));

      double v = i / 10;

      _idlePlayer.setVolume(v * 1.2);   // 🔺 idle to hơn
      _startPlayer.setVolume(1.0 - v);  // 🔻 start giảm dần
    }
    await _startPlayer.stop(); // 🔥 tắt hẳn start
  }

  // 🛑 STOP (fade out rồi tắt)
  Future<void> stop() async {
    isRunning = false;

    _startSub?.cancel();

    // 🔥 fade out cho mượt
    for (int i = 10; i >= 0; i--) {
      await Future.delayed(const Duration(milliseconds: 20));
      _idlePlayer.setVolume(i / 10);
    }

    await _idlePlayer.stop();
    await _startPlayer.stop();
  }

  // ⚡ RPM
  void updateRPM(double rpm) {
    if (!isRunning) return;

    double rate = (rpm / 1000).clamp(0.8, 2.0);
    _idlePlayer.setSpeed(rate);

    double volume = (rpm / 3000).clamp(0.6, 1.2);
    _idlePlayer.setVolume(volume);
  }

  Future<void> misfireEffect() async {
    if (!isRunning || _isMisfiringLight) return;

    _isMisfiringLight = true;

    final v = _idlePlayer.volume;
    final s = _idlePlayer.speed;

    _idlePlayer.setVolume(v * 0.1);   // 🔥 tăng độ hụt
    _idlePlayer.setSpeed(s * 0.55);

    await Future.delayed(const Duration(milliseconds: 90));

    _idlePlayer.setSpeed(s);
    _idlePlayer.setVolume(v);

    _isMisfiringLight = false;
  }

  Future<void> misfireStrong() async {
    if (!isRunning || _isMisfiringStrong) return;

    _isMisfiringStrong = true;

    final v = _idlePlayer.volume;
    final s = _idlePlayer.speed;

    _idlePlayer.setVolume(v * 0.05);
    _idlePlayer.setSpeed(s * 0.4);

    await Future.delayed(const Duration(milliseconds: 90));

    _idlePlayer.setSpeed(s * 1.3);
    _idlePlayer.setVolume(v);

    await Future.delayed(const Duration(milliseconds: 40));

    _idlePlayer.setSpeed(s);

    _isMisfiringStrong = false;
  }

  void dispose() {
    _startSub?.cancel();
    _startPlayer.dispose();
    _idlePlayer.dispose();
  }
}