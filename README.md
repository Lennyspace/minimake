# minimake

A GNU Make clone written in C99. Parses Makefile syntax, expands variables, resolves dependencies, and executes build recipes in the correct order.

## What it does

- Parses Makefile targets, dependencies, variables, and recipes
- Expands variables and handles automatic variables
- Checks file timestamps to skip up-to-date targets
- Executes recipes in dependency order
- Supports phony targets and pattern rules

## Architecture

```
src/
|-- main.c                  # Entry point and argument handling
|-- parser/                 # Makefile parsing
|-- minimake/               # Core build logic
|-- list_target/            # Target dependency graph
|-- list_variable/          # Variable storage
|-- extension_var/          # Variable expansion
|-- is_up_to_date/          # Timestamp checking
|-- exec_target/            # Recipe execution
`-- string/                 # String utilities
```

## Build & run

```bash
make
./minimake [target]
```

Or use it on any Makefile:

```bash
./minimake -f path/to/Makefile [target]
```

## Tests

```bash
make check
```

The test suite covers variable expansion, phony targets, pattern rules, up-to-date detection, and dependency ordering.

---

EPITA - Systems programming (ING1)
