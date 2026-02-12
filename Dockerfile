# OpenClaw Stack - Dockerfile
# Baseado em Debian/Node para compatibilidade maxima

FROM node:22-slim

# Instalar dependencias de sistema
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    make \
    g++ \
    python3 \
    ffmpeg \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Instalar pnpm
RUN npm install -g pnpm

WORKDIR /app

# Clonar OpenClaw (branch principal)
RUN git clone --depth 1 https://github.com/openclaw/openclaw.git .

# Instalar dependencias e build
RUN npm install
RUN npm run build

# Build da UI (dashboard)
RUN cd ui && npm install && npm run build

# Diretorio de persistencia
RUN mkdir -p /root/.openclaw/workspace

USER root

# Gateway (18789) + Dashboard UI (18793)
EXPOSE 18789 18793

CMD ["node", "dist/index.js", "gateway", "start"]
