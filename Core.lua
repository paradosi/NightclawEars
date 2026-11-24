---- Core — count Al'Aketh Cultist's Ears against what Exalted with the Nightclaw Druids costs

local addonName = ...

local FACTION   = 2758    -- Nightclaw Druids (Shadowgale Forest)
local EAR       = 258771  -- Al'Aketh Cultist's Ear
local FIRST     = 93165   -- "Mercy Falls on Deaf Ears": once, 5 ears, 1000 rep
local REPEAT    = 93459   -- "More Al'Aketh Ears": the repeatable, Vayn Moongaze
local FIRST_EARS, FIRST_REP = 5, 1000
local EXALTED   = 42000   -- currentStanding at which Exalted starts (Neutral = 0)
local ZONE      = 2521    -- Zephras Isle (UI map): Shadowgale Forest, the Shrine of Akir, Gustberry Lowlands

-- Ears and rep per repeatable turn-in. The quest text says 10 ears, its objective
-- data says 5; Wowhead says 200 rep. Both are replaced by what the game shows:
-- ears from the turn-in window (QUEST_PROGRESS), rep from the actual gain.
-- shown: opened by hand (stays open everywhere). auto: open on arriving at Zephras Isle.
-- turnin: hand the ears in by itself when you talk to Vayn (Shift skips).
local DEFAULTS = { ears = 5, rep = 200, shown = false, locked = false, auto = true, turnin = true }
local VAYN = "Vayn Moongaze"  -- until the turn-in window gives his name as the client spells it (db.vayn)

local db
local frame

local function Num(n)
    return FormatLargeNumber and FormatLargeNumber(n) or tostring(n)
end

local function Say(msg)
    print("|cffe3b664Nightclaw Ears|r: " .. msg)
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

---- Panel, in wowdb.dev's look: navy surface, hairline borders, gold accent,
---- Oswald for labels and JetBrains Mono for numbers (both SIL OFL, media/fonts)

local FONTS = "Interface\\AddOns\\" .. addonName .. "\\media\\fonts\\"
local DISPLAY, DISPLAY_LIGHT = FONTS .. "Oswald-Regular.ttf", FONTS .. "Oswald-Light.ttf"
local MONO, MONO_MEDIUM = FONTS .. "JetBrainsMono-Regular.ttf", FONTS .. "JetBrainsMono-Medium.ttf"

-- wowdb's tokens (apps/web/app/globals.css)
local C = {
    bg        = { 0.086, 0.106, 0.161, 0.96 },  -- --bg #161b29
    deep      = { 0.063, 0.075, 0.114, 1 },     -- --bg-deep #10131d
    track     = { 0.890, 0.714, 0.392, 0.18 },  -- the bar's empty part: gold, faint, so it shows on the navy
    border    = { 1, 1, 1, 0.10 },              -- --border
    divider   = { 1, 1, 1, 0.07 },              -- --divider
    primary   = { 0.961, 0.969, 0.988 },        -- --text-primary #f5f7fc
    secondary = { 0.761, 0.784, 0.855 },        -- --text-secondary #c2c8da
    muted     = { 0.588, 0.616, 0.702 },        -- --text-muted #969db3
    accent    = { 0.890, 0.714, 0.392 },        -- --accent #e3b664
    accentHi  = { 0.953, 0.835, 0.584 },        -- --accent-hi #f3d595
    chip      = { 0.890, 0.714, 0.392, 0.16 },  -- --chip-accent
    place     = { 0.953, 0.663, 0.510 },        -- --place #f3a982
}
local W, PAD = 256, 14
local TRACK_W = W - PAD * 2 - 34 - 10  -- the bar, right of the 34px icon
local ui = {}

local function Fill(tex, c) tex:SetColorTexture(c[1], c[2], c[3], c[4] or 1) end

local function Text(parent, font, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(font, size, "")
    fs:SetTextColor(color[1], color[2], color[3])
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    return fs
end

local function Line(parent, y, c, x1, x2)
    local t = parent:CreateTexture(nil, "BORDER")
    Fill(t, c)
    t:SetHeight(1)
    t:SetPoint("TOPLEFT", x1 or 0, y)
    t:SetPoint("TOPRIGHT", -(x2 or 0), y)
    return t
end

-- --gold-line: transparent → gold → transparent
local function GoldLine(parent, y)
    local a, b = parent:CreateTexture(nil, "BORDER"), parent:CreateTexture(nil, "BORDER")
    for _, t in ipairs({ a, b }) do t:SetColorTexture(1, 1, 1, 1); t:SetHeight(1) end
    a:SetPoint("TOPLEFT", 0, y); a:SetPoint("TOPRIGHT", parent, "TOP", 0, y)
    b:SetPoint("TOPLEFT", parent, "TOP", 0, y); b:SetPoint("TOPRIGHT", 0, y)
    local r, g, bl = C.accentHi[1], C.accentHi[2], C.accentHi[3]
    a:SetGradient("HORIZONTAL", CreateColor(r, g, bl, 0), CreateColor(r, g, bl, 0.8))
    b:SetGradient("HORIZONTAL", CreateColor(r, g, bl, 0.8), CreateColor(r, g, bl, 0))
end

-- A facts row: uppercase Oswald label on the left, mono value on the right, hairline under it
local function Row(y, label, big)
    local l = Text(frame, DISPLAY, 10, C.muted)
    l:SetPoint("LEFT", frame, "TOPLEFT", PAD, y - 10)
    l:SetText(label)
    local v = Text(frame, big and MONO_MEDIUM or MONO, big and 15 or 11, big and C.accent or C.primary, "RIGHT")
    v:SetPoint("RIGHT", frame, "TOPRIGHT", -PAD, y - 10)
    Line(frame, y - 20, C.divider, PAD, PAD)
    return v
end

local function Refresh()
    if not frame or not frame:IsShown() then return end
    local f, met = Faction()
    local bags, all = EarCount()
    local rep, turnins, ears = Need()

    ui.standing:SetText(StandingLabel(f.reaction))
    ui.notMet:SetText(met and "" or "not met yet")
    local into = (f.currentStanding or 0) - (f.currentReactionThreshold or 0)
    local size = (f.nextReactionThreshold or 0) - (f.currentReactionThreshold or 0)
    local exalted = rep == 0
    if exalted or size <= 0 then
        ui.progress:SetText("")
        ui.fill:SetWidth(TRACK_W)
    else
        ui.progress:SetText(Num(into) .. " / " .. Num(size))
        ui.fill:SetWidth(math.max(2, TRACK_W * math.min(1, into / size)))  -- a 2px sliver at the start
    end

    ui.ears:SetText(Num(bags) .. (all > bags and ("  |cff969db3+" .. Num(all - bags) .. " bank|r") or ""))
    if exalted then
        ui.rep:SetText("|cffe3b664Exalted|r")
        ui.turnins:SetText("—")
        ui.more:SetText("0")
    elseif db.cappedAt and (f.reaction or 4) >= db.cappedAt then
        ui.rep:SetText(Num(rep) .. " rep")
        ui.turnins:SetText("|cfff3a982no rep past " .. StandingLabel(db.cappedAt) .. "|r")
        ui.more:SetText("—")
    else
        ui.rep:SetText(Num(rep) .. " rep")
        ui.turnins:SetText(Num(turnins))
        ui.more:SetText(Num(math.max(0, ears - all)))
    end
    ui.rate:SetText(db.ears .. " ears = " .. db.rep .. " rep per turn-in")
    ui.auto:SetText(db.turnin and "auto turn-in" or "auto turn-in off")
    ui.auto:SetTextColor(unpack(db.turnin and C.accent or C.muted))
end

local targetButton

local function VaynName() return db.vayn or VAYN end

-- Point the button at his name. Attributes on a secure button can't change in combat.
local function SetTarget()
    if not targetButton or InCombatLockdown() then return end
    targetButton:SetAttribute("macrotext", "/target " .. VaynName())
    targetButton.label:SetText("TARGET " .. VaynName():upper())
end

-- A secure macro button: /target Vayn Moongaze. Talking to him still takes your own
-- click or the "Interact with Target" key: addons can't start an NPC conversation.
-- Forever's secure buttons get OnClick on the press only, so it acts on the down.
local function TargetButton()
    local b = CreateFrame("Button", "NightclawEarsTargetButton", frame, "SecureActionButtonTemplate")
    b:SetPoint("TOPLEFT", PAD, -186)
    b:SetPoint("TOPRIGHT", -PAD, -186)
    b:SetHeight(22)
    b:RegisterForClicks("AnyDown")
    b:SetAttribute("useOnKeyDown", true)
    b:SetAttribute("type", "macro")

    local bg = b:CreateTexture(nil, "BACKGROUND"); Fill(bg, C.chip); bg:SetAllPoints()
    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.14); hl:SetAllPoints()
    for _, side in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" } }) do
        local t = b:CreateTexture(nil, "BORDER"); t:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.35)
        t:SetPoint(side[1]); t:SetPoint(side[2]); t:SetHeight(1)
    end
    b.label = Text(b, DISPLAY, 10, C.accent, "CENTER")
    b.label:SetPoint("CENTER")

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Target " .. VaynName(), 1, 1, 1)
        GameTooltip:AddLine("Then right-click him, or press your Interact with Target key.", 0.761, 0.784, 0.855, true)
        if db.turnin then
            GameTooltip:AddLine("The ears go in by themselves. Hold Shift as you talk to him to skip that.", 0.761, 0.784, 0.855, true)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    targetButton = b
    SetTarget()
end

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    db.point = { point, relPoint, x, y }
end

local function BuildFrame()
    frame = CreateFrame("Frame", "NightclawEarsFrame", UIParent)
    frame:SetSize(W, 240)
    frame:SetFrameStrata("MEDIUM")
    local p = db.point
    if p then frame:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else frame:SetPoint("CENTER", UIParent, "CENTER", 300, 0) end
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    -- The target button is secure, which makes the panel protected in combat: no moving it then
    frame:SetScript("OnDragStart", function(self) if not db.locked and not InCombatLockdown() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition() end)

    -- Surface with a 1px inset border (box-shadow: inset 0 0 0 1px var(--border))
    local bg = frame:CreateTexture(nil, "BACKGROUND"); Fill(bg, C.bg); bg:SetAllPoints()
    local head = frame:CreateTexture(nil, "BACKGROUND", nil, 1); Fill(head, C.deep)
    head:SetPoint("TOPLEFT"); head:SetPoint("TOPRIGHT"); head:SetHeight(34)
    for _, side in ipairs({ { "TOPLEFT", "TOPRIGHT", nil, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
                            { "TOPLEFT", "BOTTOMLEFT", 1, nil }, { "TOPRIGHT", "BOTTOMRIGHT", 1, nil } }) do
        local t = frame:CreateTexture(nil, "BORDER"); Fill(t, C.border)
        t:SetPoint(side[1]); t:SetPoint(side[2])
        if side[3] then t:SetWidth(1) else t:SetHeight(1) end
    end

    -- Header: the gold dot, the name, and a chip, like wowdb's brand bar
    local dot = frame:CreateTexture(nil, "ARTWORK"); Fill(dot, C.accent)
    dot:SetSize(7, 7); dot:SetPoint("LEFT", frame, "TOPLEFT", PAD, -17)
    if frame.CreateMaskTexture and dot.AddMaskTexture then
        local mask = frame:CreateMaskTexture()
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(dot)
        dot:AddMaskTexture(mask)
    end
    local title = Text(frame, DISPLAY, 13, C.primary)
    title:SetPoint("LEFT", dot, "RIGHT", 8, 0)
    title:SetText("Nightclaw Druids")
    local chipText = Text(frame, DISPLAY, 9, C.accent)
    chipText:SetText("ZEPHRAS ISLE")
    chipText:SetPoint("RIGHT", frame, "TOPRIGHT", -PAD - 7, -17)
    local chip = frame:CreateTexture(nil, "ARTWORK"); Fill(chip, C.chip)
    chip:SetPoint("TOPLEFT", chipText, "TOPLEFT", -7, 4); chip:SetPoint("BOTTOMRIGHT", chipText, "BOTTOMRIGHT", 7, -4)
    GoldLine(frame, -34)

    -- Standing: the ear's icon, the standing in light Oswald, a thin gold bar
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(34, 34); icon:SetPoint("TOPLEFT", PAD, -48)
    icon:SetTexture(C_Item.GetItemIconByID(EAR)); icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local iconEdge = frame:CreateTexture(nil, "BORDER"); Fill(iconEdge, C.border)
    iconEdge:SetPoint("TOPLEFT", icon, -1, 1); iconEdge:SetPoint("BOTTOMRIGHT", icon, 1, -1)

    ui.standing = Text(frame, DISPLAY_LIGHT, 22, C.primary)
    ui.standing:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 3)
    ui.notMet = Text(frame, MONO, 9, C.muted)
    ui.notMet:SetPoint("BOTTOMLEFT", ui.standing, "BOTTOMRIGHT", 6, 4)
    ui.progress = Text(frame, MONO, 10, C.secondary, "RIGHT")
    ui.progress:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -PAD, -66)

    ui.track = frame:CreateTexture(nil, "ARTWORK"); Fill(ui.track, C.track)
    ui.track:SetHeight(4)
    ui.track:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 1)
    ui.track:SetWidth(TRACK_W)
    ui.fill = frame:CreateTexture(nil, "ARTWORK", nil, 1); Fill(ui.fill, C.accent)
    ui.fill:SetHeight(4); ui.fill:SetPoint("LEFT", ui.track, "LEFT")

    -- Facts, as wowdb's item pages list them
    ui.ears    = Row(-96, "EARS")
    ui.rep     = Row(-118, "TO EXALTED")
    ui.turnins = Row(-140, "TURN-INS")
    ui.more    = Row(-162, "STILL TO COLLECT", true)
    TargetButton()

    ui.rate = Text(frame, MONO, 9, C.muted)
    ui.rate:SetPoint("BOTTOMLEFT", PAD, 11)
    ui.auto = Text(frame, MONO, 9, C.accent, "RIGHT")
    ui.auto:SetPoint("BOTTOMRIGHT", -PAD, 11)

    frame:SetScript("OnShow", Refresh)
end

local autoShown = false  -- opened by arriving in the zone, so leaving closes it
local afterCombat        -- show/hide asked for during combat, done when it ends

local function ShowPanel(show)
    if InCombatLockdown() then afterCombat = show; return end
    afterCombat = nil
    if show and not frame then BuildFrame() end
    if frame then frame:SetShown(show) end
    Refresh()
end

-- By hand (/ears, the compartment button): remembered, and the zone leaves it alone
local function Toggle()
    local show = not (frame and frame:IsShown())
    if afterCombat ~= nil then show = not afterCombat end
    db.shown, autoShown = show, false
    ShowPanel(show)
    if InCombatLockdown() then Say(show and "the panel opens after combat." or "the panel closes after combat.") end
end

function NightclawEars_OnCompartmentClick()
    Toggle()
end

---- Zephras Isle: open on arrival, close on leaving

local function InZone()
    local m = C_Map.GetBestMapForUnit("player")
    for _ = 1, 10 do  -- the map itself or any parent (caves and towns have their own maps)
        if not m or m == 0 then return false end
        if m == ZONE then return true end
        local info = C_Map.GetMapInfo(m)
        m = info and info.parentMapID
    end
    return false
end

local wasInZone

local function OnZoneChanged()
    local inZone = InZone()
    if inZone == wasInZone then return end
    wasInZone = inZone
    if inZone then
        local open = frame and frame:IsShown()
        if db.auto and not open and Need() > 0 then
            autoShown = true
            ShowPanel(true)
        end
    elseif autoShown then
        autoShown = false
        if not db.shown then ShowPanel(false) end
    end
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

---- Auto turn-in: once you're talking to Vayn, pick the repeatable, hand the ears in,
---- take the reward. Only quest 93459, only with enough ears in your bags, never
---- with Shift held, and never when the reward is a choice.

local function AutoOK()
    return db.turnin and not IsShiftKeyDown()
end

local function EnoughEars()
    return (EarCount()) >= db.ears
end

-- Vayn's chat window (gossip NPCs)
local function OnGossipShow()
    if not AutoOK() or not EnoughEars() then return end
    for _, q in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
        if q.questID == REPEAT then C_GossipInfo.SelectActiveQuest(REPEAT); return end
    end
    for _, q in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
        if q.questID == REPEAT then C_GossipInfo.SelectAvailableQuest(REPEAT); return end
    end
end

-- The same list, for NPCs that open the quest window straight away
local function OnQuestGreeting()
    if not AutoOK() or not EnoughEars() then return end
    for i = 1, GetNumActiveQuests() do
        if GetActiveQuestID(i) == REPEAT then SelectActiveQuest(i); return end
    end
    for i = 1, GetNumAvailableQuests() do
        if select(5, GetAvailableQuestInfo(i)) == REPEAT then SelectAvailableQuest(i); return end
    end
end

local function OnQuestDetail()
    if GetQuestID() == REPEAT and AutoOK() and EnoughEars() then AcceptQuest() end
end

-- The turn-in window lists the ears the quest takes
local function OnQuestProgress()
    if GetQuestID() ~= REPEAT then return end
    -- UnitName can be a secret value on Forever (identity restrictions): never compare one
    local npc = UnitName("npc")
    if npc and (not canaccessvalue or canaccessvalue(npc)) and npc ~= "" and npc ~= db.vayn then
        db.vayn = npc; SetTarget()
    end
    for i = 1, GetNumQuestItems() do
        local _, _, count, _, _, itemID = GetQuestItemInfo("required", i)
        if itemID == EAR and count and count > 0 and count ~= db.ears then
            Say("a turn-in takes " .. count .. " ears (was " .. db.ears .. ").")
            db.ears = count
            Refresh()
        end
    end
    if AutoOK() and IsQuestCompletable() then CompleteQuest() end
end

local function OnQuestComplete()
    if GetQuestID() ~= REPEAT or not AutoOK() then return end
    local choices = GetNumQuestChoices()
    if choices <= 1 then GetQuestReward(choices) end
end

---- Tooltip line on the ear itself

local function AddTooltip(tooltip, data)
    if not data or data.id ~= EAR or not db then return end
    local rep, _, ears = Need()
    if rep == 0 then
        tooltip:AddLine("Nightclaw Druids: Exalted", 0, 1, 0)
    else
        local more = math.max(0, ears - select(2, EarCount()))
        tooltip:AddLine(string.format("Nightclaw Druids: %s more ears to Exalted", Num(more)), 0.890, 0.714, 0.392)
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
        events:RegisterEvent("GOSSIP_SHOW")
        events:RegisterEvent("QUEST_GREETING")
        events:RegisterEvent("QUEST_DETAIL")
        events:RegisterEvent("QUEST_COMPLETE")
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        events:RegisterEvent("PLAYER_ENTERING_WORLD")
        events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        events:RegisterEvent("ZONE_CHANGED")
        if db.shown then ShowPanel(true) end
        OnZoneChanged()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        OnZoneChanged()
    elseif event == "UPDATE_FACTION" then
        OnFactionChanged()
        Refresh()
    elseif event == "BAG_UPDATE_DELAYED" then
        Refresh()
    elseif event == "QUEST_PROGRESS" then
        OnQuestProgress()
    elseif event == "QUEST_TURNED_IN" then
        OnTurnedIn(arg1)
    elseif event == "GOSSIP_SHOW" then
        OnGossipShow()
    elseif event == "QUEST_GREETING" then
        OnQuestGreeting()
    elseif event == "QUEST_DETAIL" then
        OnQuestDetail()
    elseif event == "QUEST_COMPLETE" then
        OnQuestComplete()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if afterCombat ~= nil then ShowPanel(afterCombat) end
        SetTarget()
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
    elseif msg == "auto" then
        db.auto = not db.auto
        Say(db.auto and "the panel opens when you arrive on Zephras Isle." or "the panel no longer opens by itself.")
    elseif msg == "turnin" or msg == "autoturnin" then
        db.turnin = not db.turnin
        Say(db.turnin and "ears go in by themselves when you talk to " .. VaynName() .. " (hold Shift to skip)."
            or "auto turn-in off: hand the ears in yourself.")
        Refresh()
    elseif msg == "help" then
        Say("/ears shows or hides the panel · /ears turnin (auto turn-in at Vayn) · /ears auto (open on Zephras Isle) · /ears lock · /ears reset (position)")
    else
        Toggle()
    end
end
