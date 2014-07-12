Api =
  # load a flag's data
  #
  # @params at[String] the flag
  # @params data [Array] data to storage.
  load: (at, data) -> c.model.load data if c = this.controller(at)

  getInsertedItemsWithIDs: (at) ->
    return [null, null] unless c = this.controller at
    at = "-#{c.get_opt('alias') || c.at}" if at
    ids = []
    items = $.map @$inputor.find("span.atwho-view-flag#{at || ""}"), (item) ->
      data = $(item).data('atwho-data-item')
      return if ids.indexOf(data.id) > -1
      ids.push = data.id if data.id
      data
    [ids, items]
  getInsertedItems: (at) -> Api.getInsertedItemsWithIDs.apply(this, [at])[1]
  getInsertedIDs: (at) -> Api.getInsertedItemsWithIDs.apply(this, [at])[0]
  setIframe: (iframe) -> this.setIframe(iframe); null;

  run: -> this.dispatch()
  destroy: ->
    this.shutdown()
    @$inputor.data('atwho', null)

$CONTAINER = $("<div id='atwho-container'></div>")

$.fn.atwho = (method) ->
  _args = arguments
  $('body').append($CONTAINER)
  result = null
  this.filter('textarea, input, [contenteditable=true]').each ->
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
  space_after: true
  data: null
  tpl: "<li data-value='${atwho-at}${name}'>${name}</li>"
  insert_tpl: "<span>${atwho-data-value}</span>"
  callbacks: DEFAULT_CALLBACKS
  search_key: "name"
  start_with_space: yes
  highlight_first: yes
  limit: 5
  max_len: 20
  display_timeout: 300
  delay: null
