-- luacheck: ignore
-- (this file stubs the WoW API by assigning its globals; nothing here ships)
--
-- Headless smoke test: loads the addon in TOC order against a permissive stubbed
-- WoW API (any unknown global is a no-op), logs in, and works the settings page
-- and the minimap button. It draws nothing: layout still needs the game.
--
--   cd NightclawEars && lua5.1 tests/smoke.lua

local failures = 0
local function check(cond, msg)
    if cond then io.write("ok   " .. msg .. "\n") else failures = failures + 1; io.write("FAIL " .. msg .. "\n") end
end

---- A permissive widget: unknown methods are no-ops

local methods = {}
local Widget = {
    __index = function(_, k)
        if methods[k] then return methods[k] end
        if type(k) == "string" and k:match("^%u") then return function() end end
    end,
}
local function NewWidget(kind, name)
    return setmetatable({ kind = kind, name = name, scripts = {}, shown = true, w = 140, h = 140 }, Widget)
end
function methods.SetScript(self, k, fn) self.scripts[k] = fn end
function methods.GetScript(self, k) return self.scripts[k] end
function methods.Show(self)
    local was = self.shown
    self.shown = true
    if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods.Hide(self) self.shown = false end
function methods.SetShown(self, on) if on then self:Show() else self:Hide() end end
function methods.IsShown(self) return self.shown end
function methods.SetText(self, t) self.text = t end
function methods.GetText(self) return self.text or "" end
function methods.GetWidth(self) return self.w end
function methods.GetHeight(self) return self.h end
function methods.GetCenter() return 100, 100 end
function methods.GetEffectiveScale() return 1 end
function methods.CreateTexture() return NewWidget("Texture") end
function methods.CreateFontString() return NewWidget("FontString") end
function methods.CreateMaskTexture() return NewWidget("MaskTexture") end
function methods.RegisterEvent(self, e) self.events = self.events or {}; self.events[e] = true end
function methods.UnregisterEvent(self, e) if self.events then self.events[e] = nil end end

---- Globals: anything not stubbed here is a function that returns nothing

local frames = {}
function CreateFrame(kind, name)
    local f = NewWidget(kind, name)
    if name then _G[name] = f end
    table.insert(frames, f)
    return f
end
UIParent = NewWidget("Frame", "UIParent")
Minimap = NewWidget("Frame", "Minimap")
GameTooltip = NewWidget("GameTooltip", "GameTooltip")
function GetCursorPosition() return 0, 0 end
SlashCmdList = {}
Enum = { TooltipDataType = { Item = 0 } }
TooltipDataProcessor = { AddTooltipPostCall = function() end }
C_Item = { GetItemCount = function() return 0 end, GetItemIconByID = function() return 0 end }
C_Reputation = { GetFactionDataByID = function() return nil end }
C_QuestLog = { IsQuestFlaggedCompleted = function() return false end }
C_Map = { GetBestMapForUnit = function() return nil end, GetMapInfo = function() return nil end }
C_Timer = { After = function() end }
local category = { GetID = function() return 1 end }
local registered
Settings = {
    RegisterCanvasLayoutCategory = function(panel) registered = panel; return category end,
    RegisterAddOnCategory = function() end,
    OpenToCategory = function() end,
}
local said = {}
function print(msg) table.insert(said, msg) end
setmetatable(_G, { __index = function(_, k)
    -- (saved variables start out nil, as in the game)
    if type(k) == "string" and k:match("^%u") and not k:match("DB$") then return function() end end
end })

---- Load in TOC order, log in

local ns = {}
for line in io.lines("NightclawEars.toc") do
    if line:match("%.lua$") then assert(loadfile(line))("NightclawEars", ns) end
end
local function Fire(event, ...)
    for _, f in ipairs(frames) do
        if f.events and f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
    end
end
Fire("ADDON_LOADED", "NightclawEars")
Fire("PLAYER_LOGIN")

---- The minimap button and its setting

local mb = NightclawEarsMinimapButton
check(mb and mb.shown, "minimap: the button is there")
check(NightclawEarsDB.minimap == true and NightclawEarsDB.minimapAngle == 245, "minimap: defaults saved")

SlashCmdList.NIGHTCLAWEARS("minimap")
check(not mb.shown and NightclawEarsDB.minimap == false, "minimap: /ears minimap hides it")

check(registered and registered == NightclawEarsOptions, "settings: the page is registered")
registered:Show()
local tick = ns.settingsTicks.minimap
check(tick and tick.checked == false, "settings: the minimap tick follows /ears minimap (unticked)")
check(ns.settingsTicks.turnin.checked == true and ns.settingsTicks.locked.checked == false,
    "settings: the other ticks show their settings")
tick.scripts.OnClick(tick)
check(mb.shown and NightclawEarsDB.minimap == true, "settings: the tick shows the button again")

mb.scripts.OnEnter(mb); mb.scripts.OnDragStart(mb); mb.scripts.OnUpdate(mb); mb.scripts.OnDragStop(mb)
check(type(NightclawEarsDB.minimapAngle) == "number" and NightclawEarsDB.minimapAngle ~= 245,
    "minimap: dragging saves its place")

local before = NightclawEarsDB.shown
mb.scripts.OnClick(mb, "LeftButton")
check(NightclawEarsDB.shown ~= before, "minimap: left-click shows or hides the panel")

io.write(failures == 0 and "all passed\n" or (failures .. " failed\n"))
os.exit(failures == 0 and 0 or 1)
