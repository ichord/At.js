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
    // concat: {
    //   dist: {
    //     src: ['<banner:meta.banner>', '<file_strip_banner:src/<%= pkg.name %>.js>'],
    //     dest: 'dist/<%= pkg.name %>.js'
    //   }
    // },
    // min: {
    //   dist: {
    //     src: ['<banner:meta.banner>', '<config:concat.dist.dest>'],
    //     dest: 'dist/<%= pkg.name %>.min.js'
    //   }
    // },
    lint: {
      files: ['grunt.js', 'src/**/*.js', 'test/**/*.js']
    },
    watch: {
      files: '<config:lint.files>',
      tasks: 'lint jasmine_node'
    },
    jshint: {
      options: {
        curly: true,
        eqeqeq: true,
        immed: true,
        latedef: true,
        newcap: true,
        noarg: true,
        sub: true,
        undef: true,
        boss: true,
        eqnull: true,
        browser: true
      },
      globals: {
        jQuery: true
      }
    },
    coffee: {
      app: {
        src: ['src/*.coffee'],
        dest: 'js/'
      }
    },
    jasmine_node: {
      specNameMatcher: "spec", // load only specs containing specNameMatcher
      extensions: "coffee",
      projectRoot: ".",
      forceExit: true,
      jUnit: {
        report: false,
        savePath : "./spec/reports/",
        useDotNotation: true,
        consolidate: true
      }
    }
  });

  // grunt.loadNpmTasks('grunt-jasmine-runner');
  // grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-coffee');
  grunt.loadNpmTasks('grunt-jasmine-node');

  // Default task.
  grunt.registerTask('default', 'coffee lint jasmine_node');

};
