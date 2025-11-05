#!/bin/bash
# ==============================================
# Script de Instalação do VirtualHere USB Server
# Compatível com Ubuntu Server (x86_64 ou ARM)
# Autor: Marco
# ==============================================

echo "🔧 Atualizando pacotes..."
sudo apt update -y

echo "📦 Instalando dependências..."
sudo apt install -y nano wget

echo "📁 Criando diretório /opt..."
sudo mkdir -p /opt
cd /opt

# Detecta arquitetura automaticamente
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    FILE="vhusbdx86_64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "armv7l" ]]; then
    FILE="vhusbdarm"
else
    echo "❌ Arquitetura não suportada: $ARCH"
    exit 1
fi

echo "⬇️ Baixando VirtualHere Server ($FILE)..."
sudo wget -O /opt/$FILE https://www.virtualhere.com/sites/default/files/usbserver/$FILE

echo "🔑 Dando permissão de execução..."
sudo chmod +x /opt/$FILE

echo "⚙️ Criando serviço systemd..."
sudo bash -c "cat > /etc/systemd/system/virtualhere.service <<EOF
[Unit]
Description=VirtualHere USB Server
After=network.target

[Service]
ExecStart=/opt/$FILE
WorkingDirectory=/opt
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF"

echo "🔄 Recarregando systemd..."
sudo systemctl daemon-reload

echo "🚀 Ativando e iniciando o VirtualHere Server..."
sudo systemctl enable virtualhere
sudo systemctl start virtualhere

echo "✅ Instalação concluída!"
echo "-----------------------------------------"
echo "📡 Verifique o status com: sudo systemctl status virtualhere"
echo "📜 Logs em tempo real:      journalctl -u virtualhere -f"
echo "-----------------------------------------"
