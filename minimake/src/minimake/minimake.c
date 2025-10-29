#include "minimake.h"
#define _POSIX_C_SOURCE 200809L

struct makefile *init_makefile(void)
{
    struct makefile *makefile = malloc(sizeof(struct makefile));

    makefile->list_t = init_list_target();

    makefile->list_v = init_list_variable();

    makefile->list_p = malloc(2 * sizeof(char *));
    makefile->size_p = 0;
    makefile->cap_p = 2;

    makefile->is_been_executed = false;
    return makefile;
}

void add_phony(struct makefile *makefile, char *phon)
{
    if (makefile->size_p == makefile->cap_p)
    {
        makefile->cap_p *= 2;
        makefile->list_p =
            realloc(makefile->list_p, makefile->cap_p * sizeof(char *));
    }
    makefile->list_p[makefile->size_p++] = phon;
}

void free_makefile(struct makefile *make)
{
    free_list_target(make->list_t);
    free_list_variable(make->list_v);
    for (size_t i = 0; i < make->size_p; i++)
    {
        free(make->list_p[i]);
    }
    free(make->list_p);
    free(make);
}

void print_makefile(struct makefile *make)
{
    printf("# variables\n");
    print_list_variable(make->list_v);
    printf("# rules\n");
    print_list_target(make->list_t);
}
