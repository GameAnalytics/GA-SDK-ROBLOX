local ASSERTIONS_ENABLED = false -- Whether to run several checks when the module is first loaded

local INNER_PADDING_CHAR = string.char(0x36)
local OUTER_PADDING_CHAR = string.char(0x5C)

local binaryStringMap = {} -- For the sake of speed of converting hexes to strings, there's a map of the conversions here
for i = 0, 255 do
    binaryStringMap[string.format("%02x", i)] = string.char(i)
end

--- XORs two strings together on a byte level
local function xorStrings(str1, str2)
    local output = {}
    for i = 1, #str1 do
        output[i] = string.char(bit32.bxor(string.byte(str1, i), string.byte(str2, i)))
    end
    return table.concat(output)
end

--- Converts hex strings to their binary equivalent
local function hexToBinary(string)
    return ( string.gsub(string, "%x%x", binaryStringMap) )
end

--- Outputs a HMAC string (in hex) given a key, message, hashing function, and block size.
--- Optionally accepts an output size to truncate the HMAC to, and a boolean to indicate whether to output the data as a binary string or not.
--- Both blockSize and outputSize are in bytes for ease of computation.
local function hmac(key, message, hash, blockSize, outputSize, asBinaryData)
    local innerPadding = string.rep(INNER_PADDING_CHAR, blockSize)
    local outerPadding = string.rep(OUTER_PADDING_CHAR, blockSize)

    if #key > blockSize then
        key = hexToBinary(hash(key))
    end
    if #key < blockSize then
        key = key..string.rep("\0", blockSize-#key)
    end
    local outerKey = xorStrings(key, outerPadding)
    local innerKey = xorStrings(key, innerPadding)

    local mac = hash( outerKey..hexToBinary(hash(innerKey..message)) )

    local output;
    if outputSize then
        output = string.sub(mac, 1, outputSize*2) -- Today's gross hack is brought to you by every byte being represented by two hex digits
    else
        output = mac
    end
    if asBinaryData then
        return hexToBinary(output)
    else
        return output
    end
end

if ASSERTIONS_ENABLED then
    local sha256 = require(script.Parent.sha256)
    -- SHA-256 tests (https://tools.ietf.org/html/rfc4231)
    assert(hmac(string.rep(string.char(0x0b), 20), "Hi There", sha256, 64) == "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7", "(HMAC-SHA-256) RFC test case 1 hash does not match")

    assert(hmac("Jefe", "what do ya want for nothing?", sha256, 64) == "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843", "(HMAC-SHA-256) RFC test case 2 hash does not match")

    assert(hmac(string.rep(string.char(0xaa), 20), string.rep(string.char(0xdd), 50), sha256, 64) == "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe", "(HMAC-SHA-256) RFC test case 3 hash does not match")

    assert(hmac(hexToBinary("0102030405060708090a0b0c0d0e0f10111213141516171819"), string.rep(string.char(0xcd), 50), sha256, 64) == "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b", "(HMAC-SHA-256) RFC test case 4 hash does not match")

    assert(hmac(string.rep(string.char(0x0c), 20), "Test With Truncation", sha256, 64, 16) == "a3b6167473100ee06e0c796c2955552b", "(HMAC-SHA-256) RFC test case 5 hash does not match")

    assert(hmac(string.rep(string.char(0xaa), 131), "Test Using Larger Than Block-Size Key - Hash Key First", sha256, 64) == "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54", "(HMAC-SHA-256) RFC test case 6 hash does not match")

    assert(hmac(string.rep(string.char(0xaa), 131), "This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.", sha256, 64) == "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2", "(HMAC-SHA-256) RFC test case 7 hash does not match")

    -- Tests explicitly for binary data output
    assert(hmac(string.rep(string.char(0x0b), 20), "Hi There", sha256, 64, nil, true) == "\176\52\76\97\216\219\56\83\92\168\175\206\175\11\241\43\136\29\194\0\201\131\61\167\38\233\55\108\46\50\207\247", "(HMAC-SHA-256) RFC test case 1 hash as binary does not match")

    assert(hmac("Jefe", "what do ya want for nothing?", sha256, 64, nil, true) == "\91\220\193\70\191\96\117\78\106\4\36\38\8\149\117\199\90\0\63\8\157\39\57\131\157\236\88\185\100\236\56\67", "(HMAC-SHA-256) RFC test case 2 hash as binary does not match")

    assert(hmac(string.rep(string.char(0xaa), 20), string.rep(string.char(0xdd), 50), sha256, 64, nil, true) == "\119\62\169\30\54\128\14\70\133\77\184\235\208\145\129\167\41\89\9\139\62\248\193\34\217\99\85\20\206\213\101\254", "(HMAC-SHA-256) RFC test case 3 hash as binary does not match")

    assert(hmac(hexToBinary("0102030405060708090a0b0c0d0e0f10111213141516171819"), string.rep(string.char(0xcd), 50), sha256, 64, nil, true) == "\130\85\138\56\154\68\60\14\164\204\129\152\153\242\8\58\133\240\250\163\229\120\248\7\122\46\63\244\103\41\102\91", "(HMAC-SHA-256) RFC test case 4 hash as binary does not match")

    assert(hmac(string.rep(string.char(0x0c), 20), "Test With Truncation", sha256, 64, 16, true) == "\163\182\22\116\115\16\14\224\110\12\121\108\41\85\85\43", "(HMAC-SHA-256) RFC test case 5 hash as binary does not match")

    assert(hmac(string.rep(string.char(0xaa), 131), "Test Using Larger Than Block-Size Key - Hash Key First", sha256, 64, nil, true) == "\96\228\49\89\30\224\182\127\13\138\38\170\203\245\183\127\142\11\198\33\55\40\197\20\5\70\4\15\14\227\127\84", "(HMAC-SHA-256) RFC test case 6 hash as binary does not match")

    assert(hmac(string.rep(string.char(0xaa), 131), "This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.", sha256, 64, nil, true) == "\155\9\255\167\27\148\47\203\39\99\95\188\213\176\233\68\191\220\99\100\79\7\19\147\138\127\81\83\92\58\53\226", "(HMAC-SHA-256) RFC test case 7 hash as binary does not match")
end

return hmac