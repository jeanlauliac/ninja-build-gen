'use strict';
var NinjaAssignBuilder, NinjaBuilder, NinjaEdgeBuilder, NinjaRuleBuilder, escape, fs;

require('source-map-support').install();

fs = require('fs');

escape = function(s) {
  return s.replace(/[ :$]/g, function(match) {
    return '$' + match;
  });
};

NinjaAssignBuilder = (function() {
  function NinjaAssignBuilder(name, value) {
    this.name = name;
    this.value = value;
  }

  NinjaAssignBuilder.prototype.write = function(stream) {
    return stream.write("" + this.name + " = " + this.value + "\n");
  };

  return NinjaAssignBuilder;

})();

NinjaEdgeBuilder = (function() {
  function NinjaEdgeBuilder(targets) {
    this.targets = targets;
    this.assigns = [];
    this.rule = 'phony';
    if (typeof this.targets === 'string') {
      this.targets = [this.targets];
    }
  }

  NinjaEdgeBuilder.prototype.using = function(rule) {
    this.rule = rule;
    return this;
  };

  NinjaEdgeBuilder.prototype.from = function(sources) {
    if (typeof sources === 'string') {
      sources = [sources];
    }
    if (this.sources == null) {
      this.sources = sources;
    } else {
      this.sources = this.sources.concat(sources);
    }
    return this;
  };

  NinjaEdgeBuilder.prototype.need = function(dependencies) {
    if (typeof dependencies === 'string') {
      dependencies = [dependencies];
    }
    if (this.dependencies == null) {
      this.dependencies = dependencies;
    } else {
      this.dependencies = this.dependencies.concat(dependencies);
    }
    return this;
  };

  NinjaEdgeBuilder.prototype.after = function(orderDeps) {
    if (typeof orderDeps === 'string') {
      orderDeps = [orderDeps];
    }
    if (this.orderDeps == null) {
      this.orderDeps = orderDeps;
    } else {
      this.orderDeps = this.orderDeps.concat(orderDeps);
    }
    return this;
  };

  NinjaEdgeBuilder.prototype.assign = function(name, value) {
    this.assigns[name] = value;
    return this;
  };

  NinjaEdgeBuilder.prototype.pool = function(pool) {
    this._pool = pool;
    return this;
  };

  NinjaEdgeBuilder.prototype.write = function(stream) {
    var name, value, _ref;
    stream.write("build " + (this.targets.join(' ')) + ": " + this.rule);
    if (this.sources != null) {
      stream.write(' ' + this.sources.join(' '));
    }
    if (this.dependencies != null) {
      stream.write(' | ' + this.dependencies.join(' '));
    }
    if (this.orderDeps != null) {
      stream.write(' || ' + this.orderDeps.join(' '));
    }
    _ref = this.assigns;
    for (name in _ref) {
      value = _ref[name];
      stream.write("\n  " + name + " = " + value);
    }
    stream.write('\n');
    if (this._pool != null) {
      return stream.write("  pool = " + this._pool + "\n");
    }
  };

  return NinjaEdgeBuilder;

})();

NinjaRuleBuilder = (function() {
  function NinjaRuleBuilder(name) {
    this.name = name;
    this.command = '';
  }

  NinjaRuleBuilder.prototype.run = function(command) {
    this.command = command;
    return this;
  };

  NinjaRuleBuilder.prototype.description = function(desc) {
    this.desc = desc;
    return this;
  };

  NinjaRuleBuilder.prototype.depfile = function(file) {
    this.dependencyFile = file;
    return this;
  };

  NinjaRuleBuilder.prototype.restat = function(doRestat) {
    this.doRestat = doRestat;
    return this;
  };

  NinjaRuleBuilder.prototype.generator = function(isGenerator) {
    this.isGenerator = isGenerator;
    return this;
  };

  NinjaRuleBuilder.prototype.pool = function(pool) {
    this._pool = pool;
    return this;
  };

  NinjaRuleBuilder.prototype.write = function(stream) {
    stream.write("rule " + this.name + "\n  command = " + this.command + "\n");
    if (this.desc != null) {
      stream.write("  description = " + this.desc + "\n");
    }
    if (this.doRestat) {
      stream.write("  restat = 1\n");
    }
    if (this.isGenerator) {
      stream.write("  generator = 1\n");
    }
    if (this._pool != null) {
      stream.write("  pool = " + this._pool + "\n");
    }
    if (this.dependencyFile != null) {
      stream.write("  depfile = " + this.dependencyFile + "\n");
      return stream.write("  deps = gcc\n");
    }
  };

  return NinjaRuleBuilder;

})();

NinjaBuilder = (function() {
  function NinjaBuilder(version, buildDir) {
    this.version = version;
    this.buildDir = buildDir;
    this.edges = [];
    this.rules = [];
    this.variables = [];
    this.edgeCount = 0;
    this.ruleCount = 0;
  }

  NinjaBuilder.prototype.header = function(value) {
    this.headerValue = value;
    return this;
  };

  NinjaBuilder.prototype.byDefault = function(name) {
    this.defaultRule = name;
    return this;
  };

  NinjaBuilder.prototype.assign = function(name, value) {
    var clause;
    clause = new NinjaAssignBuilder(name, value);
    this.variables.push(clause);
    return clause;
  };

  NinjaBuilder.prototype.rule = function(name) {
    var clause;
    clause = new NinjaRuleBuilder(name);
    this.rules.push(clause);
    this.ruleCount++;
    return clause;
  };

  NinjaBuilder.prototype.edge = function(targets) {
    var clause;
    clause = new NinjaEdgeBuilder(targets);
    this.edges.push(clause);
    this.edgeCount++;
    return clause;
  };

  NinjaBuilder.prototype.saveToStream = function(stream) {
    var clause, _i, _len, _ref;
    if (this.headerValue != null) {
      stream.write(this.headerValue + '\n\n');
    }
    if (this.version != null) {
      stream.write("ninja_required_version = " + this.version + "\n");
    }
    if (this.buildDir != null) {
      stream.write("builddir=" + this.buildDir + "\n");
    }
    _ref = [].concat(this.rules, this.edges, this.variables);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      clause = _ref[_i];
      clause.write(stream);
    }
    if (this.defaultRule != null) {
      return stream.write("default " + this.defaultRule + "\n");
    }
  };

  NinjaBuilder.prototype.save = function(path, callback) {
    var file;
    file = fs.createWriteStream(path);
    this.saveToStream(file);
    if (callback) {
      file.on('close', function() {
        return callback();
      });
    }
    return file.end();
  };

  return NinjaBuilder;

})();

module.exports = function(version, builddir) {
  return new NinjaBuilder(version, builddir);
};

module.exports.escape = escape;

/*
//@ sourceMappingURL=ninja-build-gen.js.map
*/