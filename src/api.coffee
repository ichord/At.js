Api =
  # load a flag's data
  #
  # @params at[String] the flag
  # @params data [Array] data to storage.
  load: (at, data) -> c.model.load data if c = this.controller(at)
  setIframe: (iframe, standalone) -> this.setIframe(iframe, standalone); null;
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
  tpl: "<li>${name}</li>"
  insert_tpl: "${atwho-at}${name}"
  callbacks: DEFAULT_CALLBACKS
  search_key: "name"
  suffix: undefined
  hide_without_suffix: no
  start_with_space: yes
  highlight_first: yes
  limit: 5
  max_len: 20
  display_timeout: 300
  delay: null
