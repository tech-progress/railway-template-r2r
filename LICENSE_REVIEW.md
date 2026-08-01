# License review

R2R v3.6.5 is MIT-licensed. This template adds configuration and a small startup wrapper around the official image without redistributing R2R source. The official R2R Dashboard repository and image are also MIT-licensed; pgvector is PostgreSQL-licensed, PostgreSQL is PostgreSQL-licensed, and the graph-clustering image is part of R2R's official Compose topology.

The Docker image is modified only to remove an upstream log statement that serializes the database configuration, because R2R 3.6.5 otherwise prints the PostgreSQL password. `sanitize-image.py` fails the build if the expected upstream line changes, forcing a fresh review on upgrade.

