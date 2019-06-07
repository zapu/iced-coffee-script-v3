util = require 'util'

compileAndGetTraceNames = (src) ->
  traces = []
  nodes = CoffeeScript.nodes src, { bare : true }
  nodes.compile()
  nodes.traverseChildren true, (x) ->
    if x.icedTraceName
      traces.push x.icedTraceName()
  traces.filter((x) -> x)

test "nested functions 1", ->
  src = """
    foo = ->
      y = ->
    """
  traces = compileAndGetTraceNames(src)
  # TODO: Ideally, instead of 'y' we want 'foo.y' or something similar.
  deepEqual traces, ['foo', 'y']

test "class methods", ->
  src = """
    class B
      y : ->
      z = ->
    """
  traces = compileAndGetTraceNames(src)
  deepEqual traces, ['B::y', 'z']

  src = """
    exports.B = class C
      y : ->
      z = ->
    """
  traces = compileAndGetTraceNames(src)
  deepEqual traces, ['C::y', 'z']

test "object method", ->
  src = "exports.x = ->"
  traces = compileAndGetTraceNames(src)
  deepEqual traces, ['exports.x']

  src = "exports.x = x = ->"
  traces = compileAndGetTraceNames(src)
  deepEqual traces, ['x']

test "object methods 2", ->
  src = """
    zzz =
      foo : ->
      bar : ->
  """
  traces = compileAndGetTraceNames(src)
  # TODO: We want `zzz.foo` and `zzz.bar` instead.
  deepEqual traces, ['foo', 'bar']
