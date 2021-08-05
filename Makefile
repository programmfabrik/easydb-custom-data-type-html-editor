PLUGIN_NAME = custom-data-type-html-editor
PLUGIN_PATH = easydb-custom-data-type-html-editor

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
	$(WEB)/tinymce \
	$(CSS) \
	$(JS) \
	$(THIRDPARTY_FILES) \
	manifest.yml

COFFEE_FILES = src/webfrontend/CustomDataTypeHtmlEditor.coffee \
	src/webfrontend/CustomDataTypeHtmlEditorCSVImporterDestinationField.coffee

SCSS_FILES = src/webfrontend/scss/custom-data-type-html-editor.scss

THIRDPARTY_FILES = build/webfrontend/tinymce


all: build

include easydb-library/tools/base-plugins.make

build: code $(L10N) buildinfojson

thirdparty_copy:
	mkdir -p build/webfrontend
	cp -r src/thirdparty/tinymce build/webfrontend

code: $(JS) css thirdparty_copy

clean: clean-base

wipe: wipe-base
