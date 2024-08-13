#!/bin/bash

LOG_FILE="/data/releaseLog/deploy_$(date +%Y%m%d).log"
echo " " | tee -a $LOG_FILE 
echo "===== $(date) =====" | tee -a  $LOG_FILE
echo "=============== deploy start ===============" | tee -a $LOG_FILE
echo " start..."

## 변수셋팅
BASE_PATH="/home/jenkins-ssh/deploy"
JAR_PATH="$(ls -t $BASE_PATH/sample-*.jar | head -1)"
JAVA_CMD="java -jar"
JVM_OPTIONS="-Xmx1024m"

echo " profile check..." | tee -a $LOG_FILE

CURRENT_PROFILE=$(curl -s http://localhost/profile)

echo "  > current profile: $CURRENT_PROFILE" | tee -a $LOG_FILE

## profile에 따른 셋팅
if [ $CURRENT_PROFILE == was1 ] 
then

  echo " setting target server #2..." | tee -a $LOG_FILE

  SET_PROFILE=was2
  SET_PORT=8082
  RESTORE_PROFILE=was1
  RESTORE_PORT=8081

elif [ $CURRENT_PROFILE == was2 ] 
then

  echo " setting target server #1..." | tee -a $LOG_FILE

  SET_PROFILE=was1
  SET_PORT=8081
  RESTORE_PROFILE=was2
  RESTORE_PORT=8082

else

  echo " not matching target... current profile : $CURRENT_PROFILE"
  echo " setting target server #1..." | tee -a $LOG_FILE

  SET_PROFILE=was1
  SET_PORT=8081
  RESTORE_PROFILE=was2
  RESTORE_PROFILE=8082

fi

echo "  > profile: $SET_PROFILE" | tee -a $LOG_FILE 
echo "  > port: $SET_PORT" | tee -a $LOG_FILE

echo " application symbol-link create..." | tee -a $LOG_FILE

APP_NAME="sample.jar"
DEPLOY_APP=$SET_PROFILE-$APP_NAME
DEPLOY_APP_PATH=$BASE_PATH/$DEPLOY_APP
RESTORE_APP=$RESTORE_PROFILE-$APP_NAME
RESTORE_APP_PATH=$BASE_PATH/$RESTORE_APP

#echo "| tee -a $DEPLOY_APP_PATH"
ln -fs $JAR_PATH $DEPLOY_APP_PATH

## 실행중인 프로세스 kill
if pgrep -f "$DEPLOY_APP" > /dev/null; then
  echo " $DEPLOY_APP is alive... " | tee -a $LOG_FILE

  sudo pkill -f "$DEPLOY_APP"

  echo " $DEPLOY_APP  process kill..." | tee -a $LOG_FILE

  for i in {1..15}; do
    
    if pgrep -f "$DEPLOY_APP" > /dev/null; then
	echo " Waiting for $DEPLOY_APP to terminate... " | tee -a $LOG_FILE
        sleep 1
    else
	echo " $DEPLOY_APP process kill success! " | tee -a $LOG_FILE
        break
    fi
  done

  if pgrep -f "$DEPLOY_APP" > /dev/null; then
    echo "$DEPLOY_APP did not terminate... force kill... " | tee -a $LOG_FILE
    sudo pkill -9 f "$DEPLOY_APP"

    if pgrep -f "$DEPLOY_APP" > /dev/null; then
      echo "$DEPLOY_APP process kill failed..." | tee -a $LOG_FILE
    else 
      echo "$DEPLOY_APP process force kill completed. " | tee -a $LOG_FILE
    fi
    
  fi

else
  echo " 현재 구동중인 APP이 없습니다." | tee -a $LOG_FILE
fi


echo "================< Start deploy Jar >===============" | tee -a $LOG_FILE

## jar execute
BUILD_ID=dontKillMe nohup $JAVA_CMD $JVM_OPTIONS -Dspring.profiles.active=$SET_PROFILE $DEPLOY_APP_PATH > /dev/null 2>&1 & 

echo " $SET_PROFILE health check..." | tee -a $LOG_FILE
#echo " curl -s http://localhost:$SET_PORT/actuator/health"

sleep 5

## health check logic
for reCnt in {1..21}
do
  response=$(curl -s http://localhost:$SET_PORT/actuator/health)
  upCount=$(echo $response | grep 'UP' | wc -l) 


  if [ $upCount -ge 1 ]
  then
    echo "  > Deploy Success!!" | tee -a $LOG_FILE
    
#    /home/jenkins-ssh/nginx-switch.sh
    break
  else
    echo "  > No response And Unknown Status..." | tee -a $LOG_FILE
    echo "  > response: $response"
  fi

  if [ $reCnt -eq 20 ]
  then 
    echo "  > Deploy Fail..." | tee -a $LOG_FILE
    echo "  > Deploy process Exit..." | tee -a $LOG_FILE

    echo "  > Restore application..." | tee -a $LOG_FILE
    ## nginx restore
    #/home/jenkins-ssh/nginx-switch.sh
 
    exit 1
  fi

  echo "  > connection fail... Retry! - $reCnt / 20" | tee -a $LOG_FILE
  sleep 1
done

## nginx proxy_pass change.
sleep 3
/home/jenkins-ssh/nginx-switch.sh

