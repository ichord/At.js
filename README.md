Add Twitter / Weibo style @ mentions autocomplete to your application.

###Demo
[http://ichord.github.com/At.js][1]

###Features
* Can listen to any character - not just '@', and set up multiple listeners for different characters with different behavior and data.
* Supports static data and dynamic data(via AJAX) at the same time - static data will be searched first, and then use AJAX to fetch non-existing values.
* Listener events can be bound to multiple textareas
* Cacheable
* Format returned data using templates
* Keyboard controls in addition to mouse - `Tab` or `Enter` keys select the value, `Up` and `Down` navigate between values

### Requirements
* jQuery >= 1.7.0.

### Usage

#### Settings

```javascript
    default = {
                /*
                 Callback function to dynamically retrieve data based on query.
                 `At` will pass two arguments to the callback: `query` and `callback`.
                 `query` is the keyword that is being autocompleted after the character listener ('@' is the default)
                 `callback` should be run on the data. It accepts a string array or plain object array
                 */
		'callback': null,

                /*
		 Enable search cache. Set to false if you want to use $.ajax cache.
                 */
		'cache' : true,

                /* 
                 Static data to use before the callback is invoked
                 */
		'data':[],

                /*
                 How many items to show at a time in the results
                 */
                'limit' : 5,

                /* 
                 Item format template
                 `data-value` contents will be inserted to the textarea on selection
                 */
                'tpl' : "<li id='${index}' data-value='${name}'>${name}</li>",

                /*
                 The name of the data attribute in the item template
                 */
                'choose' : "data-value"
	};
```
#### Using static data

Bind a textarea to listen to a specific character and pass an array of data in the `data` parameter:

``` javascript
    var emoji_list = [
        "apple", "aquarius", "aries", "arrow_backward", "arrow_down",
        "arrow_forward", "arrow_left", "arrow_lower_left",     "arrow_lower_right",
    "arrow_right", "arrow_up", "arrow_upper_left", "arrow_upper_right"];
    
    $('textarea').atWho(":",{data:emoji_list});
```

#### Using dynamic data with AJAX

This time we pass a callback function instead of the static data as the second parameter.

``` javascript
    $('textarea').atWho("@",function(query,callback) {
        var url = "#",
        param = {'q':query},
        names = [];
        $.ajax(url,param,function(data) {
            names = $.parseJSON(data);
            <div></div>
            callback(names);
        });
    });
```

#### Using both static data and dynamic data

We pass a configuration object containing both the `data` and `callback` parameters.

``` javascript
    var names = ['one','two'];
    $('textarea').atWho("@",{
        'data': names,
        'callback': function(query,callback) { 
            console.log(query,callback);
        }
    });
```

#### Custom templates

_The following code is taken from the example.html file_

**base template**, `li` element and `data-value` attribute are all necessary. We also show how to set up multiple listeners with different characters.

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

[1]: http://ichord.github.com/At.js
