# START:alias
# in Dockerfile

# END:alias
ARG EX_VSN=1.16.0
ARG OTP_VSN=26.2.1
ARG DEB_VSN=bullseye-20231009-slim

ARG BUILDER_IMG="hexpm/elixir:${EX_VSN}-erlang-${OTP_VSN}-debian-${DEB_VSN}"

# START:alias
FROM ${BUILDER_IMG} AS builder
# END:alias

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV


# START:config
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to get re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile
# END:config


# START:release
COPY priv priv

COPY lib lib

COPY assets assets

# compile assets
RUN mix assets.deploy

# compile the release
RUN mix compile

# changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel

RUN mix release
# END:release