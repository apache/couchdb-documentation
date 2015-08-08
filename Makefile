## Licensed under the Apache License, Version 2.0 (the "License"); you may not
## use this file except in compliance with the License. You may obtain a copy of
## the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
## WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
## License for the specific language governing permissions and limitations under
## the License.

SPHINXBUILD  := sphinx-build
TEX          := tex
PDFLATEX     := pdflatex
MAKEINFO     := makeinfo

BUILDDIR     := build
SOURCE       := src/
PAPERSIZE    := -D latex_paper_size=a4
SPHINXFLAGS  := -a -E -W -n -A local=1 $(PAPERSIZE) -d $(BUILDDIR)/doctree
SPHINXOPTS   := $(SPHINXFLAGS) $(SOURCE)

ENSURECMD=\
if [[ $(shell which $(1) > /dev/null 2>&1; echo $$?) -eq 1 ]]; then \
  echo "*** Make sure that $(1) is installed and on your path" && exit 1; \
fi


all: html pdf info man

clean:
	rm -rf $(BUILDDIR)

html: build/html

build/html: $(SPHINXBUILD)
	$(SPHINXBUILD) -b html $(SPHINXOPTS) $(BUILDDIR)/html

latex: build/latex

build/latex: $(SPHINXBUILD) $(TEX)
	$(SPHINXBUILD) -b latex $(SPHINXOPTS) $(BUILDDIR)/latex

pdf: latex build/latex/CouchDB.pdf

build/latex/CouchDB.pdf: $(PDFLATEX)
	$(MAKE) -C $(BUILDDIR)/latex all-pdf

info: build/texinfo

build/texinfo: $(SPHINXBUILD) $(MAKEINFO)
	$(SPHINXBUILD) -b texinfo $(SPHINXOPTS) $(BUILDDIR)/texinfo
	make -C $(BUILDDIR)/texinfo info

man: build/man

build/man: $(SPHINXBUILD)
	$(SPHINXBUILD) -b man $(SPHINXOPTS) $(BUILDDIR)/man

check:
	python ext/linter.py $(SOURCE)

install-html:
install-pdf:
install-info:
install-man:

install: install-html install-pdf install-info install-man
	# copy-files

distclean: clean
	# delete-installed-files


$(SPHINXBUILD):
	@$(call ENSURECMD,$@)

$(TEX):
	@$(call ENSURECMD,$@)

$(PDFLATEX):
	@$(call ENSURECMD,$@)

$(MAKEINFO):
	@$(call ENSURECMD,$@)

$(PYTHON):
	@$(call ENSURECMD,$@)
