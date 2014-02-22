describe "content editable", ->
	$inputor = null
	app = null

	beforeEach ->
		loadFixtures "inputors.html"
		$inputor = $("#editable").atwho(at: "@", data: ["Jobs"])
		app = getAppOf $inputor

	it "can insert content", ->
		triggerAtwhoAt $inputor
		expect($inputor.text()).toContain('@Jobs')

	it "insert by click", ->
		simulateTypingIn $inputor
		$inputor.blur()
		app.controller().view.$el.find('ul').children().first().trigger('click')
		expect($inputor.text()).toContain('@Jobs')
