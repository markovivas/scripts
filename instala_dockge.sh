#!/bin/bash

# Script de configuracao do Dockge (sem instalar Docker)
echo "?? Configurando Dockge..."

# Verificar e corrigir permissoes de montagem
echo "?? Verificando sistema de arquivos..."
if mount | grep -q "/opt.*ro"; then
    echo "??  /opt esta como read-only, corrigindo..."
    sudo mount -o remount,rw /opt 2>/dev/null || sudo mount -o remount,rw /
fi

# Verificar se Docker esta instalado
if ! command -v docker &> /dev/null; then
    echo "? Docker nao encontrado!"
    echo "?? Instale o Docker primeiro:"
    echo "    curl -fsSL https://get.docker.com | sh"
    echo "    sudo usermod -aG docker markovivas"
    echo "    newgrp docker"
    exit 1
fi

# Verificar se Docker daemon esta rodando
if ! docker info &> /dev/null; then
    echo "? Docker daemon nao esta rodando!"
    echo "?? Inicie o Docker service:"
    echo "    sudo systemctl start docker"
    echo "    sudo systemctl enable docker"
    exit 1
fi

echo "? Docker esta instalado e funcionando"

# Configurar estrutura de pastas do Dockge
echo "?? Configurando estrutura do Dockge..."
DOCKGE_DIR="/home/markovivas/dockge"

mkdir -p "$DOCKGE_DIR/data"
mkdir -p "$DOCKGE_DIR/stacks"

chmod -R 755 "$DOCKGE_DIR"
chmod -R 777 "$DOCKGE_DIR/data"
chmod -R 777 "$DOCKGE_DIR/stacks"

echo "? Estrutura criada em: $DOCKGE_DIR"

# Criar e executar compose do Dockge
echo "?? Iniciando Dockge..."
cat > "$DOCKGE_DIR/docker-compose.yaml" << EOF
version: "3.8"

services:
  dockge:
    image: louislam/dockge:latest
    container_name: dockge
    restart: unless-stopped
    ports:
      - "5001:5001"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /home/markovivas/dockge/data:/app/data
      - /home/markovivas/dockge/stacks:/app/stacks
    environment:
      - DOCKGE_STACKS_DIR=/app/stacks
EOF

# Iniciar Dockge
cd "$DOCKGE_DIR"
docker compose up -d

echo "? Configuracao concluida!"
echo "?? Dockge disponivel em: http://localhost:5001"
echo "?? Stacks location: $DOCKGE_DIR/stacks"
echo "?? Para parar: cd $DOCKGE_DIR && docker compose down"