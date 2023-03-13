#!/bin/bash
sleeping_min=1

# store the bash script pid 
mypid=$$
pidplace="/var/pid_storage/pid_store.txt"
tmpplace='/tmp/tmppid/'
errordir="$HOME/.scheduler/errorlog"
lockfile="${tmpplace}pid.lock"
echo "$mypid" >> "$pidplace"

function genlock (){
    # create lock file so pid storage doesn't get changed when used by other process
    echo "$mypid" > "$lockfile"
 }

function rmlock (){
    # remove lock file and return 0 if file was removed or 1 if file was alread gone
    if [ -f "$lockfile" ]; then
        rm "$lockfile"
        return 0
    else
        return 1
    fi
 }

function checklock (){
    # check if PID in lockfile is still alive
    if [ -f "$lockfile" ]; then
        lockpid=$(cat "$lockfile") 
        # if its not myself
        if [ ! "$lockpid" == "$mypid" ] && [ -n "$lockpid" ];then
            # if lock PID is dead
            if ! ps -p "$lockpid" > /dev/null;then
                rmlock
                rml_ret="$?"
                if [[ "$rml_ret" -eq "0" ]];then
                    echo "*** Removed crashed pid lock ***"
                fi
            fi
            
        fi
    fi

    # check if valid lockfile exists and if so then wait
    while [ -f "$lockfile" ]; do
        sleep 0.5
    done
 }

function cleanup (){
    SIGNAL=$1
    echo "xxx CLEANUP xxx"

    # removes my PID from storage file
    echo "*** Removing myself from running PIDs ***"
    checklock
    genlock
    awk "!/$mypid/" $pidplace > "${tmpplace}r${mypid}"
    cat "${tmpplace}r${mypid}" > "$pidplace"
    rmlock

    if [ -f "${tmpplace}e${mypid}" ];then
        rm "${tmpplace}e${mypid}"
    fi

    if [ -f "${tmpplace}r${mypid}" ];then
        rm "${tmpplace}r${mypid}"
    fi

    if [ -f "${tmpplace}${mypid}" ];then
        rm "${tmpplace}${mypid}"
    fi

    if [ -n "$SIGNAL" ]; then
        trap $SIGNAL
        kill -${SIGNAL} $$
    fi
}

function monitor_pids (){
    # true if nothing is running
    check=0
    incr=0
    checklock
    genlock
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
        sed $crashedpid $pidplace > "$tmppid"
        cat "$tmppid" > "$pidplace"
    fi
    rmlock
    return $check
}

if [ ! -d "/tmp/tmppid" ]; then
    mkdir "$tmpplace"
fi

trap cleanup EXIT

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
