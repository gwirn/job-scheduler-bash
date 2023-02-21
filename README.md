# job-scheduler-bash
This is a lightweight job scheduling bash program.

It is ment to be used for CLI programs/ bash scripts that should not run in parallel (e.g. because they might exhaust your computational resources) but should be run one after another. It keeps a internal queue so that the programs/ scripts get executed in chronoligical order.

It can be used with one and multiple users.

**Tested for Ubuntu 22.04 and GNU bash version 5.1.16(1)**


In order to set everything run `bash setup.sh`

This executes the following steps:
*  checks for the `/var/pid_storage` directory and shows the command needed to create it if it's not present
*  checks for `/var/pid_storage/pid_store.txt` and shows the necessary commands needed to set everything up
*  creates a directory `$HOME/.scheduler` where the script and error messages will be stored
   * in there a directory `errorlog` will be created at the first time running
   * in this directory errors happening during run with this scheduler will be stored in `error.log`
*  copies the `schedule.sh` to this directory
*  creates an alias in your `$HOME/.bashrc` file
   *  you then can run anything you want with `jsb "YOURCOMMAND"`
   *  note that the `" "` are essential
