#include "list_target.h"

struct list_target *init_list_target(void)
{
    struct list_target *list_t = malloc(sizeof(struct list_target));
    list_t->size = 0;
    list_t->capacity = 8;
    list_t->list = malloc(8 * sizeof(struct target *));
    return list_t;
}

void add_list_target(struct list_target *list_t, struct target *target)
{
    if (list_t->size == list_t->capacity)
    {
        list_t->list = realloc(list_t->list,
                               2 * list_t->capacity * sizeof(struct target *));
        list_t->capacity = list_t->capacity * 2;
    }
    list_t->list[list_t->size] = target;
    list_t->size++;
}

void free_list_target(struct list_target *list_t)
{
    for (size_t i = 0; i < list_t->size; i++)
    {
        free_target(list_t->list[i]);
    }
    free(list_t->list);
    free(list_t);
}

void free_target(struct target *target)
{
    free(target->name);
    for (size_t i = 0; i < target->size_dep; i++)
    {
        free(target->dependencies[i]);
    }
    free(target->dependencies);
    for (size_t i = 0; i < target->size_rec; i++)
    {
        free(target->recipes[i]);
    }
    free(target->recipes);
    free(target);
}

static bool is_target_pattern(char *name)
{
    int i = 0;
    while (name[i])
    {
        if (name[i] == '%')
        {
            return true;
        }
        i++;
    }
    return false;
}

struct target *init_target(char *name)
{
    struct target *targ = malloc(sizeof(struct target));
    targ->name = name;

    targ->size_dep = 0;
    targ->cap_dep = 4;
    targ->dependencies = malloc(4 * sizeof(char *));

    targ->size_rec = 0;
    targ->cap_rec = 4;
    targ->recipes = malloc(4 * sizeof(char *));

    targ->is_pattern = is_target_pattern(name);
    targ->is_phony = false;

    return targ;
}

void add_target_dependencies(struct target *target, char *dep)
{
    if (target->size_dep == target->cap_dep)
    {
        target->dependencies =
            realloc(target->dependencies, target->cap_dep * 2 * sizeof(char *));
        target->cap_dep = target->cap_dep * 2;
    }
    target->dependencies[target->size_dep++] = dep;
}

void add_target_recipes(struct target *target, char *rec)
{
    if (target->size_rec == target->cap_rec)
    {
        target->recipes =
            realloc(target->recipes, target->cap_rec * 2 * sizeof(char *));
        target->cap_rec = target->cap_rec * 2;
    }
    target->recipes[target->size_rec++] = rec;
}
static void print_dep(struct target *target)
{
    for (size_t i = 0; i < target->size_dep; i++)
    {
        printf(" [%s]", target->dependencies[i]);
    }
}
static void print_rec(struct target *target)
{
    for (size_t i = 0; i < target->size_rec; i++)
    {
        printf("\n\t'%s'", target->recipes[i]);
    }
    printf("\n");
}

void print_list_target(struct list_target *list_t)
{
    for (size_t i = 0; i < list_t->size; i++)
    {
        printf("(%s):", list_t->list[i]->name);
        print_dep(list_t->list[i]);
        print_rec(list_t->list[i]);
    }
}
