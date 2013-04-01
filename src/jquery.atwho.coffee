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

  # Controller 用于处理渲染数据的一组方法.
  #为了方便开发者可以自定义插件的部分功能而独立出来.
  #
  # @mixin
  #
  # 以下所有方法的调用上下文都是 Controller. 并且按照文档显示的顺序调用
  #
  # 也就是这个顺序 [data_refactor, matcher, filter, remote_filter, sorter, tpl_evl, highlighter, selector]
  #
  # 以默认配置的方式 Mixin 到 Controller 里.
  DEFAULT_CALLBACKS =

    # 用于插件最开始时对设置的数据进行重构.
    # 默认情况下将数组组织成Hash形式.
    #
    # @param data [Array] 开发者自己在配置中设置的数据列表
    #
    # @return [Array] 重构后的数据列表
    data_refactor: (data) ->
      return data if not $.isArray(data)
      $.map data, (item, k) ->
        if not $.isPlainObject item
          item = {name:item}
        return item

    # 匹配当前标记后面字符串的匹配规则
    #
    # @param flag [String] 当前标记 ("@", etc)
    # @param subtext [String] 输入框从开始到插入符号前的字符串
    #
    # @return [String] 匹配后得到的字符串
    matcher: (flag, subtext) ->
      regexp = new RegExp flag+'([A-Za-z0-9_\+\-]*)$|'+flag+'([^\\x00-\\xff]*)$','gi'
      match = regexp.exec subtext
      matched = null
      if match
        matched = if match[2] then match[2] else match[1]
      matched

    # ---------------------

    # 根据匹配的的字符串搜索数据
    #
    # @param query [String] 匹配得到的字符串
    # @param data [Array] 数据列表
    # @param search_key [String] 用于搜索的关键字
    #
    # @return [Array] 过滤后的数据
    filter: (query, data, search_key) ->
      $.map data, (item,i) =>
        name = if $.isPlainObject(item) then item[search_key] else item
        item if name.toLowerCase().indexOf(query) >= 0

    # 当 `data` 设置为 url 的时候, 我们使用这个 filter 来发起 ajax 请求
    #
    # @param params [Hash] ajax 请求参数. {"search_term": query, limit: 5}
    # @param url [String] 开发者自己设置的 url 地址
    # @param render_view [Function] 将数据渲染到下拉列表的回调
    remote_filter: (params, url, render_view) ->
      $.ajax url,
        data: params
        success: (data) ->
          render_view(data)

    # 对重构后的数据进行排序
    #
    # @param query [String] 匹配后的关键字
    # @param items [Array] 重构后的数据列表
    # @param search_key [String] 用于搜索的关键字
    #
    # @return [Array] 排序后的数据列表
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


    # 解析并渲染下拉列表中单个项的模板
    #
    # @param tpl [String] 模板字符串
    # @param map [Hash] 数据的键值对.
    tpl_eval: (tpl, map) ->
      try
        el = tpl.replace /\$\{([^\}]*)\}/g, (tag,key,pos) ->
          map[key]
      catch error
        ""

    # 高亮关键字
    #
    # @param li [String] HTML String. 经过渲染后的模板
    # @param query [String] 匹配得到的关键字
    #
    # @return [String] 高亮处理后的 HTML 字符串
    highlighter: (li, query) ->
      return li if not query
      li.replace new RegExp(">\\s*(\\w*)(" + query.replace("+","\\+") + ")(\\w*)\\s*<", 'ig'), (str,$1, $2, $3) ->
          '> '+$1+'<strong>' + $2 + '</strong>'+$3+' <'

    # 选择某列表项的动作
    #
    # @param $li [jQuery Object] 选中的列表项目
    selector: ($li) ->
      this.replace_str($li.data("value") || "") if $li.length > 0


  # At.js 对数据操作(搜索, 匹配, 渲染) 的主控中心
  class Controller

    # @param inputor [HTML DOM Object] 输入框
    constructor: (inputor) ->
      @settings     = {}
      @pos          = 0
      @flags        = null
      @current_flag = null
      @query        = null

      @$inputor = $(inputor)
      @view = new View(this, @$el)
      this.listen()

    # 绑定对输入框的各种监听事件
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

    # At.js 可以对每个输入框绑定不同的监听标记. 比如同时监听 "@", ":" 字符
    # 并且通过不同的 `settings` 给予不同的表现行为, 比如插入不同的内容(即不同的渲染模板)
    #
    # 控制器初始化的时候会将默认配置当作一个所有标记共有的配置. 而每个标记只存放针对自己的特定配置.
    # 搜索配置的时候, 将先寻找标记里的配置. 如果找不到则去公用的配置里找.
    #
    # 当输入框已经注册了某个字符后, 再对该字符进行注册将会更新其配置, 比如改变 `data`, 其它的配置不变.
    #
    # @param flag [String] 要监听的字符
    # @param settings [Hash] 配置哈希值
    reg: (flag, settings) ->
      @current_flag = flag
      current_settings = if @settings[flag]
        @settings[flag] = $.extend {}, @settings[flag], settings
      else
        @settings[flag] = $.extend {}, $.fn.atwho.default, settings

      current_settings["data"] = this.callbacks("data_refactor").call(this, current_settings["data"])

      this


    # 将自定义的 `jQueryEvent` 事件代理到当前输入框( inputor )
    # 这个方法会自动为事件添加名为 `atwho` 的命名域(namespace), 并且将当前上下为作为最后一个参数传入.
    #
    # @example
    #   this.trigger "roll_n_rock", [1,2,3,4]
    #   # 对应的输入框可以如下监听事件.
    #   $inputor.on "rool_n_rock", (e, one, two, three, four) ->
    #     console.log one, two, three, four
    #
    # @param name [String] 事件名称
    # @param data [Array] 传递给回调函数的数据.
    trigger: (name, data) ->
      data ||= []
      data.push this
      @$inputor.trigger "#{name}.atwho", data

    # get or set current data which would be shown on the list view.
    #
    # @param data [Array] set data
    # @return [Array|undefined] 当前数据, 数据元素一般为 Hash 对象.
    data: (data)->
      if data
        @$inputor.data("atwho-data", data)
      else
        @$inputor.data("atwho-data")

    # At.js 允许开发者自定义控制器使用的一些功能函数
    #
    # @param func_name [String] 回调的函数名
    # @return [Function] 该回调函数
    callbacks: (func_name)->
      func = this.get_opt("callbacks")[func_name]
      func = DEFAULT_CALLBACKS[func_name] unless func
      func

    # 由于可以绑定多字符, 但配置却不相同, 而且有公用配置.所以会根据当前标记获得对应的配置
    #
    # @param key [String] 某配置项的键名
    # @param default_value [?] 没有找到任何值后自定义的默认值
    # @return [?] 配置项的值
    get_opt: (key, default_value) ->
      try
        @settings[@current_flag][key]
      catch e
        null

    # 获得标记字符在输入框中的位置
    #
    # @return [Hash] 位置信息. {top: y, left: x, bottom: bottom}
    rect: ->
      c = @$inputor.caret('offset', @pos - 1)
      if document.selection
        scale_bottom = scale = -2
      else
        scale = 0
        scale_bottom = 2
      {left:c.left + scale, top:c.top + scale, bottom: c.top+c.height + scale_bottom}

    # 捕获标记字符后的字符串
    #
    # @return [Hash] 该字符串的信息, 包括在输入框中的位置. {'text': "hello", 'head_pos': 0, 'end_pos': 0}
    catch_query: ->
      content = @$inputor.val()
      ##获得inputor中插入符的position.
      caret_pos = @$inputor.caret('pos')
      ### 向在插入符前的的文本进行正则匹配
       * 考虑会有多个 @ 的存在, 匹配离插入符最近的一个###
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

    # 将选中的项的`data-value` 内容插入到输入框中
    #
    # @param str [String] 要插入的字符串, 一般为 `data-value` 的值.
    replace_str: (str) ->
      $inputor = @$inputor
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
      e.stopPropagation()

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
      e.stopPropagation()

    # 将处理完的数据显示到下拉列表中
    #
    # @param data [Array] 处理过后的数据列表
    render_view: (data) ->
      search_key = this.get_opt("search_key")
      data = this.callbacks("sorter").call(this, @query.text, data, search_key)
      data = data.slice(0, this.get_opt('limit'))

      this.data(data)
      @view.render data

    remote_call: (data, query) ->
      params =
          limit: this.get_opt("limit")
      params[this.get_opt("search_term")] = query.text
      _callback = (data) ->
        this.render_view data
      _callback = $.proxy _callback, this
      this.callbacks('remote_filter').call(this, params, data, _callback)


    # 根据关键字搜索数据
    look_up: ->
      query = this.catch_query()
      return no if not query

      data = this.get_opt("data")
      search_key = this.get_opt("search_key")
      if typeof data is "string"
        this.remote_call(data, query)
      else if (data = this.callbacks('filter').call(this, query.text, data, search_key))
        this.render_view data
      else
          @view.hide()
      $.noop()


  # 操作下拉列表所有表现行为的类
  # 所有的这个类的对象都只操作一个视图.
  class View

    # @param controller [Object] 控制器对象.
    constructor: (@controller) ->
      @id = @controller.get_opt("view_id") || "at-view"
      @timeout_id = null
      @$el = $("##{@id}")
      this.create_view()

    # 如果试图还不存在,则创建一个新的视图
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
        e.stopPropagation()
        e.preventDefault()
        @$el.data("_view").choose()


    # 判断视图是否存在
    #
    # @return [Boolean]
    exist: ->
      $("##{@id}").length > 0

    # 判断视图是否显示中
    #
    # @return [Boolean]
    visible: ->
      @$el.is(":visible")

    # 选择某项的操作
    choose: ->
      $li = @$el.find ".cur"
      @controller.callbacks("selector").call(@controller, $li)
      @controller.trigger "choose", [$li]
      this.hide()

    # 重置视图在页面中的位置.
    reposition: ->
      rect = @controller.rect()
      if rect.bottom + @$el.height() - $(window).scrollTop() > $(window).height()
          rect.bottom = rect.top - @$el.height()
      offset = {left:rect.left, top:rect.bottom}
      @$el.offset offset
      @controller.trigger "reposition", [offset]

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
      tpl = @controller.get_opt('tpl', DEFAULT_TPL)

      $.each list, (i, item) =>
        li = @controller.callbacks("tpl_eval").call(@controller, tpl, item)
        $li = $ @controller.callbacks("highlighter").call(@controller, li, @controller.query.text)
        $li.data("info", item)
        $ul.append $li

      this.show()
      $ul.find("li:eq(0)").addClass "cur"


  DEFAULT_TPL = "<li data-value='${name}'>${name}</li>"

  $.fn.atwho = (flag, options) ->
    @.filter('textarea, input').each () ->
      $this = $(this)
      data = $this.data "atwho"

      $this.data 'atwho', (data = new Controller(this)) if not data
      data.reg flag, options

  $.fn.atwho.Controller = Controller
  $.fn.atwho.View = View
  $.fn.atwho.default =
      data: null
      search_key: "name"
      search_term: "q"
      callbacks: DEFAULT_CALLBACKS
      limit: 5
      display_flag: yes
      display_timeout: 300
      tpl: DEFAULT_TPL
