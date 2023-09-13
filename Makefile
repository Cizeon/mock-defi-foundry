FORGE=forge
CAST=cast
ANVIL=anvil

.PHONY: coverage clean test

all:
	- $(FORGE) build

test:
	- $(FORGE) test -vv

coverage:
	- rm -rf coverage && mkdir coverage
	- $(FORGE) coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage

clean:
	- rm -rf broadcast coverage lcov.info .git
	- $(FORGE) clean