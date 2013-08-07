###
  Implement Github like autocomplete mentions
  http://ichord.github.com/At.js

  Copyright (c) 2013 chord.luo@gmail.com
  Licensed under the MIT license.
###

###
本插件操作 textarea 或者 input 内的插入符
只实现了获得插入符在文本框中的位置，我设置
插入符的位置.
###
( (factory) ->
  # Uses AMD or browser globals to create a jQuery plugin.
  # It does not try to register in a CommonJS environment since
  # jQuery is not likely to run in those environments.
  #
  # form [umd](https://github.com/umdjs/umd) project
  if typeof define is 'function' and define.amd
    # Register as an anonymous AMD module:
    define ['jquery'], factory
  else
    # Browser globals
    factory window.jQuery
) ($) ->

  "use strict";

  pluginName = 'caret'

  class Caret

    constructor: (@$inputor) ->
      @domInputor = @$inputor[0]

    getPos: ->
      inputor = @domInputor
      inputor.focus()

      if document.selection #IE
        # reference: http://tinyurl.com/86pyc4s

        ###
        #assume we select "HATE" in the inputor such as textarea -> { }.
         *               start end-point.
         *              /
         * <  I really [HATE] IE   > between the brackets is the selection range.
         *                   \
         *                    end end-point.
         ###

        range = document.selection.createRange()
        pos = 0
        # selection should in the inputor.
        if range and range.parentElement() is inputor
          normalizedValue = inputor.value.replace /\r\n/g, "\n"
          ### SOMETIME !!!
           "/r/n" is counted as two char.
            one line is two, two will be four. balalala.
            so we have to using the normalized one's length.;
          ###
          len = normalizedValue.length
          ###
             <[  I really HATE IE   ]>:
              the whole content in the inputor will be the textInputRange.
          ###
          textInputRange = inputor.createTextRange()
          ###                 _here must be the position of bookmark.
                           /
             <[  I really [HATE] IE   ]>
              [---------->[           ] : this is what moveToBookmark do.
             <   I really [[HATE] IE   ]> : here is result.
                            \ two brackets in should be in line.
          ###
          textInputRange.moveToBookmark range.getBookmark()
          endRange = inputor.createTextRange()
          ###  [--------------------->[] : if set false all end-point goto end.
            <  I really [[HATE] IE  []]>
          ###
          endRange.collapse false
          ###
                          ___VS____
                         /         \
           <   I really [[HATE] IE []]>
                                    \_endRange end-point.

          " > -1" mean the start end-point will be the same or right to the end end-point
         * simplelly, all in the end.
          ####
          if textInputRange.compareEndPoints("StartToEnd", endRange) > -1
            #TextRange object will miss "\r\n". So, we count it ourself.
            start = end = len
          else
            ###
                    I really |HATE] IE   ]>
                           <-|
                  I really[ [HATE] IE   ]>
                        <-[
                I reall[y  [HATE] IE   ]>

              will return how many unit have moved.
            ###
            start = -textInputRange.moveStart "character", -len
            end = -textInputRange.moveEnd "character", -len

      else
        start = inputor.selectionStart
      return start

    setPos: (pos) ->
      inputor = @domInputor
      if document.selection #IE
        range = inputor.createTextRange()
        range.move "character", pos
        range.select()
      else
        inputor.setSelectionRange pos, pos

    getPosition: (pos)->
      $inputor = @$inputor
      format = (value) ->
        value.replace(/</g, '&lt')
        .replace(/>/g, '&gt')
        .replace(/`/g,'&#96')
        .replace(/"/g,'&quot')
        .replace(/\r\n|\r|\n/g,"<br />")

      pos = this.getPos() if pos is undefined
      start_range = $inputor.val().slice(0, pos)
      html = "<span>"+format(start_range)+"</span>"
      html += "<span id='caret'>|</span>"

      mirror = new Mirror($inputor)
      at_rect = mirror.create(html).rect()

      x = at_rect.left - $inputor.scrollLeft()
      y = at_rect.top - $inputor.scrollTop()
      h = at_rect.height

      {left: x, top: y, height: h}

    getOffset: (pos) ->
      $inputor = @$inputor
      if document.selection # for IE full
        range = @domInputor.createTextRange()
        range.move('character', pos) if pos
        x = range.boundingLeft + $inputor.scrollLeft()
        y = range.boundingTop + $(window).scrollTop() + $inputor.scrollTop()
        h = range.boundingHeight
      else
        offset = $inputor.offset()
        position = this.getPosition(pos)

        x = offset.left + position.left
        y = offset.top + position.top
        h = position.height

      {left: x, top: y, height: h}


  # @example
  #   mirror = new Mirror($("textarea#inputor"))
  #   html = "<p>We will get the rect of <span>@</span>icho</p>"
  #   mirror.create(html).rect()
  class Mirror
    css_attr: [
      "overflowY", "height", "width", "paddingTop", "paddingLeft",
      "paddingRight", "paddingBottom", "marginTop", "marginLeft",
      "marginRight", "marginBottom","fontFamily", "borderStyle",
      "borderWidth","wordWrap", "fontSize", "lineHeight", "overflowX",
      "text-align",
    ]

    constructor: (@$inputor) ->

    mirrorCss: ->
      css =
        position: 'absolute'
        left: -9999
        top:0
        zIndex: -20000
        'white-space': 'pre-wrap'
      $.each @css_attr, (i,p) =>
        css[p] = @$inputor.css p
      css

    create: (html) ->
      @$mirror = $('<div></div>')
      @$mirror.css this.mirrorCss()
      @$mirror.html(html)
      @$inputor.after(@$mirror)
      this

    # 获得标记的位置
    #
    # @return [Object] 标记的坐标
    #   {left: 0, top: 0, bottom: 0}
    rect: ->
      $flag = @$mirror.find "#caret"
      pos = $flag.position()
      rect = {left: pos.left, top: pos.top, height: $flag.height() }
      @$mirror.remove()
      rect


  methods =
    pos: (pos) ->
      if pos
        this.setPos pos
      else
        this.getPos()

    position: (pos) ->
      this.getPosition pos

    offset: (pos) ->
      this.getOffset pos


  $.fn.caret = (method) ->
    caret = new Caret this

    if methods[method]
      methods[method].apply caret, Array::slice.call(arguments, 1)
    else
      $.error "Method #{method} does not exist on jQuery.caret"



