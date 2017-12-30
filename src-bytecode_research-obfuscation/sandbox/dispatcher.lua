local CHUNK_TYPE = {
  START = -1,
  ENTRY = -2,
  STOP  = -3,
  DEBUG = -4,
  _ENV_ = -5,
}

local functions  = {
  [CHUNK_TYPE._ENV_] = {

  },

  [CHUNK_TYPE.START] = function(chunk, arg) -- main
    print "Start\n\n"
    return CHUNK_TYPE.ENTRY
  end,

  [CHUNK_TYPE.DEBUG] = function(chunk, arg) -- main
    print "Debug call"
    return CHUNK_TYPE.STOP
  end,

  [CHUNK_TYPE.STOP] = function(chunk) -- exit
    return
  end,
}

local dispatcher = coroutine.create (function()
  local state = { CHUNK_TYPE.START, unpack(arg or {}) }

  repeat
    state = { (coroutine.wrap (functions[state[1]])) (state[1], select(2, unpack (state))) }
  until state[1] == CHUNK_TYPE.STOP

end)

coroutine.resume (dispatcher)