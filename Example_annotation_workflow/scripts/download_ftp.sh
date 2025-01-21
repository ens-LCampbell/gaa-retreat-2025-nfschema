#!/usr/bin/sh

URL=$1
FILE=$2
if [[ `wget -S --spider $URL  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then 
    echo "Downloading URL [$URL]" | tee -a ftp_file_download.log
    wget $URL -O $FILE
fi