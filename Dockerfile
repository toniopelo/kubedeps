FROM alpine:3 AS builder

ENV KUBEDEPS_TAG_VERSION=v0.3.4

WORKDIR /app

# hadolint ignore=DL3018
RUN apk add --no-cache wget \
    && wget -q --no-check-certificate "https://raw.githubusercontent.com/toniopelo/kubedeps/$KUBEDEPS_TAG_VERSION/kubedeps" \
    && chmod +x kubedeps

FROM alpine:3
WORKDIR /app
COPY --from=builder /app/kubedeps /app/kubedeps
