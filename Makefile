.PHONY: all fixed_source xml fixed_xml ptx post fix_ids post2 post3 build_web clean pristine restore onetime

#
# .env sets some environment varibles that we don't want to commit
#
ifeq ($(origin R2P), undefined)
include .env
endif

DEBUG_PRETEXT := # -v DEBUG

# The root of everything
sources := $(shell find _sources -type f)

# After we fix them with the fix'em scripts
fixed_sources := $(patsubst _sources/%,_fixed_sources/%,$(sources))

# Then we generate XML for each rst file except for common.rst
xml := $(patsubst _fixed_sources/%.rst,build/xml/%.xml,$(filter-out _fixed_sources/common.rst,$(fixed_sources)))

# And then each xml file is eventually turned into ptx
ptx := $(patsubst build/xml/%.xml,pretext/%.ptx,$(xml))

# This will run from a virtual env.
rs2ptx := python -m runestone rs2ptx --sourcedir _fixed_sources

all: fixed_source fixed_xml
	# $(MAKE) fixed_ptx build_$(TARGET)

fixed_source: $(fixed_sources)

_fixed_sources/%: _sources/% | _fixed_sources
	mkdir -p $(dir $@)
	./fix-raw-html-links.pl --debug $< > $@
	./fix-source.pl $@

_fixed_sources:
	mkdir $@

xml:
	$(rs2ptx)
	# rm build/xml/common.xml

fixed_xml: xml
	find build/xml -name '*.xml' -exec ./fix-xml.pl {} \;
	./fixIds.py build/xml ".xml"

fixed_ptx: post
	find pretext -name '*.ptx' -exec ./fix-ptx.pl {} \;
	find pretext -name '*.ptx' -exec ./fix-tests.pl {} \;
	find pretext -name '*.ptx' -exec ./fix-data-stdin.pl {} \;
	if [ -d hand-fixes ]; then rsync -r hand-fixes/ pretext/; fi

# This works better than the script that does them all
pretext/%.ptx: XMLFILE = $(patsubst _fixed_sources/%.rst,build/xml/%.xml,$<)
pretext/%.ptx: _fixed_sources/%.rst | build/xml/%.xml pretext
	mkdir -p $(dir $@)
	xsltproc --novalid $(R2P)/docutils2ptx.xsl $(XMLFILE) > $(XMLFILE).pass1
	xsltproc --novalid post-1.xsl $(XMLFILE).pass1 > $(XMLFILE).pass2
	xsltproc --novalid post-2.xsl $(XMLFILE).pass2 > $(XMLFILE).pass3
	xsltproc --novalid post-3.xsl $(XMLFILE).pass3 > $@

pretext/rs-substitutes.xml: rs-substitutes.xml | pretext
	cp $< $@

pretext:
	mkdir $@

ptx: $(ptx) pretext/rs-substitutes.xml

# need to do pretext init in here to generate project.ptx
# need to manually edit project.ptx and create publication-rs-for-all.xml
#   as described in https://github.com/bnmnetp/Runestone2PreTeXt/blob/main/README.md
post: ptx
	./fixIds.py pretext .ptx
	python $(R2P)/fix_xrefs.py
	python $(R2P)/reformatPtx.py
	python $(R2P)/index2main.py
	python $(R2P)/toctree2xml.py . _fixed_sources
	python $(R2P)/filltoc.py pretext _fixed_sources
	python $(R2P)/copy_figs.py ./_fixed_sources ./pretext/assets

restore:
	git restore pretext
	git restore _sources/
	git restore rs-substitutes.xml
	git clean -fdx pretext

onetime:
	python $(R2P)/index2main.py

build_web:
	pretext $(DEBUG_PRETEXT) build web

build_runestone:
	pretext $(DEBUG_PRETEXT) build runestone

clean: restore
	rm -rf build/xml

pristine: clean
	rm -rf _fixed_sources