/* 
    Implement Twitter/Weibo @ mentions

    Copyright (C) 2012 @chord.luo

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
(function($) {
    function getCaretPos($inputor) {
        $inputor.focus();
        inputor = $inputor.get(0);
        if ("selection" in document) {
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
    function setCaretPos($inputor, pos) {
        el = $inputor.get(0);
        if ("selection" in document) {
            range = el.createTextRange();
            range.move('character',pos);
            range.select();
        } else 
            el.setSelectionRange(pos,pos);
    }
    $.fn.caretPos = function(pos) {
        if (pos) {
            return setCaretPos(this,pos);
        } else {
            return getCaretPos(this);
        }
    }
})(jQuery);
