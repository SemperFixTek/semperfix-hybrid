import socket

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

s.settimeout(2)

s.sendto(b"probe", ("10.10.10.130", 22001))

data, addr = s.recvfrom(1024)

print(data.decode())

s.close()