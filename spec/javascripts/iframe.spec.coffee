describe "iframe editor", ->
	$inputor = null
	app = null

	beforeEach ->
    loadFixtures "inputors.html"
    ifr = $('#iframeInput')[0]
    ifrBody = ifr.contentDocument.body
    ifrBody.contentEditable = true
    ifrBody.id = 'ifrBody'
    ifrBody.innerHTML = 'Stay Foolish, Stay Hungry. @Jobs'
    $inputor = $(ifrBody).atwho at: "@", data: ['Jobs']
    app = getAppOf $inputor

  it "can insert content", ->
    triggerAtwhoAt $inputor
    expect($inputor.text()).toContain('@Jobs')

  it "insert by click", ->
    simulateTypingIn $inputor
    app.controller().view.$el.find('ul').children().first().trigger('click')
    expect($inputor.text()).toContain('@Jobs')
