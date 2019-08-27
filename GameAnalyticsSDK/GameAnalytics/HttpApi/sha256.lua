local ASSERTIONS_ENABLED = false -- Whether to run several checks when the module is first loaded and when a message is preprocessed.

local INIT_0_256 = 0x6a09e667
local INIT_1_256 = 0xbb67ae85
local INIT_2_256 = 0x3c6ef372
local INIT_3_256 = 0xa54ff53a
local INIT_4_256 = 0x510e527f
local INIT_5_256 = 0x9b05688c
local INIT_6_256 = 0x1f83d9ab
local INIT_7_256 = 0x5be0cd19

local APPEND_CHAR = string.char(0x80)
local INT_32_CAP = 2^32

local K = { [0] =
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

---Packs four 8-bit integers into one 32-bit integer
local function packUint32(a, b, c, d)
    return bit32.lshift(a, 24)+bit32.lshift(b, 16)+bit32.lshift(c, 8)+d
end

---Unpacks one 32-bit integer into four 8-bit integers
local function unpackUint32(int)
    return bit32.extract(int, 24, 8), bit32.extract(int, 16, 8),
           bit32.extract(int, 08, 8), bit32.extract(int, 00, 8)
end

local function CH(x, y, z)
    -- C ~ (A & (B ~ C)) has less ops than (A & B) ^ (~A & C)
    return bit32.bxor( z, bit32.band(x, bit32.bxor(y, z)) )
end

local function MAJ(x, y, z)
    -- A | (B | C) | (B & C) has less ops than (A & B) ^ (A & C) ^ (B & C)
    return bit32.bor( bit32.band(x, bit32.bor(y, z)), bit32.band(y, z) )
end

local function BSIG0(x)
    return bit32.bxor( bit32.rrotate(x, 2), bit32.rrotate(x, 13), bit32.rrotate(x, 22) )
end

local function BSIG1(x)
    return bit32.bxor( bit32.rrotate(x, 6), bit32.rrotate(x, 11), bit32.rrotate(x, 25) )
end

local function SSIG0(x)
    return bit32.bxor( bit32.rrotate(x, 7), bit32.rrotate(x, 18), bit32.rshift(x, 3) )
end

local function SSIG1(x)
    return bit32.bxor( bit32.rrotate(x, 17), bit32.rrotate(x, 19), bit32.rshift(x, 10) )
end

local function preprocessMessage(message)
    local initMsgLen = #message*8 -- Message length in bits
    local msgLen = initMsgLen+8
    local nulCount = 4 -- This is equivalent to 32 bits.
    -- We're packing 32 bits of size, but the SHA-256 standard calls for 64, meaning we have to add at least 32 0s
    -- Unfortunately 64 bits is not possible due to Lua numbers being doubles
    message = message..APPEND_CHAR
    while (msgLen+64)%512 ~= 0 do
        nulCount = nulCount+1
        msgLen = msgLen+8
    end
    message = message..string.rep("\0", nulCount)
    message = message..string.char(unpackUint32(initMsgLen))
    if ASSERTIONS_ENABLED then
        assert(msgLen%512 == 448, "message length space check")
        assert(#message%64 == 0, "message length check")
    end
    return message
end

local function sha256(message)
    local message = preprocessMessage(message)
    local H0 = INIT_0_256
    local H1 = INIT_1_256
    local H2 = INIT_2_256
    local H3 = INIT_3_256
    local H4 = INIT_4_256
    local H5 = INIT_5_256
    local H6 = INIT_6_256
    local H7 = INIT_7_256

    local W = {}
    for chunkStart = 1, #message, 64 do
        local place = chunkStart
        for t = 0, 15 do
            W[t] = packUint32(string.byte(message, place, place+3))
            place = place+4
        end

        for t = 16, 63 do
            W[t] = SSIG1(W[t-2])+W[t-7]+SSIG0(W[t-15])+W[t-16]
        end

        local a, b, c, d, e, f, g, h = H0, H1, H2, H3, H4, H5, H6, H7

        for t = 0, 63 do
            T1 = h + BSIG1(e) + CH(e, f, g) + K[t] + W[t]
            T2 = BSIG0(a) + MAJ(a, b, c)
            h = g
            g = f
            f = e
            e = d + T1
            d = c
            c = b
            b = a
            a = T1 + T2
        end

        H0 = (H0+a)%INT_32_CAP
        H1 = (H1+b)%INT_32_CAP
        H2 = (H2+c)%INT_32_CAP
        H3 = (H3+d)%INT_32_CAP
        H4 = (H4+e)%INT_32_CAP
        H5 = (H5+f)%INT_32_CAP
        H6 = (H6+g)%INT_32_CAP
        H7 = (H7+h)%INT_32_CAP
    end

    return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", H0, H1, H2, H3, H4, H5, H6, H7)
end

if ASSERTIONS_ENABLED then
    assert(packUint32(255, 167, 125, 235) == 4289166827, "(SHA-256/224) packUint32 check 1")
    assert(packUint32(255, 0, 125, 235) == 4278222315, "(SHA-256/224) packUint32 check 2")

    local b0, b1, b2, b3 = unpackUint32(4278222315)
    assert(b0 == 255, "(SHA-256/224) unpackUint32 check 1")
    assert(b1 == 000, "(SHA-256/224) unpackUint32 check 2")
    assert(b2 == 125, "(SHA-256/224) unpackUint32 check 3")
    assert(b3 == 235, "(SHA-256/224) unpackUint32 check 4")

    -- SHA-256 tests
    assert(sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "(SHA-256) abc hash does not match")
    assert(sha256("") == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "(SHA-256) empty hash does not match")
    assert(sha256("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") == "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1", "(SHA-256) 448 bit alphabet hash does not match")
    assert(sha256("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu") == "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1", "(SHA-256) 896 bit alphabet hash does not match")
    assert(sha256("foo") == "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae", "(SHA-256) foo hash does not match")
    assert(sha256("bar") == "fcde2b2edba56bf408601fb721fe9b5c338d10ee429ea04fae5511b68fbf8fb9", "(SHA-256) bar hash does not match")
    assert(sha256("baz") == "baa5a0964d3320fbc0c6a922140453c8513ea24ab8fd0577034804a967248096", "(SHA-256) baz hash does not match")
    if true then
        assert(sha256(string.rep("e", 199999)) == "434cf81dca15a72777e811ed4ae9144f9272ca3c04ff9c2de1533bbbffed5449", "(SHA-256) e hash does not match")
        assert(sha256(string.rep("a", 1e6)) == "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0", "(SHA-256) million a hash does not match")
    end
end

return sha256