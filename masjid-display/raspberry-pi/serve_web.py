#!/usr/bin/env python3
"""Minimal static web server for the app's web build (Raspberry Pi version of
serve-web.ps1). Uses only the Python standard library and listens on
localhost only, so the app isn't reachable from other machines.

Usage: python3 serve_web.py [--root <folder>] [--port 8080]
"""

import argparse
import functools
import http.server
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_ROOT = os.path.normpath(os.path.join(HERE, '..', '..', 'build', 'web'))


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        '.html': 'text/html; charset=utf-8',
        '.js': 'text/javascript; charset=utf-8',
        '.mjs': 'text/javascript; charset=utf-8',
        '.json': 'application/json',
        '.wasm': 'application/wasm',
        '.otf': 'font/otf',
        '.ttf': 'font/ttf',
        '.woff': 'font/woff',
        '.woff2': 'font/woff2',
        '.env': 'text/plain; charset=utf-8',
    }

    def send_head(self):
        # App route (no file extension) that isn't a file: serve index.html so
        # the app can handle it. Real missing files still get a 404.
        path = self.translate_path(self.path)
        if not os.path.exists(path) and not os.path.splitext(path)[1]:
            self.path = '/index.html'
        return super().send_head()

    def end_headers(self):
        # Always revalidate, so an updated web build shows after a reload.
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

    def log_message(self, format, *args):
        pass  # keep the log quiet; errors still raise


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default=DEFAULT_ROOT)
    parser.add_argument('--port', type=int, default=8080)
    args = parser.parse_args()

    if not os.path.isfile(os.path.join(args.root, 'index.html')):
        sys.exit(f"No index.html in '{args.root}'. Run setup.sh to build the app.")

    handler = functools.partial(Handler, directory=args.root)
    server = http.server.ThreadingHTTPServer(('127.0.0.1', args.port), handler)
    print(f'Serving {args.root} at http://localhost:{args.port}/  (Ctrl+C to stop)')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
