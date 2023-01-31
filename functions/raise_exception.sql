--Inspired by https://hakibenita.com/future-proof-sql

--Documentation: https://postgrespro.ru/docs/postgresql/14/plpgsql-errors-and-messages

create or replace function raise_exception(
    value anyelement,
    message text default 'Unhandled value',
    detail  text default null,
    hint    text default 'See value in detail as JSON',
    errcode text default 'raise_exception',
    "column"     text default null,
    "constraint" text default null,
    "table"      text default null,
    "schema"     text default null
)
    returns boolean
    immutable
    --strict -- returns null if any parameter is null
    parallel safe
    language plpgsql
    set search_path = ''
as
$$
begin
    raise exception using
        message = coalesce(message, 'Unhandled value'),
        detail  = coalesce(detail, coalesce(to_json(value), 'null'::json)::text),
        hint    = coalesce(hint, 'See value in detail as JSON'),
        errcode = coalesce(errcode, 'raise_exception'),
        column      = coalesce("column", ''),
        constraint  = coalesce("constraint", ''),
        table       = coalesce("table", ''),
        schema      = coalesce("schema", ''),
        datatype    = pg_typeof(value);
end;
$$;

--TEST
do $$
    DECLARE
        i int not null default 0;

        exception_sqlstate text;
        exception_message text;
        exception_context text;
        exception_detail text;
        exception_hint text;
        exception_datatype text;
    BEGIN
        LOOP
            BEGIN -- subtransaction SAVEPOINT
                i := i + 1;
                if i = 1 then
                    perform raise_exception(null::int);
                elsif i = 2 then
                    perform raise_exception(1234567890, null);
                elsif i = 3 then
                    perform raise_exception('ABCDE'::text, null, null);
                elsif i = 4 then
                    perform raise_exception(json_build_object('id', 123), null, null, null);
                elsif i = 5 then
                    perform raise_exception('1d2h3m4s'::interval, null, null, null, null);
                elsif i = 6 then
                    perform raise_exception(now(), null, null, null, null, null);
                elsif i = 7 then
                    perform raise_exception(true, null, null, null, null, null, null);
                elsif i = 8 then
                    perform raise_exception(-123.456, null, null, null, null, null, null, null);
                elsif i = 9 then
                    perform raise_exception(point(0, 0), null, null, null, null, null, null, null, null);
                end if;
                EXIT WHEN true;
            EXCEPTION WHEN others THEN
                GET STACKED DIAGNOSTICS --https://postgrespro.ru/docs/postgresql/14/plpgsql-control-structures#PLPGSQL-ERROR-TRAPPING
                    exception_sqlstate := RETURNED_SQLSTATE,
                    exception_message  := MESSAGE_TEXT,
                    exception_context  := PG_EXCEPTION_CONTEXT,
                    exception_detail   := PG_EXCEPTION_DETAIL,
                    exception_hint     := PG_EXCEPTION_HINT,
                    exception_datatype := PG_DATATYPE_NAME;

                RAISE NOTICE '====== % ======', i;
                RAISE NOTICE '* exception_sqlstate = %', exception_sqlstate;
                RAISE NOTICE '* exception_message = %', exception_message;
                RAISE NOTICE '* exception_context = %', exception_context;
                RAISE NOTICE '* exception_detail = %', exception_detail;
                RAISE NOTICE '* exception_hint = %', exception_hint;
                RAISE NOTICE '* exception_datatype = %', exception_datatype;
            END;
        END LOOP;
    END;
$$;

/*
--explain
select i
from generate_series(1, 3000000) as x(i)
where case when clock_timestamp() - statement_timestamp() < '1s'
           then true
           else raise_exception(i)
      end
order by i;
*/
