# Rede Livre Install

Installe a `#redelivre` en su computador hoje ! we ♥ DX
[![Join the chat at https://telegram.me/IdentidadeDigital](https://patrolavia.github.io/telegram-badge/chat.png)](https://t.me/RedeLivreOrg)


# Sumário

 - O que é este repositório? 
   - Infraestrutura da `#redelivre`
   - Suíte install
 - Chaves `ssh`
 - Instalação
   - Rápido
     - Configure o arquivo `.env` 
   - Desenvolvedores
    - Clone
    - Crie um arquivo `.env`
 
# O que é este repositório

Este repositório é uma suíte de _softwares_ desenvolvidos pela comunidade #Redelivre.


## Infraestrutura da #RedeLivre

Essa etapa tentar garantir aos desenvolvedores instalarem a Rede Livre em seu próprio computador. Para isso, algumas dependências obrigatórias são necessárias: 
  
  - [Docker](https://rancher.com/docs/rancher/v1.6/en/hosts/#supported-docker-versions) *;
  - [Docker Compose](https://github.com/docker/compose/releases/tag/1.22.0) * ;
  - [Make](https://pt.wikipedia.org/wiki/Make)**.

    * _Esta dependência será verificada durante a execução do script `install.sh`_
    ** _Esta dependência necessita de instalação manual
    

## Suíte install

A Rede Livre é, por enquanto, formada por 3 produtos principais: 
  
  - [Login Cidadão](https://github.com/redelivre/login-cidadao);
  - [Mapas Culturais](https://github.com/hacklabr/mapasculturais); 
  - [Wordpress](https://github.com/redelivre/2.0);
  
De forma adicional, adicionamos no [_branch_](https://git-scm.com/book/pt-br/v1/Ramifica%C3%A7%C3%A3o-Branching-no-Git-O-que-%C3%A9-um-Branch) [dev](https://github.com/lunhg/install/tree/dev) mais 6 produtos, ainda em fase de desenvolvimento, e portanto, sujeitos a possíveis instabilidades e malfuncionamento:

  - [alpine](https://gitlab.com/install/alpine);
    - Imagem customizavel para execução de OS enxuto;
  - [alpine-node](https://gitlab.com/install/alpine-node);
    - Imagem customizavel para execução de OS enxuto com node.js (versão 10);
  - [alpine-redis](https://gitlab.com/install/alpine-redis);
    - Imagem customizável para execução de OS enxuto com redis;
  - [tg-bot](https://gitlab.com/install/tg-bot);
    - Bot telegram em node.js e redis;
    - deve acompanhar [tg-bot-commands](https://gitlab.com/install/tg-bot-commands); 
  - [assistente](https://gitlab.com/install/assistente)
    - API de gerenciamento de  multiplos robos e seus comandos;
    
  - [WebWhatsapp-Wrapper](https://www.github.com/lunhg/WebWhatsapp-Wrapper): customização de um bot whatsapp python rodando com um wrapper de [web.whatsapp.com](https://web.whatsapp.com)

# Chaves `ssh`

Dentre os _softwares_ que constituem a suíte `#redelivre`, alguns estão localizados no [gitlab](https://gitlab.com/install). Estamos seguindo essa abordagem como experiência de uma provável migração.

Para habilitar clonagens e updates com o mínimo de digitação de senhas e maior flexibilidade e segurança para servidores remotos, 
uma chave `ssh` deve ser gerada:

```
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/<user>/.ssh/id_rsa): /home/<user>/.ssh/gitlab
****
```

Copie a chave pública correspondente e crie-a em suas configurações de acesso remoto do [gitlab](https://gitlab.com/profile/keys).

```
$ cat ~/.ssh/gitlab
<chave_publica>
```

Agora habilite  acesso remoto com `ssh`:

```
$ eval $(ssh-agent -s) && ssh-add ~/.ssh/gitlab
Agent pid <pid>
Enter passphrase for /home/<user>/.ssh/gitlab: 
****
```

# Instalação


## Rápido (sujeito a bugs):


Supõe a presença de um do [curl](https://pt.wikipedia.org/wiki/Curl) e de variáveis de ambiente padrão (Maísuculas) e customizáveis/únicas (minúsculas):

  ```
  $ DOCKER_VERSION=<18.06> \
    DOCKER_COMPOSE_VERSION=<1.22.0> \
    NODE_VERSION=<v11.0.0> \
    REDIS_PORT=<6379> \
    REMOTE='<origin|lunhg|gitlab|...> \
    BRANCH='<master|dev|...>' \
    HOME='</home/$(whoami)>' \
    ADMIN_EMAIL='<email@mail.com>' \
    ADMIN_STORAGE='<acme.json>' \
    TG_BOTNAME= '<random-uuid>' \
    WWW_BOTNAME= '<random-uuid>' \
    telegram_token=<token> \
    telegram_admins='12345+23456+345' \
    openid_id=<id> \
    openid_secret=<secret> \
    curl --cookie "_gitlab_session=<meucookiegitlab*>" -o- https://gitlab.com/install/install/raw/dev/install.sh | bash
  ```

__* As variáveis em letras minúsculas atestam variáveis únicas e devem ser mantidas em segredo, de forma que uma forma enxuta do comando acima pode ser__ :

```
  $ ADMIN_EMAIL='<email@mail.com>' \
    telegram_name='<botname>' \
    telegram_token=<token> \
    telegram_admins='12345+23456+345' \
    openid_id=<id> \
    openid_secret=<secret> \
    curl --cookie "_gitlab_session=<meucookiegitlab*>" -o- https://gitlab.com/install/install/raw/dev/install.sh | bash
  ```

__* Um cookie gitlab pode ser encontrado no google chrome; para acessá-lo, esteja logado no gitlab, clique no cadeado verde ao lado da caixa de URI, e procure pelo cookie referente à sua sessão atual gitlab__

## Desenvolvedores

### Clone

Este repositório e adicione forks (opcional para desenvolvedores):


```
# Repositório principal e forks
$ mkdir $HOME/redelivre
$ git clone https://www.github.com/redelivre/install $HOME/redelivre/install
$ git remote add lunhg https://www.github.com/lunhg/install
$ git remote add gitlab git@gitlab.com:install/install.git 
```
### Crie um arquivo .env

O arquivo `.env` será utilizado para flexibilzar instâncias diversas da _suite_. Em outras palavras, permitirá que um mesmo código-fonte poderá gerar, de acordo com diferente variáveis de ambiente do sistema (tal como `hostname`), mas prefixadas de acordo com o _software_ (wordpress, bases de dados, microserverviços , etc...). Exemplos:

  - Wordpress: Página principal, ou `<hostname>`
  - Load Balancer: `lb.<hostname>`
  - Adminer:  `adminer.<hostname>`
  - PHPmyadmin: `phpmyadmin.<hostname>`

```
# Imagens de base
username=<username>
apk_dependencies=sudo make git <adicione!>
NODE_ENV=10.11.0

# Pontos de acesso
redisUI=redis.local
wordpress=wp.local
loginCidadao=lc.local
minio=s3.alarm.local
adminer=adminer.local
phpmyadmin=phpmyadmin.local
smtp=smtp.local
elk=elk.local
traefik=lb.local
tgbot=bot.local
api=api.local

# Robo
TELEGRAM_NAME=R4dar
TELEGRAM_DOMAIN=https://api.local
TELEGRAM_TOKEN=<token>
TELEGRAM_ADMINS=<admin1>+<admin2>+<admin3>...

# API robo telegram
assistente_node_env=production
assistente_port=3000
assistente_redis_host=redis.local
assistente_redis_port=6379
assistente_redis_db=0
assistente_jwt_issuer=<nome_do_issuer>
assistente_jwt_audience=https://api.local
assistente_session_name=<nome_para_sessions>
assistente_secret=<segredo_sessions>
openid_id=<id_openid>
openid_secret=<segredo_openid>

# API Wrapper whatsapp
www_selenium_client=firefox
www_botname=<nome
www_bot_module=<gituser>/WebWhatsapp-Wrapper-<git_bot_class>
www_bot_plugins=<gituser>/WebWhatsapp-Wrapper-plugin-<pluginA>:<gituser>/WebWhatsapp-Wrapper-plugin-<pluginB>:<gituser>/WebWhatsapp-Wrapper-plugin-<pluginC>
```

### Execute `./install.sh`

```
$ chown +x install.sh
$ ./install.sh
```

## Pós- instalção

O _script_ `./install.sh` executará:

- Verificação na máquina local pela existência do _software_ docker (e instalação, se necessário);
- Verificação na máquina local pela existência do _software_ docker-compose (e instalação, se necessário)
- Verificação na máquina local pela existência dos repositórios que incluem a suíte `#redelivre` (_download_, se necessário);
- Execução da receita `redelivre` do programa `Make`, cuja ações são:
  - Compilar imagens customizadas;
  - baixar imagens já distribuídas no [hub.docker.com](https://hub.docker.com/),
  - configurar e subir serviços

### Estimativa de tempo

Esse processo pode levar mais de 120 minutos, dependendo da conexão com a internet e do processador do computador. 

### Urls de acesso

As urls adicionadas ao host estarão funcionando correntamente, se tudo deu certo no build.

``` 
$ make urls
```

### 
Caso ocorra algum problema, execute o comando:


```bash
make status
```

Abaixo um quadro de como devem aparecer os serviços após inicializados:

```bash
$ docker-compose ps
         Name                        Command                  State                                    Ports
------------------------------------------------------------------------------------------------------------------------------------------
rl-install_app_lc_1       docker-php-entrypoint php-fpm    Up             9000/tcp
rl-install_app_mc_1       docker-php-entrypoint php-fpm    Up             9000/tcp
rl-install_app_wp_1       /entrypoint supervisord          Up             9000/tcp
rl-install_elk_1          /usr/bin/supervisord -n -c ...   Up             0.0.0.0:84->80/tcp
rl-install_mariadb_1      docker-entrypoint.sh mysqld      Up             0.0.0.0:3306->3306/tcp
rl-install_memcached_1    docker-entrypoint.sh memcached   Up             0.0.0.0:11211->11211/tcp
rl-install_phpmyadmin_1   /run.sh supervisord -n           Up             80/tcp, 9000/tcp
rl-install_postgres_1     docker-entrypoint.sh postgres    Up             0.0.0.0:5432->5432/tcp
rl-install_redis_1        docker-entrypoint.sh redis ...   Up             0.0.0.0:6379->6379/tcp
rl-install_s3_1           /usr/bin/docker-entrypoint ...   Up (healthy)   0.0.0.0:9000->9000/tcp
rl-install_smtp_1         MailHog                          Up             0.0.0.0:1025->1025/tcp, 0.0.0.0:8025->8025/tcp
rl-install_traefik_1      /traefik                         Up             0.0.0.0:443->443/tcp, 0.0.0.0:80->80/tcp, 0.0.0.0:8080->8080/tcp
rl-install_web_lc_1       nginx                            Up             0.0.0.0:436->443/tcp, 0.0.0.0:83->80/tcp
rl-install_web_mc_1       nginx                            Up             0.0.0.0:435->443/tcp, 0.0.0.0:82->80/tcp
rl-install_web_wp_1       /bin/sh -c envsubst $VIRT ...    Up             0.0.0.0:434->443/tcp, 0.0.0.0:81->80/tcp
```

Dessa forma vai conseguir visualizar em qual parte do build você teve problemas.

## Novos serviços

Caso queira adicionar um novo serviço na infraestrutura da rede livre, [crie um pull request](https://help.github.com/articles/creating-a-pull-request/).

## Comandos úteis

```bash
# bash commands
$ docker-compose exec app_lc bash

# Composer (e.g. composer update)
$ docker-compose exec app_lc composer update

# SF commands (Tips: there is an alias inside app_lc container)
$ docker-compose exec app_lc php /var/www/html/app/console cache:clear # Symfony2
$ docker-compose exec app_lc php /var/www/html/bin/console cache:clear # Symfony3
# Same command by using alias
$ docker-compose exec app_lc bash
$ sf cache:clear

# Retrieve an IP Address (here for the nginx container)
$ docker inspect --format '{{ .NetworkSettings.Networks.dockersymfony_default.IPAddress }}' $(docker ps -f name=web_lc -q)
$ docker inspect $(docker ps -f name=web_lc -q) | grep IPAddress

# MySQL commands
$ docker-compose exec mariadb mysql -uroot -p

# F***ing cache/logs folder
$ sudo chmod -R 777 app/cache app/logs # Symfony2
$ sudo chmod -R 777 var/cache var/logs var/sessions # Symfony3

# Check CPU consumption
$ docker stats $(docker inspect -f "{{ .Name }}" $(docker ps -q))

# Delete all containers
$ docker rm $(docker ps -aq)

# Delete all images
$ docker rmi $(docker images -q)

# Delete all "<tagged>" images
$ docker rmi $(docker images | grep "^<tagged>" | awk "{ print $3}")
```
