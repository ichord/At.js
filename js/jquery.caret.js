
/*
   Implement Twitter/Weibo @ mentions

   Copyright (c) 2012 chord.luo@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   "Software"), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
   OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
   WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
本插件操作 textarea 或者 input 内的插入符
只实现了获得插入符在文本框中的位置，我设置
插入符的位置.
*/

(function() {

  (function($) {
    var getCaretPos, setCaretPos;
    getCaretPos = function(inputor) {
      var end, endRange, len, normalizedValue, pos, range, start, textInputRange;
      if (document.selection) {
        /*
                    #assume we select "HATE" in the inputor such as textarea -> { }.
                     *               start end-point.
                     *              /
                     * <  I really [HATE] IE   > between the brackets is the selection range.
                     *                   \
                     *                    end end-point.
        */
        range = document.selection.createRange();
        pos = 0;
        if (range && range.parentElement() === inputor) {
          normalizedValue = inputor.value.replace(/\r\n/g, "\n");
          /* SOMETIME !!! 
           "/r/n" is counted as two char.
            one line is two, two will be four. balalala.
            so we have to using the normalized one's length.;
          */
          len = normalizedValue.length;
          /*
                             <[  I really HATE IE   ]>:
                              the whole content in the inputor will be the textInputRange.
          */
          textInputRange = inputor.createTextRange();
          /*                 _here must be the position of bookmark.
                           /
             <[  I really [HATE] IE   ]>
              [---------->[           ] : this is what moveToBookmark do.
             <   I really [[HATE] IE   ]> : here is result.
                            \ two brackets in should be in line.
          */
          textInputRange.moveToBookmark(range.getBookmark());
          endRange = inputor.createTextRange();
          /*  [--------------------->[] : if set false all end-point goto end.
            <  I really [[HATE] IE  []]>
          */
          endRange.collapse(false);
          /*
                                          ___VS____
                                         /         \
                           <   I really [[HATE] IE []]>
                                                    \_endRange end-point.
                          
                          " > -1" mean the start end-point will be the same or right to the end end-point
                         * simplelly, all in the end.
          */
          if (textInputRange.compareEndPoints("StartToEnd", endRange) > -1) {
            start = end = len;
          } else {
            /*
                                        I really |HATE] IE   ]> 
                                               <-|
                                      I really[ [HATE] IE   ]>
                                            <-[
                                    I reall[y  [HATE] IE   ]>
                                 
                                  will return how many unit have moved.
            */
            start = -textInputRange.moveStart("character", -len);
            end = -textInputRange.moveEnd("character", -len);
          }
        }
      } else {
        start = inputor.selectionStart;
      }
      return start;
    };
    setCaretPos = function(inputor, pos) {
      var range;
      if (document.selection) {
        range = inputor.createTextRange();
        range.move("character", pos);
        return range.select();
      } else {
        return inputor.setSelectionRange(pos, pos);
      }
    };
    return $.fn.caretPos = function(pos) {
      var inputor;
      inputor = this[0];
      inputor.focus();
      if (pos) {
        return setCaretPos(inputor, pos);
      } else {
        return getCaretPos(inputor);
      }
    };
  })(window.jQuery);

}).call(this);
