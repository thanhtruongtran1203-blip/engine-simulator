import 'dart:async';

import 'package:flutter/material.dart';

import 'brand_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const BrandScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 6,
              color: const Color(0xFF0088D1),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(90, 8, 90, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/vnuhcm.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(width: 35),

                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            'assets/images/bk.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const Expanded(
                        child: Column(
                          children: [
                            Text(
                              'TRƯỜNG ĐẠI HỌC BÁCH KHOA THÀNH PHỐ HỒ CHÍ MINH',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Times New Roman',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'KHOA KỸ THUẬT GIAO THÔNG',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Times New Roman',
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Image.asset(
                        'assets/images/transport.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),

                  Container(
                    height: 1.2,
                    color: const Color(0xFF0088D1),
                  ),
                ],
              ),
            ),

            const Spacer(),

            const Text(
              'ĐỒ ÁN TỐT NGHIỆP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 170),
              child: Text(
                'THIẾT KẾ MÔ HÌNH SỐ TRONG CHẨN ĐOÁN HỆ\n'
                    'THỐNG ĐIỆN - ĐIỆN TỬ CHO ĐỘNG CƠ SUZUKI K15B\n'
                    'PHỤC VỤ GIẢNG DẠY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.only(left: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Giảng viên hướng dẫn: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: 'ThS. Phạm Trần Đăng Quang'),
                      ],
                    ),
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 18),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 18, color: Colors.black),
                      SizedBox(width: 12),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Sinh viên thực hiện: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'Trần Thanh Trường'),
                          ],
                        ),
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge_outlined, size: 18, color: Colors.black),
                      SizedBox(width: 12),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'ID: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '2247830'),
                          ],
                        ),
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mail_outline, size: 18, color: Colors.black),
                      SizedBox(width: 12),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Email: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: 'truong.tran1009@hcmut.edu.vn'),
                          ],
                        ),
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Thành phố Hồ Chí Minh, Tháng 06, 2026',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}