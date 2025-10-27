
#ifndef EXTENSION_VAR_H
#define EXTENSION_VAR_H
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#include "../minimake/minimake.h"
#include "../string/string.h"

char *get_name_extended(struct makefile *make, char *str);
bool is_valid_after_dollar(char c);
#endif /* EXTENSION_VAR_H */
