describe "jquery.atwho", ->

  $inputor = null
  fixtures = null
  app = null

  KEY_CODE =
    DOWN: 40
    UP: 38
    ESC: 27
    TAB: 9
    ENTER: 13

  trigger_atwho = ->
    simulate_input()
    simulate_choose()

  simulate_input = (flag) ->
    $inputor.data("atwho").set_context_for flag || "@"
    $inputor.caret('pos', 31)
    $inputor.trigger("keyup")

  simulate_choose = ->
    e = $.Event("keydown", keyCode: KEY_CODE.ENTER)
    $inputor.trigger(e)

  it "should be defined", ->
    expect($.fn.atwho).toBeDefined()

  beforeEach ->
    loadFixtures("inputors.html")
    fixtures = loadJSONFixtures("data.json")["data.json"]
    $inputor = $("#inputor").atwho
      at: "@"
      data: fixtures["names"]
    app = $inputor.data('atwho').set_context_for("@")

  describe "default callbacks", ->
    callbacks = null
    app = null
    text = null

    beforeEach ->
      text = $.trim $inputor.text()
      callbacks = $.fn.atwho.default.callbacks
      app = $inputor.data("atwho")

    it "refactor the data before save", ->
      items = callbacks.before_save.call(app, fixtures["names"])
      expect(items).toContain({"name":"Jacob"})
      expect(items).toContain({"name":"Isabella"})

    it "should match the key word following @", ->
      query = callbacks.matcher.call(app, "@", text)
      expect(query).toBe("Jobs")

    it "can filter data", ->
      names = callbacks.before_save.call(app, fixtures["names"])
      names = callbacks.filter.call(app, "jo", names, "name")
      expect(names).toContain name: "Joshua"

    it "request data from remote by ajax if set remote_filter", ->
      remote_call = jasmine.createSpy("remote_call")
      $inputor.atwho
        at: "@"
        data: null,
        callbacks:
          remote_filter: remote_call
      simulate_input()
      expect(remote_call).toHaveBeenCalled()

    it "can sort the data", ->
      names = callbacks.before_save.call(app, fixtures["names"])
      names = callbacks.sorter.call(app, "e", names, "name")
      expect(names[0].name).toBe 'Ethan'

    it "don't sort the data without a query", ->
      names = callbacks.before_save.call(app, fixtures["names"])
      names = callbacks.sorter.call(app, "", names, "name")
      expect(names[0]).toEqual({ name : 'Jacob' })

    it "can eval temple", ->
      map = {name: "username", nick: "nick_name"}
      tpl = '<li data-value="${name}">${nick}</li>'
      html = '<li data-value="username">nick_name</li>'

      result = callbacks.tpl_eval.call(app, tpl, map)
      expect(result).toBe(html)

    it "can highlight the query", ->
      html = '<li data-value="username">Ethan</li>'
      highlighted = callbacks.highlighter.call(app, html, "e")
      result = '<li data-value="username"> <strong>E</strong>than </li>'
      expect(highlighted).toBe(result)

    it "can insert the text which be choosed", ->
      spyOn(callbacks, "before_insert").andCallThrough()

      trigger_atwho()
      expect(callbacks.before_insert).toHaveBeenCalled()

  describe "settings", ->
    app = null
    controller = null
    callbacks = null
    beforeEach ->
      app = $inputor.data("atwho").set_context_for("@")
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

      trigger_atwho()
      expect(filter).toHaveBeenCalled()
      expect(callbacks.filter).not.toHaveBeenCalled()

    describe "setting data as url and load remote data", ->
      controller = null

      beforeEach ->
        jasmine.Ajax.useMock()
        controller = app.controller()
        controller.model.save null
        $inputor.atwho
          at: "@"
          data: "/atwho.json"

      it "data should be empty at first", ->
        expect(controller.model.fetch().length).toBe 0

      it "should load data after focus inputor", ->
        simulate_input()

        request = mostRecentAjaxRequest()
        response_data = [{"name":"Jacob"}, {"name":"Joshua"}, {"name":"Jayden"}]
        request.response
          status: 200
          responseText: JSON.stringify(response_data)

        expect(controller.model.fetch().length).toBe 3

    it "setting timeout", ->
      jasmine.Clock.useMock()
      $inputor.atwho
        at: "@"
        display_timeout: 500

      simulate_input()
      $inputor.trigger "blur"
      view = controller.view.$el

      expect(view).not.toBeHidden()
      jasmine.Clock.tick 503
      expect(view).toBeHidden()

    it "escape RegExp flag", ->
      $inputor = $('#inputor2').atwho
        at: "$"
        data: fixtures["names"]

      controller = $inputor.data('atwho').set_context_for("$").controller()
      simulate_input("$")
      expect(controller.view.visible()).toBe true

    it "can be trigger with no space", ->
      $inputor = $('#inputor3').atwho
        at: "@"
        data: fixtures["names"]
        start_with_space: no

      controller = $inputor.data('atwho').set_context_for("@").controller()
      simulate_input()
      expect(controller.view.visible()).toBe true

  describe "jquery events", ->
    controller = null
    callbacks = null

    beforeEach ->
      controller = app.controller()
      callbacks = $.fn.atwho.default.callbacks
      simulate_input()

    it "trigger esc", ->
      esc_event = $.Event("keyup.atwho", keyCode: KEY_CODE.ESC)
      $inputor.trigger(esc_event)
      expect(controller.view.visible()).toBe(false)

    it "trigger tab", ->
      spyOn(callbacks, "before_insert").andCallThrough()
      tab_event = $.Event("keydown.atwho", keyCode: KEY_CODE.TAB)
      $inputor.trigger(tab_event)
      expect(controller.view.visible()).toBe(false)
      expect(callbacks.before_insert).toHaveBeenCalled()

    it "trigger enter", ->
      spyOn(callbacks, "before_insert").andCallThrough()
      enter_event = $.Event("keydown.atwho", keyCode: KEY_CODE.ENTER)
      $inputor.trigger(enter_event)
      expect(callbacks.before_insert).toHaveBeenCalled()

    it "trigger up", ->
      spyOn(controller.view, "prev").andCallThrough()
      up_event = $.Event("keydown.atwho", keyCode: KEY_CODE.UP)
      $inputor.trigger(up_event)
      expect(controller.view.prev).toHaveBeenCalled()

    it "trigger down", ->
      spyOn(controller.view, "next").andCallThrough()
      down_event = $.Event("keydown.atwho", keyCode: KEY_CODE.DOWN)
      $inputor.trigger(down_event)
      expect(controller.view.next).toHaveBeenCalled()

  describe "atwho events", ->

    it "trigger matched", ->
      matched_event = spyOnEvent($inputor, "matched.atwho")
      trigger_atwho()
      expect(matched_event).toHaveBeenTriggered()

    it "trigger inserted", ->
      choose_event = spyOnEvent($inputor, "inserted.atwho")
      trigger_atwho()
      expect(choose_event).toHaveBeenTriggered()

    it "trigger reposition", ->
      reposition_event = spyOnEvent($inputor, "reposition.atwho")
      trigger_atwho()
      expect(reposition_event).toHaveBeenTriggered()

    it "trigger a special matched for @ with alias", ->
      $inputor.atwho
        at: "@"
        alias: "at-memtions"

      event = spyOnEvent($inputor, "matched-at-memtions.atwho")
      trigger_atwho()
      expect(event).toHaveBeenTriggered()


  describe "inner api", ->
    controller = null
    callbacks = null
    beforeEach ->
      controller = app.controller()

    it "can get current data", ->
      simulate_input()
      expect(controller.model.fetch().length).toBe 23

    it "can save current data", ->
      simulate_input()
      data = [{id: 1, name: "one"}, {id: 2, name: "two"}]
      controller.model.save(data)
      expect(controller.model.fetch().length).toBe 2

    it "don't change data setting while using remote filter", ->
      jasmine.Ajax.useMock()
      $inputor.atwho
        at: "@"
        data: "/atwho.json"

      simulate_input()

      request = mostRecentAjaxRequest()
      response_data = [{"name":"Jacob"}, {"name":"Joshua"}, {"name":"Jayden"}]
      request.response
        status: 200
        responseText: JSON.stringify(response_data)

      expect(controller.get_opt("data")).toBe "/atwho.json"
      expect(controller.model.fetch().length).toBe 3

  describe "public api", ->
    controller = null
    data = []

    beforeEach ->
      controller = app.controller()
      data = [
        {one: 1}
        {two: 2}
        {three: 3}
      ]

    it "can load data for special flag", ->
      $inputor.atwho "load", "@", data
      expect(controller.model.fetch().length).toBe data.length

    it "can load data with alias", ->
      $inputor.atwho at: "@", alias: "at"
      $inputor.atwho "load", "at", data
      expect(controller.model.fetch().length).toBe data.length

    it "can run it handly", ->
      app.set_context_for null
      $inputor.caret('pos', 31)
      $inputor.atwho "run"

      expect(app.controller().view.$el).not.toBeHidden()

