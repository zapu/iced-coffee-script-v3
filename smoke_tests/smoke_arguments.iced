hello = (a,b,c,cb) ->
  console.log arguments
  await setTimeout defer(), 1
  console.log arguments
  _arguments = [1,2]
  console.log arguments
  console.log _arguments
  cb null

hello 1, 2, 3, () -> console.log("(done)")