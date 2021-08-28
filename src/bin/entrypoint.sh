#!/usr/bin/env bash

set -e

# Setting Colors
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' #No Color
NOW=$(date "+%Y-%m-%d_%H-%M-%S")


if [ "${IAC_MODE}" == "standalone" ]; then

   # Init certbot cache
   echo -e "${BLUE}Init certbot cache...${NC}"
   mkdir -p /etc/letsencrypt

   # Azure ini
   echo -e "${BLUE}Setting azure ini...${NC}"
   (umask 077; echo ${AZURE_CONF} | base64 -d > azure.ini)
   chmod 600 azure.ini

   # Renew existing cert or build
   echo -e "${BLUE}Building certs...${NC}"
   certbot renew -n --agree-tos --dns-ovh --dns-ovh-credentials ovh.ini --dns-ovh-propagation-seconds 60 --cert-name ${IAC_CERTBOT_DOMAIN} -m ${IAC_CERTBOT_EMAIL} || certbot certonly -n --agree-tos --dns-ovh --dns-ovh-credentials ovh.ini --dns-ovh-propagation-seconds 60 -d ${IAC_CERTBOT_DOMAIN} -d *.${IAC_CERTBOT_DOMAIN} -m ${IAC_CERTBOT_EMAIL}

else

  # Init certbot cache
  echo -e "${BLUE}Init certbot cache...${NC}"
  mkdir -p /etc/letsencrypt
  aws s3 sync s3://${IAC_CERTBOT_CACHE} /etc/letsencrypt

  # Cleanup symblinks
  echo -e "${BLUE}Cleanup symblinks...${NC}"
  rm -f /etc/letsencrypt/live/${IAC_CERTBOT_DOMAIN}/*.pem || true
  ln -s /etc/letsencrypt/archive/${IAC_CERTBOT_DOMAIN}/cert*.pem /etc/letsencrypt/live/${IAC_CERTBOT_DOMAIN}/cert.pem || true
  ln -s /etc/letsencrypt/archive/${IAC_CERTBOT_DOMAIN}/chain*.pem /etc/letsencrypt/live/${IAC_CERTBOT_DOMAIN}/chain.pem || true
  ln -s /etc/letsencrypt/archive/${IAC_CERTBOT_DOMAIN}/fullchain*.pem /etc/letsencrypt/live/${IAC_CERTBOT_DOMAIN}/fullchain.pem || true
  ln -s /etc/letsencrypt/archive/${IAC_CERTBOT_DOMAIN}/privkey*.pem /etc/letsencrypt/live/${IAC_CERTBOT_DOMAIN}/privkey.pem || true

  # Azure ini
  echo -e "${BLUE}Setting azure ini...${NC}"
  (umask 077; echo ${AZURE_CONF} | base64 -d > azure.ini)
  chmod 600 azure.ini

  # Renew existing cert or build
  echo -e "${BLUE}Building certs...${NC}"
  certbot renew -n --agree-tos --dns-ovh --dns-ovh-credentials ovh.ini --dns-ovh-propagation-seconds 60 --cert-name ${IAC_CERTBOT_DOMAIN} -m ${IAC_CERTBOT_EMAIL} || certbot certonly -n --agree-tos --dns-ovh --dns-ovh-credentials ovh.ini --dns-ovh-propagation-seconds 60 -d ${IAC_CERTBOT_DOMAIN} -d *.${IAC_CERTBOT_DOMAIN} -m ${IAC_CERTBOT_EMAIL}

  # Update certbot cache
  echo -e "${BLUE}Updating certbot cache...${NC}"
  aws s3 sync /etc/letsencrypt s3://${IAC_CERTBOT_CACHE}
fi