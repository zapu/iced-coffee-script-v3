foo = (i, cb) ->
  await delay(defer(), i)
  cb(i)

atest "basic iced waiting", (cb) ->
  i = 1
  await delay defer()
  i++
  cb(i is 2, {})