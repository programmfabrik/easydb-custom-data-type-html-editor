PLUGIN_NAME = custom-data-type-html-editor

EASYDB_LIB = easydb-library

L10N_FILES = l10n/$(PLUGIN_NAME).csv
L10N_GOOGLE_KEY = 1Z3UPJ6XqLBp-P8SUf-ewq4osNJ3iZWKJB83tc6Wrfn0
L10N_GOOGLE_GID = 926543909

INSTALL_FILES = \
	$(WEB)/l10n/cultures.json \
	$(WEB)/l10n/de-DE.json \
	$(WEB)/l10n/en-US.json \
	$(WEB)/l10n/es-ES.json \
	$(WEB)/l10n/it-IT.json \
	$(CSS) \
	$(JS) \
	CustomDataTypeHtmlEditor.config.yml

COFFEE_FILES = src/webfrontend/CustomDataTypeHtmlEditor.coffee

SCSS_FILES = src/webfrontend/scss/custom-data-type-html-editor.scss

all: build

include easydb-library/tools/base-plugins.make

build: code $(L10N)

code: $(JS) css

clean: clean-base

wipe: wipe-base

