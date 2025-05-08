1) Скачал и склей csv. Импортировал в таблицу
2) ```
   SELECT payment_type, round(sum(tips)/sum(tips+fare)*100) tips_persent, count(*)
    FROM taxi_trips
    group by payment_type
    order by 3 desc;
   ```
   Стандартный запрос выполнился за 2 s 636 ms
3) Сделал индекс 
```create index payment_type_index on taxi_trips (payment_type);   ```
   Запрос выполнился за 2 s 475 ms, ничего не поменялось. Индекс бесполезный, мы группируем по этому полю, все равно сканим все.
   Плюс мало значений
4)   ```  
     WITH tips_persent AS (
        SELECT unique_key , tips, fare from taxi_trips
   )
      SELECT payment_type, round(sum(cte.tips)/sum(cte.tips+cte.fare)*100) tips_persent, count(*)
      FROM taxi_trips
      Join tips_persent cte on taxi_trips.unique_key = cte.unique_key
      group by payment_type
      order by 3 desc;
   ``` Попробовал так, c cte. Стало 5 s 416 ms, Изначально думал что будет хуже, попробовал для интереса
    

5) ``` 
CREATE MATERIALIZED VIEW mv_tips_persent AS
SELECT payment_type, round(sum(tips)/sum(tips+fare)*100) tips_persent, count(*) as cnt
    FROM taxi_trips
    group by payment_type ;

SELECT * FROM mv_tips_persent
         ORDER BY cnt DESC; 
``` Можно сделать  MATERIALIZED VIEW и заранее подсчитать, запрос тогда будет выполняться за 153 ms 
 И сделть крон для обновления  VIEW

6) ```
    SET max_parallel_workers = 12;
    SET max_parallel_workers_per_gather = 8;
    ```
    поставил По калькулятору  косты уменьшились с 380к до 344к, начало больше воркеров сканить таблицу,  но скорость выполнения осталась на том-же уровне

7) Протестировал с     ```PARTITION BY RANGE (EXTRACT(YEAR FROM trip_start_timestamp));```

    косты уменьшились с 380к до 361, начало больше воркеров сканить таблицу, но скорость выполнения осталась на том-же уровне. 
    Что не удивительно, так как нам все равно надо заходить в каждый парт 
8) Еще попробовал в клике, запрос выполняется за 203 ms