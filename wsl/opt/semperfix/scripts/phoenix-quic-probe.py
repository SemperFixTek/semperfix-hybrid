#!/usr/bin/env python3

import socket
import sys
import time

if len(sys.argv) != 3:
    print("usage: phoenix-quic-probe.py <ip> <port>")
    sys.exit(2)

host = sys.argv[1]
port = int(sys.argv[2])

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.settimeout(2)

start = time.time()

try:
    sock.sendto(b"probe", (host, port))

    data, _ = sock.recvfrom(1024)

    latency = int((time.time() - start) * 1000)

    if data.decode().strip() == "ack":
        print(f"true:{latency}")
        sys.exit(0)

    print("false:-1")
    sys.exit(1)

except Exception:
    print("false:-1")
    sys.exit(1)

finally:
    sock.close()