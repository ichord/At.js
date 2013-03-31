### 2013-04

* remove ability of changing common setting after inputor binded
* can fix list view after matched query in IE now.
* separated core function (get offset of inputor) as a jquery plugins.

### v0.2.0 - 2012-12

**No more testing in IEs browsers.**

#### Note
The name `atWho` was changed to `atwho`.

#### New features

* Customer data handlers(matcher, filter, sorter) and template renders(highlight, template eval) by a group of configurable callbacks.
* Support **AMD**

#### Removed features

* Filter by local data and remote (by ajax) data at the same time.
* Caching
* Mouse event

#### Changed settings

`-` mean removed option
`+` mean new added option
The one that start without `-` or `+` mean not change.

* `-` data: [],  
* `+` data: null,

* `-` choose: "data-value",
* `+` search_key: "name",

* `-` callback: null,
* `+` callbacks: DEFAULT_CALLBACKS,

* `+` display_timeout: 300,

* `-` tpl: _DEFAULT_TPL
* `+` tpl: DEFAULT_TPL

* `-` cache: false

Not change settings

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
