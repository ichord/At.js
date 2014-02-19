@KEY_CODE =
  DOWN: 40
  UP: 38
  ESC: 27
  TAB: 9
  ENTER: 13

@fixtures or= loadJSONFixtures("data.json")["data.json"]

@triggerAtwhoAt = ($inputor) ->
  simulateTypingIn $inputor
  simulate_choose $inputor

@simulateTypingIn = ($inputor, flag) ->
  $inputor.data("atwho").set_context_for flag || "@"
  $inputor.caret('pos', 31)
  $inputor.trigger("keyup")

@simulate_choose = ($inputor) ->
  e = $.Event("keydown", keyCode: KEY_CODE.ENTER)
  $inputor.trigger(e)

@getAppOf = ($inputor, at = "@") ->
  $inputor.data('atwho').set_context_for(at)
