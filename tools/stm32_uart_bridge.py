import argparse
import socket
import time


def serve_fake(host: str, port: int) -> None:
    print(f"Fake bridge listening on {host}:{port}")
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((host, port))
    server.listen(1)

    while True:
        client, address = server.accept()
        print(f"Emulator connected from {address}")
        angle = 0
        rpm = 1200
        firing = [1, 3, 4, 2]
        inject = [4, 2, 1, 3]
        index = 0

        try:
            while True:
                frame = f"<{rpm},{angle},{firing[index]},{inject[index]}>\n"
                client.sendall(frame.encode("ascii"))
                angle = (angle + 6) % 720
                index = (index + 1) % len(firing)
                time.sleep(0.08)
        except OSError:
            print("Emulator disconnected")
        finally:
            client.close()


def serve_serial(host: str, port: int, com_port: str, baudrate: int) -> None:
    try:
        import serial
    except ImportError as exc:
        raise SystemExit(
            "Missing pyserial. Install it with: python -m pip install pyserial"
        ) from exc

    print(f"Opening {com_port} at {baudrate} baud")
    ser = serial.Serial(com_port, baudrate, timeout=0.1)

    print(f"UART bridge listening on {host}:{port}")
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((host, port))
    server.listen(1)

    while True:
        client, address = server.accept()
        print(f"Emulator connected from {address}")

        try:
            while True:
                data = ser.read(256)
                if data:
                    client.sendall(data)
        except OSError:
            print("Emulator disconnected")
        finally:
            client.close()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=5000)
    parser.add_argument("--com", help="Windows COM port, for example COM3")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--fake", action="store_true")
    args = parser.parse_args()

    if args.fake:
      serve_fake(args.host, args.port)
    else:
      if not args.com:
          raise SystemExit("Pass --com COMx, for example: --com COM3")
      serve_serial(args.host, args.port, args.com, args.baud)


if __name__ == "__main__":
    main()
