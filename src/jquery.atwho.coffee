###
  Implement Github like autocomplete mentions
  http://ichord.github.com/At.js

  Copyright (c) 2013 chord.luo@gmail.com
  Licensed under the MIT license.
###

( (factory) ->
  # Uses AMD or browser globals to create a jQuery plugin.
  # It does not try to register in a CommonJS environment since
  # jQuery is not likely to run in those environments.
  #
  # form [umd](https://github.com/umdjs/umd) project
  if typeof define is 'function' and define.amd
    # Register as an anonymous AMD module:
    define ['jquery'], factory
  else
    # Browser globals
    factory window.jQuery
) ($) ->

  # At.js central contoller(searching, matching, evaluating and rendering.)
  class App

    # @param inputor [HTML DOM Object] `input` or `textarea`
    constructor: (inputor) ->
      @current_flag = null
      @controllers = {}
      @$inputor = $(inputor)
      this.listen()

    controller: (key) ->
      @controllers[key || @current_flag]

    set_context_for: (key) ->
      @current_flag = key
      this

    # At.js can register multiple key char (flag) to every inputor such as "@" and ":"
    # Along with their own `settings` so that it works differently.
    # After register, we still can update their `settings` such as updating `data`
    #
    # @param flag [String] key char (flag)
    # @param settings [Hash] the settings
    reg: (flag, setting) ->
      controller = @controllers[flag] ||= new Controller(this, flag)
      @controllers[setting.alias] = controller if setting.alias
      controller.init setting
      this

    # binding jQuery events of `inputor`'s
    listen: ->
      @$inputor
        .on 'keyup.atwho', (e) =>
          this.on_keyup(e)
        .on 'keydown.atwho', (e) =>
          this.on_keydown(e)
        .on 'scroll.atwho', (e) =>
          this.controller()?.view.hide()
        .on 'blur.atwho', (e) =>
          c.view.hide(c.get_opt("display_timeout")) if c = this.controller()

    dispatch: ->
      $.map @controllers, (c) =>
        this.set_context_for c.key if c.look_up()

    on_keyup: (e) ->
      switch e.keyCode
        when KEY_CODE.ESC
          e.preventDefault()
          this.controller()?.view.hide()
        when KEY_CODE.DOWN, KEY_CODE.UP
          $.noop()
        else
          this.dispatch()
      # coffeescript will return everywhere!!
      return

    on_keydown: (e) ->
      # return if not (view = this.controller().view).visible()
      view = this.controller()?.view
      return if not (view and view.visible())
      switch e.keyCode
        when KEY_CODE.ESC
          e.preventDefault()
          view.hide()
        when KEY_CODE.UP
          e.preventDefault()
          view.prev()
        when KEY_CODE.DOWN
          e.preventDefault()
          view.next()
        when KEY_CODE.TAB, KEY_CODE.ENTER
          return if not view.visible()
          e.preventDefault()
          view.choose()
        else
          $.noop()
      return

  class Controller
    _uuid = 0
    uuid = ->
      _uuid += 1

    constructor: (@app, @key) ->
      @$inputor = @app.$inputor
      @id = @$inputor[0].id || uuid()
      @setting  = null
      @query    = null
      @pos      = 0
      $CONTAINER.append @$el = $("<div id='atwho-ground-#{@id}'></div>")

      @model    = new Model(this)
      @view     = new View(this)


    init: (setting) ->
      @setting = $.extend {}, @setting || $.fn.atwho.default, setting
      @model.reload @setting.data

    super_call: (func_name, args...) ->
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
    trigger: (name, data) ->
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

    # Because different registered key chars have different settings.
    # so we should give their own for them.
    #
    # @param key [String] setting's key name
    # @param default_value [?] return this if nothing is returned from current settings.
    # @return [?] setting's value
    get_opt: (key, default_value) ->
      try
        @setting[key]
      catch e
        null

    # Catch query string behind the key char
    #
    # @return [Hash] Info of the query. Look likes this: {'text': "hello", 'head_pos': 0, 'end_pos': 0}
    catch_query: ->
      content = @$inputor.val()
      caret_pos = @$inputor.caret('pos')
      subtext = content.slice(0,caret_pos)

      query = this.callbacks("matcher").call(this, @key, subtext)

      if typeof query is "string" and query.length <= this.get_opt('max_len', 20)
        start = caret_pos - query.length
        end = start + query.length
        @pos = start
        query = {'text': query.toLowerCase(), 'head_pos': start, 'end_pos': end}
        this.trigger "matched", [@key, query.text]
      else
        @view.hide()

      @query = query

    # Get offset of current key char(`flag`)
    #
    # @return [Hash] the offset which look likes this: {top: y, left: x, bottom: bottom}
    rect: ->
      c = @$inputor.caret('offset', @pos - 1)
      scale_bottom = if document.selection then 0 else 2
      {left: c.left, top: c.top, bottom: c.top + c.height + scale_bottom}

    # Insert value of `data-value` attribute of chosen item into inputor
    #
    # @param str [String] string to insert
    insert: (str) ->
      $inputor = @$inputor
      # ensure str is str.
      # BTW: Good way to change num into str: http://jsperf.com/number-to-string/2
      str = '' + str
      source = $inputor.val()
      start_str = source.slice 0, (@query['head_pos'] || 0) - @key.length
      text = "#{start_str}#{str} #{source.slice @query['end_pos'] || 0}"

      $inputor.val text
      $inputor.caret 'pos',start_str.length + str.length + 1
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

  # Class to process data
  class Model
    _storage = {}

    constructor: (@context) ->
      @key = @context.key

    saved: ->
      this.fetch() > 0

    # fetch data from storage by query.
    # will invoke `callback` to return data
    #
    # @param query [String] catched string for searching
    # @param callback [Function] for receiving data
    query: (query, callback) ->
      data = this.fetch()
      search_key = @context.get_opt("search_key")
      callback data = @context.callbacks('filter').call(@context, query, data, search_key)
      @context.callbacks('remote_filter')?.call(@context, query, callback) unless data and data.length > 0

    # get or set current data which would be shown on the list view.
    #
    # @param data [Array] set data
    # @return [Array|undefined] current data that are showing on the list view.
    fetch: ->
      _storage[@key] || []

    # save special flag's data to storage
    #
    # @param data [Array] data to save
    save: (data) ->
      _storage[@key] = @context.callbacks("before_save").call(@context, data || [])

    # load data. It wouldn't load for a second time if it has been loaded.
    #
    # @param data [Array] data to load
    load: (data) ->
      this._load(data) unless this.saved() or not data

    reload: (data) ->
      this._load(data)

    # load data from local or remote with callback
    #
    # @param data [Array|String] data to load.
    _load: (data) ->
      if typeof data is "string"
        $.ajax(data, dataType: "json").done (data) => this.save(data)
      else
        this.save data

  # View class to control how At.js's view showing.
  # All classes share the same DOM view.
  class View

    # @param controller [Object] The Controller.
    constructor: (@context) ->
      @key = @context.key
      @id = @context.get_opt("alias") || "at-view-#{@key.charCodeAt(0)}"
      @$el = $("<div id='#{@id}' class='atwho-view'><ul id='#{@id}-ul' class='atwho-view-url'></ul></div>")
      @timeout_id = null

      # create HTML DOM of list view if it does not exist
      @context.$el.append(@$el)
      this.bind_event()

    bind_event: ->
      $menu = @$el.find('ul')
      $menu.on 'mouseenter.view','li', (e) ->
        $menu.find('.cur').removeClass 'cur'
        $(e.currentTarget).addClass 'cur'
      .on 'click', (e) =>
        this.choose()
        e.preventDefault()

    # Check if view is visible
    #
    # @return [Boolean]
    visible: ->
      @$el.is(":visible")

    choose: ->
      $li = @$el.find ".cur"
      @context.insert @context.callbacks("before_insert").call(@context, $li.data("value"), $li)
      @context.trigger "inserted", [$li]
      this.hide()

    reposition: ->
      rect = @context.rect()
      if rect.bottom + @$el.height() - $(window).scrollTop() > $(window).height()
          rect.bottom = rect.top - @$el.height()
      offset = {left:rect.left, top:rect.bottom}
      @$el.offset offset
      @context.trigger "reposition", [offset]

    next: ->
      cur = @$el.find('.cur').removeClass('cur')
      next = cur.next()
      next = @$el.find('li:first') if not next.length
      next.addClass 'cur'

    prev: ->
      cur = @$el.find('.cur').removeClass('cur')
      prev = cur.prev()
      prev = @$el.find('li:last') if not prev.length
      prev.addClass 'cur'

    show: ->
      @$el.show() if not this.visible()
      this.reposition()

    hide: (time) ->
      if isNaN time and this.visible()
        @$el.hide()
      else
        callback = => this.hide()
        clearTimeout @timeout_id
        @timeout_id = setTimeout callback, time

    # render list view
    render: (list) ->
      if not $.isArray list or list.length <= 0
        this.hide()
        return

      @$el.find('ul').empty()
      $ul = @$el.find('ul')
      tpl = @context.get_opt('tpl', DEFAULT_TPL)

      for item in list
        li = @context.callbacks("tpl_eval").call(@context, tpl, item)
        $li = $ @context.callbacks("highlighter").call(@context, li, @context.query.text)
        $li.data("atwho-info", item)
        $ul.append $li

      this.show()
      $ul.find("li:first").addClass "cur"

  KEY_CODE =
    DOWN: 40
    UP: 38
    ESC: 27
    TAB: 9
    ENTER: 13

  # Functions set for handling and rendering the data.
  # Others developers can override these methods to tweak At.js such as matcher.
  # We can override them in `callbacks` settings.
  #
  # @mixin
  #
  # The context of these functions is `$.atwho.Controller` object and they are called in this sequences:
  #
  # [before_save, matcher, filter, remote_filter, sorter, tpl_evl, highlighter, before_insert]
  #
  DEFAULT_CALLBACKS =

    # It would be called to restructure the data before At.js invokes `Model#save` to save data
    # In default, At.js will convert it to a Hash Array.
    #
    # @param data [Array] data to refacotor.
    # @return [Array] Data after refactor.
    before_save: (data) ->
      return data if not $.isArray data
      for item in data
        if $.isPlainObject item then item else name:item

    # It would be called to match the `flag`.
    # It will match at start of line or after whitespace
    #
    # @param flag [String] current `flag` ("@", etc)
    # @param subtext [String] Text from start to current caret position.
    #
    # @return [String | null] Matched result.
    matcher: (flag, subtext) ->
      # escape RegExp
      flag = '(?:^|\\s)' + flag.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
      regexp = new RegExp flag+'([A-Za-z0-9_\+\-]*)$|'+flag+'([^\\x00-\\xff]*)$','gi'
      match = regexp.exec subtext
      if match then match[2] || match[1] else null

    # ---------------------

    # Filter data by matched string.
    #
    # @param query [String] Matched string.
    # @param data [Array] data list
    # @param search_key [String] key char for searching.
    #
    # @return [Array] result data.
    filter: (query, data, search_key) ->
      # !!null #=> false; !!undefined #=> false; !!'' #=> false;
      _results = []
      for item in data
        _results.push item if ~item[search_key].toLowerCase().indexOf query
      _results

    # If a function is given, At.js will invoke it if local filter can not find any data
    #
    # @param params [String] matched query
    # @param callback [Function] callback to render page.
    remote_filter: null
    # remote_filter: (query, callback) ->
    #   $.ajax url,
    #     data: params
    #     success: (data) ->
    #       render_view(data)

    # Sorter data of course.
    #
    # @param query [String] matched string
    # @param items [Array] data that was refactored
    # @param search_key [String] key char to search
    #
    # @return [Array] sorted data
    sorter: (query, items, search_key) ->
      return items unless query

      _results = []
      for item in items
        item.atwho_order = item[search_key].toLowerCase().indexOf query
        _results.push item if item.atwho_order > -1

      _results.sort (a,b) -> a.atwho_order - b.atwho_order

    # Eval template for every single item in display list.
    #
    # @param tpl [String] The template string.
    # @param map [Hash] Data map to eval.
    tpl_eval: (tpl, map) ->
      try
        tpl.replace /\$\{([^\}]*)\}/g, (tag, key, pos) -> map[key]
      catch error
        ""

    # Highlight the `matched query` string.
    #
    # @param li [String] HTML String after eval.
    # @param query [String] matched query.
    #
    # @return [String] highlighted string.
    highlighter: (li, query) ->
      return li if not query
      regexp = new RegExp(">\\s*(\\w*)(" + query.replace("+","\\+") + ")(\\w*)\\s*<", 'ig')
      li.replace regexp, (str, $1, $2, $3) -> '> '+$1+'<strong>' + $2 + '</strong>'+$3+' <'

    # What to do before inserting item's value into inputor.
    #
    # @param value [String] content to insert
    # @param $li [jQuery Object] the chosen item
    before_insert: (value, $li) ->
      value


  DEFAULT_TPL = "<li data-value='${name}'>${name}</li>"

  Api =
    # init or update an inputor with a special flag
    #
    # @params options [Object] settings of At.js
    init: (options) ->
      app = ($this = $(this)).data "atwho"
      $this.data 'atwho', (app = new App(this)) if not app
      app.reg options.at, options

    # load a flag's data
    #
    # @params key[String] the flag
    # @params data [Array] data to storage.
    load: (key, data) ->
      c.model.load data if c = this.controller(key)

    run: ->
      this.dispatch()

  $CONTAINER = $("<div id='atwho-container'></div>")

  $.fn.atwho = (method) ->
    _args = arguments
    $('body').append($CONTAINER)
    @.filter('textarea, input').each () ->
      if typeof method is 'object' || !method
        Api.init.apply this, _args
      else if Api[method]
        Api[method].apply app, Array::slice.call(_args, 1) if app = $(this).data('atwho')
      else
        $.error "Method #{method} does not exist on jQuery.caret"

  $.fn.atwho.default =
    at: undefined
    alias: undefined
    data: null
    tpl: DEFAULT_TPL
    callbacks: DEFAULT_CALLBACKS
    search_key: "name"
    limit: 5
    max_len: 20
    display_timeout: 300
