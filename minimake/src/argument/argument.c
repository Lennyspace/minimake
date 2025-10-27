#include "argument.h"


struct argument* argument_init(void){
	struct argument* res=malloc(sizeof(struct argument));
	res->cap_f=4;
	res->size_f=0;
	res->list_file=malloc(res->cap_f*sizeof(char*));


	res->cap_r=4;
	res->size_r=0;
	res->list_rule=malloc(res->cap_r*sizeof(char*));

	res->flag_p=false;
	res->flag_h=false;
	return res;
}


void add_file(struct argument* arg,char* file){
	if(arg->size_f==arg->cap_f){
		arg->cap_f=arg->cap_f*2;
		arg->list_file=realloc(arg->list_file,arg->cap_f*sizeof(char*));
	}
	arg->list_file[arg->size_f++]=file;
}
		
void add_rule(struct argument* arg,char* rule){
	if(arg->size_r==arg->cap_r){
		arg->cap_r=arg->cap_r*2;
		arg->list_rule=realloc(arg->list_rule,arg->cap_r*sizeof(char*));
	}
	arg->list_rule[arg->size_r++]=rule;
}

void add_rule_first(struct argument* arg,char* rule){
	if(arg->size_r==arg->cap_r){
		arg->cap_r=arg->cap_r*2;
		arg->list_rule=realloc(arg->list_rule,arg->cap_r*sizeof(char*));
	}
	for (size_t i = arg->size_r; i > 0; i--) {
		arg->list_rule[i] = arg->list_rule[i - 1];
    	}
	arg->list_rule[0]=rule;
	arg->size_r++;
}

	
	 

void free_argument(struct argument* arg){
	for(size_t i=0;i<arg->size_f;i++){
		free(arg->list_file[i]);
	}
	free(arg->list_file);
	for(size_t i=0;i<arg->size_r;i++){
		free(arg->list_rule[i]);
	}
	free(arg->list_rule);
	
	free(arg);
}


