(function() {
  this.KEY_CODE = {
    DOWN: 40,
    UP: 38,
    ESC: 27,
    TAB: 9,
    ENTER: 13
  };

  this.fixtures || (this.fixtures = loadJSONFixtures("data.json")["data.json"]);

  this.triggerAtwhoAt = function($inputor) {
    simulateTypingIn($inputor);
    return simulateChoose($inputor);
  };

  this.simulateTypingIn = function($inputor, flag) {
    var clonedRange, oDocument, oWindow, range, sel;
    $inputor.data("atwho").set_context_for(flag || "@");
    oDocument = $inputor[0].ownerDocument;
    oWindow = oDocument.defaultView || oDocument.parentWindow;
    if ($inputor.attr('contentEditable') === 'true' && oWindow.getSelection) {
      $inputor.focus();
      sel = oWindow.getSelection();
      range = sel.getRangeAt(0);
      clonedRange = range.cloneRange();
      clonedRange.selectNodeContents($inputor[0]);
      clonedRange.setStart(range.endContainer, 31);
      clonedRange.collapse(true);
      sel.removeAllRanges();
      sel.addRange(clonedRange);
    } else {
      $inputor.caret('pos', 31);
    }
    return $inputor.trigger("keyup");
  };

  this.simulateChoose = function($inputor) {
    var e;
    e = $.Event("keydown", {
      keyCode: KEY_CODE.ENTER
    });
    return $inputor.trigger(e);
  };

  this.getAppOf = function($inputor, at) {
    if (at == null) {
      at = "@";
    }
    return $inputor.data('atwho').set_context_for(at);
  };

}).call(this);
