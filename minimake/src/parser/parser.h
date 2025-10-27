#ifndef PARSER_H
#define PARSER_H
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>



#include "../minimake/minimake.h"
#include "../list_variable/list_variable.h"
#include "../list_target/list_target.h"
#include "../string/string.h"
#include "../extension_var/extension_var.h"
enum line_type{
	NOTHING,
	VAR,
	TARGET,
	PHONY,
	ERROR_TAB_NOT_IN_TARGET,
	ERROR_NOR_VAR_TARGET_PHONY,
	ERROR_INVALID_VAR_NAME,
	ERROR_INVALID_TARGET_NAME,
	ERROR_INVALID_SYNTAX, //en mod $(la ou ${a
};
int parser(FILE* file,struct makefile* make);
#endif /* PARSER_H */
