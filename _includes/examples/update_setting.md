
{% highlight html %}
<div class="container">
  
  <div class="controls">
    <button id="update">new data</button>
    <button id="fallback">old data</button>
  </div>
  
  <textarea>@hello click the button to change the data!</textarea>
<div>

{% endhighlight %}

{% highlight javascript %}
var names = ["Jacob", "Isabella", "Ethan", "Emma", "Michael", "Olivia", "Alexander", "Sophia", "William", "Ava", "Joshua", "Emily", "Daniel", "Madison", "Jayden", "Abigail", "Noah", "Chloe", "你好", "你你你"];

$inputor = $(".container textarea");
$inputor.atwho("@", {
    data: names
});

var new_names = [{key:"one"}, {key: "two"}, {key: "three"}, {key: "four"}];
$("#update").on("click", function(e) {
  $inputor.atwho("@", {
    data: new_names,
    search_key: "key",
    tpl: '<li data-value="${key}">${key} <small>${key}-hello</small></li>'
  });
  $inputor.focus();
});

$("#fallback").on("click", function(e) {
  $inputor.atwho("@", {
    search_key: $inputor.atwho.default.search_key,
    tpl: $inputor.atwho.default.tpl,
    data: names
  });
  $inputor.focus();
});

{% endhighlight %}
