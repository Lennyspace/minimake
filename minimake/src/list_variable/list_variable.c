#include "list_variable.h"

struct list_variable* init_list_variable(void){
	struct list_variable* list_v=malloc(sizeof(struct list_variable));
	list_v->size=0;
	list_v->capacity=8;
	list_v->list=malloc(8*sizeof(struct variable*));
	return list_v;
}

void add_list_variable(struct list_variable* list_v,struct variable* var){
	if(list_v->size==list_v->capacity){
		list_v->list=realloc(list_v->list,list_v->capacity*2 *sizeof(struct variable*));
		list_v->capacity*=2;
	}
	list_v->list[list_v->size++]=var;
}

struct variable* init_variable(char* name, char* value){
	struct variable* var=malloc(sizeof(struct variable));
	var->name=name;
	var->value=value;
	return var;
}

void free_variable(struct variable* var){
	free(var->name);
	free(var->value);
	free(var);

}
void free_list_variable(struct list_variable* list_v){
	for(size_t i=0;i<list_v->size;i++){
		free_variable(list_v->list[i]);
	}
	free(list_v->list);
	free(list_v);
}

static void print_variable(struct variable* var){
	printf("'%s' = '%s'",var->name,var->value);
}

void print_list_variable(struct list_variable* list_v){
	for(size_t i=0;i<list_v->size;i++){
		print_variable(list_v->list[i]);
		printf("\n");
	}

}




