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
                /* must use word-wrap rather than wordWrap. $.css not work for this property in ie*/
                'word-wrap':'break-word'
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
        }
    };
    At = {
        keyword : {'text':"",'start':0,'stop':0},
        _cache : {},
        // textarea, input.
        $inputor : null,
        lenght : 0,
        /* @ position in inputor */
        pos: 0,
        /* @ offset*/
        offset: function() {
            $inputor = this.$inputor;
            mirror = $inputor.data("mirror");
            if (mirror == undefined) {
                mirror = new Mirror($inputor);
                $inputor.data("mirror",mirror);
            }
            
            /* 将inputor中字符转化成对应的html特殊字符
             * 如 <,> 等, 包括换行符*/
            function format(value) {
                //html encode
                rep_str = "<pre style='display:inline;'> </pre>";
                if ($.browser.msie && $.browser.version <= 8)
                    rep_str = "<span style='white-space:pre-wrap;'> </span>";
                return value.replace(/ /g,rep_str).replace(/\r\n|\r|\n/g,"<br />");
            } 
            /* 克隆完inputor后将原来的文本内容根据
             * @的位置进行分块,以获取@块在inputor(输入框)里的position
             * */
            text = $inputor.val();
            start_range = text.slice(0,this.pos);
            end_range = text.slice(this.pos+1);
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
            // jquey 1.7.1 fixed the scrollTop problem!?
            y = offset.top + at_pos.top + line_height
                - $inputor.scrollTop();
            x = offset.left + at_pos.left - $inputor.scrollLeft();

            return {'top':y,'left':x};
        },
        cache: function(key,value) {
            if (!settings['cache']) return null;
            if (value)
                this._cache[key] = value;
            return this._cache[key];
        },
        getKey: function() {
            $inputor = this.$inputor;
            text = $inputor.val();
            //获得inputor中插入符的position.
            caret_pos = $inputor.caretPos();
            /* 向在插入符前的的文本进行正则匹配
             * 考虑会有多个 @ 的存在, 匹配离插入符最近的一个*/
            subtext = text.slice(0,caret_pos);
            word = subtext.match(/@\w+$|@[^\x00-\xff]+$/g);
            key = null;
            if (!word) {
                this.view.hide();
                return null;
            }
            word = word.join("").slice(1);
            start = caret_pos - word.length;
            end = start + word.length;
            this.pos = start - 1;
            key = {'text':word, 'start':start, 'end':end};
            this.keyword = key;
            return key;
        },
        /* 捕捉inputor的上下回车键.
         * 在列表框做相应的操作,上下滚动,回车选择
         * 返回 false 阻止冒泡事件以捕捉inputor对应的事件
         * */
        onkeydown:function(e) {
            view = this.view;
            // 当列表没显示时不捕捉inputor相关事件.
            if (!view.running()) return true;
            last_idx = $(view.id).find("ul li").length - 1;
            switch (e.keyCode) {
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
                    return false;
                    break;
                case 40:
                    $(view.id + " ul li.cur").removeClass("cur");
                    view.cur_li_idx++;
                    if (view.cur_li_idx > last_idx)
                        view.cur_li_idx = 0;
                    $(view.id + " li:eq(" + view.cur_li_idx + ")")
                        .addClass('cur');
                    return false;
                    break;
                case 13:
                    $(view.id + " ul li.cur").removeClass("cur");
                    // 如果列表为空，则不捕捉回车事件
                    $cur_li = $(view.id + " li:eq("+view.cur_li_idx+")");
                    this.choose($cur_li);
                    view.hide();
                    return false;
                    break;
                default:
                    return true
            }
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
            this.replaceStr($li.text()+" ");
            this.view.hide();
        },
        reg: function(inputor) {
            // 捕捉inputor事件
            var self = this;
            $(inputor).bind("keydown",function(e) {
                return self.onkeydown(e);
            })
            .scroll(function(e){
                self.view.hide();
            })
            .blur(function(e){
                self.view.timeout_id = setTimeout("At.view.hide()",100);
            });   
        },
        run: function(inputor) {
            this.$inputor = $(inputor);
            key = this.getKey();
            if (!key) return false;
            
            data = settings['data'];
            if($.isArray(data) && data.length != 0) {
                this.runWithData(key,data);
                return true;
            }

            if (data = this.cache(this.keyword.text))
                return this.view.load(data);
            callback = settings['callback'];
            if($.isFunction(callback)) {
                callback(At);
                //At.view.load(names);
            }
        },
        runWithData:function(key,data) {
            names = $.map(data,function(name) {
                match = name.match((new RegExp(key.text,"i")));
                return match ? name : null;
            });
            At.view.load(names);
        }
    };

    /* 弹出的用户列表框相关的操作 */
    At.view = {
        //当前高亮的条目
        cur_li_idx : 0,
        timeout_id : null,
        id : '#at-view',
        // 列表框是否显示中.
        running :function() {
            return $(this.id).is(":visible");
        },
        onLoaded: function($view) {
            $view.click(function(e) {
                e.target.tagName == "LI" && At.choose($(e.target));
            })
            .mousemove(function(e) {
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
            if (!this.running())
                $view = $(this.id).show();
            this.rePosition($view);
        },
        hide: function() {
            if (!this.running()) return;
            this.cur_li_idx = 0;
            $(this.id).hide();
        },
        load: function(name_list) {
            At.cache(At.keyword.text,name_list);
            if (!$.isArray(name_list)) return false;
            $at_view = $(this.id);

            // 是否已经加载了列表视图
            if ($at_view.length == 0) {
                tpl = "<div id='"+this.id.slice(1)+"' class='at-view'><span>@who?</span><ul id='"+this.id.slice(1)+"-ul'></ul></div>";
                $at_view = $(tpl);
                $('body').append($at_view);
                $at_view = $(this.id);
                this.onLoaded($at_view);
            }

            //update data;
            li_tpl = "";
            $.each(name_list,function(i,name){
                li_tpl += "<li>" + name + "</li>";
            });
            $at_view.find('ul:first').html(li_tpl);
            this.show();
            $(this.id+ " ul li:eq(0)").addClass("cur");
            this.length = name_list.length;
            return $at_view;
        }
    };

    function setSettings(options) {
        opt = {};
        if ($.isFunction(options))
            opt['callback'] = options;
        else
            opt = options;
        return $.extend({
            //must return array;
            'callback': function(context) {return []},
            'cache' : true,
            'data':[]
        },opt);
    }
    
    $.fn.atWho = function (options) {
        settings = setSettings(options);
        return this.each(function() {
            At.reg(this);
            $(this).bind("keyup",function(e) {
                /* 当用户列表框显示时, 上下键不触发查询 */
                run = At.view.running() && (e.keyCode == 40 || e.keyCode == 38);
                if (!run) At.run(this);
            })
            .mouseup(function(e) {
                At.run(this);
            });
        });
    }
})(jQuery);
