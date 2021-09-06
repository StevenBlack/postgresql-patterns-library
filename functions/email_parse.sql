
create function email_parse(email text) returns text[]
    PARALLEL SAFE
    LANGUAGE SQL
    STABLE
    RETURNS NULL ON NULL INPUT
as
$BODY$

    -- парсит email, возвращает массив из 2-х элементов, в первом имя пользователя, а во втором домен
    select regexp_match(email, '^(.+)@([^@]+)$', '');

$BODY$;

select email_parse('my@email@gmail.com.uk');
