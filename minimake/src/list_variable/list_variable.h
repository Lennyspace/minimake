#ifndef LIST_VARIABLE_H
#define LIST_VARIABLE_H
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
struct variable
{
    char *name;
    char *value;
};
struct list_variable
{
    size_t size;
    size_t capacity;
    struct variable **list;
};

struct list_variable *init_list_variable(void);
void add_list_variable(struct list_variable *list_v, struct variable *var);
struct variable *init_variable(char *name, char *value);
void free_variable(struct variable *var);
void free_list_variable(struct list_variable *list_v);

void print_list_variable(struct list_variable *list_v);
#endif /* LIST_VARIABLE_H */
