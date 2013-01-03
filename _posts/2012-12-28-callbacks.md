---
section_id: callbacks
title: Callbacks
sub_title: 自己定制 At.js
---

At.js 将所有处理数据的方法都独立出来, 组成一组可改变的回调函数.  
**如果你想自己操作处理数据, 可以替换掉相应的回调函数.**  
下面会简单介绍如何使用这些函数, 特别是它们的**调用顺序**.  
详细的介绍请查阅技术文档的 <a href="http://coffeedoc.info/github/ichord/At.js/master/mixins/DEFAULT_CALLBACKS.html" target="_blank">Mixins</a> 章节

<span class="label label-warning">NOTE</span> 下列方法将按照调用顺序排列
{% highlight javascript %}

    // ------ for data handler

    // 重新组织数据的结构, 比如传入一组数组: ["hello", "heaaa", "tttss"]. 
    // 你可以将其组织成 [{"name": "hello"}, {"name": "heaaa"}, ...]
    data_refactor: function (data)
        
    // At.js 捕获至紧跟 flag("@", etc) 之后的文字后, 将调用此方法进行匹配.
    matcher: function (flag, subtext)

    // 如果 `data` 设置为 url string. At.js 将调用此方法发起 ajax 请求
    remote_filter: function (params, url, render_view)

    // 根据"搜索关键字"过滤数据
    filter: function (query, data, search_key)

    // ------ for render

    // 对过滤后的数据进行排序
    sorter: function (query, items, search_key)

    // 解析并渲染模板
    tpl_eval: function (tpl, map)

    // 高亮搜索搜索关键字
    highlighter: function (li, query)

    // 选中列表项时的操作
    selector: function($li)

{% endhighlight %}

