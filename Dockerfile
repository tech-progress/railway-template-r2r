FROM sciphiai/r2r:3.6.5@sha256:e7caf41aba36db5561a2579eeb3e4763c907ae4d4b241712a33e783fa381aa8a

COPY sanitize-image.py /tmp/sanitize-image.py
RUN python /tmp/sanitize-image.py && rm /tmp/sanitize-image.py

COPY --chmod=0555 entrypoint.py /app/railway-entrypoint.py
COPY --chmod=0555 scripts/smoke-client.py /app/railway-smoke-client.py
COPY r2r.toml.template /app/r2r.toml.template

ENV R2R_CONFIG_PATH=/tmp/r2r.toml
EXPOSE 7272

CMD ["python", "/app/railway-entrypoint.py"]
