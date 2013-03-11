describe "jquery.atwho", ->

  $inputor = null
  fixtures = null

  KEY_CODE =
    DOWN: 40
    UP: 38
    ESC: 27
    TAB: 9
    ENTER: 13

  trigger_atwho = ->
    simulate_input()
    simulate_choose()

  simulate_input = ->
    $inputor.data("atwho").current_flag = "@"
    $inputor.caretPos(31)
    $inputor.trigger("keyup")

  simulate_choose = ->
    e = $.Event("keydown", keyCode: KEY_CODE.ENTER)
    $inputor.trigger(e)

  it "should be defined", ->
    expect($.fn.atwho).toBeDefined()

  beforeEach ->
    loadFixtures("inputors.html")
    fixtures = loadJSONFixtures("data.json")["data.json"]
    $inputor = $("#inputor").atwho "@",
      data: fixtures["names"]

  describe "default callbacks", ->
    callbacks = null
    controller = null
    text = null

    beforeEach ->
      text = $.trim $inputor.text()
      callbacks = $.fn.atwho.default.callbacks
      controller = $inputor.data("atwho")

    it "refactor the data", ->
      items = callbacks.data_refactor.call(controller, fixtures["names"])
      expect(items).toContain({"name":"Jacob"})
      expect(items).toContain({"name":"Isabella"})

    it "should match the key word following @", ->
      query = callbacks.matcher.call(controller, "@", text)
      expect(query).toBe("Jobs")

    it "filter the data without data_refactor", ->
      items = callbacks.filter.call(controller, "jo", fixtures["names"])
      expect(items).toContain("Joshua")

    it "filter data after data_refactor", ->
      names = callbacks.data_refactor.call(controller, fixtures["names"])
      names = callbacks.filter.call(controller, "jo", fixtures["names"])
      expect(names).toContain("Joshua")

    it "request data from remote by ajax", ->
      jasmine.Ajax.useMock()

      render_callback = jasmine.createSpy("render_view")
      callbacks.remote_filter({}, "/", render_callback)

      request = mostRecentAjaxRequest()
      # response_data = ["Jacob", "Joshua", "Jayden"]
      response_data = [{"name":"Jacob"}, {"name":"Joshua"}, {"name":"Jayden"}]
      request.response
        status: 200
        responseText: JSON.stringify(response_data)

      expect(render_callback).toHaveBeenCalled()
      names = render_callback.mostRecentCall.args[0]
      expect(names).toContain({"name":'Jacob'})

    it "can sort the data", ->
      names = callbacks.data_refactor.call(controller, fixtures["names"])
      names = callbacks.sorter.call(controller, "e", names, "name")
      expect(names).toContain({ name : 'Ethan', order : 0 })

    it "can sort the data without a query", ->
      names = callbacks.data_refactor.call(controller, fixtures["names"])
      names = callbacks.sorter.call(controller, "", names, "name")
      expect(names[0]).toEqual({ name : 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' })

    it "can eval temple", ->
      map = {name: "username", nick: "nick_name"}
      tpl = '<li data-value="${name}">${nick}</li>'
      html = '<li data-value="username">nick_name</li>'

      result = callbacks.tpl_eval.call(controller, tpl, map)
      expect(result).toBe(html)

    it "can highlight the query", ->
      html = '<li data-value="username">Ethan</li>'
      highlighted = callbacks.highlighter.call(controller, html, "e")
      result = '<li data-value="username"> <strong>E</strong>than </li>'
      expect(highlighted).toBe(result)

    it "can insert the text which be choosed", ->
      spyOn(callbacks, "selector").andCallThrough()

      trigger_atwho()
      expect(callbacks.selector).toHaveBeenCalled()
      # expect(controller.$inputor).toHaveText("Jacob")

  describe "settings", ->
    controller = null
    callbacks = null
    beforeEach ->
      controller = $inputor.data("atwho")
      callbacks = $.fn.atwho.default.callbacks

    it "update common settings", ->
      $inputor.atwho limit: 8
      expect(controller.common_settings.limit).toBe(8)

    it "update specific settings", ->
      $inputor.atwho "@", limit: 3
      expect(controller.settings["@"].limit).toBe(3)

    it "update callbacks", ->
      filter = jasmine.createSpy("filter")
      spyOn(callbacks, "filter")
      $inputor.atwho "@",
        callbacks:
          filter: filter

      trigger_atwho()
      expect(filter).toHaveBeenCalled()
      expect(callbacks.filter).not.toHaveBeenCalled()

    it "setting data as url", ->
      jasmine.Ajax.useMock()
      spyOn(callbacks, "remote_filter")

      $inputor.atwho "@", data: "/"
      trigger_atwho()

      mostRecentAjaxRequest().response status: 200

      expect(callbacks.remote_filter).toHaveBeenCalled()

    it "setting timeout", ->
      jasmine.Clock.useMock()
      $inputor.atwho display_timeout: 500

      simulate_input()
      $inputor.trigger "blur"
      jasmine.Clock.tick 503
      view = controller.view.$el
      expect(view).toBeHidden()


  describe "jquery events", ->
    controller = null
    callbacks = null
    beforeEach ->
      controller = $inputor.data("atwho")
      callbacks = $.fn.atwho.default.callbacks
      simulate_input()

    it "trigger esc", ->
      esc_event = $.Event("keyup.atwho", keyCode: KEY_CODE.ESC)
      $inputor.trigger(esc_event)
      expect(controller.view.visible()).toBe(false)

    it "trigger tab", ->
      spyOn(callbacks, "selector").andCallThrough()
      tab_event = $.Event("keydown.atwho", keyCode: KEY_CODE.TAB)
      $inputor.trigger(tab_event)
      expect(controller.view.visible()).toBe(false)
      expect(callbacks.selector).toHaveBeenCalled()

    it "trigger enter", ->
      spyOn(callbacks, "selector").andCallThrough()
      enter_event = $.Event("keydown.atwho", keyCode: KEY_CODE.ENTER)
      $inputor.trigger(enter_event)
      expect(callbacks.selector).toHaveBeenCalled()

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

    it "trigger choose", ->
      choose_event = spyOnEvent($inputor, "choose.atwho")
      trigger_atwho()
      expect(choose_event).toHaveBeenTriggered()

    it "trigger reposition", ->
      reposition_event = spyOnEvent($inputor, "reposition.atwho")
      trigger_atwho()
      expect(reposition_event).toHaveBeenTriggered()
