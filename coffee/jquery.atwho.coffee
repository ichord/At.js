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

    Mirror =
        $mirror: null
        css: ["overflowY", "height", "width", "paddingTop", "paddingLeft", "paddingRight", "paddingBottom", "marginTop", "marginLeft", "marginRight", "marginBottom",'fontFamily', 'borderStyle', 'borderWidth','wordWrap', 'fontSize', 'lineHeight', 'overflowX']
        init: ($origin) ->
            $mirror = $('<div></div>')
            css =
                position: 'absolute'
                left: -9999
                top:0
                zIndex: -20000
                'white-space': 'pre-wrap'
            $.each @.css, (i,p) ->
                css[p] = $origin.css p
            $mirror.css(css)
            @.$mirror = $mirror
            $origin.after($mirror)
            this
        setContent: (html) ->
            @.$mirror.html(html)
            this
        getFlagRect: () ->
            $flag = @.$mirror.find "span#flag"
            pos = $flag.position()
            rect = {left:pos.left, top:pos.top, bottom:$flag.height() + pos.top}
            @.$mirror.remove()
            rect

    At = (inputor) ->
        $inputor = @.$inputor = $(inputor)
        @options = {}
        @query =
            text:""
            start:0
            stop:0
        @_cache = {}
        @pos = 0
        @flags = {}
        @theflag = null
        @search_word = {}

        @view = AtView
        @mirror = Mirror

        $inputor
            .on "keyup.inputor", (e) =>
                stop = e.keyCode is 40 or e.keyCode is 38
                lookup = not (stop and @.view.isShowing())
                @.lookup() if lookup
            .on "mouseup.inputor",(e) =>
                @.lookup()
        @.init()
        log "At.new", $inputor[0]
        return this

    At:: =
        constructor: At

        init: ->
            @.$inputor
                .on 'keydown.inputor', (e) =>
                    @.onkeydown(e)
                .on 'scroll.inputor', (e) =>
                    @.view.hide()
                .on 'blur.inputor', (e) =>
                    @.view.hide(1000)
            log "At.init", @.$inputor[0]

        reg: (flag, options) ->
            opt = {}
            if $.isFunction options
                opt['callback'] = options
            else
                opt = options
            _default = @.options[flag] or= $.fn.atWho.default
            @.options[flag] = $.extend {}, _default, opt
            log "At.reg", @.$inputor[0],flag, options

        dataValue: ->
            search_word = @.search_word[@.theflag]
            return search_word if search_word
            match = /data-value=["']?\$\{(\w+)\}/g.exec(this.getOpt('tpl'))
            return @.search_word[@.theflag] =  if !_isNil(match) then match[1] else null

        getOpt: (key) ->
            try
                return @.options[@.theflag][key]
            catch error
                return null

        rect: ->
            $inputor = @.$inputor
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
            value = if $inputor.text() then $inputor.text() else $inputor.val()
            start_range = value.slice(0,@pos - 1)
            html = "<span>"+format(start_range)+"</span>"
            html += "<span id='flag'>@</span>"

            ###
              将inputor的 offset(相对于document)
              和@在inputor里的position相加
              就得到了@相对于document的offset.
              当然,还要加上行高和滚动条的偏移量.
            ###
            offset = $inputor.offset()
            at_rect = @mirror.init($inputor).setContent(html).getFlagRect()

            x = offset.left + at_rect.left - $inputor.scrollLeft()
            y = offset.top - $inputor.scrollTop()
            bottom = y + at_rect.bottom
            y += at_rect.top

            # bottom + 2: for some font style problem
            return {top:y,left:x,bottom:bottom + 2}

        cache: (value) ->
            key = @.query.text
            return null if not @.getOpt("cache") or not key
            return @._cache[key] or= value

        getKeyname: ->
            $inputor = @.$inputor
            text = if $inputor.text() then $inputor.text() else $inputor.val()

            ##获得inputor中插入符的position.
            caret_pos = $inputor.caretPos()

            ### 向在插入符前的的文本进行正则匹配
             * 考虑会有多个 @ 的存在, 匹配离插入符最近的一个###
            subtext = text.slice(0,caret_pos)

            matched = null
            $.each this.options, (flag) =>
                regexp = new RegExp flag+'([A-Za-z0-9_\+\-]*)$|'+flag+'([^\\x00-\\xff]*)$','gi'
                match = regexp.exec subtext
                if not _isNil(match)
                    matched = if match[2] then match[2] else match[1]
                    @.theflag = flag
                    return no

            if typeof matched is 'string' and matched.length <= 20
                start = caret_pos - matched.length
                end = start + matched.length
                @.pos = start
                key = {'text':matched.toLowerCase(), 'start':start, 'end':end}
            else
                @.view.hide()

            log "At.getKeyname", key
            @.query = key

        replaceStr: (str) ->
            $inputor = @.$inputor
            key = @.query
            source = if $inputor.text() then $inputor.text() else $inputor.val()
            flag_len = if @.getOpt("display_flag") then 0 else @theflag.length
            start_str = source.slice 0, key.start - flag_len
            text = start_str + str + source.slice key.end

            if $inputor.text() then $inputor.text text
            else $inputor.val text
            $inputor.caretPos start_str.length + str.length
            $inputor.change()
            log "At.replaceStr", text

        onkeydown: (e) ->
            view = @.view
            return if not view.isShowing()
            switch e.keyCode
                # UP
                when 38
                    e.preventDefault()
                    view.prev()
                # DOWN
                when 40
                    e.preventDefault()
                    view.next()
                # TAB or ENTER
                when 9, 13
                    return if not view.isShowing()
                    e.preventDefault()
                    view.choose()
                else
                    $.noop()
            e.stopPropagation()

        renderView: (datas) ->
            log "At.renderView", @, datas

            datas = datas.splice(0, @.getOpt('limit'))
            datas = _unique(datas, @.dataValue())
            datas = _objectify(datas)
            datas = _sorter.call(@,datas)

            this.view.render this, datas

        lookup: ->
            key = this.getKeyname()
            return no if not key
            log "At.lookup.key", key

            if not _isNil(datas = @.cache())
                @.renderView datas
            else if not _isNil(datas = @.lookupWithData key)
                @.renderView datas
            else if $.isFunction(callback = @.getOpt 'callback')
                callback key.text, $.proxy(@.renderView,@)
            else
                @.view.hide()
            $.noop()

        lookupWithData: (key) ->
            data = @.getOpt "data"
            if $.isArray(data) and data.length != 0
                items = $.map data, (item,i) =>
                    try
                        name = if $.isPlainObject item then item[@.dataValue()] else item
                        regexp = new RegExp(key.text.replace("+","\\+"),'i')
                        match = name.match(regexp)
                    catch e
                        return null

                    return if match then item else null
            items

    AtView =
        timeout_id: null
        id: '#at-view'
        holder: null
        _jqo: null
        jqo: ->
            jqo = @._jqo
            jqo = if _isNil jqo then (@._jqo = $(@.id)) else jqo

        init: ->
            return if not _isNil @.jqo()
            tpl = "<div id='"+this.id.slice(1)+"' class='at-view'><ul id='"+this.id.slice(1)+"-ul'></ul></div>"
            $("body").append(tpl)

            $menu = @.jqo().find('ul')
            $menu.on 'mouseenter.view','li', (e) ->
                    $menu.find('.cur').removeClass 'cur'
                    $(e.currentTarget).addClass 'cur'
                .on 'click', (e) =>
                    e.stopPropagation()
                    e.preventDefault()
                    @.choose()


        isShowing: () ->
            @.jqo().is(":visible")

        choose: () ->
            $li = @.jqo().find ".cur"
            str = if _isNil($li) then @.holder.query.text+" " else $li.attr(@.holder.getOpt("choose")) + " "
            @.holder.replaceStr(str)
            @.hide()

        rePosition: () ->
            rect = @.holder.rect()
            if rect.bottom + @.jqo().height() - $(window).scrollTop() > $(window).height()
                rect.bottom = rect.top - @.jqo().height()
            log "AtView.rePosition",{left:rect.left, top:rect.bottom}
            @.jqo().offset {left:rect.left, top:rect.bottom}

        next: () ->
            cur = @.jqo().find('.cur').removeClass('cur')
            next = cur.next()
            next = $(@.jqo().find('li')[0]) if not next.length
            next.addClass 'cur'

        prev: () ->
            cur = @.jqo().find('.cur').removeClass('cur')
            prev = cur.prev()
            prev = @.jqo().find('li').last() if not prev.length
            prev.addClass('cur')

        show: () ->
            @.jqo().show() if not @.isShowing()
            @.rePosition()

        hide: (time) ->
            if isNaN time
                @.jqo().hide() if @.isShowing()
            else
                callback = => @.hide()
                clearTimeout @.timeout_id
                @.timeout_id = setTimeout callback, 300

        clear: (clear_all) ->
            @._cache = {} if clear_all is yes
            @.jqo().find('ul').empty()

        render: (holder, list) ->
            return no if not $.isArray(list)
            if list.length <= 0
                @.hide()
                return yes

            @.holder = holder
            holder.cache(list)
            @.clear()

            $ul = @.jqo().find('ul')
            tpl = holder.getOpt('tpl')

            $.each list, (i, item) ->
                tpl or= _DEFAULT_TPL
                li = _evalTpl tpl, item
                log "AtView.render", li
                $ul.append _highlighter li,holder.query.text

            @.show()
            $ul.find("li:eq(0)").addClass "cur"


    _objectify = (list) ->
        $.map list, (item,k) ->
            if not $.isPlainObject item
                item = {id:k, name:item}
            return item

    _evalTpl = (tpl, map) ->
        try
            el = tpl.replace /\$\{([^\}]*)\}/g, (tag,key,pos) ->
                map[key]
        catch error
            ""

    _highlighter = (li,query) ->
        return li if _isNil(query)
        li.replace new RegExp(">\\s*(\\w*)(" + query.replace("+","\\+") + ")(\\w*)\\s*<", 'ig'), (str,$1, $2, $3) ->
            '> '+$1+'<strong>' + $2 + '</strong>'+$3+' <'

    _sorter = (items) ->
        data_value = @.dataValue()
        query = @.query.text
        results = []

        for item in items
            text = item[data_value]
            continue if text.toLowerCase().indexOf(query) is -1
            item.order = text.toLowerCase().indexOf query
            results.push(item)

        results.sort (a,b) ->
            a.order - b.order
        return results


    ###
      maybe we can use $._unique.
      But i don't know it will delete li element frequently or not.
      I think we should not change DOM element frequently.
      more, It seems batter not to call evalTpl function too much times.
    ###
    _unique = (list,query) ->
        record = []
        $.map list, (v, id) ->
            value = if $.isPlainObject(v) then v[query] else v
            if $.inArray(value,record) < 0
                record.push value
                return v

    _isNil = (target) ->
        not target \
        or ($.isPlainObject(target) and $.isEmptyObject(target)) \
        or ($.isArray(target) and target.length is 0) \
        or (target instanceof $ and target.length is 0) \
        or target is undefined

    _DEFAULT_TPL = "<li id='${id}' data-value='${name}'>${name}</li>"

    log = () ->
        #console.log(arguments)

    $.fn.atWho = (flag, options) ->
        AtView.init()
        # OLD: .filter('textarea, input')
        # Have to check each, or else something else?
        @.each () ->
            $this = $(this)
            data = $this.data "AtWho"

            $this.data 'AtWho', (data = new At(this)) if not data
            data.reg flag, options

    $.fn.atWho.default =
        data: []
        # Parameter: choose
        ## specify the attribute on customer tpl,
        ## so that we could append different value to the input other than the value we searched in
        choose: "data-value"
        callback: null
        cache: yes
        limit: 5
        display_flag: yes
        tpl: _DEFAULT_TPL

)(window.jQuery)