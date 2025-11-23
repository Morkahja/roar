-- ROARR Addon (Turtle WoW, Lua 5.0-safe)
-- SavedVariables: ROARRDB

-------------------------------------------------
-- Emote Pool (must be lowercase for DoEmote)
-------------------------------------------------
local EMOTE_POOL = {
  "roar", "charge", "cheer", "bored", "flex",
}

-------------------------------------------------
-- State
-------------------------------------------------
local WATCH_SLOT = nil
local ROARR_ENABLED = true
local WATCH_MODE = false
local LAST_EMOTE_TIME = 0
local ROARR_COOLDOWN = 6
local roar_chance = 100

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function chat(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800ROARR:|r " .. msg)
  end
end

local function ensureDB()
  if type(ROARRDB) ~= "table" then ROARRDB = {} end
  return ROARRDB
end

local _r_loaded_once = false
local function ensureLoaded()
  if not _r_loaded_once then
    local db = ensureDB()
    WATCH_SLOT = db.slot or WATCH_SLOT
    if db.cooldown then ROARR_COOLDOWN = db.cooldown end
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
  if now - LAST_EMOTE_TIME < ROARR_COOLDOWN then return end
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
-- Hook UseAction (global override for Turtle WoW)
-------------------------------------------------
local _Orig_UseAction = UseAction
UseAction = function(slot, checkCursor, onSelf)
  ensureLoaded()
  if WATCH_MODE then
    chat("pressed slot " .. tostring(slot))
  end
  if ROARR_ENABLED and WATCH_SLOT and slot == WATCH_SLOT then
    maybeEmoteNow()
  end
  return _Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- Slash Command /raorr
-------------------------------------------------
SLASH_ROARR1 = "/raorr"
SlashCmdList["ROARR"] = function(raw)
  ensureLoaded()
  local cmd, rest = split_cmd(raw)

  if cmd == "slot" then
    local n = tonumber(rest)
    if n then
      WATCH_SLOT = n
      ensureDB().slot = n
      chat("watching slot " .. n .. " (saved)")
    else
      chat("usage: /raorr slot <number>")
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
      chat("usage: /raorr chance <0-100>")
    end

  elseif cmd == "cd" then
    local n = tonumber(rest)
    if n and n >= 0 then
      ROARR_COOLDOWN = n
      ensureDB().cooldown = n
      chat("cooldown set to " .. n .. "s")
    else
      chat("usage: /raorr cd <seconds>")
    end

  elseif cmd == "off" then
    ROARR_ENABLED = false
    chat("ROARR disabled.")

  elseif cmd == "on" then
    ROARR_ENABLED = true
    chat("ROARR enabled.")

  elseif cmd == "tutorial" then
    chat("ROARR tutorial:")
    chat("1. Use /raorr watch and press your action bar buttons to see their slot numbers.")
    chat("2. Set the watched slot with /raorr slot <n>.")
    chat("3. Adjust chance with /raorr chance <0-100>.")
    chat("4. Adjust cooldown with /raorr cd <seconds>.")
    chat("5. Toggle with /raorr on or /raorr off.")
    chat("6. Use /raorr info to see current settings.")

  elseif cmd == "info" then
    chat("watching slot: " .. (WATCH_SLOT and tostring(WATCH_SLOT) or "none"))
    chat("chance: " .. tostring(roar_chance) .. "% | cooldown: " .. tostring(ROARR_COOLDOWN) .. "s | pool: " .. tostring(table.getn(EMOTE_POOL)))

  elseif cmd == "reset" then
    WATCH_SLOT = nil
    ensureDB().slot = nil
    chat("slot cleared")

  elseif cmd == "save" then
    local db = ensureDB()
    db.slot = WATCH_SLOT
    db.chance = roar_chance
    db.cooldown = ROARR_COOLDOWN
    chat("saved settings")

  else
    chat("/raorr slot <n> | watch | chance <0-100> | cd <sec> | info | reset | save | on | off | tutorial ")
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
    math.randomseed(math.floor(GetTime() * 1000000)); math.random()
  elseif event == "PLAYER_LOGOUT" then
    local db = ensureDB()
    db.slot = WATCH_SLOT
    db.chance = roar_chance
    db.cooldown = ROARR_COOLDOWN
  end
end)
