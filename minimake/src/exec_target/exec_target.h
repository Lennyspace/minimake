#ifndef EXEC_TARGET_H
#define EXEC_TARGET_H
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdint.h>

#include "../list_target/list_target.h"
#include "../list_variable/list_variable.h"
#include "../minimake/minimake.h"
#include "../extension_var/extension_var.h"
#include "../string/string.h"
#include "../is_up_to_date/is_up_to_date.h"

struct target* get_target_with_name(struct makefile* make,char* name_target);

int exec_target_recipes(struct makefile* make,struct target* targ);

int exec_target_and_dep(struct makefile* make,struct target* targ);
#endif /* EXEC_TARGET_H */
