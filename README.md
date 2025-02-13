# submit-vnc
This script allows you to submit a VNC session as a compute job.

To submit the job, assuming you are using SLURM, please try:
```sh
sbatch submit_desktop.sh
```
Once your job is running, you will find an output file `VNC_Desktop-<job_id>.out`. This file will contain the URL and password for you to connect to the session.

After the job is completed, please submit the following script to the same node:
```sh
sbatch clean_after.sh
```

Please note that the execution of this script depends on intermediate file `vnc_display.txt`. Deleting this file before cleanup will result in a failure to clean the .X11 locks, and will semi-permanently lock that display (until reboot). Please be mindful.
