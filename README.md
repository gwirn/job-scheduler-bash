# job-scheduler-bash
This is a lightweight job scheduling bash program.
It is ment to be used for CLI programs/ bash scripts that should not run in parallel (because they might exhaust your computational resources).
It can be used with one and multiple users.


In order to set everything run `bash setup.sh`
This does the following steps:
    * checks for the `/var/pid_storage` folder and shows the command needed to create it if it's not present
    * checks for `/var/pid_storage/pid_store.txt` and shows the necessary commands needed to set everything up
    * creates a folder `$HOME/.scheduler` where the script and error messages will be stored
    * copies the `scheduler.sh` to this folder
    * creates an alias in your `$HOME/.bashrc` file
        * you then can run anything you want with `jsb "YOURCOMMAND"`
        * note that `"` are essential
        
