# Local Data Platform

Целью данного проекта является развитие концепции локального тестирования отдельных компонентов и тестирование взаимодействия этих компонентов друг с другом в их минимальной конфигурацией для k8s на примере платформы данных.

Содержание:
- [Структура проекта](#Структура-проекта)
- [Как пользоваться](#Как-пользоваться)
- [Как добавить новый компонент](#Как-добавить-новый-компонент)


## Структура проекта
Компоненты сгрупированны по их смысловому значению:

[catalog](catalog) - содержит компоненты технических каталогов данных

[engine](engine) - содержит вычислительные компоненты

[gitlab](gitlab/gitlab/) - helm chart gitlab

[jupyterhub](jupyterhub/jupyterhub/) - helm chart jupyterhub

[keycloakx](keycloakx/keycloakx/) - helm chart keycloakx

[orchestrator](orchestrator) - содержит компоненты оркестраторов

[storage](storage) - содержит компоненты системы хранения

[utils](utils) - содержит инструменты для предварительной настройки локального кластера

Каждый компонент представляет из себя helm chart проект взятый с официальных ресурсов и набор файлов:

`keycloak-export-<название компонента>-client-settings.json` - хранит настройки `client` для keycloak. Импортируются через `clients > Import client`

`keycloak-export-<название компонента>-client-authorization-settings.json` - хранит настройки `authorization` для keycloak. При необходимости активируются в блоке `Capability config` для `client` и импортируются во вкладке `Authorization` (файл создавать при необходимости)

`configuring.sh` - хранит конфигурацию нужную для компонента перед установкой (файл создавать при необходимости)

`install.sh` - установка компонента в кластер

`uninstall.sh` - удаление компонента из кластера

`upgrade.sh` - обновление компонента в кластере, после внесения изменений в его конфигурацию

`values-minimum.yaml` - минимальная конфигурация helm chart необходимая для корректной работы компонента

## Как пользоваться
1) Прежде всего нужно отправлять запросы с доменом `*.local.me` на `127.0.0.1:2053`. В данном случае на уровне MacOS необходимо выполнить следующие действия:
    ```
    # 1. Create the resolver directory (requires root once)
    sudo mkdir -p /etc/resolver

    # 2. Add resolver config pointing *.local.me to a local DNS responder on port 2053
    sudo tee /etc/resolver/local.me <<EOF
    nameserver 127.0.0.1
    port 2053
    EOF

    # 3. Flush macOS DNS cache to activate immediately
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder

    # 4. Verify resolution with scutil
    scutil --dns | grep -A 5 "resolver #.*(domain: local.me)"
    ```
    Адрес `127.0.0.1:2053` прослушивается DNS-сервером [dnsmasq](utils/dnsmasq/), который необходимо запустить. Он в свою очередь перенаправляет запросы на локальный кластер, находящийся по адресу `192.168.139.2`.
    
2) Установить содержимое [utils](utils)

    [setup-tls.sh](utils/certs/setup-tls.sh) - идемотентно выполнит необходимые действия для tls соединения с компонентами

    [metrics-server](utils/metrics-server/) - нужно для отображения утилизируемых ресурсов локальным кластером k8s

    [nginx-ingress](utils/nginx-ingress/) - это reverse proxy для всего локального кластера k8s

3) Установить [keycloak](keycloakx/install.sh) и импортировать настройки `keycloak-export-<название компонента>-client-settings.json` используемого компонента для `client`, дополнительно, **при необходимости**, активировать `Authorization` в блоке `Capability config` и импортировать во вкладке `Authorization` соотвествующие настройки `keycloak-export-<название компонента>-client-authorization-settings.json`. Для пользователя admin задать email `admin@example.com` и выставить `Email verified: On`

4) Установить необходимые для работы компопненты

## Как добавить новый компонент
1) Необходимо найти и скачать соответствующий helm chart проект и разместить его внутри директории компонента с таким же названием
2) Вынести настройки, кофигурацию и скрипты установки в соотвествующие файлы внутри директории компонента рядом с директорией проекта:

    `keycloak-export-<название компонента>-client-settings.json`
    
    `keycloak-export-<название компонента>-client-authorization-settings.json` 

    `configuring.sh`

    `install.sh`

    `uninstall.sh`

    `upgrade.sh`

    `values-minimum.yaml`

3) Если требуется доступ извне локального кластера, необходимо в [setup-tls.sh](utils/certs/setup-tls.sh) добавить в переменную `DOMAINS` новый домен и добавить в переменную `NAMESPACES` новый namespace, т. к. каждый компонент размещается в своём. После чего выполнить bash скрипт
    > [!WARNING]
    > При использовании `*` в доменах, следует помнить что `*` в имени сертификата заменяет строго одну метку (одно слово между точками) согласно [RFC 6125](https://www.rfc-editor.org/info/rfc6125/)

4) Если компонент использует дополнительные хранилища типа ORDBMS (Object-Relational Database Management System) и/или S3, лучше настроить на единые хранилища [postgresql](storage/postgresql/) и [minio](storage/minio/), добавить в `configuration.sh` идемпотентное создание database и bucket соответственно. В качестве примера можно использовать [configuration.sh](gitlab/configuring.sh)