# syntax=docker/dockerfile:1.7

ARG TARGETPLATFORM=linux/amd64
ARG BUILDER_IMAGE=hexpm/elixir:1.19.1-erlang-28.1.1-debian-bookworm-20251020-slim
ARG RUNNER_IMAGE=debian:bookworm-20251020-slim

FROM --platform=$TARGETPLATFORM ${BUILDER_IMAGE} AS build

ENV MIX_ENV=prod \
    LANG=en_US.UTF-8 \
    ERL_INETRC=/etc/erl_inetrc

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      curl \
      bash \
      openssl \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    printf '{inet6, false}.\n' > /etc/erl_inetrc

ENV ERL_FLAGS="+JPperf true"

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

COPY guided/mix.exs guided/mix.lock ./
COPY guided/config config

RUN mix deps.get --only ${MIX_ENV} && \
    mix deps.compile

COPY guided/priv priv
COPY guided/lib lib
COPY guided/assets assets

RUN mix assets.setup && \
    mix assets.deploy

RUN mix release

FROM --platform=$TARGETPLATFORM ${RUNNER_IMAGE} AS runtime

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libstdc++6 \
      openssl \
      libncurses5 \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    printf '{inet6, false}.\n' > /etc/erl_inetrc

WORKDIR /app

COPY --from=build /app/_build/prod/rel/guided ./guided

ENV HOME=/app \
    MIX_ENV=prod \
    PHX_SERVER=true \
    PORT=4000 \
    ERL_INETRC=/etc/erl_inetrc

EXPOSE 4000

ENTRYPOINT ["./guided/bin/guided"]
CMD ["start"]
