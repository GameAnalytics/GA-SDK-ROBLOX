# Changelog

---------

All notable changes to this project will be documented in this file.

## [3.0.0]

**Breaking changes**
- Studio is no longer sandboxed: play-tests send real events with your keys. Use test keys
- `build` defaults to `game.PlaceVersion` when not set; add place versions to experiment build lists
- Robux to USD rate updated from 0.0035 to 0.0038, reported revenue rises about 8.6%
- Remote config values are always strings; use `getRemoteConfigsValueAsJson` for structured values

**Remote configs v3**
- Remote configs v3 with A/B test ids on init and events
- Added `getRemoteConfigsValueAsJson`, `getABTestingId` and `getABTestingVariantId` on the server
- Added `OnRemoteConfigsUpdated` server signal; use it instead of `OnPlayerReadyEvent` (#131)
- Added client remote configs API on `GameAnalyticsClient` with its own `OnRemoteConfigsUpdated` signal
- Getters return the default for unknown players instead of erroring; init responses are validated
- `RemoteConfigs` options type renamed `RemoteConfigsOptions`; old name kept as a deprecated alias

**Studio plugin**
- New Creator Store plugin installs, updates, configures and validates the SDK without Rojo or Wally
- Keys never enter the place; the plugin generates the server snippet for your own script
- Plugin build attached to every GitHub release
- Rejected keys on init are reported in plain language instead of a raw 401

**DataStores**
- SDK loads in unpublished places and without DataStores, falling back to in-memory data
- DataStore requests give up after 3 attempts; a failed load never overwrites the stored record

**Fixes**
- Invalid custom dimensions are cleared instead of only logged
- Fixed nil concatenation on a nil design event id and on undecodable init responses
- Failed error count writes no longer overwrite the in-memory count
- `sdk_error` fields capped at 8192 characters

**Development**
- Jest Roblox test suite, run through `run-in-roblox`
- Toolchain moved from Aftman to Rokit; StyLua and luau-lsp configs added

## [2.2.6]

- Fixed a bug with teleport data not being validated properly before extrating analytics data
- Added changelog
- Cleaned the README


## [2.2.5]

- Add "custom_fields" to events
- Added types to the public facing api
- Applied StyLua to codebase

## [2.2.4]

- Removed LocalScript that was added in 2.2.3, causing errors on requiring GameAnalyticsClient module

## [2.2.3]

- Fixed bug where PlayerData would reference BasePlayerData tables instead of making copies
- Added datastore queue

## [2.2.2]

- Fix to wally support

## [2.2.1]

- Fixed bug related to game passes purchases

## [2.2.0]

- Added support for wally (OBS: breaking changes)

## [2.1.35]

- Fixed argument order

## [2.1.34]

- Corrected to use new postie api where referenced

## [2.1.33]

- Postie script updated

## [2.1.32]

- Replace global spawn and wait with task library

## [2.1.31]

- Fixed postie bug after moving the script under gameanalytics script

## [2.1.30]

- Replaced rbxmx generator script with rojo build command (requires min. rojo 6)

## [2.1.29]

- Moved postie script inside GameAnalytics scripts

## [2.1.28]

- Fixed error message in errorhandler

## [2.1.27]

- Country code field always sent with events now (sent as 'null' if country code couldn't be fetched)

## [2.1.26]

- Fixed undefined variable errors

## [2.1.25]

- Fixed potential error in session end event code

## [2.1.24]

- Added error tracking if country code fails to get retrieved

## [2.1.23]

- Fixed ab testing

## [2.1.22]

- Fixed bug with remote configs and ab testing ids not being added to events

## [2.1.21]

- Fixed GetPlayerDataFromCache function

## [2.1.20]

- Fixes to gamepass in business events

## [2.1.19]

- Fixed detection of website gamepasses throttling datastores

## [2.1.18]

- Fixed sesion start and end issues which caused problems with metrics

## [2.1.17]

- Corrected variable name inside GetPlayerDataFromCache function

## [2.1.16]

- Player data cache now accepts both userId of string or number type

## [2.1.15]

- Fixed not clearing session start ts because teleport flag was not cleared

## [2.1.14]

- Fixed logic for error handler

## [2.1.13]

- Added player id to error events sent from error reporting

## [2.1.12]

- Fixed ScriptContext.Error error reporting

## [2.1.11]

- Switched from using LogService to ScriptContext.Error for error reporting

## [2.1.10]

- Fixed setAvailableGamepasses function

## [2.1.9]

- Correct install instructions and fixed GameAnalyticsServerInit script

## [2.1.8]

- Correct business event for 'Gamepass' itemType

## [2.1.7]

- Added country code to events to get correct country of users

## [2.1.6]

- Corrected install instructions

## [2.1.5]

- Moved everything from GameAnalyticsServer to GameAnalytics module and created a template server script for calling the initialize function.
- Added queue for functions like addDesignEvent etc. that are called before player or GA is initialized
- Renamed server init with settings script and restructured it (new usage)

## [2.1.4]

- Added session_num to init request

## [2.1.3]

- Replaced previous HMAC + SHA256 + Base64 implementation with HashLib. This version is around 23 - 25% faster.
- Changed indenting from spaces to tabs (Roblox default).
- Worked on reformatting so it followed the Roblox Lua style guide a little better.
- Updated the luacheck files more.

## [2.1.2]

- Fixed rojo file

## [2.1.1]

- Updated postie script

## [2.1.0]

- Added website game pass purchase tracking support

## [2.0.1]

- Remote configs fixes

## [2.0.0]

- Remote Config calls have been updated and the old calls have deprecated. Please see GA documentation for the new SDK calls and migration guide
- A/B testing support added

## [1.4.2]

- Improvements for business event

## [1.4.1]

- Fix to playerRemoved function

## [1.4.0]

- Added bindable event to listen to when player is ready (has gotten its player data loaded)

## [1.3.9]

- Started using new bit module instead of old one

## [1.3.8]

- Fixes for progression events

## [1.3.7]

- Bug fix for platform name fallback option

## [1.3.6]

- Fix for command center populated events

## [1.3.5]

- Fixes to some types of events not being sent

## [1.3.4]

- Fixed bug with automatic error events

## [1.3.3]

- Fixed bug with error events not sending (another one)

## [1.3.2]

- Fixed bug with error events not sending

## [1.3.1]

- Fixed multi-place game bugs

## [1.3.0]

- Added support for multi-place game sessions

## [1.2.13]

- Changed Postie from being a script to a modulescript

## [1.2.12]

- Added Postie module to replace invokeclient call in playerjoined

## [1.2.11]

- Fixed playerjoined method to not wait indefinitely in some cases

## [1.2.10]

- Fixed playerjoined method to not wait indefinitely in some cases

## [1.2.9]

- Fixed load table bug

## [1.2.8]

- Added missing files to rbxmx

## [1.2.7]

- Performance to enum lookups

## [1.2.6]

- Added limit to how many events there can max be in the events queue

## [1.2.5]

- Added better error handling for thread task execution

## [1.2.4]

- Added toggle function for debug logging in studio mode
- Threading performance fix

## [1.2.3]

- Various bug fixes

## [1.2.2]

- Bug fixes to manual configuration and initialization of sdk

## [1.2.1]

- Updated server scripts to just be descendants of ServerScriptService and not just direct child of ServerScriptService

## [1.2.0]

- Added enable/disable event submission function

## [1.1.0]

- Moved settings related code in GameAnalyticsServer script into a new script called GameAnalyticsServerInitUsingSettings to allow manual initialization from own script (OPS look at new INSTALL instructions for new script)

## [1.0.5]

- Renamed GameAnalyticsScript to GameAnalyticsServer
- Removed script location restriction on GameAnalyticsClient

## [1.0.4]

- Small corrections

## [1.0.3]

- Fixed automatic sending of error events
- Added script for generating rbxmx file

## [1.0.2]

- Fixed sha256 performance issues
- Added processReceiptCallback function to use within your own processReceipt method
- Replaced all string.len and table.getn with # operator instead
- Using game:GetService() to access services instead of using game.[some_service]
- Fixed device recognition method
- Fixed automatic sending of error events

## [1.0.1]

- Small bugs fixes

## [1.0.0] - Initial Release

- Added session tracking
- Implemented custom event logging
- Integrated teleport data handling