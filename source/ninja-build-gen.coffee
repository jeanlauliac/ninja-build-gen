# # Ninja-build Generator
#
# This library exports a a set of functions to build a Ninja file
# programmatically.
'use strict'
require('source-map-support').install()
fs          = require 'fs'
ld          = require 'lodash'

# Represent a Ninja variable assignation (it's more a binding, actually).
class NinjaAssign
    constructor: (@name, @value) ->

    # Write the assignation into a `stream`.
    write: (stream) ->
        stream.write "#{@name} = #{@value}\n"

# Represent a Ninja edge, that is, "how to construct this file X from Y".
class NinjaEdge
    # Construct an edge specifing the resulting files, as `targets`, of the
    # edge.
    constructor: (@targets = [], @rule = 'phony', \
                  @sources = [], @dependencies = []) ->
        @assigns = []
        @targets = [@targets] if typeof @targets == 'string'
        @sources = [@sources] if typeof @sources == 'string'
        @dependencies = [@dependencies] if typeof @dependencies == 'string'

    # Define the Ninja `rule` name to use to build this edge.
    using: (rule) ->
        @rule = rule
        this

    # Define one or several direct `sources`, that is, files to be transformed
    # by the rule.
    from: (sources) ->
        sources = [sources] if typeof sources == 'string'
        @sources = @sources.concat sources
        this

    # Define one or several indirect `dependencies`, that is, files needed but
    # not part of the compilation or transformation.
    need: (dependencies) ->
        dependencies = [dependencies] if typeof dependencies == 'string'
        @dependencies = @dependencies.concat dependencies
        this

    # Define one or several order-only dependencies in `orderDeps`, that is,
    # this edge should be build after those dependencies are.
    after: (orderDeps) ->
        orderDeps = [orderDeps] if typeof orderDeps == 'string'
        @orderDeps = @orderDeps.concat orderDeps
        this

    # Bind a variable to a temporary value for the edge.
    assign: (name, value) ->
        @assigns[name] = value

    # Write the edge into a `stream`.
    write: (stream) ->
        stream.write "build #{@targets.join(' ')}: #{@rule}"
        stream.write ' ' + @sources.join(' ') if @sources?
        if @dependencies.length > 0
            stream.write ' | ' + @dependencies.join ' '
        if @orderDeps.length > 0
            stream.write ' || ' + @orderDeps.join ' '
        for name, value of @assigns
            stream.write "\n  #{name} = #{value}"
        stream.write '\n'

# Represent a Ninja rule, that is, a method to "how I build a file of type A
# to type B".
class NinjaRule
    # Create a rule with this `name`.
    constructor: (@name, @command, @desc) ->
        @command = ''

    # Specify the command-line to run to execute the rule.
    run: (command) ->
        @command = command
        this

    # Provide a description, displayed by Ninja instead of the bare command-
    # line.
    description: (desc) ->
        @desc = desc
        this

    # Provide a Makefile-compatible dependency file for the rule products.
    depfile: (file) ->
        @dependencyFile = file
        this

    # Write the rule into a `stream`.
    write: (stream) ->
        stream.write "rule #{@name}\n  command = #{@command}\n"
        stream.write "  description = #{@desc}\n" if @desc?
        if @dependencyFile?
            stream.write "  depfile = #{@dependencyFile}\n"
            stream.write "  deps = gcc\n"

# Represent a Ninja build file.
class NinjaFile
    # Create the builder, specifing an optional required Ninja `version`, and a
    # build directory (where Ninja put logs and where you can put
    # intermediary products).
    constructor: (@version, @buildDir) ->
        @clauses = []
        @edgeCount = 0
        @ruleCount = 0

    # Set an arbitrary header.
    header: (value) ->
        @headerValue = value
        this

    # Specify the default rule by its `name`.
    byDefault: (name) ->
        @defaultRule = name
        this

    # Add a variable assignation into `name` from the `value`.
    assign: (name, value) ->
        clause = new NinjaAssignBuilder(name, value)
        @clauses.push clause
        clause

    # Add one or more edge(s) or rule(s). You can pass just a clause, of
    # array of clause.
    push: (clauses) ->
        clauses = [clause] if typeof clauses == 'string'
        @clauses = @clauses.concat clauses
        this

    # Write to a `stream`. It does not end the stream.
    saveToStream: (stream) ->
        stream.write @headerValue + '\n\n' if @headerValue?
        stream.write "ninja_required_version = #{@version}\n" if @version?
        stream.write "builddir=#{@buildDir}\n" if @buildDir?
        for clause in @clauses
            clause.write stream
        stream.write "default #{@defaultRule}\n" if @defaultRule?

    # Save the Ninja file on the filesystem at this `path` and call
    # `callback` when it's done.
    save: (path, callback) ->
        file = fs.createWriteStream(path)
        @saveToStream file
        if callback
            file.on 'close', -> callback()
        file.end()

exports.edge = (targets) ->
    new NinjaEdge(targets)

exports.rule = (name) ->
    new NinjaRule(name)

exports.file = (version, builddir) ->
    new NinjaFile(version, builddir)
