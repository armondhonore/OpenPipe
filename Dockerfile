# Root-context build for the OpenPipe Next.js app (app/). The build context is
# the repo root; this mirrors app/Dockerfile which already uses root-relative
# COPY paths. Pinned so the pipeline does not regenerate it.
FROM mirror.gcr.io/library/node:20.9.0-bullseye AS base
# pnpm 8.x matches the repo's lockfileVersion 6.0 and supports Node 20.
# (Floating `pnpm` now resolves to v11 which requires Node >=22.13 and fails.)
RUN yarn global add pnpm@8.15.9

# DEPS
FROM base AS deps
WORKDIR /code
COPY app/prisma app/package.json /code/app/
COPY client-libs/typescript/package.json /code/client-libs/typescript/
COPY pnpm-lock.yaml pnpm-workspace.yaml /code/
RUN cd app && pnpm install --frozen-lockfile

# BUILDER
FROM base AS builder
WORKDIR /code
COPY --from=deps /code/node_modules ./node_modules
COPY --from=deps /code/app/node_modules ./app/node_modules
COPY --from=deps /code/client-libs/typescript/node_modules ./client-libs/typescript/node_modules
COPY app /code/app
COPY client-libs/typescript /code/client-libs/typescript
RUN cd app && SKIP_ENV_VALIDATION=1 pnpm build

# RUNNER
FROM base AS runner
WORKDIR /code/app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=builder /code/ /code/
EXPOSE 3000
ENV PORT=3000
# run-prod.sh runs `prisma migrate deploy` then `next start`
CMD ["/code/app/scripts/run-prod.sh"]
