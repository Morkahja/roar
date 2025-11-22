-- ROAR Addon (Turtle WoW, Lua 5.0-safe)
-- SavedVariables: ROARDB

-------------------------------------------------
-- Emote Pool
-------------------------------------------------
local EMOTE_POOL = {
  "ROAR", "CHARGE", "CHEER", "BORED", "FLEX",
}

-------------------------------------------------
-- State
-------------------------------------------------
local WATCH_SLOT = nil
local WATCH_MODE = false
local LAST_EMOTE_TIME = 0
local ROAR_COOLDOWN = 6
local roar_chance = 100

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function chat(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800ROAR:|r " .. msg)
  end
end

local function ensureDB()
  if type(ROARDB) ~= "table" then ROARDB = {} end
  return ROARDB
end

local _r_loaded_once = false
local function ensureLoaded()
  if not _r_loaded_once then
    local db = ensureDB()
    WATCH_SLOT = db.slot or WATCH_SLOT
    if db.cooldown then ROAR_COOLDOWN = db.cooldown end
    if db.chance then roar_chance = db.chance end
    _r_loaded_once = true
  end
end

local function pick(tbl)
  local n = table.getn(tbl)
  if n < 1 then return nil end
  return tbl[math.random(1, n)]
end

local function performEmote(token)
  if DoEmote then
    DoEmote(token)
  else
    SendChatMessage("ist sehr animalisch...", "EMOTE")
  end
end

local function maybeEmoteNow()
  local now = GetTime()
  if now - LAST_EMOTE_TIME < ROAR_COOLDOWN then return end
  LAST_EMOTE_TIME = now
  if math.random(1, 100) <= roar_chance then
    local e = pick(EMOTE_POOL)
    if e then performEmote(e) end
  end
end

-- Lua 5.0-safe command splitter
local function split_cmd(raw)
  local s = raw or ""
  s = string.gsub(s, "^%s+", "")
  local _, _, cmd, rest = string.find(s, "^(%S+)%s*(.*)$")
  if not cmd then cmd = "" rest = "" end
  return cmd, rest
end

-------------------------------------------------
-- Hook UseAction
-------------------------------------------------
local _Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
  ensureLoaded()
  if WATCH_MODE then
    chat("pressed slot " .. tostring(slot))
  end
  if WATCH_SLOT and slot == WATCH_SLOT then
    maybeEmoteNow()
  end
  return _Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- Slash Command /roar
-------------------------------------------------
SLASH_ROAR1 = "/roar"
SlashCmdList["ROAR"] = function(raw)
  ensureLoaded()
  local cmd, rest = split_cmd(raw)

  if cmd == "slot" then
    local n = tonumber(rest)
    if n then
      WATCH_SLOT = n
      ensureDB().slot = n
      chat("watching slot " .. n .. " (saved)")
    else
      chat("usage: /roar slot <number>")
    end

  elseif cmd == "watch" then
    WATCH_MODE = not WATCH_MODE
    chat("watch mode " .. (WATCH_MODE and "ON" or "OFF"))

  elseif cmd == "chance" then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 100 then
      roar_chance = n
      ensureDB().chance = n
      chat("chance set to " .. n .. "%")
    else
      chat("usage: /roar chance <0-100>")
    end

  elseif cmd == "cd" then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 60 then
      ROAR_COOLDOWN = n
      ensureDB().cooldown = n
      chat("cooldown set to " .. n .. "s")
    else
      chat("usage: /roar cd <0-60>")
    end

  elseif cmd == "info" then
    chat("watching slot: " .. (WATCH_SLOT and tostring(WATCH_SLOT) or "none"))
    chat("chance: " .. tostring(roar_chance) .. "% | cooldown: " .. tostring(ROAR_COOLDOWN) .. "s | pool: " .. tostring(table.getn(EMOTE_POOL)))

  elseif cmd == "reset" then
    WATCH_SLOT = nil
    ensureDB().slot = nil
    chat("slot cleared")

  elseif cmd == "save" then
    local db = ensureDB()
    db.slot = WATCH_SLOT
    db.chance = roar_chance
    db.cooldown = ROAR_COOLDOWN
    chat("saved settings")

  else
    chat("/roar slot <n> | watch | chance <0-100> | cd <sec> | info | reset | save")
  end
end

-------------------------------------------------
-- Init
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    math.randomseed(math.floor(GetTime() * 1000)); math.random()
  elseif event == "PLAYER_LOGOUT" then
    local db = ensureDB()
    db.slot = WATCH_SLOT
    db.chance = roar_chance
    db.cooldown = ROAR_COOLDOWN
  end
end)
