#!/bin/bash

LOG_FILE="/data/Log/deploy_$(date +%Y%m%d).log"
echo "=============== <Nginx proxy switch> ==============" >> $LOG_FILE
echo " current profile port check..."

CURRENT_PROFILE=$(curl -s http://localhost/profile)

echo "  > current profile:  $CURRENT_PROFILE" >> $LOG_FILE

if [ $CURRENT_PROFILE == was1 ]
then
  SET_PORT=8082
elif [ $CURRENT_PROFILE == was2 ]
then
  SET_PORT=8081
else
  echo "  > not matching target... current profile : $CURRENT_PROFILE"
  SET_PORT=8081
fi

echo "  > set port : $SET_PORT" >> $LOG_FILE
echo "set \$service_port $SET_PORT;" | sudo tee /etc/nginx/conf.d/service-url.inc 


echo " Nginx reload" >> $LOG_FILE
sudo systemctl reload nginx

echo " ********** THE END *********" >> $LOG_FILE
echo " " >> $LOG_FILE

exit 0
