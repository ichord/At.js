describe "jquery.caret", ->

  $inputor = null

  beforeEach ->
    loadFixtures("inputors.html")
    $inputor = $("#inputor")

  it "was defined", ->
    expect($.fn.caret).toBeDefined()

  it "work", ->
    $inputor.caret('pos', 5)
    expect($inputor.caret('pos')).toBe(5)
