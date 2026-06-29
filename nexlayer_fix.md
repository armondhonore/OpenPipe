# Nexlayer build/deploy fix guidance (pinned)

Do NOT regenerate the Dockerfile. The repo's published image
`openpipe/openpipe:latest` does NOT exist on Docker Hub (returns UNAUTHORIZED),
so the app MUST be built from source.

Build facts (pinned):
- Build context = repo ROOT. The Dockerfile (a root-context copy of app/Dockerfile)
  builds the Next.js app under `app/` with pnpm.
- Base image: mirror.gcr.io/library/node:20.9.0-bullseye
- The app listens on PORT=3000 (set in the Dockerfile + yaml).
- Startup runs app/scripts/run-prod.sh = `prisma migrate deploy` then `next start`.
- Runtime env validation (@t3-oss/env-nextjs) REQUIRES non-empty:
  DATABASE_URL, AUTHENTICATED_SYSTEM_KEY, GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET,
  OPENAI_API_KEY. These are set to non-empty placeholders so the server boots;
  external integrations (OpenAI/GitHub OAuth/SMTP/Azure/Stripe) are not wired.
- Postgres pod is `openpipe-postgres-service` (avoids shared-ns postgres.pod
  collision); password shared via ${POSTGRES_PASSWORD} in both pods.
