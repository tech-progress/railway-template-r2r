# Publishing R2R RAG backend

The current template release is `v1.0.1`. Publish the standalone repository's `release-v1` branch and immutable `v1.0.1` tag, then apply `.railway/railway.ts` to a source project.

Generate public domains for `R2R API` on port 7272 and `R2R Dashboard` on port 3000. Supply a disposable OpenAI-compatible provider only for verification, run `scripts/smoke-client.py`, restart the API and PostgreSQL, rerun the smoke, and confirm every service has one running and zero crashed replicas.

Create or update the Railway template, restore `template-defaults.json`, `template-descriptions.json`, `template-networking.json`, and `template-volumes.json`, then audit the stored graph before and after publication.

```bash
railway templates publish TEMPLATE_ID \
  --category AI \
  --description "Authenticated R2R retrieval with pgvector and cited RAG." \
  --readme-file MARKETPLACE.md
```

After publication, deploy the stored `templateDeployV2` graph, repeat the representative workflow, record the exact project and template IDs in `FINDINGS.md`, and delete every source, mock-provider, and disposable verification project.
