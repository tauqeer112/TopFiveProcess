1. The main script file is script.sh
2. memory_log.txt is created in 3rd run of script.
3. Since memory is unlike time which get consumed. Maximum memory occupied 
   is maximum memory a process is using at a particular time, not the
   addition. 
   ---------------------**********************************************************---------------------------------------
   | max_mem = max(max(file1) , max(file2) , max (file3)) | if pid are not same and mem is max we log multiple entries.|
   ---------------------**********************************************************---------------------------------------
   
4. { echo "* * * * * /home/tauqeer/assig5/script.sh"; } | crontab - && crontab -l  #command to add to crontab
5. ./script.sh will run the file
6. /home/tauqeer/assig5/script.sh  is path to script.sh
7. /home/tauqeer/assig5/ - is base directory can be modified in script.sh
