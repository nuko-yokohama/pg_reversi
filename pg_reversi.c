/**
 * pg_reversi.c
 *
 * appication_name is "pg_reversi", disable output query server log.
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include "postgres.h"
#include "utils/elog.h"
#include "utils/guc.h"

PG_MODULE_MAGIC;

void _PG_init(void);
void _PG_fini(void);
static void pg_reversi_emit_log_hook(ErrorData *data);

static void
pg_reversi_emit_log_hook(ErrorData *data) {
    const char* appname = application_name;

    if (appname == NULL || *appname == '\0') {
		/* applicatoin_name is no set */
		return ;
    }

    if (!strcmp(appname, "pg_reversi")) {
        /* When application_name is pg_reversi, output to the server log is suppressed. */ 
		data->output_to_server = false;
    }
	return ;
}

/*
 *  * _PG_init
 *   * Entry point loading hooks
 *    */
void
_PG_init(void)
{
	emit_log_hook = pg_reversi_emit_log_hook;
}

