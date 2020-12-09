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

	renderEditorInput: (data, topLevelData, opts) ->
		initData = @__initData(data)

		resultObject = opts.editor.object
		standard = resultObject.getStandard(topLevelData)

		customCSSURL = ez5.session.config.base.system.html_editor?.custom_css_url
		editorToolbar = "undo redo | styleselect | bold italic forecolor backcolor | alignleft aligncenter alignright alignjustify | outdent indent"
		inputEditor = null

		inputElement = CUI.dom.element("input")
		inputElement.value = initData.value
		CUI.dom.addClass(inputElement, "ez5-custom-data-type-html-editor-fixed-height")
		CUI.dom.setStyle(inputElement, visibility: "hidden")

		CustomDataTypeHtmlEditor.loadLibraryPromise.done(->
			CUI.dom.waitForDOMInsert(node: inputElement).done(->
				tinymce.init(
					menubar:false
					toolbar: editorToolbar
					toolbar_mode: 'sliding'
					target: inputElement
					content_css: customCSSURL
					setup: ((inputText) ->
						CUI.dom.setStyle(inputElement, visibility: "")
						inputEditor = inputText
						inputText.on('change', ->
							initData.value = inputText.getContent()

							CUI.Events.trigger
								node: editorContent
								type: "editor-changed"
						)
					)
				)
			)
		)

		placeholderLabel = new CUI.Label
			text: $$("custom.data.type.html-editor.editor.editing-placeholder")
			class: "ez5-custom-data-type-html-editor-fixed-height"
			multiline: true
			centered: true
			appearance: "secondary"
		CUI.dom.hideElement(placeholderLabel)

		openEditorButton = new LocaButton
			loca_key: "custom.data.type.html-editor.editor.window.open-button"
			appearance: "link"
			size: "mini"
			onClick: =>
				saveChanges = false
				manualClose = false

				initData._editorWindowOpen = true # Avoid saving data when the window is open.
				openEditorButton.disable()
				CUI.dom.hideElement(inputEditor.getContainer())
				CUI.dom.showElement(placeholderLabel)

				features = "toolbar=no,status=no,menubar=no,scrollbars=yes,width=#{window.innerWidth},height=#{window.innerHeight}"
				win = window.open("", "_blank", features)

				win.document.title = $$("custom.data.type.html-editor.editor.window.title",
					standard: ez5.loca.getBestDatabaseValue(standard?["1"]?.text) or ""
					fieldName: @ColumnSchema._name_localized
				)

				# Add easydb css
				ez5CSSLinkElement = CUI.dom.element("link",
					href: document.location.origin + ez5.cssLoader.getActiveCSS().url
					rel: "stylesheet"
					type: "text/css"
				)
				win.document.head.appendChild(ez5CSSLinkElement)

				# Add plugin css
				plugin = ez5.pluginManager.getPlugin("custom-data-type-html-editor")
				pluginCSSLinkElement = CUI.dom.element("link",
					href: plugin.getBareBaseURL() + plugin.getWebfrontend().css
					rel: "stylesheet"
					type: "text/css"
				)
				win.document.head.appendChild(pluginCSSLinkElement)

				windowInputElement = CUI.dom.element("input")
				windowInputElement.value = initData.value

				verticalLayout = new CUI.VerticalLayout
					class: "ez5-custom-data-type-html-editor-window"
					center:
						content: windowInputElement
					bottom:
						content: new CUI.HorizontalLayout
							right:
								content: new CUI.Buttonbar
									buttons:[
										text: $$("custom.data.type.html-editor.editor.window.button.discard")
										onClick: =>
											confirmationChoice = new CUI.ConfirmationChoice
												text: $$("custom.data.type.html-editor.editor.window.cancel-confirmation")
												title: $$("custom.data.type.html-editor.editor.window.button.discard")
												choices: [
													text: $$("base.cancel")
												,
													text: $$("base.ok")
													onClick: =>
														manualClose = true
														win.close()
												]
											confirmationChoice.open()
											CUI.dom.append(win.document.body, confirmationChoice.getLayerRoot())
											return
									,
										primary: true
										text: $$("custom.data.type.html-editor.editor.window.button.apply")
										onClick: =>
											saveChanges = true
											manualClose = true
											win.close()
									]

				win.document.body.appendChild(verticalLayout.DOM)

				windowInputEditor = null
				CustomDataTypeHtmlEditor.loadLibraryPromise.done(->
					tinymce.init(
						menubar:false
						toolbar: editorToolbar
						target: windowInputElement
						toolbar_mode: 'sliding'
						height: "100%"
						content_css: customCSSURL
						setup: ((inputText) ->
							windowInputEditor = inputText
						)
					)
				)

				win.addEventListener('beforeunload', (e) ->
					if not manualClose
						return e.returnValue = null
					return
				)

				win.addEventListener('unload', ->
					openEditorButton.enable()
					CUI.dom.hideElement(placeholderLabel)
					CUI.dom.showElement(inputEditor.getContainer())
					delete initData._editorWindowOpen

					if saveChanges
						initData.value = windowInputEditor.getContent()
						inputEditor.setContent(initData.value)

						CUI.Events.trigger
							node: editorContent
							type: "editor-changed"
					return
				)

		editorContent = new CUI.VerticalLayout
			top: content: placeholderLabel
			center: content: inputElement
			bottom: content: openEditorButton

		return editorContent

	__getCustomCSSElement: ->
		customCssURL = ez5.session.config.base.system.html_editor?.custom_css_url
		if not customCssURL
			return
		linkElement = CUI.dom.element("link",
			href: customCssURL
			rel: "stylesheet"
			type: "text/css"
		)
		return linkElement

	renderDetailOutput: (data, topLevelData, opts) ->
		initData = @__initData(data)

		resultObject = opts.detail.object
		standard = resultObject.getStandard(topLevelData)

		iframe = CUI.dom.$element("iframe", "ez5-custom-data-type-html-editor-iframe")

		html = CUI.dom.element("html")
		head = CUI.dom.element("head")
		body = CUI.dom.element("body")

		CUI.dom.append(html, head)
		CUI.dom.append(html, body)
		CUI.dom.setStyle(body, "margin": "0px") # Remove the default margin of the HTML.

		CUI.dom.append(body, CUI.dom.htmlToNodes(initData.value))
		customLinkElement = @__getCustomCSSElement()
		if customLinkElement
			CUI.dom.append(head, customLinkElement)

		iframe.addEventListener("load", =>
			iframeContent = iframe.contentDocument.documentElement
			iframeContent.innerHTML = html.innerHTML
		)

		openButton = new LocaButton
			loca_key: "custom.data.type.html-editor.detail.window.open-button"
			appearance: "link"
			size: "mini"
			onClick: =>
				openButton.disable()

				features = "toolbar=no,status=no,menubar=no,scrollbars=yes,width=#{window.innerWidth},height=#{window.innerHeight}"
				win = window.open("", "_blank", features)

				newInputElement = CUI.dom.element("input")
				newInputElement.value = initData.value
				win.document.title = $$("custom.data.type.html-editor.detail.window.title",
					standard: ez5.loca.getBestDatabaseValue(standard?["1"]?.text) or ""
					fieldName: @ColumnSchema._name_localized
				)
				win.document.body.innerHTML = initData.value
				win.addEventListener('beforeunload', ->
					openButton.enable()
				)
				return

		detailContent = new CUI.VerticalLayout
			center:
				content: iframe
			bottom:
				content: openButton
		return detailContent

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
			initData = value: ""
			data[@name()] = initData
		else
			initData = data[@name()]
		initData

	isEmpty: (data) ->
		return CUI.util.isEmpty(data[@name()]?.value)

CustomDataType.register(CustomDataTypeHtmlEditor)

CUI.ready =>
	CustomDataTypeHtmlEditor.loadLibraryPromise = CUI.loadScript("https://cdnjs.cloudflare.com/ajax/libs/tinymce/5.5.1/tinymce.min.js")