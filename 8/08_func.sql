gcloud beta compute --project=celtic-house-266612 instances create postgres4 --zone=us-central1-a --machine-type=e2-medium --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=933982307116-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image-family=ubuntu-2404-lts-amd64 --image-project=ubuntu-os-cloud --boot-disk-size=50GB --boot-disk-type=pd-ssd --boot-disk-device-name=postgres4 --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any

gcloud compute ssh postgres4

sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-17 unzip atop iotop

gcloud compute instances list


-- откроем доступ и подключимся через DBeaver
-- listener
sudo nano /etc/postgresql/17/main/postgresql.conf
-- pg_hba
sudo nano /etc/postgresql/17/main/pg_hba.conf
-- password admin#123$
sudo -u postgres psql
\password
-- рестарт сервера
sudo pg_ctlcluster 17 main stop && sudo pg_ctlcluster 17 main start


SELECT current_database();

-- вывод notice в DBeaver
shift+ctrl+o  
/*
  тоже комментарий
*/

-- простые примеры 
-- язык SQL
drop function if exists add;
CREATE FUNCTION add(integer, integer) RETURNS integer
    AS 'SELECT $1 + $2;'
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;

SELECT add(3,4);
SELECT * from add(3,4);

SELECT add(null,20);

-- если дефолтное значение и вызов с NULL INPUT
drop function add2;
CREATE or replace FUNCTION add2(integer, integer default 42) RETURNS integer
    AS 'SELECT $1 + $2;'
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;

SELECT add2(20, null);
SELECT add2(20);

-- Функция увеличения целого числа на 1, использующая именованный аргумент, на языке PL/pgSQL:
-- обратим внимание на OR REPLACE
CREATE OR REPLACE FUNCTION increment(i integer) RETURNS integer AS $$
BEGIN
    RETURN i + 1;
END;
$$ LANGUAGE plpgsql;

SELECT increment(3);


-- Функция, возвращающая запись с несколькими выходными параметрами:
CREATE FUNCTION dup(in int, out f1 int, out f2 text) AS $$ 
    SELECT $1, CAST($1 AS text) || ' is text' 
$$
LANGUAGE SQL;

SELECT * FROM dup(42);

-- примеры объявления параметров
CREATE OR REPLACE FUNCTION instr(varchar, integer) RETURNS integer AS $$
DECLARE
    v_string ALIAS FOR $1;
    index ALIAS FOR $2;
BEGIN
    -- вычисления, использующие v_string и index
    	return v_string + index;
--	return v_string::int + index;
END;
$$ LANGUAGE plpgsql;

select instr('1',2);

CREATE FUNCTION sales_tax2(subtotal real, OUT tax real) AS $$
BEGIN
    tax := subtotal * 0.06;
END;
$$ LANGUAGE plpgsql;

select sales_tax2(200);


-- как вернуть значение для каждой строчки из таблицы
create table sales(summa decimal);
insert into sales values (100);

SELECT * FROM sales;
SELECT sales_tax2(cast(sales.summa as real)) FROM sales;


-- несколько выходных параметров
drop function if exists sum_n_product;
CREATE FUNCTION sum_n_product(x int, IN y int, OUT sum int, OUT prod int) AS $$
BEGIN
    sum := x + y;
    prod := x * y;
END;
$$ LANGUAGE plpgsql;

SELECT sum_n_product(200, 400);
SELECT * from sum_n_product(200, 400);
SELECT prod from sum_n_product(200, 400);

-- пример переменной inout
drop function if exists return_inout;
CREATE or replace function return_inout(inout result1 int, out result2 int)
as $$
begin
    result2 := result1;  
    result1 := 1;
return;
end
$$ language plpgsql; 

SELECT return_inout(6);
select * from return_inout(6);


-- вернем таблицу
drop TABLE if exists sales;
CREATE TABLE sales (itemno int, price int, quantity int);
INSERT INTO sales VALUES (1,10,100),(2,20,200);


drop function if exists extended_sales;
CREATE or replace FUNCTION extended_sales(p_itemno int)
RETURNS TABLE(quantity int, total int) AS $$
BEGIN
    RETURN QUERY SELECT s.quantity as a, s.quantity * s.price as b FROM sales s
                 WHERE s.itemno = p_itemno;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM sales;
SELECT extended_sales(1);
SELECT * from extended_sales(1);

SELECT extended_sales(itemno) from sales;


-- использование составного типа
CREATE TYPE currency AS (
    amount numeric,
    code   text
);
drop table if exists transactions;
CREATE TABLE transactions(
    account_id   integer,
    debit        currency,
    credit       currency,
    date_entered date DEFAULT current_date
);

-- Значения составного типа можно формировать либо в виде строки, 
-- внутри которой в скобках перечислены значения
INSERT INTO transactions VALUES(1, NULL, '(7000.00,"RUR")');

-- Либо с помощью табличного конструктора ROW:
INSERT INTO transactions VALUES(2, ROW(350.00,'RUR'), NULL);

-- Если составной тип содержит более одного поля, то слово ROW можно опустить:
INSERT INTO transactions VALUES(3, (20.00,'RUR'), NULL);

SELECT * FROM transactions;


-- Функция для работы с составным типом:

CREATE TYPE dup_result AS (f1 int, f2 text);

CREATE or replace FUNCTION dup2(int) RETURNS dup_result
    AS $$ SELECT $1, CAST($1 AS text) || ' is text' $$
    LANGUAGE SQL;

SELECT * FROM dup2(42);
SELECT dup2(42);




-- Дальше мы можем создать функции для работы с этим типом. Например:
CREATE FUNCTION multiply(factor numeric, cur currency) RETURNS currency AS $$
    SELECT ROW(factor * cur.amount, cur.code)::currency;
$$ IMMUTABLE LANGUAGE SQL;

select * from transactions;
SELECT account_id, multiply(2,debit), multiply(2,credit), date_entered FROM transactions;

-- Хотелось бы, чтобы такая функция не превращала неопределенное значение в пустую запись. 
-- Для этого можно либо явно выполнить необходимую проверку, либо указать для функции свойство STRICT:
ALTER FUNCTION multiply(numeric, currency) STRICT;

-- Мы можем даже определить оператор умножения:
CREATE OPERATOR * (
    PROCEDURE = multiply,
    LEFTARG = numeric,
    RIGHTARG = currency
);

-- И использовать его в выражениях:
SELECT account_id, 1.2 * debit, 2 * credit, date_entered FROM transactions;


SELECT account_id, debit * 2, date_entered FROM transactions;
CREATE FUNCTION multiply(cur currency, factor numeric) RETURNS currency AS $$
    SELECT ROW(factor * cur.amount, cur.code)::currency;
$$ IMMUTABLE LANGUAGE SQL;

CREATE OPERATOR * (
    PROCEDURE = multiply,
    LEFTARG = currency,
    RIGHTARG = numeric
);

SELECT account_id, debit * 2, 2 * credit, date_entered FROM transactions;



-- Составной тип как тип строки таблицы
-- При создании таблицы неявно создается одноименный тип 
drop table if exists seats cascade;
CREATE TABLE seats(
    line   text,
    number integer,
    vip    boolean
);


-- Команда \dT "прячет" такие неявные типы, но при желании их можно увидеть непосредственно в таблице pg_type.
-- можно объявить как RETURNS seats:
drop function make_seat;
CREATE FUNCTION make_seat(line text, number integer, vip boolean DEFAULT false) RETURNS seats AS $$
SELECT ROW(line, number, vip)::seats;
$$ IMMUTABLE LANGUAGE SQL;

SELECT make_seat('A',32);

-- Функцию можно вызывать не только в списке выборки запроса или в условиях, как часть выражения. 
-- К функции можно обратиться и в предложении FROM, как к таблице:
SELECT * FROM make_seat('A',32);
-- при этом постгрес знает имена и типы возвращаемых данных


-- вычисляемые поля
CREATE FUNCTION no(seat seats) RETURNS text AS $$
    SELECT seat.line || seat.number;
$$ IMMUTABLE LANGUAGE SQL;

SELECT no(ROW('A',32,false));
INSERT INTO seats VALUES ('A',32,true), ('B',3,false), ('C',27,false);
SELECT s.line, s.number, no(s.*) FROM seats s;

-- Синтаксисом допускается обращение к функции как к столбцу таблицы (и наоборот, к столбцу как к функции).
SELECT s.line, number(s), s.no FROM seats s;

-- number(s) <-> s.number
-- s.no <-> no(s.*)
SELECT s.line, number(s), s.no FROM seats s; <==> SELECT s.line, s.number, no(s.*) FROM seats s;

-- если совпадает имя поля и имя функции
CREATE FUNCTION line(seat seats) RETURNS text AS $$
    SELECT seat.line || seat.number;
$$ IMMUTABLE LANGUAGE SQL;

SELECT s.line, number(s) FROM seats s;
SELECT s.line, number(s), line(s) FROM seats s;
SELECT s.line, number(s), line(s.*) FROM seats s;

-- Значения составных типов можно сравнивать между собой. Это происходит поэлементно 
-- (примерно так же, так строки сравниваются посимвольно):
SELECT * FROM seats s WHERE s < make_seat('B',52);


-- RECORD
-- еще один вариант - объявить функцию как возвращающую псевдотип record, который обозначает составной тип "вообще", без уточнения его структуры.
DROP FUNCTION make_seat(text, integer, boolean);
CREATE FUNCTION make_seat(line text, number integer, vip boolean DEFAULT false) RETURNS record AS $$
SELECT line, number, vip;
$$ IMMUTABLE LANGUAGE SQL;

SELECT make_seat('A',42);

-- Но вызвать такую функцию в предложении FROM уже не получится, поскольку возвращаемый составной тип не просто анонимный,
-- но и количество и типы его полей заранее (на этапе разбора запроса) неизвестны:

SELECT * FROM make_seat('A',42);

-- В этом случае при вызове функции структуру составного типа придется уточнить:
SELECT * FROM make_seat('A',42) AS seats(line text, number integer, vip boolean);

-- вернуть множество анонимных записей
DROP FUNCTION if exists make_seat_setof(text, integer, boolean);
CREATE FUNCTION make_seat_setof(line text, number integer, vip boolean DEFAULT false) RETURNS SETOF record AS $$
begin
	return query SELECT line, number, vip, vip;
	return query select line, number, vip, vip;
end;
$$ LANGUAGE plpgSQL;
SELECT make_seat_setof('A',42);

-- одна проблема - нужно все равно указать типы при разборе анонимной записи
SELECT * FROM make_seat_setof('A',42) AS seats(line text, number integer, vip boolean, vip2 boolean);

-- Ещё один способ вернуть несколько столбцов — применить функцию TABLE:

CREATE or replace FUNCTION dup3(int) RETURNS TABLE(f1 int, f2 text)
    AS $$ SELECT $1, CAST($1 AS text) || ' is text' $$
    LANGUAGE SQL;

SELECT * FROM dup3(42);

-- Однако пример с TABLE отличается от предыдущих, так как в нём функция на самом деле возвращает не одну, а набор записей.

SELECT f1 FROM dup3(42);

-- SETOF
-- второй вариант вернуть несколько строк
-- Напишем функцию, которая вернет все места в зале заданного размера (и ближняя половина зала будет считаться vip-зоной).
CREATE FUNCTION make_seats(max_line integer, max_number integer) RETURNS SETOF seats AS $$
    SELECT chr(line+64), number, line <= max_line/2
    FROM generate_series(1,max_line) AS lines(line), generate_series(1,max_number) AS numbers(number);
$$ IMMUTABLE LANGUAGE SQL;

-- поименованная передача параметра
SELECT * FROM make_seats(max_number => 6, max_line => 12);






-- использование переменной VARIADIC массив с переменным набором аргументов
-- https://www.postgresql.org/docs/current/functions-srf.html
-- https://stackoverflow.com/questions/10674735/in-postgresql-what-is-gi-in-FROM-generate-subscripts1-1-gi
CREATE or replace FUNCTION mleast(VARIADIC arr numeric[]) RETURNS numeric AS $$
    SELECT min($1[i]) FROM generate_subscripts($1, 1) g(i);
$$ LANGUAGE SQL;

SELECT mleast(100 , 50, -1, 5, 4.4);


-- PERFORM
-- Если результат запроса не нужен, можно не использовать фиктивные переменные, а заменить SELECT на PERFORM.
CREATE FUNCTION do_something() RETURNS void AS $$
BEGIN
    RAISE NOTICE 'Что-то сделалось.';
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    PERFORM do_something();
END;
$$;



-- перегрузка
-- Напишем функцию, возвращающую большее из двух целых чисел
-- (Похожая функция есть в SQL и называется greatest, но мы сделаем ее сами)

CREATE FUNCTION maximum(a integer, b integer) RETURNS integer AS $$
SELECT CASE WHEN a > b THEN a ELSE b END;
$$ LANGUAGE SQL;


-- Проверим:
SELECT maximum(100,200);

-- Допустим, мы решили сделать аналогичную функцию для трех чисел. 
-- Благодаря перегрузке, не надо придумывать для нее какое-то новое название:

CREATE FUNCTION maximum(a integer, b integer, c integer) RETURNS integer AS $$
SELECT CASE WHEN a > b THEN maximum(a,c) ELSE maximum(b,c) END;
$$ LANGUAGE SQL;

-- Теперь у нас две функции с одним именем, но разным числом параметров:
\df maximum

-- И обе работают:
SELECT maximum(10,20), maximum(10,20,-100);

-- Пусть наша функция работает не только для целых чисел, но и для вещественных.
CREATE FUNCTION maximum(a real, b real) RETURNS real AS $$
    SELECT CASE WHEN a > b THEN a ELSE b END;
$$ LANGUAGE SQL;

-- \df maximum
SELECT maximum(10,20), maximum(3.1,3.2);




-- Полиморфные функции
-- Здесь нам поможет полиморфный тип anyelement.
-- Удалим все три наши функции и затем создадим новую:

DROP FUNCTION maximum(integer, integer);
DROP FUNCTION maximum(integer, integer, integer);
DROP FUNCTION maximum(real, real);

CREATE FUNCTION maximum(a anyelement, b anyelement) RETURNS anyelement AS $$
    SELECT CASE WHEN a > b THEN a ELSE b END;
$$ LANGUAGE SQL;

SELECT maximum(1,2);

-- попробуем сравнить строки
SELECT maximum('C','B');
-- Получится???


-- Увы, нет. В данном случае строковые литералы могут быть типа char, varchar, text - 
-- конкретный тип нам неизвестен. Но можно применить явное приведение типов:
SELECT maximum('C'::text,'B'::text);

-- Еще пример с другим типом:
SELECT maximum(now(), now() + interval '1 day');

-- Важно, чтобы типы обоих параметров совпадали, иначе будет ошибка:
SELECT maximum(1,'C');


create table test_numeric2(n numeric(38,20));



-- Процедуры
-- простая процедура
DROP TABLE IF EXISTS tbl;
CREATE TABLE tbl (i int);

CREATE or replace PROCEDURE insert_data(a integer, b integer)
LANGUAGE SQL
AS $$
INSERT INTO tbl VALUES (a);
INSERT INTO tbl VALUES (b);
$$;


-- вызовем процедуру используя CALL
CALL insert_data(1, 2);

SELECT * FROM tbl;

-- В код PL/pgSQL можно встраивать команды SQL. Наверное, наиболее часто используемый вариант - 
-- команда SELECT, возвращающая одну строку. Пример, который не получилось бы выполнить 
-- с помощью выражения с подзапросом (потому что возвращаются сразу два значения):
DROP TABLE IF EXISTS t;
CREATE TABLE t(id integer, code text);
INSERT INTO t VALUES (1, 'Один'), (3, 'Три');

-- анонимная процедура
DO $$
DECLARE
    r record;
BEGIN
    SELECT id, code INTO r FROM t WHERE id = 1;
    RAISE NOTICE '%', r;
END;
$$;


gcloud compute instances delete postgres4