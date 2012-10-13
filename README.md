Add Twitter / Weibo style @ mentions autocomplete to your application.

###Demo
[http://ichord.github.com/At.js][1]

###Features
* Can listen to any character  
    not just '@', and set up multiple listeners for different characters with different behavior and data.
* Supports static data and dynamic data(via AJAX) at the same time  
    static data will be searched first, and then use AJAX to fetch non-existing values.
* Listener events can be bound to multiple textareas
* Cacheable
* Format returned data using templates
* Keyboard controls in addition to mouse   
    `Tab` or `Enter` keys select the value, `Up` and `Down` navigate between values

### Requirements
* jQuery >= 1.7.0.

### Usage

---

#### Settings

Here is the Default setting.

```javascript
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
    'cache': true,

    /* 
     Static data to use before the callback is invoked
     */
    'data': [],

    /*
     How many items to show at a time in the results
     */
    'limit': 5,

    /* 
     Item format template
     `data-value` contents will be inserted to the textarea on selection
     */
    'tpl': "<li id='${index}' data-value='${name}'>${name}</li>",

    /*
     The name of the data attribute in the item template
     You can change it into any name defined in attributes of `li` element which is template
     */
    'choose': "data-value"
```

#### Using static data

Bind a textarea to listen to a specific character and pass an array of data in the `data` parameter  
The first argument is the character you want to listen, and the second one is a map of options:

``` javascript
    var emoji_list = [
        "apple", "aquarius", "aries", "arrow_backward", "arrow_down",
        "arrow_forward", "arrow_left", "arrow_lower_left", "arrow_lower_right",
        "arrow_right", "arrow_up", "arrow_upper_left", "arrow_upper_right"
    ];
    
    $('textarea').atWho(":", {data:emoji_list});
```

#### Using dynamic data with AJAX

This time we pass a callback function instead of the static data as the second parameter.  
You can just set a function as second argument, At.js will determine it and set it to callback option.  
the data - `names` - would be a string array or a map array which the same as `data` option  
`query` argument is the string behind the character you are listening as "@" in this example.

``` javascript
    $('textarea').atWho("@", function(query, callback) {
        var url = "data.json",
            param = {'q':query};
        $.ajax(url, param, function(data) {
            names = $.parseJSON(data);
            callback(names);
        });
    });
```

#### Using both static data and dynamic data

We pass a configuration object containing both the `data` and `callback` parameters.  
It will search the local static data first.

``` javascript
    var names = ['one', 'two'];
    $('textarea').atWho("@", {
        'data': names,
        'callback': function(query, callback) { 
            console.log(query, callback);
        }
    });
```

#### Custom templates

**base template**, `li` element and `data-value` attribute are all necessary.  
We also show how to set up multiple listeners with different characters.

``` html
    <li data-value='${word}'>anything here</li>
```

---

we use these static data in all examples below:

``` javascript
    emojis = $.map(emojis, function(value, i) {
        return {'id':i, 'key':value+":", 'name':value};
    });

    data = $.map(data, function(value, i) {
        return {'id':i, 'name':value, 'email':value+"@email.com"};
    });
```

##### Simple

At.js will search by `data-value` and the contents will be inserted to the textarea on selection  

``` javascript
    $("textarea").atWho("@",{
        'tpl': "<li id='${id}' data-value='${name}'>${name} <small>${email}</small></li>",
        'data': data
    });
```

``` javascript
    $("textarea").atWho(":",{
        tpl: "<li data-value='${key}'>${name} <img src='http://xxx/emoji/${name}.png' height='20' width='20' /></li>",
        data: emojis
    });
```

##### With callback

``` javascript
    $('textarea').atWho("@",{
        tpl: "<li id='${id}' data-value='${name}'>${name} <small>${email}</small></li>",
        callback: function(query, callback) {
            var url = "data.json",
                param = {'q':query};
            $.ajax(url, param, function(data) {
                names = $.parseJSON(data);
                callback(names);
            });
        }
    });
```

##### Insert different value

Alternatively, you can specific which value would be inserted by setting `choose` option.

``` javascript
    $("textarea").atWho("@", {
        'tpl': "<li id='${id}' data-value='${name}' data-insert='${email}'>${name} <small>${email}</small></li>",
        'data': data,
        'choose': "data-insert"
    });
```

---

#### Update Data
If you want to update data to all binded inputor or specified one. You can do that like this:

``` javascript
    // for all binded textarea
    $('textarea').atWho("@", {data:new_data})
    // for specified one
    $('textarea#at_mention').atWho("@", {data:new_data})
```

It won't change others setting which has been setted earlier.
Actually, It just update the setting. You can use it to change others settings like that.


[1]: http://ichord.github.com/At.js
