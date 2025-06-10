#!/bin/bash
#*******************************************************************************
#* @file        php_list.sh
#*
#* @brief       This scripts creates an list with used php versions for each domain on DA
#*
#*
#* @author 	Jordi van Nistelrooij @ Webs en Systems. 
#* @email 	info@websensystems.nl
#* @website	https://websensystems.nl
#* @version 	1.0.0
#* @copyright 	Non of these scripts maybe copied or modified without permission of the author
#*
#* @date        2025-06-10
#*
#*******************************************************************************
DA_USERS="/usr/local/directadmin/data/users"
OPTIONS_CONF="/usr/local/directadmin/custombuild/options.conf"
OUTPUT_FILE="php_versies_per_domein.txt"

# Haal phpX_release waardes op uit options.conf
declare -A php_versions
for i in {1..4}; do
    versie=$(grep "^php${i}_release=" "$OPTIONS_CONF" | cut -d= -f2)
    if [ -n "$versie" ]; then
        php_versions["$i"]="$versie"
    fi
done

echo "Domein | Gekozen PHP Slot | PHP Versie" > "$OUTPUT_FILE"
echo "------------------------------" >> "$OUTPUT_FILE"

for user in $(ls "$DA_USERS"); do
    DOMAINS_FILE="$DA_USERS/$user/domains.list"

    if [ -f "$DOMAINS_FILE" ]; then
        for domain in $(cat "$DOMAINS_FILE"); do
            CONF_FILE="$DA_USERS/$user/domains/${domain}.conf"
            if [ ! -f "$CONF_FILE" ]; then
                continue
            fi

            SLOT=$(grep "^php1_select=" "$CONF_FILE" | cut -d= -f2)

            if [ -z "$SLOT" ]; then
                SLOT="1"  # fallback naar php1 als er geen php1_select is
            fi

            VERSION="${php_versions[$SLOT]:-(onbekend)}"

            echo "$domain | $SLOT | $VERSION" >> "$OUTPUT_FILE"
        done
    fi
done

column -t -s '|' "$OUTPUT_FILE"


exit
