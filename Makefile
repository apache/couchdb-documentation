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
BUILDDIR     := _build
COUCHVERSION := $(shell git describe --tags --abbrev=0 2>/dev/null || echo unknown)
COUCHDOCSHA  := $(shell git rev-parse --verify --short HEAD 2>/dev/null || echo src)
COUCHRELEASE := $(COUCHVERSION)-git-$(COUCHDOCSHA)
SOURCE       := src/
PAPERSIZE    := -D latex_paper_size=a4
SPHINXFLAGS  := -a -E -W -n -A local=1 $(PAPERSIZE) -d $(BUILDDIR)/doctree 
SPHINXOPTS   := $(SPHINXFLAGS) $(SOURCE)

all: distclean html pdf info man install clean

clean:
	rm -rf $(BUILDDIR)

html:
    ifeq ($(shell which $(SPHINXBUILD) >/dev/null 2>&1; echo $$?), 1)
    $(error ensure that $(SPHINXBUILD) is installed and on your path)
    endif
	$(SPHINXBUILD) -b html $(SPHINXOPTS) $(BUILDDIR)/html

latex:
    ifeq ($(shell which tex >/dev/null 2>&1; echo $$?), 1)
    $(error ensure that tex is installed and on your path)
    endif
	$(SPHINXBUILD) -b latex $(SPHINXOPTS) $(BUILDDIR)/latex

pdf: latex
    ifeq ($(shell which pdflatex >/dev/null 2>&1; echo $$?), 1)
    $(error ensure that pdflatex is installed and on your path)
    endif
	$(MAKE) -C $(BUILDDIR)/latex all-pdf

info:
    ifeq ($(shell which makeinfo >/dev/null 2>&1; echo $$?), 1)
    $(error ensure that makeinfo is installed and on your path)
    endif
	$(SPHINXBUILD) -b texinfo $(SPHINXOPTS) $(BUILDDIR)/texinfo
	make -C $(BUILDDIR)/texinfo info

man:
	$(SPHINXBUILD) -b man $(SPHINXOPTS) $(BUILDDIR)/man

install-html:
install-pdf:
install-info:
install-man:

install: install-html install-pdf install-info install-man
	# copy-files

distclean: clean
	# delete-installed-files
