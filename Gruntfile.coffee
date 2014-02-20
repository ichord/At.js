
module.exports = (grunt) ->
  
  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    meta:
      banner: "/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - " +
        "<%= grunt.template.today(\"yyyy-mm-dd\") %>\n" +
        "<%= pkg.homepage ? \"* \" + pkg.homepage + \"\n\" : \"\" %>" +
        "* Copyright (c) <%= grunt.template.today(\"yyyy\") %> <%= pkg.author.name %>;" +
        " Licensed <%= _.pluck(pkg.licenses, \"type\").join(\", \") %> */"

    coffee:
      dist:
        src: 'src/<%= pkg.name %>.coffee', dest: 'dist/js/<%= pkg.name %>.js'
      specs:
        files:[
          {
            expand: true, cwd: 'spec/javascripts', ext: ".spec.js",
            src: '*.spec.coffee', dest: 'spec/build/javascripts',
          },
          src: 'spec/spec_helper.coffee', dest: 'spec/build/spec_helper.js'
        ]

    uglify:
      dist:
        src: 'dist/js/<%= pkg.name %>.js', dest: 'dist/js/<%= pkg.name %>.min.js'

    watch:
      coffee:
        files: ['src/*.coffee', 'spec/javascripts/*.spec.coffee', 'spec/spec_helper.coffee']
        tasks: ['coffee', 'uglify', 'notify']
      test:
        options:
          debounceDelay: 250
        files: ['spec/javascripts/*.spec.coffee', 'spec/spec_helper.coffee']
        tasks: ['test', 'notify']

    jasmine:
      dist:
        src: 'dist/js/<%= pkg.name %>.js',
        options:
          keepRunner: true
          styles: 'dist/css/<%= pkg.name %>.css',
          specs: 'spec/build/javascripts/*.spec.js',
          vendor: [
            'bower_components/jquery/jquery.min.js',
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
          {src: 'component.json', dest: 'component.json'},
          {src: 'At.jquery.json', dest: 'At.jquery.json'}
        ]

    notify:
      success:
        options:
          message: 'Build Successfully'

    copy:
      css: {src: 'src/jquery.atwho.css', dest: 'dist/css/jquery.atwho.css'}


  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-json-replace'
  grunt.loadNpmTasks 'grunt-notify'
  grunt.loadNpmTasks 'grunt-contrib-copy'

  # alias
  grunt.registerTask 'update-version', 'json-replace'

  grunt.registerTask "server", ["coffee", "jasmine:dist:build", "connect"]
  grunt.registerTask "test", ["coffee", "jasmine"]
  grunt.registerTask "default", ['test', 'uglify', 'copy', 'update-version']
