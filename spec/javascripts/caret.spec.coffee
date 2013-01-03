describe "jquery.caret", ->

  $inputor = null

  beforeEach ->
    loadFixtures("inputors.html")
    $inputor = $("#inputor")

  it "was defined", ->
    expect($.fn.caretPos).toBeDefined()

  it "work", ->
    $inputor.caretPos(5)
    expect($inputor.caretPos()).toBe(5)
