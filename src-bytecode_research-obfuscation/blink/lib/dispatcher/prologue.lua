local CHUNK_TYPE = {
  START = -1;
  STOP  = -2;
  DEBUG = -3;
}

local functions  = {
  [CHUNK_TYPE.START] = function(chunk, arg) -- main
    print "Start\n\n"
    return CHUNK_TYPE.DEBUG
  end,

  [CHUNK_TYPE.DEBUG] = function(chunk, arg) -- main
    print "Debug call"
    return CHUNK_TYPE.STOP
  end,

  [CHUNK_TYPE.STOP] = function(chunk) -- exit
    return
  end,
}