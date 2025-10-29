#define _POSIX_C_SOURCE 200809L
#include "exec_target.h"
static char *get_special_variable(char *recipe, struct target *targ)
{
    struct string *str_res = init_string();
    int i = 0;
    while (recipe[i])
    {
        if (recipe[i] != '$')
        {
            add_char_string(str_res, recipe[i]);
            i++;
        }
        else
        {
            i++;
            if (recipe[i] == 0)
            {
                add_char_string(str_res, '$');
                break;
            }
            else if (recipe[i] == '@')
            {
                // ajoute target name
                for (size_t j = 0; j < strlen(targ->name); j++)
                {
                    add_char_string(str_res, targ->name[j]);
                }
                i++;
            }
            else if (recipe[i] == '<' || recipe[i] == '^')
            {
                if (targ->size_dep != 0)
                {
                    size_t nb_dep = 1;
                    if (recipe[i] == '^')
                    {
                        nb_dep = targ->size_dep;
                    }
                    for (size_t k = 0; k < nb_dep; k++)
                    {
                        if (k > 0)
                        {
                            add_char_string(str_res, ' ');
                        }
                        for (size_t j = 0; j < strlen(targ->dependencies[k]);
                             j++)
                        {
                            add_char_string(str_res, targ->dependencies[k][j]);
                        }
                    }
                }
                i++;
            }
            else
            {
                add_char_string(str_res, '$');
                add_char_string(str_res, recipe[i]);
                i++;
            }
        }
    }
    add_char_string(str_res, '\0');
    char *res = strdup(str_res->str);
    free_string(str_res);
    return res;
}

int exec_recipe(struct makefile *make, char *recipe, struct target *targ)
{
    char *recipe_ext = NULL;
    if (recipe[0] != '@')
    {
        char *recipe_s = get_special_variable(recipe, targ);
        recipe_ext = get_name_extended(make, recipe_s);
        free(recipe_s);

        printf("%s\n", recipe_ext);
        fflush(stdout);
    }
    else
    {
        char *recipe_s = get_special_variable(recipe + 1, targ);
        recipe_ext = get_name_extended(make, recipe_s);
        free(recipe_s);
    }

    pid_t pid = fork();
    if (pid == 0)
    {
        execl("/bin/sh", "sh", "-c", recipe_ext, NULL);
    }
    else
    {
        int status;
        waitpid(pid, &status, 0);

        if (WIFEXITED(status))
        {
            int return_code = WEXITSTATUS(status);
            if (return_code != 0)
            {
                fprintf(stderr, "Command flop\n");
                free(recipe_ext);
                return 2;
            }
        }
        else
        {
            free(recipe_ext);
            return 2;
        }
    }
    free(recipe_ext);
    return 0;
}

int exec_target_recipes(struct makefile *make, struct target *targ)
{
    for (size_t i = 0; i < targ->size_rec; i++)
    {
        if (exec_recipe(make, targ->recipes[i], targ) != 0)
        {
            return 2;
        }
        fflush(stdout);
        fflush(stderr);
    }
    return 0;
}

int exec_target_and_dep(struct makefile *make, struct target *targ)
{
    targ->has_been_executed = true;
    for (size_t i = 0; i < targ->size_dep; i++)
    {
        struct target *targ_d =
            get_target_with_name(make, targ->dependencies[i]);
        if (targ_d == NULL)
        {
            fprintf(stderr,
                    "minimake: *** No rule to make target '%s', needed by "
                    "'%s'. Stop.\n",
                    targ->dependencies[i], targ->name);
            return 2;
        }
        if (((nothing_to_be_done(make, targ_d) || is_up_to_date(make, targ_d))
             && (!is_in_list_phony(make, targ_d)))
            || targ_d->has_been_executed)
        {
            printf("minimake: Nothing to be done for '%s'.\n", targ->name);

            continue;
        }
        if (exec_target_and_dep(make, targ_d) == 2)
        {
            return 2;
        }
    }
    if (exec_target_recipes(make, targ) == 2)
    {
        fprintf(stderr, "probleme exec %s\n", targ->name);
        return 2;
    }
    return 0;
}

bool stem_if_valid_rec(char *pattern, char *name, struct string *str_stem)
{
    if (pattern[0] == 0 || name[0] == 0)
    {
        return pattern[0] == name[0];
    }
    if (pattern[0] == '%')
    {
        for (int i = 1; name[i - 1]; i++)
        {
            add_char_string(str_stem, name[i - 1]);
            if (stem_if_valid_rec(pattern + 1, name + i, str_stem))
            {
                return true;
            }
        }
        return false;
    }
    else if (pattern[0] == name[0])
    {
        return stem_if_valid_rec(pattern + 1, name + 1, str_stem);
    }
    else
    {
        return false;
    }
    return false;
}
char *stem_if_valid(char *pattern, char *name)
{
    struct string *str_stem = init_string();
    if (stem_if_valid_rec(pattern, name, str_stem))
    {
        add_char_string(str_stem, '\0');
        char *stem_final = strdup(str_stem->str);
        free_string(str_stem);
        return stem_final;
    }
    free_string(str_stem);
    return NULL;
}
char *str_with_stem(char *name, char *stem)
{
    char *new_str = malloc((strlen(name) + strlen(stem) + 1) * sizeof(char));
    int i = 0;
    int i_new_str = 0;
    while (name[i])
    {
        if (name[i] != '%')
        {
            new_str[i_new_str++] = name[i++];
        }
        else
        {
            int j = 0;
            while (stem[j])
            {
                new_str[i_new_str++] = stem[j++];
            }
            i++;
        }
    }
    new_str[i_new_str] = '\0';
    return new_str;
}

static struct target *new_target_with_steam(struct target *targ_pattern,
                                            char *stem)
{
    struct target *new_targ =
        init_target(str_with_stem(targ_pattern->name, stem));

    for (size_t i = 0; i < targ_pattern->size_dep; i++)
    {
        add_target_dependencies(
            new_targ, str_with_stem(targ_pattern->dependencies[i], stem));
    }
    for (size_t i = 0; i < targ_pattern->size_rec; i++)
    {
        add_target_recipes(new_targ, strdup(targ_pattern->recipes[i]));
    }
    free(stem);
    return new_targ;
}

static struct target *looking_for_pattern(struct makefile *make,
                                          char *name_target)
{ // creer une target en remplacer le stem dams target et dependencies
    size_t min = SIZE_MAX;
    char *stem_res = NULL;
    struct target *targ_pattern = NULL;
    for (size_t i = 0; i < make->list_t->size; i++)
    {
        struct target *targ = make->list_t->list[i];
        if (targ->is_pattern)
        {
            char *stem =
                stem_if_valid(targ->name, name_target); // stem pas vide
            if (stem)
            {
                if (strlen(stem) < min)
                {
                    if (stem_res)
                    {
                        free(stem_res);
                    }
                    min = strlen(stem);
                    stem_res = stem;
                    targ_pattern = targ;
                }
                else
                {
                    free(stem);
                }
            }
        }
    }
    if (stem_res == NULL || targ_pattern == NULL)
    {
        return NULL;
    }
    return new_target_with_steam(targ_pattern, stem_res);
}

struct target *get_target_with_name(struct makefile *make, char *name_target)
{
    struct target *targ = NULL;
    struct list_target *list_t = make->list_t;
    for (size_t i = 0; i < list_t->size; i++)
    {
        if (strcmp(list_t->list[i]->name, name_target) == 0)
        {
            targ = list_t->list[i];
        }
    }
    if (targ == NULL)
    {
        targ = looking_for_pattern(make, name_target);
        if (targ != NULL)
        {
            add_list_target(make->list_t, targ);
        }
        return targ;
    }
    return targ;
}
