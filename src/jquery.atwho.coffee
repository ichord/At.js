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

    # It would be called to restrcture the data when At.js invoke `reset` to save data
    # Often invoke it when reg a `flag`("@", etc).
    # In default, At.js will convert it to a Hash Array.
    #
    # @param data [Array] data to refacotor.
    #
    # @return [Array] Data after refactor.
    before_save: (data) ->
      return data if not $.isArray data
      for item in data
        if $.isPlainObject item then item else name:item

    # It would be called to match the `flag`
    #
    # @param flag [String] current `flag` ("@", etc)
    # @param subtext [String] Text from start to current caret position.
    #
    # @return [String] Matched string.
    matcher: (flag, subtext) ->
      # escape RegExp
      flag = " " + flag.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
      regexp = new RegExp flag+'([A-Za-z0-9_\+\-]*)$|'+flag+'([^\\x00-\\xff]*)$','gi'
      match = regexp.exec subtext
      if match then match[2] || match[1] else null

    # ---------------------

    # Filter data by matched string.
    #
    # @param query [String] Matched string.
    # @param data [Array] data list
    # @param search_key [String] key char for seaching.
    #
    # @return [Array] result data.
    filter: (query, data, search_key) ->
      # !!null #=> false; !!undefined #=> false; !!'' #=> false;
      _results = []
      for item in data
        _results.push item if ~item[search_key].toLowerCase().indexOf query
      _results

    # It function is given, At.js will invoke it if local filter can not find any data
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
      if !query
        return items.sort (a, b) -> if a[search_key].toLowerCase() > b[search_key].toLowerCase() then 1 else -1
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

    # Hightlight the `matched query` string.
    #
    # @param li [String] HTML String after eval.
    # @param query [String] matched query.
    #
    # @return [String] hightlighted string.
    highlighter: (li, query) ->
      return li if not query
      regexp = new RegExp(">\\s*(\\w*)(" + query.replace("+","\\+") + ")(\\w*)\\s*<", 'ig')
      li.replace regexp, (str, $1, $2, $3) -> '> '+$1+'<strong>' + $2 + '</strong>'+$3+' <'

    # What to do after use choose a item.
    #
    # @param $li [jQuery Object] Chosen item
    before_insert: (value, $li) ->
      value

  class Model
    _storage = {}

    constructor: (@context, @key) ->

    saved: ->
      this.fetch() > 0

    query: (query, callback) ->
      data = this.fetch()
      search_key = @context.get_opt("search_key")

      data = @context.callbacks('filter').call(@context, query, data, search_key)
      if data and data.length > 0
        callback(data)
      else if (remote_filter = @context.callbacks('remote_filter'))
        remote_filter.call(@context, query, callback)

    # get or set current data which would be shown on the list view.
    #
    # @param data [Array] set data
    # @return [Array|undefined] current data that showing on the list view.
    fetch: ->
      _storage[@key] || []

    save: (data) ->
      _storage[@key] = @context.callbacks("before_save").call(@context, data)

    load: (data) ->
      this._load(data) unless this.saved() or not data

    reload: (data) ->
      this._load(data)

    _load: (data) ->
      if typeof data is "string"
        $.ajax(data, dataType: "json").done (data) => this.save(data)
      else
        this.save data

  # At.js central contoller(searching, matching, evaluating and rendering.)
  class Controller
    _uuid = 0
    uuid = ->
      _uuid += 1
    # @param inputor [HTML DOM Object] `input` or `textarea`
    constructor: (inputor) ->
      @id = inputor.id || uuid()
      @settings     = {}
      @pos          = 0
      @current_flag = null
      @query        = null
      @the_flag = {}
      @_views = {}
      @_models = {}

      @$inputor = $(inputor)
      $CONTAINER.append @$el = $("<div id='atwho-ground-#{@id}'></div>")
      this.listen()

    # binding jQuery events of `inputor`'s
    listen: ->
      @$inputor
        .on 'keyup.atwho', (e) =>
          this.on_keyup(e)
        .on 'keydown.atwho', (e) =>
          this.on_keydown(e)
        .on 'scroll.atwho', (e) =>
          @view.hide()
        .on 'blur.atwho', (e) =>
          @view.hide this.get_opt("display_timeout")

    set_context_for: (flag) ->
      flag = @current_flag = @the_flag[flag]
      @view = @_views[flag]
      @model = @_models[flag]
      this

    # At.js can register multipule key char (flag) to every inputor such as "@" and ":"
    # And their has it's own `settings` so that it work differently.
    # After register, we still can update their `settings` such as updating `data`
    #
    # @param flag [String] key char (flag)
    # @param settings [Hash] the settings
    reg: (flag, settings) ->
      setting = @settings[flag] = $.extend {}, @settings[flag] || $.fn.atwho.default, settings

      this.set_context_for flag = (
        @the_flag[setting.alias] = flag if setting.alias
        @the_flag[flag] = flag
      )

      (@_models[flag] = new Model(this, flag)).reload setting.data
      @_views[flag] = new View(this, flag)

      this

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

    super_call: (func_name, args...) ->
      try
        DEFAULT_CALLBACKS[func_name].apply this, args
      catch error
        $.error "#{error} Or maybe At.js doesn't have function #{func_name}"

    # Get callback either in settings which was set by plugin user or in default callbacks list.
    #
    # @param func_name [String] callback's name
    # @return [Function] The callback.
    callbacks: (func_name)->
      this.get_opt("callbacks")[func_name] || DEFAULT_CALLBACKS[func_name]

    # Because different reigstered key char has different settings.
    # so we should give their own for them.
    #
    # @param key [String] setting's key name
    # @param default_value [?] return this if get nothing from current settings.
    # @return [?] setting's value
    get_opt: (key, default_value) ->
      try
        @settings[@current_flag][key]
      catch e
        null

    # Get offset of current key char(`flag`)
    #
    # @return [Hash] the offset which look likes this: {top: y, left: x, bottom: bottom}
    rect: ->
      c = @$inputor.caret('offset', @pos - 1)
      scale_bottom = if document.selection then 0 else 2
      {left: c.left, top: c.top, bottom: c.top + c.height + scale_bottom}

    # Catch query string behind the key char
    #
    # @return [Hash] Info of the query. Look likes this: {'text': "hello", 'head_pos': 0, 'end_pos': 0}
    catch_query: ->
      content = @$inputor.val()
      caret_pos = @$inputor.caret('pos')
      subtext = content.slice(0,caret_pos)

      query = null
      $.map @settings, (setting) =>
        _result = this.callbacks("matcher").call(this, setting.at, subtext)
        if _result?
          query = _result
          this.set_context_for(setting.at)

      if typeof query is "string" and query.length <= this.get_opt('max_len', 20)
        start = caret_pos - query.length
        end = start + query.length
        @pos = start
        query = {'text': query.toLowerCase(), 'head_pos': start, 'end_pos': end}
        this.trigger "matched", [@current_flag, query.text]
      else
        @view?.hide()

      @query = query

    # Insert value of `data-value` attribute of choosed item into inputor
    #
    # @param str [String] string to insert
    insert: (str) ->
      $inputor = @$inputor
      # ensure str is str.
      # BTW: Good way to change num into str: http://jsperf.com/number-to-string/2
      str = '' + str
      source = $inputor.val()
      flag_len = if this.get_opt("display_flag") then 0 else @current_flag.length
      start_str = source.slice 0, (@query['head_pos'] || 0) - flag_len
      text = "#{start_str}#{str} #{source.slice @query['end_pos'] || 0}"

      $inputor.val text
      $inputor.caret 'pos',start_str.length + str.length + 1
      $inputor.change()

    on_keyup: (e) ->
      switch e.keyCode
        when KEY_CODE.ESC
          e.preventDefault()
          @view.hide()
        when KEY_CODE.DOWN, KEY_CODE.UP
          $.noop()
        else
          this.look_up()
      # coffeescript will return everywhere!!
      return

    on_keydown: (e) ->
      return if not @view?.visible()
      switch e.keyCode
        when KEY_CODE.ESC
          e.preventDefault()
          @view.hide()
        when KEY_CODE.UP
          e.preventDefault()
          @view.prev()
        when KEY_CODE.DOWN
          e.preventDefault()
          @view.next()
        when KEY_CODE.TAB, KEY_CODE.ENTER
          return if not @view.visible()
          e.preventDefault()
          @view.choose()
        else
          $.noop()
      return

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
      _callback = (data) -> if data then this.render_view data else @view.hide()
      @model.query query.text, $.proxy(_callback, this)


  # View class to controll how At.js's view showing.
  # All classes share the some DOM view.
  class View

    # @param controller [Object] The Controller.
    constructor: (@context, @key) ->
      @id = @context.get_opt("alias") || "at-view-#{@key.charCodeAt(0)}"
      @$el = $("<div id='#{@id}' class='atwho-view'><ul id='#{@id}-ul' class='atwho-view-url'></ul></div>")
      @timeout_id = null

      # create HTML DOM of list view if it does not exists
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


  DEFAULT_TPL = "<li data-value='${name}'>${name}</li>"

  Api =
    init: (options) ->
      app = ($this = $(this)).data "atwho"
      $this.data 'atwho', (app = new Controller(this)) if not app
      app.reg options.at, options

    load: (flag, data) ->
      this.set_context_for flag
      this.model.load data

    run: ->
      this.look_up()

  $CONTAINER = $("<div id='atwho-container'></div>")

  $.fn.atwho = (method) ->
    _args = arguments
    $('body').append($CONTAINER)
    @.filter('textarea, input').each () ->
      if typeof method is 'object' || !method
        Api.init.apply this, _args
      else if Api[method]
        Api[method].apply $(this).data('atwho'), Array::slice.call(_args, 1)
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
    display_flag: yes
    display_timeout: 300
