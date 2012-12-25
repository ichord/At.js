
## Add Github like mentions autocomplete to your application.

**Let me know you are using it. So I will work harder on it, Thanks. :smile: .**  

add your websit on [THIS LIST](https://github.com/ichord/At.js/wiki/Sites) if you are using **At.js**


### Demo

[http://ichord.github.com/At.js][1]


### Features

* Can listen to any character
    not just '@', and set up multiple listeners for different characters with different behavior and data.
* TODO: Supports static data and dynamic data(via AJAX) at the same time
    static data will be searched first, and then use AJAX to fetch non-existing values.
* Listener events can be bound to multiple textareas
* TODO: Cacheable
* Format returned data using templates
* Keyboard controls in addition to mouse
    `Tab` or `Enter` keys select the value, `Up` and `Down` navigate between values

* 可自定义数据过滤方法.
* 过滤前可重组数据.
* 可自定义匹配规则. 比如匹配中文
* 可自定义排序规则.
* 可自定义高亮.
* 可自定义模板解析.


### Requirements
* jQuery >= 1.7.0.


### Usage

---


#### Settings

Here is the Default setting.

```javascript
    /*
    为数组(Array)时, 当做静态数据处理.
    为 url 字符串(String)时, At.js 将会从向该地址发送 ajax 请求
    具体使用方法请看下面的示例
     */
    'data': null,

    /*
    假设数据以 {"key": "ichord"} 方式组织, At.js 捕获 "@"后面的字符串后将与 "key" 对应的值进行匹配.
    */
    'search_key': "name"

    // 显示在列表中单个条目的模板. `data-value` 的值将会在条目被选中后插入到输入框里
    'tpl': "<li data-value='${name}'>${name}</li>",

    /*
    自定义回调函数哈希列表.
    用户可自定义某个函数, 比如 `filter`, 可根据 At.js 捕获的字符串去过滤数据.
    详细用法请阅读 `开发者` 章节
    */
    callbacks: DEFAULT_CALLBACKS # {}

     // Enable search cache. Set to false if you want to use $.ajax cache.
    'cache': true,

     // How many items to show at a time in the results
    'limit': 5,

    // 是否插入监听字符
    display_flag: yes

    // 下拉列表延时消失的时间长度, 毫秒为单位
    display_timeout: 300
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

TODO: 如何将 `data` 设置成 url 获取数据

``` javascript

    $('textarea').atWho("@", {
        data: "http://www.atjs.com/users.json", 
        limit: 5
    });

```


#### Custom templates

**base template**, `li` element and `data-value` attribute are all necessary.
We also show how to set up multiple listeners with different characters.

``` html
    <li data-value='${word}'>anything here</li>
```

---

NOTE: we use these static data in all examples below:

``` javascript
    emojis = $.map(emojis, function(value, i) {
        return {'id':i, 'key':value+":", 'name':value};
    });

    data = $.map(data, function(value, i) {
        return {'id':i, 'name':value, 'email':value+"@email.com"};
    });
```

At.js will search by `search_key` and the `data-value` will be inserted to the textarea

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

### Development Magic

#### Callbacks
At.js 将所有处理数据的方法都独立出来, 组成一组**可改变**的回调函数.  
如果你想自己操作处理数据, 可以替换掉相应的回调函数.  
下面会详细 At.js 介绍如何使用这些函数, 特别是它们的**调用顺序**.  
详细用法请查看[开发文档]("#todo")

** 下列方法将按照调用顺序排列 **

```javascript
    
    // ------ for data handler
    
    // At.js 捕获至紧跟 flag("@", etc) 之后的文字后, 将调用此方法进行匹配.
    matcher: function (flag, subtext)

    // 如果 `data` 设置为 url string. At.js 将调用此方法发起 ajax 请求
    remote_filter: function (params, url, render_view)

    // 根据"搜索关键字"过滤数据
    filter: function (query, data, search_key)

    // ------ for render

    // 重新组织数据的结构, 比如传入一组数组: ["hello", "heaaa", "tttss"]. 
    // 你可以将其组织成 [{"name": "hello"}, {"name": "heaaa"}, ...], 用于模板渲染
    data_refactor: function (data)

    // 对过滤后的数据进行排序
    sorter: function (query, items, search_key)

    // 解析并渲染模板
    tpl_eval: function (tpl, map)

    // 高亮搜索搜索关键字
    highlighter: function (li, query)
```

[1]: http://ichord.github.com/At.js
