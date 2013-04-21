'use strict';

module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON("package.json"),
    banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
      '<%= grunt.template.today("yyyy-mm-dd hh:mm:ss") %>\n' +
      '<%= pkg.homepage ? " * " + pkg.homepage + "\\n" : "" %>' +
      ' * Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
      ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %>\n */\n',
    // Task configuration.
    concat: {
      options: {
        banner: '<%= banner %>',
        stripBanners: true
      },
      dist: {
        src: ['html/compiled/grotto.js'],
        dest: 'html/grotto.js'
      },
    },
    coffee: {
      glob_to_multiple: {
        expand: true,
        cwd: 'client',
        src: ['*.coffee'],
        dest: 'html/compiled',
        ext: '.js'
      }
    },
    watch: {
      coffee: {
        files: ['client/*.coffee'],
        tasks: ['coffee', 'browserify', 'concat']
      }
    },
    browserify: {
      js: {
        src: ['html/compiled/main.js'],
        dest: 'html/compiled/grotto.js'
      },
    }
  });

  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-browserify');
  
  // Default task.
  grunt.registerTask('default', ['coffee', 'browserify', 'concat']);

};