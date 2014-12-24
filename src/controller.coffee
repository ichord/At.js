class Controller
  uid: ->
    (Math.random().toString(16)+"000000000").substr(2,8) + (new Date().getTime())

  constructor: (@app, @at) ->
    @$inputor = @app.$inputor
    @id = @$inputor[0].id || this.uid()

    @setting  = null
    @query    = null
    @pos      = 0
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

  callDefault: (funcName, args...) ->
    try
      DEFAULT_CALLBACKS[funcName].apply this, args
    catch error
      $.error "#{error} Or maybe At.js doesn't have function #{funcName}"

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
    alias = this.getOpt('alias')
    eventName = if alias then "#{name}-#{alias}.atwho" else "#{name}.atwho"
    @$inputor.trigger eventName, data

  # Get callback either in settings which was set by plugin user or in default callbacks list.
  #
  # @param funcName [String] callback's name
  # @return [Function] The callback.
  callbacks: (funcName)->
    this.getOpt("callbacks")[funcName] || DEFAULT_CALLBACKS[funcName]

  # Because different registered at chars have different settings.
  # so we should give their own for them.
  #
  # @param at [String] setting's at name
  # @param default_value [?] return this if nothing is returned from current settings.
  # @return [?] setting's value
  getOpt: (at, default_value) ->
    try
      @setting[at]
    catch e
      null

  insertContentFor: ($li) ->
    tpl = this.getOpt('insert_tpl')
    data = $.extend {}, $li.data('item-data'), {'atwho-at': @at}
    this.callbacks("tpl_eval").call(this, tpl, data)

  # Render list view
  #
  # @param data [Array] The data
  renderView: (data) ->
    search_key = this.getOpt("search_key")
    data = this.callbacks("sorter").call(this, @query.text, data[0..1000] , search_key)
    @view.render data[0...this.getOpt('limit')]

  # Searching!
  lookUp: (e) ->
    return if not query = this.catchQuery e
    _callback = (data) -> if data and data.length > 0 then this.renderView data else @view.hide()
    @model.query query.text, $.proxy(_callback, this)
    query
