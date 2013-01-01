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
(($) ->
    getCaretPos = (inputor) ->
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

    setCaretPos = (inputor, pos) ->
      if document.selection #IE
        range = inputor.createTextRange()
        range.move "character", pos
        range.select()
      else
        inputor.setSelectionRange pos, pos

    $.fn.caretPos = (pos) ->
      inputor = this[0]
      inputor.focus()
      if pos
        setCaretPos(inputor, pos)
      else
        getCaretPos(inputor)

)(window.jQuery)
