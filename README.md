Implement Twitter/Weibo @ mentions

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
                 It's must be a function.

                 `At` will pass two arguments to this callback, they are `query` and `callback`:
                 `query` is the key word that fetch from the textarea 
                 with the char you have regsitered such as "@"

                 `callback` will accept a string array or plain object array
                 one more thing, those name is optional.
                 */
		'callback': null,

                /*
		 enable search cache. if you want to use $.ajax cache.
		 just set it false.
                 */
		'cache' : true,

                /* 
                 static data will be searched by this plugin
                 */
		'data':[],

                /*
                 how much item will be showed in box
                 */
                'limit' : 5,

                /* 
                 item template
                 this plugin will insert the value of `data-value` into textarea and search by it.
                 `data-value` attr is nessnary.
                 */
                'tpl' : "<li id='${index}' data-value='${name}'>${name}</li>",

                /*
                 which attribute's value of the `li` element would be appended to input.
                 default attribute is "data-value"
                 */
                'choose' : "data-value"
	};
```

####static data
what you need to do is just register the character such as `@` or `:` like this example,
and then pass the data.

``` javascript
emoji_list = [
    "apple", "aquarius", "aries", "arrow_backward", "arrow_down",
    "arrow_forward", "arrow_left", "arrow_lower_left", "arrow_lower_right",
    "arrow_right", "arrow_up", "arrow_upper_left", "arrow_upper_right"];
$('textarea').atWho(":",{data:emoji_list});
```

####ajax

``` javascript
$('textarea').atWho("@",function(query,callback){
    var url = "#",
    param = {'q':query},
    names = [];
    $.ajax(url,param,function(data) {
        names = $.parseJSON(data);
        // `names` must be a array contain string or plain object 
        callback(names);
    });
});
```

####both

``` javascript
names = ['one','two'];
$('textarea').atWho("@",{
    'data': names,
    'callback': function(query,callback) { console.log(query,callback);}
    });
```

####customs template

code in example.html file  
**base template**, `li` element and `data-value` attribute is necessary :  

`<li data-value='${word}'>anything here</li>`

``` javascript
$("textarea")
.atWho("@",{
    'tpl': "<li id='${id}' data-value='${name}'>${name} <small>${email}</small></li>"
    ,'data':data
})
.atWho(":",{
    tpl:"<li data-value='${key}'>${name} <img src='http://a248.e.akamai.net/assets.github.com/images/icons/emoji/${name}.png'  height='20' width='20' /></li>"
    ,callback:function(query,callback) {
        $.ajax({
            url:'data.json'
            data:{q:query}
            ,type:'GET'
            ,success:function(data) {
                datas = $.map(data,function(value,i){
                    return {'id':i,'key':value+":",'name':value}
                    })
                callback(datas)
            }
        })
    }
})
```
