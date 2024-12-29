
#!/bin/sh
#Author: Jordi van Nistelrooij - Webs en systems
#Website: https://websensystems.nl
#Contact: info@websensystems.nl
#Date: 2024-12-29
#Version: 2.0
#Discription: Script for leaning userbased bayes with mailbox folders other then default (ham) and know spam folders>

LOGPATH='/var/log/sa-learn/'
mkdir -p $LOGPATH


# Definieer spam-mappen
SPAM_FOLDERS=(".Ongewenste e-mail" ".spam" ".Spam" ".Unwanted" ".Junk" ".Junk E-mail" ".Courrier indésirable" ".Unerwünschte E-Mails" ".Correo no deseado" ".Posta indesiderata" ".Junkmail" ".Spamfolder" ".Unwanted" ".Blocked" ".Blacklisted" ".BULK" ".INBOX.Spam" ".INBOX.spam")
# Definieer uitzonderingen
IGNORE_FOLDERS=(".Trash" "cur" "tmp" "new" ".Verwijderde items" "INBOX.Verwijderde items" ".Trash.Verwijderde items")



for USER in `ls /usr/local/directadmin/data/users`;
do
echo "=== Start ===" >> $LOGPATH$USER.log
echo $(date +%F) >> $LOGPATH$USER.log
echo "=============" >> $LOGPATH$USER.log
echo -e "Domain\tMailbox\tLearn\tFolder\tResult" >> $LOGPATH$USER.log
echo -e "===\t===\t===\t===\t===" >> $LOGPATH$USER.log



for DOMAIN in $(ls -d /home/$USER/imap/*); do
  for MAILBOX in $(ls -d $DOMAIN/*); do
    # Leer spam-mappen
    for FOLDER in "${SPAM_FOLDERS[@]}"; do
      if [ -d "$MAILBOX/Maildir/$FOLDER" ]; then
        echo "Leren van spam uit $MAILBOX/Maildir/$FOLDER" >> $LOGPATH$USER.log
        rspamc learn_spam "$MAILBOX/Maildir/$FOLDER" >> >> $LOGPATH$USER.log
      fi
    done

    # Dynamisch bouwen van uitsluitingen voor spam-mappen
    EXCLUDES=""
    if [ "${#SPAM_FOLDERS[@]}" -gt 0 ]; then
      for FOLDER in "${SPAM_FOLDERS[@]}"; do
        EXCLUDES+="! -iname \"$FOLDER\" "
      done
    fi

if [ "${#IGNORE_FOLDERS[@]}" -gt 0 ]; then
      for FOLDER in "${IGNORE_FOLDERS[@]}"; do
        EXCLUDES+="! -iname \"$FOLDER\" "
      done
    fi


    # Leer ham-mappen
    eval find "$MAILBOX/Maildir" -mindepth 1 -maxdepth 1 -type d  $EXCLUDES |
    while read -r HAM_FOLDER; do
      echo "Leren van ham uit $HAM_FOLDER" >> $LOGPATH$USER.log
     rspamc learn_ham "$HAM_FOLDER" >> $LOGPATH$USER.log

    done
  done
done

echo -e "===\t===\t===\t===\t===" >> $LOGPATH$USER.log

done
echo "Info" >> /var/log/sa-learn/overall.log
echo rspamc -h /var/run/rspamd/rspamd_controller.sock stat >> /var/log/sa-learn/overall.log
echo "===-------===" >>  /var/log/sa-learn/overall.log
echo $(date +%F) >>  /var/log/sa-learn/overall.log
echo "=============" >> /var/log/sa-learn/overall.log
echo "Updating DSR & KAM" >> /var/log/sa-learn/overall.log
rm -f /etc/mail/spamassassin/DSR.cf
rm -f /etc/mail/spamassassin/KAM.cf
echo "DSR & KAM removed" >> /var/log/sa-learn/overall.log
cd /etc/mail/spamassassin >> /var/log/sa-learn/overall.log
/usr/bin/wget -N https://dutchspamassassinrules.nl/DSR/DSR.cf >> /var/log/sa-learn/overall.log
/usr/bin/wget -N https://www.pccc.com/downloads/SpamAssassin/contrib/KAM.cf >> /var/log/sa-learn/overall.log
echo "Downloaded DSR & KAM" >> /var/log/sa-learn/overall.log
echo "Restarting spamassassin" >> /var/log/sa-learn/overall.log
systemctl restart spamassassin >> /var/log/sa-learn/overall.log
echo "DSR & KAM update done" >> /var/log/sa-learn/overall.log
rm -f $spamfile
rm -fr $spamfile_unpacked
exit
