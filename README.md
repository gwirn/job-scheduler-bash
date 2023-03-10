# job-scheduler-bash
This is a lightweight job scheduling bash program.

It is ment to be used for CLI programs/ scripts that should not run in parallel (e.g. because they might exhaust your computational resources) but should be run one after another. It keeps a internal queue so that the programs/ scripts get executed in chronoligical order.
One can queue everything like it was run in a bash shell without any changes to their workflow.

It can be used with one or multiple users. Each user uses the same internal queue. Thus, jobs from different users can also be queued one after another.

**Tested for Ubuntu 22.04 and GNU bash version 5.1.16(1)**

## Internal mechanisms
* shows how many jobs are scheduled
* tells you when it removes crashed PIDs from the queue
* removes itself from the PID queue in order to keep the queue clean
* checks whether queued PIDs are still alive and removes them if they crashed
* stores the time, the command and the error message for jobs that didn't succeed (jobs with ExitCode != 0)
  * only the last 1000 lines of error messages are stored

## Setup 
In order to set everything run `bash setup.sh` from within this directory.

By default the `pid_storage` file will be stored in `/var/pid_storage`. This can be changed by running the setup like `bash setup.sh "PATH/TO/STORAGE/DIRECTORY"'`.

This executes the following steps:
*  checks for the `/var/pid_storage` directory and shows the command needed to create it if it's not present
*  checks for `/var/pid_storage/pid_store.txt` and shows the necessary commands needed to set everything up
*  creates a directory `$HOME/.scheduler` where the script and error messages will be stored
   * in there a directory `errorlog` will be created at the first time running
   * in this directory errors happening during runs with the scheduler will be stored in `error.log`
*  copies the `schedule.sh` to this directory
*  creates aliases in your `$HOME/.bashrc` file
   *  you then can run anything you want with `jsb "YOURCOMMAND"`
   *  note that the `" "` are essential
   * sample commands: 
      * `jsb "python3 long_running.py"`
      * `jsb "bash bigbashscript.sh"`
   * can be run with nohup like:
      * `njsb "./expensivetask" &`
## Usage example
For two given programs `bigprogram_a.py` and `bigprogram_b.py` one can open two consoles and run `jsb "python3 bigprogram_a.py"` and in the second one run `jsb "python3 bigprogram_b.py"`. This will run `bigprogram_a.py` and test every minute whether `bigprogram_a.py` is still running. If not it starts `bigprogram_b.py` or if it's still running it tests again in one minute. The same can be done with `nohup` as described above. 
