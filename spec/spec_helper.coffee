@KEY_CODE =
  DOWN: 40
  UP: 38
  ESC: 27
  TAB: 9
  ENTER: 13
  CTRL: 17
  P: 80
  N: 78

@fixtures or= loadJSONFixtures("data.json")["data.json"]

@triggerAtwhoAt = ($inputor) ->
  simulateTypingIn $inputor
  simulateChoose $inputor

@simulateTypingIn = ($inputor, flag) ->
  $inputor.data("atwho").set_context_for flag || "@"
  oDocument = $inputor[0].ownerDocument
  oWindow = oDocument.defaultView || oDocument.parentWindow
  if $inputor.attr('contentEditable') == 'true' && oWindow.getSelection
    $inputor.focus()
    sel = oWindow.getSelection()
    range = sel.getRangeAt(0)
    clonedRange = range.cloneRange()
    clonedRange.selectNodeContents($inputor[0])
    clonedRange.setStart(range.endContainer, 31)
    clonedRange.collapse(true)
    sel.removeAllRanges()
    sel.addRange(clonedRange)
  else
    $inputor.caret('pos', 31)

  $inputor.trigger("keyup")

@simulateChoose = ($inputor) ->
  e = $.Event("keydown", keyCode: KEY_CODE.ENTER)
  $inputor.trigger(e)

@getAppOf = ($inputor, at = "@") ->
  $inputor.data('atwho').set_context_for(at)
