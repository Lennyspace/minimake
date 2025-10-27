#ifndef IS_UP_TO_DATE_H
#define IS_UP_TO_DATE_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "../exec_target/exec_target.h"
#include "../extension_var/extension_var.h"
#include "../list_target/list_target.h"
#include "../list_variable/list_variable.h"
#include "../minimake/minimake.h"
#include "../string/string.h"

bool is_up_to_date(struct makefile *make, struct target *target);
bool nothing_to_be_done(struct makefile *make, struct target *target);
bool is_in_list_phony(struct makefile *make, struct target *target);
#endif /* IS_UP_TO_DATE_H */
