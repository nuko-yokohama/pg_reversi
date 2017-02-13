SELECT get_turn_boad_status() AS status;
\o /dev/null
SELECT x AS " ", y, 
  CASE
    WHEN status = 1  THEN '●'
    WHEN status = -1 THEN '○'
    ELSE ' '
  END AS status
FROM boad ORDER BY x;
\o
\crosstabview " " y status y

