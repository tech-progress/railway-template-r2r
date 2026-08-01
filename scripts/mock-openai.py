#!/usr/bin/env python3
import json
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def send_json(self, status, body):
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        if self.path == "/health":
            self.send_json(200, {"status": "ok"})
        elif self.path.endswith("/models"):
            self.send_json(200, {"object": "list", "data": []})
        else:
            self.send_json(404, {"error": "not found"})

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        request = json.loads(self.rfile.read(length) or b"{}")
        now = int(time.time())
        if self.path.endswith("/embeddings"):
            inputs = request.get("input", [])
            if isinstance(inputs, str):
                inputs = [inputs]
            dimensions = int(request.get("dimensions") or 512)
            data = []
            for index, _ in enumerate(inputs):
                vector = [0.0] * dimensions
                vector[index % dimensions] = 1.0
                data.append({"object": "embedding", "index": index, "embedding": vector})
            self.send_json(
                200,
                {
                    "object": "list",
                    "data": data,
                    "model": request.get("model", "text-embedding-3-small"),
                    "usage": {"prompt_tokens": len(inputs), "total_tokens": len(inputs)},
                },
            )
            return
        if self.path.endswith("/chat/completions"):
            answer = "The verification code is ORCHID-742 [1]."
            self.send_json(
                200,
                {
                    "id": "chatcmpl-r2r-template-test",
                    "object": "chat.completion",
                    "created": now,
                    "model": request.get("model", "gpt-4.1-mini"),
                    "choices": [
                        {
                            "index": 0,
                            "message": {"role": "assistant", "content": answer},
                            "finish_reason": "stop",
                        }
                    ],
                    "usage": {"prompt_tokens": 10, "completion_tokens": 8, "total_tokens": 18},
                },
            )
            return
        self.send_json(404, {"error": "not found"})


ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
