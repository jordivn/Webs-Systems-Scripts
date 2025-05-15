#!/bin/bash
#*******************************************************************************
#* @file        caa.sh
#*
#* @brief       This script  handles CAA records creation on bases of the current certificate
#*
#* @author      Jordi van Nistelrooij @ Webs en Systems.
#* @email       info@websensystems.nl
#* @website     https://websensystems.nl
#* @version     1.0.0
#* @copyright   Non of these scripts maybe copied or modified without permission of the author
#*
#* @date        2025-05-15
#*
#*******************************************************************************

exec >> /var/log/caalog 2>&1
echo "==== $(date) - Start CAA update for $1 ===="

DOMAIN="$1"
EMAIL="admin@$DOMAIN"
ZONE_PATH="/var/named/${DOMAIN}.db"
KEY_DIR="/var/named"

if [[ -z "$DOMAIN" ]]; then
  echo "Useage: $0 domeinnaam.nl"
  exit 1
fi

if [[ ! -f "$ZONE_PATH" ]]; then
  echo "Zonefile not found: $ZONE_PATH"
  exit 1
fi

ISSUER=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null \
    | openssl x509 -noout -issuer | grep -o 'O=.*,' | cut -d= -f2)

echo "Certificate issuer): $ISSUER"

if [[ "$ISSUER" == *"Let's Encrypt"* ]]; then
    CA="letsencrypt.org"
elif [[ "$ISSUER" == *"Sectigo"* ]]; then
    CA="sectigo.com"
elif [[ "$ISSUER" == *"DigiCert"* ]]; then
    CA="digicert.com"
elif [[ "$ISSUER" == *"Google Trust Services"* || "$ISSUER" == *"R10"* ]]; then
    CA="pki.goog"
elif [[ "$ISSUER" == *"GlobalSign"* ]]; then
    CA="globalsign.com"
elif [[ "$ISSUER" == *"Buypass"* ]]; then
    CA="buypass.com"
elif [[ "$ISSUER" == *"Amazon"* || "$ISSUER" == *"AWS"* ]]; then
    CA="amazon.com"
elif [[ "$ISSUER" == *"SSL.com"* ]]; then
    CA="ssl.com"
elif [[ "$ISSUER" == *"Entrust"* ]]; then
    CA="entrust.net"
elif [[ "$ISSUER" == *"Actalis"* ]]; then
    CA="actalis.com"
elif [[ "$ISSUER" == *"GoDaddy"* ]]; then
    CA="godaddy.com"
elif [[ "$ISSUER" == *"Certum"* ]]; then
    CA="certum.pl"
else
    echo "Onbekende issuer: $ISSUER"
    exit 1
fi

cp "$ZONE_PATH" "$ZONE_PATH.bak"

sed -i '/IN[[:space:]]\+CAA/d' "$ZONE_PATH"

echo "@ IN CAA 0 issue \"$CA\"" >> "$ZONE_PATH"
echo "@ IN CAA 0 issuewild \"$CA\"" >> "$ZONE_PATH"
echo "@ IN CAA 0 iodef \"mailto:$EMAIL\"" >> "$ZONE_PATH"

DNSSEC_KEYS=$(ls "$KEY_DIR"/${DOMAIN}*.key 2>/dev/null | wc -l)

if [[ "$DNSSEC_KEYS" -gt 0 ]]; then
  echo "DNSSEC active. Zone will be resignd..."
  /usr/local/directadmin/scripts/dnssec.sh sign $DOMAIN
else
  echo "DNSSEC not active."
fi

# Reload BIND
rndc reload "$DOMAIN"

echo "Adding CAA records succesful."
