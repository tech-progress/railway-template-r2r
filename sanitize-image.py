#!/usr/bin/env python3
from pathlib import Path


path = Path("/app/core/base/providers/database.py")
source = path.read_text(encoding="utf-8")
unsafe = 'logger.info(f"Initializing DatabaseProvider with config {config}.")'
safe = 'logger.info("Initializing DatabaseProvider.")'
if source.count(unsafe) != 1:
    raise SystemExit("unexpected R2R database logging source; refusing image build")
path.write_text(source.replace(unsafe, safe), encoding="utf-8")
