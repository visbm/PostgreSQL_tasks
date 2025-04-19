1. Создать таблицу с продажами.

2. Реализовать функцию выбор трети года (1-4 мес - первая треть, 5-8 - вторая и т.д.)

a. Через case

b. * (бонуса в виде зачета дз не будет) используя математическую операцию (лучше 2+

варианта)

c. предусмотреть NULL на входе

3. Вызвать эту функцию в SELECT из таблицы с продажами, убедиться, что всё отработало

1) Таблицы

    `CREATE TABLE sales (id SERIAL PRIMARY KEY,item_no int, price decimal, quantity int, dt date);`

2) Функция через case и предусмотрен null 

    `CREATE OR REPLACE  FUNCTION PriceByThird(th int default 1) RETURNS TABLE(id int, item_no int, price decimal, third int) AS $$
    BEGIN
    th := COALESCE(th, 1);
    IF  th < 1 OR th > 3 THEN
    RAISE EXCEPTION 'Third must be between 1 and 3' ;
    END IF;
        RETURN QUERY
            SELECT * FROM
            (SELECT
                s.id,
                s.item_no,
                s.price,
                CASE
                    WHEN extract(month from s.dt) <= 4 THEN 1
                    WHEN extract(month from s.dt)<= 8  THEN 2
                    ELSE 3
                    END AS third
            FROM sales s) t
            WHERE t.third = th;
    END;
    $$ LANGUAGE plpgsql;`

3) Функция через заранее вычесленное значение 

`CREATE OR REPLACE  FUNCTION PriceByThird(th int default 1) RETURNS TABLE(id int, item_no int, price decimal, third int) AS $$
    declare endOFThird int;
BEGIN
    th := COALESCE(th, 1);
    IF  th < 1 OR th > 3 THEN
        RAISE EXCEPTION 'Third must be between 1 and 3' ;
        END IF;
    endOFThird := 4 * th;
    RETURN QUERY
        SELECT * FROM
        (SELECT
            s.id,
            s.item_no,
            s.price,
            CASE
                WHEN extract(month from s.dt) <= endOFThird THEN 1
                WHEN extract(month from s.dt)<= endOFThird  THEN 2
                ELSE 3
                END AS third
        FROM sales s) t
        WHERE t.third = th;
END;
$$ LANGUAGE plpgsql;`

4) Функция через математическую операцию

    `CREATE OR REPLACE  FUNCTION PriceByThird(th int default 1) RETURNS TABLE(id int, item_no int, price decimal, third int) AS $$
        declare endOFThird int;
    BEGIN
        th := COALESCE(th, 1);
        IF  th < 1 OR th > 3 THEN
            RAISE EXCEPTION 'Third must be between 1 and 3' ;
            END IF;
        endOFThird := 4 * th;
        RETURN QUERY
            SELECT * FROM
            (SELECT
                s.id,
                s.item_no,
                s.price,
                ((extract(month from s.dt)-1)/4+1)::int as third
            FROM sales s) t
            WHERE t.third = th;
    END;
    $$ LANGUAGE plpgsql;`

5) Через математическую операцию

    `select * from sales;
    CREATE OR REPLACE  FUNCTION PriceByThird(th int default 1) RETURNS TABLE(id int, item_no int, price decimal, third int) AS $$
        declare endOFThird int;
    BEGIN
        th := COALESCE(th, 1);
        IF  th < 1 OR th > 3 THEN
            RAISE EXCEPTION 'Third must be between 1 and 3' ;
            END IF;
        endOFThird := 4 * th;
        RETURN QUERY
            SELECT * FROM
            (SELECT
                s.id,
                s.item_no,
                s.price,
                CEILING(extract(month from s.dt)/4)::int as third
            FROM sales s) t
            WHERE t.third = th;
    END;
    $$ LANGUAGE plpgsql;`