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
