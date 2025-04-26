1) Создал таблицу и заполнил ее
```
create table all_place(id int, depart_date date, busstation text, svobodno int);

WITH all_place AS (
    SELECT count(s.id) as all_place, s.fkbus as fkbus
    FROM book.seat s
    GROUP BY s.fkbus
),
     order_place AS (
         SELECT count(t.id) as order_place, t.fkride
         FROM book.tickets t
         GROUP BY t.fkride
     )
INSERT INTO all_place (id, depart_date, busstation, svobodno)
SELECT r.id,
       r.startdate as depart_date,
       bs.city || ', ' || bs.name as busstation,
       st.all_place - t.order_place as svobodno
FROM book.ride r
         JOIN book.schedule s
              ON r.fkschedule = s.id
         JOIN book.busroute br
              ON s.fkroute = br.id
         JOIN book.busstation bs
              ON br.fkbusstationfrom = bs.id
         JOIN order_place t
              ON t.fkride = r.id
         JOIN all_place st
              ON r.fkbus = st.fkbus
GROUP BY r.id, r.startdate, bs.city || ', ' || bs.name, t.order_place, st.all_place
ORDER BY r.startdate
LIMIT 10;
```

2) Создал триггеры
На вставку и удаление изменяет количество свободных мест
```
CREATE OR REPLACE FUNCTION change_free_places() RETURNS TRIGGER AS $$
    BEGIN
    IF TG_OP = 'INSERT' THEN
       UPDATE book.all_place SET svobodno = svobodno - 1 WHERE id = NEW.fkride;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE book.all_place SET svobodno = svobodno + 1 WHERE id = OLD.fkride;
    END IF;
    RETURN NULL;
end;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE TRIGGER change_free_places
    AFTER INSERT OR DELETE ON book.tickets
    FOR EACH ROW EXECUTE FUNCTION change_free_places();
```
На вставку,  BEFORE INSERT проверяет количество свободных мест, чтобы больше 0
```
CREATE OR REPLACE FUNCTION check_free_places() RETURNS TRIGGER AS $$
    BEGIN
        IF TG_OP = 'INSERT' THEN
            if (SELECT all_place.svobodno from book.all_place where id = NEW.fkride) <= 0 THEN
                RAISE EXCEPTION 'NO FREE PLACES';
        end if;
            END IF;
        RETURN NEW;
    END ;
    $$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER check_free_places
    BEFORE INSERT ON book.tickets
    FOR EACH ROW EXECUTE FUNCTION check_free_places();

```

3) Проверил вставку без триггеров
```
EXPLAIN ANALYSE
    INSERT INTO book.tickets (fkride, fio, contact, fkseat)
    values (2, 'Ivan', '123', 1);

```
Среднее время: 0.344 ms

4) Проверил вставку с триггерами
```
EXPLAIN ANALYSE
    INSERT INTO book.tickets (fkride, fio, contact, fkseat)
    values (2, 'Ivan', '123', 1);
```
Среднее время: 1.148 ms

    Таким образом, вставка с происходит дольше