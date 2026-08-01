# Supporting the R2R template

Start with `/v3/health` on the API domain and the current replica state for all four services. If R2R is unhealthy, inspect PostgreSQL first; the database must finish initialization before R2R can create its schema and administrator.

An ingestion or RAG request returning a provider error usually means `OPENAI_API_KEY` is missing, invalid, or lacks access to the configured models. For an OpenAI-compatible endpoint, set `OPENAI_API_BASE` and `OPENAI_BASE_URL` to the same `/v1` base URL and confirm it supports `text-embedding-3-small` with 512 dimensions plus `gpt-4.1-mini` chat completions.

Changing `R2R_ADMIN_PASSWORD` after the database is initialized does not reset the existing administrator. Use R2R's password-management API or dashboard flow instead. Changing `POSTGRES_PASSWORD` after initialization also requires changing the PostgreSQL role itself before updating the matching variables.

This template supports one R2R API replica using simple orchestration. Hatchet, MinIO, SMTP verification, high availability, provider-specific model changes, and embedding-dimension migrations are outside the support boundary.
