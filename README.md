Implement Twitter/Weibo @ mentions

**support ie6,7. But problem in long word break**

###Demo
http://ichord.github.com/At.js

###Feature
* can listen any char you want.
    every listening can have same settings but different value.
    so they can have different behaviors such as showing different data by setting different template.
* support static data and dynamic data(ajax) at the same time
    it will search the static data first. If not exist, searching by callabck then.
* can bind multiple textarea
* cacheable
* decide which data should be showing yourself(data template)
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

####static data
``` javascript
emoji_list = [
    "apple", "aquarius", "aries", "arrow_backward", "arrow_down",
    "arrow_forward", "arrow_left", "arrow_lower_left", "arrow_lower_right",
    "arrow_right", "arrow_up", "arrow_upper_left", "arrow_upper_right"];
$('textarea').atWho(":",{data:emoji_list});
```

####ajax
``` javascript
$('textarea').atWho("@",function(context){
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

####both
``` javascript
names = ['one','two'];
$('textarea').atWho("@",{
    'data': names,
    'callback': function(c) { console.log(c);}
    });
```

####customs template
code in example.html file
base template :

`<li data-keyname='${search_word}'>anything here</li>`

``` javascript

    var emojis = $.map(emoji_list,function(value,i) {
                        return {'id':i,'key':value+":",'name':value};
                        });

                    $("textarea").atWho("@",{
                        'tpl': "<li id='${id}' data-keyname='${name}'>${name} <small>${email}</small></li>",
                        'debug':true,
                        'data':data
                        })
                    .atWho(":",{
                        debug:true,
                        'data':emojis,
                        'tpl':"<li data-keyname='${key}'>${name} <img src='http://a248.e.akamai.net/assets.github.com/images/icons/emoji/${name}.png'  height='20' width='20' /></li>"
                        });

```
