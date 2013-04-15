'use strict';

module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON("package.json"),
    banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
      '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
      '<%= pkg.homepage ? "* " + pkg.homepage + "\\n" : "" %>' +
      '* Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
      ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %> */\n',
    // Task configuration.
    concat: {
      options: {
        banner: '<%= banner %>',
        stripBanners: true
      },
      dist: {
        src: ['src/<%= pkg.name %>.js'],
        dest: 'dist/ba-<%= pkg.name %>.js'
      },
    },
    coffee: {
      glob_to_multiple: {
        expand: true,
        cwd: 'coffee',
        src: ['*.coffee'],
        dest: 'html/compiled',
        ext: '.js'
      }
    },
    watch: {
      coffee: {
        files: ['coffee/*.coffee'],
        tasks: 'coffee'
      }
    },
    "ftp-deploy": {
      build: {
        auth: {
          host: 'ftp.webhero.com',
          port: 21,
          authKey: 'dewb.org'
        },
        src: 'html',
        dest: '/public_html/grotto',
        exclusions: [
          '**/.DS_Store', 
          '**/Thumbs.db', 
        ],
      },
    },
  });

  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-ftp-deploy');
  
  // Default task.
  grunt.registerTask('default', ['coffee']);

};