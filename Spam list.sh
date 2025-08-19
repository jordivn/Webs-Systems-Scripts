#!/bin/bash
# Author: Jordi van Nistelrooij - Webs en Systems
# Date: 2025-08-19
# Version: 1.0
# Top 10 rapport generator van spamdetails.log
# Velden in spamdetails.log: FROM;SERVER;IP;SUBJECT

LOGFILE="/var/log/sa-learn/spamdetails.log"

print_top10() {
    local title="$1"
    local field="$2"
    echo "=== Top 10 $title ==="
    printf "%-6s | %s\n" "Aantal" "$title"
    printf "-------+-----------------------------\n"
    awk -F';' "{print \$$field}" "$LOGFILE" | sort | uniq -c | sort -nr | head -10 | while read -r count value; do
        printf "%-6s | %s\n" "$count" "$value"
    done
    echo
}

print_top10 "Afzenders" 1
print_top10 "Onderwerpen" 4
print_top10 "Domeinnamen" 2
print_top10 "IP-adressen" 3
