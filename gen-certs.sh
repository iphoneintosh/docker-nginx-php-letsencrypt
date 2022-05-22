#!/bin/bash

################################################################################

# TODO: insert your domains for which you want to generate a certificate
domains=() # i.e.: domains = (one.domain two.domain three.domain)

# TODO: insert your email address to get notified of certificate expiration
email="" # i.e.: email = "alice@example.com"

################################################################################

# config

rsa_key_size=4096
data_path="./certbot"
staging=0

# check for requirements

if ! [ -x "$(command -v docker)" ]; then
  echo "Error: docker is not installed." >&2
  exit 1
fi

if ! [ -x "$(command -v docker-compose)" ]; then
  echo "Error: docker-compose is not installed." >&2
  exit 1
fi

# check for existing certificates

if [ -d "$data_path" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (Y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

# check nginx ssl config

if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
  echo "Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
fi

# create dummy certificates for nginx

for domain in "${domains[@]}"; do
  echo "Creating dummy certificate for $domain ..."
  path="/etc/letsencrypt/live/$domain"
  mkdir -p "$data_path/conf/live/$domain"
  docker-compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
      -keyout '$path/privkey.pem' \
      -out '$path/fullchain.pem' \
      -subj '/CN=localhost'" certbot
done

# start php

docker-compose up -d php

# start nginx with dummy certificates

echo "Starting nginx ..."
docker-compose up --force-recreate -d nginx

# delete dummy certificates

for domain in "${domains[@]}"; do
  echo "Deleting dummy certificate for $domain ..."
  docker-compose run --rm --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$domain && \
    rm -Rf /etc/letsencrypt/archive/$domain && \
    rm -Rf /etc/letsencrypt/renewal/$domain.conf" certbot
done

# select email

case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# enable staging mode if needed

if [ $staging != "0" ]; then staging_arg="--staging"; fi

# request real certificates from lets encrypt

for domain in "${domains[@]}"; do
  echo "Requesting Let's Encrypt certificate for $domain ..."
  docker-compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
      $staging_arg \
      $email_arg \
      -d $domain \
      --rsa-key-size $rsa_key_size \
      --agree-tos \
      --force-renewal" certbot
done

# reload nginx with real certificates

echo "Reloading nginx ..."
docker-compose exec nginx nginx -s reload
