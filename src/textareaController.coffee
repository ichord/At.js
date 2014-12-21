class TextareaController extends Controller
  # Catch query string behind the at char
  #
  # @return [Hash] Info of the query. Look likes this: {'text': "hello", 'head_pos': 0, 'end_pos': 0}
  catch_query: ->
    content = @$inputor.val()
    caret_pos = @$inputor.caret('pos', {iframe: @app.iframe})
    subtext = content.slice(0, caret_pos)
    query = this.callbacks("matcher").call(this, @at, subtext, this.get_opt('start_with_space'))
    if typeof query is "string" and query.length <= this.get_opt('max_len', 20)
      start = caret_pos - query.length
      end = start + query.length
      @pos = start
      query = {'text': query, 'head_pos': start, 'end_pos': end}
      this.trigger "matched", [@at, query.text]
    else
      query = null
      @view.hide()

    @query = query

  # Get offset of current at char(`flag`)
  #
  # @return [Hash] the offset which look likes this: {top: y, left: x, bottom: bottom}
  rect: ->
    return if not c = @$inputor.caret('offset', @pos - 1, {iframe: @app.iframe})
    if @app.iframe and not @app.iframeStandalone
      iframe_offset = $(@app.iframe).offset()
      c.left += iframe_offset.left
      c.top += iframe_offset.top
    scale_bottom = if @app.document.selection then 0 else 2
    {left: c.left, top: c.top, bottom: c.top + c.height + scale_bottom}

  # Insert value of `data-value` attribute of chosen item into inputor
  #
  # @param content [String] string to insert
  insert: (content, $li) ->
    $inputor = @$inputor
    source = $inputor.val()
    start_str = source.slice 0, Math.max(@query.head_pos - @at.length, 0)
    suffix = if (suffix = @get_opt 'suffix') == "" then suffix else suffix or " " 
    content += suffix
    text = "#{start_str}#{content}#{source.slice @query['end_pos'] || 0}"
    $inputor.val text
    $inputor.caret('pos', start_str.length + content.length, {iframe: @app.iframe})
    $inputor.focus() unless $inputor.is ':focus'
    $inputor.change()
