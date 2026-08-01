# Changelog

## [1.0.1] - 2026-08-01

- Declare graph clustering's port 7276 explicitly so Railway can route its health check.

## [1.0.0] - 2026-08-01

- Add R2R 3.6.5 with an authenticated API, dashboard, private pgvector/PostgreSQL, and graph clustering.
- Pin all runtime images by digest and remove PostgreSQL credentials from R2R startup logs.
- Verify anonymous denial, administrator login, ingestion, search, cited RAG, dashboard health, and initialized-state restart.
