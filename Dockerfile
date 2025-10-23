# Install the base requirements for the app.
# This stage is to support development.
FROM --platform=$BUILDPLATFORM python:3.11-alpine AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1
WORKDIR /app
COPY requirements.txt .
# Actualiza pip/setuptools/wheel y luego instala deps
RUN pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# Base para app Node (tests/zip)
FROM --platform=$BUILDPLATFORM node:18-alpine AS app-base
WORKDIR /app
# Habilita Yarn mediante Corepack (Node 18 lo trae)
RUN corepack enable && corepack prepare yarn@1.22.22 --activate
COPY app/package.json app/yarn.lock ./
COPY app/spec ./spec
COPY app/src ./src

# Run tests to validate app
FROM app-base AS test
RUN yarn install --frozen-lockfile
RUN yarn test

# Clear out the node_modules and create the zip
FROM app-base AS app-zip-creator
# (Re)usa archivos limpios y evita incluir node_modules en el zip
COPY --from=test /app/package.json /app/yarn.lock ./
COPY app/spec ./spec
COPY app/src ./src
RUN apk add --no-cache zip && \
    zip -r /app.zip /app

# Dev-ready container - actual files will be mounted in
FROM --platform=$BUILDPLATFORM base AS dev
EXPOSE 8000
CMD ["mkdocs", "serve", "-a", "0.0.0.0:8000"]

# Do the actual build of the mkdocs site
FROM --platform=$BUILDPLATFORM base AS build
COPY . .
# --strict para fallar si hay warnings (opcional); quítalo si no lo deseas
RUN mkdocs build

# Extract the static content from the build
# and use a nginx image to serve the content
FROM --platform=$TARGETPLATFORM nginx:alpine
# Publica el zip de la app JS como asset descargable
COPY --from=app-zip-creator /app.zip /usr/share/nginx/html/assets/app.zip
# Publica el sitio estático generado por MkDocs
COPY --from=build /app/site /usr/share/nginx/html
