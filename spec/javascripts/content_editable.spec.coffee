describe "content editable", ->
	$inputor = null
	app = null

	beforeEach ->
		loadFixtures "inputors.html"
		$inputor = $("#editable").atwho(at: "@", data: ["Jobs"])
		app = getAppOf $inputor
  afterEach ->
    $inputor.atwho 'destroy'

	it "can insert content", ->
		triggerAtwhoAt $inputor
		expect($inputor.text()).toContain('@Jobs')

	it "insert by click", ->
		simulateTypingIn $inputor
		$inputor.blur()
		app.controller().view.$el.find('ul').children().first().trigger('click')
		expect($inputor.text()).toContain('@Jobs')

	it "unwrapp span.atwho-query after match failed", ->
		simulateTypingIn $inputor
		expect $('.atwho-query').length
			.toBe 1
		$('.atwho-query').html "@J "
		simulateTypingIn $inputor, "@", 3
		expect $('.atwho-query').length
			.toBe 0
