describe "jquery.atWho", ->

  callbacks = null

  beforeEach ->
    loadFixtures("inputors.html")
    $inputor = $("#inputor")

    names = loadJSONFixture("names.json")
    emojis = loadJSONFixture("emojis.json")
    text = $inputor.text()

    callbacks = $.fn.atWho.default.callbacks
    controller = new $.fn.atWho.Controller($inputor)

  describe "default callbacks", ->

    it "should match the key word following @", ->
      callbacks.matcher.call(controller, "@", text)

  #   it "filter the data", ->
  #     callbacks.filter.call(controller, "jo", "name")


  # describe "Mirror", ->
  #   it "TODO", ->
  #     expect(true).not.toBe(false)
