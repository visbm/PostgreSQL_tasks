Процедура :

DO $$
        BEGIN
            FOR i IN 1..10 LOOP
            UPDATE TestVacuum SET id = id + 1;
            RAISE NOTICE 'Iteration: %', i;
        END LOOP;
        commit; 
    END $$;


2) Размер таблицы 35 мб
3) размер после 5х обновлений 237 мб
   n_dead_tup = 5млн  Так как мы 5 раз обновили таблиц по 1 млн
4) Пришел автовакум, n_dead_tup =0 , но размер таблицы тот же, так как автовакуп пометил таплы мертывыми, 
и разрешил на перезапись, но физически не очистил место
5) Обновили 10 раз , но вес таблички = 207мб , увеличился в два раза, так как он перезаписал первые 5млн строк и добавил еще 5млн