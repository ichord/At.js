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

  insert_content_for: ($li) ->
    data_value = $li.data('value')
    tpl = this.get_opt('insert_tpl')
    if @$inputor.is('textarea, input') or not tpl
      return data_value

    data = $.extend {}, $li.data('item-data'), {'atwho-data-value': data_value, 'atwho-at': @at}
    this.callbacks("tpl_eval").call(this, tpl, data)

  # Render list view
  #
  # @param data [Array] The data
  render_view: (data) ->
    search_key = this.get_opt("search_key")
    data = this.callbacks("sorter").call(this, @query.text, data[0..1000] , search_key)
    @view.render data[0...this.get_opt('limit')]

  # Searching!
  look_up: (e) ->
    return if not query = this.catch_query e
    _callback = (data) -> if data and data.length > 0 then this.render_view data else @view.hide()
    @model.query query.text, $.proxy(_callback, this)
    query
