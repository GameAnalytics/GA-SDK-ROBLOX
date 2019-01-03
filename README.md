GA-SDK-ROBLOX
=============

GameAnalytics Roblox SDK.

Documentation can be found [here](https://gameanalytics.com/docs/item/roblox-sdk).

#### Requirements
* [rojo](https://github.com/LPGhatguy/rojo) (optional, but needed if you want to automatically sync the source files inside the GameAnalyticsSDK folder into your Roblox project)

Changelog
---------
<!--(CHANGELOG_TOP)-->
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
