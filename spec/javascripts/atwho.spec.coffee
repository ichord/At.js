describe "jquery.atWho", ->

  beforeEach ->
    loadFixtures("inputors.html")

  it "should defined jquery", ->
    expect(jQuery).toBeDefined()
    expect($).toBeDefined()
    expect($.fn).toBeDefined()

  it "should be defined", ->
    expect($.fn.atWho).toBeDefined()


  # callbacks = null

  # beforeEach ->
  #   loadFixtures("inputors.html")
  #   $inputor = $("#inputor")

  #   names = loadJSONFixtures("names.json")
  #   emojis = loadJSONFixtures("emojis.json")
  #   text = $inputor.text()

  #   callbacks = $.fn.atWho.default.callbacks
  #   controller = new $.fn.atWho.Controller($inputor)

  # describe "default callbacks", ->

  #   it "should match the key word following @", ->
  #     callbacks.matcher.call(controller, "@", text)

  #   it "filter the data", ->
  #     callbacks.filter.call(controller, "jo", "name")


  # describe "Mirror", ->
  #   it "TODO", ->
  #     expect(true).not.toBe(false)
