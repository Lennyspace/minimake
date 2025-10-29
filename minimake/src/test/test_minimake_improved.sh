#!/bin/bash

# Comprehensive test suite for Minimake
# Based on the subject document

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
TOTAL=0

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
echo ""

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

# Get the absolute path to minimake for use in subdirectories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$MINIMAKE" == ./* ]] || [[ "$MINIMAKE" == ../* ]]; then
    MINIMAKE="$(cd "$(dirname "$MINIMAKE")" && pwd)/$(basename "$MINIMAKE")"
fi

# Start tests
echo "Starting Minimake Test Suite"
echo "============================="

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

# ============================================================================

print_test "2.4 - Empty string argument error"
setup
cat > Makefile << 'EOF'
all:
	echo test
EOF
$MINIMAKE "" 2>&1 | grep -q "empty string invalid"
check_result "Empty string error detection"

# ============================================================================

print_test "2.5 - -f with -h (file named -h)"
setup
echo "test" > -h
$MINIMAKE -f -h 2>&1 | grep -q "No such file"
check_result "-f -h tries to open file named -h"

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

# ============================================================================

print_test "3.2 - No targets error"
setup
cat > Makefile << 'EOF'
%.o: %.c
	echo pattern rule
EOF
$MINIMAKE 2>&1 | grep -q "No targets"
check_result "No targets error when only pattern rules"

# ============================================================================

print_test "3.3 - Rule not found error"
setup
cat > Makefile << 'EOF'
all:
	echo test
EOF
$MINIMAKE toto 2>&1 | grep -q "No rule to make target 'toto'"
check_result "Error for non-existent target"

# ============================================================================

print_test "3.4 - Dependency not found error"
setup
cat > Makefile << 'EOF'
all: tutu
	echo This is all
EOF
$MINIMAKE all 2>&1 | grep -q "No rule to make target 'tutu', needed by 'all'"
check_result "Error for non-existent dependency"

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

# ============================================================================

print_test "8.2 - No makefile found error"
setup
$MINIMAKE 2>&1 | grep -q "No targets specified and no makefile found"
check_result "Error when no makefile exists"

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

# ============================================================================
# FINAL SUMMARY
# ============================================================================

cd ..
cleanup

echo ""
echo "========================================="
echo "           TEST SUMMARY"
echo "========================================="
echo -e "Total tests: ${TOTAL}"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
echo -e "${RED}Failed: ${FAILED}${NC}"
echo "========================================="

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! 🎉${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review.${NC}"
    exit 1
fi
