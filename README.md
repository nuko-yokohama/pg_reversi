# pg_reversi - reversi game on PostgreSQL

## Required

- PostgreSQL 9.6

## functoins
- black(x int, y int)
- white(x int, y int)
- black_pass(x int, y int)
- white_pass(x int, y int)

## script file
- pg_reversi_init.sql
- pg_reverse_view.sql
- pg_reverse_viewer.sh

## build and install

### build

```
make USE_PGXS=1
make USE_PGXS=1 install
```

### install

```
$ psql -U postgres pg_reversi
psql (9.6.0)
Type "help" for help.

pg_reversi=# CREATE EXTENSION pg_reversi ;
CREATE EXTENSION
pg_reversi=# 
```

## initialize and launch viewer
### initialize

```
$ psql -U postgres pg_reversi -f pg_reversi_init.sql 
TRUNCATE TABLE
TRUNCATE TABLE
TRUNCATE TABLE
INSERT 0 1
INSERT 0 64
```

### launch pg_reversi_viewer

```
$ ./pg_reversi_viewer.sh
```

When the viewer is activated, the following screen is displayed.

```
         status          
-------------------------
 turn = ● : ●  = 2, ○ =2
(1 row)

   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 
---+---+---+---+---+---+---+---+---
 0 |   |   |   |   |   |   |   |  
 1 |   |   |   |   |   |   |   |  
 2 |   |   |   |   |   |   |   |  
 3 |   |   |   | ○ | ● |   |   |  
 4 |   |   |   | ● | ○ |   |   |  
 5 |   |   |   |   |   |   |   |  
 6 |   |   |   |   |   |   |   |  
 7 |   |   |   |   |   |   |   |  
(8 rows)
```
## play sample

```
[nuko@localhost pg_reversi]$ psql -U postgres pg_reversi
psql (9.6.0)
Type "help" for help.

pg_reversi=# SELECT black(2,3);
 black 
-------
     1
(1 row)

pg_reversi=# 
```

The following screen is displayed on the viewer.

```
         status          
-------------------------
 turn = ○ : ●  = 4, ○ =1
(1 row)

   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 
---+---+---+---+---+---+---+---+---
 0 |   |   |   |   |   |   |   |  
 1 |   |   |   |   |   |   |   |  
 2 |   |   |   | ● |   |   |   |  
 3 |   |   |   | ● | ● |   |   |  
 4 |   |   |   | ● | ○ |   |   |  
 5 |   |   |   |   |   |   |   |  
 6 |   |   |   |   |   |   |   |  
 7 |   |   |   |   |   |   |   |  
(8 rows)
```

```
pg_reversi=# SELECT white(4,2);
 white 
-------
     1
(1 row)
```

The following screen is displayed on the viewer.

```
         status          
-------------------------
 turn = ● : ●  = 3, ○ =3
(1 row)

   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 
---+---+---+---+---+---+---+---+---
 0 |   |   |   |   |   |   |   |  
 1 |   |   |   |   |   |   |   |  
 2 |   |   |   | ● |   |   |   |  
 3 |   |   |   | ● | ● |   |   |  
 4 |   |   | ○ | ○ | ○ |   |   |  
 5 |   |   |   |   |   |   |   |  
 6 |   |   |   |   |   |   |   |  
 7 |   |   |   |   |   |   |   |  
(8 rows)
```


