#!/bin/sh

DOCKER_VERSION=${DOCKER_VERSION:='18.03'}
DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:='1.22.0'}
REMOTE=${REMOTE:='gitlab'}
BRANCH=${BRANCH:='dev'}
REDELIVRE_PATH=${REDELIVRE_PATH:='$HOME/redelivre'}
hasDocker=`echo $(which docker)`
hasDockerCompose=`echo $(which docker-compose)`

# Check if docker and docker-compose exists
if [ ! -n $hasDocker ] ; then
    curl https://releases.rancher.com/install-docker/${DOCKER_VERSION}.sh | sh
fi

if [ ! -n $hasDockerCompose ] ; then
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
fi

if [ ! -d $REDELIVRE_PATH ] ; then
    mkdir -p $REDELIVRE_PATH
fi

# wordpress
if [ ! -d $REDELIVRE_PATH/wordpress ] ;
    git clone "https://www.github.com/redelivre/2.0" $REDELIVRE_PATH/wordpress
fi

# Install github repos
for url in "install" "login-cidadao" "mapasculturais";  do
    if [ ! -d $HOME/redelivre/$url ] ; then
        git clone  "https://www.github.com/redelivre/${url}.git" $REDELIVRE_PATH/$url
    fi
done

# Add repos to install/
cd $HOME/redelivre/install \
    && git remote add lunhg https://www.github.com/lunhg/install.git \
    && git remote add gitlab git@gitlab.com:install/install.git \
    && git fetch --all \
    && git pull $REMOTE $BRANCH

cd -

# install gitlab repos in prefixed $HOME
for url in "alpine" "alpine-node" "alpine-redis" "redis-ui" "tg-bot" "tg-bot-commands" "assistente";  do
    if [ ! -d $HOME/redelivre/$url ] ; then
        git clone  git@gitlab.com:install/$url.git $REDELIVRE_PATH/$url
    fi
done

# Configure a .env file
for i in "username=$(whoami)" "apk_dependencies=sudo make git" "TRAVIS_LOCAL=senhasupersecreta" "NODE_ENV=10.11.0" "redisUI=redis.$(hostname)" "wordpress=wp.$(hostname)" "loginCidadao=lc.$(hostname)" "minio=s3.$(hostname)" "adminer=adminer.$(hostname)" "phpmyadmin=phpmyadmin.$(hostname)" "smtp=smtp.$(hostname)" "elk=elk.$(hostname)" "traefik=lb.$(hostname)" "tgbot=tgbot.$(hostname)" "api=api.tgbot.$(hostname)" "assistente_node_env=production" "assistente_port=3000" "assistente_redis_host=$(hostname)" "assistente_redis_port=6379" "assistente_redis_db=0" "assistente_jwt_issuer=feathers-plus" "assistente_jwt_audience=https://api.tgbot.$(hostname)" "assistente_session_name=ASSISTENTE-JWT" ; do echo $i >> $REDELIVRE_PATH/install/.env ; done

echo "Type a name for your telegram bot [ENTER]:"
eval read name && echo "TELEGRAM_NAME=$name" >> $REDELIVRE_PATH/install/.env

echo "Type a token for your telegram bot [ENTER]:"
eval read token && echo "TELEGRAM_TOKEN=$token" >> $REDELIVRE_PATH/install/.env

echo "Type 3 admins for your telegram bot, followed by '+' [ENTER]:"
eval read admins && echo "TELEGRAM_ADMINS=$admins" >> $REDELIVRE_PATH/install/.env

echo "Type a openid id for your telegram bot [ENTER]:"
eval read openid_id && echo "openid_id=$openid_id" >> $REDELIVRE_PATH/install/.env

echo "Type a openid secret for your telegram bot [ENTER]:"
eval read openid_secret && echo "openid_id=$openid_secret" >> $REDELIVRE_PATH/install/.env

echo "assistente_secret=$(cat /proc/sys/kernel/random/uuid)" >> $REDELIVRE_PATH/install/.env

eval make redelivre

exit 0
