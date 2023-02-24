#!/bin/bash

cmdneed=0
if [ ! -d "/var/pid_storage/" ]; then
    cmdneed=1
    echo "pid_storage is missing"
    echo "run following command:"
    echo "sudo mkdir /var/pid_storage/"
fi

if [ ! -e "/var/pid_storage/pid_store.txt" ]; then
    cmdneed=1
    echo "pid_store.txt is missing"
    echo "run following commands:"
    echo "sudo touch /var/pid_storage/pid_store.txt"
    echo "sudo chown YOURNAME /var/pid_storage/pid_store.txt"
    echo "chmod o+rw /var/pid_storage/pid_store.txt"
fi

if [ ! -d "$HOME/.scheduler" ]; then
    echo "creating directory for scheduler in '$HOME/.scheduler'"
    mkdir "$HOME/.scheduler"
fi

if [ ! -e "$HOME/.scheduler/schedule.sh" ];then
    echo "copying scheduler (schedule.sh) to '$HOME/.scheduler'"
    cp "schedule.sh" "$HOME/.scheduler/schedule.sh"
fi

ALIAS='alias jsb="bash $HOME/.scheduler/schedule.sh"' 
if ! grep -q "$ALIAS" "$HOME/.bashrc"; then
    echo $ALIAS >> "$HOME/.bashrc"
    echo "Scheduler added as 'jsb' alias in your $HOME/.bashrc"
fi

NALIAS='alias njsb="nohup bash $HOME/.scheduler/schedule.sh"' 
if ! grep -q "$NALIAS" "$HOME/.bashrc"; then
    echo $NALIAS >> "$HOME/.bashrc"
    echo "Scheduler added as 'njsb' alias in your $HOME/.bashrc"
fi

if [[ "$cmdneed" -eq 1 ]]; then
    echo "Everything is set after executing the commands above - you can remove this folder if you want"
else
    echo "Everything is set - you can remove this folder if you want"
fi
