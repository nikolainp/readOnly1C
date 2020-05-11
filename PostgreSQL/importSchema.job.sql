DO $$
DECLARE
    jid integer;
    scid integer;
BEGIN
    -- Creating a new job
    INSERT INTO pgagent.pga_job(
        jobjclid, jobname, jobdesc, jobhostagent, jobenabled
    ) VALUE (
        1::integer, 'importSchema'::text, ''::text, ''::text, true
    ) RETURNING jobid INTO jid;

    -- Steps
    -- Inserting a step (jobid: NULL)
    INSERT INTO pgagent.pga_jobstep (
        jstjobid, jstname, jstenabled, jstkind,
        jstconnstr, jstdbname, jstonerror,
        jstcode, jstdesc
    ) VALUES (
        jid, 'main'::text, true, 's'::character(1),
        ''::text, 'test'::name, 'f'::character(1),
        'BEGIN
        IF needImportSchema() THEN
            call importSchema();
        END IF; 
    END;'::text, ''::text
    ) ;

    -- Schedules
    -- Inserting a schedule
    INSERT INTO pgagent.pga_schedule(
        jscjobid, jscname, jscdesc, jscenabled,
        jscstart,     jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths
    ) VALUES (
        jid, 'main'::text, ''::text, true,
        '2020-05-10T16:39:59+03:00'::timestamp with time zone, 
        -- Minutes
        ARRAY[true,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]::boolean[],
        -- Hours
        ARRAY[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]::boolean[],
        -- Week days
        ARRAY[false,false,false,false,false,false,false]::boolean[],
        -- Month days
        ARRAY[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]::boolean[],
        -- Months
        ARRAY[false,false,false,false,false,false,false,false,false,false,false,false]::boolean[]
    ) RETURNING jscid INTO scid;
END
$$;
