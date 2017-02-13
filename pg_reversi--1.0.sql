/* contrib/pg_reversi/pg_reversi--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_reversi" to load this file. \quit

DROP TABLE IF EXISTS turn;
CREATE TABLE IF NOT EXISTS turn (
    status integer -- 1:black turn -1:white turn, 0:game over.
) WITH (fillfactor = 90);

DROP TABLE IF EXISTS boad;
CREATE TABLE IF NOT EXISTS boad (
  x int,
  y int,
  status integer -- 1:black turn -1:white turn, 0:empty
) WITH (fillfactor = 50);

DROP SEQUENCE IF EXISTS num_seq;
CREATE SEQUENCE IF NOT EXISTS num_seq;

DROP TABLE IF EXISTS history;
CREATE TABLE IF NOT EXISTS history (
  num integer,
  x integer,
  y integer,
  turn integer
);

--
-- get turn and boad status 
--
CREATE OR REPLACE FUNCTION get_turn_boad_status() RETURNS text AS $$
DECLARE
  turn_status text;
  black integer;
  white integer;
  status_text text;
BEGIN
  SELECT
    CASE 
      WHEN status = 1 THEN '●'
      WHEN status = -1 THEN '○'
      ELSE 'BUG!'
    END
    FROM turn INTO turn_status;
  SELECT COUNT(*) FROM boad WHERE status = 1 INTO black;
  SELECT COUNT(*) FROM boad WHERE status = -1 INTO white;
  status_text := 'turn = ' || turn_status || ' : ●  = ' || black || ', ○ =' || white;

  RETURN status_text;
END;
$$ LANGUAGE plpgsql;

--
-- check turn
--
CREATE OR REPLACE FUNCTION check_turn(status_in int) RETURNS boolean AS $$
  SELECT (status = status_in) FROM turn;
$$ LANGUAGE sql;

--
-- check x,y range(0-7)
--
CREATE OR REPLACE FUNCTION is_range(x_in int, y_in int) RETURNS boolean AS $$
  SELECT x_in >= 0 AND x_in <=7 AND y_in >=0 AND y_in <= 7
$$ LANGUAGE sql;

--
-- check empty cell
--
CREATE OR REPLACE FUNCTION is_empty(x_in int, y_in int) RETURNS boolean AS $$
  SELECT status = 0 FROM boad WHERE x = x_in AND y = y_in
$$ LANGUAGE sql;

--
-- check up direction (key 8)
--
CREATE OR REPLACE FUNCTION check_up_direction(x_in int, y_in int, status_in int) RETURNS integer AS $$
DECLARE
  check_flag boolean;
  x_min integer;
  e_min integer;
BEGIN
  -- 隣接セル(down)が自分の色と反対か？
  SELECT status = (-1 * (status_in)) FROM boad WHERE x = x_in + 1 AND y = y_in INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF;
  -- 下方向に自分の色のセルがあるか？
  SELECT count(status) > 0 FROM boad WHERE x > x_in + 1 AND y = y_in AND status = status_in INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF; 
  -- 下方向の自分の色のセルのmin_xを取得
  SELECT min(x) FROM boad WHERE x > x_in + 1 AND y = y_in AND status = status_in INTO x_min;
  -- 下方向の自分のemptyセルのe_minを取得
  SELECT min(x) FROM boad WHERE x > x_in + 1 AND y = y_in AND status = 0 INTO e_min;

  IF e_min < x_min THEN
    RETURN 0;
  END IF;

  return x_min - x_in - 1;
END;
$$ LANGUAGE plpgsql;

--
-- check down direction (key 2)
--
CREATE OR REPLACE FUNCTION check_down_direction(x_in int, y_in int, status_in int) RETURNS integer AS $$
DECLARE
  check_flag boolean;
  x_max integer;
  e_max integer;
BEGIN
  -- 隣接セル(up)が自分の色と反対か？
  SELECT status = (-1 * (status_in)) FROM boad WHERE x = x_in - 1 AND y = y_in INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF;
  -- 上方向に自分の色のセルがあるか？
  SELECT count(status) > 0 FROM boad WHERE x < x_in - 1 AND y = y_in AND status = status_in INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF; 
  -- 上方向の自分の色セルのx_maxを取得
  SELECT max(x) FROM boad WHERE x < x_in - 1 AND y = y_in AND status = status_in INTO x_max;

  -- 上方向のemptyセルのx_maxを取得
  SELECT max(x) FROM boad WHERE x < x_in - 1 AND y = y_in AND status = status_in INTO e_max;

  IF e_max > x_max THEN
    
    RETURN 0;
  END IF;

  return x_in - x_max - 1;
END;
$$ LANGUAGE plpgsql;

--
-- check left direction (key 4)
--
CREATE OR REPLACE FUNCTION check_left_direction(x_in int, y_in int, status_in int) RETURNS integer AS $$
DECLARE
  check_flag boolean;
  y_min integer;
  e_min integer;
BEGIN
  -- 隣接セル(right)が自分の色と反対か？
  SELECT status = (-1 * (status_in)) FROM boad WHERE x = x_in AND y = y_in + 1 INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF;
  -- right方向に自分の色のセルがあるか？
  SELECT count(status) > 0 FROM boad WHERE x = x_in AND y > y_in + 1 AND status = status_in INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF; 
  -- right方向の自分の色のセルのy_minを取得
  SELECT min(y) FROM boad WHERE x = x_in AND y > y_in + 1 AND status = status_in INTO y_min;

  -- right方向のemptyセルのe_minを取得
  SELECT min(y) FROM boad WHERE x = x_in AND y > y_in + 1 AND status = 0 INTO e_min;

  IF e_min < y_min THEN
    RETURN 0;
  END IF;

  return y_min - y_in - 1;
END;
$$ LANGUAGE plpgsql;

--
-- check right direction (key 6)
--
CREATE OR REPLACE FUNCTION check_right_direction(x_in int, y_in int, status_in int) RETURNS integer AS $$
DECLARE
  check_flag boolean;
  y_max integer;
  e_max integer;
BEGIN
  -- 隣接セル(left)が自分の色と反対か？
  SELECT status = (-1 * (status_in)) FROM boad WHERE x = x_in AND y = y_in - 1 INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF;
  -- left方向に自分の色のセルがあるか？
  SELECT count(status) > 0 FROM boad WHERE x = x_in AND y < y_in - 1 AND status = status_in INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF; 
  -- left方向の自分の色のセルのy_maxを取得
  SELECT max(y) FROM boad WHERE x = x_in AND y < y_in - 1 AND status = status_in INTO y_max;

  -- left方向の自分の色のセルのe_maxを取得
  SELECT max(y) FROM boad WHERE x = x_in AND y < y_in - 1 AND status = 0 INTO e_max;
  IF e_max > y_max THEN
    RETURN 0;
  END IF;

  return y_in - y_max - 1;
END;
$$ LANGUAGE plpgsql;


--
-- check right-down direction (key 3)
--
CREATE OR REPLACE FUNCTION check_right_down_direction(x_in int, y_in int, status_in int) RETURNS integer AS $$
DECLARE
  check_flag boolean;
  y_max integer;
  e_max integer;
BEGIN
  -- 隣接セル(left-up)が自分の色と反対か？
  SELECT status = (-1 * (status_in)) FROM boad WHERE x = x_in - 1 AND y = y_in - 1 INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF;
  -- left-up方向に自分の色のセルがあるか？
  -- TODO: smart query.
  SELECT count(status) > 0 FROM boad WHERE 
    ((x = x_in - 2 AND y = y_in - 2) OR (x = x_in - 3 AND y = y_in - 3)  OR (x = x_in - 4 AND y = y_in - 4)  OR (x = x_in - 5 AND y = y_in - 5) OR (x = x_in - 6 AND y = y_in - 6)) 
    AND status = status_in INTO check_flag;

  IF check_flag = false THEN
    RETURN 0;
  END IF; 

  -- left-up方向の自分の色のセルのy_maxを取得
  SELECT max(y) FROM boad WHERE 
    ((x = x_in - 2 AND y = y_in - 2) OR (x = x_in - 3 AND y = y_in - 3)  OR (x = x_in - 4 AND y = y_in - 4)  OR (x = x_in - 5 AND y = y_in - 5) OR (x = x_in - 6 AND y = y_in - 6)) 
    AND status = status_in INTO y_max;

  -- left-up方向の自分の色のセルのe_maxを取得
  SELECT max(y) FROM boad WHERE 
    ((x = x_in - 2 AND y = y_in - 2) OR (x = x_in - 3 AND y = y_in - 3)  OR (x = x_in - 4 AND y = y_in - 4)  OR (x = x_in - 5 AND y = y_in - 5) OR (x = x_in - 6 AND y = y_in - 6)) 
    AND status = 0 INTO e_max;

  IF e_max > y_max THEN
    RETURN 0;
  END IF;

  return y_in -y_max - 1;
END;
$$ LANGUAGE plpgsql;


--
-- check left-up direction (key 7)
--
CREATE OR REPLACE FUNCTION check_left_up_direction(x_in int, y_in int, status_in int) RETURNS integer AS $$
DECLARE
  check_flag boolean;
  y_min integer;
  e_min integer;
BEGIN
  -- 隣接セル(right-down)が自分の色と反対か？
  SELECT status = (-1 * (status_in)) FROM boad WHERE x = x_in + 1 AND y = y_in + 1 INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF;
  -- right-down方向に自分の色のセルがあるか？
  -- TODO: smart query.
  SELECT count(status) > 0 FROM boad WHERE 
    ((x = x_in + 2 AND y = y_in + 2) OR (x = x_in + 3 AND y = y_in + 3)  OR (x = x_in + 4 AND y = y_in + 4)  OR (x = x_in + 5 AND y = y_in + 5) OR (x = x_in + 6 AND y = y_in + 6)) 
    AND status = status_in INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF; 
  -- right-down方向の自分の色のセルのy_minを取得
  SELECT min(y) FROM boad WHERE 
    ((x = x_in + 2 AND y = y_in + 2) OR (x = x_in + 3 AND y = y_in + 3)  OR (x = x_in + 4 AND y = y_in + 4)  OR (x = x_in + 5 AND y = y_in + 5) OR (x = x_in + 6 AND y = y_in + 6)) 
    AND status = status_in INTO y_min;

  SELECT min(y) FROM boad WHERE 
    ((x = x_in + 2 AND y = y_in + 2) OR (x = x_in + 3 AND y = y_in + 3)  OR (x = x_in + 4 AND y = y_in + 4)  OR (x = x_in + 5 AND y = y_in + 5) OR (x = x_in + 6 AND y = y_in + 6)) 
    AND status = 0 INTO e_min;

  IF e_min < y_min THEN
    RETURN 0;
  END IF;

  return y_min - y_in - 1;
END;
$$ LANGUAGE plpgsql;


--
-- check right-up direction (key 9)
--
CREATE OR REPLACE FUNCTION check_right_up_direction(x_in int, y_in int, status_in int) RETURNS integer AS $$
DECLARE
  check_flag boolean;
  y_max integer;
  e_max integer;
BEGIN
  -- 隣接セル(left-down)が自分の色と反対か？
  SELECT status = (-1 * (status_in)) FROM boad WHERE x = x_in + 1 AND y = y_in - 1 INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF;
  -- left-down方向に自分の色のセルがあるか？
  -- TODO: smart query.
  SELECT count(status) > 0 FROM boad WHERE 
    ((x = x_in + 2 AND y = y_in - 2) OR (x = x_in + 3 AND y = y_in - 3)  OR (x = x_in + 4 AND y = y_in - 4)  OR (x = x_in + 5 AND y = y_in - 5) OR (x = x_in + 6 AND y = y_in - 6)) 
    AND status = status_in INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF; 
  -- left-down方向の自分の色のセルのy_maxを取得
  SELECT max(y) FROM boad WHERE 
    ((x = x_in + 2 AND y = y_in - 2) OR (x = x_in + 3 AND y = y_in - 3)  OR (x = x_in + 4 AND y = y_in - 4)  OR (x = x_in + 5 AND y = y_in - 5) OR (x = x_in + 6 AND y = y_in - 6)) 
    AND status = status_in INTO y_max;

  SELECT max(y) FROM boad WHERE 
    ((x = x_in + 2 AND y = y_in - 2) OR (x = x_in + 3 AND y = y_in - 3)  OR (x = x_in + 4 AND y = y_in - 4)  OR (x = x_in + 5 AND y = y_in - 5) OR (x = x_in + 6 AND y = y_in - 6)) 
    AND status = 0 INTO e_max;

  IF e_max > y_max THEN
    RETURN 0;
  END IF;

  return y_in -y_max - 1;
END;
$$ LANGUAGE plpgsql;


--
-- check left-down direction (key 1)
--
CREATE OR REPLACE FUNCTION check_left_down_direction(x_in int, y_in int, status_in int) RETURNS integer AS $$
DECLARE
  check_flag boolean;
  y_min integer;
  e_min integer;
BEGIN
  -- 隣接セル(right-up)が自分の色と反対か？
  SELECT status = (-1 * (status_in)) FROM boad WHERE x = x_in - 1 AND y = y_in + 1 INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF;
  -- right-up方向に自分の色のセルがあるか？
  -- TODO: smart query.
  SELECT count(status) > 0 FROM boad WHERE 
    ((x = x_in - 2 AND y = y_in + 2) OR (x = x_in - 3 AND y = y_in + 3)  OR (x = x_in - 4 AND y = y_in + 4)  OR (x = x_in - 5 AND y = y_in + 5) OR (x = x_in - 6 AND y = y_in + 6)) 
    AND status = status_in INTO check_flag;
  IF check_flag = false THEN
    RETURN 0;
  END IF; 
  -- right-up方向の自分の色のセルのy_minを取得
  SELECT min(y) FROM boad WHERE 
    ((x = x_in - 2 AND y = y_in + 2) OR (x = x_in - 3 AND y = y_in + 3)  OR (x = x_in - 4 AND y = y_in + 4)  OR (x = x_in - 5 AND y = y_in + 5) OR (x = x_in - 6 AND y = y_in + 6)) 
    AND status = status_in INTO y_min;

  SELECT min(y) FROM boad WHERE 
    ((x = x_in - 2 AND y = y_in + 2) OR (x = x_in - 3 AND y = y_in + 3)  OR (x = x_in - 4 AND y = y_in + 4)  OR (x = x_in - 5 AND y = y_in + 5) OR (x = x_in - 6 AND y = y_in + 6)) 
    AND status = 0 INTO e_min;

  IF e_min < y_min THEN
    RETURN 0;
  END IF;

  return y_min - y_in - 1;
END;
$$ LANGUAGE plpgsql;


--
-- check_reverse
-- pg_reverse main check routine.
--
CREATE OR REPLACE FUNCTION check_reverse(x_in integer, y_in integer, status_in integer) RETURNS integer AS $$
DECLARE
  check_flag boolean;

  num_up integer;
  num_down integer;
  num_left integer;
  num_right integer;
  num_left_down integer;
  num_right_down integer;
  num_left_up integer;
  num_right_up integer;
  nums integer;

BEGIN

  -- check turn.
  check_flag := check_turn(status_in);
  IF check_flag = false THEN
    RAISE NOTICE 'Not your turn!';
    return 0;
  END IF;

  -- check range.
  check_flag := is_range(x_in, y_in);
  IF check_flag = false THEN
    RAISE NOTICE 'Out of range (range:0-7)';
    return 0;
  END IF;

  -- check empty.
  check_flag := is_empty(x_in, y_in);
  IF check_flag = false THEN
    RAISE NOTICE 'This location is not empty!(%,%)', x_in, y_in;
    return 0;
  END IF;
  
  -- check reversi
  num_up := check_up_direction(x_in, y_in, status_in);
  num_down := check_down_direction(x_in, y_in, status_in);
  num_left := check_left_direction(x_in, y_in, status_in);
  num_right := check_right_direction(x_in, y_in, status_in);
  num_left_up := check_left_up_direction(x_in, y_in, status_in);
  num_left_down := check_left_down_direction(x_in, y_in, status_in);
  num_right_up := check_right_up_direction(x_in, y_in, status_in);
  num_right_down := check_right_down_direction(x_in, y_in, status_in);
  nums := num_up + num_down + num_left + num_right + num_left_up + num_left_down + num_right_up + num_right_down;
  IF nums = 0 THEN
    RAISE NOTICE 'This location is not reverse!(%,%)', x_in, y_in;
  END IF;
 
  return nums;
END;  
$$ LANGUAGE plpgsql;


--
-- update up direction (key 8)
--
CREATE OR REPLACE FUNCTION update_up_direction(x_in int, y_in int, num integer, status_in int) RETURNS integer AS $$
BEGIN
  UPDATE boad SET status = status_in WHERE x > x_in AND x <= x_in + num AND y = y_in ;
  RETURN 0; -- dummy
END;
$$ LANGUAGE plpgsql;

--
-- update down direction (key 2)
--
CREATE OR REPLACE FUNCTION update_down_direction(x_in int, y_in int, num integer, status_in int) RETURNS integer AS $$
BEGIN
  UPDATE boad SET status = status_in WHERE x < x_in AND x >= x_in - num AND y = y_in ;
  RETURN 0; -- dummy
END;
$$ LANGUAGE plpgsql;

--
-- update left direction (key 4)
--
CREATE OR REPLACE FUNCTION update_left_direction(x_in int, y_in int, num integer, status_in int) RETURNS integer AS $$
BEGIN
  UPDATE boad SET status = status_in WHERE y > y_in AND y <= y_in + num AND x = x_in ;
  RETURN 0; -- dummy
END;
$$ LANGUAGE plpgsql;

--
-- update right direction (key 6)
--
CREATE OR REPLACE FUNCTION update_right_direction(x_in int, y_in int, num integer, status_in int) RETURNS integer AS $$
BEGIN
  UPDATE boad SET status = status_in WHERE y < y_in AND y >= y_in - num AND x = x_in ;
  RETURN 0; -- dummy
END;
$$ LANGUAGE plpgsql;

--
-- update left-down direction (key 1)
--
CREATE OR REPLACE FUNCTION update_left_down_direction(x_in int, y_in int, num integer, status_in int) RETURNS integer AS $$
DECLARE
  i integer;
BEGIN
  FOR i IN 0 .. num - 1  LOOP
    UPDATE boad SET status = status_in WHERE y = y_in + i + 1 AND x = x_in - 1 - i;
  END LOOP;

  RETURN 0; -- dummy
END;
$$ LANGUAGE plpgsql;

--
-- update right-down direction (key 3)
--
CREATE OR REPLACE FUNCTION update_right_down_direction(x_in int, y_in int, num integer, status_in int) RETURNS integer AS $$
DECLARE
  i integer;
BEGIN
  FOR i IN 0 .. num - 1  LOOP
    UPDATE boad SET status = status_in WHERE y = y_in - i - 1 AND x = x_in - 1 - i;
  END LOOP;

  RETURN 0; -- dummy
END;
$$ LANGUAGE plpgsql;

--
-- update left-up direction (key 7)
--
CREATE OR REPLACE FUNCTION update_left_up_direction(x_in int, y_in int, num integer, status_in int) RETURNS integer AS $$
DECLARE
  i integer;
BEGIN
  FOR i IN 0 .. num - 1  LOOP
    UPDATE boad SET status = status_in WHERE y = y_in + i + 1 AND x = x_in + 1 + i;
  END LOOP;

  RETURN 0; -- dummy
END;
$$ LANGUAGE plpgsql;

--
-- update right-up direction (key 9)
--
CREATE OR REPLACE FUNCTION update_right_up_direction(x_in int, y_in int, num integer, status_in int) RETURNS integer AS $$
DECLARE
  i integer;
BEGIN
  FOR i IN 0 .. num - 1  LOOP
    UPDATE boad SET status = status_in WHERE y = y_in - i - 1 AND x = x_in + 1 + i;
  END LOOP;

  RETURN 0; -- dummy
END;
$$ LANGUAGE plpgsql;

--
-- update center(key 5)
--
CREATE OR REPLACE FUNCTION update_center(x_in int, y_in int, status_in int) RETURNS integer AS $$
BEGIN
  UPDATE boad SET status = status_in WHERE y = y_in AND x = x_in ;
  RETURN 0; -- dummy
END;
$$ LANGUAGE plpgsql;

--
-- update turn
--
CREATE OR REPLACE FUNCTION update_turn(status_in integer) RETURNS integer AS $$
BEGIN
  UPDATE turn SET status = (status * -1);
  RETURN 0;
END;
$$ LANGUAGE plpgsql;


--
-- update_boad
--
CREATE OR REPLACE FUNCTION update_boad(x_in integer, y_in integer, status_in integer) RETURNS integer AS $$
BEGIN
  PERFORM update_up_direction(x_in, y_in, check_up_direction(x_in, y_in, status_in), status_in);
  PERFORM update_down_direction(x_in, y_in, check_down_direction(x_in, y_in, status_in), status_in);
  PERFORM update_left_direction(x_in, y_in, check_left_direction(x_in, y_in, status_in), status_in);
  PERFORM update_right_direction(x_in, y_in, check_right_direction(x_in, y_in, status_in), status_in);

  PERFORM update_left_up_direction(x_in, y_in, check_left_up_direction(x_in, y_in, status_in), status_in);
  PERFORM update_left_down_direction(x_in, y_in, check_left_down_direction(x_in, y_in, status_in), status_in);
  PERFORM update_right_up_direction(x_in, y_in, check_right_up_direction(x_in, y_in, status_in), status_in);
  PERFORM update_right_down_direction(x_in, y_in, check_right_down_direction(x_in, y_in, status_in), status_in);

  PERFORM update_center(x_in, y_in, status_in);

  PERFORM update_turn(status_in);
  RETURN 0; -- dummy
END;
$$ LANGUAGE plpgsql;

--
-- set_stone
-- pg_reverse main routine.
--
CREATE OR REPLACE FUNCTION set_stone(x_in integer, y_in integer, status_in integer) RETURNS integer AS $$
DECLARE
  nums integer;
BEGIN
  -- check
  nums := check_reverse(x_in, y_in, status_in);
  IF nums = 0 THEN
    RETURN nums;
  END IF;

  -- update boad
  PERFORM update_boad(x_in, y_in, status_in);

  -- insert history
  INSERT INTO history (num, x, y, turn) VALUES (nextval('num_seq'), x_in, y_in, status_in);

  RETURN nums;
END;
$$ LANGUAGE plpgsql;

--
-- set_stone wrapper function
--
CREATE OR REPLACE FUNCTION black(x_in integer, y_in integer) RETURNS integer AS $$
  SELECT set_stone(x_in, y_in, 1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION white(x_in integer, y_in integer) RETURNS integer AS $$
  SELECT set_stone(x_in, y_in, -1);
$$ LANGUAGE SQL;

--
--
--
CREATE OR REPLACE FUNCTION pass(status_in integer) RETURNS boolean AS $$
DECLARE
  x integer;
  y integer;
  check_flag boolean;
  nums integer;
BEGIN
  -- check turn.
  check_flag := check_turn(status_in);
  IF check_flag = false THEN
    RAISE NOTICE 'Not your turn!';
    return false;
  END IF;
  
  -- pass check
  FOR x in 0 .. 7 LOOP
    FOR y in 0 .. 7 LOOP
      -- check
      nums := check_reverse(x, y, status_in);
      IF nums <> 0 THEN
        RAISE NOTICE 'You cannot pass!';
        RETURN false;
      END IF;
    END LOOP;
  END LOOP;

  -- pass
  RAISE NOTICE 'Passed.';
  PERFORM update_turn(status_in);

  RETURN true;
END;
$$ LANGUAGE plpgsql;


--
-- pass wrapper function
--

CREATE OR REPLACE FUNCTION black_pass() RETURNS boolean AS $$
  SELECT pass(1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION white_pass() RETURNS boolean AS $$
  SELECT pass(-1);
$$ LANGUAGE SQL;


---
--- initialize
---
INSERT INTO  turn (status) VALUES (1);

INSERT INTO boad (x, y, status) VALUES
  (0, 0, 0),(0, 1, 0),(0, 2, 0),(0, 3, 0),(0, 4, 0),(0, 5, 0),(0, 6, 0),(0, 7, 0),
  (1, 0, 0),(1, 1, 0),(1, 2, 0),(1, 3, 0),(1, 4, 0),(1, 5, 0),(1, 6, 0),(1, 7, 0),
  (2, 0, 0),(2, 1, 0),(2, 2, 0),(2, 3, 0),(2, 4, 0),(2, 5, 0),(2, 6, 0),(2, 7, 0),
  (3, 0, 0),(3, 1, 0),(3, 2, 0),(3, 3,-1),(3, 4, 1),(3, 5, 0),(3, 6, 0),(3, 7, 0),
  (4, 0, 0),(4, 1, 0),(4, 2, 0),(4, 3, 1),(4, 4,-1),(4, 5, 0),(4, 6, 0),(4, 7, 0),
  (5, 0, 0),(5, 1, 0),(5, 2, 0),(5, 3, 0),(5, 4, 0),(5, 5, 0),(5, 6, 0),(5, 7, 0),
  (6, 0, 0),(6, 1, 0),(6, 2, 0),(6, 3, 0),(6, 4, 0),(6, 5, 0),(6, 6, 0),(6, 7, 0),
  (7, 0, 0),(7, 1, 0),(7, 2, 0),(7, 3, 0),(7, 4, 0),(7, 5, 0),(7, 6, 0),(7, 7, 0);

