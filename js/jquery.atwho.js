/* 
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
*/

(function($) {
    /* 克隆(镜像) inputor. 用于获得@在输入框中的位置
             * 复制它的大小形状相关的样式. */
    Mirror = function($origin) {
        this.init($origin)
    }
    Mirror.prototype = {
        $mirror: null,
        css : ["overflowY", "height", "width", "paddingTop", "paddingLeft", "paddingRight", "paddingBottom", "marginTop", "marginLeft", "marginRight", "marginBottom",'fontFamily', 'borderStyle', 'borderWidth','wordWrap', 'fontSize', 'lineHeight', 'overflowX'],
        init: function($origin) {
            $mirror =  $('<div></div>')
            var css = {
                opacity: 0, 
                position: 'absolute', 
                left: 0,
                top:0, 
                zIndex: -20000,
                'white-space':'pre-wrap'
            }
            $.each(this.css,function(i,p){
                css[p] = $origin.css(p)
            })
            $mirror.css(css)
            $('body').append($mirror)
            this.$mirror = $mirror
        },
        setContent: function(html) {
            this.$mirror.html(html)
        },
        getFlagPos:function() {
            return this.$mirror.find("span#flag").position()
        },
        height: function() {
          return this.$mirror.height()
        }
    }
    
    At = function(inputor) {
        // textarea, input.
        $inputor = this.$inputor = $(inputor)
        this.options = {}
        this.keyword = {'text':"",'start':0,'stop':0}
        this._cache = {}
        /* @ position in inputor */
        this.pos = 0
        this.flags = {}
        this.theflag = null
        this.search_word = {}

        this.view = AtView
        this.mirror = new Mirror($inputor)

        this.$inputor.on("keyup.inputor", $.proxy(function(e) {
            /* 当用户列表框显示时, 上下键不触发查询 */
            var stop_key = e.keyCode == 40 || e.keyCode == 38
            lookup = !(this.view.isShowing() && stop_key)
            if (lookup) this.lookup()
        },this))
        .on('mouseup.inputor', $.proxy(function(e) {
            this.lookup()
        },this))

        this.init()
    }

    At.prototype = {
        constructor: At
        ,reg: function(flag,options) {
            opt = {}
            if ($.isFunction(options))
                opt['callback'] = options
            else
                opt = options

            this.options[flag] = $.extend({},$.fn.atWho.default,opt)
        }
        ,searchWord:function() {
            // just used in this.holder.lookupWithData
            search_word = this.search_word[this.theflag]
            if (search_word)
                return search_word
            var match = /data-value=['?]\$\{(\w+)\}/g.exec(this.getOpt('tpl'))
            return this.search_word[this.theflag] = !_isNil(match) ? match[1] : null
        },
        getOpt: function(key) {
            try {
                return this.options[this.theflag][key]
            } catch (e) {
                return null
            }
        },
        /* @ offset*/
        offset: function() {
            $inputor = this.$inputor

            if (document.selection) {// IE!!! 
                var Sel = document.selection.createRange()
                x = Sel.boundingLeft + $inputor.scrollLeft()
                y = Sel.boundingTop + Sel.boundingHeight 
                    + $(window).scrollTop() + $inputor.scrollTop()
                return {'top':y,'left':x}
            }

            mirror = this.mirror
            
            /* 为了将textarea中文字的排版模拟到镜像div中
             * 我们需要做一些字符处理.由于div元素中不认多余的空格.
             * 我们需要将多余的空格用元素块包裹.
             × 换行符直接替换成<br/>就可以了.
             * NOTE: “\r\n” 用于ie的textarea.
             */
            function format(value) {
                value = value.replace(/</g, '&lt')
                    .replace(/>/g, '&gt')
                    .replace(/`/g,'&#96')
                    .replace(/"/g,'&quot')
                return value.replace(/\r\n|\r|\n/g,"<br />")
            } 
            /* 克隆完inputor后将原来的文本内容根据
             * @的位置进行分块,以获取@块在inputor(输入框)里的position
             * */
            text = $inputor.val()
            start_range = text.slice(0,this.pos - 1)
            end_range = text.slice(this.pos + 1)
            html = "<span>"+format(start_range)+"</span>"
            html += "<span id='flag'>@</span>"
            html += "<span>"+format(end_range)+"</span>"
            mirror.setContent(html)

            /* 将inputor的 offset(相对于document)
             * 和@在inputor里的position相加
             * 就得到了@相对于document的offset.
             * 当然,还要加上行高和滚动条的偏移量.
             * */
            offset = $inputor.offset()
            at_pos = mirror.getFlagPos()
            line_height = $inputor.css("line-height")
            line_height = isNaN(line_height) ? 20 : line_height
            //FIXME: -$(window).scrollTop() get "wrong" offset.
            // but is good for $inputor.scrollTop()
            // jquey 1. + 07.1 fixed the scrollTop problem!?
            y = offset.top + at_pos.top + line_height - $inputor.scrollTop()
            x = offset.left + at_pos.left - $inputor.scrollLeft()
            
            return {'top':y,'left':x}
        },
        cache: function(value) {
            var key = this.keyword.text
            if (!this.getOpt('cache') || !key) return null
            if (value)
                this._cache[key] = value
            return this._cache[key]
        },
        getKeyname: function() {
            $inputor = this.$inputor
            text = $inputor.val()
            //获得inputor中插入符的position.
            caret_pos = $inputor.caretPos()
            /* 向在插入符前的的文本进行正则匹配
             * 考虑会有多个 @ 的存在, 匹配离插入符最近的一个*/
            subtext = text.slice(0,caret_pos)
            // word = subtext.exec(/@(\w+)$|@[^\x00-\xff]+$/g)
            var self = this
            var matched = null
            $.each(this.options,function(flag) {
                regexp = new RegExp(flag+'([A-Za-z0-9_\+\-]*)$|'+flag+'([^\\x00-\\xff]*)$','gi')
                match = regexp.exec(subtext)
                if (!_isNil(match)) {
                    matched = match[1] == undefined ? match[2] : match[1]
                    self.theflag = flag
                    return false
                }
            })
            var key = null
            if (typeof matched == "string" && matched.length <= 20) {
                start = caret_pos - matched.length
                end = start + matched.length
                this.pos = start
                key = {'text':matched, 'start':start, 'end':end}
            } else
                this.view.hide()

            this.keyword = key
            return key
        },
        replaceStr: function(str) {
            /* $inputor.replaceStr(str,start,end)*/
            $inputor = this.$inputor
            key = this.keyword
            source = $inputor.val()
            start_str = source.slice(0, key.start)
            text = start_str + str + source.slice(key.end)

            $inputor.val(text)
            $inputor.caretPos(start_str.length + str.length)
            $inputor.change()
        }
        /* 捕捉inputor的上下回车键.
         * 在列表框做相应的操作,上下滚动,回车选择
         * 返回 false 阻止冒泡事件以捕捉inputor对应的事件
         * */
        ,onkeydown: function(e) {
            view = this.view
            if (!view.isShowing()) return
            switch (e.keyCode) {
                // UP
                case 38:
                    e.preventDefault()
                    view.prev()
                    break
                // DOWN
                case 40:
                    e.preventDefault()
                    view.next()
                    break
                //TAB or ENTER
                case 9:
                case 13:
                    if (!view.isShowing()) return
                    e.preventDefault()
                    view.choose()
                    break
                default:
                    $.noop()
            }
            e.stopPropagation()
        }       
        ,init: function() {
            // 捕捉inputor事件
            var self = this
            $inputor.on('keydown.inputor',function(e) {
                return self.onkeydown(e)
            })
            .on('scroll.inputor',function(e){
                self.view.hide()
            })
            .on('blur.inputor',function(e){
                self.view.timeout_id = setTimeout("self.view.hide()",150)
            })
        }
        ,loadView: function(datas) {
            return this.view.load(this, datas)
        }
        ,lookup: function() {
            var key = this.getKeyname()
            if (!key) return false
            /*
             * 支持多渠道获得用户数据.
             * 可以设置静态数据的同时从服务器动态获取.
             * 获取级别从先到后: cache -> statis data -> ajax.
             */
            var datas = null
            if (!_isNil(datas = this.cache())) {
                this.loadView(datas)
            } else if (!_isNil(datas = this.lookupWithData(key))) {
                this.loadView(datas)
            } else if ($.isFunction(callback = this.getOpt('callback'))){
                callback(key.text,this.loadView)
            } else
                this.view.hide()
        },
        lookupWithData:function(key) {
            data = this.getOpt("data")
            var items = null
            var self = this
            if($.isArray(data) && data.length != 0) {
                items = $.map(data,function(item,i) {
                    //support plain object also
                    try {
                        var name = $.isPlainObject(item) ? item[self.searchWord()] : item
                        var match = name.match((new RegExp(key.text.replace("+","\\+"),"i")))    
                    } catch(e) {
                        return null
                    }
                    return match ? item : null
                })
            }
            return items
        }
    }

    /* private class
     * 弹出的用户列表框相关的操作 */
    AtView = {
        timeout_id : null
        ,id : '#at-view'
        ,holder : null
        ,_jqo: null
        ,jqo: function() {
            var jqo = this._jqo
            return _isNil(jqo) ? (this._jqo = $(this.id)) : jqo 
        }
        ,init: function() {
            // 是否已经加载了列表视图
            if (!_isNil(this.jqo())) return
            tpl = "<div id='"+this.id.slice(1)+"' class='at-view'><ul id='"+this.id.slice(1)+"-ul'></ul></div>"
            $('body').append(tpl)

            $menu = this.jqo().find('ul')
            $menu.on('mouseenter.view','li',function(e) {
                $menu.find('.cur').removeClass('cur')
                $(e.currentTarget).addClass('cur')
            }).on('click', $.proxy(function(e){
                e.stopPropagation()
                e.preventDefault()
                this.choose()
            },this))
            
        }
        // 列表框是否显示中.
        ,isShowing :function() {
            return this.jqo().is(":visible")
        },
        choose: function() {
            $li = this.jqo().find(".cur")
            str = _isNil($li) ? this.holder.keyword.text+" " : $li.attr("data-value")+" " 
            this.holder.replaceStr(str)
            this.hide()
        },
        rePosition:function() {
            this.jqo().offset(this.holder.offset())
        }
        ,next: function(event) {
            var cur = this.jqo().find('.cur').removeClass('cur')
                , next = cur.next()
            if (!next.length) {
                next = $(this.jqo().find('li')[0])
            }
            next.addClass('cur')
        }
        ,prev: function() {
            var cur = this.jqo().find('.cur').removeClass('cur')
                , prev = cur.prev()
            if (!prev.length) {
                prev = this.jqo().find('li').last()
            }
            prev.addClass('cur')
        }
        ,show: function(){
            if (!this.isShowing())
                this.jqo().show()
            this.rePosition()
        },
        hide: function() {
            if (!this.isShowing()) return
            this.jqo().hide()
        }
        ,clear: function(clear_all) {
            if (clear_all == true)
                this._cache = {}
            this.jqo().find('ul').empty()
        }
        ,load: function(holder,list) {
            if (!$.isArray(list)) return false

            this.holder = holder
            this.holder.cache(list)

            this.clear()
            var tpl = this.holder.getOpt('tpl')
            var list = _unique(list,this.holder.searchWord())

            var self = this
            $ul = this.jqo().find('ul')
            $.each(list.splice(0, this.holder.getOpt('limit')), function(i,item) {
                if (!$.isPlainObject(item)) {
                    item = {'id':i,'name':item}
                    tpl = _DEFAULT_TPL
                }
                $ul.append(_evalTpl(tpl,item))
            })
            this.show()
            $ul.find("li:eq(0)").addClass("cur")
        }
    }

    function _evalTpl(tpl,map) {
        if(_isNil(tpl)) return
        el = tpl.replace(/\$\{([^\}]*)\}/g,function(tag,key,pos){
            return map[key]
        })
        return el
    }
    /* maybe we can use $._unique. 
     * But i don't know it will delete li element frequently or not.
     * I think we should not change DOM element frequently.
     * more, It seems batter not to call evalTpl function too much times.
     * */
    function _unique(list,keyword) {
        var record = []
        return $.map(list,function(v,idx){
            var value = $.isPlainObject(v) ? v[keyword] : v
            if ($.inArray(value,record) < 0) {
                record.push(value)
                return v
            }
        })
    }

    function _isNil(target) {
        return !target
        //empty_object =  
        || ($.isPlainObject(target) && $.isEmptyObject(target))
        //empty_array = 
        || ($.isArray(target) && target.length == 0)
        // nil_jquery = 
        || (target instanceof $ && target.length == 0)
        || target === undefined
    }

    _DEFAULT_TPL = "<li id='${id}' data-value='${name}'>${name}</li>"
    
    $.fn.atWho = function (flag,options) {
        AtView.init()
        return this.filter('textarea, input').each(function() {
            var $this = $(this)
            , data = $this.data('AtWho')

            if (!data)
                $this.data('AtWho', (data = new At(this)))
            data.reg(flag,options)
        })
    }

    $.fn.atWho.default = {
        'data' : [],
        'callback' : null,
        'cache' : true,
        'limit' : 5,
        'tpl' : _DEFAULT_TPL
    }
})(window.jQuery);
