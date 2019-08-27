local ASSERTIONS_ENABLED = true -- Whether to run several checks when the module is first loaded

local CHAR_SET = { [0] =
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "/",
}

local REVERSE_CHAR_SET = {
    [65] = 0, [66] = 1, [67] = 2, [68] = 3, [69] = 4, [70] = 5, [71] = 6, [72] = 7, [73] = 8, [74] = 9, [75] = 10, [76] = 11, [77] = 12, [78] = 13,
    [79] = 14, [80] = 15, [81] = 16, [82] = 17, [83] = 18, [84] = 19, [85] = 20, [86] = 21, [87] = 22, [88] = 23, [89] = 24, [90] = 25, [97] = 26,
    [98] = 27, [99] = 28, [100] = 29, [101] = 30, [102] = 31, [103] = 32, [104] = 33, [105] = 34, [106] = 35, [107] = 36, [108] = 37, [109] = 38, [110] = 39,
    [111] = 40, [112] = 41, [113] = 42, [114] = 43, [115] = 44, [116] = 45, [117] = 46, [118] = 47, [119] = 48, [120] = 49, [121] = 50, [122] = 51, [48] = 52,
    [49] = 53, [50] = 54, [51] = 55, [52] = 56, [53] = 57, [54] = 58, [55] = 59, [56] = 60, [57] = 61, [43] = 62, [47] = 63,
}

--- Packs three 8-bit integers into one unsigned 24-bit integer.
local function packUint24FromOctets(a, b, c)
    return bit32.lshift(a, 16)+bit32.lshift(b, 8)+c
end

--- Packs four 6-bit integers into one unsigned 24-bit integer
local function packUint24FromSextets(a, b, c, d)
    return bit32.lshift(a, 18)+bit32.lshift(b, 12)+bit32.lshift(c, 6)+d
end

--- Encodes `input` from plaintext into base64, optionally omitting padding
local function encodeBase64(input, omitPadding)
    local output = {}
    local padding = #input%3

    local c = 1
    for i = 1, #input, 3 do
        local b1, b2, b3 = string.byte(input, i, i+2)
        local packed = packUint24FromOctets(b1, b2 or 0, b3 or 0)
        output[c] = CHAR_SET[bit32.extract(packed, 18, 6)]
        output[c+1] = CHAR_SET[bit32.extract(packed, 12, 6)]
        if b2 then
            output[c+2] = CHAR_SET[bit32.extract(packed, 6, 6)]
            if b3 then
                output[c+3] = CHAR_SET[bit32.extract(packed, 0, 6)]
            end
        end
        c = c+4
    end
    if not omitPadding then
        if padding == 2 then
            output[c-1] = "="
        elseif padding == 1 then
            output[c-2] = "=="
        end
    end
    return table.concat(output)
end

--- Decodes `input` from base64 to plaintext.
local function decodeBase64(input)
    assert(not (string.find(input, "[^%w+/=]")), "input contains invalid characters")

    local output = {}

    local c = 1
    for i = 1, #input, 4 do
        local b1, b2, b3, b4 = string.byte(input, i, i+3)
        b1 = REVERSE_CHAR_SET[b1]
        b2 = REVERSE_CHAR_SET[b2]
        b3 = REVERSE_CHAR_SET[b3]
        b4 = REVERSE_CHAR_SET[b4]

        local packed = packUint24FromSextets(b1, b2, b3 or 0, b4 or 0)
        output[c] = string.char(bit32.extract(packed, 16, 8))
        if not b3 then
            break
        end
        output[c+1] = string.char(bit32.extract(packed, 8, 8))
        if not b4 then
            break
        end
        output[c+2] = string.char(bit32.extract(packed, 0, 8))
        c = c+3
    end
    return table.concat(output)
end

if ASSERTIONS_ENABLED then
    assert(packUint24FromOctets(77, 97, 110) == 5071214, "(Base64) packUint24FromOctets check")
    assert(packUint24FromSextets(19, 22, 5, 46) == 5071214, "(Base64) packUint24FromSextets check")

    assert(encodeBase64("Man") == "TWFu", "(Base64) Man failed to encode into TWFu")
    assert(encodeBase64("Ma") == "TWE=", "(Base64) Ma failed to encode into TWE=")
    assert(encodeBase64("M") == "TQ==", "(Base64) M failed to encode into TQ==")
    assert(encodeBase64("Baby shark") == "QmFieSBzaGFyaw==", "(Base64) Baby shark failed to encode into QmFieSBzaGFyaw==")
    assert(encodeBase64("Almost heaven, West Virginia\nBlue Ridge Mountains, Shenandoah River\nLife is old there, older than the trees\nYounger than the mountains, blowing like a breeze\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nAll my memories gather round her\nMiner's lady, stranger to blue water\nDark and dusty, painted on the sky\nMisty taste of moonshine, teardrop in my eye\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nI hear her voice, in the morning hour she calls me\nThe radio reminds me of my home far away\nAnd driving down the road I get a feeling\nThat I should have been home yesterday, yesterday\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nTake me home, down country roads\nTake me home, down country roads") == "QWxtb3N0IGhlYXZlbiwgV2VzdCBWaXJnaW5pYQpCbHVlIFJpZGdlIE1vdW50YWlucywgU2hlbmFuZG9haCBSaXZlcgpMaWZlIGlzIG9sZCB0aGVyZSwgb2xkZXIgdGhhbiB0aGUgdHJlZXMKWW91bmdlciB0aGFuIHRoZSBtb3VudGFpbnMsIGJsb3dpbmcgbGlrZSBhIGJyZWV6ZQpDb3VudHJ5IHJvYWRzLCB0YWtlIG1lIGhvbWUKVG8gdGhlIHBsYWNlIEkgYmVsb25nCldlc3QgVmlyZ2luaWEsIG1vdW50YWluIG1hbWEKVGFrZSBtZSBob21lLCBjb3VudHJ5IHJvYWRzCkFsbCBteSBtZW1vcmllcyBnYXRoZXIgcm91bmQgaGVyCk1pbmVyJ3MgbGFkeSwgc3RyYW5nZXIgdG8gYmx1ZSB3YXRlcgpEYXJrIGFuZCBkdXN0eSwgcGFpbnRlZCBvbiB0aGUgc2t5Ck1pc3R5IHRhc3RlIG9mIG1vb25zaGluZSwgdGVhcmRyb3AgaW4gbXkgZXllCkNvdW50cnkgcm9hZHMsIHRha2UgbWUgaG9tZQpUbyB0aGUgcGxhY2UgSSBiZWxvbmcKV2VzdCBWaXJnaW5pYSwgbW91bnRhaW4gbWFtYQpUYWtlIG1lIGhvbWUsIGNvdW50cnkgcm9hZHMKSSBoZWFyIGhlciB2b2ljZSwgaW4gdGhlIG1vcm5pbmcgaG91ciBzaGUgY2FsbHMgbWUKVGhlIHJhZGlvIHJlbWluZHMgbWUgb2YgbXkgaG9tZSBmYXIgYXdheQpBbmQgZHJpdmluZyBkb3duIHRoZSByb2FkIEkgZ2V0IGEgZmVlbGluZwpUaGF0IEkgc2hvdWxkIGhhdmUgYmVlbiBob21lIHllc3RlcmRheSwgeWVzdGVyZGF5CkNvdW50cnkgcm9hZHMsIHRha2UgbWUgaG9tZQpUbyB0aGUgcGxhY2UgSSBiZWxvbmcKV2VzdCBWaXJnaW5pYSwgbW91bnRhaW4gbWFtYQpUYWtlIG1lIGhvbWUsIGNvdW50cnkgcm9hZHMKQ291bnRyeSByb2FkcywgdGFrZSBtZSBob21lClRvIHRoZSBwbGFjZSBJIGJlbG9uZwpXZXN0IFZpcmdpbmlhLCBtb3VudGFpbiBtYW1hClRha2UgbWUgaG9tZSwgY291bnRyeSByb2FkcwpUYWtlIG1lIGhvbWUsIGRvd24gY291bnRyeSByb2FkcwpUYWtlIG1lIGhvbWUsIGRvd24gY291bnRyeSByb2Fkcw==", "(Base64) Country Roads failed to encode properly")

    assert(encodeBase64("Man", true) == "TWFu", "(Base64) Man with padding disabled failed to encode into TWFu")
    assert(encodeBase64("Ma", true) == "TWE", "(Base64) Ma with padding disabled failed to encode into TWE")
    assert(encodeBase64("M", true) == "TQ", "(Base64) M with padding disabled failed to encode into TQ")
    assert(encodeBase64("Baby shark", true) == "QmFieSBzaGFyaw", "(Base64) Baby shark with padding disabled failed to encode into QmFieSBzaGFyaw")

    assert(encodeBase64("") == "", "(Base64) Empty string failed to encode properly")
    assert(encodeBase64("f") == "Zg==", "(Base64) f failed to encode into Zg==")
    assert(encodeBase64("fo") == "Zm8=", "(Base64) fo failed to encode into Zm8=")
    assert(encodeBase64("foo") == "Zm9v", "(Base64) foo failed to encode into Zm9v")
    assert(encodeBase64("foob") == "Zm9vYg==", "(Base64) foob failed to encode into Zm9vYg==")
    assert(encodeBase64("fooba") == "Zm9vYmE=", "(Base64) fooba failed to encode into Zm9vYmE=")
    assert(encodeBase64("foobar") == "Zm9vYmFy", "(Base64) foobar failed to encode into Zm9vYmFy")

    assert(encodeBase64("A\0B") == "QQBC", "(Base64) A\\0B failed to encode into QQBC")
    assert(encodeBase64("A\n\t\v") == "QQoJCw==", "(Base64) A\\n\\t\\v failed to encode into QQoJCw==")
    assert(encodeBase64("☺☻") == "4pi64pi7", "(Base64) ☺☻ failed to encode into 4pi64pi7")
    assert(encodeBase64("テスト") == "44OG44K544OI", "(Base64) テスト failed to encode into 44OG44K544OI")

    assert(decodeBase64("TWFu") == "Man", "(Base64) Man failed to decode into TWFu")
    assert(decodeBase64("TWE=") == "Ma", "(Base64) Ma failed to decode into TWE=")
    assert(decodeBase64("TQ==") == "M", "(Base64) M failed to decode into TQ==")
    assert(decodeBase64("QmFieSBzaGFyaw==") == "Baby shark", "(Base64) Baby shark failed to decode into QmFieSBzaGFyaw==")
    assert(decodeBase64("QWxtb3N0IGhlYXZlbiwgV2VzdCBWaXJnaW5pYQpCbHVlIFJpZGdlIE1vdW50YWlucywgU2hlbmFuZG9haCBSaXZlcgpMaWZlIGlzIG9sZCB0aGVyZSwgb2xkZXIgdGhhbiB0aGUgdHJlZXMKWW91bmdlciB0aGFuIHRoZSBtb3VudGFpbnMsIGJsb3dpbmcgbGlrZSBhIGJyZWV6ZQpDb3VudHJ5IHJvYWRzLCB0YWtlIG1lIGhvbWUKVG8gdGhlIHBsYWNlIEkgYmVsb25nCldlc3QgVmlyZ2luaWEsIG1vdW50YWluIG1hbWEKVGFrZSBtZSBob21lLCBjb3VudHJ5IHJvYWRzCkFsbCBteSBtZW1vcmllcyBnYXRoZXIgcm91bmQgaGVyCk1pbmVyJ3MgbGFkeSwgc3RyYW5nZXIgdG8gYmx1ZSB3YXRlcgpEYXJrIGFuZCBkdXN0eSwgcGFpbnRlZCBvbiB0aGUgc2t5Ck1pc3R5IHRhc3RlIG9mIG1vb25zaGluZSwgdGVhcmRyb3AgaW4gbXkgZXllCkNvdW50cnkgcm9hZHMsIHRha2UgbWUgaG9tZQpUbyB0aGUgcGxhY2UgSSBiZWxvbmcKV2VzdCBWaXJnaW5pYSwgbW91bnRhaW4gbWFtYQpUYWtlIG1lIGhvbWUsIGNvdW50cnkgcm9hZHMKSSBoZWFyIGhlciB2b2ljZSwgaW4gdGhlIG1vcm5pbmcgaG91ciBzaGUgY2FsbHMgbWUKVGhlIHJhZGlvIHJlbWluZHMgbWUgb2YgbXkgaG9tZSBmYXIgYXdheQpBbmQgZHJpdmluZyBkb3duIHRoZSByb2FkIEkgZ2V0IGEgZmVlbGluZwpUaGF0IEkgc2hvdWxkIGhhdmUgYmVlbiBob21lIHllc3RlcmRheSwgeWVzdGVyZGF5CkNvdW50cnkgcm9hZHMsIHRha2UgbWUgaG9tZQpUbyB0aGUgcGxhY2UgSSBiZWxvbmcKV2VzdCBWaXJnaW5pYSwgbW91bnRhaW4gbWFtYQpUYWtlIG1lIGhvbWUsIGNvdW50cnkgcm9hZHMKQ291bnRyeSByb2FkcywgdGFrZSBtZSBob21lClRvIHRoZSBwbGFjZSBJIGJlbG9uZwpXZXN0IFZpcmdpbmlhLCBtb3VudGFpbiBtYW1hClRha2UgbWUgaG9tZSwgY291bnRyeSByb2FkcwpUYWtlIG1lIGhvbWUsIGRvd24gY291bnRyeSByb2FkcwpUYWtlIG1lIGhvbWUsIGRvd24gY291bnRyeSByb2Fkcw==") == "Almost heaven, West Virginia\nBlue Ridge Mountains, Shenandoah River\nLife is old there, older than the trees\nYounger than the mountains, blowing like a breeze\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nAll my memories gather round her\nMiner's lady, stranger to blue water\nDark and dusty, painted on the sky\nMisty taste of moonshine, teardrop in my eye\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nI hear her voice, in the morning hour she calls me\nThe radio reminds me of my home far away\nAnd driving down the road I get a feeling\nThat I should have been home yesterday, yesterday\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nCountry roads, take me home\nTo the place I belong\nWest Virginia, mountain mama\nTake me home, country roads\nTake me home, down country roads\nTake me home, down country roads", "(Base64) Country Roads failed to decode properly")

    assert(decodeBase64("TWE") == "Ma", "(Base64) TWE failed to decode into Ma")
    assert(decodeBase64("TQ") == "M", "(Base64) TQ failed to decode into M")
    assert(decodeBase64("QmFieSBzaGFyaw") == "Baby shark", "(Base64) QmFieSBzaGFyaw failed to decode into Baby shark")

    assert(decodeBase64("") == "", "(Base64) Empty string failed to decode")
    assert(decodeBase64("Zg==") == "f", "(Base64) Zg== failed to decode into f")
    assert(decodeBase64("Zm8=") == "fo", "(Base64) Zm8= failed to decode into fo")
    assert(decodeBase64("Zm9v") == "foo", "(Base64) Zm9v failed to decode into foo")
    assert(decodeBase64("Zm9vYg==") == "foob", "(Base64) Zm9vYg== failed to decode into foob")
    assert(decodeBase64("Zm9vYmE=") == "fooba", "(Base64) Zm9vYmE= failed to decode into fooba")
    assert(decodeBase64("Zm9vYmFy") == "foobar", "(Base64) Zm9vYmFy failed to decode into foobar")

    assert(decodeBase64("QQBC") == "A\0B", "(Base64) QQBC failed to decode into A\\0B")
    assert(decodeBase64("QQoJCw==") == "A\n\t\v", "(Base64) QQoJCw== failed to decode into A\\n\\t\\v")
    assert(decodeBase64("4pi64pi7") == "☺☻", "(Base64) 4pi64pi7 failed to decode into ☺☻")
    assert(decodeBase64("44OG44K544OI") == "テスト", "(Base64) 44OG44K544OI failed to decode into テスト")
end

return {
    encode = encodeBase64,
    decode = decodeBase64,
}
