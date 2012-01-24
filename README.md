Implement Twitter/Weibo @ mentions

###todo
* <del>获取 @ 后面关键字并显示列表.</del>
* <del>caret.js: 对文本框内的光标进行操作.</del>
* <del>列表框浮动到 @ 符号下.</del>
* 性能优化
* 浏览器兼容
* 适应输入框大小变化
* caret.js fork
    更多的文本框操作.插入, 替换等.

###todo - en
* <del> get the tail of @: match the key word after @</del>
* <del> caret.js: set or get caret position in textarea or input element</del>
* <del> let mention box dance with the "@"</del>
* Let's dance beautifully!!! - performance optimite, css.
* caret.js: more caret or textarea element handle.
* adapt the inputor(textare,input) size
* I hate IE! you know that.

###usage
####ajax
``` javascript
$('textarea').atWho(function(context){
    var url = "#",
    param = {'q':context.keyword},
    names = [];
    $.ajax(url,param,function(data) {
        names = $.jsonParse(data);
        //for now , just support plain text array.
        context.view.load(names);
    });
});
```
####static data
``` javascript
names = ['one','two'];
$('textarea').atWho({data:names});
```
