**CoffeeScript is a little language that compiles into JavaScript.** Underneath that awkward Java-esque patina, JavaScript has always had a gorgeous heart. CoffeeScript is an attempt to expose the good parts of JavaScript in a simple way.

The golden rule of CoffeeScript is: _“It’s just JavaScript”_. The code compiles one-to-one into the equivalent JS, and there is no interpretation at runtime. You can use any existing JavaScript library seamlessly from CoffeeScript (and vice-versa). The compiled output is readable, pretty-printed, and tends to run as fast or faster than the equivalent handwritten JavaScript.

The CoffeeScript compiler goes to great lengths to generate output JavaScript that runs in every JavaScript runtime, but there are exceptions. Use [generator functions](#generator-functions), [`for…from`](#generator-iteration), or [tagged template literals](#tagged-template-literals) only if you know that your [target runtimes can support them](http://kangax.github.io/compat-table/es6/). If you use [modules](#modules), you will need to [use an additional tool to resolve them](#modules-note).

**Latest 1.x Version:** [<%= fullVersion %>](https://github.com/jashkenas/coffeescript/tarball/<%= fullVersion %>)

```bash
npm install -g coffeescript
```

**Upgrade to CoffeeScript 2!** It adds support for [ES2015 classes](/#classes), [`async`/`await`](/#async-functions), [JSX](/#jsx), <span class="nowrap">[object rest/spread syntax](/#splats)</span>, and [JavaScript generated using modern syntax](/#coffeescript-2). [Learn more](/announcing-coffeescript-2/).
