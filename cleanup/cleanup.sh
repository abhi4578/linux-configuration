#!/bin/bash
### Cleanup script - removing
### unneeded apt packages, snaps, docker related stuff
### Need to run using sudo command
# Removes old revisions of snaps
# CLOSE ALL SNAPS BEFORE RUNNING THIS
set -eu
apt autoremove -y
snap list --all | awk '/disabled/{print $1, $3}' |
while read snapname revision; do
snap remove "$snapname" --revision="$revision"
done

journalctl --vacuum-time=3d

docker system prune -f 
