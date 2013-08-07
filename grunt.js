/*global module:false*/
module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: '<json:At.jquery.json>',
    meta: {
      banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
      '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
      '<%= pkg.homepage ? "* " + pkg.homepage + "\n" : "" %>' +
      '* Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
      ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %> */'
    },
    concat: {
      dist: {
        src: ['bower_components/Caret.js/src/jquery.caret.js', 'src/*.js'],
        dest: 'dist/js/<%= pkg.name %>.js'
      }
    },
    min: {
      dist: {
        src: ['<config:concat.dist.dest>'],
        dest: 'dist/js/<%= pkg.name %>.min.js'
      }
    },
    mincss: {
      compress: {
        files: {
          "dist/css/jquery.atwho.css": ["src/*.css"]
        }
      }
    },
    watch: {
      files: '<config:coffee.app.src>',
      tasks: 'test'
    },
    coffee: {
      app: {
        src: ['spec/**/*.coffee', 'src/**/*.coffee'],
        options: {
          // add the safety wrapper.
          bare: false
        }
      }
    },
    'jasmine' : {
      src : '<config:concat.dist.src>',
      helpers : 'spec/helpers/*.js',
      specs : 'spec/**/*.spec.js',
      template : 'spec/SpecRunner.tmpl'
    },
    'jasmine-server' : {
      browser : true
    }
  });

  grunt.loadNpmTasks('grunt-coffee');
  grunt.loadNpmTasks('grunt-jasmine-runner');
  grunt.loadNpmTasks('grunt-contrib-mincss');

  // Default task.
  grunt.registerTask('default', 'coffee jasmine concat mincss min');
  grunt.registerTask('ugly', 'coffee concat mincss min');
  grunt.registerTask('test', 'coffee jasmine')

};
