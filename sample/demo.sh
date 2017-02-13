#!/bin/sh -x
psql -U postgres postgres -c "SHOW log_statement"
echo "=== use psql ==="
read
psql -U postgres pg_reversi -f ../pg_reversi_init.sql
psql -U postgres pg_reversi -c "SELECT black(3,2);"
psql -U postgres pg_reversi -c "SELECT white(2,2);"

echo "=== use ps_reversi ==="
read
pg_reversi -U postgres pg_reversi -f ../pg_reversi_init.sql
pg_reversi -U postgres pg_reversi -c "SELECT black(2,3);"
pg_reversi -U postgres pg_reversi -c "SELECT white(4,2);"

