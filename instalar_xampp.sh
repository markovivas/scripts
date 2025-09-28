#!/bin/bash

set -e

# Variaveis
APACHE_PORT=9080
PHPMYADMIN_PORT=9081
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WWW_DIR="/var/www/html"
MYSQL_ROOT_PASSWORD="00100"

# Atualiza repositorios e instala pacotes basicos
echo "Atualizando repositorios..."
sudo apt update

echo "Instalando Apache, MySQL, PHP 7.4 e extensoes necessarias..."
sudo apt install -y apache2 mysql-server php php-mysqli php-intl php-mbstring php-imap php-cli php-common php-zip php-curl php-xml php-gd php-mysql unzip wget

# Verificar versao do PHP
PHP_VERSION=$(php -r "echo PHP_VERSION;")
REQUIRED_PHP_VERSION="7.3"

version_gte() {
  [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

if ! version_gte "$PHP_VERSION" "$REQUIRED_PHP_VERSION"; then
  echo "PHP versao $REQUIRED_PHP_VERSION ou superior e requerida. Sua versao: $PHP_VERSION"
  exit 1
fi

# Cria a pasta www no diretorio padrao do Apache
echo "Criando diretorio www em $WWW_DIR..."
sudo mkdir -p "$WWW_DIR"

# Ajusta permissoes
echo "Ajustando permissoes da pasta www para www-data..."
sudo chown -R www-data:www-data "$WWW_DIR"
sudo chmod -R 755 "$WWW_DIR"
sudo chmod +x $(dirname "$WWW_DIR")

# Configurar Apache
echo "Configurando Apache na porta $APACHE_PORT com DocumentRoot em $WWW_DIR..."

# Desabilitar o site padrao
sudo a2dissite 000-default.conf || true

# Cria configuracao customizada
CUSTOM_APACHE_CONF="/etc/apache2/sites-available/custom-web.conf"

sudo tee "$CUSTOM_APACHE_CONF" > /dev/null <<EOL
<VirtualHost *:$APACHE_PORT>
    ServerAdmin webmaster@localhost
    DocumentRoot $WWW_DIR

    <Directory $WWW_DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Habilita mod_rewrite
sudo a2enmod rewrite

# Configura porta e habilita o site
echo "Listen $APACHE_PORT" | sudo tee /etc/apache2/ports.conf > /dev/null
sudo a2ensite custom-web.conf

# Reinicia Apache
sudo systemctl restart apache2

# Configuracao do MySQL com suporte a versoes modernas
echo "Configurando senha root do MySQL..."

# Verifica a versao do MySQL
MYSQL_VERSION=$(mysql --version | awk '{print $3}' | awk -F. '{print $1}')

if [[ "$MYSQL_VERSION" -ge 8 ]]; then
  echo "MySQL 8.0+ detectado. Usando caching_sha2_password..."
  sudo mysql <<EOSQL
  ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$MYSQL_ROOT_PASSWORD';
  FLUSH PRIVILEGES;
EOSQL
else
  echo "MySQL anterior a 8.0 detectado. Usando mysql_native_password..."
  sudo mysql <<EOSQL
  ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';
  FLUSH PRIVILEGES;
EOSQL
fi

# Instalacao do phpMyAdmin
echo "Instalando phpMyAdmin..."

PHPMYADMIN_VERSION="5.2.0"
PHPMYADMIN_URL="https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VERSION/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip"
PHPMYADMIN_DIR="/usr/share/phpmyadmin"

# Remove instalacao antiga, se existir
sudo rm -rf $PHPMYADMIN_DIR

# Baixa e descompacta
wget -q $PHPMYADMIN_URL -O /tmp/phpmyadmin.zip
sudo unzip -q /tmp/phpmyadmin.zip -d /usr/share/
sudo mv /usr/share/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages $PHPMYADMIN_DIR
rm /tmp/phpmyadmin.zip

# Ajusta permissoes
sudo chown -R www-data:www-data $PHPMYADMIN_DIR
sudo chmod -R 755 $PHPMYADMIN_DIR

# Cria configuracao minima
sudo tee $PHPMYADMIN_DIR/config.inc.php > /dev/null <<EOL
<?php
/* phpMyAdmin sample config */
\$cfg['blowfish_secret'] = '$(openssl rand -base64 32)';
\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['host'] = 'localhost';
\$cfg['Servers'][\$i]['connect_type'] = 'tcp';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
EOL

# Configura Apache para phpMyAdmin
echo "Configurando Apache para phpMyAdmin na porta $PHPMYADMIN_PORT..."

PHPMYADMIN_CONF="/etc/apache2/sites-available/phpmyadmin.conf"

sudo tee "$PHPMYADMIN_CONF" > /dev/null <<EOL
Listen $PHPMYADMIN_PORT

<VirtualHost *:$PHPMYADMIN_PORT>
    ServerAdmin webmaster@localhost
    DocumentRoot $PHPMYADMIN_DIR

    <Directory $PHPMYADMIN_DIR>
        Options Indexes FollowSymLinks
        DirectoryIndex index.php
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/phpmyadmin-error.log
    CustomLog \${APACHE_LOG_DIR}/phpmyadmin-access.log combined
</VirtualHost>
EOL

sudo a2ensite phpmyadmin.conf
sudo systemctl restart apache2

# Cria arquivo index.html padrao
echo "Criando arquivo index.html padrao..."
sudo tee "$WWW_DIR/index.html" > /dev/null <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>Servidor Configurado</title>
</head>
<body>
    <h1>Servidor configurado com sucesso!</h1>
    <p>Acesse o phpMyAdmin em: <a href="http://localhost:$PHPMYADMIN_PORT/">http://localhost:$PHPMYADMIN_PORT/</a></p>
</body>
</html>
EOL

# Mensagem final
echo "Instalacao concluida!"
echo "Acesse seu servidor web em: http://localhost:$APACHE_PORT/"
echo "Acesse phpMyAdmin em: http://localhost:$PHPMYADMIN_PORT/"
echo "Usuario root MySQL com senha: $MYSQL_ROOT_PASSWORD"
echo "Pasta www esta em: $WWW_DIR"
