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
  # [loading_data, matcher, filter, remote_filter, sorter, tpl_evl, highlighter, selector]
  #
  DEFAULT_CALLBACKS =

    # It would be called to restrcture the data when At.js invoke `reset` to save data
    # Often invoke it when reg a `flag`("@", etc).
    # In default, At.js will convert it to a Hash Array.
    #
    # @param data [Array] data to refacotor.
    #
    # @return [Array] Data after refactor.
    loading_data: (data) ->
      return data if not $.isArray(data)
      $.map data, (item, k) ->
        if not $.isPlainObject item
          item = {name:item}
        return item

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
      matched = null
      if match
        matched = if match[2] then match[2] else match[1]
      matched

    # ---------------------

    # Filter data by matched string.
    #
    # @param query [String] Matched string.
    # @param data [Array] data list
    # @param search_key [String] key char for seaching.
    #
    # @return [Array] result data.
    filter: (query, data, search_key) ->
      $.map data, (item,i) =>
        name = if $.isPlainObject(item) then item[search_key] else item
        item if name.toLowerCase().indexOf(query) >= 0

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
        return items.sort (a, b) ->
          if a[search_key].toLowerCase() > b[search_key].toLowerCase() then 1 else -1

      results = []

      for item in items
        text = item[search_key]
        item.atwho_order = text.toLowerCase().indexOf query
        results.push(item)

      results.sort (a,b) ->
        a.atwho_order - b.atwho_order

      results = for item in results
        delete item["atwho_order"]
        item


    # Eval template for every single item in display list.
    #
    # @param tpl [String] The template string.
    # @param map [Hash] Data map to eval.
    tpl_eval: (tpl, map) ->
      try
        el = tpl.replace /\$\{([^\}]*)\}/g, (tag,key,pos) ->
          map[key]
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
      li.replace new RegExp(">\\s*(\\w*)(" + query.replace("+","\\+") + ")(\\w*)\\s*<", 'ig'), (str,$1, $2, $3) ->
          '> '+$1+'<strong>' + $2 + '</strong>'+$3+' <'

    # What to do after use choose a item.
    #
    # @param $li [jQuery Object] Chosen item
    selector: ($li) ->
      this.replace_str($li.data("value") || "") if $li.length > 0

  class Model
    constructor: (@context) ->
      # all data either from `settings` or from anywhere be saved by `reset` function.
      @_data_sets = {}
      @_loaded_keys = []

    query: (query, callback) ->
      data = this.all() || []
      search_key = @context.get_opt("search_key")

      data = @context.callbacks('filter').call(@context, query, data, search_key)
      if data and data.length > 0
        callback(data)
      else if (remote_filter = @context.callbacks('remote_filter'))
        remote_filter.call(@context, query && query.text, callback)
      else
        return no
      yes

    # get or set current data which would be shown on the list view.
    #
    # @param data [Array] set data
    # @return [Array|undefined] current data that showing on the list view.
    all: (key) ->
      @_data_sets[key ||= @context.current_flag]

    reset: (data, key) ->
      key ||= @context.current_flag
      data = @_data_sets[key] = @context.callbacks("loading_data").call(@context, data)
      @_loaded_keys[key] = true if data and data.length > 0

    load: (key, data) ->
      return if @_loaded_keys[key]

      if typeof data is "string"
        this._load_remote_data data, key
      else
        this.reset data, key

    _load_remote_data: (url, key) ->
      $.ajax(url,
        dataType: "json"
      ).done (data) =>
        this.reset(key, data)


  # At.js central contoller(searching, matching, evaluating and rendering.)
  class Controller

    # @param inputor [HTML DOM Object] `input` or `textarea`
    constructor: (inputor) ->
      @settings     = {}
      @pos          = 0
      @flags        = null
      @current_flag = null
      @query        = null
      @loaded_flags = []

      @$inputor = $(inputor)
      @view = new View(this, @$el)
      @model = new Model(this)

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

    # At.js can register multipule key char (flag) to every inputor such as "@" and ":"
    # And their has it's own `settings` so that it work differently.
    # After register, we still can update their `settings` such as updating `data`
    #
    # @param flag [String] key char (flag)
    # @param settings [Hash] the settings
    reg: (flag, settings) ->
      @current_flag = flag
      current_setting = if @settings[flag]
        @settings[flag] = $.extend {}, @settings[flag], settings
      else
        @settings[flag] = $.extend {}, $.fn.atwho.default, settings

      @model.load flag, current_setting.data

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
      data ||= []
      data.push this
      @$inputor.trigger "#{name}.atwho", data

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
      func = this.get_opt("callbacks")[func_name]
      func = DEFAULT_CALLBACKS[func_name] unless func
      func

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
      if document.selection # IE
        scale_bottom = scale = 0
      else
        scale = 0
        scale_bottom = 2
      {left:c.left + scale, top:c.top + scale, bottom: c.top+c.height + scale_bottom}

    # Catch query string behind the key char
    #
    # @return [Hash] Info of the query. Look likes this: {'text': "hello", 'head_pos': 0, 'end_pos': 0}
    catch_query: ->
      content = @$inputor.val()
      caret_pos = @$inputor.caret('pos')
      subtext = content.slice(0,caret_pos)

      query = null
      $.each @settings, (flag, settings) =>
        query = this.callbacks("matcher").call(this, flag, subtext)
        if query?
          @current_flag = flag
          return false

      if typeof query is "string" and query.length <= 20
        start = caret_pos - query.length
        end = start + query.length
        @pos = start
        query = {'text': query.toLowerCase(), 'head_pos': start, 'end_pos': end}
        this.trigger "matched", [@current_flag, query.text]
      else
        @view.hide()

      @query = query

    # Insert value of `data-value` attribute of choosed item into inputor
    #
    # @param str [String] string to insert
    replace_str: (str) ->
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
      return if not @view.visible()
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
      data = this.callbacks("sorter").call(this, @query.text, data, search_key)
      data = data.slice(0, this.get_opt('limit'))

      @view.render data

    # Searching!
    #
    look_up: ->
      query = this.catch_query()
      return if not query

      _callback = (data) ->
        if data
          this.render_view data
        else
          @view.hide()
      _callback = $.proxy _callback, this

      @view.hide() unless @model.query(query.text, _callback)


  # View class to controll how At.js's view showing.
  # All classes share the some DOM view.
  class View

    # @param controller [Object] The Controller.
    constructor: (@context) ->
      @id = @context.get_opt("view_id") || "at-view"
      @timeout_id = null
      @$el = $("##{@id}")
      this.create_view()

    # create HTML DOM of list view if it does not exists
    create_view: ->
      return if this.exist()
      tpl = "<div id='#{@id}' class='at-view'><ul id='#{@id}-ul'></ul></div>"
      $("body").append(tpl)
      @$el = $("##{@id}")

      $menu = @$el.find('ul')
      $menu.on 'mouseenter.view','li', (e) ->
        $menu.find('.cur').removeClass 'cur'
        $(e.currentTarget).addClass 'cur'
      .on 'click', (e) =>
        e.preventDefault()
        @$el.data("_view").choose()


    # Check if the view is exists
    #
    # @return [Boolean]
    exist: ->
      $("##{@id}").length > 0

    # Check if view is visible
    #
    # @return [Boolean]
    visible: ->
      @$el.is(":visible")

    choose: ->
      $li = @$el.find ".cur"
      @context.callbacks("selector").call(@context, $li)
      @context.trigger "choose", [$li]
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
      next = $(@$el.find('li')[0]) if not next.length
      next.addClass 'cur'

    prev: ->
      cur = @$el.find('.cur').removeClass('cur')
      prev = cur.prev()
      prev = @$el.find('li').last() if not prev.length
      prev.addClass('cur')

    show: ->
      @$el.show() if not this.visible()
      this.reposition()

    hide: (time) ->
      if isNaN time
        @$el.hide() if this.visible()
      else
        callback = =>
          this.hide()
        clearTimeout @timeout_id
        @timeout_id = setTimeout callback, time

    clear: ->
      @$el.find('ul').empty()

    render: (list) ->
      return no if not $.isArray(list)
      if list.length <= 0
        this.hide()
        return yes

      this.clear()
      @$el.data("_view",this)

      $ul = @$el.find('ul')
      tpl = @context.get_opt('tpl', DEFAULT_TPL)

      $.each list, (i, item) =>
        li = @context.callbacks("tpl_eval").call(@context, tpl, item)
        $li = $ @context.callbacks("highlighter").call(@context, li, @context.query.text)
        $li.data("info", item)
        $ul.append $li

      this.show()
      $ul.find("li:eq(0)").addClass "cur"


  DEFAULT_TPL = "<li data-value='${name}'>${name}</li>"

  methods =
    init: (options) ->
      $this = $(this)
      data = $this.data "atwho"
      $this.data 'atwho', (data = new Controller(this)) if not data
      data.reg options.at, options

    load: (flag, data) ->
      _loader = (flag, data) ->
        this.model.load flag, data
      _loader = $.proxy(_loader, this)
      if $.isFunction data
        data(_loader)
      else
        _loader(flag, data)

  $.fn.atwho = (method) ->
    _args = arguments
    @.filter('textarea, input').each () ->
      if typeof method is 'object' || !method
        methods.init.apply this, _args
      else if methods[method]
        methods[method].apply $(this).data('atwho'), Array::slice.call(_args, 1)
      else
        $.error "Method #{method} does not exist on jQuery.caret"

  $.fn.atwho.default =
    data: null
    search_key: "name"
    callbacks: DEFAULT_CALLBACKS
    limit: 5
    display_flag: yes
    display_timeout: 300
    tpl: DEFAULT_TPL
