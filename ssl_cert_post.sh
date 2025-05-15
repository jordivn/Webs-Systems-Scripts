#!/bin/bash
#*******************************************************************************
#* @file        ssl_cert_post.sh
#*
#* @brief       This script is an hook for DA to call caa.sh to handle CAA records
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


# ssl_cert_post.sh
# Deze hook wordt aangeroepen nadat een SSL-certificaat is geïnstalleerd (Let's Encrypt of handmatig)

# DirectAdmin geeft het domein als eerste argument door
DOMAIN="$1"

# Pad naar jouw CAA-script (pas aan indien nodig)
CAA_SCRIPT="/usr/local/bin/caa.sh"

# Logbestand
LOGFILE="/var/log/caalog"

# Logging starten
echo "[$(date '+%F %T')] SSL-certificaat geïnstalleerd voor $DOMAIN - CAA verwerking gestart." >> "$LOGFILE"

# Controleer of caa.sh bestaat en uitvoerbaar is
if [[ -x "$CAA_SCRIPT" ]]; then
  "$CAA_SCRIPT" "$DOMAIN" >> "$LOGFILE" 2>&1
  echo "[$(date '+%F %T')] CAA-verwerking voltooid voor $DOMAIN" >> "$LOGFILE"
else
  echo "[$(date '+%F %T')] FOUT: $CAA_SCRIPT niet gevonden of niet uitvoerbaar" >> "$LOGFILE"
fi
