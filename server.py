import base64
from binascii import hexlify
import os
import socket
import sys
import threading
import traceback
import time

import paramiko
from paramiko.py3compat import b, u, decodebytes
import os


class Server(paramiko.ServerInterface):
    # 'data' is the output of base64.b64encode(key)
    # (using the "user_rsa_key" files)
    data = (
        b"AAAAB3NzaC1yc2EAAAABIwAAAIEAyO4it3fHlmGZWJaGrfeHOVY7RWO3P9M7hp"
        b"fAu7jJ2d7eothvfeuoRFtJwhUmZDluRdFyhFY/hFAh76PJKGAusIqIQKlkJxMC"
        b"KDqIexkgHAfID/6mqvmnSJf0b5W8v5h2pI/stOSwTQ+pxVhwJ9ctYDhRSlF0iT"
        b"UWT10hcuO4Ks8="
    )
    good_pub_key = paramiko.RSAKey(data=decodebytes(data))

    def __init__(self):
        self.event = threading.Event()

    def check_channel_request(self, kind, chanid):
        if kind == "session":
            return paramiko.OPEN_SUCCEEDED
        return paramiko.OPEN_FAILED_ADMINISTRATIVELY_PROHIBITED

    def check_auth_password(self, username, password):
        if (username == "berdan") and (password == "foo"):
            return paramiko.AUTH_SUCCESSFUL
        return paramiko.AUTH_FAILED

    def check_auth_publickey(self, username, key):
        print("Auth attempt with key: " + u(hexlify(key.get_fingerprint())))
        #if (username == "berdan") and (key == self.good_pub_key):
        return paramiko.AUTH_SUCCESSFUL
        #return paramiko.AUTH_FAILED

    def check_auth_gssapi_with_mic(
        self, username, gss_authenticated=paramiko.AUTH_FAILED, cc_file=None
    ):
        """
        .. note::
            We are just checking in `AuthHandler` that the given user is a
            valid krb5 principal! We don't check if the krb5 principal is
            allowed to log in on the server, because there is no way to do that
            in python. So if you develop your own SSH server with paramiko for
            a certain platform like Linux, you should call ``krb5_kuserok()`` in
            your local kerberos library to make sure that the krb5_principal
            has an account on the server and is allowed to log in as a user.
        .. seealso::
            `krb5_kuserok() man page
            <http://www.unix.com/man-page/all/3/krb5_kuserok/>`_
        """
        #if gss_authenticated == paramiko.AUTH_SUCCESSFUL:
        return paramiko.AUTH_SUCCESSFUL
        #return paramiko.AUTH_FAILED

    def check_auth_gssapi_keyex(
        self, username, gss_authenticated=paramiko.AUTH_FAILED, cc_file=None
    ):
        #if gss_authenticated == paramiko.AUTH_SUCCESSFUL:
        return paramiko.AUTH_SUCCESSFUL
        #return paramiko.AUTH_FAILED

    def enable_auth_gssapi(self):
        return True

    def get_allowed_auths(self, username):
        return "gssapi-keyex,gssapi-with-mic,password,publickey"

    def check_channel_shell_request(self, channel):
        self.event.set()
        return True

    def check_channel_pty_request(
        self, channel, term, width, height, pixelwidth, pixelheight, modes
    ):
        return True

# setup logging
paramiko.util.log_to_file("demo_server.log")

host_key = paramiko.RSAKey(filename="test_rsa.key")
#host_key2 = paramiko.RSAKey(filename="test_rsa2.key")
# host_key = paramiko.DSSKey(filename='test_dss.key')

print("Read key: " + u(hexlify(host_key.get_fingerprint())))

# now connect
try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("", 2200))
except Exception as e:
    print("*** Bind failed: " + str(e))
    traceback.print_exc()
    sys.exit(1)

try:
    sock.listen(100)
    print("Listening for connection ...")
    client1, addr1 = sock.accept()
except Exception as e:
    print("*** Listen/accept failed: " + str(e))
    traceback.print_exc()
    sys.exit(1)

print("Got a connection!")

try:
    sock.listen(100)
    print("Listening for connection ...")
    client2, addr2 = sock.accept()
except Exception as e:
    print("*** Listen/accept failed: " + str(e))
    traceback.print_exc()
    sys.exit(1)

print("Got second connection!")

DoGSSAPIKeyExchange = True

t1 = paramiko.Transport(client1, gss_kex=DoGSSAPIKeyExchange)
t2 = paramiko.Transport(client2, gss_kex=DoGSSAPIKeyExchange)

t1.set_gss_host(socket.getfqdn(""))
try:
    t1.load_server_moduli()
except:
    print("(Failed to load moduli -- gex will be unsupported.)")
    raise
t1.add_server_key(host_key)
server = Server()
try:
    t1.start_server(server=server)
except paramiko.SSHException:
    print("*** SSH negotiation failed.")
    sys.exit(1)


t2.set_gss_host(socket.getfqdn(""))
try:
    t2.load_server_moduli()
except:
    print("(Failed to load moduli -- gex will be unsupported.)")
    raise
t2.add_server_key(host_key)
server = Server()
try:
    t2.start_server(server=server)
except paramiko.SSHException:
    print("*** SSH negotiation failed.")
    sys.exit(1)

chan1 = t1.accept(20)
print("between")
chan1.send("Connected!\r\n")
chan2 = t2.accept(20)
print("end")
chan2.send("Connected!\n")

#os.system("ruby game.rb")
#threadASD = threading.Thread(target=os.system, args=("ruby game.rb",))
#threadASD.start()
#_thread.start_new_thread ( function, args[, kwargs] )

#for i in range(5):
#threadASD.join()

ip = '192.168.1.8'
port = 22345
s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.bind((ip,port))
s.listen()
print('Server is listening...')

rbthr = threading.Thread(target=os.system, args=("ruby game.rb",))
rbthr.start()

rubyCode, addr = s.accept()
print("found ruby code")

while True:
    #print(rubyCode)
    print("waiting p1 string")
    user1Str = rubyCode.recv(6000).decode("utf-8").replace("\n", "\r\n")
    chan1.send(user1Str)
    #print("ara")
    print("waiting p2 string")
    user2Str = rubyCode.recv(6000).decode("utf-8").replace("\n", "\r\n")
    chan2.send(user2Str)
    print("waiting turn")
    userTurn = rubyCode.recv(1024).decode("utf-8")
    #print(type(userTurn))
    if userTurn != "true" and userTurn != "false":
        chan1.send(userTurn)
        chan2.send(userTurn)
        break

    if userTurn == "true":
        userTurn = True
    else:
        userTurn = False

    print("waiting for move")
    if userTurn:
        f = chan1.makefile("rU")
        command = f.read(1)#.strip("\r\n")
        time.sleep(1)
        rubyCode.send(command)
        print("sent")
    else:
        f = chan2.makefile("rU")
        command = f.read(1)#.strip("\r\n")
        print("2")
        print(command)
        rubyCode.send(command)

    print("got move!")

