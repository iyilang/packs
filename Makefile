.PHONY: build serve update migrate migration check test clean
IYI = iyi
PORT ?= 3000
# .env, kept out of git, may hold GITHUB_TOKEN=… for make update.
-include .env
export GITHUB_TOKEN

# The server, the GitHub import and the migration tool.
build:
	mkdir -p bin
	$(IYI) build packs.iyi -o bin/packs --no-color
	$(IYI) build update.iyi -o bin/update --no-color
	$(IYI) build migrate.iyi -o bin/migrate --no-color
# Serves the directory at http://localhost:3000 (PORT=… for another port),
# applying pending migrations first.
serve:
	mkdir -p bin
	$(IYI) build packs.iyi -o bin/packs --no-color
	./bin/packs -p $(PORT)
# Finds the iyi modules on GitHub and writes them into data/packs.db; set
# GITHUB_TOKEN, here or in .env, for code search and a higher rate limit.
update:
	mkdir -p bin
	$(IYI) build update.iyi -o bin/update --no-color
	./bin/update
# Applies pending migrations; `make migrate ARGS=status` runs another command.
ARGS ?= up
migrate:
	mkdir -p bin
	$(IYI) build migrate.iyi -o bin/migrate --no-color
	./bin/migrate $(ARGS)
# Writes an empty migration: make migration NAME=hide_some_module
migration:
	$(MAKE) migrate ARGS="scaffold $(NAME)"
check:
	$(IYI) check packs.iyi --no-color
	$(IYI) check update.iyi --no-color
	$(IYI) check migrate.iyi --no-color
test:
	$(IYI) test
clean:
	rm -rf bin .cache/site_test.db
