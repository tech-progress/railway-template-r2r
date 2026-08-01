# R2R RAG backend on Railway

This template deploys an authenticated R2R 3.6.5 API and dashboard with private pgvector/PostgreSQL storage and R2R's graph-clustering service. All runtime images are pinned by digest, PostgreSQL has no public endpoint, and the current template release is `v1.0.3`.

[Deploy R2R RAG backend on Railway](https://railway.com/deploy/r2r-rag-backend)

## Required configuration

Set `OPENAI_API_KEY` during deployment. R2R uses it for document embeddings, ingestion summaries, retrieval, and generated RAG answers. `OPENAI_API_BASE` and `OPENAI_BASE_URL` are blank by default; set both to the same URL only when using an OpenAI-compatible provider that supports the configured OpenAI model names and 512-dimensional embeddings.

Railway generates `R2R_ADMIN_PASSWORD`, `R2R_SECRET_KEY`, and `POSTGRES_PASSWORD`. The administrator email defaults to `admin@example.com`. After deployment, open the `R2R API` service variables to copy `R2R_ADMIN_PASSWORD`, then sign in through the dashboard; the password is deliberately not placed in a `NEXT_PUBLIC_*` dashboard variable because those values are visible to browsers.

## Using the deployment

The dashboard is the primary browser interface. The separate API domain serves `/v3`, including `/v3/health`, and works with the official Python and JavaScript SDKs. Uploaded files, chunks, vectors, users, and metadata are stored in PostgreSQL and survive application redeploys.

The bundled configuration uses R2R's simple in-process orchestration, which is appropriate for one replica and small internal workloads. The graph-clustering service is available for knowledge-graph operations. MinIO and Hatchet are omitted because the official standard configuration stores files in PostgreSQL and uses simple orchestration; adding those services creates a different operational tier with separate queues, databases, and upgrade work.

## Environment variables

Every required variable is created by the template. You provide only `OPENAI_API_KEY`; the administrator and database credentials are generated. Optional provider-base variables must be changed together as described above. See `template-descriptions.json` for the complete service-by-service variable contract.

## Operations

Back up the PostgreSQL volume because it contains the complete durable R2R state for this topology. This is a single API replica with no database high availability, external object store, Hatchet workers, SMTP verification, or autoscaling. Read `UPGRADE.md` before changing any image or embedding dimension, and use `SUPPORT.md` for failure diagnosis.
