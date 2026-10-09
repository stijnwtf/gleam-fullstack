# syntax=docker/dockerfile:1

ARG GLEAM_VERSION=v1.19.1

# 1. Build the Lustre client into server/priv/static
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang AS client
WORKDIR /app
COPY shared shared
COPY client client
COPY server/priv server/priv
RUN cd client && gleam run -m lustre/dev build

# 2. Compile the server to a self-contained Erlang release
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang AS server
WORKDIR /app
COPY shared shared
COPY server server
COPY --from=client /app/server/priv/static server/priv/static
RUN cd server && gleam export erlang-shipment

# 3. Small runtime image, no Gleam compiler needed
FROM erlang:29-alpine
WORKDIR /app
COPY --from=server /app/server/build/erlang-shipment .
ENV PORT=8000
EXPOSE 8000
ENTRYPOINT ["./entrypoint.sh"]
CMD ["run"]
