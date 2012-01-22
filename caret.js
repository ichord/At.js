/* 
    Implement Twitter/Weibo @ mentions

    Copyright (C) 2012 chord.luo@gmail.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

/* 本插件操作 textarea 或者 input 内的插入符
 * 只实现了获得插入符在文本框中的位置，我设置
 * 插入符的位置.
 * */
(function($) {
    function getCaretPos(inputor) {
        if ("selection" in document) { // IE
            range = inputor.createTextRange();
            sel_range = document.selection.createTextRange().duplicate();
            try {
                range.setEndPoint("EndToStart",sel_range);
            } catch (e) {
                return 0;
            }
            pos = range.text.length
        } else {
            pos = inputor.selectionStart;
        }
        return pos;
    }
    function setCaretPos(inputor, pos) {
        if ("selection" in document) { //IE
            range = inputor.createTextRange();
            range.move('character',pos);
            range.select();
        } else 
            inputor.setSelectionRange(pos,pos);
    }
    $.fn.caretPos = function(pos) {
        inputor = this.get(0);
        if (pos) {
            return setCaretPos(inputor,pos);
        } else {
            return getCaretPos(inputor);
        }
    }
})(jQuery);
 /*  */
