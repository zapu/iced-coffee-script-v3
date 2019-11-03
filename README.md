
                                      ICED

                                       _____       __  __
                                      / ____|     / _|/ _|
     .- ----------- -.               | |     ___ | |_| |_ ___  ___
    (  (ice cubes)    )              | |    / _ \|  _|  _/ _ \/ _ \
    |`-..________ ..-'|              | |___| (_) | | | ||  __/  __/
    |                 |               \_____\___/|_| |_| \___|\___|
    |                 ;--.
    |                (__  \            _____           _       _
    |                 | )  )          / ____|         (_)     | |
    |                 |/  /          | (___   ___ _ __ _ _ __ | |_
    |                 (  /            \___ \ / __| '__| | '_ \| __|
    |                 |/              ____) | (__| |  | | |_) | |_
    |                 |              |_____/ \___|_|  |_| .__/ \__|
     `-.._________..-'                                  | |
                                                        |_|

CoffeeScript is a little language that compiles into JavaScript.
IcedCoffeeScript is a superset of CoffeeScript that adds two new
keywords: `await` and `defer`.

IcedCoffeeScript is based on CoffeeScript V1 - the one without Javascript ES6
support. Based on top of last CoffeeScript V1, version 1.12.8, git commit id:
`943579a23943ce62e8d2e3dbc868f22bac773f36`.

## Iced v3 Alpha

We're current alpha-testing Iced v3, which emits ES6 with `yield`s and generators.
Relative to Iced v2, this version stays much closer to the CoffeeScript main body of
code, and emits much simpler code. The downside is that the target must run ES6, or
be transpiled into ES5 with a further step not handled by this package.

## **iced-types-wip** branch

This branch is also testing an attempt at correctly preserving type comments, so
Iced code can be typed using JSDoc comments and verified with TypeScript.

To do that, we are also working on enabling `let` bindings instead of hoisting everything to the top of the scope and declaring using `var` keywords. This will allow the compiler to emit proper declaration with type, e.g.:
```
#@type{(a : number, b : number) => string}
func = (a,b) -> "#{a} + #{b}"
```
compiles to:
```
/**@type{(a : number, b : number) => string} */
let func = function(a,b) { return a + " + " + b }
```

Note that in order to excercise our `let` scoping, we are emitting `let`-bindings whenever possible, not just when a type comment is present. If a `let`-binding cannot be done with keeping old Coffee scoping rules, we are falling back to `var`, e.g.:
```
try
  a = read()
catch e
  process.exit()
console.log a
```
compiles to:
```
var a;
try { a = read(); }
catch (e) { process.exit(); }
console.log(a);
```
(even though `a` is first assigned to in `try` block, it's used outside of it, so use `var` here)

## How to Build

```
./bin/cake build
```

## Installation

If you have the node package manager, npm, installed:

```shell
npm install -g iced-coffee-script-3
```

Leave off the `-g` if you don't wish to install globally. If you don't wish to use npm:

```shell
git clone -b iced3 https://github.com/maxtaco/coffeescript.git
sudo coffeescript/bin/cake install
```

## Getting Started

Run REPL:

```shell
iced3
```

Execute a script:

```shell
iced3 /path/to/script.iced
```

Compile a script:

```shell
iced3 -c /path/to/script.iced
```

For documentation, usage, and examples, see: http://coffeescript.org/

To suggest a feature or report a bug: http://github.com/maxtaco/coffeescript/issues

The source repository: https://github.com/maxtaco/coffeescript.git
