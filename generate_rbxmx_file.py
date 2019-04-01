#!/usr/bin/python
import os

ROBLOX_DIR = os.path.abspath(os.path.join(__file__, '..'))
ROBLOX_GA_DIR = os.path.join(ROBLOX_DIR, "GameAnalyticsSDK")
RBXMX_TMP_FILE = os.path.join(ROBLOX_DIR, "GameAnalyticsSDK.rbxmx.tmp")
RBXMX_RELEASE_FILE = os.path.join(ROBLOX_DIR, "release", "GameAnalyticsSDK.rbxmx")

GAMEANALYTICSSERVER_BODY = 'GameAnalyticsServer_BODY'
GAMEANALYTICSSERVER_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalyticsServer.server.lua")
GAMEANALYTICSSERVERINITUSINGSETTINGS_BODY = 'GameAnalyticsServerInitUsingSettings_BODY'
GAMEANALYTICSSERVERINITUSINGSETTINGS_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalyticsServerInitUsingSettings.server.lua")
INSTALL_BODY = 'INSTALL_BODY'
INSTALL_FILE = os.path.join(ROBLOX_GA_DIR, "INSTALL.txt")
GAMEANALYTICSCLIENT_BODY = 'GameAnalyticsClient_BODY'
GAMEANALYTICSCLIENT_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalyticsClient.client.lua")
GAMEANALYTICS_BODY = 'GameAnalytics_BODY'
GAMEANALYTICS_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "init.lua")
SETTINGS_BODY = 'Settings_BODY'
SETTINGS_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "Settings.lua")
HTTPAPI_BODY = 'HttpApi_BODY'
HTTPAPI_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "init.lua")
LOCKBOX_BODY = 'lockbox_BODY'
LOCKBOX_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "Encoding", "lockbox", "init.lua")
STREAM_BODY = 'stream_BODY'
STREAM_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "Encoding", "lockbox", "util", "stream.lua")
QUEUE_BODY = 'queue_BODY'
QUEUE_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "Encoding", "lockbox", "util", "queue.lua")
ARRAY_BODY = 'array_BODY'
ARRAY_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "Encoding", "lockbox", "util", "array.lua")
BASE64_BODY = 'base64_BODY'
BASE64_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "Encoding", "lockbox", "util", "base64.lua")
UTIL_BIT_BODY = 'util_bit_BODY'
UTIL_BIT_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "Encoding", "lockbox", "util", "bit.lua")
HMAC_BODY = 'hmac_BODY'
HMAC_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "Encoding", "lockbox", "mac", "hmac.lua")
SHA2_256_BODY = 'sha2_256_BODY'
SHA2_256_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "Encoding", "lockbox", "digest", "sha2_256.lua")
BIT_BODY = 'bit_BODY'
BIT_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "Encoding", "bit.lua")
LOGGER_BODY = 'Logger_BODY'
LOGGER_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "Logger.lua")
STORE_BODY = 'Store_BODY'
STORE_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "Store.lua")
EVENTS_BODY = 'Events_BODY'
EVENTS_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "Events.lua")
UTILITIES_BODY = 'Utilities_BODY'
UTILITIES_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "Utilities.lua")
VERSION_BODY = 'Version_BODY'
VERSION_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "Version.lua")
STATE_BODY = 'State_BODY'
STATE_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "State.lua")
VALIDATION_BODY = 'Validation_BODY'
VALIDATION_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "Validation.lua")
THREADING_BODY = 'Threading_BODY'
THREADING_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "Threading.lua")
GAERRORSEVERITY_BODY = 'GAErrorSeverity_BODY'
GAERRORSEVERITY_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "GAErrorSeverity.lua")
GAPROGRESSIONSTATUS_BODY = 'GAProgressionStatus_BODY'
GAPROGRESSIONSTATUS_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "GAProgressionStatus.lua")
GARESOURCEFLOWTYPE_BODY = 'GAResourceFlowType_BODY'
GARESOURCEFLOWTYPE_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "GAResourceFlowType.lua")


def main():
    print('--- generating rbxmx file ----')
    rbxmx_contents = ""
    with open(RBXMX_TMP_FILE, 'r') as rbxmx_tmp_file:
        rbxmx_contents = rbxmx_tmp_file.read()

    file_contents = ""
    with open(GAMEANALYTICSSERVER_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(GAMEANALYTICSSERVER_BODY, file_contents)

    file_contents = ""
    with open(GAMEANALYTICSSERVERINITUSINGSETTINGS_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(GAMEANALYTICSSERVERINITUSINGSETTINGS_BODY, file_contents)

    file_contents = ""
    with open(INSTALL_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(INSTALL_BODY, file_contents)

    file_contents = ""
    with open(GAMEANALYTICSCLIENT_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(GAMEANALYTICSCLIENT_BODY, file_contents)

    file_contents = ""
    with open(GAMEANALYTICS_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(GAMEANALYTICS_BODY, file_contents)

    file_contents = ""
    with open(SETTINGS_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(SETTINGS_BODY, file_contents)

    file_contents = ""
    with open(HTTPAPI_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(HTTPAPI_BODY, file_contents)

    file_contents = ""
    with open(LOCKBOX_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(LOCKBOX_BODY, file_contents)

    file_contents = ""
    with open(STREAM_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(STREAM_BODY, file_contents)

    file_contents = ""
    with open(QUEUE_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(QUEUE_BODY, file_contents)

    file_contents = ""
    with open(ARRAY_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(ARRAY_BODY, file_contents)

    file_contents = ""
    with open(BASE64_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(BASE64_BODY, file_contents)

    file_contents = ""
    with open(UTIL_BIT_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(UTIL_BIT_BODY, file_contents)

    file_contents = ""
    with open(HMAC_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(HMAC_BODY, file_contents)

    file_contents = ""
    with open(SHA2_256_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(SHA2_256_BODY, file_contents)

    file_contents = ""
    with open(BIT_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(BIT_BODY, file_contents)

    file_contents = ""
    with open(LOGGER_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(LOGGER_BODY, file_contents)

    file_contents = ""
    with open(STORE_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(STORE_BODY, file_contents)

    file_contents = ""
    with open(EVENTS_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(EVENTS_BODY, file_contents)

    file_contents = ""
    with open(UTILITIES_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(UTILITIES_BODY, file_contents)

    file_contents = ""
    with open(VERSION_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(VERSION_BODY, file_contents)

    file_contents = ""
    with open(STATE_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(STATE_BODY, file_contents)

    file_contents = ""
    with open(VALIDATION_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(VALIDATION_BODY, file_contents)

    file_contents = ""
    with open(THREADING_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(THREADING_BODY, file_contents)

    file_contents = ""
    with open(GAERRORSEVERITY_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(GAERRORSEVERITY_BODY, file_contents)

    file_contents = ""
    with open(GAPROGRESSIONSTATUS_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(GAPROGRESSIONSTATUS_BODY, file_contents)

    file_contents = ""
    with open(GARESOURCEFLOWTYPE_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(GARESOURCEFLOWTYPE_BODY, file_contents)

    f = open(RBXMX_RELEASE_FILE, "w")
    f.write(rbxmx_contents)
    f.truncate()
    f.close()
    print('--- done generating rbxmx file ----')


if __name__ == '__main__':
    main()
