#!/bin/bash
sleeping_min=1

# store the bash script pid 
mypid=$$
pidplace='/var/pid_storage/pid_store.txt'
tmpplace='/tmp/tmppid/'
errordir="$HOME/.scheduler/errorlog"
echo "$mypid" >> "$pidplace"

function avoid_change (){
    # avoid changing the pid storage file when it is currently processed
    while [ -n "$(lsof "$pidplace")" ]; do
        sleep 0.5
    done
}

function monitor_pids (){
    # true if nothing is running
    check=0
    incr=0
    # read the file with stored PIDs
    while IFS= read -r saved_pids; do
        # check if PID in file is still running
        if ps -p "$saved_pids" > /dev/null; then
            # if the running PID is not me
            if [ ! "$saved_pids" -eq "$mypid" ]; then
                # let me sleep
                let check=1
                break
            else
                # my turn
                break
            fi
        else
            # get crashed pids position in file
            incr=$(expr $incr + 1)
            crashedpid="${crashedpid}"${incr}"d;"
        fi
    done <$pidplace
    # remove crashed PIDs if they were not removed correctly
    if (( "$incr" > 0 )) && [[ "$check" -eq "0" ]]; then
        echo "*** Removing stored but crashed PIDs ***"
        tmppid="${tmpplace}${mypid}"
        avoid_change
        sed $crashedpid $pidplace > "$tmppid"
        cat "$tmppid" > "$pidplace"
    fi
    return $check
}

if [ ! -d "/tmp/tmppid" ]; then
    mkdir "$tmpplace"
fi

# check queued jobs
file_start=$(head -n 1 $pidplace)
queued=$(sed -n "/${file_start}/,/${mypid}/p" $pidplace | wc -l)
echo "*** $(( $queued - 1 )) job(s) is/are queued before your job ***"

# signal to start my process
go=0
while [[ "$go" -eq "0" ]]; do
    # check if I am the oldest running PID
    if ! monitor_pids; then
        echo "--- $(date +%Y-%m-%d-%H-%M-%S) Machine is busy - next try in ${sleeping_min} minute(s) ---"
        sleep $(( $sleeping_min * 60 ))
    else
        let go=1
    fi
done

echo "*** Now we are free - ready to take of ***"

# saving errors - dir creation and date saving
if  [ ! -d "$errordir" ]; then
    mkdir "$errordir"
fi
errlogfile="$errordir/error.log"
now=$(date +%Y-%m-%d-%H-%M-%S)
echo "$now" >> "$errlogfile"

# runs the program and save exit code
bash -c "$1" 2>> "$errlogfile"

# continuation error log - store time, error code and command 
bashexit="$?"
if [ ! "$bashexit" -eq "0" ]; then
    echo "$1" >> "$errlogfile"
    awk "/$now/,0" "$errlogfile"
else
    awk "!/$now/" "$errlogfile" >  "${tmpplace}e${mypid}"
    cat "${tmpplace}e${mypid}" > "$errlogfile"
fi

# keeping only the last 1000 lines of error messages
tail -n 1000 "$errlogfile" > "${tmpplace}e${mypid}"
cat "${tmpplace}e${mypid}" > "$errlogfile" 
rm "${tmpplace}e${mypid}"

# removes my PID from storage file
echo "*** Removing myself from running PIDs ***"
avoid_change
awk "!/$mypid/" $pidplace > "${tmpplace}r${mypid}"
cat "${tmpplace}r${mypid}" > "$pidplace"
rm "$tmpplace"*
