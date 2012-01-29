Implement Twitter/Weibo @ mentions

**tested in chrome firefox ie8**

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
                 //see usage below.
		'data':[],
                // if set true it will issue running msg;
                'debug':false
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

###both
``` javascript
names = ['one','two'];
$('textarea').atWho({
    'data': names,
    'callback': function(c) { console.log(c);}
    });
```
