create or replace function cpu_core(
    id bigint,
    core_num integer,
    core_max integer
)
    -- Функция предназначена для распараллеливания SQL запросов
    -- Принимает решение, использовать преданный номер ядра процессора или нет
    -- Пример: WHERE cpu_core(id, 1, 5)
    returns boolean
    stable
    returns null on null input
    parallel safe
    language plpgsql
as
$$
BEGIN
    IF core_num NOT BETWEEN 1 AND 256 THEN
        RAISE EXCEPTION 'Argument core_num must be between 1 and 256, but % given!', core_num;
    ELSIF core_max NOT BETWEEN 1 AND 256 THEN
        RAISE EXCEPTION 'Argument core_max must be between 1 and 256, but % given!', core_max;
    ELSIF core_num > core_max THEN
        RAISE EXCEPTION 'Argument core_num must be <= core_max! Given core_num = %, core_max = %', core_num, core_max;
    END IF;

    RETURN abs(id) % core_max = core_num - 1;
END;
$$;

--TEST
select
    sum(cpu_core(g, 1, 3)::int), --3333
    sum(cpu_core(g, 2, 3)::int), --3334
    sum(cpu_core(g, 3, 3)::int) --3333
from generate_series(1, 10000) as g;

------------------------------------------------------------------------------------------------------------------------
create or replace function cpu_core(
    str text,
    core_num integer,
    core_max integer
)
    -- Функция предназначена для распараллеливания SQL запросов
    -- Принимает решение, использовать преданный номер процессора или нет
    -- Пример: WHERE cpu_core('mike@domain.com', 1, 5)
    returns boolean
    stable
    returns null on null input
    parallel safe
    language plpgsql
as
$$
BEGIN
    IF core_num NOT BETWEEN 1 AND 256 THEN
        RAISE EXCEPTION 'Argument core_num must be between 1 and 256, but % given!', core_num;
    ELSIF core_max NOT BETWEEN 1 AND 256 THEN
        RAISE EXCEPTION 'Argument core_max must be between 1 and 256, but % given!', core_max;
    ELSIF core_num > core_max THEN
        RAISE EXCEPTION 'Argument core_num must be <= core_max! Given core_num = %, core_max = %', core_num, core_max;
    END IF;

    -- https://github.com/rin-nas/postgresql-patterns-library/blob/master/functions/crc32.sql
    RETURN abs(crc32(str)) % core_max = core_num - 1;
END;
$$;

--TEST
select
    sum(cpu_core(g::text, 1, 3)::int), --3307
    sum(cpu_core(g::text, 2, 3)::int), --3358
    sum(cpu_core(g::text, 3, 3)::int) --3335
from generate_series(1, 10000) as g;
