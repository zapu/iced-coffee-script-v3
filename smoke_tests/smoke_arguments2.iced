delay = (cb, time) -> setTimeout cb, time

func = (cb, test) ->
  _arguments = [1,2,3]
  await delay defer(), 1
  cb(arguments[1])

await func defer(res), 'test'
console.log res == 'test', {}