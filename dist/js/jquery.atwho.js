
/*
  Implement Github like autocomplete mentions
  http://ichord.github.com/At.js

  Copyright (c) 2013 chord.luo@gmail.com
  Licensed under the MIT license.
*/


(function() {

  (function(factory) {
    if (typeof define === 'function' && define.amd) {
      return define(['jquery'], factory);
    } else {
      return factory(window.jQuery);
    }
  })(function($) {
    var Controller, DEFAULT_CALLBACKS, DEFAULT_TPL, KEY_CODE, Mirror, View;
    Mirror = (function() {

      Mirror.prototype.css_attr = ["overflowY", "height", "width", "paddingTop", "paddingLeft", "paddingRight", "paddingBottom", "marginTop", "marginLeft", "marginRight", "marginBottom", "fontFamily", "borderStyle", "borderWidth", "wordWrap", "fontSize", "lineHeight", "overflowX", "text-align"];

      function Mirror($inputor) {
        this.$inputor = $inputor;
      }

      Mirror.prototype.copy_inputor_css = function() {
        var css,
          _this = this;
        css = {
          position: 'absolute',
          left: -9999,
          top: 0,
          zIndex: -20000,
          'white-space': 'pre-wrap'
        };
        $.each(this.css_attr, function(i, p) {
          return css[p] = _this.$inputor.css(p);
        });
        return css;
      };

      Mirror.prototype.create = function(html) {
        this.$mirror = $('<div></div>');
        this.$mirror.css(this.copy_inputor_css());
        this.$mirror.html(html);
        this.$inputor.after(this.$mirror);
        return this;
      };

      Mirror.prototype.get_flag_rect = function() {
        var $flag, pos, rect;
        $flag = this.$mirror.find("span#flag");
        pos = $flag.position();
        rect = {
          left: pos.left,
          top: pos.top,
          bottom: $flag.height() + pos.top
        };
        this.$mirror.remove();
        return rect;
      };

      return Mirror;

    })();
    KEY_CODE = {
      DOWN: 40,
      UP: 38,
      ESC: 27,
      TAB: 9,
      ENTER: 13
    };
    DEFAULT_CALLBACKS = {
      data_refactor: function(data) {
        if (!$.isArray(data)) {
          return data;
        }
        return $.map(data, function(item, k) {
          if (!$.isPlainObject(item)) {
            item = {
              name: item
            };
          }
          return item;
        });
      },
      matcher: function(flag, subtext) {
        var match, matched, regexp;
        regexp = new RegExp(flag + '([A-Za-z0-9_\+\-]*)$|' + flag + '([^\\x00-\\xff]*)$', 'gi');
        match = regexp.exec(subtext);
        matched = null;
        if (match) {
          matched = match[2] ? match[2] : match[1];
        }
        return matched;
      },
      filter: function(query, data, search_key) {
        var _this = this;
        return $.map(data, function(item, i) {
          var name;
          name = $.isPlainObject(item) ? item[search_key] : item;
          if (name.toLowerCase().indexOf(query) >= 0) {
            return item;
          }
        });
      },
      remote_filter: function(params, url, render_view) {
        return $.ajax(url, {
          data: params,
          success: function(data) {
            return render_view(data);
          }
        });
      },
      sorter: function(query, items, search_key) {
        var item, results, text, _i, _len;
        if (!query) {
          return items.sort(function(a, b) {
            if (a[search_key].toLowerCase() > b[search_key].toLowerCase()) {
              return 1;
            } else {
              return -1;
            }
          });
        }
        results = [];
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          item = items[_i];
          text = item[search_key];
          item.order = text.toLowerCase().indexOf(query);
          results.push(item);
        }
        return results.sort(function(a, b) {
          return a.order - b.order;
        });
      },
      tpl_eval: function(tpl, map) {
        var el;
        try {
          return el = tpl.replace(/\$\{([^\}]*)\}/g, function(tag, key, pos) {
            return map[key];
          });
        } catch (error) {
          return "";
        }
      },
      highlighter: function(li, query) {
        if (!query) {
          return li;
        }
        return li.replace(new RegExp(">\\s*(\\w*)(" + query.replace("+", "\\+") + ")(\\w*)\\s*<", 'ig'), function(str, $1, $2, $3) {
          return '> ' + $1 + '<strong>' + $2 + '</strong>' + $3 + ' <';
        });
      },
      selector: function($li) {
        if ($li.length > 0) {
          return this.replace_str($li.data("value") || "");
        }
      }
    };
    Controller = (function() {

      function Controller(inputor) {
        this.settings = {};
        this.common_settings = {};
        this.pos = 0;
        this.flags = null;
        this.current_flag = null;
        this.query = null;
        this.$inputor = $(inputor);
        this.mirror = new Mirror(this.$inputor);
        this.common_settings = $.extend({}, $.fn.atwho["default"]);
        this.view = new View(this, this.$el);
        this.listen();
      }

      Controller.prototype.listen = function() {
        var _this = this;
        return this.$inputor.on('keyup.atwho', function(e) {
          return _this.on_keyup(e);
        }).on('keydown.atwho', function(e) {
          return _this.on_keydown(e);
        }).on('scroll.atwho', function(e) {
          return _this.view.hide();
        }).on('blur.atwho', function(e) {
          return _this.view.hide(_this.get_opt("display_timeout"));
        });
      };

      Controller.prototype.reg = function(flag, settings) {
        var current_settings, data;
        current_settings = {};
        current_settings = $.isPlainObject(flag) ? this.common_settings = $.extend({}, this.common_settings, flag) : !this.settings[flag] ? this.settings[flag] = $.extend({}, settings) : this.settings[flag] = $.extend({}, this.settings[flag], settings);
        data = current_settings["data"];
        current_settings["data"] = this.callbacks("data_refactor").call(this, data);
        return this;
      };

      Controller.prototype.trigger = function(name, data) {
        data || (data = []);
        data.push(this);
        return this.$inputor.trigger("" + name + ".atwho", data);
      };

      Controller.prototype.data = function() {
        return this.get_opt("data");
      };

      Controller.prototype.callbacks = function(func_name) {
        var func;
        if (!(func = this.get_opt("callbacks", {})[func_name])) {
          func = this.common_settings["callbacks"][func_name];
        }
        return func;
      };

      Controller.prototype.get_opt = function(key, default_value) {
        var value;
        try {
          if (this.current_flag) {
            value = this.settings[this.current_flag][key];
          }
          if (value === void 0) {
            value = this.common_settings[key];
          }
          return value = value === void 0 ? default_value : value;
        } catch (e) {
          return value = default_value === void 0 ? null : default_value;
        }
      };

      Controller.prototype.rect = function() {
        var $inputor, Sel, at_rect, bottom, format, html, offset, start_range, x, y;
        $inputor = this.$inputor;
        if (document.selection) {
          Sel = document.selection.createRange();
          x = Sel.boundingLeft + $inputor.scrollLeft();
          y = Sel.boundingTop + $(window).scrollTop() + $inputor.scrollTop();
          bottom = y + Sel.boundingHeight;
          return {
            top: y - 2,
            left: x - 2,
            bottom: bottom - 2
          };
        }
        format = function(value) {
          return value.replace(/</g, '&lt').replace(/>/g, '&gt').replace(/`/g, '&#96').replace(/"/g, '&quot').replace(/\r\n|\r|\n/g, "<br />");
        };
        /* 克隆完inputor后将原来的文本内容根据
          @的位置进行分块,以获取@块在inputor(输入框)里的position
        */

        start_range = $inputor.val().slice(0, this.pos - 1);
        html = "<span>" + format(start_range) + "</span>";
        html += "<span id='flag'>?</span>";
        /*
                将inputor的 offset(相对于document)
                和@在inputor里的position相加
                就得到了@相对于document的offset.
                当然,还要加上行高和滚动条的偏移量.
        */

        offset = $inputor.offset();
        at_rect = this.mirror.create(html).get_flag_rect();
        x = offset.left + at_rect.left - $inputor.scrollLeft();
        y = offset.top - $inputor.scrollTop();
        bottom = y + at_rect.bottom;
        y += at_rect.top;
        return {
          top: y,
          left: x,
          bottom: bottom + 2
        };
      };

      Controller.prototype.catch_query = function() {
        var caret_pos, content, end, query, start, subtext,
          _this = this;
        content = this.$inputor.val();
        caret_pos = this.$inputor.caretPos();
        /* 向在插入符前的的文本进行正则匹配
         * 考虑会有多个 @ 的存在, 匹配离插入符最近的一个
        */

        subtext = content.slice(0, caret_pos);
        query = null;
        $.each(this.settings, function(flag, settings) {
          query = _this.callbacks("matcher").call(_this, flag, subtext);
          if (query != null) {
            _this.current_flag = flag;
            return false;
          }
        });
        if (typeof query === "string" && query.length <= 20) {
          start = caret_pos - query.length;
          end = start + query.length;
          this.pos = start;
          query = {
            'text': query.toLowerCase(),
            'head_pos': start,
            'end_pos': end
          };
          this.trigger("matched", [this.current_flag, query.text]);
        } else {
          this.view.hide();
        }
        return this.query = query;
      };

      Controller.prototype.replace_str = function(str) {
        var $inputor, flag_len, source, start_str, text;
        $inputor = this.$inputor;
        source = $inputor.val();
        flag_len = this.get_opt("display_flag") ? 0 : this.current_flag.length;
        start_str = source.slice(0, (this.query['head_pos'] || 0) - flag_len);
        text = "" + start_str + str + " " + (source.slice(this.query['end_pos'] || 0));
        $inputor.val(text);
        $inputor.caretPos(start_str.length + str.length + 1);
        return $inputor.change();
      };

      Controller.prototype.on_keyup = function(e) {
        switch (e.keyCode) {
          case KEY_CODE.ESC:
            e.preventDefault();
            this.view.hide();
            break;
          case KEY_CODE.DOWN:
          case KEY_CODE.UP:
            $.noop();
            break;
          default:
            this.look_up();
        }
        return e.stopPropagation();
      };

      Controller.prototype.on_keydown = function(e) {
        if (!this.view.visible()) {
          return;
        }
        switch (e.keyCode) {
          case KEY_CODE.ESC:
            e.preventDefault();
            this.view.hide();
            break;
          case KEY_CODE.UP:
            e.preventDefault();
            this.view.prev();
            break;
          case KEY_CODE.DOWN:
            e.preventDefault();
            this.view.next();
            break;
          case KEY_CODE.TAB:
          case KEY_CODE.ENTER:
            if (!this.view.visible()) {
              return;
            }
            e.preventDefault();
            this.view.choose();
            break;
          default:
            $.noop();
        }
        return e.stopPropagation();
      };

      Controller.prototype.render_view = function(data) {
        var search_key;
        search_key = this.get_opt("search_key");
        data = this.callbacks("sorter").call(this, this.query.text, data, search_key);
        data = data.splice(0, this.get_opt('limit'));
        return this.view.render(data);
      };

      Controller.prototype.remote_call = function(data, query) {
        var params, _callback;
        params = {
          q: query.text,
          limit: this.get_opt("limit")
        };
        _callback = function(data) {
          this.reg(this.current_flag, {
            data: data
          });
          return this.render_view(this.data());
        };
        _callback = $.proxy(_callback, this);
        return this.callbacks('remote_filter').call(this, params, data, _callback);
      };

      Controller.prototype.look_up = function() {
        var data, query, search_key;
        query = this.catch_query();
        if (!query) {
          return false;
        }
        data = this.data();
        search_key = this.get_opt("search_key");
        if (typeof data === "string") {
          this.remote_call(data, query);
        } else if ((data = this.callbacks('filter').call(this, query.text, data, search_key))) {
          this.render_view(data);
        } else {
          this.view.hide();
        }
        return $.noop();
      };

      return Controller;

    })();
    View = (function() {

      function View(controller) {
        this.controller = controller;
        this.id = this.controller.get_opt("view_id", "at-view");
        this.timeout_id = null;
        this.$el = $("#" + this.id);
        this.create_view();
      }

      View.prototype.create_view = function() {
        var $menu, tpl,
          _this = this;
        if (this.exist()) {
          return;
        }
        tpl = "<div id='" + this.id + "' class='at-view'><ul id='" + this.id + "-ul'></ul></div>";
        $("body").append(tpl);
        this.$el = $("#" + this.id);
        $menu = this.$el.find('ul');
        return $menu.on('mouseenter.view', 'li', function(e) {
          $menu.find('.cur').removeClass('cur');
          return $(e.currentTarget).addClass('cur');
        }).on('click', function(e) {
          e.stopPropagation();
          e.preventDefault();
          return _this.$el.data("_view").choose();
        });
      };

      View.prototype.exist = function() {
        return $("#" + this.id).length > 0;
      };

      View.prototype.visible = function() {
        return this.$el.is(":visible");
      };

      View.prototype.choose = function() {
        var $li;
        $li = this.$el.find(".cur");
        this.controller.callbacks("selector").call(this.controller, $li);
        this.controller.trigger("choose", [$li]);
        return this.hide();
      };

      View.prototype.reposition = function() {
        var offset, rect;
        rect = this.controller.rect();
        if (rect.bottom + this.$el.height() - $(window).scrollTop() > $(window).height()) {
          rect.bottom = rect.top - this.$el.height();
        }
        offset = {
          left: rect.left,
          top: rect.bottom
        };
        this.$el.offset(offset);
        return this.controller.trigger("reposition", [offset]);
      };

      View.prototype.next = function() {
        var cur, next;
        cur = this.$el.find('.cur').removeClass('cur');
        next = cur.next();
        if (!next.length) {
          next = $(this.$el.find('li')[0]);
        }
        return next.addClass('cur');
      };

      View.prototype.prev = function() {
        var cur, prev;
        cur = this.$el.find('.cur').removeClass('cur');
        prev = cur.prev();
        if (!prev.length) {
          prev = this.$el.find('li').last();
        }
        return prev.addClass('cur');
      };

      View.prototype.show = function() {
        if (!this.visible()) {
          this.$el.show();
        }
        return this.reposition();
      };

      View.prototype.hide = function(time) {
        var callback,
          _this = this;
        if (isNaN(time)) {
          if (this.visible()) {
            return this.$el.hide();
          }
        } else {
          callback = function() {
            return _this.hide();
          };
          clearTimeout(this.timeout_id);
          return this.timeout_id = setTimeout(callback, time);
        }
      };

      View.prototype.clear = function() {
        return this.$el.find('ul').empty();
      };

      View.prototype.render = function(list) {
        var $ul, tpl,
          _this = this;
        if (!$.isArray(list)) {
          return false;
        }
        if (list.length <= 0) {
          this.hide();
          return true;
        }
        this.clear();
        this.$el.data("_view", this);
        $ul = this.$el.find('ul');
        tpl = this.controller.get_opt('tpl', DEFAULT_TPL);
        $.each(list, function(i, item) {
          var $li, li;
          li = _this.controller.callbacks("tpl_eval").call(_this.controller, tpl, item);
          $li = $(_this.controller.callbacks("highlighter").call(_this.controller, li, _this.controller.query.text));
          $li.data("info", item);
          return $ul.append($li);
        });
        this.show();
        return $ul.find("li:eq(0)").addClass("cur");
      };

      return View;

    })();
    DEFAULT_TPL = "<li data-value='${name}'>${name}</li>";
    $.fn.atwho = function(flag, options) {
      return this.filter('textarea, input').each(function() {
        var $this, data;
        $this = $(this);
        data = $this.data("atwho");
        if (!data) {
          $this.data('atwho', (data = new Controller(this)));
        }
        return data.reg(flag, options);
      });
    };
    $.fn.atwho.Controller = Controller;
    $.fn.atwho.View = View;
    $.fn.atwho.Mirror = Mirror;
    return $.fn.atwho["default"] = {
      data: null,
      search_key: "name",
      callbacks: DEFAULT_CALLBACKS,
      limit: 5,
      display_flag: true,
      display_timeout: 300,
      tpl: DEFAULT_TPL
    };
  });

}).call(this);


/*
  Implement Github like autocomplete mentions
  http://ichord.github.com/At.js

  Copyright (c) 2013 chord.luo@gmail.com
  Licensed under the MIT license.
*/


/*
本插件操作 textarea 或者 input 内的插入符
只实现了获得插入符在文本框中的位置，我设置
插入符的位置.
*/


(function() {

  (function(factory) {
    if (typeof exports === 'object') {
      return factory(require('jquery'));
    } else if (typeof define === 'function' && define.amd) {
      return define(['jquery']);
    } else {
      return factory(window.jQuery);
    }
  })(function($) {
    var getCaretPos, setCaretPos;
    getCaretPos = function(inputor) {
      var end, endRange, len, normalizedValue, pos, range, start, textInputRange;
      if (document.selection) {
        /*
                #assume we select "HATE" in the inputor such as textarea -> { }.
                 *               start end-point.
                 *              /
                 * <  I really [HATE] IE   > between the brackets is the selection range.
                 *                   \
                 *                    end end-point.
        */

        range = document.selection.createRange();
        pos = 0;
        if (range && range.parentElement() === inputor) {
          normalizedValue = inputor.value.replace(/\r\n/g, "\n");
          /* SOMETIME !!!
           "/r/n" is counted as two char.
            one line is two, two will be four. balalala.
            so we have to using the normalized one's length.;
          */

          len = normalizedValue.length;
          /*
                       <[  I really HATE IE   ]>:
                        the whole content in the inputor will be the textInputRange.
          */

          textInputRange = inputor.createTextRange();
          /*                 _here must be the position of bookmark.
                           /
             <[  I really [HATE] IE   ]>
              [---------->[           ] : this is what moveToBookmark do.
             <   I really [[HATE] IE   ]> : here is result.
                            \ two brackets in should be in line.
          */

          textInputRange.moveToBookmark(range.getBookmark());
          endRange = inputor.createTextRange();
          /*  [--------------------->[] : if set false all end-point goto end.
            <  I really [[HATE] IE  []]>
          */

          endRange.collapse(false);
          /*
                                    ___VS____
                                   /         \
                     <   I really [[HATE] IE []]>
                                              \_endRange end-point.
          
                    " > -1" mean the start end-point will be the same or right to the end end-point
                   * simplelly, all in the end.
          */

          if (textInputRange.compareEndPoints("StartToEnd", endRange) > -1) {
            start = end = len;
          } else {
            /*
                                I really |HATE] IE   ]>
                                       <-|
                              I really[ [HATE] IE   ]>
                                    <-[
                            I reall[y  [HATE] IE   ]>
            
                          will return how many unit have moved.
            */

            start = -textInputRange.moveStart("character", -len);
            end = -textInputRange.moveEnd("character", -len);
          }
        }
      } else {
        start = inputor.selectionStart;
      }
      return start;
    };
    setCaretPos = function(inputor, pos) {
      var range;
      if (document.selection) {
        range = inputor.createTextRange();
        range.move("character", pos);
        return range.select();
      } else {
        return inputor.setSelectionRange(pos, pos);
      }
    };
    return $.fn.caretPos = function(pos) {
      var inputor;
      inputor = this[0];
      inputor.focus();
      if (pos) {
        return setCaretPos(inputor, pos);
      } else {
        return getCaretPos(inputor);
      }
    };
  });

}).call(this);
