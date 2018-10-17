#!/bin/sh

DOCKER_VERSION=${DOCKER_VERSION:='18.06'}
DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:='1.22.0'}
REMOTE=${REMOTE:='gitlab'}
BRANCH=${BRANCH:='dev'}
HOME=${HOME:=/home/$(whoami)}
REDELIVRE_PATH=${REDELIVRE_PATH:=$HOME/redelivre}
hasDocker=`echo $(which docker)`
hasDockerCompose=`echo $(which docker-compose)`

echo "######  ####### ######  ####### #       ### #     # ######  ####### "
echo "#     # #       #     # #       #        #  #     # #     # #       "
echo "#     # #       #     # #       #        #  #     # #     # #       "
echo "######  #####   #     # #####   #        #  #     # ######  #####   "
echo "#   #   #       #     # #       #        #   #   #  #   #   #       "
echo "#    #  #       #     # #       #        #    # #   #    #  #       "
echo "#     # ####### ######  ####### ####### ###    #    #     # ####### "
echo "===> Configuring docker $DOCKER_VERSION"
echo "===> Configuring docker-compose $DOCKER_COMPOSE_VERSION"
echo "===> Configuring remote $REMOTE"
echo "===> Configuring branch $BRANCH"
echo "===> Configuring prefix $REDELIVRE_PATH"

# Check if docker and docker-compose exists
if [ ! -n $hasDocker ] ; then
    echo "==> Installing docker"
    curl https://releases.rancher.com/install-docker/${DOCKER_VERSION}.sh | sh
fi

if [ ! -n $hasDockerCompose ] ; then
    echo "==> Installing docker-compose"
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
fi

if [ ! -d $REDELIVRE_PATH ] ; then
    echo "==> Creating $REDELIVRE_PATH"
    mkdir -p $REDELIVRE_PATH
fi

# wordpress
if [ ! -d $REDELIVRE_PATH/wordpress ] ; then
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
    && git config user.name "$(whoami)" \
    && git remote add lunhg https://www.github.com/lunhg/install.git \
    && git remote add gitlab git@gitlab.com:install/install.git \
    && git fetch --all \
    && git pull $REMOTE $BRANCH \
    && git checkout dev

cd -

# install gitlab repos in prefixed $HOME
for url in "alpine" "alpine-node" "alpine-redis" "redis-ui" "tg-bot" "tg-bot-commands" "assistente";  do
    if [ ! -d $HOME/redelivre/$url ] ; then
        git clone  git@gitlab.com:install/$url.git $REDELIVRE_PATH/$url
    fi
done

# Configure a .env file
for i in "username=$(whoami)" "apk_dependencies=sudo make git" "TRAVIS_LOCAL=senhasupersecreta" "NODE_ENV=10.11.0" "redisUI=redis.$(hostname)" "wordpress=wp.$(hostname)" "loginCidadao=lc.$(hostname)" "minio=s3.$(hostname)" "adminer=adminer.$(hostname)" "phpmyadmin=phpmyadmin.$(hostname)" "smtp=smtp.$(hostname)" "elk=elk.$(hostname)" "traefik=lb.$(hostname)" "tgbot=tgbot.$(hostname)" "api=api.tgbot.$(hostname)" "assistente_node_env=production" "assistente_port=3000" "assistente_redis_host=$(hostname)" "assistente_redis_port=6379" "assistente_redis_db=0" "assistente_jwt_issuer=feathers-plus" "assistente_jwt_audience=https://api.tgbot.$(hostname)" "assistente_session_name=ASSISTENTE-JWT" ; do echo $i >> $REDELIVRE_PATH/install/.env ; done


for i in "telegram_name" "telegram_token" "telegram_admins" "openid_id" "openid_secret" ; do
    if [ ! -n ${!i} ] ; then
        echo "==> ${!i} not declared"
        exit 1
    fi
    if [ -n $i ] ; then
        echo "$i=${!i}" >> $REDELIVRE_PATH/install/.env
    fi
done

echo "assistente_secret=$(cat /proc/sys/kernel/random/uuid)" >> $REDELIVRE_PATH/install/.env

# Make redelivre
cd $REDELIVRE_PATH/install
make --makefile $REDELIVRE_PATH/install/Makefile redelivre
cd -
exit 0
