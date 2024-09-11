#!/bin/sh
#Author: Jordi van Nistelrooij - Webs en systems
#Website: https://websensystems.nl
#Contact: info@websensystems.nl
#Date: 2023-05-19
#Version: 1.0
#Discription: Script for leaning userbased bayes with mailbox folders other then default (ham) and know spam folders (spam). Also use mbox spam from artinvoice
# THIS VERSION IS FOR SPAMASSASSIN used by directadmin

LOGPATH='/var/log/sa-learn/'
mkdir -p $LOGPATH

for USER in `ls /usr/local/directadmin/data/users`;
do
#rm $LOGPATH$USER.log -f
echo "=== Start ===" >> $LOGPATH$USER.log
echo $(date +%F) >> $LOGPATH$USER.log
echo "=============" >> $LOGPATH$USER.log
echo -e "Domain\tMailbox\tLearn\tFolder\tResult" >> $LOGPATH$USER.log
echo -e "===\t===\t===\t===\t===" >> $LOGPATH$USER.log



for DOMAINS in `ls -d /home/$USER/imap/*`;
do

if [ `find $DOMAINS -maxdepth 1 -type d | wc -l` -ge 2 ]
then
for MAILBOX in `ls -d $DOMAINS/*`;
do

if [ `find $MAILBOX -maxdepth 1 -type d | wc -l` -ge 2 ]
then
IFS=$'\n'
for HAMMAILBOXFOLDER in `ls -d $MAILBOX/Maildir/.* | egrep -v -i 'spam|Ongewenst|verwijderde|trash|drafts|concepten|junk|prullenbak|unwanted|deleted|\.$|\.\.$'`;
do
if [ -d "${HAMMAILBOXFOLDER}/cur" ]
then
echo -e `basename ${DOMAINS}` "\t" `basename ${MAILBOX}` "\tHAM\t" `basename ${HAMMAILBOXFOLDER}` "\t" `sa-learn --ham --db /home/$USER/.spamassassin "${HAMMAILBOXFOLDER}/cur"` >> $LOGPATH$USER.log
fi
done

IFS=$'\n'
for SPAMMAILBOXFOLDER in `ls -d $MAILBOX/Maildir/.* | egrep -i 'spam|Ongewenst|junk|unwanted'`;
do
if [ -d "${SPAMMAILBOXFOLDER}/cur" ]
then
echo -e `basename ${DOMAINS}` "\t" `basename ${MAILBOX}` "\tSPAM\t" `basename ${SPAMMAILBOXFOLDER}` "\t" `sa-learn --spam --db /home/$USER/.spamassassin "${SPAMMAILBOXFOLDER}/cur"` >> $LOGPATH$USER.log
fi
done
fi
done
fi
done
echo -e "===\t===\t===\t===\t===" >> $LOGPATH$USER.log
echo "Syncing" >> $LOGPATH$USER.log
sa-learn --sync --dbpath /home/$USER/.spamassassin >> $LOGPATH$USER.log
echo "Bayes info" >> $LOGPATH$USER.log
sa-learn --dump magic --dbpath /home/$USER/.spamassassin >> $LOGPATH$USER.log
chown $USER:$USER /home/$USER/.spamassassin/bayes_*
echo "=== Done ===" >> $LOGPATH$USER.log
done

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
