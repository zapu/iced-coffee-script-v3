C = require('iced-runtime-3').const

class Err
  @make : (msg, sc) ->
    err = new Error msg
    err.sc = sc
    return err

class ESC
  ipush = (e, msg) ->
    if msg?
      e.istack = [] unless e.istack?
      e.istack.push msg

  copy_trace = (src, dst) ->
    dst[C.trace] = src[C.trace]
    dst

  # Error short-circuit connector
  @make : (gcb, where) ->
    where = ESC.make.caller?.name unless where?
    return (lcb) ->
      copy_trace lcb, (err, args...) ->
        if not err? then lcb args...
        else if not gcb.__esc
          gcb.__esc = true
          ipush err, where ? "unnamed error"
          gcb err

class ExampleHandler
  _unpack_args : (cb) ->
    try
      @_obj = JSON.parse @_arg
    catch
      err = Err.make "Unable to parse arguments", 1
    cb err

  _do_foo : (cb) ->
    esc = ESC.make cb
    await process.nextTick esc defer()
    cb null

  do_fail : (cb) ->
    esc = ESC.make cb
    await process.nextTick esc defer()
    throw Err.make "oops", 2

  _handle : (cb) ->
    esc = ESC.make cb
    await @_unpack_args esc defer()
    await @_do_foo esc defer()
    await @do_fail esc defer()
    cb null

if require.main is module
  handler = new ExampleHandler()
  handler._arg = "{}"
  await handler._handle defer err


