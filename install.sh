
#!/bin/sh

export DOCKER_VERSION='18.03'
export DOCKER_COMPOSE_VERSION='1.22.0'
REMOTE='gitlab'
BRANCH='dev'

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
    && git remote add lunhg https://github.com/lunhg/install.git \
    && git remote add gitlab git@gitlab.com:install/install.git \
    && git fetch --all && git pull $REMOTE $BRANCH \
    && make redelivre
exit 0
