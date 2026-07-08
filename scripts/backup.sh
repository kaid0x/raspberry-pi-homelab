#!/bin/bash
# Nightly backup: mirror the main file drive to the portable backup drive.
# Scheduled via cron: 30 4 * * * /home/USER/backup.sh   (04:30 daily)
#
# Notes:
#   -rt (not -a) because the backup drive is exFAT and can't store Linux perms/ownership
#   --delete makes it a true mirror
#   --exclude 'lost+found' skips the ext4-only recovery folder on the source

LOGFILE="/home/USER/backup.log"
echo "=== Backup started: $(date) ===" >> "$LOGFILE"

rsync -rtv --delete --exclude 'lost+found' /mnt/filedrive/ /mnt/backupdrive/ >> "$LOGFILE" 2>&1

echo "=== Backup finished: $(date) ===" >> "$LOGFILE"
echo "" >> "$LOGFILE"
