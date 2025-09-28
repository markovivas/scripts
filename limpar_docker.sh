#!/bin/bash

echo "===> Removendo tudo do Docker..."

# Para todos os containers (parando e removendo)
docker rm -f $(docker ps -aq) 2>/dev/null

# Remove imagens, volumes, redes e cache
docker system prune -a --volumes -f

echo "===> Parando servico Docker..."
sudo systemctl stop docker
sudo systemctl stop docker.socket

echo "===> Desinstalando Docker (apt)..."
sudo apt remove --purge -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "===> Removendo arquivos residuais Docker..."
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker
sudo rm -rf /run/docker
sudo rm -rf ~/.docker

echo "===> Removendo Docker instalado via Snap (se existir)..."
sudo snap remove docker 2>/dev/null

echo "===> Limpando pacotes nao utilizados..."
sudo apt autoremove -y
sudo apt autoclean -y
sudo apt clean

echo "===> Atualizando lista de pacotes..."
sudo apt update

echo "===> Verificando pacotes orfaos com deborphan..."
sudo apt install -y deborphan
sudo deborphan | xargs sudo apt -y remove --purge
sudo apt autoremove -y

echo "===> Removendo arquivos temporarios..."
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

echo "===> Limpeza final concluida!"
