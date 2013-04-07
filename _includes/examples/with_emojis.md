
{% highlight javascript %}
var emojis = ["smile", "iphone", "girl", "smiley", "heart", "kiss", "copyright", "coffee"];
var emojis_list = $.map(emojis, function(value, i) {
  return {'id':i, 'key':value+":", 'name':value};
});
//http://a248.e.akamai.net/assets.github.com/images/icons/emoji/8.png
$(".container textarea").atwho(":", {
  tpl: "<li data-value='${key}'><img src='http://a248.e.akamai.net/assets.github.com/images/icons/emoji/${name}.png' height='20' width='20'/> ${name} </li>",
  data: emojis_list
});
{% endhighlight %}
