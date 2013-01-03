describe "jquery.atWho", ->

  $inputor = null
  fixtures = null

  trigger_atwho = ->
    $inputor.data("AtWho").current_flag = "@"
    $inputor.caretPos(31)
    e = $.Event("keydown.atWho", keyCode: 13)
    $inputor.trigger("keyup.atWho").trigger(e)

  it "should be defined", ->
    expect($.fn.atWho).toBeDefined()

  beforeEach ->
    loadFixtures("inputors.html")
    fixtures = loadJSONFixtures("data.json")["data.json"]
    $inputor = $("#inputor").atWho "@",
      data: fixtures["names"]

  describe "default callbacks", ->
    callbacks = null
    controller = null
    text = null

    beforeEach ->
      text = $.trim $inputor.text()
      callbacks = $.fn.atWho.default.callbacks
      controller = $inputor.data("AtWho")

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
      # FIXME: it work but, the $inputor fixture have be reset back.
      # expect(controller.$inputor).toHaveText(/Jacob/)

  describe "settings", ->
    controller = null
    callbacks = null
    beforeEach ->
      controller = $inputor.data("AtWho")
      callbacks = $.fn.atWho.default.callbacks

    it "update common settings", ->
      $inputor.atWho limit: 8
      expect(controller.common_settings.limit).toBe(8)

    it "update specific settings", ->
      $inputor.atWho "@", limit: 3
      expect(controller.settings["@"].limit).toBe(3)

    it "update callbacks", ->
      filter = jasmine.createSpy("filter")
      spyOn(callbacks, "filter")
      $inputor.atWho "@",
        callbacks:
          filter: filter

      trigger_atwho()
      expect(filter).toHaveBeenCalled()
      expect(callbacks.filter).not.toHaveBeenCalled()

    it "setting data as url", ->
      jasmine.Ajax.useMock()
      spyOn(callbacks, "remote_filter")

      $inputor.atWho "@", data: "/"
      trigger_atwho()

      mostRecentAjaxRequest().response status: 200

      expect(callbacks.remote_filter).toHaveBeenCalled()


  describe "events", ->
    it "trigger esc", ->

    it "trigger up", ->

    it "trigger down", ->

    it "trigger tab or enter", ->


