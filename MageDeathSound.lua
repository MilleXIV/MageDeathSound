local addonName, MDS = ...
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

local defaults = {
    sound = "Squeaky Toy Short",
    onSelf = true
}

local eventFrame = CreateFrame("Frame")

MDS.catId = 0
MDS.playerName = ""
eventFrame:RegisterEvent("UNIT_DIED")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addOnName = ...
        if addOnName == "MageDeathSound" then
            self:UnregisterEvent("ADDON_LOADED")
            LSM:Register(LSM.MediaType.SOUND, "Squeaky Toy Short", [[Interface\Addons\MageDeathSound\sounds\SqueakyToyShort.ogg]])
            MageDeathSoundDB = MageDeathSoundDB or CopyTable(defaults)
            MDS.db = MageDeathSoundDB
        end
    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        print("MDS: Loading MageDeathSound...")
        MDS:InitOptions()
        MDS.playerName = string.join(" ", UnitName("player"))
    elseif event == "UNIT_DIED" then
        local guid = ...
        local _, cName, _, _, _, name, _ = GetPlayerInfoByGUID(guid)
        if cName == nil then return end
        if cName ~= "MAGE" then return end
        if name == MDS.playerName and not MDS.db.onSelf then return end
        if C_RestrictedActions.GetAddOnRestrictionState(Enum.AddOnRestrictionType.Map) == Enum.AddOnRestrictionState.Active then
            PlaySoundFile(LSM:Fetch(LSM.MediaType.SOUND, MDS.db.sound), "master")
            return
        end
        if C_PartyInfo.IsGUIDInGroup(guid) then
            PlaySoundFile(LSM:Fetch(LSM.MediaType.SOUND, MDS.db.sound), "master")
            return
        end
    end
end)

function MDS:InitOptions()
    print("MDS: Adding options...")
    local category = Settings.RegisterVerticalLayoutCategory("Mage Death Sound")
    do
        local setting = Settings.RegisterAddOnSetting(category, "MDS_OnSelf", "onSelf", MDS.db, type(defaults.onSelf), "Play on Own Death", defaults.onSelf)
        setting:SetValueChangedCallback(function (_, value)
            MDS.db.onSelf = value
        end)
        Settings.CreateCheckbox(category, setting, "Toggle playing sound on own death")
    end
    do
        local setting = Settings.RegisterAddOnSetting(category, "MDS_Sound", "sound", MDS.db, type(defaults.sound), "Death Sound", defaults.sound)
        setting:SetValueChangedCallback(function (_, value)
            MDS.db.sound = value
        end)
        Settings.CreateDropdown(category, setting, function ()
            local container = Settings.CreateControlTextContainer()
            for _, item in pairs(LSM:List(LSM.MediaType.SOUND)) do
                container:Add(item, item)
            end
            return container:GetData()
        end, "Sound to play when a Mage dies")
    end
    Settings.RegisterAddOnCategory(category)
    MDS.catId = category:GetID()
end

function MDS.HandleCommand()
    Settings.OpenToCategory(MDS.catId)
end

SLASH_MAGEDEATHSOUND1 = "/mds"
SlashCmdList.MAGEDEATHSOUND = function() MDS.HandleCommand() end