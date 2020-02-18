local validation = {}

local logger = require(script.Parent.Logger)
local utilities = require(script.Parent.Utilities)

function validation:validateCustomDimensions(customDimensions)
	return validation:validateArrayOfStrings(20, 32, false, "custom dimensions", customDimensions)
end

function validation:validateDimension(dimensions, dimension)
	-- allow nil
	if utilities:isStringNullOrEmpty(dimension) then
		return true
	end

	if not utilities:stringArrayContainsString(dimensions, dimension) then
		return false
	end

	return true
end

function validation:validateResourceCurrencies(resourceCurrencies)
	if not validation:validateArrayOfStrings(20, 64, false, "resource currencies", resourceCurrencies) then
		return false
	end

	-- validate each string for regex
	for _, resourceCurrency in pairs(resourceCurrencies) do
		if not string.find(resourceCurrency, "^[A-Za-z]+$") then
			logger:w("resource currencies validation failed: a resource currency can only be A-Z, a-z. String was: " .. resourceCurrency)
			return false
		end
	end

	return true
end

function validation:validateResourceItemTypes(resourceItemTypes)
	if not validation:validateArrayOfStrings(20, 32, false, "resource item types", resourceItemTypes) then
		return false
	end

	-- validate each string for regex
	for _, resourceItemType in pairs(resourceItemTypes) do
		if not validation:validateEventPartCharacters(resourceItemType) then
			logger:w("resource item types validation failed: a resource item type cannot contain other characters than A-z, 0-9, -_., ()!?. String was: " .. resourceItemType)
			return false
		end
	end

	return true
end

function validation:validateEventPartCharacters(eventPart)
	if not string.find(eventPart, "^[A-Za-z0-9%s%-_%.%(%)!%?]+$") then
		return false
	end

	return true
end

function validation:validateArrayOfStrings(maxCount, maxStringLength, allowNoValues, logTag, arrayOfStrings)
	local arrayTag = logTag

	if not arrayTag then
		arrayTag = "Array"
	end

	-- use arrayTag to annotate warning log
	if not arrayOfStrings then
		logger:w(arrayTag .. " validation failed: array cannot be nil.")
		return false
	end

	-- check if empty
	if not allowNoValues and #arrayOfStrings == 0 then
		logger:w(arrayTag .. " validation failed: array cannot be empty.")
		return false
	end

	-- check if exceeding max count
	if maxCount > 0 and #arrayOfStrings > maxCount then
		logger:w(arrayTag .. " validation failed: array cannot exceed " .. tostring(maxCount) .. " values. It has " .. #arrayOfStrings .. " values.")
		return false
	end

	-- validate each string
	for _, arrayString in ipairs(arrayOfStrings) do
		local stringLength = 0
		if arrayString then
			stringLength = #arrayString
		end

		-- check if empty (not allowed)
		if stringLength == 0 then
			logger:w(arrayTag .. " validation failed: contained an empty string.")
			return false
		end

		-- check if exceeding max length
		if maxStringLength > 0 and stringLength > maxStringLength then
			logger:w(arrayTag .. " validation failed: a string exceeded max allowed length (which is: " .. tostring(maxStringLength) .. "). String was: " .. arrayString)
			return false
		end
	end

	return true
end

function validation:validateBuild(build)
	if not validation:validateShortString(build, false) then
		return false
	end

	return true
end

function validation:validateShortString(shortString, canBeEmpty)
	-- String is allowed to be empty or nil
	if canBeEmpty and utilities:isStringNullOrEmpty(shortString) then
		return true
	end

	if utilities:isStringNullOrEmpty(shortString) or #shortString > 32 then
		return false
	end

	return true
end

function validation:validateKeys(gameKey, secretKey)
	if string.find(gameKey, "^[A-Za-z0-9]+$") and #gameKey == 32 then
		if string.find(secretKey, "^[A-Za-z0-9]+$") and #secretKey == 40 then
			return true
		end
	end

	return false
end

function validation:validateAndCleanInitRequestResponse(initResponse, configsCreated)
	-- make sure we have a valid dict
	if not initResponse then
		logger:w("validateInitRequestResponse failed - no response dictionary.")
		return nil
	end

	local validatedDict = {}

	-- validate server_ts
	local serverTsNumber = initResponse["server_ts"] or -1
	if serverTsNumber > 0 then
		validatedDict["server_ts"] = serverTsNumber
	end

	if configsCreated then
		validatedDict["configs"] = initResponse["configs"] or {}
		validatedDict["ab_id"] = initResponse["ab_id"] or ""
		validatedDict["ab_variant_id"] = initResponse["ab_variant_id"] or ""
	end

	return validatedDict
end

function validation:validateClientTs(clientTs)
	if clientTs < 1000000000 or clientTs > 9999999999 then
		return false
	end

	return true
end

function validation:validateCurrency(currency)
	if utilities:isStringNullOrEmpty(currency) then
		return false
	end

	if string.find(currency, "^[A-Z]+$") and #currency == 3 then
		return true
	end

	return false
end

function validation:validateEventPartLength(eventPart, allowNull)
	if allowNull and utilities:isStringNullOrEmpty(eventPart) then
		return true
	end

	if utilities:isStringNullOrEmpty(eventPart) then
		return false
	end

	if #eventPart == 0 or #eventPart > 64 then
		return false
	end
	return true
end

function validation:validateBusinessEvent(currency, amount, cartType, itemType, itemId)
	-- validate currency
	if not validation:validateCurrency(currency) then
		logger:w("Validation fail - business event - currency: Cannot be (null) and need to be A-Z, 3 characters and in the standard at openexchangerates.org. Failed currency: " .. currency)
		return false
	end

	if amount < 0 then
		logger:w("Validation fail - business event - amount: Cannot be less then 0. Failed amount: " .. amount)
		return false
	end

	-- validate cartType
	if not validation:validateShortString(cartType, true) then
		logger:w("Validation fail - business event - cartType. Cannot be above 32 length. String: " .. cartType)
		return false
	end

	-- validate itemType length
	if not validation:validateEventPartLength(itemType, false) then
		logger:w("Validation fail - business event - itemType: Cannot be (null), empty or above 64 characters. String: " .. itemType)
		return false
	end

	-- validate itemType chars
	if not validation:validateEventPartCharacters(itemType) then
		logger:w("Validation fail - business event - itemType: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: " .. itemType)
		return false
	end

	-- validate itemId
	if not validation:validateEventPartLength(itemId, false) then
		logger:w("Validation fail - business event - itemId. Cannot be (null), empty or above 64 characters. String: " .. itemId)
		return false
	end

	if not validation:validateEventPartCharacters(itemId) then
		logger:w("Validation fail - business event - itemId: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: " .. itemId)
		return false
	end

	return true
end

function validation:validateResourceEvent(flowTypeValues, flowType, currency, amount, itemType, itemId, currencies, itemTypes)
	if flowType ~= flowTypeValues.Source and flowType ~= flowTypeValues.Sink then
		logger:w("Validation fail - resource event - flowType: Invalid flow type " .. tostring(flowType))
		return false
	end

	if utilities:isStringNullOrEmpty(currency) then
		logger:w("Validation fail - resource event - currency: Cannot be (null)")
		return false
	end

	if not utilities:stringArrayContainsString(currencies, currency) then
		logger:w("Validation fail - resource event - currency: Not found in list of pre-defined available resource currencies. String: " .. currency)
		return false
	end

	if not (amount > 0) then
		logger:w("Validation fail - resource event - amount: Float amount cannot be 0 or negative. Value: " .. tostring(amount))
		return false
	end

	if utilities:isStringNullOrEmpty(itemType) then
		logger:w("Validation fail - resource event - itemType: Cannot be (null)")
		return false
	end

	if not validation:validateEventPartLength(itemType, false) then
		logger:w("Validation fail - resource event - itemType: Cannot be (null), empty or above 64 characters. String: " .. itemType)
		return false
	end

	if not validation:validateEventPartCharacters(itemType) then
		logger:w("Validation fail - resource event - itemType: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: " .. itemType)
		return false
	end

	if not utilities:stringArrayContainsString(itemTypes, itemType) then
		logger:w("Validation fail - resource event - itemType: Not found in list of pre-defined available resource itemTypes. String: " .. itemType)
		return false
	end

	if not validation:validateEventPartLength(itemId, false) then
		logger:w("Validation fail - resource event - itemId: Cannot be (null), empty or above 64 characters. String: " .. itemId)
		return false
	end

	if not validation:validateEventPartCharacters(itemId) then
		logger:w("Validation fail - resource event - itemId: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: " .. itemId)
		return false
	end

	return true
end

function validation:validateProgressionEvent(progressionStatusValues, progressionStatus, progression01, progression02, progression03)
	if progressionStatus ~= progressionStatusValues.Start and progressionStatus ~= progressionStatusValues.Complete and progressionStatus ~= progressionStatusValues.Fail then
		logger:w("Validation fail - progression event: Invalid progression status " .. tostring(progressionStatus))
		return false
	end

	-- Make sure progressions are defined as either 01, 01+02 or 01+02+03
	if not utilities:isStringNullOrEmpty(progression03) and not (not utilities:isStringNullOrEmpty(progression02) or utilities:isStringNullOrEmpty(progression01)) then
		logger:w("Validation fail - progression event: 03 found but 01+02 are invalid. Progression must be set as either 01, 01+02 or 01+02+03.")
		return false
	elseif not utilities:isStringNullOrEmpty(progression02) and utilities:isStringNullOrEmpty(progression01) then
		logger:w("Validation fail - progression event: 02 found but not 01. Progression must be set as either 01, 01+02 or 01+02+03")
		return false
	elseif utilities:isStringNullOrEmpty(progression01) then
		logger:w("Validation fail - progression event: progression01 not valid. Progressions must be set as either 01, 01+02 or 01+02+03")
		return false
	end

	-- progression01 (required)
	if not validation:validateEventPartLength(progression01, false) then
		logger:w("Validation fail - progression event - progression01: Cannot be (null), empty or above 64 characters. String: " .. progression01)
		return false
	end

	if not validation:validateEventPartCharacters(progression01) then
		logger:w("Validation fail - progression event - progression01: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: " .. progression01)
		return false
	end

	-- progression02
	if not utilities:isStringNullOrEmpty(progression02) then
		if not validation:validateEventPartLength(progression02, false) then
			logger:w("Validation fail - progression event - progression02: Cannot be empty or above 64 characters. String: " .. progression02)
			return false
		end

		if not validation:validateEventPartCharacters(progression02) then
			logger:w("Validation fail - progression event - progression02: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: " .. progression02)
			return false
		end
	end

	-- progression03
	if not utilities:isStringNullOrEmpty(progression03) then
		if not validation:validateEventPartLength(progression03, false) then
			logger:w("Validation fail - progression event - progression03: Cannot be empty or above 64 characters. String: " .. progression03)
			return false
		end

		if not validation:validateEventPartCharacters(progression03) then
			logger:w("Validation fail - progression event - progression03: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: " .. progression03)
			return false
		end
	end

	return true
end

function validation:validateEventIdLength(eventId)
	if utilities:isStringNullOrEmpty(eventId) then
		return false
	end

	local count = 0
	for s in string.gmatch(eventId, "([^:]+)") do
		count = count + 1
		if count > 5 or #s > 64 then
			return false
		end
	end

	return true
end

function validation:validateEventIdCharacters(eventId)
	if utilities:isStringNullOrEmpty(eventId) then
		return false
	end

	local count = 0
	for s in string.gmatch(eventId, "([^:]+)") do
		count = count + 1
		if count > 5 or not string.find(s, "^[A-Za-z0-9%s%-_%.%(%)!%?]+$") then
			return false
		end
	end

	return true
end

function validation:validateDesignEvent(eventId)
	if not validation:validateEventIdLength(eventId) then
		logger:w("Validation fail - design event - eventId: Cannot be (null) or empty. Only 5 event parts allowed seperated by :. Each part need to be 32 characters or less. String: " .. eventId)
		return false
	end

	if not validation:validateEventIdCharacters(eventId) then
		logger:w("Validation fail - design event - eventId: Non valid characters. Only allowed A-z, 0-9, -_., ()!?. String: " .. eventId)
		return false
	end

	-- value: allow 0, negative and nil (not required)
	return true
end

function validation:validateLongString(longString, canBeEmpty)
	-- String is allowed to be empty
	if canBeEmpty and utilities:isStringNullOrEmpty(longString) then
		return true
	end

	if utilities:isStringNullOrEmpty(longString) or #longString > 8192 then
		return false
	end

	return true
end

function validation:validateErrorEvent(severityValues, severity, message)
	if severity ~= severityValues.debug and severity ~= severityValues.info and severity ~= severityValues.warning and severity ~= severityValues.error and severity ~= severityValues.critical then
		logger:w("Validation fail - error event - severity: Severity was unsupported value " .. tostring(severity))
		return false
	end

	if not validation:validateLongString(message, true) then
		logger:w("Validation fail - error event - message: Message cannot be above 8192 characters.")
		return false
	end

	return true
end

return validation
