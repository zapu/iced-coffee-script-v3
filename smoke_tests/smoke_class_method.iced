class Waiter
  constructor : () -> 
    @waited = false
    @waiting = false

  wait : ({time}, cb) ->
    @waiting = true
    await setTimeout defer(), time
    @waited = true
    @waiting = false
    cb.call @, null

w = new Waiter()
ret = w.wait {time: 10}, ->
  console.log "hi, @ is bound:", w is @, "w is:", @

console.log "immediate return:", ret, "w is:", w