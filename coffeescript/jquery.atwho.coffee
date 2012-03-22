(($) ->
    Mirror = ($origin) ->
        @.init $origin

    Mirror:: =
        $mirror: null
        css: ["overflowY", "height", "width", "paddingTop", "paddingLeft", "paddingRight", "paddingBottom", "marginTop", "marginLeft", "marginRight", "marginBottom",'fontFamily', 'borderStyle', 'borderWidth','wordWrap', 'fontSize', 'lineHeight', 'overflowX']
        init: ($origin) ->
            $mirror = $('<div></div>')
            css =
                opacity: 0
                position: 'absolute'
                left: 0
                top:0
                zIndex: -20000
                'white-space': pre-wrap
            $.each this.css (i,p) ->
                css[p] = $origin.css p
            $mirror.css(css)
            $('body').append $mirror
            @.$mirror = $mirror
        setContent: (html) ->
            @.$mirror.html(html)
        getFlagPos: () ->
            @.$mirror.find("span#flag").position()
        height: () ->
            @.$mirror.height()

    At = (inputor) ->
        $inputor = @.$inputor = $(inputor)
        @options = {}
        @keyword =
            text:""
            start:0
            stop:0
        @_cache = {}
        @pos = 0
        @flags = {}
        @theflag = null
        @seach_word = {}

        @view = AtView
        @mirror = new Mirror $inputor

        $inputor.on "keyup.inputor" $.proxy ((e) ->
            stop = e.keyCode is 40 or e.keyCode is 38
            lookup = stop and not @.view.isShowing()
            this.lookup() if lookup
        ,this)

)(window.jQuery)

