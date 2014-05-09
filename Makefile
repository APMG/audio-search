help:
	@echo 'make [ deps | test | xml | schema | deploy | mprstorydeps | mpstorytest | htacess | symlinks ]'

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

deploy: schema htaccess symlinks 

install: deploy
	
.PHONY: test schema htaccess deploy symlinks 
