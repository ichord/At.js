(function() {

  (function($) {
    var At, AtView, Mirror, log, _DEFAULT_TPL, _evalTpl, _isNil, _unique;
    Mirror = function($origin) {
      this.init($origin);
      return this;
    };
    Mirror.prototype = {
      $mirror: null,
      css: ["overflowY", "height", "width", "paddingTop", "paddingLeft", "paddingRight", "paddingBottom", "marginTop", "marginLeft", "marginRight", "marginBottom", 'fontFamily', 'borderStyle', 'borderWidth', 'wordWrap', 'fontSize', 'lineHeight', 'overflowX'],
      init: function($origin) {
        var $mirror, css;
        $mirror = $('<div></div>');
        css = {
          opacity: 0,
          position: 'absolute',
          left: 0,
          top: 0,
          zIndex: -20000,
          'white-space': 'pre-wrap'
        };
        $.each(this.css, function(i, p) {
          return css[p] = $origin.css(p);
        });
        $mirror.css(css);
        $('body').append($mirror);
        return this.$mirror = $mirror;
      },
      setContent: function(html) {
        return this.$mirror.html(html);
      },
      getFlagPos: function() {
        return this.$mirror.find("span#flag").position();
      },
      height: function() {
        return this.$mirror.height();
      }
    };
    At = function(inputor) {
      var $inputor,
        _this = this;
      $inputor = this.$inputor = $(inputor);
      this.options = {};
      this.keyword = {
        text: "",
        start: 0,
        stop: 0
      };
      this._cache = {};
      this.pos = 0;
      this.flags = {};
      this.theflag = null;
      this.search_word = {};
      this.view = AtView;
      this.mirror = new Mirror($inputor);
      $inputor.on("keyup.inputor", function(e) {
        var lookup, stop;
        stop = e.keyCode === 40 || e.keyCode === 38;
        lookup = !(stop && _this.view.isShowing());
        if (lookup) return _this.lookup();
      }).on("mouseup.inputor", function(e) {
        return _this.lookup();
      });
      this.init();
      log("At.new", $inputor[0]);
      return this;
    };
    At.prototype = {
      constructor: At,
      init: function() {
        var _this = this;
        this.$inputor.on('keydown.inputor', function(e) {
          return _this.onkeydown(e);
        }).on('scroll.inputor', function(e) {
          return _this.view.hide();
        }).on('blur.inputor', function(e) {
          var callback;
          callback = function() {
            return this.view.hide();
          };
          return _this.view.timeout_id = setTimeout(callback, 150);
        });
        return log("At.init", this.$inputor[0]);
      },
      reg: function(flag, options) {
        var opt;
        opt = {};
        if ($.isFunction(options)) {
          opt['callback'] = options;
        } else {
          opt = options;
        }
        this.options[flag] = $.extend({}, $.fn.atWho["default"], opt);
        return log("At.reg", this.$inputor[0], flag, options);
      },
      searchWord: function() {
        var match, search_word;
        search_word = this.search_word[this.theflag];
        if (search_word) return search_word;
        match = /data-value=['?]\$\{(\w+)\}/g.exec(this.getOpt('tpl'));
        return this.search_word[this.theflag] = !_isNil(match) ? match[1] : null;
      },
      getOpt: function(key) {
        try {
          return this.options[this.theflag][key];
        } catch (error) {
          return null;
        }
      },
      offset: function() {
        var $inputor, Sel, at_pos, end_range, format, html, line_height, mirror, offset, start_range, text, x, y;
        $inputor = this.$inputor;
        if (document.selection) {
          Sel = document.selection.createRange();
          x = Sel.boundingLeft + $inputor.scrollLeft();
          y = Sel.boundingTop + Sel.boundingHeight + $(window).scrollTop() + $inputor.scrollTop();
          return {
            'top': y,
            'left': x
          };
        }
        mirror = this.mirror;
        format = function(value) {
          return value.replace(/</g, '&lt').replace(/>/g, '&gt').replace(/`/g, '&#96').replace(/"/g, '&quot').replace(/\r\n|\r|\n/g, "<br />");
        };
        /* 克隆完inputor后将原来的文本内容根据
          @的位置进行分块,以获取@块在inputor(输入框)里的position
        */
        text = $inputor.val();
        start_range = text.slice(0, this.pos - 1);
        end_range = text.slice(this.pos + 1);
        html = "<span>" + format(start_range) + "</span>";
        html += "<span id='flag'>@</span>";
        html += "<span>" + format(end_range) + "</span>";
        mirror.setContent(html);
        /*
                      将inputor的 offset(相对于document)
                      和@在inputor里的position相加
                      就得到了@相对于document的offset.
                      当然,还要加上行高和滚动条的偏移量.
        */
        offset = $inputor.offset();
        at_pos = mirror.getFlagPos();
        line_height = $inputor.css("line-height");
        line_height = isNaN(line_height) ? 20 : line_height;
        /*
                    FIXME: -$(window).scrollTop() get "wrong" offset.
                     but is good for $inputor.scrollTop()
                     jquey 1. + 07.1 fixed the scrollTop problem!?
        */
        y = offset.top + at_pos.top + line_height - $inputor.scrollTop();
        x = offset.left + at_pos.left - $inputor.scrollLeft();
        return {
          'top': y,
          'left': x
        };
      },
      cache: function(value) {
        var key, _base;
        key = this.keyword.text;
        if (!this.getOpt("cache") || !key) return null;
        return (_base = this._cache)[key] || (_base[key] = value);
      },
      getKeyname: function() {
        var $inputor, caret_pos, end, key, matched, start, subtext, text,
          _this = this;
        $inputor = this.$inputor;
        text = $inputor.val();
        caret_pos = $inputor.caretPos();
        /* 向在插入符前的的文本进行正则匹配
         * 考虑会有多个 @ 的存在, 匹配离插入符最近的一个
        */
        subtext = text.slice(0, caret_pos);
        matched = null;
        $.each(this.options, function(flag) {
          var match, regexp;
          regexp = new RegExp(flag + '([A-Za-z0-9_\+\-]*)$|' + flag + '([^\\x00-\\xff]*)$', 'gi');
          match = regexp.exec(subtext);
          if (!_isNil(match)) {
            matched = match[1] === 'undefined' ? match[2] : match[1];
            _this.theflag = flag;
            return false;
          }
        });
        if (typeof matched === 'string' && matched.length <= 20) {
          start = caret_pos - matched.length;
          end = start + matched.length;
          this.pos = start;
          key = {
            'text': matched,
            'start': start,
            'end': end
          };
        } else {
          this.view.hide();
        }
        log("At.getKeyname", key);
        return this.keyword = key;
      },
      replaceStr: function(str) {
        var $inputor, key, source, start_str, text;
        $inputor = this.$inputor;
        key = this.keyword;
        source = $inputor.val();
        start_str = source.slice(0, key.start);
        text = start_str + str + source.slice(key.end);
        $inputor.val(text);
        $inputor.caretPos(start_str.length + str.length);
        return $inputor.change();
      },
      onkeydown: function(e) {
        var view;
        view = this.view;
        if (!view.isShowing()) return;
        switch (e.keyCode) {
          case 38:
            e.preventDefault();
            view.prev();
            break;
          case 40:
            e.preventDefault();
            view.next();
            break;
          case 9:
          case 13:
            if (!view.isShowing()) return;
            e.preventDefault();
            view.choose();
            break;
          default:
            $.noop();
        }
        return e.stopPropagation();
      },
      loadView: function(datas) {
        log("At.loadView", this, datas);
        return this.view.load(this, datas);
      },
      lookup: function() {
        var callback, datas, key;
        key = this.getKeyname();
        if (!key) return false;
        log("At.lookup.key", key);
        if (!_isNil(datas = this.cache())) {
          this.loadView(datas);
        } else if (!_isNil(datas = this.lookupWithData(key))) {
          this.loadView(datas);
        } else if ($.isFunction(callback = this.getOpt('callback'))) {
          callback(key.text, this.loadView);
        } else {
          this.view.hide();
        }
        return $.noop();
      },
      lookupWithData: function(key) {
        var data, items,
          _this = this;
        data = this.getOpt("data");
        if ($.isArray(data) && data.length !== 0) {
          items = $.map(data, function(item, i) {
            var match, name, regexp;
            try {
              name = $.isPlainObject(item) ? item[_this.searchWord()] : item;
              regexp = new RegExp(key.text.replace("+", "\\+"), 'i');
              match = name.match(regexp);
            } catch (e) {
              return null;
            }
            if (match) {
              return item;
            } else {
              return null;
            }
          });
        }
        return items;
      }
    };
    AtView = {
      timeout_id: null,
      id: '#at-view',
      holder: null,
      _jqo: null,
      jqo: function() {
        var jqo;
        jqo = this._jqo;
        return jqo = _isNil(jqo) ? (this._jqo = $(this.id)) : jqo;
      },
      init: function() {
        var $menu, tpl,
          _this = this;
        if (!_isNil(this.jqo())) return;
        tpl = "<div id='" + this.id.slice(1) + "' class='at-view'><ul id='" + this.id.slice(1) + "-ul'></ul></div>";
        $("body").append(tpl);
        $menu = this.jqo().find('ul');
        return $menu.on('mouseenter.view', 'li', function(e) {
          $menu.find('.cur').removeClass('cur');
          return $(e.currentTarget).addClass('cur');
        }).on('click', function(e) {
          e.stopPropagation();
          e.preventDefault();
          return _this.choose();
        });
      },
      isShowing: function() {
        return this.jqo().is(":visible");
      },
      choose: function() {
        var $li, str;
        $li = this.jqo().find(".cur");
        str = _isNil($li) ? this.holder.keyword.text + " " : $li.attr("data-value") + " ";
        this.holder.replaceStr(str);
        return this.hide();
      },
      rePosition: function() {
        return this.jqo().offset(this.holder.offset());
      },
      next: function(e) {
        var cur, next;
        cur = this.jqo().find('.cur').removeClass('cur');
        next = cur.next();
        if (!cur.length) next = $(this.jqo().find('li')[0]);
        return next.addClass('cur');
      },
      prev: function(e) {
        var cur, prev;
        cur = this.jqo().find('.cur').removeClass('cur');
        prev = cur.prev();
        if (!prev.length) prev = this.jqo().find('li').last();
        return prev.addClass('cur');
      },
      show: function(e) {
        if (!this.isShowing()) this.jqo().show();
        return this.rePosition();
      },
      hide: function(e) {
        if (this.isShowing()) return this.jqo().hide();
      },
      clear: function(clear_all) {
        if (clear_all === true) this._cache = {};
        return this.jqo().find('ul').empty();
      },
      load: function(holder, list) {
        var $ul, tpl;
        if (!$.isArray(list)) return false;
        this.holder = holder;
        holder.cache(list);
        this.clear();
        tpl = holder.getOpt('tpl');
        list = _unique(list, holder.searchWord());
        $ul = this.jqo().find('ul');
        $.each(list.splice(0, holder.getOpt('limit')), function(i, item) {
          if (!$.isPlainObject(item)) {
            item = {
              id: i,
              name: item
            };
            tpl = _DEFAULT_TPL;
          }
          return $ul.append(_evalTpl(tpl, item));
        });
        this.show();
        return $ul.find("li:eq(0)").addClass("cur");
      }
    };
    _evalTpl = function(tpl, map) {
      var el;
      try {
        return el = tpl.replace(/\$\{([^\}]*)\}/g, function(tag, key, pos) {
          return map[key];
        });
      } catch (error) {
        return "";
      }
    };
    /* 
      maybe we can use $._unique. 
      But i don't know it will delete li element frequently or not.
      I think we should not change DOM element frequently.
      more, It seems batter not to call evalTpl function too much times.
    */
    _unique = function(list, keyword) {
      var record;
      record = [];
      return $.map(list, function(v, id) {
        var value;
        value = $.isPlainObject(v) ? v[keyword] : v;
        if ($.inArray(value, record) < 0) {
          record.push(value);
          return v;
        }
      });
    };
    _isNil = function(target) {
      return !target || ($.isPlainObject(target) && $.isEmptyObject(target)) || ($.isArray(target) && target.length === 0) || (target instanceof $ && target.length === 0) || target === void 0;
    };
    _DEFAULT_TPL = "<li id='${id}' data-value='${name}'>${name}</li>";
    log = function() {
      return console.log(arguments);
    };
    $.fn.atWho = function(flag, options) {
      AtView.init();
      return this.filter('textarea, input').each(function() {
        var $this, data;
        $this = $(this);
        data = $this.data("AtWho");
        if (!data) $this.data('AtWho', (data = new At(this)));
        return data.reg(flag, options);
      });
    };
    return $.fn.atWho["default"] = {
      data: [],
      callback: null,
      cache: true,
      limit: 5,
      tpl: _DEFAULT_TPL
    };
  })(window.jQuery);

}).call(this);
