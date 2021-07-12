GA-SDK-ROBLOX
=============

GameAnalytics Roblox SDK.

Documentation can be found [here](https://gameanalytics.com/docs/item/roblox-sdk).

If you have any issues or feedback regarding the SDK, please contact our friendly support team [here](https://gameanalytics.com/contact).

#### Requirements
* [rojo](https://github.com/LPGhatguy/rojo) (optional, but needed if you want to automatically sync the source files inside the GameAnalyticsSDK folder into your Roblox project)

Changelog
---------
<!--(CHANGELOG_TOP)-->
**2.1.30**
* replaced rbxmx generator script with rojo build command (requires min. rojo 6)

**2.1.29**
* moved postie script inside GameAnalytics scripts

**2.1.29**
* moved postie script inside GameAnalytics scripts

**2.1.28**
* fixed error message in errorhandler

**2.1.27**
* country code field always sent with events now (sent as 'null' if country code couldn't be fetched)

**2.1.26**
* fixed undefined variable errors

**2.1.25**
* fixed potential error in session end event code

**2.1.24**
* added error tracking if country code fails to get retrieved

**2.1.23**
* fixed ab testing

**2.1.22**
* fixed bug with remote configs and ab testing ids not being added to events

**2.1.21**
* fixed GetPlayerDataFromCache function

**2.1.20**
* fixes to gamepass in business events

**2.1.19**
* fixed detection of website gamepasses throttling datastores

**2.1.18**
* fixed sesion start and end issues which caused problems with metrics

**2.1.17**
* corrected variable name inside GetPlayerDataFromCache function

**2.1.16**
* player data cache now accepts both userId of string or number type

**2.1.15**
* fixed not clearing session start ts because teleport flag was not cleared

**2.1.14**
* fixed logic for error handler

**2.1.13**
* added player id to error events sent from error reporting

**2.1.12**
* fixed ScriptContext.Error error reporting

**2.1.11**
* switched from using LogService to ScriptContext.Error for error reporting

**2.1.10**
* fixed setAvailableGamepasses function

**2.1.9**
* correct install instructions and fixed GameAnalyticsServerInit script

**2.1.8**
* correct business event for 'Gamepass' itemType

**2.1.7**
* added country code to events to get correct country of users

**2.1.6**
* corrected install instructions

**2.1.5**
* Moved everything from GameAnalyticsServer to GameAnalytics module and created a template server script for calling the initialize function.
* Added queue for functions like addDesignEvent etc. that are called before player or GA is initialized
* renamed server init with settings script and restructured it (new usage)

**2.1.4**
* added session_num to init request

**2.1.3**
* Replaced previous HMAC + SHA256 + Base64 implementation with HashLib. This version is around 23 - 25% faster.
* Changed indenting from spaces to tabs (Roblox default).
* Worked on reformatting so it followed the Roblox Lua style guide a little better..
* Updated the luacheck files more.

**2.1.2**
* fixed rojo file

**2.1.1**
* updated postie script

**2.1.0**
* added website game pass purchase tracking support

**2.0.1**
* remote configs fixes

**2.0.0**
* Remote Config calls have been updated and the old calls have deprecated. Please see GA documentation for the new SDK calls and migration guide
* A/B testing support added

**1.4.2**
* improvements for business event

**1.4.1**
* fix to playerRemoved function

**1.4.0**
* added bindable event to listen to when player is ready (has gotten its player data loaded)

**1.3.9**
* started using new bit module instead of old one

**1.3.8**
* fixes for progression events

**1.3.7**
* bug fix for platform name fallback option

**1.3.6**
* fix for command center populated events

**1.3.5**
* fixes to some types of events not being sent

**1.3.4**
* fixed bug with automatic error events

**1.3.3**
* fixed bug with error events not sending (another one)

**1.3.2**
* fixed bug with error events not sending

**1.3.1**
* fixed multi-place game bugs

**1.3.0**
* added support for multi-place game sessions

**1.2.13**
* changed Postie from being a script to a modulescript

**1.2.12**
* added Postie module to replace invokeclient call in playerjoined

**1.2.11**
* fixed playerjoined method to not wait indefinitely in some cases

**1.2.10**
* fixed playerjoined method to not wait indefinitely in some cases

**1.2.9**
* fixed load table bug

**1.2.8**
* added missing files to rbxmx

**1.2.7**
* performance to enum lookups

**1.2.6**
* added limit to how many events there can max be in the events queue

**1.2.5**
* added better error handling for thread task execution

**1.2.4**
* added toggle function for debug logging in studio mode
* threading performance fix

**1.2.3**
* various bug fixes

**1.2.2**
* bug fixes to manual configuration and initialization of sdk

**1.2.1**
* updated server scripts to just be descendants of ServerScriptService and not just direct child of ServerScriptService

**1.2.0**
* added enable/disable event submission function

**1.1.0**
* moved settings related code in GameAnalyticsServer script into a new script called GameAnalyticsServerInitUsingSettings to allow manual initialization from own script (OPS look at new INSTALL instructions for new script)

**1.0.5**
* renamed GameAnalyticsScript to GameAnalyticsServer
* removed script location restriction on GameAnalyticsClient

**1.0.4**
* small corrections

**1.0.3**
* fixed automatic sending of error events
* added script for generating rbxmx file

**1.0.2**
* fixed sha256 performance issues
* added processReceiptCallback function to use within your own processReceipt method
* replaced all string.len and table.getn with # operator instead
* using game:GetService() to access services instead of using game.[some_service]
* fixed device recognition method
* fixed automatic sending of error events

**1.0.1**
* small bugs fixes

**1.0.0**
* initial release
