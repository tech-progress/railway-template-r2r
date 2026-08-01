#!/usr/bin/env python3
import json
import os
from pathlib import Path


def required(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        raise SystemExit(f"{name} is required")
    return value


template = Path("/app/r2r.toml.template").read_text(encoding="utf-8")
replacements = {
    "__R2R_ADMIN_EMAIL__": required("R2R_ADMIN_EMAIL"),
    "__R2R_ADMIN_PASSWORD__": required("R2R_ADMIN_PASSWORD"),
    "__R2R_POSTGRES_USER__": required("R2R_POSTGRES_USER"),
    "__R2R_POSTGRES_PASSWORD__": required("R2R_POSTGRES_PASSWORD"),
    "__R2R_POSTGRES_HOST__": required("R2R_POSTGRES_HOST"),
    "__R2R_POSTGRES_DBNAME__": required("R2R_POSTGRES_DBNAME"),
    "__R2R_PROJECT_NAME__": required("R2R_PROJECT_NAME"),
}
for marker, value in replacements.items():
    template = template.replace(marker, json.dumps(value))

Path(os.environ.get("R2R_CONFIG_PATH", "/tmp/r2r.toml")).write_text(
    template, encoding="utf-8"
)

# R2R 3.6.5 logs this environment variable verbatim during import. The
# generated config already contains the credential, so remove the variable
# before starting Uvicorn to keep it out of deployment logs.
os.environ.pop("R2R_POSTGRES_PASSWORD", None)

os.execvp(
    "uvicorn",
    [
        "uvicorn",
        "core.main.app_entry:app",
        "--host",
        os.environ.get("R2R_HOST", "0.0.0.0"),
        "--port",
        os.environ.get("R2R_PORT", "7272"),
    ],
)
