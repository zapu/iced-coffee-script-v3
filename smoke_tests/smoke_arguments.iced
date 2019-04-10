hello1 = (a,b,c,cb) ->
  console.log arguments
  await setTimeout defer(), 1
  cb null

hello2 = (a,b,c,cb) ->
  await setTimeout defer(), 1
  console.log arguments
  cb null

hello1 10, 20, 30, () -> console.log("(done)")
hello2 11, 22, 33, () -> console.log("(done)")