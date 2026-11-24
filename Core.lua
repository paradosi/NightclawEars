---- Core — count Al'Aketh Cultist's Ears against what Exalted with the Nightclaw Druids costs

local addonName = ...

local FACTION   = 2758    -- Nightclaw Druids (Shadowgale Forest)
local EAR       = 258771  -- Al'Aketh Cultist's Ear
local FIRST     = 93165   -- "Mercy Falls on Deaf Ears": once, 5 ears, 1000 rep
local REPEAT    = 93459   -- "More Al'Aketh Ears": the repeatable, Vayn Moonclaw
local FIRST_EARS, FIRST_REP = 5, 1000
local EXALTED   = 42000   -- currentStanding at which Exalted starts (Neutral = 0)

-- Ears and rep per repeatable turn-in. The quest text says 10 ears, its objective
-- data says 5; Wowhead says 200 rep. Both are replaced by what the game shows:
-- ears from the turn-in window (QUEST_PROGRESS), rep from the actual gain.
local DEFAULTS = { ears = 5, rep = 200, shown = true, locked = false }

local db
local frame, lines = nil, {}

local function Num(n)
    return FormatLargeNumber and FormatLargeNumber(n) or tostring(n)
end

local function Say(msg)
    print("|cff9370dbNightclaw Ears|r: " .. msg)
end

local function EarCount()
    return C_Item.GetItemCount(EAR) or 0, C_Item.GetItemCount(EAR, true) or 0
end

-- Standing, or Neutral 0 for a faction the character hasn't met yet
local function Faction()
    local f = C_Reputation.GetFactionDataByID(FACTION)
    if f and f.name and f.name ~= "" then return f, true end
    return { name = "Nightclaw Druids", reaction = 4, currentStanding = 0,
             currentReactionThreshold = 0, nextReactionThreshold = 3000 }, false
end

-- What is left to Exalted, in rep, turn-ins and ears
local function Need()
    local f = Faction()
    local remaining = math.max(0, EXALTED - (f.currentStanding or 0))
    local ears, turnins = 0, 0
    if remaining > 0 and not C_QuestLog.IsQuestFlaggedCompleted(FIRST) then
        remaining = remaining - FIRST_REP
        ears, turnins = FIRST_EARS, 1
    end
    if remaining > 0 then
        local n = math.ceil(remaining / db.rep)
        ears, turnins = ears + n * db.ears, turnins + n
    end
    return math.max(0, EXALTED - (f.currentStanding or 0)), turnins, ears
end

local function StandingLabel(reaction)
    return _G["FACTION_STANDING_LABEL" .. (reaction or 4)] or "?"
end

---- Panel

local function Refresh()
    if not frame or not frame:IsShown() then return end
    local f, met = Faction()
    local bags, all = EarCount()
    local rep, turnins, ears = Need()
    local color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[f.reaction or 4]
    local hex = color and string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255) or "|cffffffff"

    local into = (f.currentStanding or 0) - (f.currentReactionThreshold or 0)
    local size = (f.nextReactionThreshold or 0) - (f.currentReactionThreshold or 0)
    lines[1]:SetText(hex .. StandingLabel(f.reaction) .. "|r" ..
        (f.reaction and f.reaction < 8 and size > 0 and ("  " .. Num(into) .. " / " .. Num(size)) or "") ..
        (met and "" or "  |cff888888(not met yet)|r"))
    lines[2]:SetText("Ears: |cffffffff" .. Num(bags) .. "|r" .. (all > bags and ("  (+" .. Num(all - bags) .. " in bank)") or ""))

    if rep == 0 then
        lines[3]:SetText("|cff00ff00Exalted.|r")
        lines[4]:SetText("")
    elseif db.cappedAt and (f.reaction or 4) >= db.cappedAt then
        lines[3]:SetText("|cffff8000Turn-ins stopped giving rep at " .. StandingLabel(db.cappedAt) .. ".|r")
        lines[4]:SetText(Num(rep) .. " rep to Exalted from elsewhere")
    else
        local more = math.max(0, ears - all)
        lines[3]:SetText("To Exalted: |cffffffff" .. Num(rep) .. "|r rep, " .. Num(turnins) .. " turn-ins")
        lines[4]:SetText(Num(ears) .. " ears, |cffffd100" .. Num(more) .. " more|r to collect")
    end
    lines[5]:SetText("|cff888888" .. db.ears .. " ears = " .. db.rep .. " rep per turn-in|r")
end

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    db.point = { point, relPoint, x, y }
end

local function BuildFrame()
    frame = CreateFrame("Frame", "NightclawEarsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(230, 104)
    frame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    frame:SetBackdropColor(0, 0, 0, 0.75)
    frame:SetBackdropBorderColor(0.58, 0.44, 0.86)
    local p = db.point
    if p then frame:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else frame:SetPoint("CENTER", UIParent, "CENTER", 300, 0) end
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not db.locked then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition() end)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("TOPLEFT", 10, -9)
    icon:SetTexture(C_Item.GetItemIconByID(EAR))

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    title:SetText("Nightclaw Druids")

    local prev = icon
    for i = 1, 5 do
        local fs = frame:CreateFontString(nil, "OVERLAY", i == 5 and "GameFontNormalSmall" or "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, i == 1 and -6 or -3)
        fs:SetJustifyH("LEFT")
        lines[i] = fs
        prev = fs
    end
    frame:SetScript("OnShow", Refresh)
end

local function SetShown(show)
    db.shown = show
    if show and not frame then BuildFrame() end
    if frame then frame:SetShown(show) end
    Refresh()
end

function NightclawEars_OnCompartmentClick()
    SetShown(not db.shown)
end

---- Learning ears and rep per turn-in

local lastStanding, lastChange, pendingTurnIn

local function LearnRep(delta)
    if delta > 0 then
        if delta ~= db.rep then Say("a turn-in gives " .. delta .. " rep (was " .. db.rep .. ").") end
        db.rep, db.cappedAt = delta, nil
    end
end

local function OnFactionChanged()
    local f = Faction()
    local s = f.currentStanding or 0
    if lastStanding and s ~= lastStanding then
        local delta = s - lastStanding
        lastChange = { delta = delta, t = GetTime() }
        if pendingTurnIn and GetTime() - pendingTurnIn < 3 then
            pendingTurnIn = nil
            LearnRep(delta)
        end
    end
    lastStanding = s
end

local function OnTurnedIn(questID)
    if questID ~= REPEAT then return end
    if lastChange and GetTime() - lastChange.t < 1 then
        LearnRep(lastChange.delta)
    else
        -- The rep may still be on its way; if none comes, the repeatable has hit its cap
        pendingTurnIn = GetTime()
        C_Timer.After(3, function()
            if pendingTurnIn then
                pendingTurnIn = nil
                db.cappedAt = Faction().reaction
                Say("that turn-in gave no reputation: the repeatable stops at " .. StandingLabel(db.cappedAt) .. ".")
                Refresh()
            end
        end)
    end
    C_Timer.After(1, function()
        local rep, _, ears = Need()
        if rep > 0 then Say(Num(rep) .. " rep to Exalted: " .. Num(math.max(0, ears - select(2, EarCount()))) .. " more ears.") end
        Refresh()
    end)
end

-- The turn-in window lists the ears the quest takes
local function OnQuestProgress()
    if GetQuestID() ~= REPEAT then return end
    for i = 1, GetNumQuestItems() do
        local _, _, count, _, _, itemID = GetQuestItemInfo("required", i)
        if itemID == EAR and count and count > 0 and count ~= db.ears then
            Say("a turn-in takes " .. count .. " ears (was " .. db.ears .. ").")
            db.ears = count
            Refresh()
        end
    end
end

---- Tooltip line on the ear itself

local function AddTooltip(tooltip, data)
    if not data or data.id ~= EAR or not db then return end
    local rep, _, ears = Need()
    if rep == 0 then
        tooltip:AddLine("Nightclaw Druids: Exalted", 0, 1, 0)
    else
        local more = math.max(0, ears - select(2, EarCount()))
        tooltip:AddLine(string.format("Nightclaw Druids: %s more ears to Exalted", Num(more)), 0.58, 0.44, 0.86)
    end
end

---- Events and slash command

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        NightclawEarsDB = NightclawEarsDB or {}
        db = NightclawEarsDB
        for k, v in pairs(DEFAULTS) do if db[k] == nil then db[k] = v end end
        if TooltipDataProcessor and Enum.TooltipDataType then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddTooltip)
        end
    elseif event == "PLAYER_LOGIN" then
        lastStanding = Faction().currentStanding or 0
        events:RegisterEvent("UPDATE_FACTION")
        events:RegisterEvent("BAG_UPDATE_DELAYED")
        events:RegisterEvent("QUEST_PROGRESS")
        events:RegisterEvent("QUEST_TURNED_IN")
        if db.shown then SetShown(true) end
    elseif event == "UPDATE_FACTION" then
        OnFactionChanged()
        Refresh()
    elseif event == "BAG_UPDATE_DELAYED" then
        Refresh()
    elseif event == "QUEST_PROGRESS" then
        OnQuestProgress()
    elseif event == "QUEST_TURNED_IN" then
        OnTurnedIn(arg1)
    end
end)

SLASH_NIGHTCLAWEARS1 = "/ears"
SlashCmdList.NIGHTCLAWEARS = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "lock" then
        db.locked = not db.locked
        Say(db.locked and "panel locked." or "panel unlocked: drag to move.")
    elseif msg == "reset" then
        db.point = nil
        if frame then frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", 300, 0) end
        Say("panel moved back to the middle.")
    elseif msg == "help" then
        Say("/ears shows or hides the panel · /ears lock · /ears reset (position)")
    else
        SetShown(not db.shown)
    end
end
