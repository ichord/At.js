### v0.2.0 - 2012-12

**开发过程中不再测试 ie 浏览器.**

#### 新特性

* 可自定义数据过滤方法.
* 过滤前可重组数据.
* 可自定义匹配规则. 比如匹配中文
* 可自定义排序规则.
* 可自定义高亮.
* 可自定义模板解析.

#### 取消的功能

* 默认不能同时使用本地静态数据和动态(ajax)数据

#### 参数变更

`-` 开头表示在新版本中被去掉的参数  
`+` 开头表示新加的参数  
开头没有任何符号的则是没有改变的参数

*新参数的使用方法将会在 `README.md` 文档中详细介绍*

`data` 参数现在支持 `String` 和 `Array` 两种格式. 为 `String` 的时候则当作是一个 `url` 处理,直接从向该url请求数据. 兼容旧版用法.

* `-` data: [],  
* `+` data: null,

旧版的这个参数是为了支持插入与搜索不同的内容. 现在插入内容直接在模板里获得, 可以用新版参数设置任意搜索项.具体用法请看文档.

* `-` choose: "data-value",
* `+` search_key: "name",

新版提供了多个关键的回调, 比如匹配 `@` 后面字符串的正则表达, 可以通过 `matcher` 回调函数自由匹配.

* `-` callback: null,
* `+` callbacks: DEFAULT_CALLBACKS,

设置下拉列表消失的快慢, 以便点击比较慢时不会点不中列表项. 小时的时间用次参数自行调整

* `+` display_timeout: 300,

新的模板: "<li data-value='${name}'>${name}</li>", At.js 将直接获得 `data-value` 的值插入到输入框.

* `-` tpl: _DEFAULT_TPL
* `+` tpl: DEFAULT_TPL

以下参数没有变化

*     cache: true,
*     limit: 5,
*     display_flag: true,

### v0.1.7

同步 `jquery-atwho-rails` gem 的版本号  
这会是 `v0.1` 的固定版本. 不再有新功能更新.  

###v0.1.2 2012-3-23
* box showing above instead of bottom when it get close to the bottom of window
* coffeescript here is.
* every registered character able to have thire own options such as template(`tpl`)
* every inputor (textarea, input) able to have their own registered character and different behavior
  even the same character to other inputor

###v0.1.0
* 可以監聽多個字符
    multiple char listening.
* 顯示缺省列表.
    show default list.
