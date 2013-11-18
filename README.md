# ninja-build-gen

Create [Ninja](http://martine.github.io/ninja/) build-system manifests from
JavaScript. This can be used for build in any kind of project, though (Ruby,
Python, or even C++, why not...).

## Install

The easiest is to use the mainstream Node.js package manager, `npm`, to handle
the package installation. Most of the time, you'll add it to the
`devDependencies` of your `package.json`, eg:

```bash
$ npm install ninja-build-gen --save-dev
```

You may typically want to install the
[ninja-build](https://github.com/undashes/ninja-build) as well. Indeed, this
package does not include the Ninja build system itself.

Generally, you should not need this package for package distribution (instead
of being in `dependencies`), since it's mostly useful to handle the minimal
compilation of assets, like CoffeeScript files. Published packages should
contain the compiled JS files (or CSS, etc.), not the sources (nor the tests).

## Sample Use

This is typically used creating a `configure.js` script. In this script, let's
first create a new build file for Ninja version 1.3, with the build directory
`build`:

```js
ninjaBuildGen = require('ninja-build-gen');
ninja = ninjaBuildGen('1.3', 'build');
```

Let's add two rules, for example, one to compile
[CoffeeScript](https://github.com/jashkenas/coffee-script) files, the other to
compile [Stylus](https://github.com/LearnBoost/stylus) files:

```js
ninja.rule('coffee').run('coffee -cs < $in > $out')
     .description("Compile Coffeescript '$in' to '$out'.");
ninja.rule('stylus').run('stylus $in -o $$(dirname $out)')
     .description("Compile Stylus '$in' to '$out'");
```

Then we can add edges to compile the actual files, for example:

```js
ninja.edge('foo.js').from('foo.coffee').using('coffee');
ninja.edge('bar.js').from('bar.coffee').using('coffee');
ninja.edge('glo.css').from('glo.stylus').using('stylus');
ninja.edge('assets').from(['foo.js', 'bar.js', 'glo.cs']);
ninja.byDefault('assets');
```

Let's save the file to the standard Ninja filename:

```js
ninja.save('build.ninja');
```

That's it! Now you can run the configure script, then ninja, to build the
project:

```bash
$ node configure.js
$ ninja
[1/3] Compile Coffeescript 'foo.coffee' to 'foo.js'.
[2/3] Compile Coffeescript 'bar.coffee' to 'bar.js'.
[3/3] Compile Coffeescript 'glo.styl' to 'glo.css'.
Done.
$ ninja
ninja: nothing to do.
```

Thanks to Ninja, you get minimal recompilation: only changed file are
recompiled upon invocation, as you can see for the second execution above.

## Limitations

This package is only here to make easier the creation of Ninja build files, but
it does not provide any high-level features, and those are out of scope. That
is, no wildcards, no globbing and file lookup; just streamlined Ninja build
file generation.

It is recommended to use a globbing library such as
[glob](https://npmjs.org/package/glob) to create the edges based on
existing files. Also, you can generate the output file names by using the
[globule](https://npmjs.org/package/globule) library. For example:

```js
var files = globule.findMapping('*.coffee', {srcBase: 'src', destBase: 'out',
                                             ext: '.js'});
for (var i = 0; i < files.length; ++i) {
    var match = files[i];
    ninja.edge(match.dest).from(match.src).using('coffee');
}
```

## API

Calls can generally be chained, on `<ninja>`, `<rule>` and `<edge>`. For
example: `ninja.edge('foo.o').from('foo.c').need('foo.h').using('cc')`.

##### `ninjaBuildGen([version], [builddir])`

Create a `<ninja>` manifest. `version` specifies the Ninja version required
in the manifest, `builddir` is the building folder where Ninja will put
temporary files. You can refer to it using `$builddir` in Ninja
clauses.

##### `ninjaBuildGen.escape(string)`

Escape the `string` to be suitable in a Ninja file. See the
[Ninja lexical syntax](http://martine.github.io/ninja/manual.html#_lexical_syntax)
for more information on escaping. It escapes characters `$`, `:`, and spaces.
You can use this function to process a list of path when you know you don't
need to access variables. Eg:

```js
var paths = ['foo.js', 'bar.js', 'glo.js'];
ninja.edge('concat.js').from(paths.map(ninjaBuildGen.escape)).using('concat');
```

Otherwise, you need to escape manually. The following statements are
equivalent:

```js
ninja.edge('foo$:bar$$glo$ fiz.js');
ninja.edge(ninjaBuildGen.escape('foo:bar$glo fiz.js'));
```

### `<ninja>`

##### `<ninja>.header(value)`

Add an arbitrary header to the file containing `value`. This is useful to add
some comments on top, such as `# generated from configure.js`. You can't
cumulate several headers.

##### `<ninja>.byDefault(name)`

Set the default edge to build when Ninja is called without target. There can
be only one default edge.

##### `<ninja>.assign(name, value)`

Add a variable assignation in the manifest. The order is important, you
shall call this before adding a rule or edge referencing the variable.

##### `<ninja>.rule(name)`

Create a `<rule>`, add it the manifest, and return it. The `name`
of the rule is then used to reference it from the edges.

##### `<ninja>.edge(targets)`

Create an `<edge>`, add it to the manifest, and return it. The `targets` of the
edge is a `String` or an `Array` of it specifying the files that will
result from the compilation of the edge. Each `String` is a path, that can
be absolute, or relative to the location of the manifest (recommended).

##### `<ninja>.save(path, [callback])`

Output the manifest to a file at `path`. Call `callback()` once it's done.

##### `<ninja>.saveToStream(stream)`

Output the manifest to a Node.js
[`stream.Writable`](http://nodejs.org/api/stream.html#stream_class_stream_writable).
It does not 'end' it. It can be used, for example, like this:

```js
file = require('fs').createWriteStream('build.ninja');
ninja.saveToStream(file);
file.end();
file.on('finish', function() {console.log('manifest created!')})
```

### `<rule>`

##### `<rule>.run(command)`

Execute the specified `command` (a `String`) when the rule is invoked. You can
refer to Ninja variables like everywhere else.

##### `<rule>.description(desc)`

Provide a description, displayed by Ninja when executing the rule.

##### `<rule>.depfile(file)`

Specify a Makefile-compatible dependency `file` generated by the rule. See the
Ninja documentation for more information on those.

##### `<rule>.restat(doRestart)`

Enable or not the 'restat' of output files. It's a `boolean`.

##### `<rule>.generator(isGenerator)`

Specifiy if the rule is a 'generator' or not. It's a `boolean`.

##### `<rule>.write(stream)`

Write the rule to a steam. Generally you will want to use `<ninja>.save`
instead.

### `<edge>`

##### `<edge>.using(rule)`

Specify the `rule` used to build the edge.

##### `<edge>.from(sources)`

Specify an `Array` or a `String` being the paths of source files for the
edge. Those are directly fed to the rule.

##### `<edge>.need(dependencies)`

Specify an `Array` or a `String` being the paths of dependencies for the
edge. Those trigger a recompilation when modified, but are not direct sources
for the rule.

##### `<edge>.after(orderDeps)`

Specify an `Array` or a `String` being the paths of order-only dependencies for
the edge.

##### `<edge>.assign(name, value)`

Add a variable assignation local to the edge.

##### `<edge>.write(stream)`

Write the rule to a steam. Generally you will want to use `<ninja>.save`
instead.

## Contribute

Please, feel free to fork and submit pull requests.
