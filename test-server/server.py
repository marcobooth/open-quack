#!/usr/bin/env python
"""
Very simple HTTP server in python.
Usage::
    ./dummy-web-server.py [<port>]
Send a GET request::
    curl http://localhost
Send a HEAD request::
    curl -I http://localhost
Send a POST request::
    curl -d "foo=bar&bin=baz" http://localhost

Credit: https://gist.github.com/bradmontgomery/2219997
"""
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import urllib

class Server(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        self._set_headers()
        self.wfile.write("<html><body><h1>hi!</h1></body></html>")

    def do_HEAD(self):
        self._set_headers()

    def do_POST(self):
        if self.path[:14] == '/quack/excerpt':
            print "Data post heard!"
            length = self.headers['content-length']
            print "Data length=",length
            data = self.rfile.read(int(length))
            print "Data read!"
            filename = urllib.unquote(self.path[15:]).decode('utf8') 
            print "filename:", filename, "\tlength:", length
            
            with open(filename, 'w') as f:
                f.write(data)

            self.send_response(200)
        elif self.path == '/quack/metadata':
            length = self.headers['content-length']
            print "metadata:", self.rfile.read(int(length))
            self.send_response(200)
        else:
            self.send_response(404)

def run(server_class=HTTPServer, handler_class=Server, port=4246):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print 'Starting httpd...'
    httpd.serve_forever()

if __name__ == "__main__":
    from sys import argv

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()
