
describe "events", ->

	$inputor = null
	app = null

	beforeEach ->
    loadFixtures "inputors.html"
    $inputor = $("#inputor").atwho at: "@", data: fixtures["names"]
    app = getAppOf $inputor

	describe "jquery", ->
	  controller = null
	  callbacks = null

	  beforeEach ->
	    controller = app.controller()
	    callbacks = $.fn.atwho.default.callbacks
	    simulateTypingIn $inputor

	  it "trigger esc", ->
	    esc_event = $.Event("keyup.atwho", keyCode: KEY_CODE.ESC)
	    $inputor.trigger(esc_event)
	    expect(controller.view.visible()).toBe(false)

	  it "trigger tab", ->
	    spyOn(callbacks, "before_insert").and.callThrough()
	    tab_event = $.Event("keydown.atwho", keyCode: KEY_CODE.TAB)
	    $inputor.trigger(tab_event)
	    expect(controller.view.visible()).toBe(false)
	    expect(callbacks.before_insert).toHaveBeenCalled()

	  it "trigger enter", ->
	    spyOn(callbacks, "before_insert").and.callThrough()
	    enter_event = $.Event("keydown.atwho", keyCode: KEY_CODE.ENTER)
	    $inputor.trigger(enter_event)
	    expect(callbacks.before_insert).toHaveBeenCalled()

	  it "trigger up", ->
	    spyOn(controller.view, "prev").and.callThrough()
	    up_event = $.Event("keydown.atwho", keyCode: KEY_CODE.UP)
	    $inputor.trigger(up_event)
	    expect(controller.view.prev).toHaveBeenCalled()

	  it "trigger down", ->
	    spyOn(controller.view, "next").and.callThrough()
	    down_event = $.Event("keydown.atwho", keyCode: KEY_CODE.DOWN)
	    $inputor.trigger(down_event)
	    expect(controller.view.next).toHaveBeenCalled()

	describe "atwho", ->

	  it "trigger matched", ->
	    matched_event = spyOnEvent($inputor, "matched.atwho")
	    triggerAtwhoAt $inputor
	    expect(matched_event).toHaveBeenTriggered()

	  it "trigger inserted", ->
	    choose_event = spyOnEvent($inputor, "inserted.atwho")
	    triggerAtwhoAt $inputor
	    expect(choose_event).toHaveBeenTriggered()

	  it "trigger reposition", ->
	    reposition_event = spyOnEvent($inputor, "reposition.atwho")
	    triggerAtwhoAt $inputor
	    expect(reposition_event).toHaveBeenTriggered()

	  it "trigger a special matched for @ with alias", ->
	    $inputor.atwho
	      at: "@"
	      alias: "at-memtions"

	    event = spyOnEvent($inputor, "matched-at-memtions.atwho")
	    triggerAtwhoAt $inputor
	    expect(event).toHaveBeenTriggered()
