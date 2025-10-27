#define _POSIX_C_SOURCE 200809L 
#include "extension_var.h"



static char* get_value_of_name(struct list_variable* list_v,char* name){
	for(size_t i=0;i<list_v->size;i++){
		if(strcmp(list_v->list[i]->name,name)==0){
			return list_v->list[i]->value;
		}
	}
	char *val = getenv(name);
	if(val){
		return val;
	}
	return "";
}
bool is_valid_after_dollar(char c){
	return (c >= 'a' && c <= 'z') ||
		(c >= 'A' && c <= 'Z') ||
		(c >= '0' && c <= '9') ||
		c == '_' || c == '@' || c == '<' ||
		c == '^' || c == '+' || c == '?' ||
		c == '*' || c == '%';
}

static char* get_name_rec(struct makefile* make, char* str, int* ptr_i, char last);
//vu que recursion boucle

static void apres_dollars(struct makefile* make,char* str , int* ptr_i,struct string* str_name){
	*ptr_i=*ptr_i+1;
	char* name_int=NULL;

	if(str[*ptr_i]=='{'){
		*ptr_i=*ptr_i+1;
		name_int=get_name_rec(make,str,ptr_i,'}');
	}

	else if(str[*ptr_i]=='('){
		*ptr_i=*ptr_i+1;
		name_int=get_name_rec(make,str,ptr_i,')');
	}

	else if(is_valid_after_dollar(str[*ptr_i])){
		name_int=malloc(2*sizeof(char));
		name_int[0]=str[*ptr_i];
		name_int[1]=0;
	}
	else{

		add_char_string(str_name,'$');
		*ptr_i=*ptr_i-1;
	}

	*ptr_i=*ptr_i+1;
	if(name_int){		
		char* expended=get_name_extended(make,name_int);
		free(name_int);

		char* value=get_value_of_name(make->list_v,expended);


		char* expended_value=get_name_extended(make,value);
		for(size_t j=0;j<strlen(expended_value);j++){
			add_char_string(str_name,expended_value[j]);
		}
		free(expended);
		free(expended_value);
	}
}


static char* get_name_rec(struct makefile* make,char* str,int* ptr_i,char last){
	struct string* str_name=init_string();
	while(str[*ptr_i] && str[*ptr_i]!=last){ //str est valide donc pas possible d arrive a '\0' si last!='\0'
		if(str[*ptr_i]!='$'){
			add_char_string(str_name,str[*ptr_i]);
			*ptr_i=*ptr_i+1;
		}
		else if(str[*ptr_i+1]==0){
			add_char_string(str_name,'$');
			break;
		}
		else if(str[*ptr_i+1]=='$'){
			add_char_string(str_name,'$');
			(*ptr_i)+=2;
		}
		else{
			apres_dollars(make,str,ptr_i,str_name);
		}
	}
	add_char_string(str_name,'\0');
	char* name=strdup(str_name->str);
	free_string(str_name);
	return name;
}


char* get_name_extended(struct makefile* make,char* str){
	int i=0;
	return get_name_rec(make,str,&i,'\0');
}



