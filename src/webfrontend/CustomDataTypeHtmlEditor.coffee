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

		input = new CUI.Input(name: "value")
		input.hide(true)

		form = new CUI.Form
			data: initData
			onRender: ->
				CustomDataTypeHtmlEditor.loadLibraryPromise.done(->
					CUI.dom.waitForDOMInsert(node: form).done( ->
						inputElement = input.getElement()
						inputElement.value = initData.value
						tinymce.init(
							target: inputElement
							setup: ((inputText) ->
								inputText.on('change', ->
									initData.value = inputText.getContent()

									CUI.Events.trigger
										node: form
										type: "editor-changed"
								)
								input.show(true)
							)
						)
					)
				)
			fields: [input]

		return form

	renderDetailOutput: (data, _, opts) ->
		initData = @__initData(data)

		iframe = CUI.dom.$element("iframe", "ez5-custom-data-type-html-editor-iframe")

		html = CUI.dom.element("html")
		head = CUI.dom.element("head")
		body = CUI.dom.element("body")

		CUI.dom.append(html, head)
		CUI.dom.append(html, body)
		CUI.dom.setStyle(body, "margin": "0px") # Remove the default margin of the HTML.

		CUI.dom.append(body, CUI.dom.htmlToNodes(initData.value))
		customCssURL = ez5.session.config.base.system.html_editor?.custom_css_url
		if customCssURL
			linkElement = CUI.dom.element("link",
				href: customCssURL
				rel: "stylesheet"
				type: "text/css"
			)
			CUI.dom.append(head, linkElement)

		iframe.addEventListener("load", =>
			iframeContent = iframe.contentDocument.documentElement
			iframeContent.innerHTML = html.innerHTML
			iframe.style.height = "#{iframeContent.scrollHeight}px"
		)

		return iframe

	getSaveData: (data, save_data) ->
		data = data[@name()]
		if CUI.util.isEmpty(data)
			return save_data[@name()] = null

		save_data[@name()] =
			value: data.value
			_fulltext:
				text: data.value
		return save_data[@name()]

	__initData: (data) ->
		if not data[@name()]
			initData = {}
			data[@name()] = initData
		else
			initData = data[@name()]
		initData

	isEmpty: (data) ->
		return CUI.util.isEmpty(data[@name()]?.value)

CustomDataType.register(CustomDataTypeHtmlEditor)

CUI.ready =>
	CustomDataTypeHtmlEditor.loadLibraryPromise = CUI.loadScript("https://cdnjs.cloudflare.com/ajax/libs/tinymce/5.5.1/tinymce.min.js")