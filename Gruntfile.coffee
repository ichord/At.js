
module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    name: 'jquery.atwho'
    meta:
      banner: """
        /*! <%= name %> - v<%= pkg.version %> %>
        * Copyright (c) <%= grunt.template.today(\"yyyy\") %> <%= pkg.author.name %> <<%=pkg.author.email%>>;
        * homepage: <%= pkg.homepage %>
        * Licensed <%= pkg.license %>
        */\n
      """

    coffee:
      dist:
        options:
          bare: true, join: true
        files:
          'dist/js/<%= name %>.js': [
            'src/noConflict.coffee',
            'src/app.coffee',
            'src/controller.coffee',
            'src/textareaController.coffee',
            'src/editableController.coffee',
            'src/model.coffee',
            'src/view.coffee',
            'src/default.coffee',
            'src/api.coffee'
          ]
      specs:
        files:[
          {
            expand: true, cwd: 'spec/javascripts', ext: ".spec.js",
            src: '*.spec.coffee', dest: 'spec/build/javascripts',
          },
          src: 'spec/spec_helper.coffee', dest: 'spec/build/spec_helper.js'
        ]
    umd:
      all:
        src: 'dist/js/<%= name %>.js'
        template: 'umd'
        deps:
          'default': ['jquery']
          amd: ['jquery']
          cjs: ['jquery']
          global:
            items: ['jQuery']
            prefix: ''

    copy:
      css: {src: 'src/jquery.atwho.css', dest: 'dist/css/jquery.atwho.css'}

    concat:
      options:
        banner: "<%= meta.banner %>"
      dist:
        src: 'dist/js/<%= name %>.js', dest: 'dist/js/<%= name %>.js'

    uglify:
      dist:
        src: 'dist/js/<%= name %>.js', dest: 'dist/js/<%= name %>.min.js'
    cssmin:
      minify: {src: 'src/jquery.atwho.css', dest: 'dist/css/jquery.atwho.min.css'}

    watch:
      css:
        files: ['src/*.css']
        tasks: ['copy']
      coffee:
        files: ['src/*.coffee', 'spec/javascripts/*.spec.coffee', 'spec/spec_helper.coffee']
        tasks: ['compile', 'uglify']
      test:
        options:
          debounceDelay: 250
        files: ['src/*.coffee', 'spec/javascripts/*.spec.coffee', 'spec/spec_helper.coffee']
        tasks: ['test']

    jasmine:
      dist:
        src: 'dist/js/<%= name %>.js',
        options:
          keepRunner: true
          styles: 'dist/css/<%= name %>.css',
          specs: 'spec/build/javascripts/*.spec.js',
          vendor: [
            'bower_components/jquery/dist/jquery.js',
            'bower_components/Caret.js/src/*.js'
          ],
          helpers: [
            'bower_components/jasmine-jquery/lib/jasmine-jquery.js',
            'spec/build/spec_helper.js',
            'spec/helpers/*.js'
          ]

    connect:
      tests:
        options:
          keepalive: true,
          open:
            target: 'http://localhost:8000/_SpecRunner.html'

    'json-replace':
      options:
        space: "  ",
        replace:
          version: "<%= pkg.version %>"
      'update-version':
        files:[
          {src: 'bower.json', dest: 'bower.json'},
          {src: 'component.json', dest: 'component.json'}
        ]


  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-json-replace'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-umd'

  # alias
  grunt.registerTask 'update-version', 'json-replace'
  grunt.registerTask 'compile', ['coffee', 'umd', 'concat', 'copy', 'cssmin']

  grunt.registerTask "server", ["compile", "jasmine:dist:build", "connect"]
  grunt.registerTask "test", ["compile", "jasmine"]
  grunt.registerTask "dev", ["compile", "watch"]
  grunt.registerTask "default", ['test', 'uglify', 'update-version']
