some_func = () ->
  inner = (cb) ->
    await setTimeout defer(), 10
    cb null
  return inner

noop = () -> # do nothing
console.log some_func()(noop)