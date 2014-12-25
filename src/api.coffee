Api =
  # load a flag's data
  #
  # @params at[String] the flag
  # @params data [Array] data to storage.
  load: (at, data) -> c.model.load data if c = this.controller(at)
  setIframe: (iframe, standalone) -> this.setupRootElement(iframe, standalone); null;
  run: -> this.dispatch()
  destroy: ->
    this.shutdown()
    @$inputor.data('atwho', null)

$.fn.atwho = (method) ->
  _args = arguments
  result = null
  this.filter('textarea, input, [contenteditable=""], [contenteditable=true]').each ->
    if not app = ($this = $ this).data "atwho"
      $this.data 'atwho', (app = new App this)
    if typeof method is 'object' || !method
      app.reg method.at, method
    else if Api[method] and app
      result = Api[method].apply app, Array::slice.call(_args, 1)
    else
      $.error "Method #{method} does not exist on jQuery.caret"
  result || this

$.fn.atwho.default =
  at: undefined
  alias: undefined
  data: null
  displayTpl: "<li>${name}</li>"
  insertTpl: "${atwho-at}${name}"
  callbacks: DEFAULT_CALLBACKS
  searchKey: "name"
  suffix: undefined
  hideWithoutSuffix: no
  startWithSpace: yes
  highlightFirst: yes
  limit: 5
  maxLen: 20
  displayTimeout: 300
  delay: null
