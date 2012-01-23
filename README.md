Implement Twitter/Weibo @ mentions

###todo
* <del>获取 @ 后面关键字并显示列表.</del>
* <del>caret.js: 对文本框内的光标进行操作.</del>
* <del>列表框浮动到 @ 符号下.</del>
* 适应输入框大小变化
* 完善文档
* 浏览器兼容
* caret.js fork
    更多的文本框操作.插入, 替换等.

###usage
####ajax
``` javascript
$('inputor').atWho(function(context){
    var url = "#",
    param = {'q':"Json"},
    names = [];
    $.ajax(url,param,function(data) {
        names = $.jsonParse(data);
    });
    //for now , just support plain text array.
    return names;
});
```
####static data
``` javascript
names = ['one','two'];
$('inputor').atWho({data:names});
```
