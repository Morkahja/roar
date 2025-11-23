-- ROARR v1.1
-- Turtle/Vanilla Lua 5.0 SAFE
-- SavedVariables: ROARRDB

-------------------------------------------------
-- Emote pool
-------------------------------------------------
local ROARR_EMOTES = {
  "ROAR", "CHEER", "CHARGE", "FLEX", "BORED"
}

-------------------------------------------------
-- State
-------------------------------------------------
local WATCH_SLOT = nil
local LAST_EMOTE = 0
local ROARR_COOLDOWN = 5
local ROARR_CHANCE = 100
local ROARR_ENABLED = true
local WATCH_MODE = false

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function chat(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffaa33ROARR:|r " .. msg)
  end
end

local function ensureDB()
  if type(ROARRDB) ~= "table" then ROARRDB = {} end
  return ROARRDB
end

local loaded_once = false
local function ensureLoaded()
  if loaded_once then return end
  loaded_once = true

  local db = ensureDB()
  WATCH_SLOT       = db.slot or WATCH_SLOT
  ROARR_COOLDOWN   = db.cooldown or ROARR_COOLDOWN
  ROARR_CHANCE     = db.chance or ROARR_CHANCE
  ROARR_ENABLED    = db.enabled
  WATCH_MODE       = db.watch
end

local function pick(t)
  local n = table.getn(t)
  if n < 1 then return nil end
  return t[math.random(1, n)]
end

local function doRandomEmote()
  if not ROARR_ENABLED then return end

  local now = GetTime()
  if now - LAST_EMOTE < ROARR_COOLDOWN then return end
  LAST_EMOTE = now

  if math.random(1, 100) <= ROARR_CHANCE then
    local e = pick(ROARR_EMOTES)
    if e then DoEmote(e) end
  end
end

-------------------------------------------------
-- Lua 5.0-safe command splitter
-------------------------------------------------
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
local Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
  ensureLoaded()

  if WATCH_MODE then
    chat("Pressed slot " .. tostring(slot))
  end

  if WATCH_SLOT and slot == WATCH_SLOT then
    doRandomEmote()
  end

  return Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- Slash Command (/raorr)
-------------------------------------------------
SLASH_RAORR1 = "/raorr"
SlashCmdList["RAORR"] = function(raw)
  ensureLoaded()
  local cmd, rest = split_cmd(raw)

  if cmd == "slot" then
    local n = tonumber(rest)
    if n then
      WATCH_SLOT = n
      ensureDB().slot = n
      chat("Watching slot " .. n .. " (saved).")
    else
      chat("Usage: /raorr slot <number>")

  elseif cmd == "chance" then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 100 then
      ROARR_CHANCE = n
      ensureDB().chance = n
      chat("Emote chance set to " .. n .. "%")
    else
      chat("Usage: /raorr chance <0-100>")

  elseif cmd == "cd" then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 60 then
      ROARR_COOLDOWN = n
      ensureDB().cooldown = n
      chat("Cooldown set to " .. n .. " seconds")
    else
      chat("Usage: /raorr cd <0-60>")

  elseif cmd == "on" then
    ROARR_ENABLED = true
    ensureDB().enabled = true
    chat("ROARR enabled.")

  elseif cmd == "off" then
    ROARR_ENABLED = false
    ensureDB().enabled = false
    chat("ROARR disabled.")

  elseif cmd == "watch" then
    WATCH_MODE = not WATCH_MODE
    ensureDB().watch = WATCH_MODE
    chat("Watch mode " .. (WATCH_MODE and "ON" or "OFF"))

  elseif cmd == "tutorial" then
    chat("ROARR tutorial:")
    chat("1. Use /raorr watch and press your action bar buttons to see their slot numbers.")
    chat("2. Set the watched slot with /raorr slot <n>.")
    chat("3. Adjust chance with /raorr chance <0-100>.")
    chat("4. Adjust cooldown with /raorr cd <seconds>.")
    chat("5. Toggle with /raorr on or /raorr off.")
    chat("6. Use /raorr info to see current settings.")
    chat("7. Use /raorr save to store current settings.")

  elseif cmd == "info" then
    chat("Watching slot: " .. (WATCH_SLOT or "none"))
    chat("Chance: " .. ROARR_CHANCE .. "% | Cooldown: " .. ROARR_COOLDOWN .. "s")
    chat("Enabled: " .. tostring(ROARR_ENABLED) .. " | Watch mode: " .. tostring(WATCH_MODE))
    chat("Pool: " .. table.getn(ROARR_EMOTES) .. " emotes")

  elseif cmd == "reset" then
    WATCH_SLOT = nil
    ensureDB().slot = nil
    chat("Slot cleared.")

  elseif cmd == "save" then
    local db = ensureDB()
    db.slot       = WATCH_SLOT
    db.chance     = ROARR_CHANCE
    db.cooldown   = ROARR_COOLDOWN
    db.enabled    = ROARR_ENABLED
    db.watch      = WATCH_MODE
    chat("Settings saved.")

  else
    chat("/raorr slot <n> | chance <0-100> | cd <0-60> | info | reset | on | off | watch | tutorial | save")
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
    ensureLoaded()
  elseif event == "PLAYER_LOGOUT" then
    local db = ensureDB()
    db.slot       = WATCH_SLOT
    db.chance     = ROARR_CHANCE
    db.cooldown   = ROARR_COOLDOWN
    db.enabled    = ROARR_ENABLED
    db.watch      = WATCH_MODE
  end
end)
