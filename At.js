/* 
    Implement Twitter/Weibo @ mentions

    Copyright (C) 2012 chord.luo@gmail.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

(function($) {
    At = {
        cache : {},
        settings: {},
        // textarea, input.
        $inputor : null,
        lenght : 0,
        /* @ position in inputor */
        pos: 0,
        /* @ offset*/
        offset: function() {
            $inputor = this.$inputor;
            /* 克隆(镜像) inputor. 用于获得@在输入框中的位置
             * 复制它的大小形状相关的样式. */
            Mirror = function($origin) {
                this.init($origin);
            }
            Mirror.prototype = {
                $mirror: null,
                css : ["overflowY", "height", "width", "paddingTop", "paddingLeft", "paddingRight", "paddingBottom", "marginTop", "marginLeft", "marginRight", "marginBottom",'fontFamily', 'borderStyle', 'borderWidth', 'wordWrap', 'fontSize', 'lineHeight', 'overflowX'],
                init: function($origin) {
                    $mirror =  $('<div></div>');
                    var css = {
                        opacity: 0, 
                        position: 'absolute', 
                        left: 0,
                        top:0, 
                        zIndex: -20000
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
            mirror = $inputor.data("mirror");
            if (mirror == undefined) {
                mirror = new Mirror($inputor);
                $inputor.data("mirror",mirror);
            }
            /* 克隆完inputor后将原来的文本内容根据
             * @的位置进行分块,以获取@块在inputor(输入框)里的position
             * */
            start_range = $inputor.val().slice(0,this.pos);
            end_range = $inputor.val().slice(this.pos) - 1;
            html = "<span>"+start_range+"</span>";
            html += "<span id='flag'>@</span>";
            html += "<span id=>"+end_range -1 +"</span>";
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
            y = offset.top + at_pos.top + line_height - $(window).scrollTop();
            x = offset.left + at_pos.left;

            return {'top':y,'left':x};
        },
        getKey: function() {
            $inputor = this.$inputor;
            text = $inputor.val();
            //获得inputor中插入符的position.
            caret_pos = $inputor.caretPos();

            /* 向在插入符前的的文本进行正则匹配
             * 考虑会有多个 @ 的存在, 匹配离插入符最近的一个*/
            subtext = text.slice(0,caret_pos);
            word = subtext.match(/@\w+$|@[^\x00-\xff]+$/);
            key = null;
            if (word) {
                word = word.join("").slice(1);
                start = caret_pos - word.length;
                end = start + word.length;
                this.pos = start - 1;
                key = {'text':word, 'start':start, 'end':end};
            } else
                this.view.hide();
            this.cache['key'] = key;
            return key;
        },
        replaceStr: function(str) {
            /* $inputor.replaceStr(str,start,end)*/
            key = this.cache['key'];
            source = this.$inputor.val();
            start_str = source.slice(0, key.start);
            text = start_str + str + source.slice(key.end);
            $inputor.val(text);
            this.$inputor.caretPos(start_str.length + str.length);
        },
        choose: function($li) {
            this.replaceStr($li.text()+" ");
            this.view.hide();
        },
        init: function(options) {
            this.settings = $.extend({
                'url':"#",
                'param':{},
                'key_name':"keyword",
                'debug_data':[]
            },options);
        },
        run: function($inputor) {
            this.$inputor = $inputor;
            key = this.getKey();
            if (!key) return;
            //debug
            data = this.settings['debug_data'];
            if($.isArray(data) && data.length != 0) {
                this.runWithData(key,data);
                return;
            }

            url = this.settings['url'];
            params = this.settings['param'];
            params[this.settings['key_name']] = key.text;

            $.ajax(url,params,function(data){
                data = $.parseJSON(data);
                if ($.isArray(data))
                    At.view.load(data);
            });
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
        // 列表框是否显示中.
        running : false,
        //当前高亮的条目
        cur_li_idx : 0,
        id : '#at-view',
        /* 捕捉inputor的上下回车键.
         * 在列表框做相应的操作,上下滚动,回车选择
         * 返回 false 阻止冒泡事件以捕捉inputor对应的事件
         * */
        onkeydown:function(e) {
            // 当列表没显示时不捕捉inputor相关事件.
            if (!this.running) return true;

            last_idx = $(this.id).find("ul li").length - 1;
            $(this.id + " ul li.cur").removeClass("cur");
            switch (e.keyCode) {
                case 38:
                    if (last_idx <= 0) return true;
                    this.cur_li_idx--;
                    // 到达顶端时高亮效果跳到最后
                    if (this.cur_li_idx < 0)
                        this.cur_li_idx = last_idx;
                    $(this.id + " li:eq(" + this.cur_li_idx + ")")
                        .addClass('cur');
                    return false;
                    break;
                case 40:
                    if (last_idx <= 0) return true;
                    this.cur_li_idx++;
                    if (this.cur_li_idx > last_idx)
                        this.cur_li_idx = 0;
                    $(this.id + " li:eq(" + this.cur_li_idx + ")")
                        .addClass('cur');
                    return false;
                    break;
                case 13:
                    // 如果列表为空，则不捕捉回车事件
                    if (last_idx < 0) return false;
                    $cur_li = $(this.id + " li:eq("+this.cur_li_idx+")");
                    At.choose($cur_li);
                    this.hide();
                    return false;
                    break;
                default:
                    return true
            }
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
            })
            .blur(function(e){
                view.hide();
            });

            // 捕捉inputor事件
            view = this;
            At.$inputor.bind("keydown",function(e) {
                return view.onkeydown(e);
            });
        },
        rePosition:function() {
            $(this.id).offset({'top':0,'left':0}).offset(At.offset());
        },
        show: function(){
            $view = $(this.id).show();
            this.rePosition($view);
            this.running = true;
        },
        hide: function() {
            this.cur_li_idx = 0;
            $(this.id).hide();
            this.running = false;
        },
        load: function(name_list) {
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
            $(this.id+ " li:eq(0)").addClass("cur");
            this.show();
            this.length = name_list.length;
            return $at_view;
        }
    };
    
    $.fn.atWho = function (options) {
        At.init(options);
        $inputor = $(this);
        this.bind("keyup",function(e) {
            /* 当用户列表框显示时, 上下键不触发查询 */
            run = At.view.running && (e.keyCode == 40 || e.keyCode == 38);
            if (!run) At.run($inputor);
        })
        .mouseup(function() {
            At.run($inputor);
        });
        return this;
    }
})(jQuery);
