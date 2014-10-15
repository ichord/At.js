class Controller
  uid: ->
    (Math.random().toString(16)+"000000000").substr(2,8) + (new Date().getTime())

  constructor: (@app, @at) ->
    @$inputor = @app.$inputor
    @id = @$inputor[0].id || this.uid()

    @setting  = null
    @query    = null
    @pos      = 0
    @cur_rect = null
    @range    = null
    if (@$el = $("#atwho-ground-#{@id}", @app.$el)).length == 0
      @app.$el.append @$el = $("<div id='atwho-ground-#{@id}'></div>")

    @model    = new Model(this)
    @view     = new View(this)

  init: (setting) ->
    @setting = $.extend {}, @setting || $.fn.atwho.default, setting
    @view.init()
    @model.reload @setting.data

  destroy: ->
    this.trigger 'beforeDestroy'
    @model.destroy()
    @view.destroy()
    @$el.remove()

  call_default: (func_name, args...) ->
    try
      DEFAULT_CALLBACKS[func_name].apply this, args
    catch error
      $.error "#{error} Or maybe At.js doesn't have function #{func_name}"

  # Delegate custom `jQueryEvent` to the inputor
  # This function will add `atwho` as namespace to every jQuery event
  # and pass current context as the last param to it.
  #
  # @example
  #   this.trigger "roll_n_rock", [1,2,3,4]
  #
  #   $inputor.on "rool_n_rock", (e, one, two, three, four) ->
  #     console.log one, two, three, four
  #
  # @param name [String] Event name
  # @param data [Array] data to callback
  trigger: (name, data=[]) ->
    data.push this
    alias = this.get_opt('alias')
    event_name = if alias then "#{name}-#{alias}.atwho" else "#{name}.atwho"
    @$inputor.trigger event_name, data

  # Get callback either in settings which was set by plugin user or in default callbacks list.
  #
  # @param func_name [String] callback's name
  # @return [Function] The callback.
  callbacks: (func_name)->
    this.get_opt("callbacks")[func_name] || DEFAULT_CALLBACKS[func_name]

  # Because different registered at chars have different settings.
  # so we should give their own for them.
  #
  # @param at [String] setting's at name
  # @param default_value [?] return this if nothing is returned from current settings.
  # @return [?] setting's value
  get_opt: (at, default_value) ->
    try
      @setting[at]
    catch e
      null

  content: -> if @$inputor.is('textarea, input') then @$inputor.val() else @$inputor.text()

  # Catch query string behind the at char
  #
  # @return [Hash] Info of the query. Look likes this: {'text': "hello", 'head_pos': 0, 'end_pos': 0}
  catch_query: ->
    content = this.content()
    caret_pos = @$inputor.caret('pos', {iframe: @app.iframe})
    subtext = content.slice(0, caret_pos)

    query = this.callbacks("matcher").call(this, @at, subtext, this.get_opt('start_with_space'))
    if typeof query is "string" and query.length <= this.get_opt('max_len', 20)
      start = caret_pos - query.length
      end = start + query.length
      @pos = start
      query = {'text': query, 'head_pos': start, 'end_pos': end}
      this.trigger "matched", [@at, query.text]
    else
      query = null
      @view.hide()

    @query = query

  # Get offset of current at char(`flag`)
  #
  # @return [Hash] the offset which look likes this: {top: y, left: x, bottom: bottom}
  rect: ->
    return if not c = @$inputor.caret('offset', @pos - 1, {iframe: @app.iframe})
    if @app.iframe and not @app.iframeStandalone
      iframe_offset = $(@app.iframe).offset()
      c.left += iframe_offset.left
      c.top += iframe_offset.top
    c = @cur_rect ||= c if @$inputor.is('[contentEditable]')
    scale_bottom = if @app.document.selection then 0 else 2
    {left: c.left, top: c.top, bottom: c.top + c.height + scale_bottom}

  reset_rect: ->
    @cur_rect = null if @$inputor.is('[contentEditable]')

  mark_range: ->
    return if not @$inputor.is('[contentEditable]')
    if @app.window.getSelection and (sel = @app.window.getSelection()).rangeCount > 0
      @range = sel.getRangeAt(0)
    else if @app.document.selection
      @ie8_range = @app.document.selection.createRange()

  insert_content_for: ($li) ->
    data_value = $li.data('value')
    tpl = this.get_opt('insert_tpl')
    if @$inputor.is('textarea, input') or not tpl
      return data_value

    data = $.extend {}, $li.data('item-data'), {'atwho-data-value': data_value, 'atwho-at': @at}
    this.callbacks("tpl_eval").call(this, tpl, data)

  # Insert value of `data-value` attribute of chosen item into inputor
  #
  # @param content [String] string to insert
  insert: (content, $li) ->
    $inputor = @$inputor

    wrapped_content = this.callbacks('inserting_wrapper').call this, $inputor, content, this.get_opt("suffix")

    if $inputor.is('textarea, input')
      source = $inputor.val()
      start_str = source.slice 0, Math.max(@query.head_pos - @at.length, 0)
      text = "#{start_str}#{wrapped_content}#{source.slice @query['end_pos'] || 0}"
      $inputor.val text
      $inputor.caret('pos', start_str.length + wrapped_content.length, {iframe: @app.iframe})
    else if range = @range
      pos = range.startOffset - (@query.end_pos - @query.head_pos) - @at.length
      range.setStart(range.endContainer, Math.max(pos,0))
      range.setEnd(range.endContainer, range.endOffset)
      range.deleteContents()
      content_node = $(wrapped_content, @app.document)[0]
      range.insertNode content_node
      range.setEndAfter content_node
      range.collapse(false)
      sel = @app.window.getSelection()
      sel.removeAllRanges()
      sel.addRange(range)
    else if range = @ie8_range # IE < 9
      # NOTE: have to add this <meta http-equiv="x-ua-compatible" content="IE=Edge"/> into <header>
      #       to make it work batter.
      # REF:  http://stackoverflow.com/questions/15535933/ie-html1114-error-with-custom-cleditor-button?answertab=votes#tab-top
      range.moveStart('character', @query.end_pos - @query.head_pos - @at.length)
      range.pasteHTML wrapped_content
      range.collapse(false)
      range.select()
    $inputor.focus() if not $inputor.is ':focus'
    $inputor.change()

  # Render list view
  #
  # @param data [Array] The data
  render_view: (data) ->
    search_key = this.get_opt("search_key")
    data = this.callbacks("sorter").call(this, @query.text, data[0..1000] , search_key)
    @view.render data[0...this.get_opt('limit')]

  # Searching!
  look_up: ->
    return if not (query = this.catch_query())
    _callback = (data) -> if data and data.length > 0 then this.render_view data else @view.hide()
    @model.query query.text, $.proxy(_callback, this)
    query
