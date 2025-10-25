#ifndef LIST_TARGET_H
#define LIST_TARGET_H

#include <stdbool.h>
struct target{
	char* name;

	char** dependencies;
	size_t nb_dep;
	size_t cap_deb;

	char ** recipes //une ligne par case
	size_t nb_rec;
	size_t cap_rec

	bool is_pattern;
	bool is_phonyl;


};

struct list_target{
	size_t size;
	size_t capacity;
	struct target** list;
}






#endif /* LIST_TARGET_H */
