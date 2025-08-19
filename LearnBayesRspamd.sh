#!/bin/sh
#Author: Jordi van Nistelrooij - Webs en systems
#Website: https://websensystems.nl
#Contact: info@websensystems.nl
#Date: 2025-08-19
#Version: 3.0
#Description: Script for learning user-based bayes with mailbox folders other than default (ham) and known spam folders

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

LOGPATH='/var/log/sa-learn/'
SPAMDETAILS_LOG="/var/log/sa-learn/spamdetails.log"
mkdir -p "$LOGPATH"

# Definieer spam-mappen
SPAM_FOLDERS=(".Ongewenste e-mail" ".spam" ".Spam" ".Unwanted" ".Junk" ".Junk E-mail" ".Courrier indésirable" ".Unerwünschte E-Mails" ".Correo no deseado" ".Posta indesiderata" ".Junkmail" ".Spamfolder" ".Unwanted" ".Blocked" ".Blacklisted" ".BULK" ".INBOX.Spam" ".INBOX.spam")
# Definieer uitzonderingen
IGNORE_FOLDERS=(".Trash" "cur" "tmp" "new" ".Verwijderde items" "INBOX.Verwijderde items" ".Trash.Verwijderde items")

for USER in $(ls /usr/local/directadmin/data/users); do
    printf "=== Start ===\n%s\n=============\n" "$(date +%F)" >> "$LOGPATH$USER.log"
    printf "%s\t%s\t%s\t%s\t%s\n" "Domain" "Mailbox" "Learn" "Folder" "Result" >> "$LOGPATH$USER.log"
    printf "===\t===\t===\t===\t===\n" >> "$LOGPATH$USER.log"

    for DOMAIN in $(ls -d /home/$USER/imap/* 2>/dev/null); do
        for MAILBOX in $(ls -d $DOMAIN/* 2>/dev/null); do

            # Leer spam-mappen
            for FOLDER in "${SPAM_FOLDERS[@]}"; do
                if [ -d "$MAILBOX/Maildir/$FOLDER" ]; then
                    printf "Leren van spam uit %s\n" "$MAILBOX/Maildir/$FOLDER" >> "$LOGPATH$USER.log"
                    rspamc learn_spam "$MAILBOX/Maildir/$FOLDER" >> "$LOGPATH$USER.log"

                    find "$MAILBOX/Maildir/$FOLDER" -type f ! -name "dovecot.index*" ! -name "subscriptions" ! -name "maildirsize" ! -name "*~" | while read -r MAILFILE; do
                        FROM=$(grep -m1 "^From:" "$MAILFILE" | sed 's/^From:[[:space:]]*//')
                        SUBJECT=$(grep -m1 "^Subject:" "$MAILFILE" | sed 's/^Subject:[[:space:]]*//')
                        IP=$(grep -m1 "Received: from" "$MAILFILE" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
                        SERVER=$(grep -m1 "Received: from" "$MAILFILE" | sed -E 's/.*from ([^ ]+).*/\1/')

                        if [ -n "$FROM" ] || [ -n "$SUBJECT" ] || [ -n "$IP" ] || [ -n "$SERVER" ]; then
                            printf "%s\t%s\t%s\t%s\n" "$FROM" "$SERVER" "$IP" "$SUBJECT" >> "$SPAMDETAILS_LOG"
                        fi
                    done
                fi
            done

            # Dynamisch bouwen van uitsluitingen voor spam-mappen
            EXCLUDES=""
            for FOLDER in "${SPAM_FOLDERS[@]}"; do
                EXCLUDES+="! -iname \"$FOLDER\" "
            done
            for FOLDER in "${IGNORE_FOLDERS[@]}"; do
                EXCLUDES+="! -iname \"$FOLDER\" "
            done

            # Leer ham-mappen
            eval find "$MAILBOX/Maildir" -mindepth 1 -maxdepth 1 -type d $EXCLUDES | while read -r HAM_FOLDER; do
                printf "Leren van ham uit %s\n" "$HAM_FOLDER" >> "$LOGPATH$USER.log"
                rspamc learn_ham "$HAM_FOLDER" >> "$LOGPATH$USER.log"
            done

        done
    done

    printf "===\t===\t===\t===\t===\n" >> "$LOGPATH$USER.log"
done

printf "Info\nrspamc -h /var/run/rspamd/rspamd_controller.sock stat\n===-------===\n%s\n=============\nUpdating DSR & KAM\n" "$(date +%F)" >> /var/log/sa-learn/overall.log
rm -f /etc/mail/spamassassin/DSR.cf /etc/mail/spamassassin/KAM.cf
printf "DSR & KAM removed\n" >> /var/log/sa-learn/overall.log
cd /etc/mail/spamassassin >> /var/log/sa-learn/overall.log
/usr/bin/wget -N https://dutchspamassassinrules.nl/DSR/DSR.cf >> /var/log/sa-learn/overall.log
/usr/bin/wget -N https://www.pccc.com/downloads/SpamAssassin/contrib/KAM.cf >> /var/log/sa-learn/overall.log
printf "Downloaded DSR & KAM\nRestarting spamassassin\n" >> /var/log/sa-learn/overall.log
systemctl restart spamassassin >> /var/log/sa-learn/overall.log
printf "DSR & KAM update done\n" >> /var/log/sa-learn/overall.log
exit
