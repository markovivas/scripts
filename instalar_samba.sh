#!/bin/bash

# Titulo do script
echo "ATENCAO: Este script criara um compartilhamento SEM SEGURANCA"
echo "         Use apenas em redes locais confiaveis ou ambientes isolados"
echo "------------------------------------------------------------"

# Atualiza pacotes e instala o Samba
sudo apt update && sudo apt install samba -y

# Cria o diretorio se nao existir
[ ! -d "/home/markovivas" ] && sudo mkdir -p /home/markovivas

# Backup do arquivo de configuracao
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Configura permissoes totalmente abertas
sudo chmod -R 777 /home/markovivas
sudo chown -R nobody:nogroup /home/markovivas

# Adiciona a configuracao aberta ao Samba
sudo tee -a /etc/samba/smb.conf > /dev/null <<EOL

[markovivas]
   path = /home/markovivas
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777
   # Configuracoes adicionais para maxima abertura:
   map to guest = bad user
   public = yes
   writable = yes
   guest only = yes
EOL

# Reinicia os servicos do Samba
sudo systemctl restart smbd nmbd
sudo systemctl enable smbd nmbd

# Configura o firewall para permitir Samba (se estiver ativo)
sudo ufw allow samba 2>/dev/null

# Resultado final
echo ""
echo "COMPARTILHAMENTO ABERTO CRIADO COM SUCESSO"
echo "---------------------------------------------"
echo "Pasta compartilhada: /home/markovivas"
echo "Permissoes: TOTALMENTE ABERTAS (0777)"
echo "Acesso: QUALQUER USUARIO NA REDE (guest)"
echo "Acesse de outros dispositivos usando:"
echo ""
echo "Windows: \\\\$(hostname -I | awk '{print $1}')\\markovivas"
echo "Linux: smb://$(hostname -I | awk '{print $1}')/markovivas"
echo ""
echo "AVISO: Qualquer pessoa na rede pode:"
echo "- Ler todos os arquivos"
echo "- Modificar/deletar qualquer arquivo"
echo "- Adicionar novos arquivos"
echo ""
echo "Recomendado apenas para:"
echo "- Redes 100% locais e confiaveis"
echo "- Ambientes de teste temporarios"
echo "- Compartilhamento de dados nao sensiveis"
