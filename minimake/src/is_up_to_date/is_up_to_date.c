#include "is_up_to_date.h"
bool is_up_to_date(struct makefile *make, struct target *target)
{
    struct stat fichier_t;
    int exist = stat(target->name, &fichier_t);
    if (exist != 0)
    {
        return false;
    }
    for (size_t i = 0; i < target->size_dep; i++)
    {
        struct stat fichier_d;
        int dep_exist = stat(target->dependencies[i], &fichier_d);
        if (dep_exist != 0)
        {
            continue;
        }
        else if (fichier_t.st_mtime > fichier_d.st_mtime)
        {
            continue;
        }
        else
        {
            return false;
        }
    }
    for (size_t i = 0; i < target->size_dep; i++)
    {
        struct target *targ_dep =
            get_target_with_name(make, target->dependencies[i]);
        if (targ_dep == NULL)
        {
            continue;
        }
        else if (nothing_to_be_done(make, targ_dep) == true)
        {
            continue;
        }
        else if (is_up_to_date(make, targ_dep) == true)
        {
            continue;
        }
        else
        {
            return false;
        }
    }
    return true;
}

bool nothing_to_be_done(struct makefile *make, struct target *target)
{
    if (target->size_rec != 0)
    {
        return false;
    }
    for (size_t i = 0; i < target->size_dep; i++)
    {
        struct target *targ_dep =
            get_target_with_name(make, target->dependencies[i]);
        if (targ_dep == NULL)
        {
            continue;
        }
        else if (nothing_to_be_done(make, targ_dep) == true)
        {
            continue;
        }
        else if (is_up_to_date(make, targ_dep) == true)
        {
            continue;
        }
        else
        {
            return false;
        }
    }
    return true;
}

bool is_in_list_phony(struct makefile *make, struct target *target)
{
    for (size_t i = 0; i < make->size_p; i++)
    {
        if (strcmp(target->name, make->list_p[i]) == 0)
        {
            return true;
        }
    }
    return false;
}
