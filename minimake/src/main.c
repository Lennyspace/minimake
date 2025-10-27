#define _POSIX_C_SOURCE 200809L
#include "main.h"
static bool check_validity_target_main(struct makefile *make,
                                       struct target *targ_main)
{
    if (!is_in_list_phony(make, targ_main))
    {
        if (nothing_to_be_done(make, targ_main))
        {
            fprintf(stderr, "minimake: Nothing to be done for '%s'.\n",
                    targ_main->name);
            return false;
        }
        else if (is_up_to_date(make, targ_main))
        {
            fprintf(stderr, "minimake: '%s' is up to date.", targ_main->name);
            return false;
        }
        else
        {
            return true;
        }
    }
    else
    {
        return true;
    }
}

static int get_list_Makefile_target(int argc, char *argv[],
                                    struct argument *arg)
{
    for (int i = 1; i < argc; i++)
    {
        if (strcmp("-h", argv[i]) == 0)
        {
            arg->flag_h = true;
            // on continue si argv vide ?? oui
        }
        else if (strcmp("-p", argv[i]) == 0)
        {
            arg->flag_p = true;
        }
        else if (strcmp("-f", argv[i]) == 0)
        {
            if (i + 1 >= argc)
            {
                fprintf(stderr, "-f attend un argument\n");
                return 2;
            }
            i++;
            if (argv[i][0] == 0)
            {
                fprintf(stderr, "empty argument\n");
                return 2;
            }

            add_file(arg, strdup(argv[i]));
        }
        else if (argv[i][0] == 0)
        {
            fprintf(stderr, "empty argument\n");
            return 2;
        }
        else
        {
            add_rule(arg, strdup(argv[i]));
        }
    }
    return 0;
}

int main(int argc, char *argv[])
{
    struct argument *arg = argument_init();
    if (get_list_Makefile_target(argc, argv, arg) == 2)
    {
        free_argument(arg);
        return 2;
    }
    if (arg->flag_h)
    {
        free_argument(arg);
        printf(" t as vraiment besoin d aide pour make allo bassem ?\n");
        return 0;
    }
    struct makefile *make = init_makefile();
    for (size_t i = 0; i < arg->size_f; i++)
    {
        FILE *stream = fopen(arg->list_file[i], "r");
        if (stream == NULL)
        {
            add_rule_first(arg, arg->list_file[i]);
            continue;
        }
        if (parser(stream, make) == 2)
        {
            free_makefile(make);
            free_argument(arg);
            printf("error parsing\n");
            return 2;
        }
        fclose(stream);
    }

    if (arg->flag_p)
    {
        print_makefile(make);
        free_makefile(make);
        free_argument(arg);
        return 0;
    }

    print_makefile(make);
    for (size_t i = 0; i < arg->size_r; i++)
    {
        struct target *main_targ =
            get_target_with_name(make, arg->list_rule[i]);
        if (main_targ == NULL)
        {
            fprintf(stderr, "target does not exist sad\n");
            free_makefile(make);
            free_argument(arg);
            return 2;
        }
        if (check_validity_target_main(make, main_targ) == false)
        {
            free_makefile(make);
            free_argument(arg);
            return 2;
        }
        if (exec_target_and_dep(make, main_targ) == 2)
        {
            free_makefile(make);
            free_argument(arg);
            return 2;
        }
    }

    free_argument(arg);
    free_makefile(make);
    return 0;
}
