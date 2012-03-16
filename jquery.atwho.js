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
        this.init($origin);
    }
    Mirror.prototype = {
        $mirror: null,
        css : ["overflowY", "height", "width", "paddingTop", "paddingLeft", "paddingRight", "paddingBottom", "marginTop", "marginLeft", "marginRight", "marginBottom",'fontFamily', 'borderStyle', 'borderWidth','wordWrap', 'fontSize', 'lineHeight', 'overflowX'],
        init: function($origin) {
            $mirror =  $('<div></div>');
            var css = {
                opacity: 0, 
                position: 'absolute', 
                left: 0,
                top:0, 
                zIndex: -20000,
                'word-wrap':'break-word',
                /* wrap long line as textarea do. not work in ie < 8 */
                'white-space':'pre-wrap'
            }
            $.each(this.css,function(i,p){
                css[p] = $origin.css(p);
            });
            $mirror.css(css);
            $('body').append($mirror);
            this.$mirror = $mirror;
        },
        setContent: function(html) {
            this.$mirror.html(html);
        },
        getFlagPos:function() {
            return this.$mirror.find("span#flag").position();
        },
        height: function() {
          return this.$mirror.height();
        }
    };
    At = {
        keyword : {'text':"",'start':0,'stop':0},
        _cache : {},
        // textarea, input.
        $inputor : null,
        // prevent from duplicate binding.
        inputor_keys: [],
        lenght : 0,
        /* @ position in inputor */
        pos: 0,
        flags:{},
        theflag:null,
        options:{},
        searchWord:function() {
            // just used in At.watchWithData 
            var match = /data-keyname=['?]\$\{(\w+)\}/g.exec(this.getOpt('tpl'));
            return !_isNil(match) ? match[1] : null;
        },
        getOpt: function(key) {
            var flag = this.theflag;
            try {
                return this.options[flag][key];
            } catch (e) {
                return null
            }
        },
        /* @ offset*/
        offset: function() {
            $inputor = this.$inputor;
            mirror = $inputor.data("mirror");
            if (_isNil(mirror)) {
                mirror = new Mirror($inputor);
                $inputor.data("mirror",mirror);
            }
            
            /* 为了将textarea中文字的排版模拟到镜像div中
             * 我们需要做一些字符处理.由于div元素中不认多余的空格.
             * 我们需要将多余的空格用元素块包裹.
             × 换行符直接替换成<br/>就可以了.
             * NOTE: “\r\n” 用于ie的textarea.
             */
            function format(value) {
                value = value.replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;')
                    .replace(/`/g,'&#96;')
                    .replace(/"/g,'&quot;');
                if ($.browser.msie) {
                    rep_str = parseInt($.browser.version) < 8 ? "&nbsp;" : "<span> </span>"
                    value = value.replace(/ /g,rep_str);
                }
                return value.replace(/\r\n|\r|\n/g,"<br />");
            } 
            /* 克隆完inputor后将原来的文本内容根据
             * @的位置进行分块,以获取@块在inputor(输入框)里的position
             * */
            text = $inputor.val();
            start_range = text.slice(0,this.pos - 1);
            end_range = text.slice(this.pos + 1);
            html = "<span>"+format(start_range)+"</span>";
            html += "<span id='flag'>@</span>";
            html += "<span>"+format(end_range)+"</span>";
            mirror.setContent(html);

            /* 将inputor的 offset(相对于document)
             * 和@在inputor里的position相加
             * 就得到了@相对于document的offset.
             * 当然,还要加上行高和滚动条的偏移量.
             * */
            offset = $inputor.offset();
            at_pos = mirror.getFlagPos();
            line_height = $inputor.css("line-height");
            line_height = isNaN(line_height) ? 20 : line_height;
            //FIXME: -$(window).scrollTop() get "wrong" offset.
            // but is good for $inputor.scrollTop();
            // jquey 1. + 07.1 fixed the scrollTop problem!?
            y = offset.top + at_pos.top + line_height
                - $inputor.scrollTop();
            x = offset.left + at_pos.left - $inputor.scrollLeft();

            return {'top':y,'left':x};
        },
        cache: function(key,value) {
            if (!this.getOpt('cache')) return null;
            _log("cacheing",key,value);
            if (value)
                this._cache[key] = value;
            return this._cache[key];
        },
        getKeyname: function() {
            $inputor = this.$inputor;
            text = $inputor.val();
            //获得inputor中插入符的position.
            caret_pos = $inputor.caretPos();
            /* 向在插入符前的的文本进行正则匹配
             * 考虑会有多个 @ 的存在, 匹配离插入符最近的一个*/
            subtext = text.slice(0,caret_pos);
            // word = subtext.exec(/@(\w+)$|@[^\x00-\xff]+$/g);
            self = this;
            matched = null;
            $.each(this.options,function(flag) {
                regexp = new RegExp(flag+'(\\w+)$|'+flag+'([^\\x00-\\xff]+)$','gi');
                matched = regexp.exec(subtext);
                if (!_isNil(matched)) {
                    self.theflag = flag;
                    return false;
                }
            });
            key = null;
            _log("matched",matched)
            if (matched && (word = matched[1]).length < 20) {
                start = caret_pos - word.length;
                end = start + word.length;
                this.pos = start;
                key = {'text':word, 'start':start, 'end':end};
            } else
                this.view.hide();

            this.keyword = key;
            _log("getKeyname",key);
            return key;
        },
        /* 捕捉inputor的上下回车键.
         * 在列表框做相应的操作,上下滚动,回车选择
         * 返回 false 阻止冒泡事件以捕捉inputor对应的事件
         * */
        onkeydown:function(e) {
            view = this.view;
            // 当列表没显示时不捕捉inputor相关事件.
            if (!view.watching()) return true;
            last_idx = view.items.length - 1;
            var return_val = false;
            switch (e.keyCode) {
                case 27:
                    this.choose();
                    break;
                // UP
                case 38:
                    // if put this line outside the switch
                    // the view will flash when key down.
                    $(view.id + " ul li.cur").removeClass("cur");
                    view.cur_li_idx--;
                    // 到达顶端时高亮效果跳到最后
                    if (view.cur_li_idx < 0)
                        view.cur_li_idx = last_idx;
                    $(view.id + " li:eq(" + view.cur_li_idx + ")")
                        .addClass('cur');
                    break;
                // DOWN
                case 40:
                    $(view.id + " ul li.cur").removeClass("cur");
                    view.cur_li_idx++;
                    if (view.cur_li_idx > last_idx)
                        view.cur_li_idx = 0;
                    $(view.id + " li:eq(" + view.cur_li_idx + ")")
                        .addClass('cur');
                    break;
                //TAB or ENTER
                case 9:
                case 13:
                    $(view.id + " ul li.cur").removeClass("cur");
                    // 如果列表为空，则不捕捉回车事件
                    $cur_li = $(view.id + " li:eq("+view.cur_li_idx+")");
                    this.choose($cur_li);
                    break;
                default:
                    return_val = true;
            }
            return return_val;
        },
        replaceStr: function(str) {
            /* $inputor.replaceStr(str,start,end)*/
            key = this.keyword;
            source = this.$inputor.val();
            start_str = source.slice(0, key.start);
            text = start_str + str + source.slice(key.end);
            this.$inputor.val(text);
            this.$inputor.caretPos(start_str.length + str.length);
        },
        choose: function($li) {
            str = _isNil($li) ? this.keyword.text+" " : $li.attr("data-keyname")+" "; 
            this.replaceStr(str);
            this.view.hide();
        },
        reg: function(inputor) {
            $inputor = $(inputor);

            /* 防止对同一个inputor进行多次绑定
             * 在每个已经绑定过的inputor设置一个key.
             * 注册过的key将不再进行绑定
             * */
            key = $inputor.data("@reg-key");
            if ($.inArray(key,this.inputor_keys) >= 0)
                return null;
            _log("reg",inputor,key);

            key = "@-"+$.now();
            $inputor.data("@reg-key",key);
            this.inputor_keys.push(key);
            // 捕捉inputor事件
            var self = this;
            $inputor.bind("keydown",function(e) {
                return self.onkeydown(e);
            })
            .scroll(function(e){
                self.view.hide();
            })
            .blur(function(e){
                self.view.timeout_id = setTimeout("At.view.hide()",100);
            });   
            return key;
        },
        watch: function(inputor) {
            this.$inputor = $(inputor);
            key = this.getKeyname();
            if (!key) return false;
            /*
             * 支持多渠道获得用户数据.
             * 可以设置静态数据的同时从服务器动态获取.
             * 获取级别从先到后: cache -> statis data -> ajax.
             */
            if (!_isNil(names = this.cache(this.keyword.text))) {
                _log("cache data",names);
                this.view.load(names,false);
            } else if (!_isNil(names = this.watchWithData(key))) {
                _log("statis data",names);
                this.view.load(names,false);
            } else if ($.isFunction(callback = this.getOpt('callback'))){
                _log("callbacking",callback);
                callback(At);
            } else
                this.view.hide();
        },
        watchWithData:function(key) {
            data = this.getOpt("data");
            _log("watchWithData",data);
            var items = null;
            var self = this;
            if($.isArray(data) && data.length != 0) {
                items = $.map(data,function(item,i) {
                    //support plain object also
                    var name = $.isPlainObject(item) ? item[self.searchWord()] : item;
                    match = name.match((new RegExp(key.text,"i")));
                    return match ? item : null;
                });
            }
            _log("watch with data.item",items)
            return items;
        }
    };

    /* 弹出的用户列表框相关的操作 */
    At.view = {
        //当前高亮的条目
        cur_li_idx : 0,
        timeout_id : null,
        id : '#at-view',
        items : [],
        // 列表框是否显示中.
        watching :function() {
            return $(this.id).is(":visible");
        },
        evalTpl: function(tpl,map) {
            if(_isNil(tpl)) return;
            el = tpl.replace(/\$\{([^\}]*)\}/g,function(tag,key,pos){
                return map[key];
            });
            _log("evalTpl",el);
            return el;
        },
        onLoaded: function($view) {
            $view.find('li').live('click',function(e) {
                At.choose($(this));
            });
            $view.mousemove(function(e) {
                if (e.target.tagName == "LI") {
                    $(this).find("li.cur").removeClass("cur");
                    $(e.target).addClass("cur");
                    At.cur_li_idx = $(this).find("li").index(e.target)
                }
            });
        },
        rePosition:function($view) {
            $view.offset(At.offset());
        },
        show: function(){
            if (!this.watching())
                $view = $(this.id).show();
            this.rePosition($view);
        },
        hide: function() {
            if (!this.watching()) return;
            this.cur_li_idx = 0;
            $(this.id).hide();
        },
        load: function(list,cacheable) {
            // 是否已经加载了列表视图
            if (_isNil($(this.id))) {
                tpl = "<div id='"+this.id.slice(1)+"' class='at-view'><span id='title'>@who?</span><ul id='"+this.id.slice(1)+"-ul'></ul></div>";
                $('body').append(tpl);
                this.onLoaded($(this.id));
            }
            return this.update(list,cacheable);
        },
        clear: function(clear_all) {
            if (clear_all == true)
                this._cache = {};
            this.items = [];
            $(this.id).find('ul').empty();
        },
        update: function(list,cacheable) {
            if (!$.isArray(list)) return false;
            if (cacheable != false) At.cache(At.keyword.text,list);

            $ul = $(this.id).find('ul');
            this.clear();
            $.merge(this.items,list);
            var tpl = At.getOpt('tpl');
            var self = this;
            var list = _unique(list,At.searchWord());
            $.each(list.splice(0, At.getOpt('limit')), function(i,item) {
                if (!$.isPlainObject(item)) {
                    item = {'id':i,'name':item};
                    tpl = DEFAULT_TPL;
                }
                $ul.append(self.evalTpl(tpl,item));
            });
            this.show();
            $ul.find("li:eq(0)").addClass("cur");
        }
    };

    /* maybe we can use $._unique. 
     * But i don't know it will delete li element frequently or not.
     * I think we should not change DOM element frequently.
     * more, It seems batter not to call evalTpl function too much times.
     * */
    function _unique(list,keyword) {
        var record = [];
        _log(list,keyword);
        return $.map(list,function(v,idx){
            var value = $.isPlainObject(v) ? v[keyword] : v;
            if ($.inArray(value,record) < 0) {
                record.push(value);
                return v;
            }
        });
    }

    function _isNil(target) {
        return !target
        //empty_object =  
        || ($.isPlainObject(target) && $.isEmptyObject(target))
        //empty_array = 
        || ($.isArray(target) && target.length == 0)
        // nil_jquery = 
        || (target instanceof $ && target.length == 0)
        || target === undefined;
    }

    function _log() {
        if (!At.getOpt('debug') || $.browser.msie)
            return;
        console.log(arguments);
    }

    function _setSettings(options) {
        opt = {};
        if ($.isFunction(options))
            opt['callback'] = options;
        else
            opt = options;
        return $.extend({
            'cache' : true,
           'debug' : false,
           'limit' : 5,
           'tpl' : DEFAULT_TPL,
        },opt);
    }

    DEFAULT_TPL = "<li id='${id}' data-keyname='${name}'>${name}</li>";

    $.fn.atWho = function (flag,options) {
        At.options[flag] = _setSettings(options);
        _log("options",At.options);
        return this.filter('textarea, input').each(function() {
            if (!At.reg(this)) return;
            $(this).bind("keyup",function(e) {
                /* 当用户列表框显示时, 上下键不触发查询 */
                var stop_key = e.keyCode == 40 || e.keyCode == 38;
                watch = !(At.view.watching() && stop_key);
                if (watch) At.watch(this);
            })
            .mouseup(function(e) {
                At.watch(this);
            });
        });
        return At;
    }
})(window.jQuery);
