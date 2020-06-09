#!/usr/bin/python
import os

ROBLOX_DIR = os.path.abspath(os.path.join(__file__, '..'))
ROBLOX_GA_DIR = os.path.join(ROBLOX_DIR, "GameAnalyticsSDK")
RBXMX_TMP_FILE = os.path.join(ROBLOX_DIR, "GameAnalyticsSDK.rbxmx.tmp")
RBXMX_RELEASE_FILE = os.path.join(ROBLOX_DIR, "release", "GameAnalyticsSDK.rbxmx")

POSTIE_BODY = 'Postie_BODY'
POSTIE_FILE = os.path.join(ROBLOX_GA_DIR, "Postie.lua")
GAMEANALYTICSSERVERINIT_BODY = 'GameAnalyticsServerInit_BODY'
GAMEANALYTICSSERVERINIT_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalyticsServerInit.server.lua")
INSTALL_BODY = 'INSTALL_BODY'
INSTALL_FILE = os.path.join(ROBLOX_GA_DIR, "INSTALL.txt")
GAMEANALYTICSCLIENT_BODY = 'GameAnalyticsClient_BODY'
GAMEANALYTICSCLIENT_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalyticsClient.client.lua")
GAMEANALYTICS_BODY = 'GameAnalytics_BODY'
GAMEANALYTICS_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "init.lua")
HTTPAPI_BODY = 'HttpApi_BODY'
HTTPAPI_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "init.lua")
HASHLIB_BODY = 'HashLib_BODY'
HASHLIB_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "HashLib", "init.lua")
BASE64_BODY = 'Base64_BODY'
BASE64_FILE = os.path.join(ROBLOX_GA_DIR, "GameAnalytics", "HttpApi", "HashLib", "Base64.lua")
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
    with open(POSTIE_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(POSTIE_BODY, file_contents)

    file_contents = ""
    with open(GAMEANALYTICSSERVERINIT_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(GAMEANALYTICSSERVERINIT_BODY, file_contents)

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
    with open(HTTPAPI_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(HTTPAPI_BODY, file_contents)

    file_contents = ""
    with open(HASHLIB_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(HASHLIB_BODY, file_contents)

    file_contents = ""
    with open(BASE64_FILE, 'r') as file:
        file_contents = file.read()
    rbxmx_contents = rbxmx_contents.replace(BASE64_BODY, file_contents)

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
