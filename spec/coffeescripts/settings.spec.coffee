describe "settings", ->

  $inputor = null
  app = null
  controller = null
  callbacks = null

  beforeEach ->
    loadFixtures("inputors.html")
    $inputor = $("#inputor").atwho at: "@", data: fixtures["names"]
    app = getAppOf $inputor
    controller = app.controller()
    callbacks = $.fn.atwho.default.callbacks

  it "update common settings", ->
    func = () ->
      $.noop
    old = $.extend {}, $.fn.atwho.default.callbacks
    $.fn.atwho.default.callbacks.filter = func
    $.fn.atwho.default.limit = 8
    $inputor = $("<input/>").atwho at: "@"
    controller = $inputor.data('atwho').set_context_for("@").controller()
    expect(controller.callbacks("filter")).toBe func
    expect(controller.get_opt("limit")).toBe 8
    $.extend $.fn.atwho.default.callbacks, old

  it "update specific settings", ->
    $inputor.atwho at: "@", limit: 3
    expect(controller.setting.limit).toBe(3)

  it "update callbacks", ->
    filter = jasmine.createSpy("custom filter")
    spyOn(callbacks, "filter")
    $inputor.atwho
      at: "@"
      callbacks:
        filter: filter

    triggerAtwhoAt $inputor
    expect(filter).toHaveBeenCalled()
    expect(callbacks.filter).not.toHaveBeenCalled()

  it "setting timeout", ->
    jasmine.clock().install()
    $inputor.atwho
      at: "@"
      display_timeout: 500

    simulateTypingIn $inputor
    $inputor.trigger "blur"
    view = controller.view.$el

    expect(view).not.toBeHidden()
    jasmine.clock().tick 503
    expect(view).toBeHidden()
    jasmine.clock().uninstall()

  it "escape RegExp flag", ->
    $inputor = $('#inputor2').atwho
      at: "$"
      data: fixtures["names"]

    controller = $inputor.data('atwho').set_context_for("$").controller()
    simulateTypingIn $inputor, "$"
    expect(controller.view.visible()).toBe true

  it "can be trigger with no space", ->
    $inputor = $('#inputor3').atwho
      at: "@"
      data: fixtures["names"]
      start_with_space: no

    controller = $inputor.data('atwho').set_context_for("@").controller()
    simulateTypingIn $inputor
    expect(controller.view.visible()).toBe true


  describe "`data` as url and load remote data", ->

    beforeEach ->
      jasmine.Ajax.install()
      controller = app.controller()
      controller.model.save null
      $inputor.atwho
        at: "@"
        data: "/atwho.json"

    it "data should be empty at first", ->
      expect(controller.model.fetch().length).toBe 0

    it "should load data after focus inputor", ->
      simulateTypingIn $inputor

      request = jasmine.Ajax.requests.mostRecent()
      response_data = [{"name":"Jacob"}, {"name":"Joshua"}, {"name":"Jayden"}]
      request.response
        status: 200
        responseText: JSON.stringify(response_data)

      expect(controller.model.fetch().length).toBe 3
