FROM golang:1.26.5-bookworm AS builder

ARG TPROXY_REPO_URL=https://github.com/telegramdesktop/tproxy-server
ARG TPROXY_COMMIT=acc252ece3a25c29e9b83f608499a5567a33ab2a

WORKDIR /src

RUN git init -q . \
    && git remote add origin ${TPROXY_REPO_URL} \
    && git fetch --depth=1 origin ${TPROXY_COMMIT} \
    && git checkout -q FETCH_HEAD \
    && go test ./... \
    && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
       go build -trimpath -ldflags="-s -w" \
       -o /out/tproxy-server \
       ./cmd/tproxy-server


FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 \
       --home /nonexistent \
       --shell /usr/sbin/nologin \
       tproxy \
    && mkdir -p /etc/tproxy-server /srv/tproxy-site \
    && chown -R tproxy:tproxy /etc/tproxy-server /srv/tproxy-site

COPY --from=builder /out/tproxy-server /usr/local/bin/tproxy-server

RUN chmod 0755 /usr/local/bin/tproxy-server

USER tproxy

ENTRYPOINT ["/usr/local/bin/tproxy-server"]

CMD ["-config", "/etc/tproxy-server/config.json", "-profiles-file", "/etc/tproxy-server/profiles.json"]
