#!/bin/sh

while :
do
  clear
  pg_reversi -U postgres pg_reversi -f pg_reversi_view.sql
  sleep 0.5
done
