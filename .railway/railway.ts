import {
  defineRailway,
  github,
  group,
  preserve,
  project,
  service,
  volume,
} from "railway/iac";

const SOURCE = github("tech-progress/railway-template-r2r", {
  branch: "release-v1",
  rootDirectory: "/",
});
const POSTGRES_IMAGE =
  "pgvector/pgvector:pg16@sha256:a36250871de0833b8757561c72f2477ef1ddd1101afa4e617fb552e0de514c6b";
const CLUSTERING_IMAGE =
  "ragtoriches/cluster-prod@sha256:53bcbcc114fe08906b6df6b4d3863644145b1efa240fd6643ef65986593938b6";
const DASHBOARD_IMAGE =
  "sciphiai/r2r-dashboard:1.0.3@sha256:ba9bcb43c5e7d7d4eb9fe38970f976f6a0842297f3da078cb6223d1f078741d1";

export default defineRailway(() => {
  const postgresData = volume("R2R PostgreSQL Data", { sizeMB: 5_000 });

  const postgres = service("R2R PostgreSQL", {
    source: { image: POSTGRES_IMAGE },
    start:
      "/bin/sh -ec 'exec docker-entrypoint.sh postgres -c max_connections=256'",
    volumeMounts: { "/var/lib/postgresql/data": postgresData },
    env: {
      POSTGRES_DB: "r2r",
      POSTGRES_USER: "r2r",
      POSTGRES_PASSWORD: preserve(),
      PGDATA: "/var/lib/postgresql/data/pgdata",
    },
  });

  const clustering = service("R2R Graph Clustering", {
    source: { image: CLUSTERING_IMAGE },
    healthcheck: "/health",
    healthcheckTimeout: 120,
    env: { PORT: "7276" },
  });

  const r2r = service("R2R API", {
    source: SOURCE,
    build: {
      builder: "DOCKERFILE",
      dockerfilePath: "Dockerfile",
      watchPatterns: ["/**", "!/FINDINGS.md"],
    },
    healthcheck: "/v3/health",
    healthcheckTimeout: 300,
    env: {
      PORT: "7272",
      R2R_HOST: "0.0.0.0",
      R2R_PORT: "7272",
      R2R_LOG_LEVEL: "INFO",
      R2R_PROJECT_NAME: "railway_r2r",
      R2R_SECRET_KEY: preserve(),
      R2R_ADMIN_EMAIL: preserve(),
      R2R_ADMIN_PASSWORD: preserve(),
      R2R_POSTGRES_HOST: postgres.env.RAILWAY_PRIVATE_DOMAIN,
      R2R_POSTGRES_PORT: "5432",
      R2R_POSTGRES_DBNAME: postgres.env.POSTGRES_DB,
      R2R_POSTGRES_USER: postgres.env.POSTGRES_USER,
      R2R_POSTGRES_PASSWORD: postgres.env.POSTGRES_PASSWORD,
      R2R_POSTGRES_MAX_CONNECTIONS: "64",
      R2R_POSTGRES_STATEMENT_CACHE_SIZE: "100",
      OPENAI_API_KEY: preserve(),
      OPENAI_API_BASE: preserve(),
      OPENAI_BASE_URL: preserve(),
      CLUSTERING_SERVICE_URL:
        "http://${{R2R Graph Clustering.RAILWAY_PRIVATE_DOMAIN}}:7276",
      HATCHET_CLIENT_TLS_STRATEGY: "none",
    },
  });

  const dashboard = service("R2R Dashboard", {
    source: { image: DASHBOARD_IMAGE },
    healthcheck: "/",
    healthcheckTimeout: 180,
    env: {
      PORT: "3000",
      NEXT_PUBLIC_R2R_DEPLOYMENT_URL:
        "https://${{R2R API.RAILWAY_PUBLIC_DOMAIN}}",
      NEXT_PUBLIC_R2R_DEFAULT_EMAIL: "admin@example.com",
      NEXT_PUBLIC_R2R_DEFAULT_PASSWORD: "",
      R2R_DASHBOARD_DISABLE_TELEMETRY: "true",
    },
  });

  return project("R2R RAG backend", {
    resources: [
      group("Application", [dashboard, r2r]),
      group("Data", [postgres, postgresData]),
      group("Processing", [clustering]),
    ],
  });
});
