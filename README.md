# Ninja-build Generator

Programmatically create [Ninja](http://martine.github.io/ninja/) build-system
files from JavaScript. This can be used into any kind of project, though (Ruby,
Python, or even C++, why not...). In any case that's always preferable to use
`npm` to handle the package installation.

# Install

Most of the time, you'll add it to the `devDependencies` of your
`package.json`:

```bash
$ npm install ninja-build-gen --save-dev
```

You may typically want to install the
[ninja-build](https://github.com/undashes/ninja-build) as well. Indeed, this
package does not include the Ninja build system.

Generally, you should not need this package for package distribution (instead
of being in `dependencies`), since it's mostly useful to handle the minimal
compilation of assets, like CoffeeScript files. Published packages should
contain the compiled JS files (or CSS, etc.), not the sources (nor the tests).

# Usage

This is typically useful to create a `configure` script. In this script, let's
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
recompiled upon invocation.

# Limitations

This package is only here to make easier the creation of Ninja build files,
but it does not provide any high-level features, and won't ever provide them
(that's out of scope). That is, no wildcards, no globbing and file lookup;
just streamlined Ninja build file generation.

# Contribute

Feel free to fork and submit pull requests.
