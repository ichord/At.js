Implement Twitter/Weibo @ mentions

**support ie6,7. But problem in long word break**

###Feature
* support static data and dynamic data(ajax) at the same time
    it will search the static data first. If not exist, searching by callabck then.
* can bind multiple textarea
* cacheable
* decide which data should show yourself(data template)
* press `TAB` or `ENTER` to insert.
* press `UP` and `DOWN` to select.

###usage

#### settings
``` javascript
    default = {
                /*
		 call this function after catch the query words.
		 context object will be the core handler hold all function and field.
		 see the example below.
		 it must be return a plain text array
                 */
		'callback': function(context) {return []},
                /*
		 enable search cache. if you want to use $.ajax cache.
		 just set it false.
                 */
		'cache' : true,
                /* see usage below. */
		'data':[],
                /* if set true it will issue running msg; */
                'debug' : false,
                'limit' : 5,
                /* element render template
                 * the value will insert into textarea when you make a choose
                 */
                'tpl' : "<li id='${index}' data-insert='${name}'>${name}</li>"
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

####both
``` javascript
names = ['one','two'];
$('textarea').atWho({
    'data': names,
    'callback': function(c) { console.log(c);}
    });
```

####customs template
base template : `<li data-insert='${search_word}'>anything here</li>`

``` javascript
var data = ["Jacob","Isabella","Ethan","Emma","Michael","Olivia","Alexander","Sophia","William","Ava","Joshua","Emily","Daniel","Madison","Jayden","Abigail","Noah","Chloe"];

data = $.map(data,function(value,i) {
        return {'id':i,'name':value,'email':value+"@email.com"};
        });

$("textarea").atWho({
        'tpl': "<li id='${id}' data-insert='${name}'>${name}<small>${email}</small></li>",
        'data':data,
        'debug':true
        });
```
