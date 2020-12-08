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

		editorToolbar = "undo redo | styleselect | bold italic forecolor backcolor | alignleft aligncenter alignright alignjustify | outdent indent"

		input = new CUI.Input(name: "value")
		input.hide(true)

		inputEditor = null
		form = new CUI.Form
			data: initData
			onRender: ->
				CustomDataTypeHtmlEditor.loadLibraryPromise.done(->
					CUI.dom.waitForDOMInsert(node: form).done( ->
						inputElement = input.getElement()
						inputElement.value = initData.value
						tinymce.init(
							menubar:false
							toolbar: editorToolbar
							target: inputElement
							setup: ((inputText) ->
								inputEditor = inputText
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
			fields: [
				input
			,
				type: CUI.DataFieldProxy
				name: "editing_placeholder"
				hidden: true
				element: ->
					label = new CUI.Label
						text: $$("custom.data.type.html-editor.editor.editing-placeholder")
						multiline: true
						centered: true
						appearance: "secondary"
					return label
			,
				type: CUI.DataFieldProxy
				element: =>
					button = new LocaButton
						loca_key: "custom.data.type.html-editor.editor.window.open-button"
						appearance: "link"
						size: "mini"
						onClick: =>
							initData._editorWindowOpen = true # Avoid saving data when the window is open.
							button.hide()
							placeholder = form.getFieldsByName("editing_placeholder")[0]
							placeholder.show(true)
							input.hide(true)

							features = "toolbar=no,status=no,menubar=no,scrollbars=yes,width=800,height=800"
							win = window.open("", "_blank", features)

							# TODO: Add the discard/apply changes buttons. Add a confirmation before closing it.
							#		custom.data.type.html-editor.editor.window.button.apply
							#		custom.data.type.html-editor.editor.window.button.cancel
							#		custom.data.type.html-editor.editor.window.button.discard
							#		custom.data.type.html-editor.editor.window.close-confirmation

							newInputElement = CUI.dom.element("input")
							newInputElement.value = initData.value
							win.document.title = $$("custom.data.type.html-editor.editor.window.title")
							win.document.body.appendChild(newInputElement)

							inputEditorWindow = null
							tinymce.init(
								menubar:false
								toolbar: editorToolbar
								target: newInputElement
								height: "100%"
								setup: ((inputText) ->
									inputEditorWindow = inputText
								)
							)

							win.addEventListener('beforeunload', ->
								placeholder.hide(true)
								input.show(true)
								button.show()

								initData.value = inputEditorWindow.getContent()
								inputEditor.setContent(initData.value)

								delete initData._editorWindowOpen

								CUI.Events.trigger
									node: form
									type: "editor-changed"
							)

							return
					return button
			]

		return form

	renderDetailOutput: (data, top_level_data, opts) ->
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
		)

		openButton = new LocaButton
			loca_key: "custom.data.type.html-editor.detail.window.open-button"
			appearance: "link"
			size: "mini"
			onClick: =>
				CUI.dom.hideElement(openButton)

				features = "toolbar=no,status=no,menubar=no,scrollbars=yes,width=800,height=800"
				win = window.open("", "_blank", features)

				newInputElement = CUI.dom.element("input")
				newInputElement.value = initData.value
				win.document.title = $$("custom.data.type.html-editor.detail.window.title", top_level_data)
				win.document.body.innerHTML = initData.value
				win.addEventListener('beforeunload', ->
					CUI.dom.showElement(openButton)
				)
				return

		verticalLayout = new CUI.VerticalLayout
			center:
				content: iframe
			bottom:
				content: openButton
		return verticalLayout

	getSaveData: (data, save_data) ->
		data = data[@name()]
		if CUI.util.isEmpty(data)
			return save_data[@name()] = null

		if data._editorWindowOpen
			throw new InvalidSaveDataException(text: $$("custom.data.type.html-editor.editor.window.alert.is-open"))

		fulltext = []
		for _, value of CUI.dom.htmlToNodes(data.value)
			text = value.textContent
			if not text or /^(\s|\n)$/.test(text)
				continue
			fulltext.push(value.textContent.trim())

		save_data[@name()] =
			value: data.value
			_fulltext:
				text: fulltext.join(" ")
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