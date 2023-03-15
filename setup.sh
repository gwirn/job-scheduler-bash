#!/bin/bash

storage_path="$1"

if [ ! -z "$storage_path" ];then
    path_end="${storage_path: -1}"
    if [ ! "$path_end" == "/" ];then
        storage_path="${storage_path}/"
    fi
    tmpfile=$(mktemp ./tempfile.XXXXXX)
    sed "s+/var/pid_storage/+${storage_path}+" schedule.sh > $tmpfile ; rm schedule.sh ; mv $tmpfile schedule.sh
    chmod +rx schedule.sh
else
    storage_path="/var/pid_storage/"
fi

if [ ! -d "$storage_path" ]; then
    echo "pid_storage is missing"
    echo "creating directory ${storage_path}"
    mkdir "$storage_path"
    mkd_ret=$?
    if [ "mkd_ret" == "1" ]; then
        echo "Using sudo to create $storage_path"
        sudo mkdir "$storage_path"
    fi
fi

if [ ! -e "${storage_path}pid_store.txt" ]; then
    echo "pid_store.txt is missing"
    echo "creating file, changing ownership and permissions"
    touch "${storage_path}pid_store.txt"
    t_ret="$?"
    if [ "$t_ret" == "1" ]; then
        echo "Using sudo to create ${storage_path}pid_store.txt"
        sudo touch "${storage_path}pid_store.txt"
    fi
    chown $(whoami) "${storage_path}pid_store.txt"
    c_ret="$?"
    if [ "$c_ret" == "1" ]; then
        echo "Using sudo to change ownership of ${storage_path}pid_store.txt"
        sudo chown $(whoami) "${storage_path}pid_store.txt"
    fi
    chmod o+rw "${storage_path}pid_store.txt"
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

type nohup || echo "nohup is not installed - please install it to be able to use 'njsb'"

echo "Everything is set - you can remove this folder if you want"
