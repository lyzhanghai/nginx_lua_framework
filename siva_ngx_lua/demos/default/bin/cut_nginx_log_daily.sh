#!/bin/bash
# This script run at 00:00

# Add this line to crontab
#00 00 * * * /bin/bash /path/to/letv_ngx_lua-demo/bin/cut_nginx_log_daily.sh

# Set App Home
source `dirname $0`/utils.sh
letv_ngx_lua_app_home=$APP_ROOT

#/////////////////////////////////////////////////////////////////////////////////////

logs_path="$letv_ngx_lua_app_home/nginx_runtime/logs"
log_files=`ls $logs_path`

year=$(date -d "yesterday" +"%Y")
month=$(date -d "yesterday" +"%m")
date=$(date -d "yesterday" +"%Y%m%d")

mkdir -p ${logs_path}/$year/$month/

for log_file in $log_files; do
    if [[ $log_file == *.log* ]]; then
        #echo $log_file
        daily_log_file=${log_file//.log/.log.$date}
        echo mv ${logs_path}/$log_file ${logs_path}/$year/$month/$daily_log_file
        mv ${logs_path}/$log_file ${logs_path}/$year/$month/$daily_log_file
    fi
done
kill -USR1 `cat ${logs_path}/nginx.pid`

#/////////////////////////////////////////////////////////////////////////////////////
