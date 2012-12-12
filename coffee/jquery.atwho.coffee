###
   Implement Twitter/Weibo @ mentions

   Copyright (c) 2012 chord.luo@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   "Software"), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
   OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
   WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

(($) ->

    class Mirror
      css_attr: [
        "overflowY", "height", "width", "paddingTop", "paddingLeft",
        "paddingRight", "paddingBottom", "marginTop", "marginLeft",
        "marginRight", "marginBottom",'fontFamily', 'borderStyle',
        'borderWidth','wordWrap', 'fontSize', 'lineHeight', 'overflowX'
      ]

      constructor: (@$inputor) ->

      copy_inputor_css: ->
        css =
          position: 'absolute'
          left: -9999
          top:0
          zIndex: -20000
          'white-space': 'pre-wrap'
        $.each @css_attr, (i,p) =>
          css[p] = @$inputor.css p
        css

      create: (html) ->
        @$mirror = $('<div></div>')
        @$mirror.css this.copy_inputor_css()
        @$mirror.html(html)
        @$inputor.after(@$mirror)
        this

      get_flag_rect: ->
        $flag = @$mirror.find "span#flag"
        pos = $flag.position()
        rect = {left: pos.left, top: pos.top, bottom: $flag.height() + pos.top}
        @$mirror.remove()
        rect

    KEY_CODE =
      DOWN: 40
      UP: 38
      ESC: 27
      TAB: 9
      ENTER: 13

    GLOBAL_CALLBACKS =
      matcher: (flag, subtext) ->
        regexp = new RegExp flag+'([A-Za-z0-9_\+\-]*)$|'+flag+'([^\\x00-\\xff]*)$','gi'
        match = regexp.exec subtext
        matched = null
        if match
          matched = if match[2] then match[2] else match[1]
        matched

    DEFAULT_CALLBACKS =
      filter: (query, data, search_key) ->
        if $.isArray(data) and data.length != 0
          items = $.map data, (item,i) =>
            try
              name = if $.isPlainObject item then item[search_key] else item
              regexp = new RegExp(query.replace("+","\\+"),'i')
              match = name.match(regexp)
            catch e
              return null
            return if match then item else null
        items

      remote_filter: (params, url, render_view) ->
        $.ajax url, params, (data) ->
          names = $.parseJSON(data)
          render_view(names)

      tpl_eval: (tpl, map) ->
        try
          el = tpl.replace /\$\{([^\}]*)\}/g, (tag,key,pos) ->
            map[key]
        catch error
          ""

      highlighter: (li, query) ->
        return li if not query
        li.replace new RegExp(">\\s*(\\w*)(" + query.replace("+","\\+") + ")(\\w*)\\s*<", 'ig'), (str,$1, $2, $3) ->
            '> '+$1+'<strong>' + $2 + '</strong>'+$3+' <'

      sorter: (query, items, search_key) ->
        results = []

        for item in items
          text = item[search_key]
          continue if text.toLowerCase().indexOf(query) is -1
          item.order = text.toLowerCase().indexOf query
          results.push(item)

        results.sort (a,b) ->
          a.order - b.order
        return results

      data_refactor: (data) ->
        $.map data, (item, k) ->
          if not $.isPlainObject item
            item = {name:item}
          return item


    class At
      settings: {}
      pos: 0
      flags: null
      current_flag: null
      query: null
      _callbacks: {}

      constructor: (inputor) ->
        @$inputor = $(inputor)
        @mirror = new Mirror(@$inputor)
        @view = new View(this, @$el)
        this.listen()

      listen: ->
        @$inputor
          .on "keyup.atWho", (e) =>
            stop = e.keyCode is KEY_CODE.DOWN or e.keyCode is KEY_CODE.UP
            can_lookup = not (stop and @view.visible())
            this.look_up() if can_lookup
          .on "mouseup.atWho", (e) =>
            this.look_up()
          .on 'keyup.atWho', (e) =>
            this.on_keyup(e)
          .on 'keydown.atWho', (e) =>
            this.on_keydown(e)
          .on 'scroll.atWho', (e) =>
            @view.hide()
          .on 'blur.atWho', (e) =>
            @view.hide(1000)

      reg: (flag, settings) ->
        if not @settings[flag]
          @settings[flag] = $.extend {}, $.fn.atWho.default, settings
        else
          @settings[flag] = $.extend {}, @settings[flag], settings
        this.setup_callback_methods_for(flag)
        this

      setup_callback_methods_for: (flag) ->
        @_callbacks[flag] = $.extend {}, DEFAULT_CALLBACKS, this.get_opt("callbacks", {})

      callbacks: (func_name)->
        GLOBAL_CALLBACKS[func_name] || @_callbacks[@current_flag][func_name]

      get_opt: (key, default_value) ->
        try
          @settings[@current_flag][key] || default_value
        catch e
          default_value || null

      rect: ->
        $inputor = @$inputor
        if document.selection # for IE full
          Sel = document.selection.createRange()
          x = Sel.boundingLeft + $inputor.scrollLeft()
          y = Sel.boundingTop + $(window).scrollTop() + $inputor.scrollTop()
          bottom = y + Sel.boundingHeight
            # -2 : for some font style problem.
          return {top:y-2, left:x-2, bottom:bottom-2}

        format = (value) ->
          value.replace(/</g, '&lt')
          .replace(/>/g, '&gt')
          .replace(/`/g,'&#96')
          .replace(/"/g,'&quot')
          .replace(/\r\n|\r|\n/g,"<br />")

        ### 克隆完inputor后将原来的文本内容根据
          @的位置进行分块,以获取@块在inputor(输入框)里的position
        ###
        start_range = $inputor.val().slice(0,@pos - 1)
        html = "<span>"+format(start_range)+"</span>"
        html += "<span id='flag'>?</span>"

        ###
          将inputor的 offset(相对于document)
          和@在inputor里的position相加
          就得到了@相对于document的offset.
          当然,还要加上行高和滚动条的偏移量.
        ###
        offset = $inputor.offset()
        at_rect = @mirror.create(html).get_flag_rect()

        x = offset.left + at_rect.left - $inputor.scrollLeft()
        y = offset.top - $inputor.scrollTop()
        bottom = y + at_rect.bottom
        y += at_rect.top

        # bottom + 2: for some font style problem
        return {top:y,left:x,bottom:bottom + 2}

      catch_query: ->
        content = @$inputor.val()
        ##获得inputor中插入符的position.
        caret_pos = @$inputor.caretPos()
        ### 向在插入符前的的文本进行正则匹配
         * 考虑会有多个 @ 的存在, 匹配离插入符最近的一个###
        subtext = content.slice(0,caret_pos)

        query = @query = null
        $.each @settings, (flag, settings) =>
          query = this.callbacks("matcher").call(this, flag, subtext)
          @current_flag = flag
          return false

        if typeof query is "string" and query.length <= 20
          start = caret_pos - query.length
          end = start + query.length
          @pos = start
          @query = {'text': query.toLowerCase(), 'head_pos': start, 'end_pos': end}
        else
          @view.hide()
        @query

      replace_str: (str) ->
        $inputor = @$inputor
        source = $inputor.val()
        flag_len = if this.get_opt("display_flag") then 0 else @current_flag.length
        start_str = source.slice 0, (@query['head_pos'] || 0) - flag_len
        text = "#{start_str}#{str} #{source.slice @query['end_pos'] || 0}"

        $inputor.val text
        $inputor.caretPos start_str.length + str.length + 1
        $inputor.change()
        log "At.replace_str", text

      on_keyup: (e) ->
        return unless @view.visible()
        switch e.keyCode
          when KEY_CODE.ESC
            e.preventDefault()
            @view.hide()
          else
            $.noop()
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

      render_view: (data) ->
        data = data.splice(0, this.get_opt('limit'))
        data = this.callbacks("data_refactor").call(this, data)
        search_key = this.get_opt("search_key")
        data = this.callbacks("sorter").call(this, @query.text, data, search_key)

        @view.render data

      look_up: ->
        query = this.catch_query()
        return no if not query

        origin_data = this.get_opt("data")
        search_key = this.get_opt("search_key")
        if typeof data is "string"
          params =
            q: query.text
            limit: this.get_opt("limit")
          callback = $.proxy(this.render_view, this.callbacks('remote_filter').call(this, params, callback))
        else if (data = this.callbacks('filter').call(this, query.text, origin_data, search_key))
            this.render_view data
        else
            @view.hide()
        $.noop()


    class View
      constructor: (@at) ->
        @id = @at.get_opt("view_id", "at-view")
        @timeout_id = null
        @$el = $("##{@id}")
        this.create_view()

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
          this.choose()

      exist: ->
        $("##{@id}").length > 0

      visible: ->
        @$el.is(":visible")

      choose: ->
        $li = @$el.find ".cur"
        @at.replace_str($li.data("value") || "") if $li.length > 0
        this.hide()

      reposition: ->
        rect = @at.rect()
        if rect.bottom + @$el.height() - $(window).scrollTop() > $(window).height()
            rect.bottom = rect.top - @$el.height()
        log "AtView.reposition",{left:rect.left, top:rect.bottom}
        @$el.offset {left:rect.left, top:rect.bottom}

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
          callback = => this.hide()
          clearTimeout @timeout_id
          @timeout_id = setTimeout callback, @at.get_opt("display_timeout", 300)

      clear: ->
        @$el.find('ul').empty()

      render: (list) ->
        return no if not $.isArray(list)
        if list.length <= 0
          this.hide()
          return yes

        # holder.cache(list)
        this.clear()

        $ul = @$el.find('ul')
        tpl = @at.get_opt('tpl', _DEFAULT_TPL)

        $.each list, (i, item) =>
          li = @at.callbacks("tpl_eval").call(this, tpl, item)
          log "AtView.render", li
          $ul.append @at.callbacks("highlighter").call(this, li, @at.query.text)

        this.show()
        $ul.find("li:eq(0)").addClass "cur"


    _DEFAULT_TPL = "<li data-value='${name}'>${name}</li>"

    log = () ->
        #console.log(arguments)

    $.fn.atWho = (flag, options) ->
      @.filter('textarea, input').each () ->
        $this = $(this)
        data = $this.data "AtWho"

        $this.data 'AtWho', (data = new At(this)) if not data
        data.reg flag, options

    $.fn.atWho.At = At
    $.fn.atWho.View = View
    $.fn.atWho.Mirror = Mirror
    $.fn.atWho.default =
        # Parameter: choose
        ## specify the attribute on customer tpl,
        ## so that we could append different value to the input other than the value we searched in
        data: null
        search_key: "name"
        callbacks: {}
        cache: yes
        limit: 5
        display_flag: yes
        tpl: _DEFAULT_TPL

)(window.jQuery)
