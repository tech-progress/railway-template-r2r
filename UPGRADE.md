# Upgrading the R2R template

Treat R2R, Dashboard, graph clustering, configuration, and database schema as one tested release. The current template release is `v1.0.1`, and R2R is pinned to `3.6.5` by manifest digest.

Before an upgrade, snapshot the PostgreSQL volume and export any irreplaceable documents. Resolve every new image tag to its multi-architecture digest, compare upstream configuration and migrations, and verify that `sanitize-image.py` still targets the credential-bearing log statement or is no longer needed.

Run a clean boot, authenticated upload, search, cited RAG response, dashboard check, and initialized-state restart. Do not change the embedding model or its 512-dimensional vector size in place unless the upstream migration path explicitly covers existing vectors; a mismatched dimension makes stored embeddings unusable.
