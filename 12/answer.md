Logical Replicating
1) Поднял два кластера 16 и 17 версии
2) На 16 залил тайские средние перевозки
3)  сделал роль CREATE ROLE replicator
4) сделал публикацию CREATE PUBLICATION thai_pub_test FOR TABLES IN SCHEMA book;
5) на 17 скопировал схемы
6) сделал подписку CREATE SUBSCRIPTION thai_sub_test
7) Логическая репликация заняла с 21:03:55 до 21:05:11 -> 78 секунд

fwd
1) на 17 создал расширение CREATE EXTENSION IF NOT EXISTS postgres_fdw;
2) сервер CREATE SERVER thai_fdw
3)  маппинг пользователей CREATE USER MAPPING FOR CURRENT_USER
4)  импорт схемы IMPORT FOREIGN SCHEMA book
5) EXPLAIN analyse большого запроса на 16 версии был 15 секунд, на 17 версии через fwd 29
6) Также сделал копирование таблиц скриптом, заняло 118 секунд

Dump
1) pg_dump занял 77 секунд
2) pg_restore --jobs=4 150 сек
3) в сумме получилось 150 секунд

Логическая была быстрее всего