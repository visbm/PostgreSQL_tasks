1) Сделали таблицу , заполнили ее данными и открыли 4 транзакции
    
        CREATE TABLE testLocks (
            ID SERIAL PRIMARY KEY,
            AMOUNT INT
        );
    
        INSERT INTO testLocks (AMOUNT) VALUES (101), (200), (300);
        
        BEGIN;
        UPDATE testLocks SET AMOUNT = AMOUNT + 1 WHERE ID = 1;

2) Проверили текущие транзакции и блокировки 

        1178 - 1ая транзакция idle in transaction
        1093 - 2ая транзакция active
        1168 - 3ая транзакция active
        1358 - 4ая транзакция active
    
        Закоммитили первую транзакцию - 2ая выполнилась и стала idle in transaction 
        Закоммитили вторую транзакцию - 3ая выполнилась и стала idle in transaction
        Закоммитили третью транзакцию - 4ая выполнилась и стала idle in transaction

        То есть транзакции становяться в очередь FIFO 
3) Deadlock

        терминал 1 начинает транзакцию
          BEGIN;
          SELECT * FROM testLocks WHERE ID = 2 FOR UPDATE; Получает блокировку на строку с ID = 2 
    
        терминал 2 начинает транзакцию
          BEGIN;
          SELECT * FROM testLocks WHERE ID = 1 FOR UPDATE; Получает блокировку на строку с ID = 1
          UPDATE testLocks SET AMOUNT = AMOUNT + 1 WHERE ID = 2; Тут становиться в очередь, так как блокировку у этого id захвачена

       терминал 1 продолжает 
       UPDATE testLocks SET AMOUNT = AMOUNT + 1 WHERE ID = 1; Тут становиться в очередь, так как блокировку у этого id захвачена

В Итоге ERROR:  deadlock detected
DETAIL:  Process 1093 waits for ShareLock on transaction 945; blocked by process 1178.
Process 1178 waits for ShareLock on transaction 944; blocked by process 1093.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,18) in relation "testlocks"


Так как две транзакции ждали друг друга
