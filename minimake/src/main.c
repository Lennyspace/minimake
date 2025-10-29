#define _POSIX_C_SOURCE 200809L
#include "main.h"
static bool check_validity_target_main(struct makefile *make,
                                       struct target *targ_main)
{
    if(targ_main->has_been_executed)
    {
        if(!is_in_list_phony(make, targ_main)){
            printf("minimake: '%s' is up to date.\n", targ_main->name);
        }
        else{
            printf("minimake: Nothing to be done for '%s'.\n",
                    targ_main->name);
        }
        return false;
    }
    if (!is_in_list_phony(make, targ_main))
    {
        if (nothing_to_be_done(make, targ_main))
        {
            printf("minimake: Nothing to be done for '%s'.\n",targ_main->name);
            return false;
        }
        else if (is_up_to_date(make, targ_main))
        {
            printf("minimake: '%s' is up to date.\n", targ_main->name);
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
static int free_and_return_exit_code(struct makefile* make,struct argument* arg,int exit_code,char* msg)
{
    if(make!=NULL)
    {
        free_makefile(make);
    }
    free_argument(arg);
    if(exit_code==0 && msg!=NULL)
    {
        printf("%s",msg);
    }
    else if(exit_code!=0 && msg!=NULL)
    {
        fprintf(stderr,"%s",msg);
    }
    return exit_code;
}

static char* get_first_target_makefile(struct makefile* make,struct argument* arg)
{
    for(size_t i=0;i<make->list_t->size;i++)
    {
        if(make->list_t->list[i]->is_pattern==false)
        {
             return make->list_t->list[i]->name;
        }
    }
    return NULL;
}
int main(int argc, char *argv[])
{
    struct makefile *make=NULL;
    struct argument *arg = argument_init();
    
    
    
    if (get_list_Makefile_target(argc, argv, arg) == 2)
    {
        return free_and_return_exit_code(make,arg,2,NULL);
    }
    if (arg->flag_h)
    {
        return free_and_return_exit_code(make,arg,0,"t as vraiment besoin d aide pour make ?allo bassem ?\n");
    }
    if(arg->size_f==0)
    {
        FILE *test = fopen("Makefile", "r");
        if (test != NULL)
        {
            add_file(arg, strdup("Makefile"));
            fclose(test);
        }
        else
        {
            test = fopen("makefile", "r");
            if (test != NULL)
            {
                add_file(arg, strdup("makefile"));
                fclose(test);
            }
            else
            {
                fprintf(stderr, "Aucun Makefile trouve\n");
                return free_and_return_exit_code(make,arg,2,NULL);
            }
        }
    }
    make = init_makefile();
    for (size_t i = 0; i < arg->size_f; i++)
    {
        FILE *stream = fopen(arg->list_file[i], "r");
        if (stream == NULL)
        {
            add_rule_first(arg,strdup(arg->list_file[i]));
	    continue;
        }
        else if (parser(stream, make) == 2)
        {
		fclose(stream);
            return free_and_return_exit_code(make,arg,2,NULL);
        }
        fclose(stream);
    }

    if (arg->flag_p)
    {
        print_makefile(make);
        return free_and_return_exit_code(make,arg,0,NULL);
    }
    if(arg->size_r==0)
    {
        char* first_target=get_first_target_makefile(make,arg );
        if(first_target==NULL)
        {
            return free_and_return_exit_code(make,arg,2,"No targets dans le Makefile gg\n");
        }
        add_rule(arg, strdup(make->list_t->list[0]->name));
        
    }
    for (size_t i = 0; i < arg->size_r; i++)
    {
        struct target *main_targ = get_target_with_name(make, arg->list_rule[i]);
        if (main_targ == NULL)
        {
            return free_and_return_exit_code(make,arg,2,"Target does not exist\n");
        }
        if (check_validity_target_main(make, main_targ) == false)
        {
            continue;
        }
        if (exec_target_and_dep(make, main_targ) == 2)
        {
             return free_and_return_exit_code(make,arg,2,NULL);
        }
    }
    return free_and_return_exit_code(make,arg,0,NULL);
}
