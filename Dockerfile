# syntax=docker/dockerfile:1
# One multi-stage build for the whole monorepo; two runtime targets: `worker` and `web`.

FROM node:24-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
COPY packages/rcon/package.json packages/rcon/
COPY packages/logs/package.json packages/logs/
COPY packages/core/package.json packages/core/
COPY packages/notify/package.json packages/notify/
COPY apps/worker/package.json apps/worker/
COPY apps/web/package.json apps/web/
RUN npm ci

FROM deps AS build
COPY tsconfig.base.json ./
COPY packages packages
COPY apps apps
RUN npm run build && npm prune --omit=dev

FROM node:24-alpine AS runtime-base
ENV NODE_ENV=production SQUADPANEL_ROOT=/app SQUADPANEL_DATA_DIR=/data
WORKDIR /app
COPY --from=build /app/package.json ./
COPY --from=build /app/node_modules node_modules
COPY --from=build /app/packages/rcon/package.json packages/rcon/
COPY --from=build /app/packages/rcon/dist packages/rcon/dist
COPY --from=build /app/packages/logs/package.json packages/logs/
COPY --from=build /app/packages/logs/dist packages/logs/dist
COPY --from=build /app/packages/core/package.json packages/core/
COPY --from=build /app/packages/core/dist packages/core/dist
COPY --from=build /app/packages/core/drizzle packages/core/drizzle
COPY --from=build /app/packages/notify/package.json packages/notify/
COPY --from=build /app/packages/notify/dist packages/notify/dist
RUN mkdir -p /data && chown node:node /data
USER node

FROM runtime-base AS worker
COPY --from=build /app/apps/worker/package.json apps/worker/
COPY --from=build /app/apps/worker/dist apps/worker/dist
ENV WORKER_API_HOST=0.0.0.0 WORKER_API_PORT=3101 SQUADPANEL_WEB_URL=http://web:3000
EXPOSE 3101
CMD ["node", "apps/worker/dist/src/index.js"]

FROM runtime-base AS web
COPY --from=build /app/apps/web/package.json apps/web/
COPY --from=build /app/apps/web/build apps/web/build
ENV PORT=3000 HOST=0.0.0.0 WORKER_URL=http://worker:3101
EXPOSE 3000
CMD ["node", "apps/web/build/index.js"]
