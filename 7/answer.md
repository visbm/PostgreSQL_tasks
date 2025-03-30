1) # explain ANALYZE

Planning Time: 1.774 ms
JIT:
Functions: 80
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
"  Timing: Generation 3.599 ms (Deform 1.215 ms), Inlining 0.000 ms, Optimization 1.975 ms, Emission 26.704 ms, Total 32.278 ms"
Execution Time: 601.186 ms

2) # CREATE INDEX idx_ride_fkschedule ON book.ride(fkschedule);

Planning Time: 1.826 ms
JIT:
Functions: 80
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
"  Timing: Generation 3.854 ms (Deform 1.104 ms), Inlining 0.000 ms, Optimization 3.172 ms, Emission 27.194 ms, Total 34.219 ms"
Execution Time: 693.403 ms

3) # CREATE INDEX idx_schedule_fkroute ON book.schedule(fkroute);

Planning Time: 2.994 ms
JIT:
Functions: 80
Options: Inlining false, Optimization false, Expressions true, Deforming true
Timing: Generation 4.194 ms (Deform 1.519 ms), Inlining 0.000 ms, Optimization 3.465 ms, Emission 32.542 ms, Total 40.200 ms
Execution Time: 682.113 ms
(59 rows)

4) # CREATE INDEX idx_busroute_fkbusstationfrom ON book.busroute(fkbusstationfrom);

Planning Time: 2.863 ms
JIT:
Functions: 80
Options: Inlining false, Optimization false, Expressions true, Deforming true
Timing: Generation 4.091 ms (Deform 1.274 ms), Inlining 0.000 ms, Optimization 2.404 ms, Emission 33.152 ms, Total 39.647 ms
Execution Time: 690.998 ms
(59 rows)

5) # CREATE INDEX idx_tickets_fkride ON book.tickets(fkride);

Planning Time: 2.859 ms
JIT:
Functions: 80
Options: Inlining false, Optimization false, Expressions true, Deforming true
Timing: Generation 4.455 ms (Deform 1.373 ms), Inlining 0.000 ms, Optimization 3.177 ms, Emission 33.912 ms, Total 41.543 ms
Execution Time: 599.021 ms
(59 rows)


5) # CREATE INDEX idx_rides_fkbus ON book.ride(fkbus);

Planning Time: 2.138 ms
JIT:
Functions: 80
Options: Inlining false, Optimization false, Expressions true, Deforming true
Timing: Generation 3.612 ms (Deform 1.125 ms), Inlining 0.000 ms, Optimization 2.849 ms, Emission 34.619 ms, Total 41.080 ms
Execution Time: 684.005 ms



6) # SET enable_seqscan = OFF;
Planning Time: 2.155 ms
JIT:
Functions: 54
"  Options: Inlining true, Optimization true, Expressions true, Deforming true"
"  Timing: Generation 3.534 ms (Deform 1.179 ms), Inlining 17.094 ms, Optimization 64.366 ms, Emission 44.362 ms, Total 129.355 ms"
Execution Time: 1711.049 ms


    Создавал индексы на вторичные ключи, и каждый раз повторя запрос. Планировщик так и не стал использовать ни один новый индекс.
    Сделал SET enable_seqscan = OFF;  и Запрос стал дольше, то есть как Вы и сказали  Нужно всегда тестировать  