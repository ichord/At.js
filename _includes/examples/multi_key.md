
{% highlight javascript %}
var emojis = ["smile", "iphone", "girl", "smiley", "heart", "kiss", "copyright", "coffee"];

var names = ["Jacob", "Isabella", "Ethan", "Emma", "Michael", "Olivia", "Alexander", "Sophia", "William", "Ava", "Joshua", "Emily", "Daniel", "Madison", "Jayden", "Abigail", "Noah", "Chloe", "你好", "你你你"];

var emojis_list = $.map(emojis, function(value, i) {
  return {'id':i, 'key':value+":", 'name':value};
});

var issues = [
  { name: "1", content: "stay foolish"},
  { name: "2", content: "stay hungry"},
  { name: "3", content: "stay heathly"},
  { name: "4", content: "this happiess"},
];

//http://a248.e.akamai.net/assets.github.com/images/icons/emoji/8.png
$(".container textarea")
  .atwho("@", {
    data: names
  })
  .atwho("#", {
    tpl: '<li data-value="${name}">${name} <small>${content}</small></li>',
    data: issues
  })
  .atwho(":", {
    tpl: "<li data-value='${key}'><img src='http://a248.e.akamai.net/assets.github.com/images/icons/emoji/${name}.png' height='20' width='20'/> ${name} </li>",
    data: emojis_list
  });

{% endhighlight %}
