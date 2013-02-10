MO_PATH=../locale/
PERL_FILES=../docs/*.pl
TMPL_FILES=../tmpl/*.tmpl
TEMPLATE=qrpearls.pot

.PHONY: compile update
compile:
	@for i in $$(ls *.po); do \
		mkdir -p $(MO_PATH)$${i%.po}/LC_MESSAGES ; \
		msgfmt $$i -o $(MO_PATH)$${i%.po}/LC_MESSAGES/qrpearls.mo; \
		echo "$$i -> $(MO_PATH)$${i%.po}/LC_MESSAGES/qrpearls.mo"; \
	done
update: $(PERL_FILES) $(TMPL_FILES)
	@echo Gathering translations...
	@xgettext -L Perl \
		-k__ -k\$__ -k%__ -k__n:1,2 -k__nx:1,2 -k__np:2,3 -k__npx:2,3 -k__p:2 \
		-k__px:2 -k__x -k__xn:1,2 -kN__ -kN__n -kN__np -kN__p -k \
		--from-code utf-8 -o $(TEMPLATE) $(PERL_FILES)
	@xgettext -L C -j \
		-k_ -k \
		--from-code utf-8 -o $(TEMPLATE) $(TMPL_FILES)
	@echo Merging...
	@for i in $$(ls *.po); do \
		cp $$i $$i.old; \
		echo -n "$$i "; \
		msgmerge $$i.old $(TEMPLATE) > $$i; \
	done
