
/*
  Implement Github like autocomplete mentions
  http://ichord.github.com/At.js

  Copyright (c) 2013 chord.luo@gmail.com
  Licensed under the MIT license.
*/


(function() {
  var __slice = [].slice;

  (function(factory) {
    if (typeof define === 'function' && define.amd) {
      return define(['jquery'], factory);
    } else {
      return factory(window.jQuery);
    }
  })(function($) {
    var $CONTAINER, Api, App, Controller, DEFAULT_CALLBACKS, KEY_CODE, Model, View;
    App = (function() {

      function App(inputor) {
        this.current_flag = null;
        this.controllers = {};
        this.$inputor = $(inputor);
        this.listen();
      }

      App.prototype.controller = function(key) {
        return this.controllers[key || this.current_flag];
      };

      App.prototype.set_context_for = function(key) {
        this.current_flag = key;
        return this;
      };

      App.prototype.reg = function(flag, setting) {
        var controller, _base;
        controller = (_base = this.controllers)[flag] || (_base[flag] = new Controller(this, flag));
        if (setting.alias) {
          this.controllers[setting.alias] = controller;
        }
        controller.init(setting);
        return this;
      };

      App.prototype.listen = function() {
        var _this = this;
        return this.$inputor.on('keyup.atwho', function(e) {
          return _this.on_keyup(e);
        }).on('keydown.atwho', function(e) {
          return _this.on_keydown(e);
        }).on('scroll.atwho', function(e) {
          var _ref;
          return (_ref = _this.controller()) != null ? _ref.view.hide() : void 0;
        }).on('blur.atwho', function(e) {
          var c;
          if (c = _this.controller()) {
            return c.view.hide(c.get_opt("display_timeout"));
          }
        });
      };

      App.prototype.dispatch = function() {
        var _this = this;
        return $.map(this.controllers, function(c) {
          if (c.look_up()) {
            return _this.set_context_for(c.key);
          }
        });
      };

      App.prototype.on_keyup = function(e) {
        var _ref;
        switch (e.keyCode) {
          case KEY_CODE.ESC:
            e.preventDefault();
            if ((_ref = this.controller()) != null) {
              _ref.view.hide();
            }
            break;
          case KEY_CODE.DOWN:
          case KEY_CODE.UP:
            $.noop();
            break;
          default:
            this.dispatch();
        }
      };

      App.prototype.on_keydown = function(e) {
        var view, _ref;
        view = (_ref = this.controller()) != null ? _ref.view : void 0;
        if (!(view && view.visible())) {
          return;
        }
        switch (e.keyCode) {
          case KEY_CODE.ESC:
            e.preventDefault();
            view.hide();
            break;
          case KEY_CODE.UP:
            e.preventDefault();
            view.prev();
            break;
          case KEY_CODE.DOWN:
            e.preventDefault();
            view.next();
            break;
          case KEY_CODE.TAB:
          case KEY_CODE.ENTER:
            if (!view.visible()) {
              return;
            }
            e.preventDefault();
            view.choose();
            break;
          default:
            $.noop();
        }
      };

      return App;

    })();
    Controller = (function() {
      var uuid, _uuid;

      _uuid = 0;

      uuid = function() {
        return _uuid += 1;
      };

      function Controller(app, key) {
        this.app = app;
        this.key = key;
        this.at = this.key;
        this.$inputor = this.app.$inputor;
        this.id = this.$inputor[0].id || uuid();
        this.setting = null;
        this.query = null;
        this.pos = 0;
        this.cur_rect = null;
        $CONTAINER.append(this.$el = $("<div id='atwho-ground-" + this.id + "'></div>"));
        this.model = new Model(this);
        this.view = new View(this);
      }

      Controller.prototype.init = function(setting) {
        this.setting = $.extend({}, this.setting || $.fn.atwho["default"], setting);
        return this.model.reload(this.setting.data);
      };

      Controller.prototype.call_default = function() {
        var args, func_name;
        func_name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        try {
          return DEFAULT_CALLBACKS[func_name].apply(this, args);
        } catch (error) {
          return $.error("" + error + " Or maybe At.js doesn't have function " + func_name);
        }
      };

      Controller.prototype.data = function(key) {
        var ids;
        if (key) {
          key = "-" + (this.get_opt('alias') || this.at);
        }
        ids = {};
        return $.map(this.$inputor.find("span.atwho-view-flag" + (key || "")), function(item) {
          var data;
          data = $(item).data('atwho-data-itemInfo');
          if (ids[data.id]) {
            return;
          }
          if (data.id) {
            ids[data.id] = true;
          }
          return data;
        });
      };

      Controller.prototype.trigger = function(name, data) {
        var alias, event_name;
        data.push(this);
        alias = this.get_opt('alias');
        event_name = alias ? "" + name + "-" + alias + ".atwho" : "" + name + ".atwho";
        return this.$inputor.trigger(event_name, data);
      };

      Controller.prototype.callbacks = function(func_name) {
        return this.get_opt("callbacks")[func_name] || DEFAULT_CALLBACKS[func_name];
      };

      Controller.prototype.get_opt = function(key, default_value) {
        try {
          return this.setting[key];
        } catch (e) {
          return null;
        }
      };

      Controller.prototype.content = function() {
        if (this.$inputor.is('textarea, input')) {
          return this.$inputor.val();
        } else {
          return this.$inputor.text();
        }
      };

      Controller.prototype.catch_query = function() {
        var caret_pos, content, end, query, start, subtext;
        content = this.content();
        caret_pos = this.$inputor.caret('pos');
        subtext = content.slice(0, caret_pos);
        query = this.callbacks("matcher").call(this, this.key, subtext, this.get_opt('start_with_space'));
        if (typeof query === "string" && query.length <= this.get_opt('max_len', 20)) {
          start = caret_pos - query.length;
          end = start + query.length;
          this.pos = start;
          query = {
            'text': query.toLowerCase(),
            'head_pos': start,
            'end_pos': end
          };
          this.trigger("matched", [this.key, query.text]);
        } else {
          this.view.hide();
        }
        return this.query = query;
      };

      Controller.prototype.rect = function() {
        var c, scale_bottom;
        c = this.$inputor.caret('offset', this.pos - 1);
        if (this.$inputor.attr('contentEditable') === 'true') {
          c = (this.cur_rect || (this.cur_rect = c)) || c;
        }
        scale_bottom = document.selection ? 0 : 2;
        return {
          left: c.left,
          top: c.top,
          bottom: c.top + c.height + scale_bottom
        };
      };

      Controller.prototype.reset_rect = function() {
        if (this.$inputor.attr('contentEditable') === 'true') {
          return this.cur_rect = null;
        }
      };

      Controller.prototype.insert_content_for = function($li) {
        var at, data, data_value, tpl;
        data_value = $li.data('value');
        tpl = this.get_opt('insert_tpl');
        if (this.$inputor.is('textarea, input') || !tpl) {
          return data_value;
        }
        at = this.get_opt('at');
        data = $.extend({}, $li.data('atwho-data-itemInfo'), {
          'atwho-data-value': data_value,
          'atwho-at': at
        });
        return this.callbacks("tpl_eval").call(this, tpl, data);
      };

      Controller.prototype.insert = function(content, $li) {
        var $inputor, $insert_node, at_len, pos, range, sel, should_show_the_at, source, start_str, text, the_at_text;
        $inputor = this.$inputor;
        should_show_the_at = this.get_opt('show_the_at');
        if ($inputor.attr('contentEditable') === 'true') {
          the_at_text = should_show_the_at ? this.at : "";
          $insert_node = $("<span contenteditable='false' " + ("class='atwho-view-flag atwho-view-flag-" + (this.get_opt('alias') || this.at) + "'>") + ("" + the_at_text + content + "&nbsp;</span>"));
          $insert_node.data('atwho-data-itemInfo', $li.data('atwho-data-itemInfo'));
          $insert_node = $("<span contentEditable='true'></span>").html($insert_node);
        }
        if ($inputor.is('textarea, input')) {
          content = '' + content;
          source = $inputor.val();
          at_len = should_show_the_at ? 0 : this.at.length;
          start_str = source.slice(0, Math.max(this.query.head_pos - at_len, 0));
          text = "" + start_str + content + " " + (source.slice(this.query['end_pos'] || 0));
          $inputor.val(text);
          $inputor.caret('pos', start_str.length + content.length + 1);
        } else if (window.getSelection) {
          sel = window.getSelection();
          range = sel.getRangeAt(0);
          pos = sel.anchorOffset - (this.query.end_pos - this.query.head_pos) - this.at.length;
          range.setStart(range.endContainer, Math.max(pos, 0));
          range.setEnd(range.endContainer, range.endOffset);
          range.deleteContents();
          range.insertNode($insert_node[0]);
          range.collapse(false);
          sel.removeAllRanges();
          sel.addRange(range);
        } else if (document.selection) {
          range = document.selection.createRange();
          range.moveStart('character', this.query.end_pos - this.query.head_pos - this.at.length);
          range.pasteHTML($insert_node[0]);
          range.collapse(false);
          range.select();
        }
        return $inputor.change();
      };

      Controller.prototype.render_view = function(data) {
        var search_key;
        search_key = this.get_opt("search_key");
        data = this.callbacks("sorter").call(this, this.query.text, data.slice(0, 1001), search_key);
        return this.view.render(data.slice(0, this.get_opt('limit')));
      };

      Controller.prototype.look_up = function() {
        var query, _callback;
        if (!(query = this.catch_query())) {
          return;
        }
        _callback = function(data) {
          if (data && data.length > 0) {
            return this.render_view(data);
          } else {
            return this.view.hide();
          }
        };
        this.model.query(query.text, $.proxy(_callback, this));
        return query;
      };

      return Controller;

    })();
    Model = (function() {
      var _storage;

      _storage = {};

      function Model(context) {
        this.context = context;
        this.key = this.context.key;
      }

      Model.prototype.saved = function() {
        return this.fetch() > 0;
      };

      Model.prototype.query = function(query, callback) {
        var data, search_key, _ref;
        data = this.fetch();
        search_key = this.context.get_opt("search_key");
        callback(data = this.context.callbacks('filter').call(this.context, query, data, search_key));
        if (!(data && data.length > 0)) {
          return (_ref = this.context.callbacks('remote_filter')) != null ? _ref.call(this.context, query, callback) : void 0;
        }
      };

      Model.prototype.fetch = function() {
        return _storage[this.key] || [];
      };

      Model.prototype.save = function(data) {
        return _storage[this.key] = this.context.callbacks("before_save").call(this.context, data || []);
      };

      Model.prototype.load = function(data) {
        if (!(this.saved() || !data)) {
          return this._load(data);
        }
      };

      Model.prototype.reload = function(data) {
        return this._load(data);
      };

      Model.prototype._load = function(data) {
        var _this = this;
        if (typeof data === "string") {
          return $.ajax(data, {
            dataType: "json"
          }).done(function(data) {
            return _this.save(data);
          });
        } else {
          return this.save(data);
        }
      };

      return Model;

    })();
    View = (function() {

      function View(context) {
        this.context = context;
        this.key = this.context.key;
        this.id = this.context.get_opt("alias") || ("at-view-" + (this.key.charCodeAt(0)));
        this.$el = $("<div id='" + this.id + "' class='atwho-view'><ul id='" + this.id + "-ul' class='atwho-view-url'></ul></div>");
        this.timeout_id = null;
        this.context.$el.append(this.$el);
        this.bind_event();
      }

      View.prototype.bind_event = function() {
        var $menu,
          _this = this;
        $menu = this.$el.find('ul');
        return $menu.on('mouseenter.view', 'li', function(e) {
          $menu.find('.cur').removeClass('cur');
          return $(e.currentTarget).addClass('cur');
        }).on('click', function(e) {
          _this.choose();
          return e.preventDefault();
        });
      };

      View.prototype.visible = function() {
        return this.$el.is(":visible");
      };

      View.prototype.choose = function() {
        var $li, content;
        $li = this.$el.find(".cur");
        content = this.context.insert_content_for($li);
        this.context.insert(this.context.callbacks("before_insert").call(this.context, content, $li), $li);
        this.context.trigger("inserted", [$li]);
        return this.hide();
      };

      View.prototype.reposition = function() {
        var offset, rect;
        rect = this.context.rect();
        if (rect.bottom + this.$el.height() - $(window).scrollTop() > $(window).height()) {
          rect.bottom = rect.top - this.$el.height();
        }
        offset = {
          left: rect.left,
          top: rect.bottom
        };
        this.$el.offset(offset);
        return this.context.trigger("reposition", [offset]);
      };

      View.prototype.next = function() {
        var cur, next;
        cur = this.$el.find('.cur').removeClass('cur');
        next = cur.next();
        if (!next.length) {
          next = this.$el.find('li:first');
        }
        return next.addClass('cur');
      };

      View.prototype.prev = function() {
        var cur, prev;
        cur = this.$el.find('.cur').removeClass('cur');
        prev = cur.prev();
        if (!prev.length) {
          prev = this.$el.find('li:last');
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
        if (isNaN(time && this.visible())) {
          this.context.reset_rect();
          return this.$el.hide();
        } else {
          callback = function() {
            return _this.hide();
          };
          clearTimeout(this.timeout_id);
          return this.timeout_id = setTimeout(callback, time);
        }
      };

      View.prototype.render = function(list) {
        var $li, $ul, item, li, tpl, _i, _len;
        if (!$.isArray(list || list.length <= 0)) {
          this.hide();
          return;
        }
        this.$el.find('ul').empty();
        $ul = this.$el.find('ul');
        tpl = this.context.get_opt('tpl');
        for (_i = 0, _len = list.length; _i < _len; _i++) {
          item = list[_i];
          li = this.context.callbacks("tpl_eval").call(this.context, tpl, item);
          $li = $(this.context.callbacks("highlighter").call(this.context, li, this.context.query.text));
          $li.data("atwho-data-itemInfo", item);
          $ul.append($li);
        }
        this.show();
        return $ul.find("li:first").addClass("cur");
      };

      return View;

    })();
    KEY_CODE = {
      DOWN: 40,
      UP: 38,
      ESC: 27,
      TAB: 9,
      ENTER: 13
    };
    DEFAULT_CALLBACKS = {
      before_save: function(data) {
        var item, _i, _len, _results;
        if (!$.isArray(data)) {
          return data;
        }
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          item = data[_i];
          if ($.isPlainObject(item)) {
            _results.push(item);
          } else {
            _results.push({
              name: item
            });
          }
        }
        return _results;
      },
      matcher: function(flag, subtext, should_start_with_space) {
        var match, regexp;
        flag = flag.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
        if (should_start_with_space) {
          flag = '(?:^|\\s)' + flag;
        }
        regexp = new RegExp(flag + '([A-Za-z0-9_\+\-]*)$|' + flag + '([^\\x00-\\xff]*)$', 'gi');
        match = regexp.exec(subtext);
        if (match) {
          return match[2] || match[1];
        } else {
          return null;
        }
      },
      filter: function(query, data, search_key) {
        var item, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          item = data[_i];
          if (~item[search_key].toLowerCase().indexOf(query)) {
            _results.push(item);
          }
        }
        return _results;
      },
      remote_filter: null,
      sorter: function(query, items, search_key) {
        var item, _i, _len, _results;
        if (!query) {
          return items;
        }
        _results = [];
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          item = items[_i];
          item.atwho_order = item[search_key].toLowerCase().indexOf(query);
          if (item.atwho_order > -1) {
            _results.push(item);
          }
        }
        return _results.sort(function(a, b) {
          return a.atwho_order - b.atwho_order;
        });
      },
      tpl_eval: function(tpl, map) {
        try {
          return tpl.replace(/\$\{([^\}]*)\}/g, function(tag, key, pos) {
            return map[key];
          });
        } catch (error) {
          return "";
        }
      },
      highlighter: function(li, query) {
        var regexp;
        if (!query) {
          return li;
        }
        regexp = new RegExp(">\\s*(\\w*)(" + query.replace("+", "\\+") + ")(\\w*)\\s*<", 'ig');
        return li.replace(regexp, function(str, $1, $2, $3) {
          return '> ' + $1 + '<strong>' + $2 + '</strong>' + $3 + ' <';
        });
      },
      before_insert: function(value, $li) {
        return value;
      }
    };
    Api = {
      init: function(options) {
        var $this, app;
        app = ($this = $(this)).data("atwho");
        if (!app) {
          $this.data('atwho', (app = new App(this)));
        }
        return app.reg(options.at, options);
      },
      load: function(key, data) {
        var c;
        if (c = this.controller(key)) {
          return c.model.load(data);
        }
      },
      getInsertedItems: function(key, callback) {
        var c;
        if (c = this.controller(key)) {
          return callback.apply(null, [c.data()]);
        }
      },
      run: function() {
        return this.dispatch();
      }
    };
    $CONTAINER = $("<div id='atwho-container'></div>");
    $.fn.atwho = function(method) {
      var _args;
      _args = arguments;
      $('body').append($CONTAINER);
      return this.filter('textarea, input, [contenteditable=true]').each(function() {
        var app;
        if (typeof method === 'object' || !method) {
          return Api.init.apply(this, _args);
        } else if (Api[method]) {
          if (app = $(this).data('atwho')) {
            return Api[method].apply(app, Array.prototype.slice.call(_args, 1));
          }
        } else {
          return $.error("Method " + method + " does not exist on jQuery.caret");
        }
      });
    };
    return $.fn.atwho["default"] = {
      at: void 0,
      alias: void 0,
      data: null,
      tpl: "<li data-value='${name}'>${name}</li>",
      insert_tpl: null,
      callbacks: DEFAULT_CALLBACKS,
      search_key: "name",
      show_the_at: true,
      start_with_space: true,
      limit: 5,
      max_len: 20,
      display_timeout: 300
    };
  });

}).call(this);
