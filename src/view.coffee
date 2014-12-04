# View class to control how At.js's view showing.
# All classes share the same DOM view.
class View

  # @param controller [Object] The Controller.
  constructor: (@context) ->
    @$el = $("<div class='atwho-view'><ul class='atwho-view-ul'></ul></div>")
    @timeout_id = null
    # create HTML DOM of list view if it does not exist
    @context.$el.append(@$el)
    this.bind_event()

  init: ->
    id = @context.get_opt("alias") || @context.at.charCodeAt(0)
    @$el.attr('id': "at-view-#{id}")

  destroy: ->
    @$el.remove()

  bind_event: ->
    $menu = @$el.find('ul')
    $menu.on 'mouseenter.atwho-view','li', (e) ->
      $menu.find('.cur').removeClass 'cur'
      $(e.currentTarget).addClass 'cur'
    .on 'click.atwho-view', 'li', (e) =>
      $menu.find('.cur').removeClass 'cur'
      $(e.currentTarget).addClass 'cur'
      this.choose(e)
      e.preventDefault()

  # Check if view is visible
  #
  # @return [Boolean]
  visible: ->
    @$el.is(":visible")

  choose: (e) ->
    if ($li = @$el.find ".cur").length
      content = @context.insert_content_for $li
      @context.insert @context.callbacks("before_insert").call(@context, content, $li), $li
      @context.trigger "inserted", [$li, e]
      this.hide(e)
    @stop_showing = yes if @context.get_opt("hide_without_suffix")

  reposition: (rect) ->
    _window = if @context.app.iframeStandalone then @context.app.window else window
    if rect.bottom + @$el.height() - $(_window).scrollTop() > $(_window).height()
        rect.bottom = rect.top - @$el.height()
    if rect.left > overflowOffset = $(_window).width() - @$el.width() - 5
        rect.left = overflowOffset
    offset = {left:rect.left, top:rect.bottom}
    @context.callbacks("before_reposition")?.call(@context, offset)
    @$el.offset offset
    @context.trigger "reposition", [offset]

  next: ->
    cur = @$el.find('.cur').removeClass('cur')
    next = cur.next()
    next = @$el.find('li:first') if not next.length
    next.addClass 'cur'
    @$el.animate {
      scrollTop: Math.max 0, cur.innerHeight() * (next.index() + 2) - @$el.height()
      }, 150

  prev: ->
    cur = @$el.find('.cur').removeClass('cur')
    prev = cur.prev()
    prev = @$el.find('li:last') if not prev.length
    prev.addClass 'cur'
    @$el.animate {
      scrollTop: Math.max 0, cur.innerHeight() * (prev.index() + 2) - @$el.height()
      }, 150

  show: ->
    if @stop_showing
      @stop_showing = false
      return
    @context.mark_range()
    if not this.visible()
      @$el.show()
      @$el.scrollTop 0
      @context.trigger 'shown'
    this.reposition(rect) if rect = @context.rect()

  hide: (e, time) ->
    return if not this.visible()
    if isNaN(time)
      @context.reset_rect()
      @$el.hide()
      @context.trigger 'hidden', [e]
    else
      callback = => this.hide()
      clearTimeout @timeout_id
      @timeout_id = setTimeout callback, time

  # render list view
  render: (list) ->
    if not ($.isArray(list) and list.length > 0)
      this.hide()
      return

    @$el.find('ul').empty()
    $ul = @$el.find('ul')
    tpl = @context.get_opt('tpl')

    for item in list
      item = $.extend {}, item, {'atwho-at': @context.at}
      li = @context.callbacks("tpl_eval").call(@context, tpl, item)
      $li = $ @context.callbacks("highlighter").call(@context, li, @context.query.text)
      $li.data("item-data", item)
      $ul.append $li

    this.show()
    $ul.find("li:first").addClass "cur" if @context.get_opt('highlight_first')
