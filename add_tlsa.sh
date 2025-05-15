#!/bin/sh
#*******************************************************************************
#* @file        add_tlsa.sh
#*
#* @brief       This script handles TLSA records creation
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
DOMAIN=$1
USER=`cat /etc/virtual/snidomains | grep "^$DOMAIN" | cut -d':' -f2`
echo "Users is $USER"

TQ=/usr/local/directadmin/data/task.queue
DTQ=/usr/local/directadmin/dataskq

if [ "${DOMAIN}" = "" ] || [ ! -d /etc/virtual/$DOMAIN ]; then
       echo "$DOMAIN is not a valid domain";
       exit 1;
fi

#F=lets-encrypt-x2-cross-signed.pem
#F=lets-encrypt-x1-cross-signed.pem
#F=lets-encrypt-x3-cross-signed.pem
#wget -O $F https://letsencrypt.org/certs/$F
#F=`cat /usr/local/directadmin/data/users/$USER/domains/$DOMAIN.cert.combined`
V=`openssl x509 -in /usr/local/directadmin/data/users/$USER/domains/$DOMAIN.cert.combined -outform DER | openssl dgst -sha256 -hex | awk '{print "3 0 1", $NF}'`

echo "Value is: $V"

#R= `openssl s_client -brief -starttls smtp -dane_tlsa_domain mail.$DOMAIN -dane_tlsa_rrdata $V -connect mail.$DOMAIN:25`

#echo "$R"


#exit;
#clear the old le-ca
echo "action=dns&do=delete&domain=${DOMAIN}&type=TLSA&name=_443._tcp.mail.$DOMAIN.&value=*" >> ${TQ}
echo "action=dns&do=delete&domain=${DOMAIN}&type=TLSA&name=_443._tcp.$DOMAIN.&value=*" >> ${TQ}
echo "action=dns&do=delete&domain=${DOMAIN}&type=TLSA&name=_443._tcp.www.$DOMAIN.&value=*" >> ${TQ}
echo "action=dns&do=delete&domain=${DOMAIN}&type=TLSA&name=_25._tcp.mail.$DOMAIN.&value=*" >> ${TQ}
echo "action=dns&do=delete&domain=${DOMAIN}&type=TLSA&name=_25._tcp.$DOMAIN.&value=*" >> ${TQ}
echo "action=dns&do=delete&domain=${DOMAIN}&type=TLSA&name=_25._tcp.www.$DOMAIN.&value=*" >> ${TQ}


#adding
echo "action=dns&do=add&domain=${DOMAIN}&type=TLSA&name=_443._tcp.mail.$DOMAIN.&value=$V" >> ${TQ}
echo "action=dns&do=add&domain=${DOMAIN}&type=TLSA&name=_443._tcp.$DOMAIN.&value=$V" >> ${TQ}
echo "action=dns&do=add&domain=${DOMAIN}&type=TLSA&name=_443._tcp.www.$DOMAIN.&value=$V" >> ${TQ}
echo "action=dns&do=add&domain=${DOMAIN}&type=TLSA&name=_25._tcp.mail.$DOMAIN.&value=$V" >> ${TQ}
echo "action=dns&do=add&domain=${DOMAIN}&type=TLSA&name=_25._tcp.$DOMAIN.&value=$V" >> ${TQ}
echo "action=dns&do=add&domain=${DOMAIN}&type=TLSA&name=_25._tcp.www.$DOMAIN.&value=$V" >> ${TQ}

echo 'action=named&value=reload' >> ${TQ}
