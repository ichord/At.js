class EditableController extends Controller

  _getRange: ->
    sel = @app.window.getSelection()
    sel.getRangeAt(0) if sel.rangeCount > 0

  _setRangeEndAfter: (node, range=@_getRange()) ->
    sel = @app.window.getSelection()
    range.setEndAfter $(node)[0]
    range.collapse false
    sel.removeAllRanges()
    sel.addRange range

  catchQuery: (e) ->
    return unless range = @_getRange()
    $(range.startContainer).closest '.atwho-inserted'
      .removeClass 'atwho-inserted'
      .addClass 'atwho-query'

    # matching the `at`
    if ($query = $ ".atwho-query", @app.document).length > 0 \
      and not (e.type is "click" and $(range.startContainer).closest('.atwho-query').length is 0)
        matched = @callbacks("matcher").call(this, @at, $query.text(), @getOpt 'startWithSpace')
    else
      _range = range.cloneRange()
      _range.setStart range.startContainer, 0
      content = _range.toString()
      matched = @callbacks("matcher").call(this, @at, content, @getOpt 'startWithSpace')
      if typeof matched is 'string'
        range.setStart range.startContainer, content.lastIndexOf @at
        range.surroundContents ($query = $ "<span class='atwho-query'/>", @app.document)[0]
        @_setRangeEndAfter $query, range

    # handle the matched result
    if typeof matched is 'string' and matched.length <= @getOpt 'maxLen', 20
      query = text: matched, el: $query
      @trigger "matched", [@at, query.text]
    else
      @view.hide()
      query = null
      if $query.text().indexOf(@at) > -1
        $query.html $query.text()
        if $query.text().indexOf(@at) > -1 and false != @callbacks('afterMatchFailed').call this, @at, $query
          @_setRangeEndAfter $query.html($query.text()).contents().unwrap()
    @query = query

  # Get offset of current at char(`flag`)
  #
  # @return [Hash] the offset which look likes this: {top: y, left: x, bottom: bottom}
  rect: ->
    rect = @query.el.offset()
    if @app.iframe and not @app.iframeStandalone
      iframeOffset = $(@app.iframe).offset()
      rect.left += iframeOffset.left
      rect.top += iframeOffset.top
    rect.bottom = rect.top + @query.el.height()
    rect

  # Insert value of `data-value` attribute of chosen item into inputor
  #
  # @param content [String] string to insert
  insert: (content, $li) ->
    suffix = if suffix = @getOpt 'suffix' then suffix else suffix or "\u00A0" 
    @query.el
      .removeClass 'atwho-query'
      .addClass 'atwho-inserted'
      .html content
    if range = @_getRange()
      range.setEndAfter @query.el[0]
      range.collapse false
      range.insertNode suffixNode = @app.document.createTextNode suffix
      @_setRangeEndAfter suffixNode, range
    @$inputor.focus() unless @$inputor.is ':focus'
    @$inputor.change()
