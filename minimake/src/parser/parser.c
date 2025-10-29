#define _POSIX_C_SOURCE 200809L
#include "parser.h"

static void error_print(enum line_type type)
{
    switch (type)
    {
    case ERROR_TAB_NOT_IN_TARGET:
        fprintf(stderr, "tab not in a recipe\n");
        break;
    case ERROR_NOR_VAR_TARGET_PHONY:
        fprintf(stderr, "there no = or : in the line\n");
        break;
    case ERROR_INVALID_VAR_NAME:
        fprintf(stderr, "VAR name is invalid\n");
        break;
    case ERROR_INVALID_TARGET_NAME:
        fprintf(stderr, "target name is invalid\n");
        break;
    case ERROR_INVALID_SYNTAX:
        fprintf(stderr, "invalid syntax :(\n");
        break;
    default:
        fprintf(stderr, "unknown error \n");
        break;
    }
}

static bool is_line_blank(char *line)
{
    int i = 0;
    while (line[i])
    {
        if (!isblank(line[i]))
        {
            return false;
        }
        i++;
    }
    return true;
}

char get_first_sep(char *line)
{
    int i = 0;
    while (line[i])
    {
        if (line[i] == '=')
        {
            return '=';
        }
        if (line[i] == ':')
        {
            return ':';
        }
        i++;
    }
    return 0;
}
static bool is_valid_VAR_name_after_extend(char *line)
{
    int i = 0;
    while (line[i] && (line[i] == ' ' || line[i] == '\t'))
    {
        i++;
    }
    if (line[i] == 0)
    {
        return false; // empty name
    }
    while (line[i] != ' ' && line[i] != '\t' && line[i] != 0)
    {
        if (line[i] == '#')
        {
            return false;
        }
        i++;
    }
    if (line[i] == 0)
    {
        return true;
    }
    return false;
}

static bool is_valid_VAR_name(char *line)
{
    int i = 0;
    while (line[i] && (line[i] == ' ' || line[i] == '\t'))
    {
        i++;
    }
    if (line[i] == 0)
    {
        return false; // empty name
    }
    while (line[i] != ' ' && line[i] != '\t' && line[i] != '=')
    {
        if (line[i] == '#')
        {
            return false;
        }
        i++;
    }
    if (line[i] == '=')
    {
        return true;
    }
    while (line[i] != '=')
    {
        if (line[i] != ' ' && line[i] != '\t')
        {
            return false;
        }
        i++;
    }
    return true;
}
static bool is_not_empty_and_no_hashtag(char *line)
{
    int i = 0;
    while (line[i])
    {
        if (line[i] == '#')
        {
            return false;
        }
        i++;
    }
    return i != 0;
}

static bool is_valid_TARGET_name_afer_extend(char *line)
{
    int i = 0;
    while (line[i] == ' ' || line[i] == '\t')
    {
        i++;
    }
    if (line[i] == 0)
    {
        return true; // empty name
    }
    while (line[i] != ' ' && line[i] != '\t' && line[i] != 0)
    {
        if (line[i] == '#')
        {
            return false;
        }
        i++;
    }
    if (line[i] == 0)
    {
        return true;
    }
    return false;
}

static bool is_valid_TARGET_name(char *line)
{
    int i = 0;
    while (line[i] == ' ' || line[i] == '\t')
    {
        i++;
    }
    if (line[i] == 0)
    {
        return true; // empty name
    }
    while (line[i] != ' ' && line[i] != '\t' && line[i] != ':')
    {
        if (line[i] == '#')
        {
            return false;
        }
        i++;
    }
    if (line[i] == ':')
    {
        return true;
    }
    while (line[i] != ':')
    {
        if (line[i] != ' ' && line[i] != '\t')
        {
            return false;
        }
        i++;
    }
    return true;
}
static char *extract_target(char *line)
{
    struct string *string_target = init_string();
    int i = 0;
    while (isblank(line[i]))
    {
        i++;
    }

    while (!isblank(line[i]) && line[i] != ':')
    {
        add_char_string(string_target, line[i]);
        i++;
    }
    add_char_string(string_target, 0);
    char *res = strdup(string_target->str);
    free_string(string_target);
    return res;
}
static bool is_PHONY(char *line)
{
    char *target = extract_target(line);
    if (strcmp(target, ".PHONY") == 0)
    {
        free(target);
        return true;
    }
    free(target);
    return false;
}

static int rec_is_valid_syntax(char *str, int i, char stop)
{
    while (str[i] && str[i] != stop)
    {
        if (str[i] == '$')
        {
            if (str[i + 1] == 0)
            {
                if (stop != 0)
                {
                    return -1;
                }
                i++;
            }
            if (str[i + 1] == '$')
            {
                i += 2;
                continue;
            }
            if (str[i + 1] == '{')
            {
                i = rec_is_valid_syntax(str, i + 2, '}');
                if (i == -1)
                {
                    return -1;
                }
                continue;
            }
            if (str[i + 1] == '(')
            {
                i = rec_is_valid_syntax(str, i + 2, ')');
                if (i == -1)
                {
                    return -1;
                }
                continue;
            }
            if (str[i + 1] == ' ')
            {
                return -1;
            }
        }
        i++;
    }
    if (stop == 0)
    {
        if (str[i] == 0)
        {
            return -2; // succes
        }
        else
        {
            return -1;
        }
    }
    if (str[i] != stop)
    {
        return -1;
    }
    return i + 1;
}

static bool is_valid_syntax(char *line)
{
    if (rec_is_valid_syntax(line, 0, '\0') == -2)
    {
        return true;
    }
    return false;
}

static void without_comment(char *line)
{
    int i = 0;
    while (line[i])
    {
        if (line[i] == '#')
        {
            line[i] = 0;
            return;
        }
        i++;
    }
}

enum line_type get_line_type(char *line, size_t len)
{
    if (len == 0 || is_line_blank(line))
    {
        return NOTHING;
    }
    if (line[0] == '\t')
    {
        return ERROR_TAB_NOT_IN_TARGET;
    }
    if (!is_valid_syntax(line))
    {
        return ERROR_INVALID_SYNTAX;
    }
    char sep = get_first_sep(line);
    switch (sep)
    {
    case '=':
        if (is_valid_VAR_name(line))
        {
        }
        return VAR;
        return ERROR_INVALID_VAR_NAME;
    case ':':
        if (is_valid_TARGET_name(line))
        {
            if (is_PHONY(line))
            {
                return PHONY;
            }
            return TARGET;
        }
        return ERROR_INVALID_TARGET_NAME;
    default:
        return ERROR_NOR_VAR_TARGET_PHONY;
    }
    return 0;
}

static void remove_end(char *line)
{ // return la new len
    if (!line)
        return;
    size_t len = strlen(line);
    if (len == 0)
        return;
    if (line[len - 1] == '\n')
    {
        line[len - 1] = 0;
    }
    return;
}

static char *extract_name(char *line)
{
    struct string *string_name = init_string();
    int i = 0;
    while (line[i] != '=')
    {
        if (!isblank(line[i]))
        {
            add_char_string(string_name, line[i]);
        }
        i++;
    }
    add_char_string(string_name, 0);
    char *res = strdup(string_name->str);
    free_string(string_name);
    return res;
}
static char *extract_val(char *line)
{
    struct string *string_name = init_string();
    int i = 0;
    while (line[i] != '=')
    {
        i++;
    }
    i++;
    while (line[i] && isblank(line[i]))
    {
        i++;
    }

    while (line[i])
    {
        add_char_string(string_name, line[i]);
        i++;
    }
    add_char_string(string_name, 0);
    char *res = strdup(string_name->str);
    free_string(string_name);
    return res;
}

static int parser_var(struct makefile *make, char *line)
{
    char *name = extract_name(line);
    char *val = extract_val(line);

    char *name_ext = get_name_extended(make, name);
    if (is_valid_VAR_name_after_extend(name_ext) == false)
    {
        free(name);
        free(val);
        free(name_ext);
        return 2;
    }

    free(name);
    if (is_not_empty_and_no_hashtag(name_ext) == false)
    {
        free(val);
        free(name_ext);
        return 2;
    }

    struct variable *variable = init_variable(name_ext, val);
    add_list_variable(make->list_v, variable);
    return 0;
}

static void parser_add_dependencies(struct makefile *make, struct target *targ,
                                    char *line)
{
    size_t lenline = strlen(line);
    int i = 0;
    while (line[i] != ':')
    {
        i++;
    }
    char *deps = malloc((lenline - i + 1) * sizeof(char));
    strcpy(deps, line + i + 1);

    char *token = strtok(deps, " \t");
    while (token)
    {
        char *dep_ext = get_name_extended(make, token);
        if (dep_ext[0] != 0)
        {
            add_target_dependencies(targ, dep_ext);
        }
        else
        {
            free(dep_ext);
        }

        token = strtok(NULL, " \t");
    }
    free(deps);
}

int parser_target(FILE *file, struct makefile *make, char *line_t)
{
    char *target = extract_target(line_t);
    char *target_ext = get_name_extended(make, target);
    free(target);
    if (is_valid_TARGET_name_afer_extend(target_ext) == false)
    {
        fprintf(stderr, "invalid target name after var extention\n");
        free(target_ext);
        return 2;
    }

    struct target *new_targ = init_target(target_ext);
    parser_add_dependencies(make, new_targ, line_t);

    char *line = NULL;
    size_t len = 0;

    long pos = ftell(file); // position pour la ligne lu en trop

    while (getline(&line, &len, file) != -1)
    {
        remove_end(line);
        if (is_valid_syntax(line) == false)
        {
            free(line);
            free_target(new_targ);
            error_print(ERROR_INVALID_SYNTAX);

            return 2;
        }
        if (is_line_blank(line))
        {
            continue;
        }
        else if (line[0] == '\t')
        {
            char *rec = malloc(strlen(line) * sizeof(char) + 1);
            int start = 1;
            while (isblank(line[start]))
            {
                start++;
            }
            strcpy(rec, line + start); // sans le tab
            add_target_recipes(new_targ, rec);
            pos = ftell(file); // position pour la ligne lu en trop
        }
        else if (line[0] == '#')
        {
            continue;
        }
        else
        {
            break;
        }
    }
    fseek(file, pos, SEEK_SET);
    add_list_target(make->list_t, new_targ);
    free(line);
    return 0;
}
static int parser_phony(struct makefile *make, char *line)
{
    size_t lenline = strlen(line);
    int i = 0;
    while (line[i] != ':')
    {
        i++;
    }
    char *deps = malloc((lenline - i + 1) * sizeof(char));
    strcpy(deps, line + i + 1);

    char *token = strtok(deps, " \t");
    if (is_valid_syntax(line) == false)
    {
        fprintf(stderr, "invalid syntax in .PHONY\n");
        free(deps);
        return 2;
    }
    while (token)
    {
        char *phon_ext = get_name_extended(make, token);
        add_phony(make, phon_ext);
        token = strtok(NULL, " \t");
    }
    free(deps);
    return 0;
}

int parser(FILE *file, struct makefile *make)
{
    char *line = NULL;
    size_t len = 0;

    while (getline(&line, &len, file) != -1)
    {
        remove_end(line);
        without_comment(line); // line est coupe du commentaire et du \n

        enum line_type type = get_line_type(line, len);

        if (type >= ERROR_TAB_NOT_IN_TARGET)
        {
            free(line);
            error_print(type);
            return 2;
        }
        if (type == NOTHING)
        {
            continue;
        }
        if (type == VAR)
        {
            if (parser_var(make, line) == 2)
            {
                free(line);
                error_print(ERROR_INVALID_VAR_NAME);
                return 2;
            }
        }
        if (type == TARGET)
        {
            if (parser_target(file, make, line) == 2)
            {
                free(line);
                return 2;
            }
        }
        if (type == PHONY)
        {
            if (parser_phony(make, line) == 2
                || parser_target(file, make, line) == 2)
            {
                make->list_t->list[make->list_t->size - 1]->is_phony = true;
                free(line);
                fprintf(stderr, "invalid phony\n");
                error_print(ERROR_INVALID_TARGET_NAME);
                return 2;
            }
        }
    }
    free(line);
    return 0;
}
