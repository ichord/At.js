/*! jquery.atwho - v0.5.2 %>
* Copyright (c) 2014 chord.luo <chord.luo@gmail.com>;
* homepage: http://ichord.github.com/At.js
* Licensed MIT
*/
(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(["jquery"], function ($) {
      return (root.returnExportsGlobal = factory($));
    });
  } else if (typeof exports === 'object') {
    // Node. Does not work with strict CommonJS, but
    // only CommonJS-like enviroments that support module.exports,
    // like Node.
    module.exports = factory(require("jquery"));
  } else {
    factory(jQuery);
  }
}(this, function ($) {

var Api, App, Controller, DEFAULT_CALLBACKS, EditableController, KEY_CODE, Model, TextareaController, View,
  __slice = [].slice,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App = (function() {
  function App(inputor) {
    this.current_flag = null;
    this.controllers = {};
    this.alias_maps = {};
    this.$inputor = $(inputor);
    this.setIframe();
    this.listen();
  }

  App.prototype.createContainer = function(doc) {
    if ((this.$el = $("#atwho-container", doc)).length === 0) {
      return $(doc.body).append(this.$el = $("<div id='atwho-container'></div>"));
    }
  };

  App.prototype.setIframe = function(iframe, standalone) {
    var _ref;
    if (standalone == null) {
      standalone = false;
    }
    if (iframe) {
      this.window = iframe.contentWindow;
      this.document = iframe.contentDocument || this.window.document;
      this.iframe = iframe;
    } else {
      this.document = document;
      this.window = window;
      this.iframe = null;
    }
    if (this.iframeStandalone = standalone) {
      if ((_ref = this.$el) != null) {
        _ref.remove();
      }
      return this.createContainer(this.document);
    } else {
      return this.createContainer(document);
    }
  };

  App.prototype.controller = function(at) {
    var c, current, current_flag, _ref;
    if (this.alias_maps[at]) {
      current = this.controllers[this.alias_maps[at]];
    } else {
      _ref = this.controllers;
      for (current_flag in _ref) {
        c = _ref[current_flag];
        if (current_flag === at) {
          current = c;
          break;
        }
      }
    }
    if (current) {
      return current;
    } else {
      return this.controllers[this.current_flag];
    }
  };

  App.prototype.set_context_for = function(at) {
    this.current_flag = at;
    return this;
  };

  App.prototype.reg = function(flag, setting) {
    var controller, _base;
    controller = (_base = this.controllers)[flag] || (_base[flag] = this.$inputor.is('[contentEditable]') ? new EditableController(this, flag) : new TextareaController(this, flag));
    if (setting.alias) {
      this.alias_maps[setting.alias] = flag;
    }
    controller.init(setting);
    return this;
  };

  App.prototype.listen = function() {
    return this.$inputor.on('keyup.atwhoInner', (function(_this) {
      return function(e) {
        return _this.on_keyup(e);
      };
    })(this)).on('keydown.atwhoInner', (function(_this) {
      return function(e) {
        return _this.on_keydown(e);
      };
    })(this)).on('scroll.atwhoInner', (function(_this) {
      return function(e) {
        var _ref;
        return (_ref = _this.controller()) != null ? _ref.view.hide(e) : void 0;
      };
    })(this)).on('blur.atwhoInner', (function(_this) {
      return function(e) {
        var c;
        if (c = _this.controller()) {
          return c.view.hide(e, c.get_opt("display_timeout"));
        }
      };
    })(this)).on('click.atwhoInner', (function(_this) {
      return function(e) {
        return _this.dispatch(e);
      };
    })(this));
  };

  App.prototype.shutdown = function() {
    var c, _, _ref;
    _ref = this.controllers;
    for (_ in _ref) {
      c = _ref[_];
      c.destroy();
      delete this.controllers[_];
    }
    this.$inputor.off('.atwhoInner');
    return this.$el.remove();
  };

  App.prototype.dispatch = function(e) {
    return $.map(this.controllers, (function(_this) {
      return function(c) {
        var delay;
        if (delay = c.get_opt('delay')) {
          clearTimeout(_this.delayedCallback);
          return _this.delayedCallback = setTimeout(function() {
            if (c.look_up(e)) {
              return _this.set_context_for(c.at);
            }
          }, delay);
        } else {
          if (c.look_up(e)) {
            return _this.set_context_for(c.at);
          }
        }
      };
    })(this));
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
      case KEY_CODE.CTRL:
        $.noop();
        break;
      case KEY_CODE.P:
      case KEY_CODE.N:
        if (!e.ctrlKey) {
          this.dispatch(e);
        }
        break;
      default:
        this.dispatch(e);
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
        view.hide(e);
        break;
      case KEY_CODE.UP:
        e.preventDefault();
        view.prev();
        break;
      case KEY_CODE.DOWN:
        e.preventDefault();
        view.next();
        break;
      case KEY_CODE.P:
        if (!e.ctrlKey) {
          return;
        }
        e.preventDefault();
        view.prev();
        break;
      case KEY_CODE.N:
        if (!e.ctrlKey) {
          return;
        }
        e.preventDefault();
        view.next();
        break;
      case KEY_CODE.TAB:
      case KEY_CODE.ENTER:
        if (!view.visible()) {
          return;
        }
        e.preventDefault();
        view.choose(e);
        break;
      default:
        $.noop();
    }
  };

  return App;

})();

Controller = (function() {
  Controller.prototype.uid = function() {
    return (Math.random().toString(16) + "000000000").substr(2, 8) + (new Date().getTime());
  };

  function Controller(app, at) {
    this.app = app;
    this.at = at;
    this.$inputor = this.app.$inputor;
    this.id = this.$inputor[0].id || this.uid();
    this.setting = null;
    this.query = null;
    this.pos = 0;
    this.cur_rect = null;
    this.range = null;
    if ((this.$el = $("#atwho-ground-" + this.id, this.app.$el)).length === 0) {
      this.app.$el.append(this.$el = $("<div id='atwho-ground-" + this.id + "'></div>"));
    }
    this.model = new Model(this);
    this.view = new View(this);
  }

  Controller.prototype.init = function(setting) {
    this.setting = $.extend({}, this.setting || $.fn.atwho["default"], setting);
    this.view.init();
    return this.model.reload(this.setting.data);
  };

  Controller.prototype.destroy = function() {
    this.trigger('beforeDestroy');
    this.model.destroy();
    this.view.destroy();
    return this.$el.remove();
  };

  Controller.prototype.call_default = function() {
    var args, error, func_name;
    func_name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    try {
      return DEFAULT_CALLBACKS[func_name].apply(this, args);
    } catch (_error) {
      error = _error;
      return $.error("" + error + " Or maybe At.js doesn't have function " + func_name);
    }
  };

  Controller.prototype.trigger = function(name, data) {
    var alias, event_name;
    if (data == null) {
      data = [];
    }
    data.push(this);
    alias = this.get_opt('alias');
    event_name = alias ? "" + name + "-" + alias + ".atwho" : "" + name + ".atwho";
    return this.$inputor.trigger(event_name, data);
  };

  Controller.prototype.callbacks = function(func_name) {
    return this.get_opt("callbacks")[func_name] || DEFAULT_CALLBACKS[func_name];
  };

  Controller.prototype.get_opt = function(at, default_value) {
    var e;
    try {
      return this.setting[at];
    } catch (_error) {
      e = _error;
      return null;
    }
  };

  Controller.prototype.insert_content_for = function($li) {
    var data, data_value, tpl;
    data_value = $li.data('value');
    tpl = this.get_opt('insert_tpl');
    if (this.$inputor.is('textarea, input') || !tpl) {
      return data_value;
    }
    data = $.extend({}, $li.data('item-data'), {
      'atwho-data-value': data_value,
      'atwho-at': this.at
    });
    return this.callbacks("tpl_eval").call(this, tpl, data);
  };

  Controller.prototype.render_view = function(data) {
    var search_key;
    search_key = this.get_opt("search_key");
    data = this.callbacks("sorter").call(this, this.query.text, data.slice(0, 1001), search_key);
    return this.view.render(data.slice(0, this.get_opt('limit')));
  };

  Controller.prototype.look_up = function(e) {
    var query, _callback;
    if (!(query = this.catch_query(e))) {
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

TextareaController = (function(_super) {
  __extends(TextareaController, _super);

  function TextareaController() {
    return TextareaController.__super__.constructor.apply(this, arguments);
  }

  TextareaController.prototype.catch_query = function() {
    var caret_pos, content, end, query, start, subtext;
    content = this.$inputor.val();
    caret_pos = this.$inputor.caret('pos', {
      iframe: this.app.iframe
    });
    subtext = content.slice(0, caret_pos);
    query = this.callbacks("matcher").call(this, this.at, subtext, this.get_opt('start_with_space'));
    if (typeof query === "string" && query.length <= this.get_opt('max_len', 20)) {
      start = caret_pos - query.length;
      end = start + query.length;
      this.pos = start;
      query = {
        'text': query,
        'head_pos': start,
        'end_pos': end
      };
      this.trigger("matched", [this.at, query.text]);
    } else {
      query = null;
      this.view.hide();
    }
    return this.query = query;
  };

  TextareaController.prototype.rect = function() {
    var c, iframe_offset, scale_bottom;
    if (!(c = this.$inputor.caret('offset', this.pos - 1, {
      iframe: this.app.iframe
    }))) {
      return;
    }
    if (this.app.iframe && !this.app.iframeStandalone) {
      iframe_offset = $(this.app.iframe).offset();
      c.left += iframe_offset.left;
      c.top += iframe_offset.top;
    }
    scale_bottom = this.app.document.selection ? 0 : 2;
    return {
      left: c.left,
      top: c.top,
      bottom: c.top + c.height + scale_bottom
    };
  };

  TextareaController.prototype.insert = function(content, $li) {
    var $inputor, source, start_str, suffix, text;
    $inputor = this.$inputor;
    source = $inputor.val();
    start_str = source.slice(0, Math.max(this.query.head_pos - this.at.length, 0));
    suffix = (suffix = this.get_opt('suffix')) === "" ? suffix : suffix || " ";
    content += suffix;
    text = "" + start_str + content + (source.slice(this.query['end_pos'] || 0));
    $inputor.val(text);
    $inputor.caret('pos', start_str.length + content.length, {
      iframe: this.app.iframe
    });
    if (!$inputor.is(':focus')) {
      $inputor.focus();
    }
    return $inputor.change();
  };

  return TextareaController;

})(Controller);

EditableController = (function(_super) {
  __extends(EditableController, _super);

  function EditableController() {
    return EditableController.__super__.constructor.apply(this, arguments);
  }

  EditableController.prototype._getRange = function() {
    var sel;
    sel = this.app.window.getSelection();
    if (sel.rangeCount > 0) {
      return sel.getRangeAt(0);
    }
  };

  EditableController.prototype._setRangeEndAfter = function(node, range) {
    var sel;
    if (range == null) {
      range = this._getRange();
    }
    sel = this.app.window.getSelection();
    range.setEndAfter($(node)[0]);
    range.collapse(false);
    sel.removeAllRanges();
    return sel.addRange(range);
  };

  EditableController.prototype.catch_query = function(e) {
    var $query, content, matched, query, range, _range;
    if (!(range = this._getRange())) {
      return;
    }
    $(range.startContainer).closest('.atwho-inserted').removeClass('atwho-inserted').addClass('atwho-query');
    if (($query = $(".atwho-query", this.app.document)).length > 0) {
      if (e.type === "click" && $(range.startContainer).closest('.atwho-query').length === 0) {
        matched = null;
      } else {
        matched = this.callbacks("matcher").call(this, this.at, $query.text(), this.get_opt('start_with_space'));
      }
    } else {
      _range = range.cloneRange();
      _range.setStart(range.startContainer, 0);
      content = _range.toString();
      matched = this.callbacks("matcher").call(this, this.at, content, this.get_opt('start_with_space'));
      if (typeof matched === 'string') {
        range.setStart(range.startContainer, content.lastIndexOf(this.at));
        range.surroundContents(($query = $("<span class='atwho-query'/>", this.app.document))[0]);
        this._setRangeEndAfter($query, range);
      }
    }
    if (typeof matched === 'string' && matched.length <= this.get_opt('max_len', 20)) {
      query = {
        text: matched,
        el: $query
      };
      this.trigger("matched", [this.at, query.text]);
    } else {
      this.view.hide();
      query = null;
      if ($query.text().indexOf(this.at) > -1) {
        $query.html($query.text());
        this._setRangeEndAfter($query.contents().first().unwrap());
      }
    }
    return this.query = query;
  };

  EditableController.prototype.rect = function() {
    var iframe_offset, rect;
    rect = this.query.el.offset();
    if (this.app.iframe && !this.app.iframeStandalone) {
      iframe_offset = $(this.app.iframe).offset();
      rect.left += iframe_offset.left;
      rect.top += iframe_offset.top;
    }
    rect.bottom = rect.top + this.query.el.height();
    return rect;
  };

  EditableController.prototype.insert = function(content, $li) {
    var range, suffix, suffixNode;
    suffix = (suffix = this.get_opt('suffix')) ? suffix : suffix || "\u00A0";
    this.query.el.removeClass('atwho-query').addClass('atwho-inserted').html(content);
    if (range = this._getRange()) {
      range.setEndAfter(this.query.el[0]);
      range.collapse(false);
      range.insertNode(suffixNode = this.app.document.createTextNode(suffix));
      this._setRangeEndAfter(suffixNode, range);
    }
    if (!this.$inputor.is(':focus')) {
      this.$inputor.focus();
    }
    return this.$inputor.change();
  };

  return EditableController;

})(Controller);

Model = (function() {
  function Model(context) {
    this.context = context;
    this.at = this.context.at;
    this.storage = this.context.$inputor;
  }

  Model.prototype.destroy = function() {
    return this.storage.data(this.at, null);
  };

  Model.prototype.saved = function() {
    return this.fetch() > 0;
  };

  Model.prototype.query = function(query, callback) {
    var data, search_key, _remote_filter;
    data = this.fetch();
    search_key = this.context.get_opt("search_key");
    data = this.context.callbacks('filter').call(this.context, query, data, search_key) || [];
    _remote_filter = this.context.callbacks('remote_filter');
    if (data.length > 0 || (!_remote_filter && data.length === 0)) {
      return callback(data);
    } else {
      return _remote_filter.call(this.context, query, callback);
    }
  };

  Model.prototype.fetch = function() {
    return this.storage.data(this.at) || [];
  };

  Model.prototype.save = function(data) {
    return this.storage.data(this.at, this.context.callbacks("before_save").call(this.context, data || []));
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
    if (typeof data === "string") {
      return $.ajax(data, {
        dataType: "json"
      }).done((function(_this) {
        return function(data) {
          return _this.save(data);
        };
      })(this));
    } else {
      return this.save(data);
    }
  };

  return Model;

})();

View = (function() {
  function View(context) {
    this.context = context;
    this.$el = $("<div class='atwho-view'><ul class='atwho-view-ul'></ul></div>");
    this.timeout_id = null;
    this.context.$el.append(this.$el);
    this.bind_event();
  }

  View.prototype.init = function() {
    var id;
    id = this.context.get_opt("alias") || this.context.at.charCodeAt(0);
    return this.$el.attr({
      'id': "at-view-" + id
    });
  };

  View.prototype.destroy = function() {
    return this.$el.remove();
  };

  View.prototype.bind_event = function() {
    var $menu;
    $menu = this.$el.find('ul');
    return $menu.on('mouseenter.atwho-view', 'li', function(e) {
      $menu.find('.cur').removeClass('cur');
      return $(e.currentTarget).addClass('cur');
    }).on('click.atwho-view', 'li', (function(_this) {
      return function(e) {
        $menu.find('.cur').removeClass('cur');
        $(e.currentTarget).addClass('cur');
        _this.choose(e);
        return e.preventDefault();
      };
    })(this));
  };

  View.prototype.visible = function() {
    return this.$el.is(":visible");
  };

  View.prototype.choose = function(e) {
    var $li, content;
    if (($li = this.$el.find(".cur")).length) {
      content = this.context.insert_content_for($li);
      this.context.insert(this.context.callbacks("before_insert").call(this.context, content, $li), $li);
      this.context.trigger("inserted", [$li, e]);
      this.hide(e);
    }
    if (this.context.get_opt("hide_without_suffix")) {
      return this.stop_showing = true;
    }
  };

  View.prototype.reposition = function(rect) {
    var offset, overflowOffset, _ref, _window;
    _window = this.context.app.iframeStandalone ? this.context.app.window : window;
    if (rect.bottom + this.$el.height() - $(_window).scrollTop() > $(_window).height()) {
      rect.bottom = rect.top - this.$el.height();
    }
    if (rect.left > (overflowOffset = $(_window).width() - this.$el.width() - 5)) {
      rect.left = overflowOffset;
    }
    offset = {
      left: rect.left,
      top: rect.bottom
    };
    if ((_ref = this.context.callbacks("before_reposition")) != null) {
      _ref.call(this.context, offset);
    }
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
    next.addClass('cur');
    return this.$el.animate({
      scrollTop: Math.max(0, cur.innerHeight() * (next.index() + 2) - this.$el.height())
    }, 150);
  };

  View.prototype.prev = function() {
    var cur, prev;
    cur = this.$el.find('.cur').removeClass('cur');
    prev = cur.prev();
    if (!prev.length) {
      prev = this.$el.find('li:last');
    }
    prev.addClass('cur');
    return this.$el.animate({
      scrollTop: Math.max(0, cur.innerHeight() * (prev.index() + 2) - this.$el.height())
    }, 150);
  };

  View.prototype.show = function() {
    var rect;
    if (this.stop_showing) {
      this.stop_showing = false;
      return;
    }
    if (!this.visible()) {
      this.$el.show();
      this.$el.scrollTop(0);
      this.context.trigger('shown');
    }
    if (rect = this.context.rect()) {
      return this.reposition(rect);
    }
  };

  View.prototype.hide = function(e, time) {
    var callback;
    if (!this.visible()) {
      return;
    }
    if (isNaN(time)) {
      this.$el.hide();
      return this.context.trigger('hidden', [e]);
    } else {
      callback = (function(_this) {
        return function() {
          return _this.hide();
        };
      })(this);
      clearTimeout(this.timeout_id);
      return this.timeout_id = setTimeout(callback, time);
    }
  };

  View.prototype.render = function(list) {
    var $li, $ul, item, li, tpl, _i, _len;
    if (!($.isArray(list) && list.length > 0)) {
      this.hide();
      return;
    }
    this.$el.find('ul').empty();
    $ul = this.$el.find('ul');
    tpl = this.context.get_opt('tpl');
    for (_i = 0, _len = list.length; _i < _len; _i++) {
      item = list[_i];
      item = $.extend({}, item, {
        'atwho-at': this.context.at
      });
      li = this.context.callbacks("tpl_eval").call(this.context, tpl, item);
      $li = $(this.context.callbacks("highlighter").call(this.context, li, this.context.query.text));
      $li.data("item-data", item);
      $ul.append($li);
    }
    this.show();
    if (this.context.get_opt('highlight_first')) {
      return $ul.find("li:first").addClass("cur");
    }
  };

  return View;

})();

KEY_CODE = {
  DOWN: 40,
  UP: 38,
  ESC: 27,
  TAB: 9,
  ENTER: 13,
  CTRL: 17,
  P: 80,
  N: 78
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
    var match, regexp, _a, _y;
    flag = flag.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
    if (should_start_with_space) {
      flag = '(?:^|\\s)' + flag;
    }
    _a = decodeURI("%C3%80");
    _y = decodeURI("%C3%BF");
    regexp = new RegExp("" + flag + "([A-Za-z" + _a + "-" + _y + "0-9_\+\-]*)$|" + flag + "([^\\x00-\\xff]*)$", 'gi');
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
      if (~new String(item[search_key]).toLowerCase().indexOf(query.toLowerCase())) {
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
      item.atwho_order = new String(item[search_key]).toLowerCase().indexOf(query.toLowerCase());
      if (item.atwho_order > -1) {
        _results.push(item);
      }
    }
    return _results.sort(function(a, b) {
      return a.atwho_order - b.atwho_order;
    });
  },
  tpl_eval: function(tpl, map) {
    var error;
    try {
      return tpl.replace(/\$\{([^\}]*)\}/g, function(tag, key, pos) {
        return map[key];
      });
    } catch (_error) {
      error = _error;
      return "";
    }
  },
  highlighter: function(li, query) {
    var regexp;
    if (!query) {
      return li;
    }
    regexp = new RegExp(">\\s*(\\w*?)(" + query.replace("+", "\\+") + ")(\\w*)\\s*<", 'ig');
    return li.replace(regexp, function(str, $1, $2, $3) {
      return '> ' + $1 + '<strong>' + $2 + '</strong>' + $3 + ' <';
    });
  },
  before_insert: function(value, $li) {
    return value;
  }
};

Api = {
  load: function(at, data) {
    var c;
    if (c = this.controller(at)) {
      return c.model.load(data);
    }
  },
  setIframe: function(iframe, standalone) {
    this.setIframe(iframe, standalone);
    return null;
  },
  run: function() {
    return this.dispatch();
  },
  destroy: function() {
    this.shutdown();
    return this.$inputor.data('atwho', null);
  }
};

$.fn.atwho = function(method) {
  var result, _args;
  _args = arguments;
  result = null;
  this.filter('textarea, input, [contenteditable=""], [contenteditable=true]').each(function() {
    var $this, app;
    if (!(app = ($this = $(this)).data("atwho"))) {
      $this.data('atwho', (app = new App(this)));
    }
    if (typeof method === 'object' || !method) {
      return app.reg(method.at, method);
    } else if (Api[method] && app) {
      return result = Api[method].apply(app, Array.prototype.slice.call(_args, 1));
    } else {
      return $.error("Method " + method + " does not exist on jQuery.caret");
    }
  });
  return result || this;
};

$.fn.atwho["default"] = {
  at: void 0,
  alias: void 0,
  data: null,
  tpl: "<li data-value='${atwho-at}${name}'>${name}</li>",
  insert_tpl: "<span id='${id}'>${atwho-data-value}</span>",
  callbacks: DEFAULT_CALLBACKS,
  search_key: "name",
  suffix: void 0,
  hide_without_suffix: false,
  start_with_space: true,
  highlight_first: true,
  limit: 5,
  max_len: 20,
  display_timeout: 300,
  delay: null
};



}));
