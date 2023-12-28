#!/bin/bash
#*******************************************************************************
#* @file        DNSSEC_da_oxxa.sh
#*
#* @brief       Dit script verzorgt de registratie van de DNSSEC Keys bij OXXA
#*
#* @details     Er wordt gekeken of er inderdaad DNSSEC keys zijn op de server.
#*              Deze worden vergeleken met die van OXXA. Als deze anders zijn worden ze aangepast.
#*              Script kan opgeslagen worden in /usr/local/directadmin/scripts/custom/dnssec_sign_post.sh om automatisch te draaien na het ondertekenen.
#*              Eventueel ook standalone aan te roepen met als parameter het domeinnaam.
#*
#* @author 	Jordi van Nistelrooij @ Webs en Systems. 
#* @email 	info@websensystems.nl
#* @website	https://websensystems.nl
#* @version 	1.0.0
#* @copyright 	Non of these scripts maybe copied or modified without permission of the author
#*
#* @date        2023-12-28
#*
#*******************************************************************************

if [[ ! -z ${domain} ]]
then
echo "Directadmin"
DOMAIN=${domain}
elif [[ ! -z $1 ]]
then
echo "CLI"
DOMAIN=$1
else
        echo "Geen domeinnaam aangegeven."
        exit 1;
fi


OXXA_USER="YOUR OXXA API USERNAME HERE" 
OXXA_PASS="YOUR OXXA API PASSWORD HERE"

SLD=`echo ${DOMAIN} | cut -d'.' -f1`
TLD=`echo ${DOMAIN} | cut -d'.' -f2`

echo "=============$(date)============"
echo "We gaan DNSSEC installatie uitvoeren voor $DOMAIN"


curl -s "https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_info&sld=${SLD}&tld=${TLD}" > response.xml
echo `yq -p xml -o props response.xml | grep channel.order.status_description | cut -d'=' -f2`
yq -p xml -o props response.xml > response2.xml

KEYZ_FLAG=`cat response2.xml | grep channel.order.details.dnssec.key.flags | cut -d' ' -f3`
KEY0_FLAG=`cat response2.xml | grep channel.order.details.dnssec.key.0.flags | cut -d' ' -f3`
KEY1_FLAG=`cat response2.xml | grep channel.order.details.dnssec.key.1.flags | cut -d' ' -f3`

if [[ "KEYZ_FLAG" -eq 256 || "KEYZ_FLAG" -eq 257 ]]
then
        echo "Maar gedeeltelijk geregistreerd bij register. Sleutel wordt verwijderd."
        KEYZ_KEY=`cat response2.xml | grep channel.order.details.dnssec.key.pubKey | cut -d' ' -f3`
        KEYZ_ENCODE=$(curl -s -w '%{url_effective}\n' -G / --data-urlencode "=$KEYZ_KEY" | cut -c 3-)
        KEYZ_PRO=`cat response2.xml | grep channel.order.details.dnssec.key.protocol | cut -d' ' -f3`
        KEYZ_ALG=`cat response2.xml | grep channel.order.details.dnssec.key.alg | cut -d' ' -f3`
        curl -s "https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_del&sld=$SLD&tld=$TLD&flag=$KEYZ_FLAG&protocol=$KEYZ_PRO&alg=$KEYZ_ALG&pubkey=$KEYZ_ENCODE" > temp.response
        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`
fi

if [[ ! -f "/var/named/${DOMAIN}.ksk.key" ]]
then
        echo "Bestand bestaat niet. Dit domein heeft geen DNSSec"
        echo "We controleren of er records zijn bij de register"

if [[ "KEY0_FLAG" -eq 256 || "KEY0_FLAG" -eq 257 ]]
then
        echo "Er zijn records gevonden. Deze gaan we verwijderen"
        KEY0_KEY=`cat response2.xml | grep channel.order.details.dnssec.key.0.pubKey | cut -d' ' -f3`
        KEY0_ENCODE=$(curl -s -w '%{url_effective}\n' -G / --data-urlencode "=$KEY0_KEY" | cut -c 3-)
        KEY0_PRO=`cat response2.xml | grep channel.order.details.dnssec.key.0.protocol | cut -d' ' -f3`
        KEY0_ALG=`cat response2.xml | grep channel.order.details.dnssec.key.0.alg | cut -d' ' -f3`


        KEY1_KEY=`cat response2.xml | grep channel.order.details.dnssec.key.1.pubKey | cut -d' ' -f3`
        KEY1_ENCODE=$(curl -s -w '%{url_effective}\n' -G / --data-urlencode "=$KEY1_KEY" | cut -c 3-)
        KEY1_PRO=`cat response2.xml | grep channel.order.details.dnssec.key.1.protocol | cut -d' ' -f3`
        KEY1_ALG=`cat response2.xml | grep channel.order.details.dnssec.key.1.alg | cut -d' ' -f3`
        curl -s 'https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_del&sld=${SLD}&tld=${TLD}&flag=$KEY1_FLAG&protocol=$KEY1_PRO&alg=$KEY1_ALG&pubkey=$KEY1_ENCODE' > temp.response
        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`
        curl -s 'https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_del&sld=${SLD}&tld=${TLD}&flag=$KEY0_FLAG&protocol=$KEY0_PRO&alg=$KEY0_ALG&pubkey=$KEY0_ENCODE' > temp.response
        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`
else
        echo "Er zijn geen records gevonden."
fi
exit 0;

fi

echo "Domeinnaam heeft DNSSec ingesteld. Waardes gaan we ophalen."

KSK_FLAG=`sed -n '5p' /var/named/${DOMAIN}.ksk.key | cut -d' ' -f4`
KSK_PRO=`sed -n '5p' /var/named/${DOMAIN}.ksk.key | cut -d' ' -f5`
KSK_ALG=`sed -n '5p' /var/named/${DOMAIN}.ksk.key | cut -d' ' -f6`
KSK_PART1=`sed -n '5p' /var/named/${DOMAIN}.ksk.key | cut -d' ' -f7`
KSK_PART2=`sed -n '5p' /var/named/${DOMAIN}.ksk.key | cut -d' ' -f8`
KSK_KEY="$KSK_PART1$KSK_PART2"
KSK_ENCODE=$(curl -s -w '%{url_effective}\n' -G / --data-urlencode "=$KSK_KEY" | cut -c 3-)


ZSK_FLAG=`sed -n '5p' /var/named/${DOMAIN}.zsk.key | cut -d' ' -f4`
ZSK_PRO=`sed -n '5p' /var/named/${DOMAIN}.zsk.key | cut -d' ' -f5`
ZSK_ALG=`sed -n '5p' /var/named/${DOMAIN}.zsk.key | cut -d' ' -f6`
ZSK_PART1=`sed -n '5p' /var/named/${DOMAIN}.zsk.key | cut -d' ' -f7`
ZSK_PART2=`sed -n '5p' /var/named/${DOMAIN}.zsk.key | cut -d' ' -f8`
ZSK_KEY="$ZSK_PART1$ZSK_PART2"
ZSK_ENCODE=$(curl -s -w '%{url_effective}\n' -G / --data-urlencode "=$ZSK_KEY" | cut -c 3-)

echo "We controleren of er records zijn bij de register"

if [[ "KEY0_FLAG" -eq 256 || "KEY0_FLAG" -eq 257 ]]
then
        echo "Er zijn records gevonden. Nu controleren of deze het zelfde zijn."
        KEY0_KEY=`cat response2.xml | grep channel.order.details.dnssec.key.0.pubKey | cut -d' ' -f3`
        KEY0_ENCODE=$(curl -s -w '%{url_effective}\n' -G / --data-urlencode "=$KEY0_KEY" | cut -c 3-)
        KEY0_PRO=`cat response2.xml | grep channel.order.details.dnssec.key.0.protocol | cut -d' ' -f3`
        KEY0_ALG=`cat response2.xml | grep channel.order.details.dnssec.key.0.alg | cut -d' ' -f3`


        KEY1_KEY=`cat response2.xml | grep channel.order.details.dnssec.key.1.pubKey | cut -d' ' -f3`
        KEY1_ENCODE=$(curl -s -w '%{url_effective}\n' -G / --data-urlencode "=$KEY1_KEY" | cut -c 3-)
        KEY1_PRO=`cat response2.xml | grep channel.order.details.dnssec.key.1.protocol | cut -d' ' -f3`
        KEY1_ALG=`cat response2.xml | grep channel.order.details.dnssec.key.1.alg | cut -d' ' -f3`

        if [[ "KEY0_FLAG" -eq 257 ]]
        then
                if [[ "$KEY0_KEY" != "$KSK_KEY" ]]
                then
                        echo "KSK niet gelijk"
                        echo "KSK Server $KSK_KEY"
                        echo "KSK Register $KEY0_KEY"
                        echo "Oude KSK sleutel verwijderen bij register."
                        curl -s 'https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_del&sld=${SLD}&tld=${TLD}&flag=$KEY0_FLAG&protocol=$KEY0_PRO&alg=$KEY0_ALG&pubkey=$KEY0_ENCODE' > temp.response
                        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`
                        echo "Nieuwe KSK record invoegen."
                        curl -s "https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_add&sld=${SLD}&tld=${TLD}&flag=$KSK_FLAG&protocol=$KSK_PRO&alg=$KSK_ALG&pubkey=$KSK_ENCODE" > temp.response
                        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`

                else
                        echo "KSK Gelijk"
                fi
        elif [[ "KEY0_FLAG" -eq 256 ]]
        then
                if [[ "$KEY0_KEY" != "$ZSK_KEY" ]]
                then
                        echo "ZSK niet gelijk"
                        echo "ZSK Server $ZSK_KEY"
                        echo "ZSK Register $KEY0_KEY"
                        echo "Oude ZSK sleutel verwijderen bij register"
                        curl -s 'https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_del&sld=${SLD}&tld=${TLD}&flag=$KEY0_FLAG&protocol=$KEY0_PRO&alg=$KEY0_ALG&pubkey=$KEY0_ENCODE' > temp.response
                        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`
                        echo "Nieuwe ZSK record invoegen."
                        curl -s "https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_add&sld=${SLD}&tld=${TLD}&flag=$ZSK_FLAG&protocol=$KSK_PRO&alg=$ZSK_ALG&pubkey=$ZSK_ENCODE" > temp.response
                        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`
                else
                        echo "ZSK Gelijk"
                fi

        fi

        if [[ "KEY1_FLAG" -eq 257 ]]
        then
                if [[ "$KEY1_KEY" != "$KSK_KEY" ]]
                then
                        echo "KSK niet gelijk"
                        echo "KSK Server $KSK_KEY"
                        echo "KSK Register $KEY1_KEY"
                        echo "Oude KSK sleutel verwijderen bij register."
                        curl -s 'https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_del&sld=${SLD}&tld=${TLD}&flag=$KEY1_FLAG&protocol=$KEY1_PRO&alg=$KEY1_ALG&pubkey=$KEY1_ENCODE' > temp.response
                        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`
                        echo "Nieuwe KSK record toevoegen."
                        curl -s "https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_add&sld=${SLD}&tld=${TLD}&flag=$KSK_FLAG&protocol=$KSK_PRO&alg=$KSK_ALG&pubkey=$KSK_ENCODE" > temp.response
                        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`

                else
                        echo "KSK Gelijk"
                fi
        elif [[ "KEY1_FLAG" -eq 256 ]]
        then
                if [[ "$KEY1_KEY" != "$ZSK_KEY" ]]
                then
                        echo "ZSK niet gelijk"
                        echo "ZSK Server $ZSK_KEY"
                        echo "ZSK Register $KEY1_KEY"
                        echo "Oude ZSK sleutel verwijderen bij register."
                        curl -s 'https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_del&sld=${SLD}&tld=${TLD}&flag=$KEY1_FLAG&protocol=$KEY1_PRO&alg=$KEY1_ALG&pubkey=$KEY1_ENCODE' > temp.response
                        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`
                        echo "Nieuwe ZSK record toevoegen"
                        curl -s "https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_add&sld=${SLD}&tld=${TLD}&flag=$ZSK_FLAG&protocol=$KSK_PRO&alg=$ZSK_ALG&pubkey=$ZSK_ENCODE" > temp.response
                        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`
                else
                        echo "ZSK Gelijk"
                fi

        fi



else
        echo "Er zijn geen records gevonden. Deze gaan we aanmaken."
        curl -s "https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_add&sld=${SLD}&tld=${TLD}&flag=$KSK_FLAG&protocol=$KSK_PRO&alg=$KSK_ALG&pubkey=$KSK_ENCODE" > temp.response
        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`
        curl -s "https://api.oxxa.com/command.php?apiuser=${OXXA_USER}&apipassword=${OXXA_PASS}&command=dnssec_add&sld=${SLD}&tld=${TLD}&flag=$ZSK_FLAG&protocol=$ZSK_PRO&alg=$ZSK_ALG&pubkey=$ZSK_ENCODE" > temp.response
        echo `yq -p xml -o props temp.response | grep channel.order.status_description | cut -d'=' -f2`
fi

echo "We gaan opruimen"
rm -f response.xml
rm -f response2.xml
rm -f temp.response
echo "We zijn klaar!"
echo "=============$(date)============"
exit 0;
