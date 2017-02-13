# contrib/pg_reversi/Makefile

MODULE_big = pg_reversi
OBJS = pg_reversi.o

EXTENSION = pg_reversi
DATA = pg_reversi--1.0.sql pg_reversi_init.sql pg_reversi_view.sql

#REGRESS = pg_reversi

ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = contrib/pg_reversi
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif
