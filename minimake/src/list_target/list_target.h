#ifndef LIST_TARGET_H
#define LIST_TARGET_H

#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
struct target
{
    char *name;

    char **dependencies;
    size_t size_dep;
    size_t cap_dep;

    char **recipes; // une ligne par case
    size_t size_rec;
    size_t cap_rec;

    bool is_pattern;
    bool is_phony;

    bool has_been_executed;
};

struct list_target
{
    size_t size;
    size_t capacity;
    struct target **list;
};

struct list_target *init_list_target(void);
void add_list_target(struct list_target *list_t, struct target *target);
void free_list_target(struct list_target *list_t);
void free_target(struct target *target);
struct target *init_target(char *name);
void add_target_dependencies(struct target *target, char *dep);
void add_target_recipes(struct target *target, char *rec);

void print_list_target(struct list_target *list_t);
#endif /* LIST_TARGET_H */
