#ifndef STRING_H
#define STRING_H
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

struct string
{
    size_t size;
    size_t cap;
    char *str;
};

struct string *init_string(void);
void add_char_string(struct string *str, char c);
void free_string(struct string *str);
#endif /* STRING_H */
