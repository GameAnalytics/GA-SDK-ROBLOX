local validation = require(script.Parent.Validation)
local version = require(script.Parent.Version)

local HashLib = require(script.HashLib)

local http_api = {
	protocol = "https",
	hostName = "api.gameanalytics.com",
	version = "v2",
	remoteConfigsVersion = "v1",
	remoteConfigsSupportedVersion = 3,
	initializeUrlPath = "init",
	eventsUrlPath = "events",
	EGAHTTPApiResponse = {
		NoResponse = 0,
		BadResponse = 1,
		RequestTimeout = 2,
		JsonEncodeFailed = 3,
		JsonDecodeFailed = 4,
		InternalServerError = 5,
		BadRequest = 6,
		Unauthorized = 7,
		UnknownResponseCode = 8,
		Ok = 9,
		Created = 10,
	},
}

local HTTP = game:GetService("HttpService")
local logger = require(script.Parent.Logger)

function http_api.request(options)
	return HTTP:RequestAsync(options)
end

local baseUrl = http_api.protocol .. "://" .. http_api.hostName .. "/" .. http_api.version
local remoteConfigsBaseUrl = http_api.protocol
	.. "://"
	.. http_api.hostName
	.. "/remote_configs/"
	.. http_api.remoteConfigsVersion

local function getInitAnnotations(build, playerData, playerId)
	local initAnnotations = {
		["user_id"] = tostring(playerId) .. playerData.CustomUserId,
		["sdk_version"] = "roblox " .. version.SdkVersion,
		["os_version"] = playerData.OS,
		["platform"] = playerData.Platform,
		["build"] = build,
		["session_num"] = playerData.Sessions,
		["random_salt"] = playerData.Sessions,
	}

	return initAnnotations
end

local function encode(payload, secretKey)
	--Validate
	if not secretKey then
		logger:w("Error encoding, invalid SecretKey")
		return
	end

	--Encode
	local payloadHmac = HashLib.hmac(HashLib.sha256, secretKey, payload, true)

	return HashLib.base64_encode(payloadHmac)
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
	elseif statusCode == 201 then
		return http_api.EGAHTTPApiResponse.Created
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

function http_api:getInitUrl(gameKey, configsHash)
	return string.format(
		"%s/%s?game_key=%s&interval_seconds=0&configs_hash=%s&config_vsn_supported=%d",
		remoteConfigsBaseUrl,
		self.initializeUrlPath,
		gameKey,
		configsHash or "",
		self.remoteConfigsSupportedVersion
	)
end

function http_api:initRequest(gameKey, secretKey, build, playerData, playerId)
	local url = self:getInitUrl(gameKey, playerData.RemoteConfigs.hash)

	logger:d("Sending 'init' URL: " .. url)

	local payload = HTTP:JSONEncode(getInitAnnotations(build, playerData, playerId))
	payload = payload:gsub('"country_code":"unknown"', '"country_code":null')
	local authorization = encode(payload, secretKey)

	logger:d("init payload: " .. payload)

	local res
	local success, err = pcall(function()
		res = http_api.request({
			Url = url,
			Method = "POST",
			Headers = {
				["Authorization"] = authorization,
				["Content-Type"] = "application/json",
			},
			Body = payload,
		})
	end)

	if not success then
		logger:d("Failed Init Call. error: " .. err)
		return {
			statusCode = http_api.EGAHTTPApiResponse.UnknownResponseCode,
			body = nil,
		}
	end
	logger:d("init request content: " .. res.Body)

	local requestResponseEnum = processRequestResponse(res, "Init")

	-- if not 200 result
	if
		requestResponseEnum ~= http_api.EGAHTTPApiResponse.Ok
		and requestResponseEnum ~= http_api.EGAHTTPApiResponse.Created
		and requestResponseEnum ~= http_api.EGAHTTPApiResponse.BadRequest
	then
		logger:d(
			"Failed Init Call. URL: " .. url .. ", JSONString: " .. payload .. ", Authorization: " .. authorization
		)
		return {
			statusCode = requestResponseEnum,
			body = nil,
		}
	end

	--Response
	local responseBody
	success, err = pcall(function()
		responseBody = HTTP:JSONDecode(res.Body)
	end)

	if not success then
		logger:d("Failed Init Call. Json decoding failed: " .. tostring(err))
		return {
			statusCode = http_api.EGAHTTPApiResponse.JsonDecodeFailed,
			body = nil,
			reason = res.Body,
		}
	end

	-- print reason if bad request
	if requestResponseEnum == http_api.EGAHTTPApiResponse.BadRequest then
		logger:d("Failed Init Call. Bad request. Response: " .. res.Body)
		return {
			statusCode = requestResponseEnum,
			body = nil,
		}
	end

	-- validate Init call values
	local validatedInitValues = validation:validateAndCleanInitRequestResponse(
		responseBody,
		requestResponseEnum == http_api.EGAHTTPApiResponse.Created
	)

	if not validatedInitValues then
		return {
			statusCode = http_api.EGAHTTPApiResponse.BadResponse,
			body = nil,
		}
	end

	return {
		statusCode = requestResponseEnum,
		body = validatedInitValues,
	}
end

function http_api:sendEventsInArray(gameKey, secretKey, eventArray)
	if not eventArray or #eventArray == 0 then
		logger:d("sendEventsInArray called with missing eventArray")
		return
	end

	-- Generate URL
	local url = baseUrl .. "/" .. gameKey .. "/" .. self.eventsUrlPath

	logger:d("Sending 'events' URL: " .. url)

	-- make JSON string from data
	local payload = HTTP:JSONEncode(eventArray)
	payload = payload:gsub('"country_code":"unknown"', '"country_code":null')
	local authorization = encode(payload, secretKey)

	local res
	local success, err = pcall(function()
		res = http_api.request({
			Url = url,
			Method = "POST",
			Headers = {
				["Authorization"] = authorization,
				["Content-Type"] = "application/json",
			},
			Body = payload,
		})
	end)

	if not success then
		logger:d("Failed Events Call. error: " .. err)
		return {
			statusCode = http_api.EGAHTTPApiResponse.UnknownResponseCode,
			body = nil,
		}
	end

	logger:d("body: " .. res.Body)
	local requestResponseEnum = processRequestResponse(res, "Events")

	-- if not 200 result
	if
		requestResponseEnum ~= http_api.EGAHTTPApiResponse.Ok
		and requestResponseEnum ~= http_api.EGAHTTPApiResponse.Created
		and requestResponseEnum ~= http_api.EGAHTTPApiResponse.BadRequest
	then
		logger:d(
			"Failed Events Call. URL: " .. url .. ", JSONString: " .. payload .. ", Authorization: " .. authorization
		)
		return {
			statusCode = requestResponseEnum,
			body = nil,
		}
	end

	local responseBody
	pcall(function()
		responseBody = HTTP:JSONDecode(res.Body)
	end)

	if not responseBody then
		logger:d("Failed Events Call. Json decoding failed")
		return {
			statusCode = http_api.EGAHTTPApiResponse.JsonDecodeFailed,
			body = nil,
		}
	end

	-- print reason if bad request
	if requestResponseEnum == http_api.EGAHTTPApiResponse.BadRequest then
		logger:d("Failed Events Call. Bad request. Response: " .. res.Body)
		return {
			statusCode = requestResponseEnum,
			body = nil,
		}
	end

	-- all ok
	return {
		statusCode = http_api.EGAHTTPApiResponse.Ok,
		body = responseBody,
	}
end

return http_api
