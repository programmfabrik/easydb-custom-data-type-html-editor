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

buildinfojson:
	repo=`git remote get-url origin | sed -e 's/\.git$$//' -e 's#.*[/\\]##'` ;\
	rev=`git show --no-patch --format=%H` ;\
	lastchanged=`git show --no-patch --format=%ad --date=format:%Y-%m-%dT%T%z` ;\
	builddate=`date +"%Y-%m-%dT%T%z"` ;\
	release=$(if $(strip $(RELEASE_TAG)),'"$(RELEASE_TAG)"','null') ;\
	echo '{' > build-info.json ;\
	echo '  "repository": "'$$repo'",' >> build-info.json ;\
	echo '  "rev": "'$$rev'",' >> build-info.json ;\
	echo '  "release": '$$release',' >> build-info.json ;\
	echo '  "lastchanged": "'$$lastchanged'",' >> build-info.json ;\
	echo '  "builddate": "'$$builddate'"' >> build-info.json ;\
	echo '}' >> build-info.json

build: code $(L10N) buildinfojson

thirdparty_copy:
	mkdir -p build/webfrontend
	cp -r src/thirdparty/tinymce build/webfrontend

code: $(JS) css thirdparty_copy

clean: clean-base

wipe: wipe-base

# ------------------

# fylr only

ZIP_NAME=$(PLUGIN_NAME).zip

build-fylr: clean-fylr code buildinfojson
	mkdir -p build_fylr/$(PLUGIN_NAME)/l10n
	cp manifest_fylr.yml build_fylr/$(PLUGIN_NAME)/manifest.yml
	cp build-info.json build_fylr/$(PLUGIN_NAME)
	cp -r build/webfrontend build_fylr/$(PLUGIN_NAME)
	rm -rf build_fylr/$(PLUGIN_NAME)/webfrontend/l10n
	cp -r l10n build_fylr/$(PLUGIN_NAME)

clean-fylr:
	rm -rf build_fylr

zip: build-fylr ## build zip file for publishing for fylr
	cd build_fylr && zip $(ZIP_NAME) -r $(PLUGIN_NAME)
