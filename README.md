# jenkins-release

git-jenkins-nginx release shell script.
***

![image](https://github.com/jong-bae/jenkins-release/assets/20313814/07c14d90-12a3-42c2-9ec1-379c866ef922)


1. Jenkins
   - jenkins Github hook trigger for GITSCM polling 설정
   - build steps 설정
     - Transfer Set 후  Exec command 에서 .sh 커맨드 실행.
    
2. Shell script 수행
3. Nginx 포트변경 후 재기동
4. 배포 완료 확인
