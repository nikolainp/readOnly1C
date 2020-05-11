## Установка PGAgent

Добавляем [репозитории PostgreSQL](https://yum.postgresql.org/repopackages.php)
```shell
$ sudo yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
```

Устанавлниваем pgagent
```shell
$ sudo yum install pgagent_11
$ systemctl status pgagent_11
  ● pgagent_11.service - PgAgent for PostgreSQL 11
    Loaded: loaded (/usr/lib/systemd/system/pgagent_11.service; disabled; vendor preset: disabled)
    Active: inactive (dead)
```

Изменяем параметры
```shell
$ more  /etc/pgagent/pgagent_11.conf
DBNAME=postgres
DBUSER=postgres
DBHOST=127.0.0.1
DBPORT=5433
LOGFILE=/var/lib/pgsql/11/proxy/pg_log/pgagent_11.log
```

Для подключения через сокет необходимо поправить параметры запуска pgagent.
Все праметры запуска после флага -s - это "connection string" от [libpq](`https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PARAMKEYWORDS).
И от, что них упомянут "hostaddr", блокирует использование сокетов. 
Поэтому создаём файл /etc/systemd/system/pgagent_11.service

```ini
[Unit]
Description=PgAgent for PostgreSQL 11
After=syslog.target
After=network.target

[Service]
Type=forking

User=postgres
Group=postgres

# Location of the configuration file
EnvironmentFile=/etc/pgagent/pgagent_11.conf

# Where to send early-startup messages from the server (before the logging
# options of pgagent.conf take effect)
# This is normally controlled by the global default set by systemd
# StandardOutput=syslog

# Disable OOM kill on the postmaster
OOMScoreAdjust=-1000

ExecStart=/usr/bin/pgagent_11 -s ${LOGFILE} dbname=${DBNAME} user=${DBUSER} port=${DBPORT}
KillMode=mixed
KillSignal=SIGINT

Restart=on-failure

# Give a reasonable amount of time for the server to start up/shut down
TimeoutSec=300

[Install]
WantedBy=multi-user.target
```

Если, требуется просто изменить часть парамтеров запуска, то лучше создать файл с модификацией настроек. К сожалению, с параметром ExecStart так не получится.

```shell
$ sudo mkdir /etc/systemd/system/pgagent_11.service.d/
$ more /etc/systemd/system/pgagent_11.service.d/custom.conf
[Service]
User=postgres
Group=postgres
```

Запускаем сервис
```shell
$ sudo systemctl enable pgagent_11
Created symlink from /etc/systemd/system/multi-user.target.wants/pgagent_11.service to /etc/systemd/system/pgagent_11.service
$ sudo systemctl start pgagent_11
```

Подключаем расширение в базе postgres и проверяем, что в базе есть plpgsql.
```sql
$ sudo -u postgres psql -p 5433 -U postgres -d postgres
psql (11.5)
Type "help" for help.

postgres=# CREATE EXTENSION pgagent;
CREATE EXTENSION
postgres=# CREATE LANGUAGE plpgsql;
ERROR:  language "plpgsql" already exists
```


