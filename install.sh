#!/bin/sh

DOCKER_VERSION=${DOCKER_VERSION:='18.03'}
DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:='1.22.0'}
REMOTE=${REMOTE:='gitlab'}
BRANCH=${BRANCH:='dev'}
SSH_FILE=${SSH_FILE:='install'}


eval $(ssh-agent -s) && ssh-add $HOME/.ssh/$SSH_FILE

if [ ! `which docker` == '/usr/bin/docker' ] ; then
    curl https://releases.rancher.com/install-docker/${DOCKER_VERSION}.sh | sh
fi


if [ ! `which docker-compose` == '/usr/bin/docker-compose' ] ; then
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
fi

if [ ! -d "$HOME/redelivre" ] ; then
    mkdir -p $HOME/redelivre
fi

# wordpress
if [ ! -d $HOME/redelivre/wordpress ] ; then
    git clone "https://www.github.com/redelivre/2.0" "$HOME/redelivre/wordpress"
fi;

for url in "install" "login-cidadao" "mapasculturais";  do
    if [ ! -d $HOME/redelivre/$url ] ; then
        git clone  "https://www.github.com/redelivre/${url}.git" $HOME/redelivre/$url
    fi
done

# install gitlab repos in prefixed $HOME
for url in "alpine" "alpine-node" "alpine-redis" "redis-ui" "tg-bot" "tg-bot-commands" "assistente";  do
    if [ ! -d $HOME/redelivre/$url ] ; then
        git clone  git@gitlab.com:install/$url.git $HOME/redelivre/$url
    fi
done

cd $HOME/redelivre/install \
    && git remote add gitlab git@gitlab.com:install/install.git \
    && git fetch --all && git pull $REMOTE $BRANCH
    
# Configure a .env file
for i in "username=$(whoami)" "apk_dependencies=sudo make git" "TRAVIS_LOCAL=senhasupersecreta" "NODE_ENV=10.11.0" "redisUI=redis.$(hostname)" "wordpress=wp.$(hostname)" "loginCidadao=lc.$(hostname)" "minio=s3.$(hostname)" "adminer=adminer.$(hostname)" "phpmyadmin=phpmyadmin.$(hostname)" "smtp=smtp.$(hostname)" "elk=elk.$(hostname)" "traefik=lb.$(hostname)" "tgbot=tgbot.$(hostname)" "api=api.tgbot.$(hostname)" "assistente_node_env=production" "assistente_port=3000" "assistente_redis_host=$(hostname)" "assistente_redis_port=6379" "assistente_redis_db=0" "assistente_jwt_issuer=feathers-plus" "assistente_jwt_audience=https://api.tgbot.$(hostname)" "assistente_session_name=ASSISTENTE-JWT" ; do echo $i >> $HOME/redelivre/install/.env ; done

echo "Type a name for your telegram bot [ENTER]:"
read name
echo "TELEGRAM_NAME=$name" >> $HOME/redelivre/install/.env

echo "Type a token for your telegram bot [ENTER]:"
read token
echo "TELEGRAM_TOKEN=$token" >> $HOME/redelivre/install/.env

echo "Type 3 admins for your telegram bot, followed by '+' [ENTER]:"
read admins
echo "TELEGRAM_ADMINS=$admins" >> $HOME/redelivre/install/.env

echo "Type a openid id for your telegram bot [ENTER]:"
read openid_id
echo "openid_id=$openid_id" >> $HOME/redelivre/install/.env

echo "Type a openid secret for your telegram bot [ENTER]:"
read openid_secret
echo "openid_id=$openid_secret" >> $HOME/redelivre/install/.env

echo "assistente_secret=$(cat /proc/sys/kernel/random/uuid)" >> $HOME/redelivre/install/.env

make redelivre

exit 0
