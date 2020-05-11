CREATE OR REPLACE FUNCTION needImportSchema()
RETURNS BOOLEAN 
LANGUAGE plpgsql
AS $$
DECLARE 
    schema_public text;
    schema_v8system text;

    newTime timestamp without time zone;
    oldTime timestamp without time zone;
BEGIN

    schema_public := 'public';
    schema_v8system := 'v8system';

    -- check configuration

    EXECUTE format('SELECT MAX(modified) FROM %I.config;', schema_public)
    INTO oldTime;  

    EXECUTE format('SELECT MAX(modified) FROM %I.config;', schema_v8system)
    INTO newTime;  

    IF oldTime != newTime THEN RETURN True; END IF;


    -- check configuration extensions

    EXECUTE format('SELECT MAX(modified) FROM %I.configcas;', schema_public)
    INTO oldTime;  

    EXECUTE format('SELECT MAX(modified) FROM %I.configcas;', schema_v8system)
    INTO newTime;  

    IF oldTime != newTime THEN RETURN True; END IF;


    RETURN False;
END;
$$;

CREATE OR REPLACE PROCEDURE importSchema()
LANGUAGE plpgsql
AS $$
DECLARE
    servername text;
    schema_public text;
    schema_v8system text;

    v8tables text;
    rec record;
BEGIN
    
    servername := 'secondary';
    schema_public := 'public';
    schema_v8system := 'v8system';

    -- check extension
    IF EXISTS (
        SELECT true FROM pg_extension
        WHERE extname = 'postgres_fdw'
    ) THEN
        raise notice 'Extension postgres_fdw: exists';
    ELSE
        raise exception 'Extension postgres_fdw: not found';
    END IF;

    -- check foreign server
    IF EXISTS (
        SELECT true FROM information_schema.foreign_servers 
        WHERE foreign_server_name = servername
    ) THEN
        raise notice 'Foreign server %: exists', servername;
    ELSE
        raise exception 'Foreign server %:  not found', servername;
    END IF;

    -- check schema
    IF EXISTS (
        SELECT true FROM information_schema.schemata 
        WHERE schema_name = schema_v8system
    ) THEN
        raise notice 'Schema %: exists', schema_v8system;
    ELSE
        raise exception 'Schema %:  not found', seschema_v8systemrver;
    END IF;


    -- list current 1C:Enterprise system tables
    SELECT string_agg(table_name, ', ') INTO v8tables
    FROM information_schema.tables
    WhERE table_schema = schema_public AND table_type = 'BASE TABLE';


    -- drop old foreign tables
    raise notice 'Drop old foreign tables';
    FOR rec IN
        SELECT 
            foreign_table_schema as schemaname
            , foreign_table_name as tablename
        FROM information_schema.foreign_tables
        WhERE foreign_table_schema = schema_v8system
            OR foreign_table_schema = schema_public
    LOOP
        EXECUTE 'DROP FOREIGN TABLE IF EXISTS ' || rec.schemaname || '.' || rec.tablename;
    END LOOP;

    -- create current foreign tables
    raise notice 'Create new foreign tables';
    EXECUTE 'IMPORT FOREIGN SCHEMA public LIMIT TO (' || v8tables || ') FROM SERVER ' 
        || servername || ' INTO ' || schema_v8system;
    EXECUTE 'IMPORT FOREIGN SCHEMA public EXCEPT ( ' || v8tables || ') FROM SERVER '
        || servername || ' INTO ' || schema_public;

    -- update 1C:Entreprise metadata
    raise notice 'Update metadata';
    FOR rec IN
        SELECT foreign_table_name as tablename FROM information_schema.foreign_tables WhERE foreign_table_schema = schema_v8system
    LOOP
        EXECUTE 'TRUNCATE ' || schema_public || '.' || rec.tablename;
        EXECUTE 'INSERT INTO ' || schema_public || '.' || rec.tablename || 
            ' SELECT * FROM ' || schema_v8system || '.' || rec.tablename;
    END LOOP;

END;
$$;

CREATE OR REPLACE PROCEDURE runUpdateSchema()
LANGUAGE plpgsql
AS $$
BEGIN
    IF (SELECT needImportSchema()) THEN
        CALL importSchema();
    END IF; 
END;
$$;
