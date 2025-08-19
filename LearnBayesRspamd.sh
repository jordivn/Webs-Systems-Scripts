#!/bin/bash
# Author: Jordi van Nistelrooij - Webs en systems
# Website: https://websensystems.nl
# Contact: info@websensystems.nl
# Date: 2025-08-19
# Version: 3.0
# Description: Script for learning user-based bayes with mailbox folders (ham/spam)

LOGPATH='/var/log/sa-learn/'
SPAMDETAILS_LOG="/var/log/sa-learn/spamdetails.log"
mkdir -p "$LOGPATH"

# Header toevoegen (1x bij leeg bestand)
if [ ! -s "$SPAMDETAILS_LOG" ]; then
  echo -e "From\tServer\tIP\tSubject" > "$SPAMDETAILS_LOG"
fi

# Definieer spam-mappen
SPAM_FOLDERS=(
  ".Ongewenste e-mail" ".spam" ".Spam" ".Unwanted" ".Junk" ".Junk E-mail"
  ".Courrier indésirable" ".Unerwünschte E-Mails" ".Correo no deseado"
  ".Posta indesiderata" ".Junkmail" ".Spamfolder" ".Unwanted" ".Blocked"
  ".Blacklisted" ".BULK" ".INBOX.Spam" ".INBOX.spam"
)

# Definieer uitzonderingen
IGNORE_FOLDERS=(
  ".Trash" "cur" "tmp" "new" ".Verwijderde items"
  "INBOX.Verwijderde items" ".Trash.Verwijderde items"
)

for USER in `ls /usr/local/directadmin/data/users`; do
  echo "=== Start ===" >> "$LOGPATH$USER.log"
  echo "$(date +%F)" >> "$LOGPATH$USER.log"
  echo "=============" >> "$LOGPATH$USER.log"
  echo -e "Domain\tMailbox\tLearn\tFolder\tResult" >> "$LOGPATH$USER.log"
  echo -e "===\t===\t===\t===\t===" >> "$LOGPATH$USER.log"

  if [ -d "/home/$USER/imap" ]; then
    for DOMAIN in /home/$USER/imap/*; do
      [ -d "$DOMAIN" ] || continue
      for MAILBOX in "$DOMAIN"/*; do
        [ -d "$MAILBOX" ] || continue

        # Leer spam-mappen
        for FOLDER in "${SPAM_FOLDERS[@]}"; do
          if [ -d "$MAILBOX/Maildir/$FOLDER" ]; then
            echo "Leren van spam uit $MAILBOX/Maildir/$FOLDER" >> "$LOGPATH$USER.log"
            rspamc learn_spam "$MAILBOX/Maildir/$FOLDER" >> "$LOGPATH$USER.log"

            find "$MAILBOX/Maildir/$FOLDER" -type f \
              ! -name "dovecot.index*" \
              ! -name "subscriptions" \
              ! -name "maildirsize" \
              ! -name "*~" | while read -r MAILFILE; do

              FROM=$(grep -m1 "^From:" "$MAILFILE" | sed 's/^From:[[:space:]]*//')

              # laatste Received-header pakken (echte bron)
              RECEIVED=$(grep "^Received:" "$MAILFILE" | tail -n1)
              IP=$(echo "$RECEIVED" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
              SERVER=$(echo "$RECEIVED" | sed -E 's/.*from ([^ ]+).*/\1/')

              SUBJECT=$(grep -m1 "^Subject:" "$MAILFILE" | sed 's/^Subject:[[:space:]]*//')
              # decodeer MIME-encoded subject indien nodig
              if echo "$SUBJECT" | grep -q "=?"; then
                SUBJECT=$(echo "$SUBJECT" | perl -MEncode -MEncode::MIME::Header -ne 'print decode("MIME-Header", $_)')
              fi

              if [ -n "$FROM" ] || [ -n "$SUBJECT" ] || [ -n "$IP" ] || [ -n "$SERVER" ]; then
                echo -e "$FROM\t$SERVER\t$IP\t$SUBJECT" >> "$SPAMDETAILS_LOG"
              fi
            done
          fi
        done

        # Dynamisch bouwen van uitsluitingen voor spam-mappen
        EXCLUDES=""
        for FOLDER in "${SPAM_FOLDERS[@]}" "${IGNORE_FOLDERS[@]}"; do
          EXCLUDES+="! -iname \"$FOLDER\" "
        done

        # Leer ham-mappen
        eval find "$MAILBOX/Maildir" -mindepth 1 -maxdepth 1 -type d $EXCLUDES |
        while read -r HAM_FOLDER; do
          echo "Leren van ham uit $HAM_FOLDER" >> "$LOGPATH$USER.log"
          rspamc learn_ham "$HAM_FOLDER" >> "$LOGPATH$USER.log"
        done

      done
    done
  fi

  echo -e "===\t===\t===\t===\t===" >> "$LOGPATH$USER.log"
done

echo "Info" >> /var/log/sa-learn/overall.log
echo rspamc -h /var/run/rspamd/rspamd_controller.sock stat >> /var/log/sa-learn/overall.log
echo "===-------===" >>  /var/log/sa-learn/overall.log
echo "$(date +%F)" >>  /var/log/sa-learn/overall.log
echo "=============" >> /var/log/sa-learn/overall.log
echo "Updating DSR & KAM" >> /var/log/sa-learn/overall.log
rm -f /etc/mail/spamassassin/DSR.cf
rm -f /etc/mail/spamassassin/KAM.cf
echo "DSR & KAM removed" >> /var/log/sa-learn/overall.log
cd /etc/mail/spamassassin >> /var/log/sa-learn/overall.log
/usr/bin/wget -N https://dutchspamassassinrules.nl/DSR/DSR.cf >> /var/log/sa-learn/overall.log
/usr/bin/wget -N https://www.pccc.com/downloads/SpamAssassin/contrib/KAM.cf >> /var/log/sa-learn/overall.log
echo "Downloaded DSR & KAM" >> /var/log/sa-learn/overall.log
echo "DSR & KAM update done" >> /var/log/sa-learn/overall.log
echo "Restarting respamd" >> /var/log/sa-learn/overall.log
systemctl restart rspamd >> /var/log/sa-learn/overall.log


rm -f $spamfile
rm -fr $spamfile_unpacked
exit
