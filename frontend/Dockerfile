FROM node:20-slim as builder
RUN corepack enable
WORKDIR /build
COPY package.json pnpm-lock.yaml .
RUN pnpm install --no-optional --frozen-lockfile
COPY . .
RUN pnpm run build

FROM node:20-slim as runner
WORKDIR /app
RUN npm i --global serve
COPY --from=builder /build/build/ ./
CMD ["serve", "-l", "80"]
