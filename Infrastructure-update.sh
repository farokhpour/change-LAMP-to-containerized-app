#!/bin/bash
read -p "Enter database password: " database_password

database_password=$database_password
echo -e "\e[32mDatabase password set\e[0m"

read -p "Enter database name: " database_name
database_name=$database_name
echo -e "\e[32mDatabase name set to $database_name\e[0m"

mysqldump -u root -p$database_password $database_name > /home/infrastructure-update/before-update.sql
echo -e "\e[32mDatabase backup created\e[0m"

systemctl stop redis-server.service
echo -e "\e[32mStopped Redis Server\e[0m"

systemctl stop mariadb.service
echo -e "\e[32mStopped MariaDB Service\e[0m"

systemctl stop apache2
echo -e "\e[32mStopped Apache2\e[0m"

systemctl disable redis-server.service
echo -e "\e[32mDisabled Redis Server\e[0m"

systemctl disable mariadb.service
echo -e "\e[32mDisabled MariaDB Service\e[0m"

systemctl disable apache2
echo -e "\e[32mDisabled Apache2\e[0m"

systemctl start docker
echo -e "\e[32mStart Docker\e[0m"

systemctl enable docker
echo -e "\e[32mEnable Docker\e[0m"

unzip /home/infrastructure-update/app-docker.zip
echo -e "\e[32mUnzipped app-docker.zip\e[0m"

unzip /home/infrastructure-update/technical-risk-micro-service.zip
echo -e "\e[32mUnzipped app-docker.zip\e[0m"

unzip /home/infrastructure-update/images.zip
echo -e "\e[32mUnzipped images\e[0m"

mv /home/infrastructure-update/app-docker /var/www/html
echo -e "\e[32mMoved app-docker to /var/www/html\e[0m"

mv /home/infrastructure-update/images /root
echo -e "\e[32mMoved images to /root\e[0m"

cd /var/www/html/app-docker
chmod -R 755 ./
echo -e "\e[32mChanged permissions for app-docker\e[0m"

./import-images.sh
echo -e "\e[32mImported images\e[0m"

mv /var/www/html/app /var/www/html/app-docker/
echo -e "\e[32mMoved app to app-docker\e[0m"

mkdir /var/www/html/app-docker/services
mv /home/infrastructure-update/technical-risk-micro-service /var/www/html/app-docker/services
echo -e "\e[32mMoved technical-risk-micro-service to app-docker services\e[0m"

mv /home/infrastructure-update/env.micro /var/www/html/app-docker/app/.env
echo -e "\e[32mMoved env.micro to /var/www/html/app-docker/app/.env\e[0m"

ln -s /var/www/html/app-docker/configurations/supervisor/app.conf /etc/supervisor/conf.d/
echo -e "\e[32mCreated symlink for supervisor configuration\e[0m"

systemctl restart supervisor
sleep 5
systemctl enable supervisor 
sleep 5
supervisorctl update
echo -e "\e[32mUpdated supervisor and sleep 60\e[0m"
sleep 60

docker exec -ti app_php php artisan config:cache
echo -e "\e[32mCleared Laravel config cache for app_php\e[0m"


read -p "Enter docker database password: " docker_database_password
docker_database_password=$docker_database_password
echo -e "\e[32mDocker database password set\e[0m"

read -p "Enter docker database name: " docker_database_name
docker_database_name=$docker_database_name
echo -e "\e[32mDocker database name set to $docker_database_name\e[0m"

docker exec -i app_db mariadb -u root -p$docker_database_password $docker_database_name < /home/infrastructure-update/before-update.sql
echo -e "\e[32mImported database before-update.sql to db database\e[0m"

docker exec -ti technical_risk_php php artisan config:cache
echo -e "\e[32mCleared Laravel config cache for technical_risk_php\e[0m"

docker exec -ti app_php php artisan storage:link
echo -e "\e[32mCreated storage symlink for app_php\e[0m"

docker exec -ti technical_risk_php php artisan storage:link
echo -e "\e[32mCreated storage symlink for technical_risk_php\e[0m"

docker exec -ti technical_risk_php php artisan migrate --force
echo -e "\e[32mMigrate for technical_risk_php\e[0m"

docker exec -ti technical_risk_php php db:seed --force
echo -e "\e[32mDB seed for technical_risk_php\e[0m"

cd /var/www/html/app-docker
chown -R www-data:www-data ./
echo -e "\e[32mChanged ownership of app-docker to www-data\e[0m"

chmod -R 755 ./
echo -e "\e[32mChanged permissions for app-docker\e[0m"

cd /var/www/html/app-docker/data/
rm -rf rabbitmq
rm -rf redis
chmod 777 -R elasticsearch

echo -e "\e[32mRemoved rabbitmq and redis directories and fix chmod of elasticsearch\e[0m"

cd /var/www/html/app-docker
docker compose down
echo -e "\e[32mStopped Docker containers and wait 5 minuties\e[0m"

sleep 300

docker exec -ti app_php php artisan elastic:create-index "App\appIndexConfigurator"
echo -e "\e[32mCreated Elasticsearch index for app\e[0m"

docker exec -ti app_php php artisan scout:import "App\Model\RmAsset"
echo -e "\e[32mImported RmAsset models to Elasticsearch\e[0m"

docker exec -ti technical_risk_php php artisan rabbitmq:technicalRisk
echo -e "\e[32mExecuted artisan command rabbitmq:technicalRisk for technical_risk_php\e[0m"

docker exec -ti app_php php artisan z-app:Rabbitmq
echo -e "\e[32mExecuted artisan command z-app:Rabbitmq for app_php and wait one minutes\e[0m"

sleep 60
docker exec -ti app_php php artisan z-app:exportAsset
echo -e "\e[32mExecuted artisan command z-app:exportAsset for app_php\e[0m"
echo -e "\e[32mFINISHED\e[0m"
