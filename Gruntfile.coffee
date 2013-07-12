'use strict'
fs = require 'fs'

module.exports = (grunt) ->
    grunt.initConfig
        coffee:
            options:
                bare: true
                sourceMap: true
            dist:
                files: [{
                    expand: true
                    cwd: 'source'
                    src: '*.coffee'
                    dest: 'lib'
                    ext: '.js'
                }]
        coffeelint:
            files: [
                'source/*.coffee'
                'test/*.coffee'
                'Gruntfile.coffee'
            ]
            options: JSON.parse(fs.readFileSync('.coffeelint'))
        mochaTest:
            test:
                options:
                    reporter: 'spec'
                src: 'test/*.js'

    grunt.registerTask 'dist', [
        'coffeelint'
        'coffee'
        'mochaTest'
    ]

    grunt.registerTask 'default', ['dist']
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-coffeelint'
    grunt.loadNpmTasks 'grunt-mocha-test'
