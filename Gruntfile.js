module.exports = function (grunt) {

  grunt.initConfig({
    'jshint': {
      'options': {
        // Search for and use .jshintrc file
        'jshintrc': true
      },
      'all': [
        'Gruntfile.js',
        'app/assets/javascripts/**/*.js'
      ]
    }
  });

  grunt.loadNpmTasks('grunt-contrib-jshint');

  grunt.registerTask('default', ['jshint']);

};
