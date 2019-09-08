###
Test multiline

comment
###

### multiline ### ### two ###

delay = (cb) ->
  # `delay` preempts (yields control back to nodejs runtime) by
  # calling setTiemout and calls callback `cb`.
  await setTimeout defer(), 1 # wait here
  #Call cb with no error becaue we waited successfully
  cb null

await delay defer err
process.exit if err then -1 else 0
