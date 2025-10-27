#ifndef MINIMAKE_H
#define MINIMAKE_H
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "../list_target/list_target.h"
#include "../list_variable/list_variable.h"

struct makefile{
	struct list_target* list_t;
	struct list_variable* list_v;
	char** list_p;
	size_t size_p;
	size_t cap_p;
};


struct makefile* init_makefile(void);
void add_phony(struct makefile* makefile, char* phon);
void free_makefile(struct makefile* make);
void print_makefile(struct makefile* make);
#endif /* MINIMAKE_H */
