# License review

R2R v3.6.5 is MIT-licensed. This template adds configuration and a small startup wrapper around the official image without redistributing R2R source. The official R2R Dashboard repository is MIT-licensed, while pgvector and PostgreSQL use the PostgreSQL license. Railway pulls the graph-clustering image directly from the image named in R2R's official Compose topology; this repository does not redistribute that image.

The Docker image is modified only to remove an upstream log statement that serializes the database configuration, because R2R 3.6.5 otherwise prints the PostgreSQL password. `sanitize-image.py` fails the build if the expected upstream line changes, forcing a fresh review on upgrade.
