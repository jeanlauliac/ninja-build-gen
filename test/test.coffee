assert = require 'assert'
ninjaBuildGen = require '../lib/ninja-build-gen'
fs = require 'fs'

compareToString = (ninja, targetStr) ->
    str = ''
    buffer =
        write: (value) ->
            str += value
    ninja.saveToStream buffer
    assert.equal str, targetStr

describe 'ninja', ->
    ninja = null
    beforeEach ->
        ninja = ninjaBuildGen()

    describe '#rule', ->
        it 'should specify the command line', ->
            ninja.rule('coffee').run('coffee -cs < $in > $out')
            compareToString ninja,
                """
                rule coffee
                  command = coffee -cs < $in > $out\n
                """

        it 'should create a description', ->
            ninja.rule('coffee')
                .description('Compile coffee file: $in')
            compareToString ninja,
                """
                rule coffee
                  command = \n  description = Compile coffee file: $in\n
                """

        it 'should create a depfile binding', ->
            ninja.rule('coffee')
                .depfile('$out.d')
            compareToString ninja,
                """
                rule coffee
                  command = \n  depfile = $out.d
                  deps = gcc\n
                """

        it 'should enable restat', ->
            ninja.rule('coffee')
                .restat(true)
            compareToString ninja,
                """
                rule coffee
                  command = \n  restat = 1\n
                """

        it 'should label as generator', ->
            ninja.rule('coffee')
                .generator(true)
            compareToString ninja,
                """
                rule coffee
                  command = \n  generator = 1\n
                """

    describe '#edge', ->
        it 'should create a simple phony edge', ->
            ninja.edge('simple_phony')
            compareToString ninja, 'build simple_phony: phony\n'
        it 'should create a multi-target phony edge', ->
            ninja.edge(['phony1', 'phony2'])
            compareToString ninja, 'build phony1 phony2: phony\n'
        it 'should specify a rule', ->
            ninja.edge('baobab.js').using('coffee')
            compareToString ninja, 'build baobab.js: coffee\n'
        it 'should bind a variable', ->
            ninja.edge('baobab.js').assign 'foobar', 42
            compareToString ninja, 'build baobab.js: phony\n  foobar = 42\n'

        describe '#from', ->
            it 'should specify a source', ->
                ninja.edge('dist').from('debug')
                compareToString ninja, 'build dist: phony debug\n'
            it 'should specify several sources', ->
                ninja.edge('dist').from(['debug', 'release'])
                compareToString ninja, 'build dist: phony debug release\n'
            it 'should specify accumulated sources', ->
                ninja.edge('dist').from('debug').from(['release', 'lint'])
                compareToString ninja, 'build dist: phony debug release lint\n'

        describe '#need', ->
            it 'should specify a requirement', ->
                ninja.edge('dist').need('debug')
                compareToString ninja, 'build dist: phony | debug\n'
            it 'should specify several requirements', ->
                ninja.edge('dist').need(['debug', 'release'])
                compareToString ninja, 'build dist: phony | debug release\n'
            it 'should specify accumulated requirements', ->
                ninja.edge('dist').need('debug').need(['release', 'lint'])
                compareToString ninja,
                    'build dist: phony | debug release lint\n'

        describe '#after', ->
            it 'should specify a order-only requirement', ->
                ninja.edge('dist').after('debug')
                compareToString ninja, 'build dist: phony || debug\n'
            it 'should specify several order-only requirements', ->
                ninja.edge('dist').after(['debug', 'release'])
                compareToString ninja,
                    'build dist: phony || debug release\n'
            it 'should specify accumulated order-only requirements', ->
                ninja.edge('dist').after('debug').after(['release', 'lint'])
                compareToString ninja,
                    'build dist: phony || debug release lint\n'

    describe '#header', ->
        it 'should add a header', ->
            ninja.header('foobar\nfizzbuzz')
            compareToString ninja, 'foobar\nfizzbuzz\n\n'

    describe '#assign', ->
        it 'should bind a variable', ->
            ninja.assign 'some_var', 42
            compareToString ninja, 'some_var = 42\n'

    describe '#save', ->
        it 'should properly save to file', (cb) ->
            ninja.assign 'some_var', 42
            filePath = "#{__dirname}/test.ninja"
            ninja.save filePath, ->
                savedStr = fs.readFileSync(filePath, 'utf-8')
                assert.equal savedStr,
                    """
                    some_var = 42\n
                    """
                cb()
        it 'should save to file without callback', ->
            ninja.assign 'some_var', 42
            filePath = "#{__dirname}/test.ninja"
            ninja.save filePath
