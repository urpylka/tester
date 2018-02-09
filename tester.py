#!/usr/bin/env python
# -*- coding: utf8 -*-

# проверка сертефиката https://www.sslshopper.com/certificate-decoder.html
# HTTPS web server https://gist.github.com/dergachev/7028596
# HTTP web server https://gist.github.com/bradmontgomery/2219997
# SSL https://habrahabr.ru/post/270273/
# https://developer.github.com/webhooks/
# https://developer.github.com/apps/building-github-apps/authentication-options-for-github-apps/
# YANDEX DISK CLIENT https://pypi.python.org/pypi/YaDiskClient

# taken from http://www.piware.de/2011/01/creating-an-https-server-in-python/
# generate server.xml with the following command:
#    openssl req -new -x509 -keyout server.pem -out server.pem -days 365 -nodes
# run as follows:
#    python simple-https-server.py
# then in your browser, visit:
#    https://localhost:4443

import BaseHTTPServer, SimpleHTTPServer
from BaseHTTPServer import BaseHTTPRequestHandler
import subprocess, logging, json, threading, datetime, requests, ssl, os, urllib, sys

dir_path = os.path.dirname(os.path.realpath(__file__))
# CERT_FILE = dir_path + "letsencrypt.pem"

from ConfigParser import SafeConfigParser
cfgParser = SafeConfigParser()
cfgParser.read(dir_path + "coex-ci.conf")

SECURE_PATH = cfgParser.get('tester','secure_path')

def test_image(var):

    class MyPopen(subprocess.Popen):
        # https://stackoverflow.com/questions/30421003/exception-handling-when-using-pythons-subprocess-popen

        def __enter__(self):
            return self

        def __exit__(self, type, value, traceback):
            if self.stdout:
                self.stdout.close()
            if self.stderr:
                self.stderr.close()
            if self.stdin:
                self.stdin.close()
            # Wait for the process to terminate, to avoid zombies.
            self.wait()

    class LogingTesterThread(threading.Thread):

        def __init__(self,var):
            threading.Thread.__init__(self)
            self.daemon = True
            # execute $IMAGE $PREFIX_PATH $DEV_ROOTFS $DEV_BOOT $EXECUTE_FILE
            self.args = dir_path + "/image-config.sh " + var
            now = datetime.datetime.now()
            logging.basicConfig(filename=dir_path + '/temp/' + now.strftime("%Y%m%d_%H.%M.%S_") + "urpylka" + '.log', level=logging.DEBUG)

        def run(self):
            # https://pythonworld.ru/moduli/modul-subprocess.html
            with MyPopen(self.args, stdout=subprocess.PIPE, shell=True) as proc:
                # http://qaru.site/questions/1658/running-shell-command-from-python-and-capturing-the-output
                for line in iter(proc.stdout.readline,''):
                # for line in proc.stdout:
                    logging.debug(line.rstrip())

    t = LogingTesterThread(var)
    t.start()

class RequestHandler(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()

    def do_GET(self):
        #content_length = int(self.headers['Content-Length'])
        #post_data = self.rfile.read(8)

        if(self.path == '/'):
            self._set_headers()
            with open(dir_path + "/index.html") as f:
                for line in f:
                    self.wfile.write(line)
        else:
            self.send_response(404)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            with open(dir_path + "/404.html") as f:
                for line in f:
                    self.wfile.write(line)

    def do_HEAD(self):
        self._set_headers()

    def do_POST(self):

        self._set_headers()
        reply = {}

        payload_length = int(self.headers.getheader('Content-Length'))
        
        if self.headers.getheader("content-type") != "text/plain":
            reply["status"] = "error"
            reply["body"] = "content-type: %s" % self.headers.getheader("content-type")
            self.wfile.write(reply)
        else:
            try:
                payload = json.loads(self.rfile.read(payload_length))
            except ValueError, e:
                reply["status"] = "error"
                reply["body"] = str(e)
                self.wfile.write(reply)
                return

            if self.path != SECURE_PATH:
                reply["status"] = "error"
                reply["body"] = "Incorrect path!"
                self.wfile.write(reply)
            else:
                # Нужна обработка ошибок на случай, если параметры не введены (нет в json)
                if payload["cmd"] == "yadisk":

                    # Получение прямых ссылок с YaDisk https://github.com/wldhx/yadisk-direct

                    #payload = {}
                    #payload['link'] = "https://yadi.sk/d/I5JSEh-E3S2BcW"
                    #print payload['link']

                    sharing_link = payload["link"]
                    API_ENDPOINT = 'https://cloud-api.yandex.net/v1/disk/public/resources/download?public_key={}'

                    pk_request = requests.get(API_ENDPOINT.format(sharing_link))
                    new_link = pk_request.json()['href']

                    reply["status"] = "Got link!"
                    reply["body"] = new_link
                    self.wfile.write(reply)
                    test_image(new_link)
                else:
                    reply["status"] = "error"
                    reply["body"] = "Unknow command: " + payload["cmd"]
                    self.wfile.write(reply)

            # http://zetblog.ru/programming/200911/python-simple-web-server/

            #self.wfile.write("{ \"status\" : \"OK!\" }")

print "Starting webserver..."
httpd = BaseHTTPServer.HTTPServer(('', 8880), RequestHandler)
# httpd.socket = ssl.wrap_socket(httpd.socket, certfile=CERT_FILE, server_side=True)
httpd.serve_forever()
