# syntax=docker/dockerfile:1.18

ARG NODE_IMAGE=docker.io/library/node:24-alpine@sha256:a0b9bf06e4e6193cf7a0f58816cc935ff8c2a908f81e6f1a95432d679c54fbfd
ARG NGINX_IMAGE=docker.io/nginxinc/nginx-unprivileged:1.29-alpine@sha256:0c79d56aee561a1d81c63f00eee5fb5fe29279560cdc55e91425133104c7fbe6
ARG BALLOON_CSS_URL=https://unpkg.com/balloon-css@1.2.0/balloon.min.css
ARG BALLOON_CSS_SHA256=537996ad925665b1d0b823840b930542e2df1938b74ae25d091246efb9c53425

FROM ${NODE_IMAGE} AS build

ARG BALLOON_CSS_SHA256
ARG BALLOON_CSS_URL

WORKDIR /source

COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

COPY . .

RUN wget -qO public/balloon.min.css "${BALLOON_CSS_URL}" \
    && echo "${BALLOON_CSS_SHA256}  public/balloon.min.css" | sha256sum -c - \
    && sed -i \
      's#https://unpkg.com/balloon-css/balloon.min.css#/balloon.min.css#' \
      index.html

ENV BASE=/

RUN npm run build

FROM ${NGINX_IMAGE}

ARG BUILD_REVISION=unknown

LABEL org.opencontainers.image.description="Self-hosted Bookbinder JS static application"
LABEL org.opencontainers.image.licenses="MPL-2.0"
LABEL org.opencontainers.image.revision="${BUILD_REVISION}"
LABEL org.opencontainers.image.source="https://github.com/LanceXuanLi/bookbinder-js"
LABEL org.opencontainers.image.title="Bookbinder JS"
LABEL org.opencontainers.image.version="1.7.0"

COPY --from=build --chown=101:101 /source/dist/ /usr/share/nginx/html/
