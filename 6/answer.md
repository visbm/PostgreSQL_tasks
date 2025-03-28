### synchronous_commit = on;

1) На запись  /usr/lib/postgresql/17/bin/pgbench -c 8 -j 4 -T 10 -f ~/workload2.sql -n -U postgres -p 5432 thai

        number of transactions actually processed: 37887
        number of failed transactions: 0 (0.000%)
        latency average = 2.095 ms
        initial connection time = 84.659 ms
        tps = 3818.789002 (without initial connection time)


2) На чтение  /usr/lib/postgresql/17/bin/pgbench -c 8 -j 4 -T 10 -f ~/workload.sql -n -U postgres -p 5432 thai

       number of transactions actually processed: 183930
       number of failed transactions: 0 (0.000%)
       latency average = 0.433 ms
       initial connection time = 66.870 ms
       tps = 18485.163327 (without initial connection time)



3) Реплику на чтение  /usr/lib/postgresql/17/bin/pgbench -c 8 -j 4 -T 10 -f ~/workload.sql -n -U postgres -p 5433 thai

        number of transactions actually processed: 175353
        number of failed transactions: 0 (0.000%)
        latency average = 0.453 ms
        initial connection time = 75.361 ms
        tps = 17646.494089 (without initial connection time)


### ALTER SYSTEM SET synchronous_commit='off';

1) На запись  /usr/lib/postgresql/17/bin/pgbench -c 8 -j 4 -T 10 -f ~/workload2.sql -n -U postgres -p 5432 thai

        number of transactions actually processed: 74147
        number of failed transactions: 0 (0.000%)
        latency average = 1.073 ms
        initial connection time = 70.548 ms
        tps = 7459.182837 (without initial connection time)

2) На чтение  /usr/lib/postgresql/17/bin/pgbench -c 8 -j 4 -T 10 -f ~/workload.sql -n -U postgres -p 5432 thai

       number of transactions actually processed: 178070
       number of failed transactions: 0 (0.000%)
       latency average = 0.446 ms
       initial connection time = 76.117 ms
       tps = 17938.111450 (without initial connection time)


3) Реплику на чтение  /usr/lib/postgresql/17/bin/pgbench -c 8 -j 4 -T 10 -f ~/workload.sql -n -U postgres -p 5433 thai

        number of transactions actually processed: 186163
        number of failed transactions: 0 (0.000%)
        latency average = 0.427 ms
        initial connection time = 68.421 ms
        tps = 18740.783782 (without initial connection time)

### синхронная реплика + асинхронная каскадно снимаемая с синхронной;

1) На запись /usr/lib/postgresql/17/bin/pgbench -c 8 -j 4 -T 10 -f ~/workload2.sql -n -U postgres -p 5432 thai

        number of transactions actually processed: 30618
        number of failed transactions: 0 (0.000%)
        latency average = 2.612 ms
        initial connection time = 18.252 ms
        tps = 3063.355265 (without initial connection time)

2) На чтение мастер /usr/lib/postgresql/17/bin/pgbench -c 8 -j 4 -T 10 -f ~/workload.sql -n -U postgres -p 5432 thai

        number of transactions actually processed: 175396
        number of failed transactions: 0 (0.000%)
        latency average = 0.456 ms
        initial connection time = 14.271 ms
        tps = 17539.984126 (without initial connection time)

3) Реплику синхронную на чтение  /usr/lib/postgresql/17/bin/pgbench -c 8 -j 4 -T 10 -f ~/workload.sql -n -U postgres -p 5433 thai

       number of transactions actually processed: 180551
       number of failed transactions: 0 (0.000%)
       latency average = 0.442 ms
       initial connection time = 19.037 ms
       tps = 18084.155813 (without initial connection time)

4) Реплику синхронную на чтение  /usr/lib/postgresql/17/bin/pgbench -c 8 -j 4 -T 10 -f ~/workload.sql -n -U postgres -p 5434 thai

         number of transactions actually processed: 174654
         number of failed transactions: 0 (0.000%)
         latency average = 0.457 ms
         initial connection time = 21.178 ms
         tps = 17489.985673 (without initial connection time)



      При synchronous_commit = on на запись tps намного меньше из-за того что нужно ждать подверждение от реплики.
      На чтение тпс примерно , нембольшие погрешности. Включение синхронного коммита не влияет на чтение.
      При каскадной репликации на запись как в  synchronous_commit, так как реплика синхронная от мастера