#!/bin/bash

# Проверка, что скрипт запускается от имени root
if [ "$(id -u)" -ne "0" ]; then
  echo "Этот скрипт нужно запускать от имени root."
  exit 1
fi

# Запросить у пользователя доменное имя
echo "Введите доменное имя (например, example.com):"
read DOMAIN

# Проверка, что доменное имя введено
if [ -z "$DOMAIN" ]; then
  echo "Доменное имя не введено. Выход..."
  exit 1
fi

# Параметры
ACME_DIR="/root/.acme.sh"
APACHE_CONF="/etc/apache2/sites-enabled/000-default.conf"
ANYCONNECT_SCRIPT="/home/anyconnect-linux64-4.7.04056-core-vpn-webdeploy-k9.sh"

# Подтверждение перед удалением
echo "Вы уверены, что хотите удалить все данные для домена $DOMAIN? (y/n)"
read CONFIRMATION

if [ "$CONFIRMATION" != "y" ]; then
  echo "Отмена удаления."
  exit 0
fi

# 1. Удаление SSL-сертификатов и настроек для указанного домена
echo "Удаление сертификатов для домена $DOMAIN..."
rm -rf "$ACME_DIR/$DOMAIN"_ecc

# Удаление конфигурации Apache для SSL
echo "Удаление конфигурации Apache для SSL..."
if [ -f "$APACHE_CONF" ]; then
  sed -i "/$DOMAIN/d" "$APACHE_CONF"  # Удаление строк, содержащих домен
fi

# 2. Удаление и отключение модуля SSL в Apache
echo "Отключение и удаление модуля SSL в Apache..."
a2dismod ssl
apt-get remove --purge -y apache2-mod-ssl

# 3. Удаление Acme.sh и связанных файлов
echo "Удаление Acme.sh..."
rm -rf "$ACME_DIR"

# 4. Удаление установленных пакетов (PHP, socat и другие)
echo "Удаление установленных пакетов..."
apt-get remove --purge -y php8.1 libapache2-mod-php8.1 php8.1-curl socat

# 5. Удаление AnyConnect VPN
echo "Удаление AnyConnect VPN..."
rm -f "$ANYCONNECT_SCRIPT"

# 6. Удаление PPA для PHP 8.1
echo "Удаление PPA для PHP..."
add-apt-repository --remove -y ppa:ondrej/php

# 7. Восстановление первоначальной конфигурации Apache (если нужна стандартная конфигурация)
echo "Восстановление стандартной конфигурации Apache..."
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-enabled/000-default.conf

# 8. Перезагрузка Apache для применения всех изменений
echo "Перезагрузка Apache..."
systemctl restart apache2

echo "Все изменения удалены, сервер восстановлен к исходному состоянию."

