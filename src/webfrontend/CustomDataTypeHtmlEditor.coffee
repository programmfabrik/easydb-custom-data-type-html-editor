class CustomDataTypeHtmlEditor extends CustomDataType

	getCustomDataTypeName: ->
		"custom:base.custom-data-type-html-editor"

	getCustomDataTypeNameLocalized: ->
		$$("custom.data.type.html-editor.name")

	getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
		return []

	renderFieldAsGroup: ->
		return false

	supportsStandard: ->
		return false

	renderSearchInput: (data, opts={}) ->
		return new SearchToken(
			column: @
			data: data
			fields: opts.fields
		).getInput().DOM

	getFieldNamesForSearch: ->
		@__getFieldNames()

	getFieldNamesForSuggest: ->
		@__getFieldNames()

	renderEditorInput: (data) ->
		initData = @__initData(data)
		# TODO: CHANGE IT TO A PROPER WYSIWYG EDITOR
		form = new CUI.Form
			data: initData
			onDataChanged: ->
				CUI.Events.trigger
					node: form
					type: "editor-changed"
			fields: [
				type: CUI.Input
				name: "value"
			]
		return form

	# TODO: INLINE? POPOVER?
	renderDetailOutput: (data, _, opts) ->
		initData = @__initData(data)

		content = CUI.dom.$element("iframe", "ez5-custom-data-type-html-editor-iframe")

		html = CUI.dom.element("html")
		head = CUI.dom.element("head")
		body = CUI.dom.element("body")

		CUI.dom.append(html, head)
		CUI.dom.append(html, body)
		CUI.dom.setStyle(body, "margin": "0px") # Remove the default margin of the HTML.

		CUI.dom.append(body, initData.value)
		customCssURL = ez5.session.config.base.system.html_editor?.custom_css_url
		if customCssURL
			linkElement = CUI.dom.element("link",
				href: customCssURL
				rel: "stylesheet"
				type: "text/css"
			)
			CUI.dom.append(head, linkElement)

		content.src = 'data:text/html;charset=utf-8,' + encodeURI(html.outerHTML);
		return content

	getSaveData: (data, save_data) ->
		data = data[@name()]
		if CUI.util.isEmpty(data)
			return save_data[@name()] = null

		return save_data[@name()] = value: data.value

	__initData: (data) ->
		if not data[@name()]
			initData = {}
			data[@name()] = initData
		else
			initData = data[@name()]
		initData

	# TODO: ADD FULLTEXT TO SEARCH.

	isEmpty: (data) ->
		return CUI.util.isEmpty(data[@name()]?.value)

CustomDataType.register(CustomDataTypeHtmlEditor)