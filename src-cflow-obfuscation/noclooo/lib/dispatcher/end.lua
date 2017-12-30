local dispatcher = coroutine.create (function()
  local state = { CHUNK_TYPE.START, unpack(arg or {}) }

  repeat
    state = { (coroutine.wrap (functions[state[1]])) (state[1], select(2, unpack (state))) }
  until state[1] == CHUNK_TYPE.STOP

end)

coroutine.resume (dispatcher)