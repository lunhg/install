#!/bin/sh

DOCKER_VERSION=${DOCKER_VERSION:='18.06'}
DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:='1.22.0'}
NODE_VERSION=${NODE_VERSION:='v11.0.0'}
REDIS_PORT=${REDIS_PORT:='6379'}
REMOTE=${REMOTE:='gitlab'}
BRANCH=${BRANCH:='dev'}
HOME=${HOME:=/home/$(whoami)}
REDELIVRE_PATH=${REDELIVRE_PATH:=$HOME/redelivre}
ADMIN_EMAIL=${ADMIN_EMAIL:="mail@mail.org"}
ADMIN_STORAGE=${ADMIN_STORAGE:="acme.json"}
TG_BOTNAME=${WWW_BOTNAME:=`cat /proc/sys/kernel/random/uuid`}
WWW_BOTNAME=${WWW_BOTNAME:=`cat /proc/sys/kernel/random/uuid`}
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

# install whatsapp repos in prefixed $HOME
for url in "WebWhatsapp-Wrapper";  do
    if [ ! -d $HOME/redelivre/$url ] ; then
        git clone https://www.github.com/lunhg/$url.git $REDELIVRE_PATH/$url
    fi
done

# Configure a .env file
echo "==> Generating .env file at $REDELIVRE_PATH"
for i in "# who is the conductor" \
         "username=$(whoami)" \
         "" \
         "# conductor needs  a place to stand" \
         "apk_dependencies=sudo make git" \
         "NODE_VERSION=$NODE_VERSION" \
         "REDIS_PORT=$REDIS_PORT" \
         "" \
         "# The musicians" \
         "wordpress=$(hostname)" \
         "redis=redis.$(hostname)" \
         "lc=lc.$(hostname)" \
         "mc=mc.$(hostname)" \
         "s3=s3.$(hostname)" \
         "adminer=adminer.$(hostname)" \
         "phpmyadmin=phpmyadmin.$(hostname)" \
         "smtp=smtp.$(hostname)" \
         "elk=elk.$(hostname)" \
         "lb=lb.$(hostname)" \
         "" \
         "# some scores" \
         "postgres_pwd=$(cat /proc/sys/kernel/random/uuid)" \
         "mariadb_root_pwd=$(cat /proc/sys/kernel/random/uuid)" \
         "mariadb_pwd=$(cat /proc/sys/kernel/random/uuid)" \
         "redis_admin=$(cat /proc/sys/kernel/random/uuid)" \
         "s3_key=$(cat /proc/sys/kernel/random/uuid)" \
         "s3_secret=$(cat /proc/sys/kernel/random/uuid)" \
         "" \
         "# Bots " \
         "tg_bot=$TG_BOTNAME.bot.$(hostname)" \
         "tg_api=$TG_BOTNAME.api.$(hostname)" \
         "www_selenium=$WWW_BOTNAME.selenium.$(hostname)" \
         "www_bot=$WWW_BOTNAME.bot.$(hostname)" \
         "# some musicians need aditional configuration" \
         "# assistente api" \
         "tg_api_node_env=production" \
         "tg_api_redis_db=0" \
         "tg_api_jwt_issuer=feathers-plus" \
         "tg_api_session_name=$(cat /proc/sys/kernel/random/uuid)" \
         "tg_api_secret=$(cat /proc/sys/kernel/random/uuid)" \
         "" \
         "# WebWhatsappWrapper" \
         "www_selenium_client=firefox" \
         "www_bot_botname=$WWW_BOTNAME" \
         "www_bot_module=lunhg/WebWhatsapp-Wrapper-bot-foo" \
         "www_bot_plugins=lunhg/WebWhatsapp-Wrapper-plugin-logger:lunhg/WebWhatsapp-Wrapper-plugin-elastic-search"; do \
    echo "==> $i"
    echo $i >> $REDELIVRE_PATH/install/.env ;
done


for i in "telegram_name" "telegram_token" "telegram_admins" "openid_id" "openid_secret" ; do
    if [ ! -n ${!i} ] ; then
        echo "==> ${!i} not declared"
        exit 1
    fi
    if [ -n $i ] ; then
        echo $i'='${!i} >> $REDELIVRE_PATH/install/.env
    fi
done

# Configure traefik
# - Docker options
for i in 's|\$docker.domain|'`hostname`'|g' \
                             's|\$acme.email|'$ADMIN_EMAIL'|g' \
                             's|\$acme.storage|'$ADMIN_STORAGE'|g'; do
    echo "==> Configuring traefik  $i"
    sed -i -e $i $REDELIVRE_PATH/install/lb/traefik.toml
done

# Configure Makefile
for i in 's|\$mc|mc.'`hostname`'|g' ; do \
    echo "==> Configuring install/Makefile  $i"
    sed -i -e $i $REDELIVRE_PATH/install/Makefile
done

# Make redelivre
cd $REDELIVRE_PATH/install
make --makefile $REDELIVRE_PATH/install/Makefile redelivre
cd -
exit 0
