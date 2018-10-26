# ARGS = $(filter-out $@,$(MAKECMDGOALS))
# MAKEFLAGS += --silent

# https://github.com/maxpou/docker-symfony
# https://github.com/schliflo/bedrock-docker

redelivre: start app_lc_migrations app_wp_migrations app_mc_migrations
	make urls

app_lc_build_frontend:
	echo "==> Executing migrations on login-cidadao frontend..."
	docker-compose exec app_lc php app/console assets:install
	docker-compose exec app_lc rm -rf app/cache/prod
	docker-compose exec app_lc php app/console assetic:dump -e prod
	docker-compose exec app_lc chmod -R 777 /var/www/html/app/cache/

app_lc_migrations:
	echo "==> Executing migrations on login-cidadao..."
  sleep: 5
	docker-compose exec mariadb mysql -uroot -p $mariadb_root_pwd -e "create database lc;"
	docker-compose exec app_lc php app/console doctrine:schema:create
	docker-compose exec app_lc php app/console lc:database:populate batch/
	docker-compose exec app_lc php app/console doctrine:schema:update --force

app_mc_migrations:
	echo "==> Executing migrations on mapasculturais..."
	docker-compose exec app_mc ./scripts/db-update.sh
	docker-compose exec app_mc ./scripts/mc-db-updates.sh -d $mc
	docker-compose exec app_mc ./scripts/generate-proxies.sh
	# docker-compose exec postgres psql -d mapas -U mapas -f ../db/schema.sql
	# docker-compose exec postgres psql -d mapas -U mapas -f ../db/initial-data.sql

app_wp_migrations:
	echo "==> Executing migrations on wordpress..."
	docker-compose exec app_wp wp --allow-root core install  --path=./web/wp --url=https://$wordpress --title=teste-redelivre --admin_user=root --admin_password=$mariadb_root_pwd --skip-email --admin_email=teste@teste.com
	docker-compose exec app_wp wp --allow-root plugin activate wpro

lc:
	echo "==> Starting building login-cidadao..."
	docker-compose up --build -d --remove-orphans app_lc web_lc

mc:
	echo "==> Starting building mapasculturais..."
	docker-compose up --build -d --remove-orphans app_mc web_mc

wp:
	echo "==> Starting building wordpress..."
	docker-compose up --build -d --remove-orphans web_wp

traefik:
	echo "==> Starting building traefik load balancer..."
	docker-compose up --build -d --remove-orphans traefik

alpine:
	echo "==> Starting building alpine base image..."
	docker-compose up --build -d --remove-orphans alpine

rd:
	echo "==> Starting building redis base image and its derived images..."
	docker-compose up --build -d --remove-orphans __redis__ redis redisAdmin redisUI 

nd:
	echo "==> Starting building node base image and its derived images..."
	docker-compose up --build -d --remove-orphans __node__ tg_bot assistente_api

build: lc mc wp alpine nd rd

start: build

stop:
	echo "Stopping your project..."
	docker-compose stop

destroy: stop
	echo "Deleting all containers..."
	docker-compose down --rmi all 

upgrade:
	echo "Upgrading your project..."
	docker-compose pull
	docker-compose build --pull
	# make composer update
	make start

restart: stop up

rebuild: destroy upgrade


#############################
# UTILS
#############################

# mysql-backup:
# 	bash ./.utils/mysql-backup.sh

# mysql-restore:
# 	bash ./.utils/mysql-restore.sh

ci-test:
	bash ./.utils/ci/test.sh


#############################
# CONTAINER ACCESS
#############################

ssh:
	docker exec -it $$(docker-compose ps -q $(ARGS)) sh


#############################
# INFORMATION
#############################

urls:
	@echo "Urls disponíveis"
	@echo "-------------------------------------------------"
	@echo ""
	@echo "Wordpress Admin:    https://"`hostname`"/wp/wp-admin/"
	@echo "Wordpress:          https://"`hostname`
	@echo "Login Cidadão:      https://lc."`hostname`
	@echo "Mapas Culturais:    https://mc."`hostname`
	@echo "Servidor de E-mail: https://smtp."`hostname`
	@echo "Servidor S3:        https://s3."`hostname`
	@echo "PHPMyAdmin:         https://phpmyadmin."`hostname`
	@echo "Adminer:            https://adminer."`hostname`
	@echo "Telegram bot:       https://$tg_bot."`hostname`
	@echo "Telegram bot api:   https://$tg_api."`hostname`
	@echo "Whatsapp selenium:  https://$www_selenium."`hostname`
	@echo "Whatsapp bot:       https://$www_bot."`hostname`
	@echo "-------------------------------------------------"

clean:
	@docker-compose down -v --remove-orphans

status:
	docker-compose ps

logs:
	docker-compose logs -f --tail=50

# check-proxy:
# 	bash ./.utils/check-proxy.sh

#############################
# Argument fix workaround
#############################
%:
	@:
