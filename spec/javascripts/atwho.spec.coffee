describe "jquery.atWho", ->

  callbacks = null
  controller = null
  text = null
  fixtures = null

  beforeEach ->
    loadFixtures("inputors.html")
    $inputor = $("#inputor")

    fixtures = loadJSONFixtures("data.json")["data.json"]
    text = $.trim $inputor.text()

    callbacks = $.fn.atWho.default.callbacks
    controller = new $.fn.atWho.Controller($inputor)

  it "should be defined", ->
    expect($.fn.atWho).toBeDefined()

  describe "default callbacks work", ->

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

    it "can evl temple", ->
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

    # it "can insert the text which be choosed", ->

  describe "Mirror", ->
    it "TODO", ->
      expect(true).not.toBe(false)
