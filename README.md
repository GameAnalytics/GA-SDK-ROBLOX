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
