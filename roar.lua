-- ROAR v1.0
-- Turtle/Vanilla Lua 5.0 SAFE
-- SavedVariables: ROARDB

-------------------------------------------------
-- Emote pool
-------------------------------------------------
local ROAR_EMOTES = {
  "ROAR", "CHEER", "CHARGE", "FLEX", "BORED"
}

-------------------------------------------------
-- State
-------------------------------------------------
local WATCH_SLOT = nil
local LAST_EMOTE = 0
local ROAR_COOLDOWN = 5
local ROAR_CHANCE = 100

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function chat(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffaa33ROAR:|r " .. msg)
  end
end

local function ensureDB()
  if type(ROARDB) ~= "table" then ROARDB = {} end
  return ROARDB
end

local loaded_once = false
local function ensureLoaded()
  if loaded_once then return end
  loaded_once = true

  local db = ensureDB()

  WATCH_SLOT     = db.slot or WATCH_SLOT
  ROAR_COOLDOWN  = db.cooldown or ROAR_COOLDOWN
  ROAR_CHANCE    = db.chance or ROAR_CHANCE
end

local function pick(t)
  local n = table.getn(t)
  if n < 1 then return nil end
  return t[math.random(1, n)]
end

local function doRandomEmote()
  local now = GetTime()
  if now - LAST_EMOTE < ROAR_COOLDOWN then return end
  LAST_EMOTE = now

  if math.random(1, 100) <= ROAR_CHANCE then
    local e = pick(ROAR_EMOTES)
    if e then DoEmote(e) end
  end
end

-------------------------------------------------
-- Lua 5.0-safe command splitter  
-- NO string.match — only string.find
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

  if WATCH_SLOT and slot == WATCH_SLOT then
    doRandomEmote()
  end

  return Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- Slash Command (/roar)
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
      chat("Watching slot " .. n .. " (saved).")
    else
      chat("Usage: /roar slot <number>")
    end

  elseif cmd == "chance" then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 100 then
      ROAR_CHANCE = n
      ensureDB().chance = n
      chat("Emote chance set to " .. n .. "%")
    else
      chat("Usage: /roar chance <0-100>")
    end

  elseif cmd == "cd" then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 60 then
      ROAR_COOLDOWN = n
      ensureDB().cooldown = n
      chat("Cooldown set to " .. n .. " seconds")
    else
      chat("Usage: /roar cd <0-60>")
    end

  elseif cmd == "info" then
    chat("Watching slot: " .. (WATCH_SLOT or "none"))
    chat("Chance: " .. ROAR_CHANCE .. "% | Cooldown: " .. ROAR_COOLDOWN .. "s")
    chat("Pool: " .. table.getn(ROAR_EMOTES) .. " emotes")

  elseif cmd == "reset" then
    WATCH_SLOT = nil
    ensureDB().slot = nil
    chat("Slot cleared.")

  else
    chat("/roar slot <n> | chance <0-100> | cd <0-60> | info | reset")
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
    db.slot     = WATCH_SLOT
    db.chance   = ROAR_CHANCE
    db.cooldown = ROAR_COOLDOWN
  end
end)
