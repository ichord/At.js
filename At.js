/* 
    Implement Twitter/Weibo @ mentions

    Copyright (C) 2012 @chord.luo

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
        cur_li_idx : 0,
        $inputor : null,
        tpl_id : "#at-view",
        running : false,
        pos: 0,
        getAtOffset: function() {
            $inputor = this.$inputor;
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
            start_range = $inputor.val().slice(0,this.pos);
            end_range = $inputor.val().slice(this.pos);
            html = "<span>"+start_range+"</span>";
            html += "<span id='flag'>"+end_range+"</span>";
            mirror.setContent(html);

            offset = $inputor.offset();
            at_offset = mirror.getFlagPos();
            line_height = $inputor.css("line-height");
            line_height = isNaN(line_height) ? 20 : line_height;
            y = offset.top + at_offset.top + line_height - $(window).scrollTop();
            x = offset.left + at_offset.left;

            return {'top':y,'left':x};
        },
        rePosition:function() {
            offset = this.getAtOffset();
            $(this.tpl_id).offset({'top':0,'left':0}).offset(offset);
        },
        getKey: function() {
            $inputor = this.$inputor;
            text = $inputor.val()
            caret_pos = $inputor.caretPos();

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
                this.display(false);
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
        choose: function(Li) {
            str = Li.text();
            this.replaceStr(str+" ");
            $(this.tpl_id).hide();
        },
        onkeydown:function(e) {
            last_idx = $(this.tpl_id).find("ul li").length - 1;
            $(this.tpl_id + " ul li.cur").removeClass("cur");
            switch (e.keyCode) {
                case 38:
                    if (last_idx <= 0) return false;
                    this.cur_li_idx--;
                    if (this.cur_li_idx < 0)
                        this.cur_li_idx = last_idx;
                    $(this.tpl_id + " li:eq(" + this.cur_li_idx + ")")
                        .addClass('cur');
                    return false;
                    break;
                case 40:
                    if (last_idx <= 0) return false;
                    this.cur_li_idx++;
                    if (this.cur_li_idx > last_idx)
                        this.cur_li_idx = 0;
                    $(this.tpl_id + " li:eq(" + this.cur_li_idx + ")")
                        .addClass('cur');
                    return false;
                    break;
                case 13:
                    if (last_idx <= 0) return false;
                    $cur_li = $(this.tpl_id + " li:eq("+this.cur_li_idx+")");
                    this.choose($cur_li);
                    this.display(false);
                    return false;
                    break;
                default:
                    return true
            }
        },
        onViewReady : function($view) {
            var at = this;
            this.$inputor.bind("keydown",function(e) {
                return at.onkeydown(e);
            })
            .bind("keyup",function(e) {
                if (e.keyCode == 40 || e.keyCode == 38)
                    return false;
            });
            this.rePosition($view);
        },
        onViewLoad: function($view) {
            at = this;
            $view.click(function(e) {
                e.target.tagName == "LI" && at.choose($(e.target))
            });
            $view.mousemove(function(e) {
                if (e.target.tagName == "LI") {
                    $(this).find("li:eq(" + at.cur_li_idx + ")").removeClass("cur");
                    $(e.target).addClass("cur");
                    at.cur_li_idx = $(this).find("li").index(e.target)
                }
            })
        },
        display: function(show) {
            show = show == false ? show : true;
            if (this.running == show == true) {
                return;
            }
            $view = $(this.tpl_id);
            if (!show) {
                this.$inputor.unbind();
                $view.hide();
            } else {
                $view.show();
                this.onViewReady($view);
            }
            return this.running = show;
        },
        loadView: function(name_list) {
            $at_view = $(this.tpl_id);
            //TODO init
            this.cur_li_idx = 0;
            if ($at_view.length == 0) {
                tpl = "<div id='"+this.tpl_id.slice(1)+"' class='at_view'><strong>你想@谁?</strong><ul id='"+this.tpl_id+"-ul'></ul></div>";
                $at_view = $(tpl);
                $('body').append($at_view);
                $at_view = $(this.tpl_id);
                this.onViewLoad($at_view);
            }
            if ($at_view.length) {
                li_tpl = "";
                $.each(name_list,function(i,name){
                    li_tpl += "<li>" + name + "</li>";
                });
                $at_view.find('ul').empty().append($(li_tpl));
                $(this.tpl_id + " li:eq(0)").addClass("cur");
                this.display();
            }
            return $at_view;
        },
        run: function($inputor) {
            this.$inputor = $inputor;
            key = this.getKey();
            if (!key) return;
            params = {'keyword':key.text};
            /*$.ajax(url,params,function(name_list){
                At.loadView(name_list);
            });*/
            name_list = {
                'as':['asee','asabc','asthree'],
                'a':['aone','atwo','athree']
            };
            nicknames = name_list[key.text];
            nicknames = nicknames ? nicknames : [];
            At.loadView(nicknames);
        }
    }
    
    $.fn.atWho = function () {
        $inputor = $(this).find('textarea:first-child');
        this.keyup(function(){
            At.run($inputor);
        })
        .mouseup(function(){
            At.run($inputor);
        });
        return this;
    }
})(jQuery);
