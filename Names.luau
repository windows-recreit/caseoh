--[[
    Names.luau
    Priority module: contains target names/paths for objects to highlight.
    Loaded FIRST by Loader. If this fails to load, ESP/Menu fall back to
    empty tables and features that depend on names will simply no-op
    (with a console warning) instead of erroring.

    Structure:
      NameTargets  -> objects matched by .Name, can have multiple instances
                       (e.g. "bananaPeel" appears many times under Workspace)
      PathTargets  -> objects matched by an explicit path, singular/fixed
                       (e.g. CaseChar). Path takes priority over a name match
                       if both would resolve the same instance.

    Path format: a table of strings representing the instance chain,
    starting from game. Example {"Workspace", "CaseChar"} == workspace.CaseChar
]]

local Names = {}

Names.NameTargets = {
    bananaPeel = {
        color = Color3.fromRGB(255, 255, 0),
        multiple = true, -- expect multiple instances with this name
    },
}

Names.PathTargets = {
    CaseChar = {
        path = {"Workspace", "CaseChar"},
        color = Color3.fromRGB(255, 0, 0),
    },
}

-- Misc fixed references used across modules (sounds, folders, etc.)
Names.References = {
    FightMusic = {"Workspace", "Sounds", "FightMusic"},
    Atmosphere = {"Lighting", "Atmosphere"},
    StinkPartName = "Stink", -- child name expected under HumanoidRootPart
}

Names.PlayerHighlight = {
    color = Color3.fromRGB(0, 255, 0),
}

return Names
