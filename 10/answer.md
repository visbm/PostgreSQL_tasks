1) Создал таблицу и заполнил ее данными.
```
CREATE TABLE json_task(id SERIAL PRIMARY KEY, js JSONB);
CREATE INDEX ON json_task USING gin (js);

```

2) Обновил поле js в таблице.
    Вес toast таблицы увеличился почти в два раза как и индекс
    Так как создались новые версии строки в toast. 

3) VACUUM не помог так как он реально не удалил строки
4) после выполнения VACUUM FULL вес toast и index уменьшился почти в два раза
5) С индексом еще помогает перестроение REINDEX