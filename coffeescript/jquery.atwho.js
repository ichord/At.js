(function() {

  (function($) {
    var At, Mirror;
    Mirror = function($origin) {
      return this.init($origin);
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
          'white-space': pre - wrap
        };
        $.each(this.css(function(i, p) {
          return css[p] = $origin.css(p);
        }));
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
    return At = function(inputor) {
      this.options = {};
      this.keyword = {
        text: "",
        start: 0,
        stop: 0
      };
      return this._cache = {};
    };
  })(window.jQuery);

}).call(this);
