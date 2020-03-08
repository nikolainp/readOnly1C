### Создание запросов
---------------------

#### Запросы на импорт схемы

```sql
select 'IMPORT FOREIGN SCHEMA public LIMIT TO ( ' || string_agg(tablename, ', ') || ') FROM SERVER standby_server INTO v8system;' from pg_tables where not tableowner = 'postgres' \gexec
```

```sql
select 'IMPORT FOREIGN SCHEMA public EXCEPT ( ' || string_agg(tablename, ', ') || ') FROM SERVER standby_server INTO public;' from pg_tables where not tableowner = 'postgres' \gexec
```


#### Запрос на удаление предыдущих данных

```sql
select 'TRUNCATE ' || string_agg(tablename, ', ') || ';' from pg_tables where not tableowner = 'postgres' \gexec
```

#### Запросы на вставку данных

```sql
select 'INSERT INTO ' || tablename || ' SELECT * FROM v8system.' || tablename || ';' from pg_tables where not tableowner = 'postgres' \gexec
```


