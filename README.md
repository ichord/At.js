Implement Twitter/Weibo @ mentions

** It have been passed the testing in major browser even include IE6,7,8. **

###todo
* <del>获取 @ 后面关键字并显示列表.</del>
* <del>caret.js: 对文本框内的光标进行操作.</del>
* <del>列表框浮动到 @ 符号下.</del>
* <del>浏览器兼容</del>
* <del>caret.js fork 更多的文本框操作.插入, 替换等.</del> google rangy
* <del>支持多输入框</del>
* <del>性能优化</del>
* 适应输入框大小变化

###todo - en
* <del> get the tail of @: match the key word after @</del>
* <del> caret.js: set or get caret position in textarea or input element</del>
* <del> let mention box dance with the "@"</del>
* <del>caret.js: more caret or textarea element handle.</del> google rangy
* <del>I hate IE! you know that.: test on IE6,7,8 and run good.</del>
* <del> support multiple inputor </del>
* <del>Let's dance beautifully!!! - performance optimite, css.</del>
* adapt the inputor(textare,input) size

###usage
#### settings
``` javascript
    default = {
		// call this function after catch the query words.
		// context object will be the core handler hold all function and field.
		// see the example below.
		// it must be return a plain text array
		'callback': function(context) {return []},
		// enable search cache. if you want to use $.ajax cache.
		// just set it false.
		'cache' : true,
		'data':[]
	};
```

####ajax
``` javascript
$('textarea').atWho(function(context){
    var url = "#",
    param = {'q':context.keyword.text},
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
