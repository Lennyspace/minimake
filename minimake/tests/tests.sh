#!/bin/sh

###########################################
#   LENNY TAURINES PRIME      TESTSUITE   #
###########################################

#----------------- COLOR -----------------#
# 0 - No style | 1 - Bold
RED="\e[0;31m"
BRED="\e[1;31m"
GRN="\e[0;32m"
BGRN="\e[1;32m"
YEL="\e[0;33m"
BYEL="\e[1;33m"
BLU="\e[0;34m"
BBLU="\e[1;34m"
PUR="\e[0;35m"
BPUR="\e[1;35m"
CYA="\e[0;36m"
BCYA="\e[1;36m"
WHI="\e[0;37m"
BWHI="\e[1;37m"
GRE="\e[2;37m"

#----------------- GLOBV -----------------#
my_out=/tmp/my_out.out
my_err=/tmp/my_err.err  

#----------------- TESTS -----------------#

tit_wrap()
{
	echo -e $@$WHI
}

func_test()
{
	test_name=$1
	test_num=$2
	shift 2
	tit_wrap - $PUR "$test_name:$test_num"

    	: > "$my_out";  : > "$my_err"

	expected_out="expected_${test_num}.out"
	expected_err="expected_${test_num}.err"
	expected_code="expected_${test_num}.code"

	ref_code=$(cat "$expected_code")

	./../../minimake "$@" > "$my_out" 2> "$my_err"
	my_code=$?

	diff_out=0
	diff_err=0

	diff "$expected_out" "$my_out" >/dev/null
	diff_out=$?

	diff "$expected_err" "$my_err" >/dev/null
	diff_err=$?


	if [ $ref_code -eq $my_code ] && [ $diff_out -eq 0 ]  && [ $diff_err -eq 0 ]; then
		tit_wrap $GRN GOOD
	else 
		if [ $ref_code -ne $my_code ] ; then
			tit_wrap $RED "EXIT CODE:" $BRED "expected $ref_code" $RED '|' $RED "got $my_code"
		fi
		if [ $diff_out -ne 0 ] ; then
			tit_wrap $RED "STDOUT:" $BRED "EXPECTED ->" $GRE
            		cat "$expected_out"
            		tit_wrap $RED "| GOT ->" $GRE
            		cat "$my_out"
		fi
		if [ $diff_err -ne 0 ] ; then
			tit_wrap $RED "STDERR:" $BRED "EXPECTED ->" $GRE
            		cat "$expected_err"
            		tit_wrap $RED "| GOT ->" $GRE
            		cat "$my_err"
		fi

	fi
}

func_file()
{
	for file in *.args; do
		if [ -f $file ]; then
			i=0
			while IFS= read -r line || [ -n "$line" ]; do
				i=$((i+1))
				func_test "$file" "$i" $line
			done < "$file"
		fi
	done
}

func_dir()
{
	cd tests
	for dir in *; do
		if [ -d $dir ]; then
			tit_wrap == $BYEL $dir $YEL == 
			cd $dir
			func_file
			cd ..
		fi
	done
	cd ..
}

func_dir

