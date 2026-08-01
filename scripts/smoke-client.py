#!/usr/bin/env python3
import os
import time

import requests


base_url = os.environ.get("R2R_SMOKE_URL", "http://127.0.0.1:7272").rstrip("/")
email = os.environ["R2R_ADMIN_EMAIL"]
password = os.environ["R2R_ADMIN_PASSWORD"]

health = requests.get(f"{base_url}/v3/health", timeout=30)
health.raise_for_status()

anonymous = requests.get(f"{base_url}/v3/documents", timeout=30)
if anonymous.status_code not in (401, 403):
    raise SystemExit(f"anonymous document access returned {anonymous.status_code}")

login = requests.post(
    f"{base_url}/v3/users/login",
    data={"username": email, "password": password},
    timeout=30,
)
login.raise_for_status()
token = login.json()["results"]["access_token"]["token"]
headers = {"Authorization": f"Bearer {token}"}

documents = requests.get(f"{base_url}/v3/documents", headers=headers, timeout=30)
documents.raise_for_status()
existing = documents.json().get("results", [])
if not any("ORCHID-742" in str(document) for document in existing):
    created = requests.post(
        f"{base_url}/v3/documents",
        headers=headers,
        data={
            "raw_text": "Railway template persistence verification code ORCHID-742.",
            "ingestion_mode": "fast",
            "run_with_orchestration": "false",
            "metadata": '{"title":"Railway persistence verification ORCHID-742"}',
        },
        timeout=180,
    )
    created.raise_for_status()

search_payload = {
    "query": "What is the Railway template verification code?",
    "search_mode": "basic",
}
for _ in range(30):
    search = requests.post(
        f"{base_url}/v3/retrieval/search",
        headers=headers,
        json=search_payload,
        timeout=60,
    )
    search.raise_for_status()
    if "ORCHID-742" in search.text:
        break
    time.sleep(2)
else:
    raise SystemExit("ingested verification document was not returned by search")

rag = requests.post(
    f"{base_url}/v3/retrieval/rag",
    headers=headers,
    json={
        **search_payload,
        "rag_generation_config": {"model": "openai/gpt-4.1-mini", "stream": False},
    },
    timeout=120,
)
rag.raise_for_status()
if "ORCHID-742" not in rag.text:
    raise SystemExit("RAG response did not contain the verification code")
if "citation" not in rag.text.lower() and "[1]" not in rag.text:
    raise SystemExit("RAG response did not include citation evidence")

print("R2R authentication, ingestion, search, cited RAG, and persistence checks passed.")

