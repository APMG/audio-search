help:
	@echo 'make [ deps | installdeps | test | schema | install | htacess | symlinks ]'

all: deps

check: test

test:
	prove -r t/

schema: 
	prove -r schema/

htaccess:
	perl bin/mk-htaccess

symlinks:
	perl bin/mk-symlinks

deps:
	cd app && perl Makefile.PL 

installdeps: 
	cd app && make installdeps
	perl bin/install-deps.pl

deploy: schema htaccess symlinks perms

install: deploy

perms:
	chmod 755 bin/mk-transcript
	
.PHONY: test schema htaccess deploy symlinks perms deps installdeps
