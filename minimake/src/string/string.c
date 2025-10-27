#include "string.h"

struct string *init_string(void)
{
    struct string *str = malloc(sizeof(struct string));
    str->size = 0;
    str->cap = 8;
    str->str = malloc(8 * sizeof(char));
    return str;
}

void add_char_string(struct string *str, char c)
{
    if (str->size == str->cap)
    {
        str->cap *= 2;
        str->str = realloc(str->str, str->cap * sizeof(char));
    }
    str->str[str->size++] = c;
}
void free_string(struct string *str)
{
    free(str->str);
    free(str);
}
