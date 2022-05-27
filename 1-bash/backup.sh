#!bin/bash
#Where are backups saved?
backup_files="/root/backup"

#Destination of backup:
year=$(date +%Y)
month=$(date +%m)
dest="/root/backup/$year/$month"

#Create archive filename:
day=$(date + %Y-%m-%d)
hostname=$(hostname -s)
archive_file="$hostname-$day.tar.gz"

#Print start status of message
echo "Backing up $backup_files to $dest/$archive_file"
date
echo

# Backup the file using tar
tar czf $dest/$archive_file $backup_files

#Print end status message
echo
echo "Backup finished"
date

#Long listing of files in $dest to check file sizes.
ls -lh $dest
