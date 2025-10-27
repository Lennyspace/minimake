#ifndef ARGUMENT_H
#define ARGUMENT_H
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

struct argument{
	char** list_file;
	size_t size_f;
	size_t cap_f;

	char** list_rule;
	size_t size_r;
	size_t cap_r;

	bool  flag_p;
	bool  flag_h;
};


void free_argument(struct argument* arg);
void add_rule(struct argument* arg,char* rule);
void add_file(struct argument* arg,char* file);
void add_rule_first(struct argument* arg,char* rule);

struct argument* argument_init(void);
#endif /* ARGUMENT_H */
