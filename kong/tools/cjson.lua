local cjson = require "cjson.safe".new()
local constants = require "kong.constants"


cjson.decode_array_with_array_mt(true)
cjson.encode_sparse_array(nil, nil, 2^15)
cjson.encode_number_precision(constants.CJSON_MAX_PRECISION)


local _M = {}


_M.encode = cjson.encode
_M.decode_with_array_mt = cjson.decode


_M.array_mt = cjson.array_mt


return _M
