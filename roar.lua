-- ROAR Addon (Turtle WoW / Vanilla 1.12)
-- Based on BuxbrewCharge, rewritten as ROAR with /roar slash command.
-- Account‑wide SavedVariables: ROARDB

-------------------------------------------------
-- Emote pool for roaring moments
-------------------------------------------------
local EMOTE_POOL = {
  "ROAR",      -- /roar
  "CHARGE",    -- /charge
  "CHEER",     -- /cheer
  "BORED",     -- /bored
  "FLEX",      -- /flex
}

-------------------------------------------------
-- State
-------------------------------------------------
local ROAR_SLOT = nil
local LAST_ROAR = 0
local ROAR_COOLDOWN = 20   -- default seconds
local ROAR_CHANCE = 100    -- percent chance per activation

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function chat(t)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffdd6600ROAR:|r " .. t) end
end

local function ensureDB()
  if type(ROARDB) ~= "table" then ROARDB = {} end
  return ROARDB
end

local function pick(t)
  local n = table.getn(t)
  if n < 1 then return nil end
  return t[math.random(1, n)]
end

local function doRoar()
  local now = GetTime()
  if now - LAST_ROAR < ROAR_COOLDOWN then return end
  if math.random(1,100) > ROAR_CHANCE then return end

  LAST_ROAR = now
  local token = pick(EMOTE_POOL)
  if token and DoEmote then DoEmote(token) end
end

-------------------------------------------------
-- Hook UseAction
-------------------------------------------------
local _orig = UseAction
function UseAction(slot, check, selfcast)
  if ROAR_SLOT and slot == ROAR_SLOT then
    doRoar()
  end
  return _orig(slot, check, selfcast)
end

-------------------------------------------------
-- Slash: /roar
-------------------------------------------------
SLASH_ROAR1 = "/roar"
SlashCmdList["ROAR"] = function(raw)
  local s = string.gsub(raw or "", "^%s+", "")
  local cmd, rest = string.match(s, "^(%S+)%s*(.-)$")

  if cmd == "slot" then
    local n = tonumber(rest)
    if n then
      ROAR_SLOT = n
      ensureDB().slot = n
      chat("assigned action slot " .. n)
    else
      chat("usage: /roar slot <number>")
    end

  elseif cmd == "chance" then
    local n = tonumber(rest)
    if n then
      if n < 0 then n = 0 elseif n > 100 then n = 100 end
      ROAR_CHANCE = n
      ensureDB().chance = n
      chat("chance set to " .. n .. "%")
    else
      chat("usage: /roar chance <0–100>")
    end

  elseif cmd == "cooldown" then
    local n = tonumber(rest)
    if n then
      if n < 0 then n = 0 end
      ROAR_COOLDOWN = n
      ensureDB().cooldown = n
      chat("cooldown set to " .. n .. "s")
    else
      chat("usage: /roar cooldown <seconds>")
    end

  elseif cmd == "test" then
    doRoar()

  elseif cmd == "info" then
    chat("slot: " .. (ROAR_SLOT or "none"))
    chat("chance: " .. ROAR_CHANCE .. "%")
    chat("cooldown: " .. ROAR_COOLDOWN .. "s")

  elseif cmd == "reset" then
    ROAR_SLOT = nil
    local db = ensureDB()
    db.slot = nil
    chat("slot cleared")

  else
    chat("/roar slot <n> | /roar chance <0-100> | /roar cooldown <sec> | /roar test | /roar info | /roar reset")
  end
end

-------------------------------------------------
-- Init
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(self, event)
  if event == "VARIABLES_LOADED" then
    local db = ensureDB()
    ROAR_SLOT     = db.slot or ROAR_SLOT
    ROAR_CHANCE   = db.chance or ROAR_CHANCE
    ROAR_COOLDOWN = db.cooldown or ROAR_COOLDOWN
    chat("loaded; slot=" .. tostring(ROAR_SLOT or "none"))

  elseif event == "PLAYER_LOGIN" then
    math.randomseed(math.floor(GetTime() * 1000)); math.random()

  elseif event == "PLAYER_LOGOUT" then
    local db = ensureDB()
    db.slot     = ROAR_SLOT
    db.chance   = ROAR_CHANCE
    db.cooldown = ROAR_COOLDOWN
  end
end)
