#!/bin/bash

# Проверка, что скрипт запускается от имени root
if [ "$(id -u)" -ne "0" ]; then
  echo "Этот скрипт нужно запускать от имени root."
  exit 1
fi

# Запросить доменное имя при его отсутствии
if [ -z "$1" ]; then
  echo "Введите доменное имя (например, example.com):"
  read DOMAIN
else
  DOMAIN="$1"
fi

# Проверка, что доменное имя введено
if [ -z "$DOMAIN" ]; then
  echo "Доменное имя не введено. Выход..."
  exit 1
fi

# Параметры
ACME_DIR="/root/.acme.sh"
APACHE_CONF="/etc/apache2/sites-enabled/000-default.conf"

# 1. Обновление системы
echo "Обновление системы..."
apt-get update && apt-get upgrade -y

# 2. Добавление PPA для PHP 8.1
echo "Добавление PPA для PHP 8.1..."
add-apt-repository -y ppa:ondrej/php
apt-get update

# 3. Установка PHP 8.1 и необходимых модулей
echo "Установка PHP 8.1 и необходимых модулей..."
apt-get install -y php8.1 libapache2-mod-php8.1 php8.1-curl

# 4. Установка часового пояса
echo "Установка часового пояса..."
timedatectl set-timezone Europe/Moscow

# 5. Включение SSL в Apache
echo "Включение SSL в Apache..."
a2enmod ssl

# 6. Установка socat для Acme.sh
echo "Установка socat для Acme.sh..."
apt-get install -y socat

# 7. Установка Acme.sh для управления SSL-сертификатами
echo "Установка Acme.sh..."
curl https://get.acme.sh | sh
bash /root/.acme.sh/acme.sh --upgrade --auto-upgrade

# 8. Настройка Let's Encrypt как поставщика SSL
echo "Настройка Let's Encrypt как провайдера SSL..."
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# 9. Получение SSL-сертификата для домена
echo "Получение SSL-сертификата для домена $DOMAIN..."
/root/.acme.sh/acme.sh --issue -d $DOMAIN --apache

# 10. Настройка Apache для работы с SSL
echo "Настройка Apache для работы с SSL..."
cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
<VirtualHost *:80>
   ServerName www.${DOMAIN}
   Redirect permanent / https://www.${DOMAIN}/
</VirtualHost>

<VirtualHost *:443>
   ServerName www.${DOMAIN}
   DocumentRoot /var/www/html

   SSLEngine on
   SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
   SSLCertificateFile /root/.acme.sh/${DOMAIN}_ecc/${DOMAIN}.cer
   SSLCertificateKeyFile /root/.acme.sh/${DOMAIN}_ecc/${DOMAIN}.key
   SSLCertificateChainFile /root/.acme.sh/${DOMAIN}_ecc/fullchain.cer
   <Directory /var/www/html>
      Require all granted
   </Directory>
</VirtualHost>
EOF

# 11. Перезагрузка Apache для применения настроек
echo "Перезагрузка Apache..."
systemctl restart apache2

echo "Настройка завершена для домена $DOMAIN."

