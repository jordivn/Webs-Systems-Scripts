#!/bin/bash
# Author: Jordi van Nistelrooij - Webs en Systems
# Date: 2025-08-19
# Version: 1.0
# Description: Voeg afzenders of onderwerpen toe aan SpamAssassin cf-bestand met beschrijving

CF_FILE="/etc/mail/spamassassin/local_custom_wes.cf"
DATE_NOW=$(date '+%Y-%m-%d')

# Controleer parameters
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <afzender|onderwerp> <string>"
    exit 1
fi

TYPE="$1"
STRING="$2"

# Controleer of het type geldig is
if [[ "$TYPE" != "afzender" && "$TYPE" != "onderwerp" ]]; then
    echo "Type moet 'afzender' of 'onderwerp' zijn"
    exit 1
fi

# Maak een regelnaam van de string: alleen letters, cijfers en underscores, max 30 tekens
RULE_BASE=$(echo "$STRING" | tr -c '[:alnum:]' '_' | cut -c1-30)

DESCRIPTION="Added $DATE_NOW because of spammer"

if [ "$TYPE" == "afzender" ]; then
    RULE_NAME="${RULE_BASE}_FROM"
    # Check of de rule al bestaat
    if ! grep -q "^header $RULE_NAME" "$CF_FILE"; then
        echo "header $RULE_NAME From =~ /$STRING/i" >> "$CF_FILE"
        echo "score $RULE_NAME 5.0" >> "$CF_FILE"
        echo "describe $RULE_NAME $DESCRIPTION" >> "$CF_FILE"
        echo "Added afzender rule: $RULE_NAME"
    else
        echo "Afzender rule $RULE_NAME bestaat al, geen actie uitgevoerd."
    fi
elif [ "$TYPE" == "onderwerp" ]; then
    RULE_NAME="${RULE_BASE}_SUBJECT"
    if ! grep -q "^header $RULE_NAME" "$CF_FILE"; then
        echo "header $RULE_NAME Subject =~ /$STRING/i" >> "$CF_FILE"
        echo "score $RULE_NAME 5.0" >> "$CF_FILE"
        echo "describe $RULE_NAME $DESCRIPTION" >> "$CF_FILE"
        echo "Added onderwerp rule: $RULE_NAME"
    else
        echo "Onderwerp rule $RULE_NAME bestaat al, geen actie uitgevoerd."
    fi
fi

# Herstart spamassassin zodat de nieuwe regels geladen worden
systemctl restart rspamd
echo "Rspamd herstart met nieuwe regels."
