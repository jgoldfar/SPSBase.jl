LATEX=latexmk -pdf -bibtex

CHKTEX_ARGS=-n 3 -n 6
# Pick up environment's CHKTEXRC if possible
ifneq ($(CHKTEXRC),)
CHKTEX_ARGS+=--localrc=${CHKTEXRC}
endif

TEX_SOURCES=$(wildcard *.tex)
TEX_SOURCES_BASENAME=$(basename $(TEX_SOURCES))

%.pdf: %.tex
	$(LATEX) $<

logo-standalone.png: logo-standalone.pdf
	convert -density 150 $< -quality 90 $@

clean: clean-fmt clean-check clean-srcs

clean-all: clean clean-all-srcs

clean-srcs: $(addprefix clean-,$(TEX_SOURCES_BASENAME))

clean-all-srcs: $(addprefix clean-all-,$(TEX_SOURCES_BASENAME))

clean-%: %.tex
	$(LATEX) -c $<

clean-all-%: %.tex
	$(LATEX) -C $<

fmt: $(addsuffix .bak,$(TEX_SOURCES_BASENAME))

clean-fmt:
	$(RM) *.bak
	$(RM) indent.log

clean-chktex:
	$(RM) lint-*.out

check: $(addprefix check-,$(TEX_SOURCES_BASENAME))

clean-check: clean-chktex

fmt-%: %.bak

%.bak: %.tex
	echo "Indenting $<"
	latexindent -w -l $<

lint-%.out: %.tex
	chktex -q $(CHKTEX_ARGS) $< 2>/dev/null | tee $@

check-%: lint-%.out
	test ! -s $<
