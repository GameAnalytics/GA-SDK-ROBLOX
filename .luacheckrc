stds.roblox = {
    globals = {
        "game",
        "workspace",
        "script",
    },

    read_globals = {
        -- Global objects
        "plugin",

        -- Global functions
        "spawn",
        "delay",
        "warn",
        "wait",
        "tick",
        "typeof",
        "settings",
        "UserSettings",

        -- Global Namespaces
        "Enum",
        "debug",

        math = {
            fields = {
                "clamp",
                "sign",
                "noise"
            }
        },

        debug = {
            fields = {
                "profilebegin",
                "profileend"
            }
        },

        table = {
            fields = {
                "create"
            }
        },

        -- Global types
        "Instance",
        "Vector2",
        "Vector3",
        "CFrame",
        "Region3",
        "Color3",
        "UDim",
        "UDim2",
        "BrickColor",
        "Rect",
        "TweenInfo",
        "NumberRange",
        "NumberSequence",
        "NumberSequenceKeypoint",
        "Random",
        "Ray",
        "ColorSequence",
        "ColorSequenceKeypoint",
        "PhysicalProperties",
        "NumberSequence",
        "NumberSequenceKeypoint"
    }
}

ignore = { "111", "113", "631" }

std = "lua51+roblox"
