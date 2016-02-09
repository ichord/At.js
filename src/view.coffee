# View class to control how At.js's view showing.
# All classes share the same DOM view.
class View

  # @param controller [Object] The Controller.
  constructor: (@context) ->
    @$el = $("<div class='atwho-view'><ul class='atwho-view-ul'></ul></div>")
    @$elUl = @$el.children();
    @timeoutID = null
    # create HTML DOM of list view if it does not exist
    @context.$el.append(@$el)

  init: ->
    id = @context.getOpt("alias") || @context.at.charCodeAt(0)
    header_tpl = this.context.getOpt("headerTpl")
    if (header_tpl && this.$el.children().length == 1)
      this.$el.prepend(header_tpl)
    this.bindEvent()
    this.$el.addClass this.context.getOpt("classDivContainer")
    this.$el.find('ul').addClass this.context.getOpt("classUlContainer")
    @$el.attr('id': "at-view-#{id}")

  destroy: ->
    @$el.remove()

  bindEvent: ->
    $menu = @$el.find('ul')
    lastCoordX = 0
    lastCoordY = 0
    curItem = @context.getOpt('classCurrentItem')
    $menu.on 'mousemove.atwho-view','li', (e) =>
      # If the mouse hasn't actually moved then exit.
      return if lastCoordX == e.clientX and lastCoordY == e.clientY
      lastCoordX = e.clientX
      lastCoordY = e.clientY
      $cur = $(e.currentTarget)
      return if $cur.hasClass(curItem)
      $menu.find('.' + curItem).removeClass curItem
      $cur.addClass curItem
    .on 'click.atwho-view', 'li', (e) =>
      $menu.find('.' + curItem).removeClass curItem
      $(e.currentTarget).addClass curItem
      this.choose(e)
      e.preventDefault()

  # Check if view is visible
  #
  # @return [Boolean]
  visible: ->
    @$el.is(":visible")

  highlighted: ->
    @$el.find("." + @context.getOpt('classCurrentItem')).length > 0

  choose: (e) ->
    if ($li = @$el.find "." + @context.getOpt('classCurrentItem')).length
      content = @context.insertContentFor $li

      @context._stopDelayedCall()
      @context.insert @context.callbacks("beforeInsert").call(@context, content, $li), $li
      @context.trigger "inserted", [$li, e]
      this.hide(e)
    @stopShowing = yes if @context.getOpt("hideWithoutSuffix")

  reposition: (rect) ->
    _window = if @context.app.iframeAsRoot then @context.app.window else window
    if rect.bottom + @$el.height() - $(_window).scrollTop() > $(_window).height()
      rect.bottom = rect.top - @$el.height()
    if rect.left > overflowOffset = $(_window).width() - @$el.width() - 5
      rect.left = overflowOffset
    offset = {left:rect.left, top:rect.bottom}
    @context.callbacks("beforeReposition")?.call(@context, offset)
    @$el.offset offset
    @context.trigger "reposition", [offset]

  next: ->
    curItem = @context.getOpt('classCurrentItem')
    cur = @$el.find('.' + curItem).removeClass(curItem)
    next = cur.next()
    next = @$el.find('li:first') if not next.length
    next.addClass curItem
    nextEl = next[0]
    offset = nextEl.offsetTop + nextEl.offsetHeight + (if nextEl.nextSibling then nextEl.nextSibling.offsetHeight else 0)
    @scrollTop Math.max(0, offset - this.$el.height())

  prev: ->
    curItem = @context.getOpt('classCurrentItem')
    cur = @$el.find('.' + curItem).removeClass(curItem)
    prev = cur.prev()
    prev = @$el.find('li:last') if not prev.length
    prev.addClass curItem
    prevEl = prev[0]
    offset = prevEl.offsetTop + prevEl.offsetHeight + (if prevEl.nextSibling then prevEl.nextSibling.offsetHeight else 0)
    @scrollTop Math.max(0, offset - this.$el.height())

  scrollTop: (scrollTop) ->
    scrollDuration = @context.getOpt('scrollDuration')
    if scrollDuration
      @$elUl.animate {scrollTop: scrollTop}, scrollDuration
    else
      @$elUl.scrollTop(scrollTop)

  show: ->
    if @stopShowing
      @stopShowing = false
      return
    if not this.visible()
      @$el.show()
      @$el.scrollTop 0
      @context.trigger 'shown'
    this.reposition(rect) if rect = @context.rect()

  hide: (e, time) ->
    return if not this.visible()
    if isNaN(time)
      @$el.hide()
      @context.trigger 'hidden', [e]
    else
      callback = => this.hide()
      clearTimeout @timeoutID
      @timeoutID = setTimeout callback, time

  # render list view
  render: (list) ->
    if not ($.isArray(list) and list.length > 0)
      this.hide()
      return

    @$el.find('ul').empty()
    $ul = @$el.find('ul')
    tpl = @context.getOpt('displayTpl')

    for item in list
      item = $.extend {}, item, {'atwho-at': @context.at}
      li = @context.callbacks("tplEval").call(@context, tpl, item, "onDisplay")
      $li = $ @context.callbacks("highlighter").call(@context, li, @context.query.text)
      $li.data("item-data", item)
      $ul.append $li

    this.show()
    $ul.find("li:first").addClass @context.getOpt('classCurrentItem') if @context.getOpt('highlightFirst')
