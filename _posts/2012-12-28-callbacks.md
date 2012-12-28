---
section_id: callbacks
title: Callbacks
sub_title: when At.js catch the query string
---

This time we pass a callback function instead of the static data as the second parameter. 
You can just set a function as second argument, At.js will determine it and set it to `callback` option.

    $('textarea').atWho("@",function(query,loaddata) {
        var url = "#",
        param = {'q':query},
        names = [];
        $.ajax(url,param,function(data) {
            names = $.parseJSON(data);
            loaddata(names);
          });
    });


<!-- <section id="callbacks">
    <div class="page-header">
        <h2>Callback <small>when At.js catch the query string</small></h2>
    </div>
    <p>
        This time we pass a callback function instead of the static data as the second parameter. <br/>
        You can just set a function as second argument, At.js will determine it and set it to <code>callback</code> option.
    </p>
    <pre class="prettyprint linenums">
        $('textarea').atWho("@",function(query,loaddata) {
        var url = "#",
        param = {'q':query},
        names = [];
        $.ajax(url,param,function(data) {
        names = $.parseJSON(data);
        loaddata(names);
    });
});
</pre>
<p>
    Calling the <code>loadata</code> method will load data to At.js and show then
</p>
</section>

 -->
