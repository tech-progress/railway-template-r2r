# Deploy and Host R2R RAG backend on Railway

Deploy an authenticated R2R retrieval API and dashboard with durable pgvector storage and private graph clustering. The template pins every runtime image, generates administrator and database secrets, and keeps PostgreSQL off the public Internet.

## About Hosting R2R RAG backend

R2R is an MIT-licensed retrieval system for document ingestion, hybrid search, knowledge graphs, and retrieval-augmented generation through a REST API. This template uses R2R 3.6.5's standard single-replica configuration: files, chunks, vectors, users, and metadata live in PostgreSQL while orchestration runs in the API process.

## Why Deploy R2R RAG backend on Railway

Railway gives the dashboard and API separate managed-TLS domains while dependency traffic stays on private networking. Generated credentials, immutable image digests, a persistent database volume, health checks, and an explicit OpenAI requirement remove the hidden setup gaps found in mutable community deployments.

## Common Use Cases

- Build an authenticated internal document-search and RAG API.
- Ingest product, support, research, or policy documents into pgvector.
- Evaluate cited retrieval through the bundled dashboard and official SDKs.
- Add knowledge-graph clustering without exposing another public service.

## Dependencies for R2R RAG backend

The deployment uses R2R 3.6.5, R2R Dashboard 1.0.3, pgvector/PostgreSQL 16, R2R's graph-clustering service, and an OpenAI API key. The PostgreSQL volume defaults to 5 GB.

### Deployment Dependencies

- An OpenAI API key with access to `text-embedding-3-small` and `gpt-4.1-mini`.
- A Railway plan with enough memory for roughly 900 MB of settled service usage plus workload headroom.
