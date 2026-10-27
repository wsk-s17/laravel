FROM node:24-alpine AS assets

WORKDIR /app

COPY .npmrc .
COPY package*.json .

RUN npm ci

COPY vite.config.js .
COPY resources ./resources

RUN npm run build

FROM webdevops/php-nginx-dev:8.4

ENV WEB_DOCUMENT_ROOT="/app/public"

WORKDIR /app

COPY --chown=application:application ./ ./
COPY --from=assets --chown=application:application /app/public/build ./public/build

RUN composer install
