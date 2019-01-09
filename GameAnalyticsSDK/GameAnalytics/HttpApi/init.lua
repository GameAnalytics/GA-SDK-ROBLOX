local RunService = game:GetService("RunService")
local validation = require(script.Parent.Validation)
local version = require(script.Parent.Version)

local http_api = {
    protocol = "https",
    hostName = "api.gameanalytics.com",
    version = "v2",
    initializeUrlPath = "init",
    eventsUrlPath = "events",
    EGAHTTPApiResponse = {
        NoResponse=0,
        BadResponse=1,
        RequestTimeout=2,
        JsonEncodeFailed=3,
        JsonDecodeFailed=4,
        InternalServerError=5,
        BadRequest=6,
        Unauthorized=7,
        UnknownResponseCode=8,
        Ok=9
    }
}

local HTTP = game:GetService("HttpService")
local logger = require(script.Parent.Logger)
local baseUrl = (RunService:IsStudio() and "http" or http_api.protocol) .. "://" .. (RunService:IsStudio() and "sandbox-" or "") .. http_api.hostName .. "/" .. http_api.version
local encodingReady = false

local Encoding = {}

local function getInitAnnotations(playerData, playerId)
    local initAnnotations = {
        ["user_id"] = tostring(playerId),
        ["sdk_version"] = "roblox " .. version.SdkVersion,
        ["os_version"] = playerData.OS,
        ["platform"] = playerData.Platform
    }

    return initAnnotations
end

local function encode(payload, secretKey)
    if not encodingReady then
        Encoding.lockbox = require(script.Encoding.lockbox)
        Encoding.lockbox.bit = require(script.Encoding.bit).bit
        Encoding.array = require(Encoding.lockbox.util.array)
        Encoding.stream = require(Encoding.lockbox.util.stream)
        Encoding.base64 = require(Encoding.lockbox.util.base64)
        Encoding.hmac = require(Encoding.lockbox.mac.hmac)
        Encoding.sha256 = require(Encoding.lockbox.digest.sha2_256)
        encodingReady = true
    end

    --Validate
    if not secretKey then logger:w("Error encoding, invalid SecretKey") return end

    --Encode
    local hmacBuilder = Encoding.hmac()
        .setBlockSize(64)
        .setDigest(Encoding.sha256)
        .setKey(Encoding.array.fromString(RunService:IsStudio() and "16813a12f718bc5c620f56944e1abc3ea13ccbac" or secretKey))
        .init()
        .update(Encoding.stream.fromString(payload))
        .finish()

    return Encoding.base64.fromArray(hmacBuilder.asBytes())
end

local function processRequestResponse(response, requestId)
    local statusCode = response.StatusCode
    local body = response.Body

    if not body or #body == 0 then
        logger:d(requestId .. " request. failed. Might be no connection. Status code: " .. tostring(statusCode))
        return http_api.EGAHTTPApiResponse.NoResponse
    end

    if statusCode == 200 then
        return http_api.EGAHTTPApiResponse.Ok
    elseif statusCode == 0 or statusCode == 401 then
        logger:d(requestId .. " request. 401 - Unauthorized.")
        return http_api.EGAHTTPApiResponse.Unauthorized
    elseif statusCode == 400 then
        logger:d(requestId .. " request. 400 - Bad Request.")
        return http_api.EGAHTTPApiResponse.BadRequest
    elseif statusCode == 500 then
        logger:d(requestId .. " request. 500 - Internal Server Error.")
        return http_api.EGAHTTPApiResponse.InternalServerError
    else
        return http_api.EGAHTTPApiResponse.UnknownResponseCode
    end
end

function http_api:initRequest(gameKey, secretKey, playerData, playerId)
    local url = "https://rubick.gameanalytics.com/v2/command_center?game_key=" .. gameKey .. "&interval_seconds=1000000"
    if RunService:IsStudio() then
        url = baseUrl .. "/5c6bcb5402204249437fb5a7a80a4959/" .. self.initializeUrlPath
    end

    logger:d("Sending 'init' URL: " .. url)

    local payload = HTTP:JSONEncode(getInitAnnotations(playerData, playerId))
    local authorization = encode(payload, secretKey)

    local res
    local success, err = pcall(function()
        res = HTTP:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = {
                ["Authorization"] = authorization
            },
            Body = payload
        })
    end)

    if not success then
        logger:d("Failed Init Call. error: " .. err)
        return {
            statusCode = http_api.EGAHTTPApiResponse.UnknownResponseCode,
            body = nil
        }
    end
    logger:d("init request content: " .. res.Body)

    local requestResponseEnum = processRequestResponse(res, "Init")

    -- if not 200 result
    if requestResponseEnum ~= http_api.EGAHTTPApiResponse.Ok and requestResponseEnum ~= http_api.EGAHTTPApiResponse.BadRequest then
        logger:d("Failed Init Call. URL: " .. url .. ", JSONString: " .. payload .. ", Authorization: " .. authorization)
        return {
            statusCode = requestResponseEnum,
            body = nil
        }
    end

    --Response
    local responseBody
    success, _ = ypcall(function()
        responseBody = HTTP:JSONDecode(res.Body)
    end)

    if not success then
        logger:d("Failed Init Call. Json decoding failed: " .. err)
        return {
            statusCode = http_api.EGAHTTPApiResponse.JsonDecodeFailed,
            body = nil
        }
    end

    -- print reason if bad request
    if requestResponseEnum == http_api.EGAHTTPApiResponse.BadRequest then
        logger:d("Failed Init Call. Bad request. Response: " .. res.Body)
        return {
            statusCode = requestResponseEnum,
            body = nil
        }
    end

    -- validate Init call values
    local validatedInitValues = validation:validateAndCleanInitRequestResponse(responseBody)

    if not validatedInitValues then
        return {
            statusCode = http_api.EGAHTTPApiResponse.BadResponse,
            body = nil
        }
    end

    -- all ok
    return {
        statusCode = http_api.EGAHTTPApiResponse.Ok,
        body = responseBody
    }
end

function http_api:sendEventsInArray(gameKey, secretKey, eventArray)
    if not eventArray or #eventArray == 0 then
        logger:d("sendEventsInArray called with missing eventArray")
        return
    end

    -- Generate URL
    local url = baseUrl .. "/" .. gameKey .. "/" .. self.eventsUrlPath
    if RunService:IsStudio() then
        url = baseUrl .. "/5c6bcb5402204249437fb5a7a80a4959/" .. self.eventsUrlPath
    end

    logger:d("Sending 'events' URL: " .. url)

    -- make JSON string from data
    local payload = HTTP:JSONEncode(eventArray)
    local authorization = encode(payload, secretKey)

    local res
    local success, err = pcall(function()
        res = HTTP:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = {
                ["Authorization"] = authorization
            },
            Body = payload
        })
    end)

    if not success then
        logger:d("Failed Events Call. error: " .. err)
        return {
            statusCode = http_api.EGAHTTPApiResponse.UnknownResponseCode,
            body = nil
        }
    end


    logger:d("body: " .. res.Body)
    local requestResponseEnum = processRequestResponse(res, "Events")

    -- if not 200 result
    if requestResponseEnum ~= http_api.EGAHTTPApiResponse.Ok and requestResponseEnum ~= http_api.EGAHTTPApiResponse.BadRequest then
        logger:d("Failed Events Call. URL: " .. url .. ", JSONString: " .. payload .. ", Authorization: " .. authorization)
        return {
            statusCode = requestResponseEnum,
            body = nil
        }
    end

    local responseBody
    ypcall(function()
        responseBody = HTTP:JSONDecode(res.Body)
    end)

    if not responseBody then
        logger:d("Failed Events Call. Json decoding failed")
        return {
            statusCode = http_api.EGAHTTPApiResponse.JsonDecodeFailed,
            body = nil
        }
    end

    -- print reason if bad request
    if requestResponseEnum == http_api.EGAHTTPApiResponse.BadRequest then
        logger:d("Failed Events Call. Bad request. Response: " .. res.Body)
        return {
            statusCode = requestResponseEnum,
            body = nil
        }
    end

    -- all ok
    return {
        statusCode = http_api.EGAHTTPApiResponse.Ok,
        body = responseBody
    }
end

return http_api
