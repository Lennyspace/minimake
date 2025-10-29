#!/bin/bash

# Comprehensive test suite for Minimake with Valgrind memory checks
# Based on the subject document

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
TOTAL=0
VALGRIND_PASSED=0
VALGRIND_FAILED=0
VALGRIND_TOTAL=0

# Valgrind enabled flag
ENABLE_VALGRIND=true

# Find the minimake executable
find_minimake() {
    # Check current directory
    if [ -x "./mini" ]; then
        echo "./mini"
        return 0
    fi
    
    # Check parent directory
    if [ -x "../mini" ]; then
        echo "../mini"
        return 0
    fi
    
    # Check if we're in a subdirectory
    if [ -x "mini" ]; then
        echo "mini"
        return 0
    fi
    
    # Not found
    echo ""
    return 1
}

# Check if valgrind is available
check_valgrind() {
    if ! command -v valgrind &> /dev/null; then
        echo -e "${YELLOW}Warning: valgrind not found. Memory leak tests will be skipped.${NC}"
        echo "Install valgrind with: sudo apt-get install valgrind"
        ENABLE_VALGRIND=false
    else
        echo -e "${BLUE}Valgrind found. Memory leak detection enabled.${NC}"
    fi
}

# Find minimake executable
MINIMAKE=$(find_minimake)

if [ -z "$MINIMAKE" ]; then
    echo -e "${RED}Error: Could not find 'mini' executable${NC}"
    echo "Please ensure 'mini' is compiled and executable in:"
    echo "  - Current directory"
    echo "  - Parent directory"
    echo ""
    echo "Current location: $(pwd)"
    exit 1
fi

echo "Found minimake executable: $MINIMAKE"

# Check for valgrind
check_valgrind

# Test directory
TEST_DIR="test_minimake_tmp"

# Cleanup function
cleanup() {
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Setup test directory
setup() {
    cleanup
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR" || exit 1
}

# Print test header
print_test() {
    echo ""
    echo "========================================="
    echo "TEST: $1"
    echo "========================================="
}

# Check test result
check_result() {
    TOTAL=$((TOTAL + 1))
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASSED${NC}: $1"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAILED${NC}: $1"
        FAILED=$((FAILED + 1))
    fi
}

# Compare outputs
compare_output() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓ PASSED${NC}: $test_name"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAILED${NC}: $test_name"
        echo "Expected: $expected"
        echo "Actual:   $actual"
        FAILED=$((FAILED + 1))
    fi
    TOTAL=$((TOTAL + 1))
}

# Run valgrind memory check
valgrind_check() {
    local test_name="$1"
    shift
    local cmd="$@"
    
    if [ "$ENABLE_VALGRIND" = false ]; then
        return 0
    fi
    
    VALGRIND_TOTAL=$((VALGRIND_TOTAL + 1))
    
    # Run valgrind with leak check
    valgrind --leak-check=full \
             --show-leak-kinds=all \
             --errors-for-leak-kinds=all \
             --error-exitcode=42 \
             --quiet \
             $cmd > /dev/null 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 42 ]; then
        echo -e "${RED}✗ MEMORY LEAK${NC}: $test_name"
        echo "  Running detailed check..."
        valgrind --leak-check=full \
                 --show-leak-kinds=all \
                 --track-origins=yes \
                 $cmd 2>&1 | head -30
        VALGRIND_FAILED=$((VALGRIND_FAILED + 1))
        return 1
    else
        echo -e "${GREEN}✓ NO LEAKS${NC}: $test_name"
        VALGRIND_PASSED=$((VALGRIND_PASSED + 1))
        return 0
    fi
}

# Get the absolute path to minimake for use in subdirectories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$MINIMAKE" == ./* ]] || [[ "$MINIMAKE" == ../* ]]; then
    MINIMAKE="$(cd "$(dirname "$MINIMAKE")" && pwd)/$(basename "$MINIMAKE")"
fi

# Start tests
echo ""
echo "========================================="
echo "     MINIMAKE TEST SUITE WITH VALGRIND"
echo "========================================="
echo ""

# ============================================================================
# SECTION 1: BASIC PARSING
# ============================================================================

print_test "1.1 - Basic Variable and Rule Parsing"
setup
cat > Makefile << 'EOF'
FOO = foo bar

all:
	echo $(FOO)
EOF
output=$($MINIMAKE 2>&1)
expected_output="echo foo bar
foo bar"
compare_output "$expected_output" "$output" "Basic variable expansion"
valgrind_check "Basic variable expansion" $MINIMAKE

# ============================================================================

print_test "1.2 - Variable with spaces around ="
setup
cat > Makefile << 'EOF'
FOO = 42

all:
	echo the answer is $(FOO)
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "the answer is 42"
check_result "Variable with spaces"
valgrind_check "Variable with spaces" $MINIMAKE

# ============================================================================

print_test "1.3 - Dollar sign escape ($$)"
setup
cat > Makefile << 'EOF'
all:
	echo $$
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "echo \$"
check_result "Dollar sign escape"
valgrind_check "Dollar sign escape" $MINIMAKE

# ============================================================================

print_test "1.4 - Multiple variable references"
setup
cat > Makefile << 'EOF'
NEEDED = foo
all: $(NEEDED)
foo: foo.o
	gcc -o foo foo.o
foo.o: foo.c
	gcc -c foo.c
EOF
# Just check it parses correctly
$MINIMAKE -p > /dev/null 2>&1
check_result "Multiple rules with dependencies"
valgrind_check "Multiple rules with dependencies" $MINIMAKE -p

# ============================================================================
# SECTION 2: COMMAND LINE OPTIONS
# ============================================================================

print_test "2.1 - Help option (-h)"
setup
cat > Makefile << 'EOF'
all:
	echo test
EOF
$MINIMAKE -h > /dev/null 2>&1
exit_code=$?
[ $exit_code -eq 0 ]
check_result "Help option returns 0"
valgrind_check "Help option" $MINIMAKE -h

# ============================================================================

print_test "2.2 - File option (-f)"
setup
cat > custom_makefile << 'EOF'
test:
	@echo from custom file
EOF
output=$($MINIMAKE -f custom_makefile test 2>&1)
echo "$output" | grep -q "from custom file"
check_result "Custom makefile with -f option"
valgrind_check "Custom makefile with -f" $MINIMAKE -f custom_makefile test

# ============================================================================

print_test "2.3 - Pretty print (-p)"
setup
cat > Makefile << 'EOF'
VAR = test
all: dep
	echo command
dep:
EOF
output=$($MINIMAKE -p 2>&1)
echo "$output" | grep -q "'VAR' = 'test'"
check_result "Pretty print format"
valgrind_check "Pretty print" $MINIMAKE -p

# ============================================================================

print_test "2.4 - Empty string argument error"
setup
cat > Makefile << 'EOF'
all:
	echo test
EOF
$MINIMAKE "" 2>&1 | grep -q "empty string invalid"
check_result "Empty string error detection"
valgrind_check "Empty string error" $MINIMAKE ""

# ============================================================================
# SECTION 3: TARGET SELECTION AND BUILDING
# ============================================================================

print_test "3.1 - Default target (first non-pattern rule)"
setup
cat > Makefile << 'EOF'
%.o: %.c
	echo pattern rule

first:
	@echo this is first

second:
	@echo this is second
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "this is first"
check_result "Default target is first non-pattern rule"
valgrind_check "Default target selection" $MINIMAKE

# ============================================================================

print_test "3.2 - No targets error"
setup
cat > Makefile << 'EOF'
%.o: %.c
	echo pattern rule
EOF
$MINIMAKE 2>&1 | grep -q "No targets"
check_result "No targets error when only pattern rules"
valgrind_check "No targets error" $MINIMAKE

# ============================================================================

print_test "3.3 - Rule not found error"
setup
cat > Makefile << 'EOF'
all:
	echo test
EOF
$MINIMAKE toto 2>&1 | grep -q "No rule to make target 'toto'"
check_result "Error for non-existent target"
valgrind_check "Non-existent target error" $MINIMAKE toto

# ============================================================================

print_test "3.4 - Dependency not found error"
setup
cat > Makefile << 'EOF'
all: tutu
	echo This is all
EOF
$MINIMAKE all 2>&1 | grep -q "No rule to make target 'tutu', needed by 'all'"
check_result "Error for non-existent dependency"
valgrind_check "Non-existent dependency error" $MINIMAKE all

# ============================================================================

print_test "3.5 - Multiple targets in order"
setup
cat > Makefile << 'EOF'
first:
	@echo first rule

second:
	@echo second rule
EOF
output=$($MINIMAKE first second 2>&1)
echo "$output" | grep -q "first rule" && echo "$output" | grep -q "second rule"
check_result "Multiple targets executed in order"
valgrind_check "Multiple targets" $MINIMAKE first second

# ============================================================================
# SECTION 4: UP-TO-DATE AND NOTHING TO BE DONE
# ============================================================================

print_test "4.1 - Nothing to be done (empty recipe)"
setup
cat > Makefile << 'EOF'
empty:
EOF
output=$($MINIMAKE empty 2>&1)
echo "$output" | grep -q "Nothing to be done for 'empty'"
check_result "Nothing to be done message"
valgrind_check "Nothing to be done" $MINIMAKE empty

# ============================================================================

print_test "4.2 - Up to date (file exists)"
setup
touch file.c
cat > Makefile << 'EOF'
file.c:
EOF
output=$($MINIMAKE file.c 2>&1)
echo "$output" | grep -q "Nothing to be done for 'file.c'"
check_result "Nothing to be done for existing file with empty recipe"
valgrind_check "File exists check" $MINIMAKE file.c

# ============================================================================

print_test "4.3 - Up to date with dependency"
setup
echo "test" > toto
cat > Makefile << 'EOF'
all: toto
toto:
	@echo toto file does not exist
EOF
output=$($MINIMAKE all 2>&1)
echo "$output" | grep -q "is up to date"
check_result "Up to date detection"
valgrind_check "Up to date with dependency" $MINIMAKE all

# ============================================================================

print_test "4.4 - File older/younger comparison"
setup
echo "older" > file.c
sleep 1
echo "younger" > file.o
cat > Makefile << 'EOF'
file.o: file.c
	echo I'm up to date
EOF
output=$($MINIMAKE file.o 2>&1)
echo "$output" | grep -q "is up to date"
check_result "File modification time comparison"
valgrind_check "File timestamp comparison" $MINIMAKE file.o

# ============================================================================
# SECTION 5: TARGET DEDUPLICATION
# ============================================================================

print_test "5.1 - Same target twice"
setup
cat > Makefile << 'EOF'
all:
	echo toto
EOF
output=$($MINIMAKE all all 2>&1)
count=$(echo "$output" | grep -c "echo toto")
[ $count -eq 1 ]
check_result "Target built only once when called twice"
valgrind_check "Target deduplication" $MINIMAKE all all

# ============================================================================
# SECTION 6: COMMAND EXECUTION
# ============================================================================

print_test "6.1 - Command logging"
setup
cat > Makefile << 'EOF'
all:
	echo toto
	echo foo
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "echo toto" && echo "$output" | grep -q "echo foo"
check_result "Commands are logged before execution"
valgrind_check "Command logging" $MINIMAKE

# ============================================================================

print_test "6.2 - Silent command with @"
setup
cat > Makefile << 'EOF'
all:
	@echo a line
EOF
output=$($MINIMAKE 2>&1)
! echo "$output" | grep -q "echo a line" && echo "$output" | grep -q "a line"
check_result "@ prefix hides command logging"
valgrind_check "Silent command" $MINIMAKE

# ============================================================================

print_test "6.3 - Command failure stops execution"
setup
cat > Makefile << 'EOF'
all:
	false
	echo "will not appear"
EOF
output=$($MINIMAKE 2>&1)
! echo "$output" | grep -q "will not appear"
exit_code=$?
[ $exit_code -eq 0 ]
check_result "Execution stops on command failure"
valgrind_check "Command failure handling" $MINIMAKE

# ============================================================================

print_test "6.4 - Return code on failure"
setup
cat > Makefile << 'EOF'
all:
	false
EOF
$MINIMAKE 2>&1
exit_code=$?
[ $exit_code -eq 2 ]
check_result "Minimake returns 2 on command failure"
# Valgrind check already done in 6.3

# ============================================================================

print_test "6.5 - Shell variable scope"
setup
cat > Makefile << 'EOF'
all:
	A=42; echo "will print A: -$$A-"
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "will print A: -42-"
check_result "Shell variables in same command"
valgrind_check "Shell variable scope" $MINIMAKE

# ============================================================================
# SECTION 7: COMMENTS
# ============================================================================

print_test "7.1 - Comments in Makefile"
setup
cat > Makefile << 'EOF'
VAR = test # a comment
# all rule
all: # a comment
	echo a $(VAR) line # with a comment
	# just a comment
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "echo a test line # with a comment"
check_result "Comments handling"
valgrind_check "Comments parsing" $MINIMAKE

# ============================================================================
# SECTION 8: MAKEFILE SELECTION
# ============================================================================

print_test "8.1 - Default makefile selection (makefile)"
setup
cat > makefile << 'EOF'
all:
	@echo This is makefile
EOF
cat > Makefile << 'EOF'
all:
	@echo This is Makefile
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "This is makefile"
check_result "makefile preferred over Makefile"
valgrind_check "Makefile selection" $MINIMAKE

# ============================================================================

print_test "8.2 - No makefile found error"
setup
$MINIMAKE 2>&1 | grep -q "No targets specified and no makefile found"
check_result "Error when no makefile exists"
valgrind_check "No makefile error" $MINIMAKE

# ============================================================================
# SECTION 9: ENVIRONMENT VARIABLES
# ============================================================================

print_test "9.1 - Environment variable expansion"
setup
export TEST_VAR="from environment"
cat > Makefile << 'EOF'
all:
	echo $(TEST_VAR)
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "from environment"
check_result "Environment variable used when not defined in Makefile"
valgrind_check "Environment variable" $MINIMAKE

# ============================================================================
# SECTION 10: RECURSIVE VARIABLES
# ============================================================================

print_test "10.1 - Recursive variable expansion"
setup
cat > Makefile << 'EOF'
FOO=$(BAR)
all:
	@echo The answer is $(FOO)$($(FOO)) and not $4
BAR=4
$(FOO)=2
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "The answer is 42 and not 2"
check_result "Recursive variable expansion"
valgrind_check "Recursive variables" $MINIMAKE

# ============================================================================

print_test "10.2 - Variable defined after use"
setup
cat > Makefile << 'EOF'
all:
	echo The answer is ${FOO}
FOO = 42
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "The answer is 42"
check_result "Variable defined after recipe"
valgrind_check "Variable order independence" $MINIMAKE

# ============================================================================
# SECTION 11: SPECIAL VARIABLES
# ============================================================================

print_test "11.1 - Special variables ($@, $<, $^)"
setup
cat > Makefile << 'EOF'
all: foo bar
	@echo target: $@
	@echo first dep: $<
	@echo all deps: $^
foo:
bar:
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "target: all" && echo "$output" | grep -q "first dep: foo" && echo "$output" | grep -q "all deps: foo bar"
check_result "Special variables in recipes"
valgrind_check "Special variables" $MINIMAKE

# ============================================================================
# SECTION 12: PHONY TARGETS
# ============================================================================

print_test "12.1 - .PHONY prevents file check"
setup
touch clean
cat > Makefile << 'EOF'
.PHONY: clean
clean:
	@echo cleaning stuff up
EOF
output=$($MINIMAKE clean 2>&1)
echo "$output" | grep -q "cleaning stuff up"
check_result ".PHONY makes target always run"
valgrind_check ".PHONY target" $MINIMAKE clean

# ============================================================================

print_test "12.2 - .PHONY shows nothing to be done on second call"
setup
cat > Makefile << 'EOF'
.PHONY: all
all:
	@echo running all
EOF
output=$($MINIMAKE all all 2>&1)
echo "$output" | grep -q "Nothing to be done for 'all'"
check_result ".PHONY target shows nothing to be done on dedup"
valgrind_check ".PHONY deduplication" $MINIMAKE all all

# ============================================================================
# SECTION 13: PATTERN RULES
# ============================================================================

print_test "13.1 - Basic pattern rule"
setup
echo "test" > foo.c
cat > Makefile << 'EOF'
%.o: %.c
	@echo compiling $< to $@
EOF
output=$($MINIMAKE foo.o 2>&1)
echo "$output" | grep -q "compiling foo.c to foo.o"
check_result "Basic pattern rule matching"
valgrind_check "Pattern rule" $MINIMAKE foo.o

# ============================================================================

print_test "13.2 - Pattern rule priority (shortest stem)"
setup
touch foo.c foo.f
cat > Makefile << 'EOF'
all: foo.o
	@echo rule all: done

%.o: %.c
	@echo Size stem : 3 - Im not the closest match

f%.o: %.c
	@echo Size stem : 2 - Im first!

%o.o: %.f
	@echo Size stem : 2 - Im second
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "Size stem : 2 - Im first!"
check_result "Pattern rule shortest stem priority"
valgrind_check "Pattern priority" $MINIMAKE

# ============================================================================

print_test "13.3 - Non-pattern rule preferred over pattern"
setup
cat > Makefile << 'EOF'
all: fizz-buzz.o buzz-buzz.o fizz-fizz.o buzz-fizz.o
	@echo rule all: done

%.o:
	@echo Match extension

fizz-buzz.o:
	@echo Match full name

%-buzz.o:
	@echo Match half name
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "Match full name"
check_result "Non-pattern rule preferred"
valgrind_check "Pattern vs non-pattern" $MINIMAKE

# ============================================================================

print_test "13.4 - Pattern with special variables"
setup
echo "test" > main.c
cat > Makefile << 'EOF'
%.o: %.c
	@echo gcc -o $@ -c $<
EOF
output=$($MINIMAKE main.o 2>&1)
echo "$output" | grep -q "gcc -o main.o -c main.c"
check_result "Pattern rule with $@ and $<"
valgrind_check "Pattern with special vars" $MINIMAKE main.o

# ============================================================================
# SECTION 14: MULTIPLE -f OPTION
# ============================================================================

print_test "14.1 - Multiple -f loads all files"
setup
cat > Makefile << 'EOF'
foo:
	@echo This is foo
bar:
	@echo This is bar
baz:
	@echo This is baz
EOF
output=$($MINIMAKE -f bar -f Makefile 2>&1)
echo "$output" | grep -q "bar: No such file or directory" && echo "$output" | grep -q "This is bar"
check_result "Multiple -f option with missing file treated as target"
valgrind_check "Multiple -f" $MINIMAKE -f bar -f Makefile

# ============================================================================

print_test "14.2 - Multiple -f with targets"
setup
cat > Makefile << 'EOF'
foo:
	@echo This is foo
bar:
	@echo This is bar
baz:
	@echo This is baz
EOF
output=$($MINIMAKE baz -f bar foo -f Makefile 2>&1)
echo "$output" | grep -q "This is baz" && echo "$output" | grep -q "This is foo"
check_result "Multiple -f with explicit targets"
valgrind_check "Multiple -f with targets" $MINIMAKE baz -f bar foo -f Makefile

# ============================================================================
# SECTION 15: VARIABLE EXPANSION CONTEXTS
# ============================================================================

print_test "15.1 - Variable expansion in target name"
setup
cat > Makefile << 'EOF'
FILE=foo
all: $(FILE)
$(FILE):
	@echo building $(FILE)
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "building foo"
check_result "Variable expansion in target"
valgrind_check "Variable in target" $MINIMAKE

# ============================================================================

print_test "15.2 - Variable expansion in variable name"
setup
cat > Makefile << 'EOF'
all:
	echo $(FOO)
VAR=FOO
$(VAR)=Hello, World!
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "Hello, World!"
check_result "Variable expansion in variable name"
valgrind_check "Variable in variable name" $MINIMAKE

# ============================================================================

print_test "15.3 - Undefined variable expands to empty string"
setup
cat > Makefile << 'EOF'
all:
	echo start$(UNDEFINED)end
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "startend"
check_result "Undefined variable is empty string"
valgrind_check "Undefined variable" $MINIMAKE

# ============================================================================

print_test "15.4 - Variable expansion despite quotes"
setup
cat > Makefile << 'EOF'
VAR=42
all:
	echo '$(VAR)'
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "echo '42'"
check_result "Variables expand even in quotes (unlike bash)"
valgrind_check "Variable in quotes" $MINIMAKE

# ============================================================================
# SECTION 16: ERROR CASES
# ============================================================================

print_test "16.1 - Unclosed variable reference"
setup
cat > Makefile << 'EOF'
VAR=42
all:
	echo The answer is $(VAR
EOF
$MINIMAKE 2>&1 | grep -q -i "error\|invalid\|unexpected"
check_result "Error on unclosed variable reference"
valgrind_check "Unclosed variable error" $MINIMAKE

# ============================================================================

print_test "16.2 - Command outside of rule"
setup
cat > Makefile << 'EOF'
	echo this is wrong
all:
	echo this is right
EOF
$MINIMAKE 2>&1 | grep -q "command outside of rule\|error"
check_result "Error on command outside of rule"
valgrind_check "Command outside rule error" $MINIMAKE

# ============================================================================
# SECTION 17: STRESS TESTS FOR MEMORY LEAKS
# ============================================================================

print_test "17.1 - Large Makefile stress test"
setup
cat > Makefile << 'EOF'
VAR1=test1
VAR2=test2
VAR3=test3
VAR4=test4
VAR5=test5
VAR6=test6
VAR7=test7
VAR8=test8
VAR9=test9
VAR10=test10

all: dep1 dep2 dep3 dep4 dep5
	@echo All done

dep1:
	@echo dep1

dep2:
	@echo dep2

dep3:
	@echo dep3

dep4:
	@echo dep4

dep5:
	@echo dep5
EOF
$MINIMAKE > /dev/null 2>&1
check_result "Large Makefile parsing"
valgrind_check "Large Makefile stress test" $MINIMAKE

# ============================================================================

print_test "17.2 - Complex variable expansion stress test"
setup
cat > Makefile << 'EOF'
A=$(B)
B=$(C)
C=$(D)
D=$(E)
E=final_value

all:
	@echo $(A)
EOF
output=$($MINIMAKE 2>&1)
echo "$output" | grep -q "final_value"
check_result "Deep variable recursion"
valgrind_check "Deep variable recursion" $MINIMAKE

# ============================================================================

print_test "17.3 - Many targets stress test"
setup
cat > Makefile << 'EOF'
all: t1 t2 t3 t4 t5 t6 t7 t8 t9 t10
	@echo done
t1:
	@echo t1
t2:
	@echo t2
t3:
	@echo t3
t4:
	@echo t4
t5:
	@echo t5
t6:
	@echo t6
t7:
	@echo t7
t8:
	@echo t8
t9:
	@echo t9
t10:
	@echo t10
EOF
$MINIMAKE > /dev/null 2>&1
check_result "Many dependencies"
valgrind_check "Many dependencies stress test" $MINIMAKE

# ============================================================================

print_test "17.4 - Long variable values"
setup
cat > Makefile << 'EOF'
LONG_VAR=this_is_a_very_long_variable_value_that_should_test_memory_allocation_and_string_handling_properly_without_any_leaks_or_issues_in_the_minimake_implementation

all:
	@echo $(LONG_VAR)
EOF
$MINIMAKE > /dev/null 2>&1
check_result "Long variable value"
valgrind_check "Long variable value" $MINIMAKE

# ============================================================================

print_test "17.5 - Multiple pretty print calls (memory cleanup test)"
setup
cat > Makefile << 'EOF'
VAR=test
all:
	@echo test
EOF
for i in {1..5}; do
    $MINIMAKE -p > /dev/null 2>&1
done
check_result "Multiple invocations"
valgrind_check "Multiple -p invocations" $MINIMAKE -p

# ============================================================================
# FINAL SUMMARY
# ============================================================================

cd ..
cleanup

echo ""
echo "========================================="
echo "           TEST SUMMARY"
echo "========================================="
echo -e "Functional Tests:"
echo -e "  Total:  ${TOTAL}"
echo -e "  ${GREEN}Passed: ${PASSED}${NC}"
echo -e "  ${RED}Failed: ${FAILED}${NC}"
echo ""
if [ "$ENABLE_VALGRIND" = true ]; then
    echo -e "Memory Leak Tests (Valgrind):"
    echo -e "  Total:  ${VALGRIND_TOTAL}"
    echo -e "  ${GREEN}Passed: ${VALGRIND_PASSED}${NC}"
    echo -e "  ${RED}Failed: ${VALGRIND_FAILED}${NC}"
else
    echo -e "${YELLOW}Memory leak tests were skipped (valgrind not available)${NC}"
fi
echo "========================================="

if [ $FAILED -eq 0 ] && [ $VALGRIND_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! No memory leaks detected! 🎉${NC}"
    exit 0
else
    if [ $FAILED -gt 0 ]; then
        echo -e "${RED}Some functional tests failed.${NC}"
    fi
    if [ $VALGRIND_FAILED -gt 0 ]; then
        echo -e "${RED}Memory leaks detected! Fix them before submission.${NC}"
    fi
    exit 1
fi
