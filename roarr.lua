-- ROARR v1.0 (Vanilla/Turtle 1.12, Lua 5.0-safe)
-- SavedVariables: ROARRDB
-- Plays a random battle-themed emote when pressing a configured action bar slot.

-------------------------------------------------
-- Battle emote pool
-------------------------------------------------
local EMOTE_TOKENS_BATTLE = {
  "ROAR","CHARGE","CHEER","BORED","FLEX"
}

-------------------------------------------------
-- State
-------------------------------------------------
local WATCH_SLOT = nil
local WATCH_MODE = false
local LAST_BATTLE_EMOTE_TIME = 0
local BATTLE_COOLDOWN = 6    -- seconds
local battle_chance = 100    -- % chance to fire
local ENABLED = true

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function chat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444ROARR:|r " .. text)
  end
end

local function ensureDB()
  if type(ROARRDB) ~= "table" then ROARRDB = {} end
  return ROARRDB
end

local _roarr_loaded_once = false
local function ensureLoaded()
  if not _roarr_loaded_once then
    local db = ensureDB()
    WATCH_SLOT = db.slot or WATCH_SLOT
    if db.battle_cd then BATTLE_COOLDOWN = db.battle_cd end
    if db.battle_chance then battle_chance = db.battle_chance end
    if db.enabled ~= nil then ENABLED = db.enabled end
    _roarr_loaded_once = true
  end
end

local function pick(t)
  local n = table.getn(t)
  if n < 1 then return nil end
  return t[math.random(1, n)]
end

local function performBuiltInEmote(token)
  if DoEmote then
    DoEmote(token)
  else
    SendChatMessage("makes a battle cry!", "EMOTE") -- fallback
  end
end

local function doBattleEmoteNow()
  if not ENABLED then return end
  local now = GetTime()
  if now - LAST_BATTLE_EMOTE_TIME < BATTLE_COOLDOWN then return end
  LAST_BATTLE_EMOTE_TIME = now
  if math.random(1, 100) <= battle_chance then
    local e = pick(EMOTE_TOKENS_BATTLE)
    if e then performBuiltInEmote(e) end
  end
end

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
    doBattleEmoteNow()
  end
  return _Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- Slash Commands (/roarr)
-------------------------------------------------
SLASH_ROARR1 = "/roarr"
SlashCmdList["ROARR"] = function(raw)
  ensureLoaded()
  local cmd, rest = split_cmd(raw)

  if cmd == "slot" then
    local n = tonumber(rest)
    if n then
      WATCH_SLOT = n
      ensureDB().slot = n
      chat("watching slot " .. n .. " (saved).")
    else
      chat("usage: /roarr slot <number>")
    end

  elseif cmd == "watch" then
    WATCH_MODE = not WATCH_MODE
    chat("watch mode " .. (WATCH_MODE and "ON" or "OFF"))

  elseif cmd == "chance" then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 100 then
      battle_chance = n
      ensureDB().battle_chance = n
      chat("battle emote chance set to " .. n .. "%")
    else
      chat("usage: /roarr chance <0-100>")
    end

  elseif cmd == "cd" then
    local n = tonumber(rest)
    if n and n >= 0 then
      BATTLE_COOLDOWN = n
      ensureDB().battle_cd = n
      chat("battle cooldown set to " .. n .. "s")
    else
      chat("usage: /roarr cd <seconds>")
    end

  elseif cmd == "on" then
    ENABLED = true
    ensureDB().enabled = true
    chat("ROARR enabled.")

  elseif cmd == "off" then
    ENABLED = false
    ensureDB().enabled = false
    chat("ROARR disabled.")

  elseif cmd == "info" then
    chat("watching slot: " .. (WATCH_SLOT and tostring(WATCH_SLOT) or "none"))
    chat("battle chance: " .. tostring(battle_chance) ..
        "% | cooldown: " .. tostring(BATTLE_COOLDOWN) ..
        "s | enabled: " .. tostring(ENABLED) ..
        " | pool: " .. tostring(table.getn(EMOTE_TOKENS_BATTLE)) .. " emotes")

  elseif cmd == "reset" then
    WATCH_SLOT = nil
    ensureDB().slot = nil
    chat("cleared saved slot.")

  elseif cmd == "save" then
    local db = ensureDB()
    db.slot = WATCH_SLOT
    db.battle_chance = battle_chance
    db.battle_cd = BATTLE_COOLDOWN
    db.enabled = ENABLED
    chat("settings saved.")

  elseif cmd == "tutorial" then
    chat("/roarr watch | slot <n> | chance <0-100> | cd <seconds> | on/off | info | reset | save")

  else
    chat("/roarr slot <n> | watch | chance <0-100> | cd <seconds> | on/off | info | reset | save | tutorial")
  end
end

-------------------------------------------------
-- Init / RNG
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
    db.battle_chance = battle_chance
    db.battle_cd = BATTLE_COOLDOWN
    db.enabled = ENABLED
  end
end)
