# What Is IcedCoffeeScript?

IcedCoffeeScript (ICS) is a system for handling callbacks in event-based code.
There were two existing implementations, one in [the sfslite library for
C++](https://github.com/maxtaco/sfslite), and another in the [tamejs translator
for JavaScript](https://github.com/maxtaco/tamejs).  This extension to
CoffeeScript is a third implementation. The code and translation techniques
are derived from experience with JS, but with some new Coffee-style
flavoring.

This document first presents a "Iced" tutorial (adapted from the JavaScript
version), and then discusses the specifics of the CoffeeScript implementation.

# Installing and Running ICS

ICS is available as an npm package:

    npm install -g iced-coffee-script-3

You can alternatively checkout ICS and install from source:

    git clone https://github.com/maxtaco/coffee-script
    ./bin/cake install

This will give you libraries under `iced-coffee-script-3` and
the binaries `iced3` and `icake3`, which are replacements
for `coffee` and `cake` respectively.  In almost all cases,
`iced3` should serve as a drop-in replacement for `coffee`,
since the ICS language is a superset of CoffeeScript.

For more information about CS and ICS, you can also see
our <a href="http://maxtaco.github.com/coffee-script">brochure page</a>.

# Quick Tutorial and Examples

Here is a simple example that prints "hello" 10 times, with 100ms
delay slots in between:

```coffeescript
# A basic serial loop
for i in [0..10]
  await setTimeout(defer(), 100)
  console.log "hello"
```

There is one new language addition here, the `await ... ` block (or
expression), and also one new primitive function, `defer`.  The two of
them work in concert.  A function must "wait" at the close of a
`await` block until all `defer`rals made in that `await` block are
fulfilled.  The function `defer` returns a callback, and a callee in
an `await` block can fulfill a deferral by simply calling the callback
it was given.  In the code above, there is only one deferral produced
in each iteration of the loop, so after it's fulfilled by `setTimer`
in 100ms, control continues past the `await` block, onto the log line,
and back to the next iteration of the loop.  The code looks and feels
like threaded code, but is still in the asynchronous idiom (if you
look at the rewritten code output by the *coffee* compiler).

This next example does the same, while showcasing power of the
`await..` language addition.  In the example below, the two timers
are fired in parallel, and only when both have fulfilled their deferrals
(after 100ms), does progress continue...

```coffeescript
for i in [0..10]
  await
    setTimeout defer(), 100
    setTimeout defer(), 10
  console.log ("hello");
```

Now for something more useful. Here is a parallel DNS resolver that
will exit as soon as the last of your resolutions completes:

```coffeescript
dns = require("dns");

do_one = (cb, host) ->
  await dns.resolve host, "A", defer(err, ip)
  msg = if err then "ERROR! #{err}" else "#{host} -> #{ip}"
  console.log msg
  cb()

do_all = (lst) ->
  await
    for h in lst
      do_one defer(), h

do_all process.argv[2...]
```

You can run this on the command line like so:

    iced examples/iced/dns.coffee yahoo.com google.com nytimes.com okcupid.com tinyurl.com

And you will get a response:

    yahoo.com -> 72.30.2.43,98.137.149.56,209.191.122.70,67.195.160.76,69.147.125.65
    google.com -> 74.125.93.105,74.125.93.99,74.125.93.104,74.125.93.147,74.125.93.106,74.125.93.103
    nytimes.com -> 199.239.136.200
    okcupid.com -> 66.59.66.6
    tinyurl.com -> 195.66.135.140,195.66.135.139

If you want to run these DNS resolutions in serial (rather than
parallel), then the change from above is trivial: just switch the
order of the `await` and `for` statements above:

```coffeescript
do_all = (lst) ->
  for h in lst
    await
      do_one defer(), h
```

### Slightly More Advanced Example

We've shown parallel and serial work flows, what about something in
between?  For instance, we might want to make progress in parallel on
our DNS lookups, but not smash the server all at once. A compromise is
windowing, which can be achieved in IcedCoffeeScript conveniently in a
number of different ways.  The [2007 academic paper on
tame](http://pdos.csail.mit.edu/~max/docs/tame.pdf) suggests a
technique called a *rendezvous*.  A rendezvous is implemented in
CoffeeScript as a pure CS construct (no rewriting involved), which
allows a program to continue as soon as the first deferral is
fulfilled (rather than the last):

```coffeescript
do_all = (lst, windowsz) ->
  rv = new iced.Rendezvous
  nsent = 0
  nrecv = 0

  while nrecv < lst.length
    if nsent - nrecv < windowsz and  nsent < n
      do_one rv.id(nsent).defer(), lst[nsent]
      nsent++
    else
      await rv.wait defer evid
      console.log "got back lookup nsent=#{evid}"
      nrecv++
```

This code maintains two counters: the number of requests sent, and the
number received.  It keeps looping until the last lookup is received.
Inside the loop, if there is room in the window and there are more to
send, then send; otherwise, wait and harvest.  `Rendezvous.defer`
makes a deferral much like the `defer` primitive, but it can be
labeled with an identifier.  This way, the waiter can know which
deferral has fulfilled.  In this case we use the variable `nsent` as the
defer ID --- it's the ID of this deferral in launch order.  When we
harvest the deferral, `rv.wait` fires its callback with the ID of the
deferral that's harvested.

Note that with windowing, the arrival order might not be the same as
the issue order. In this example, a slower DNS lookup might arrive
after faster ones, even if issued before them.

### Composing Serial And Parallel Patterns

In IcedCoffeeScript, arbitrary composition of serial and parallel control flows is
possible with just normal functional decomposition.  Therefore, we
don't allow direct `await` nesting.  With inline anonymous CoffeeScript
functions, you can concisely achieve interesting patterns.  The code
below launches 10 parallel computations, each of which must complete
two serial actions before finishing:

```coffeescript
f = (n,cb) ->
  await
    for i in [0..n]
      ((cb) ->
        await setTimeout defer(), 5 * Math.random()
        await setTimeout defer(), 4 * Math.random()
        cb()
      )(defer())
  cb()
```

## Language Design Considerations

In sum, the iced additions to CoffeeScript consist of three new keywords:

* **await**, marking off a block or a single statement.
* **defer**, which is quite similar to a normal function call, but is compiled specially
to accommodate argument passing.

These keywords represent the potential for these iced additions to
break existing CoffeeScript code --- any preexisting use of these
keywords as regular function, variable or class names will cause
headaches.

### Debugging and Stack Traces -- Now Greatly Improved!

An oft-cited problem with async-style programming, with ICS or
hand-rolled, is that stack traces are often incomplete or
incomprehensible.  If an exception is caught in a Iced function, the
stack trace will only show the "bottom half" of the call stack, or all
of those functions that are descendents of the main event loop.  The
"top half" of the call stack, telling you "who _really_ called this
function," is probably long gone.

ICS has a workaround to this problem.  When an iced function is
entered, the runtime will find the first argument to the function that
was output by `defer()`.  Such callbacks are annotated to contain the
file, line and function where they were created.  They also are
annotated to hold a refernce to `defer()`-generated callback passed to
the function in which they were created.  This chaining creates an
implicit stack that can be walked when an exception is thrown.

Consider this example:

```coffeescript
iced.catchExceptions()

foo = (y) ->
  await setTimeout defer(), 10
  throw new Error "oh no!"
  y(10)

bar = (x) ->
  await foo defer()
  x()

baz = () ->
  await bar defer()

baz()
```

The function `iced.catchExceptions` sets the `uncaughtException`
handler in Node to print out the standard callstack, and also the Iced
"callstack", and then to exit.  The callback generated by `defer()`
in the function `bar` holds a reference to `x`.  Similarly,
the callback generated in `foo` holds a reference to `y`.
Here's what happens when this program is run:

```
Error: oh no!
    at Deferrals.continuation (/Users/max/src/coffee-script/prog.iced:24:13)
    at Deferrals._call (/Users/max/src/coffee-script/lib/coffee-script/iced.js:86:19)
    at Deferrals._fulfill (/Users/max/src/coffee-script/lib/coffee-script/iced.js:97:23)
    at Object._onTimeout (/Users/max/src/coffee-script/lib/coffee-script/iced.js:53:18)
    at Timer.ontimeout (timers.js:84:39)
Iced 'stack' trace (w/ real line numbers):
   at foo (prog.iced:4)
   at bar (prog.iced:9)
   at baz (prog.iced:13)
```

The first stack trace is the standard Node stacktrace.  It is
inscrutable, since it mainly covers node internals, and has line
numbering relative to the translated file (I still haven't fixed this
bug, sorry). The second stack trace is much better.  It tells the
sequence of Iced calls the lead to this exception.  Line numbers are
relative to the original input file.

The relavant API is as follows:

#### iced.stackWalk cb

Start from the given `cb`, or use the currently active callback
if none was given, and walk up the Iced-generated stack. Return
a list of call site descriptions.  You can call this from your
own exception-handling code.

#### iced.catchExceptions()

Tell the runtime to catch uncaught exceptions, and to print
a Iced-aware stack dump as above.


### The Lowdown on defer

The implementation of `defer` is interesting --- it's trying to
emulate ``call by reference'' in languages like C++ or Java.  Here is an
example that shows off the four different cases required to make this
happen:

```coffeescript
cb = defer x, obj.field, arr[i], rest...
```

And here is the output from the iced `coffee` compiler:

```javascript
cb = __iced_deferrals.defer({
    assign_fn: (function(__slot_1, __slot_2, __slot_3) {
      return function() {
        x = arguments[0];
        __slot_1.field = arguments[1];
        __slot_2[__slot_3] = arguments[2];
        return rest = __slice.call(arguments, 3);
      };
    })(obj, arr, i)
  });
```

The `__iced_deferrals` object is an internal object of type `Deferrals`
that's collecting all calls to `defer` in the current `await` block.
The one in question should fulfill with 3 or more values.  When it does,
it will call into the innermost anonymous function to perform the
appropriate assignments in the original scope. The four cases are:

1. **Simple assignment** --- seen in `x = arguments[0]`.  Here, the
`x` variable is in the scope of the original `defer` call.

1. **Object slot assignment** --- seen in `__slot_1.field = arguments[1]`.
Here, the reference `obj` must be captured at the time of the `defer` call,
and `obj.field` is filled in later.

1. **Array cell assignment** --- seen in `__slot_2[__slot_3] = arguments[2]`.
This of course will work on an array or an object.  Here, the reference
to the array, and the value of the index must be captured when `defer`
is called, and the cell is assigned later.

1. **Splat assignment** --- seen in `res = __slice.call(arguments,3)`.
This is much like a simple assignment, but allows a ``splat'' meaning
assignment of multiple values at once, accessed as an array.

These specifics are also detailed in the code in the `Defer` class,
file `nodes.coffee`.

### Awaits No Longer Work as Expressions

The following do not work and will generate syntax errors at compile time:

```coffeescript
y = (await foo defer x)
```

```coffeescript
x = if true
  await foo defer y
  y
else 10
```

```coffescript
my_func 10, (
  await foo defer y
  y
)
```

That is, you can't treat `await` statements as expressions.
And recursively speaking, you can't treat  any blocks that
contain `await` statements as expressions. Previous versions of
IcedCoffeeScript supported this arcane feature, but it was extremely
difficult to implement properly, and unnecessarily obscured the
control flow of iced programs.

## Translation Technique

Iced Coffee Script 3 translates asynchronous functions and wraps them in
JavaScript generators. Function is considered asynchronous if its code contains
an `async` keyword. Iced runtime is required for the translation, which can be
imported from `iced-runtime-3` package using Node.js `require`, but there are
other options available: consult `iced3 --help` for `--runtime` option.

Iced Coffee Script 3 runs the same compiler pipeline as regular CoffeeScript
compiler ICS is based on. The addition is a translation phase that has to:

1) Find and wrap asynchronous functions in JavaScript generator functions. Also
   wrap them in this-binding functions if usage of `this` is discovered in the
   body of the function.
2) Find and generate `Deferrals` objects for every `await` call. Translate
   every `defer` call to a `Deferrals.defer` call. Output a conditional `yield`
   instruction for every `Deferrals` created (conditional because even though
   call is asynchronous, it might return immediately. Whether given `Deferrals`
   is finished or not is tracked by `Deferrals.defer` code).
3) Output file preamble - either `require` call for `iced-runtime-3` or include
   inlined runtime within the file.
4) Compile as normal. Transformations in 1-3 are merely coffee AST
   transformations. The compilation is then handled to Coffeescript compiler
   for actual Javascript code generation.

## API and Library Documentation

### iced.Rendezvous

The `Rendezvous` is a not a core feature, meaning it's written as a
straight-ahead CoffeeScript library.  It's quite useful for more advanced
control flows, so we've included it in the main runtime library.

The `Rendezvous` is similar to a blocking condition variable (or a
"Hoare style monitor") in threaded programming.

#### iced.Rendezvous.id(i,[multi]).defer slots...

Associate a new deferral with the given Rendezvous, whose deferral ID
is `i`, and whose callbacks slots are supplied as `slots`.  Those
slots can take the two forms of `defer` return as above.  As with
standard `defer`, the return value of the `Rendezvous`'s `defer` is
fed to a function expecting a callback.  As soon as that callback
fires (and the deferral is fulfilled), the provided slots will be
filled with the arguments to that callback.

Also, note the optional boolean flag `multi`.  By default, a function
generated by `defer` can be called only once, and will generate an
error on subsequent calls.  Only with the `multi` flag set to `true`
(and only in the case of a `Rendezvous`), can this restriction be
relaxed.

#### iced.Rendezvous.defer slots...

You don't need to explicitly assign an ID to a deferral generated from a
Rendezvous.  If you don't, one will automatically be assigned, in
ascending order starting from `0`.

#### iced.Rendezvous.wait cb

Wait until the next deferral on this rendezvous is fulfilled.  When it
is, callback `cb` with the ID of the fulfilled deferral.  If an
unclaimed deferral fulfilled before `wait` was called, then `cb` is fired
immediately.

Though `wait` would work with any hand-rolled JS function expecting
a callback, it's meant to work particularly well with *tamejs*'s
`await` function.

#### Example

Here is an example that shows off the different inputs and
outputs of a `Rendezvous`.  It does two parallel DNS lookups,
and reports only when the first returns:

```coffeescript
hosts = [ "okcupid.com", "google.com" ];
ips = errs = []
rv = new iced.Rendezvous
for h,i in hosts
    dns.resolve hosts[i], rv.id(i).defer errs[i], ips[i]

await rv.wait defer which
console.log "#{hosts[which]}  -> #{ips[which]}"
```

### connectors

A *connector* is a function that takes as input
a callback, and outputs another callback.   The best example
is a `timeout`, given here:

#### iced.timeout(cb, time, res = [])

Timeout an arbitrary async operation.

Given a callback `cb`, a time to wait `time`, and an array to output a
result `res`, return another callback.  This connector will set up a
race between the callback returned to the caller, and the timer that
fires after `time` milliseconds.  If the callback returned to the
caller fires first, then fill `res[0] = true;`.  If the timer won
(i.e., if there was a timeout), then fill `res[0] = false;`.

In the following example, we timeout a DNS lookup after 100ms:

```coffeescript
{timeout} = require 'icedlib'
info = [];
host = "pirateWarezSite.ru";
await dns.lookup host, timeout(defer(err, ip), 100, info)
if not info[0]
    console.log "#{host}: timed out!"
else if (err)
    console.log "#{host}: error: #{err}"
else
    console.log "#{host} -> #{ip}"
```

### The Pipeliner library

There's another way to do the windowed DNS lookups we saw earlier ---
you can use the control flow library called `Pipeliner`, which
manages the common pattern of having "m calls total, with only
n of them in flight at once, where m > n."

The Pipeliner class is available in the `icedlib` library:

```coffeescript
{Pipeliner} = require 'icedlib'
pipeliner = new Pipeliner w,s
```

Using the pipeliner, we can rewrite our earlier windowed DNS lookups
as follows:

```coffescript
do_all = (lst, windowsz) ->
  pipeliner = new Pipeliner windowsz
  for x in list
    await pipeliner.waitInQueue defer()
    do_one pipeliner.defer(), x
  await pipeliner.flush defer()
```

The API is as follows:

#### new Pipeliner w, s

Create a new Pipeliner controller, with a window of at most `w` calls
out at once, and waiting `s` seconds before launching each call.  The
default values are `w = 10` and `s = 0`.

#### Pipeliner.waitInQueue c

Wait in a queue until there's room in the window to launch a new call.
The callback `c` will be fulfilled when there is room.

#### Pipeliner.defer args...

Create a new `defer`al for this pipeline, and pass it to whatever
function is doing the actual work.  When the work completes, fulfill
this `defer`al --- that will update the accounting in the pipeliner
class, allowing queued actions to proceed.

#### Pipeliner.flush c

Wait for the pipeline to clear out.  Fulfills the callback `c`
when the last action in the pipeline is done.
