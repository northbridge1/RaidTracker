
-- RaidTracker - Core

-- Ensure addon table exists early (Core.lua may load before other modules)
RaidTracker = RaidTracker or {}
local RT = RaidTracker
RT._qsOn = RT._qsOn or false

local function RT_IsSpanishClient()
  local loc = (GetLocale and GetLocale()) or "enUS"
  return loc == "esES" or loc == "esMX"
end

RT.Locale = RT.Locale or (RT_IsSpanishClient() and "es" or "en")

local _L = {
  en = {
    CONFIG = "Settings",
    WHITELIST = "Whitelist",
    BLACKLIST = "Blacklist",
    RAIDS = "Raids",
    ADD_CHARACTER = "Add character",
    ADD = "Add",
    BLOCK = "Block",
    CHARACTER = "Character",
    WEEKLY = "Weekly",
    EXPORT_IMPORT = "Export / Import",
    CLOSE = "Close",
    IMPORT = "Import",
    EXPORT = "Export",
    TOOLS_TITLE = "RaidTracker - Tools",
    RESCAN = "Rescan",
    RESET = "Reset",
    API_CHANNEL = "API channel (SendAddonMessage)",
    WHISPER_CHANNEL = "Whisper channel (RTSYNC)",
    SNIFFER_ONLY = "Sniffer: RTSYNC only",
    SNIFFER_ON = "Sniffer: ON",
    SNIFFER_OFF = "Sniffer: OFF",
    QUESTSNIFF_ON = "QuestSniff: ON",
    QUESTSNIFF_OFF = "QuestSniff: OFF",
    IMPORT_OK = "Import OK.",
    IMPORT_ERROR_FMT = "Import error: %s",
    EMPTY_TEXT = "Empty text",
    NO_VALID_LINES = "No valid lines found to import (did you copy the full export text?)",
    TEXT = "Text",
    DONE = "Done",
    READY_TO_TURN_IN = "Ready to turn in",
    IN_PROGRESS = "In progress",
    PENDING = "Pending",
    LOCKED = "Locked",
    NOT_LOCKED = "Not locked",
    RESET_AT_FMT = "Reset: %s",
    UPDATED_AT_FMT = "Updated: %s",
    SYNC_LOG = "Sync log",
    LOG_OPEN_FAIL = "[RaidTracker] Could not open the log window",
    QUEST_SNIFF_ON = "Quest sniff ON",
    QUEST_SNIFF_OFF = "Quest sniff OFF",
    QUEST_SNIFF_TOGGLED = "QuestSniff toggled",
    WHISPER_CHANNEL_TOGGLE_FMT = "[RaidTracker] WHISPER channel (RTSYNC) %s",
    API_CHANNEL_TOGGLE_FMT = "[RaidTracker] API channel (SendAddonMessage) %s",
    DEBUG_SYNC_FMT = "[RaidTracker] Sync debug %s",
    USAGE_SYNC = "[RaidTracker] Usage: /rt sync Name",
    USAGE_SYNC1 = "[RaidTracker] Usage: /rt sync1 Name",
    USAGE_WIPECHAR = "[RaidTracker] Usage: /rt wipechar Name",
    SYNC_REQALL_FMT = "[RaidTracker] Sync (REQALL) -> %s",
    SYNC_REQ_FMT = "[RaidTracker] Sync (REQ) -> %s",
    AUTOSYNC_TRIGGERED = "[RaidTracker] Auto-sync triggered",
    AUTOSYNC_UNAVAILABLE = "[RaidTracker] Auto-sync unavailable",
    RESET_APPLIED = "[RaidTracker] Reset applied",
    WIPEALL_DONE = "[RaidTracker] Data wiped (wipeall)",
    WIPECHAR_DONE_FMT = "[RaidTracker] Character deleted: %s",
    SHOW_ALL = "[RaidTracker] Show all",
    UI_REFRESH_OK = "[RaidTracker] UI refresh OK",
    UI_REFRESH_MARKED = "[RaidTracker] UI refresh marked (open the window to see it)",
    APPROVAL_REQ = "%s wants to sync with you.\n\nAccept?",
    APPROVAL_REQALL = "%s wants to sync all characters with you.\n\nAccept?",
    ACCEPT = "Accept",
    DENY = "Decline",
  },
  es = {
    CONFIG = "Configuración",
    WHITELIST = "Whitelist",
    BLACKLIST = "Blacklist",
    RAIDS = "Raids",
    ADD_CHARACTER = "Añadir personaje",
    ADD = "Añadir",
    BLOCK = "Bloquear",
    CHARACTER = "Personaje",
    WEEKLY = "Semanal",
    EXPORT_IMPORT = "Export / Import",
    CLOSE = "Cerrar",
    IMPORT = "Importar",
    EXPORT = "Exportar",
    TOOLS_TITLE = "RaidTracker - Herramientas",
    RESCAN = "Reescanear",
    RESET = "Reset",
    API_CHANNEL = "Canal API (SendAddonMessage)",
    WHISPER_CHANNEL = "Canal Whisper (RTSYNC)",
    SNIFFER_ONLY = "Sniffer: solo RTSYNC",
    SNIFFER_ON = "Sniffer: ON",
    SNIFFER_OFF = "Sniffer: OFF",
    QUESTSNIFF_ON = "QuestSniff: ON",
    QUESTSNIFF_OFF = "QuestSniff: OFF",
    IMPORT_OK = "Importación OK.",
    IMPORT_ERROR_FMT = "Error importando: %s",
    EMPTY_TEXT = "Texto vacío",
    NO_VALID_LINES = "No se encontraron líneas válidas para importar (¿copiaste TODO el texto de Exportar?)",
    TEXT = "Texto",
    DONE = "Hecha",
    READY_TO_TURN_IN = "Lista para entregar",
    IN_PROGRESS = "En progreso",
    PENDING = "Pendiente",
    LOCKED = "Bloqueado",
    NOT_LOCKED = "No bloqueado",
    RESET_AT_FMT = "Reset: %s",
    UPDATED_AT_FMT = "Actualizado: %s",
    SYNC_LOG = "Sync log",
    LOG_OPEN_FAIL = "[RaidTracker] No se pudo abrir la ventana de log",
    QUEST_SNIFF_ON = "Quest sniff ON",
    QUEST_SNIFF_OFF = "Quest sniff OFF",
    QUEST_SNIFF_TOGGLED = "QuestSniff toggled",
    WHISPER_CHANNEL_TOGGLE_FMT = "[RaidTracker] Canal WHISPER (RTSYNC) %s",
    API_CHANNEL_TOGGLE_FMT = "[RaidTracker] Canal API (SendAddonMessage) %s",
    DEBUG_SYNC_FMT = "[RaidTracker] Sync debug %s",
    USAGE_SYNC = "[RaidTracker] Uso: /rt sync Nombre",
    USAGE_SYNC1 = "[RaidTracker] Uso: /rt sync1 Nombre",
    USAGE_WIPECHAR = "[RaidTracker] Uso: /rt wipechar Nombre",
    SYNC_REQALL_FMT = "[RaidTracker] Sync (REQALL) -> %s",
    SYNC_REQ_FMT = "[RaidTracker] Sync (REQ) -> %s",
    AUTOSYNC_TRIGGERED = "[RaidTracker] Auto-sync disparado",
    AUTOSYNC_UNAVAILABLE = "[RaidTracker] Auto-sync no disponible",
    RESET_APPLIED = "[RaidTracker] Reset aplicado",
    WIPEALL_DONE = "[RaidTracker] Datos borrados (wipeall)",
    WIPECHAR_DONE_FMT = "[RaidTracker] Borrado personaje: %s",
    SHOW_ALL = "[RaidTracker] Mostrar todos",
    UI_REFRESH_OK = "[RaidTracker] UI refresh OK",
    UI_REFRESH_MARKED = "[RaidTracker] UI refresh marcado (abre la ventana para verlo)",
    APPROVAL_REQ = "%s quiere sincronizar contigo.\n\n¿Aceptar?",
    APPROVAL_REQALL = "%s quiere sincronizar todos los personajes contigo.\n\n¿Aceptar?",
    ACCEPT = "Aceptar",
    DENY = "Rechazar",
  },
}

RT.L = RT.L or setmetatable({}, {
  __index = function(_, key)
    local tbl = _L[RT.Locale] or _L.en
    return (tbl and tbl[key]) or (_L.en and _L.en[key]) or key
  end,
})

-- Minimal print (used by debug tools)
if not RT.Print then
  function RT.Print(msg)
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage(tostring(msg))
    else
      print(tostring(msg))
    end
  end
end

-- WotLK 3.3.5 (3.3.0 interface)

local ADDON = ...

-- Weekly raid quest IDs (Archmage Lan'dalock "Must Die!" weeklies)
-- These are stable on WotLK 3.3.5a.
local DEFAULT_WEEKLY_QUEST_IDS = {
  24579, -- Sartharion Must Die!
  24580, -- Anub'Rekhan Must Die!
  24581, -- Noth the Plaguebringer Must Die!
  24582, -- Instructor Razuvious Must Die!
  24583, -- Patchwerk Must Die!
  24584, -- Malygos Must Die!
  24585, -- Flame Leviathan Must Die!
  24586, -- Razorscale Must Die!
  24587, -- Ignis the Furnace Master Must Die!
  24588, -- XT-002 Deconstructor Must Die!
  24589, -- Lord Jaraxxus Must Die!
  24590, -- Lord Marrowgar Must Die!
}

local WEEKLY_EMBLEM_FROST_ID   = 49426
local WEEKLY_EMBLEM_TRIUMPH_ID = 47241

RaidTracker = RaidTracker or {}
local RT = RaidTracker
RaidTrackerDB = RaidTrackerDB or nil

local function Now()
  if GetServerTime then return GetServerTime() end
  return time()
end


-- Quest sniffer (debug): logs quest events and helps diagnose weekly detection.

-- Quest sniffer (debug): logs quest events and helps diagnose weekly detection.
function RT.ToggleQuestSniff(force)
  if not RT._qsFrame then
    RT._qsFrame = CreateFrame("Frame")
    RT._qsFrame._last = 0
  end

  if force == false or (force == nil and RT._qsOn) then
    RT._qsFrame:UnregisterAllEvents()
    RT._qsFrame:SetScript("OnEvent", nil)
    RT._qsOn = false
    RT.Print(RT.L.QUEST_SNIFF_OFF)
    return
  end

  RT._qsFrame:UnregisterAllEvents()
  RT._qsFrame:RegisterEvent("QUEST_ACCEPTED")
  RT._qsFrame:RegisterEvent("QUEST_LOG_UPDATE")
  RT._qsFrame:RegisterEvent("QUEST_COMPLETE")
  RT._qsFrame:RegisterEvent("QUEST_FINISHED")
  RT._qsFrame:RegisterEvent("QUEST_QUERY_COMPLETE")
  RT._qsFrame:RegisterEvent("GOSSIP_SHOW")
  RT._qsFrame:RegisterEvent("QUEST_GREETING")

  RT._qsFrame:SetScript("OnEvent", function(_, ev, ...)
    local now = Now()
    -- throttle noisy events
    if ev == "QUEST_LOG_UPDATE" and (now - (RT._qsFrame._last or 0) < 1) then return end
    RT._qsFrame._last = now

    local msg = "QS "..ev
    if ev == "QUEST_ACCEPTED" then
      local idx, qid = ...
      idx = tonumber(idx) or 0
      qid = tonumber(qid) or 0
      local title = (idx>0 and GetQuestLogTitle and select(1, GetQuestLogTitle(idx))) or ""
      local link = (idx>0 and GetQuestLink and GetQuestLink(idx)) or ""
      msg = msg .. string.format(" idx=%d qid=%d title=[%s]", idx, qid, tostring(title or ""))
      if link and link ~= "" then msg = msg .. " link=" .. link end
    elseif ev == "QUEST_QUERY_COMPLETE" then
      msg = msg .. " (completed list updated)"
    end

    RT.Print(msg)

    if RT.UpdateWeeklyAuto then RT.UpdateWeeklyAuto() end
    if RT.CheckWeeklyFromGossip and (ev=="GOSSIP_SHOW" or ev=="QUEST_GREETING") then RT.CheckWeeklyFromGossip() end
    if RT.UI and RT.UI.Refresh then RT.UI.Refresh(true) end
  end)

  RT._qsOn = true
  RT.Print(RT.L.QUEST_SNIFF_ON)
end




-- Weekly raid reset on Warmane: Wednesday 03:59 server time
local function NextRaidReset(ts)
  ts = ts or Now()
  local t = date("*t", ts)
  local targetWday = 4 -- Wednesday (Sunday=1)
  local daysUntil = (targetWday - t.wday) % 7

  local resetToday = time({ year=t.year, month=t.month, day=t.day, hour=3, min=59, sec=0 })
  if daysUntil == 0 and ts >= resetToday then
    daysUntil = 7
  end

  local target = resetToday + (daysUntil * 86400)
  return target
end

local function RealmName()
  local r = GetRealmName and GetRealmName() or "Unknown"
  return r
end

local function PlayerName()
  local n = UnitName and UnitName("player") or "Unknown"
  return n
end

local function PlayerClass()
  local _, class = UnitClass("player")
  return class or "UNKNOWN"
end

function RT.CharKey(realm, name)
  return tostring(realm or "") .. "-" .. tostring(name or "")
end

-- Weekly key: week starts on Wednesday 00:00 server time.
-- Week identifier (robust + simple): ISO year + ISO week number (YYYYWW)
-- We implement ISO week calculation ourselves to avoid relying on %V support.
local function IsoWeekYear(ts)
  local t = date("*t", ts)
  -- Lua/WoW: t.wday: Sunday=1..Saturday=7. Convert to ISO: Monday=1..Sunday=7.
  local isoDow = ((t.wday + 5) % 7) + 1
  -- Day of year (1..366)
  local jan1 = time({ year=t.year, month=1, day=1, hour=0, min=0, sec=0 })
  local doy = math.floor((time({ year=t.year, month=t.month, day=t.day, hour=0, min=0, sec=0 }) - jan1) / 86400) + 1

  local week = math.floor((doy - isoDow + 10) / 7)
  local isoYear = t.year

  local function WeeksInIsoYear(y)
    -- ISO week year has the week containing Dec 28 as the last week.
    local dec28 = time({ year=y, month=12, day=28, hour=0, min=0, sec=0 })
    local tt = date("*t", dec28)
    local isoDow2 = ((tt.wday + 5) % 7) + 1
    local jan1y = time({ year=y, month=1, day=1, hour=0, min=0, sec=0 })
    local doy2 = math.floor((time({ year=y, month=tt.month, day=tt.day, hour=0, min=0, sec=0 }) - jan1y) / 86400) + 1
    return math.floor((doy2 - isoDow2 + 10) / 7)
  end

  if week < 1 then
    isoYear = isoYear - 1
    week = WeeksInIsoYear(isoYear)
  else
    local weeksInYear = WeeksInIsoYear(isoYear)
    if week > weeksInYear then
      isoYear = isoYear + 1
      week = 1
    end
  end

  return isoYear, week
end

function RT.GetWeekId(ts)
  ts = ts or Now()
  -- Anchor weekId to the weekly raid reset (Wednesday 03:59). This avoids switching on Monday (ISO week).
  local nextReset = NextRaidReset(ts)
  local anchor = nextReset - (7 * 86400)
  local y, w = IsoWeekYear(anchor)
  return (tonumber(y) or 0) * 100 + (tonumber(w) or 0)
end

-- Weekly raid quest auto-tracking (Warmane / 3.3.5):
-- Detect weekly quests by their Spanish suffix "debe morir" and mark weekly done on turn-in.
RT._questTitleById = RT._questTitleById or {}

local function _Trim(s)
  return (tostring(s or ""):gsub("^%s+",""):gsub("%s+$",""))
end

local function _NormTitle(title)
  local t = _Trim(title):lower()
  -- strip trailing punctuation like '!' '.' ':' and extra spaces
  t = t:gsub("[%s%p]+$", "")
  t = t:gsub("%s+", " ")
  return t
end


local function _GetQuestCompletedTable()
  if not GetQuestsCompleted then return nil end
  -- Support both signatures:
  --  - GetQuestsCompleted(table)  (fills)
  --  - local t = GetQuestsCompleted()
  local t = {}
  local ok = false
  if pcall then
    ok = pcall(GetQuestsCompleted, t)
    if ok then
      -- Some versions return a table, some fill the provided one.
      -- If it returned a table, prefer it.
      local r = GetQuestsCompleted()
      if type(r) == "table" then return r end
      return t
    end
    local r
    ok, r = pcall(GetQuestsCompleted)
    if ok and type(r) == "table" then return r end
  else
    -- No pcall (unlikely), try no-arg
    local r = GetQuestsCompleted()
    if type(r) == "table" then return r end
  end
  return nil
end

local function _QuestRewardsEmblems(logIndex)
  if not SelectQuestLogEntry or not GetQuestLogSelection then return false end
  if not GetNumQuestLogRewards and not GetNumQuestLogChoices then return false end

  local frostId = WEEKLY_EMBLEM_FROST_ID
  local triumphId = WEEKLY_EMBLEM_TRIUMPH_ID

  local prev = GetQuestLogSelection()
  SelectQuestLogEntry(logIndex)

  local hasF, hasT = false, false

  local function scan(kind)
    local n = 0
    if kind == "reward" and GetNumQuestLogRewards then n = GetNumQuestLogRewards() or 0 end
    if kind == "choice" and GetNumQuestLogChoices then n = GetNumQuestLogChoices() or 0 end
    for j = 1, n do
      local link
      if GetQuestLogItemLink then
        link = GetQuestLogItemLink(kind, j)
      end
      if link then
        local iid = tonumber(string.match(link, "item:(%d+):")) or 0
        local _, _, count = string.match(link, "|Hitem:%d+:[^|]*|h%[[^%]]+%]|h|r") -- not reliable for count
        -- Count isn't in link; use info API for amount
      end

      if kind == "reward" and GetQuestLogRewardInfo then
        local name, _, num = GetQuestLogRewardInfo(j)
        if name and num then
          local iidLink = GetQuestLogItemLink and GetQuestLogItemLink("reward", j)
          local iid = iidLink and (tonumber(string.match(iidLink, "item:(%d+):")) or 0) or 0
          if iid == frostId and num == 5 then hasF = true end
          if iid == triumphId and num == 5 then hasT = true end
        end
      elseif kind == "choice" and GetQuestLogChoiceInfo then
        local name, _, num = GetQuestLogChoiceInfo(j)
        if name and num then
          local iidLink = GetQuestLogItemLink and GetQuestLogItemLink("choice", j)
          local iid = iidLink and (tonumber(string.match(iidLink, "item:(%d+):")) or 0) or 0
          if iid == frostId and num == 5 then hasF = true end
          if iid == triumphId and num == 5 then hasT = true end
        end
      end

      if hasF and hasT then break end
    end
  end

  -- Best path: item links (stable across locales). Fallback: localized names (via GetItemInfo)
  if GetQuestLogItemLink and (GetQuestLogRewardInfo or GetQuestLogChoiceInfo) then
    scan("reward")
    scan("choice")
  else
    local frostName = GetItemInfo and GetItemInfo(frostId)
    local triumphName = GetItemInfo and GetItemInfo(triumphId)
    local function scanByName(kind)
      local n = 0
      if kind == "reward" and GetNumQuestLogRewards and GetQuestLogRewardInfo then n = GetNumQuestLogRewards() or 0 end
      if kind == "choice" and GetNumQuestLogChoices and GetQuestLogChoiceInfo then n = GetNumQuestLogChoices() or 0 end
      for j=1,n do
        local name, _, num
        if kind == "reward" then name, _, num = GetQuestLogRewardInfo(j) end
        if kind == "choice" then name, _, num = GetQuestLogChoiceInfo(j) end
        if frostName and name == frostName and num == 5 then hasF = true end
        if triumphName and name == triumphName and num == 5 then hasT = true end
        if hasF and hasT then break end
      end
    end
    scanByName("reward")
    scanByName("choice")
  end

  SelectQuestLogEntry(prev)

  return hasF and hasT
end

local function IsWeeklyRaidQuestRewards(logIndex)
  return _QuestRewardsEmblems(logIndex)
end

local function IsWeeklyRaidQuestTitle(title)
  local t = _NormTitle(title)
  if t == "" then return false end
  return (t:match("debe morir$") ~= nil) or (t:match("must die$") ~= nil) or (t:find("debe morir", 1, true) ~= nil) or (t:find("must die", 1, true) ~= nil)
end

local function QuestLooksWeekly(i, title)
  if IsWeeklyRaidQuestTitle(title) then return true end
  if IsWeeklyRaidQuestRewards and IsWeeklyRaidQuestRewards(i) then return true end
  return false
end


local function QuestLogIsReady(i)
  if not GetQuestLogTitle then return false end

  -- Try completion flag from GetQuestLogTitle (position varies by client/core)
  local a1,a2,a3,a4,a5,a6,a7,a8,a9,a10 = GetQuestLogTitle(i)
  local candidates = {a6,a7,a8,a9,a10}
  for _,v in ipairs(candidates) do
    if v == 1 or v == true then
      return true
    end
  end

  -- Fallback: check objective completion via leaderboards
  if SelectQuestLogEntry and GetQuestLogSelection and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
    local oldSel = GetQuestLogSelection()
    pcall(SelectQuestLogEntry, i)
    local n = tonumber(GetNumQuestLeaderBoards()) or 0
    if n > 0 then
      local allDone = true
      for j = 1, n do
        local _, _, done = GetQuestLogLeaderBoard(j)
        if not done then allDone = false break end
      end
      if oldSel then pcall(SelectQuestLogEntry, oldSel) end
      return allDone
    end
    if oldSel then pcall(SelectQuestLogEntry, oldSel) end
  end

  return false
end



-- Forward declarations (locals used before definition)
local SetWeeklyInProgressFromQuest
local LearnWeeklyQuestId
local IsKnownWeeklyQuestId
local MarkWeeklyDoneFromQuest


local function CacheWeeklyQuestsFromLog()
  if not GetNumQuestLogEntries or not GetQuestLogTitle then return end
  local n = GetNumQuestLogEntries() or 0
  local foundAny = false

  for i = 1, n do
    local title, _, _, _, isHeader = GetQuestLogTitle(i)
    if title and (not isHeader) and IsWeeklyRaidQuestTitle(title) then
      local qid = 0
      if GetQuestLink then
        local link = GetQuestLink(i)
        if link then
          qid = tonumber(string.match(link, "Hquest:(%d+):")) or 0
        end
      end

      if qid > 0 then
        RT._questTitleById[qid] = title
        LearnWeeklyQuestId(qid, title)
        SetWeeklyInProgressFromQuest(qid, title)
      else
        -- If we can't extract the ID, still reflect progress by title.
        SetWeeklyInProgressFromQuest(0, title)
      end
      foundAny = true
      break
    end
  end

  if not foundAny then
    -- If none found, clear in-progress (do not touch done)
    local w = RT.GetWeeklyState(RealmName(), PlayerName())
    if w and w.inProgress and not w.done then
      w.inProgress = false
      w.questId = 0
      w.questTitle = nil
      w.ts = Now()
      w.weekId = RT.GetWeekId(w.ts)
    end
  end
end


-- Robust weekly auto-update:
-- - Orange (inProgress) if any weekly quest ("debe morir" / "must die") is in the quest log.
-- - Green (done) if the active weekly quest is flagged completed (turned in), or any known weekly quest ID is flagged completed.

function RT.UpdateWeeklyAuto()
  local realm = RealmName()
  local name = PlayerName()
  local w = RT.GetWeeklyState(realm, name)
  local now = Now()
  RT._weeklyExpandLast = RT._weeklyExpandLast or 0

  -- Detect an active weekly quest in the quest log
  local function ScanOnce()
    if not (GetNumQuestLogEntries and GetQuestLogTitle) then return false end
    local n = GetNumQuestLogEntries() or 0
    for i = 1, n do
      local title, _, _, _, isHeader, _, _, _ = GetQuestLogTitle(i)
      if title and (not isHeader) and QuestLooksWeekly(i, title) then
        local qid = 0
        if qid <= 0 and GetQuestLink then
          local link = GetQuestLink(i)
          if link then qid = tonumber(string.match(link, "Hquest:(%d+):")) or 0 end
        end

        if not w.done then
          local isReady = QuestLogIsReady(i)
          w.ready = isReady and true or false
          w.inProgress = (not isReady) and true or false
          w.questTitle = title
          w.questId = qid
          w.activeQuestId = qid
          w.ts = now
          w.weekId = RT.GetWeekId(now)
        end

        if qid and qid > 0 then
          LearnWeeklyQuestId(qid, title)
          RT._questTitleById[qid] = title
        end
        return true
      end
    end
    return false
  end


  -- If the title matcher fails (some clients append completion tags), try locating the same quest by questId.
  local function ScanById(wantedQid)
    wantedQid = tonumber(wantedQid) or 0
    if wantedQid <= 0 then return false end
    local n = GetNumQuestLogEntries() or 0
    for i = 1, n do
      local title, _, _, _, isHeader = GetQuestLogTitle(i)
      if title and (not isHeader) and GetQuestLink then
        local link = GetQuestLink(i)
        if link then
          local qid = tonumber(string.match(link, "Hquest:(%d+):")) or 0
          if qid == wantedQid then
            local isReady = QuestLogIsReady(i)
            w.ready = isReady and true or false
            w.inProgress = (not isReady) and true or false
            w.questTitle = title
            w.questId = qid
            w.activeQuestId = qid
            w.ts = now
            w.weekId = RT.GetWeekId(now)
            return true
          end
        end
      end
    end
    return false
  end


  local found = ScanOnce()
  if (not found) and ExpandQuestHeader and (now - (RT._weeklyExpandLast or 0) > 30) then
    -- Some clients hide quests under collapsed headers; expand once and try again.
    RT._weeklyExpandLast = now
    ExpandQuestHeader(0)
    found = ScanOnce()
  end

  -- Fallback: if we already know the weekly questId, locate it by id even if the title matcher fails.
  if (not found) and w and tonumber(w.activeQuestId or 0) > 0 then
    found = ScanById(w.activeQuestId)
  end

  if found then return end

  -- No weekly quest in log: if we previously saw it READY and it disappears,
  -- only mark DONE if we recently entered the turn-in flow (QUEST_COMPLETE).
  if w and (not w.done) and w.ready then
    local qid = tonumber(w.activeQuestId or w.questId) or 0
    local pending = tonumber(w.turninPending or 0) or 0
    if pending > 0 and (now - pending) < 120 then
      MarkWeeklyDoneFromQuest(qid)
      w.turninPending = nil
      return
    end

    -- Otherwise, the quest vanished without a confirmed turn-in (abandoned/reset/client quirk).
    w.inProgress = false
    w.ready = false
    w.activeQuestId = 0
    w.turninPending = nil
    w.ts = now
    w.weekId = RT.GetWeekId(now)
    return
  end

  -- No weekly quest in log: clear orange/yellow state
  if w and (not w.done) and (w.inProgress or w.ready) then
    w.inProgress = false
    w.ready = false
    w.activeQuestId = 0
    w.ts = now
    w.weekId = RT.GetWeekId(now)
    return
  end
end


local function IsLandalockNPC()
  if not UnitName then return false end
  local n = UnitName("npc") or UnitName("target") or ""
  n = tostring(n or "")
  if n == "" then return false end
  n = n:lower()
  return (n:find("lan'dalock", 1, true) ~= nil)
end

local function GossipHasWeekly()
  if not GetGossipAvailableQuests then return nil end
  local t = {GetGossipAvailableQuests()}
  local n = #t
  if n == 0 then return nil end

  -- Guess stride (4 or 5) depending on return count
  local stride = (n % 5 == 0) and 5 or ((n % 4 == 0) and 4 or 5)
  for i = 1, n, stride do
    local title = t[i]
    if type(title) == "string" and IsWeeklyRaidQuestTitle(title) then
      return true
    end
  end
  return false
end

local function GossipHasActiveWeekly()
  if not GetGossipActiveQuests then return nil, false end
  local t = {GetGossipActiveQuests()}
  local n = #t
  if n == 0 then return nil, false end
  local stride = (n % 5 == 0) and 5 or ((n % 4 == 0) and 4 or 5)
  for i = 1, n, stride do
    local title = t[i]
    local isComplete = t[i+3] -- heuristic: often 4th field
    if type(title) == "string" and IsWeeklyRaidQuestTitle(title) then
      local ready = (isComplete == 1 or isComplete == true)
      return true, ready
    end
  end
  return false, false
end

function RT.CheckWeeklyFromGossip()
  -- Only apply strong inference when talking to Lan'dalock
  if not IsLandalockNPC() then return end

  local realm = RealmName()
  local name = PlayerName()
  local w = RT.GetWeeklyState(realm, name)

  local hasAvail = GossipHasWeekly()
  local hasActive, activeReady = GossipHasActiveWeekly()

  if hasActive then
    if not w.done then
      w.ready = activeReady and true or false
      w.inProgress = (not w.ready) and true or false
      w.ts = Now()
      w.weekId = RT.GetWeekId(w.ts)
    end
    return
  end

  if hasAvail == true then
    -- Weekly is available but not taken: force NOT done (overrides any false positives)
    w.done = false
    w.ready = false
    w.inProgress = false
    w.ts = Now()
    w.weekId = RT.GetWeekId(w.ts)
    return
  end

  if hasAvail == false and (not w.done) then
    -- Talking to Lan'dalock and no weekly offered/active: assume already completed this reset window.
    -- Do not override if we currently have it in progress/ready.
    if not w.inProgress and not w.ready then
      MarkWeeklyDoneFromQuest(0)
    end
  end
end



-- Query completed quests so we can detect weekly DONE even if the character never accepts the weekly quest.
-- In 3.3.5 you can request the server's completed-quest list via QueryQuestsCompleted() and read it on QUEST_QUERY_COMPLETE.





SetWeeklyInProgressFromQuest = function(qid, title)
  local realm = RealmName()
  local name = PlayerName()
  local w = RT.GetWeeklyState(realm, name)
  if w.done then return end
  w.done = false
  w.inProgress = true
  w.ts = Now()
  w.weekId = RT.GetWeekId(w.ts)
  w.questId = tonumber(qid) or 0
  if title and title ~= "" then
    w.questTitle = title
  end
end

LearnWeeklyQuestId = function(qid, title)
  qid = tonumber(qid)
  if not qid or qid <= 0 then return end
  local db = RT.GetDB()
  db.config.weeklyQuestIds = db.config.weeklyQuestIds or {}
  db.config.weeklyQuestTitles = db.config.weeklyQuestTitles or {}
  db.config.weeklyQuestIds[qid] = true
  if title and title ~= "" then
    db.config.weeklyQuestTitles[qid] = title
  end
end

IsKnownWeeklyQuestId = function(qid)
  qid = tonumber(qid)
  if not qid or qid <= 0 then return false end
  local db = RT.GetDB()
  return db and db.config and db.config.weeklyQuestIds and db.config.weeklyQuestIds[qid] == true
end

MarkWeeklyDoneFromQuest = function(qid)
  local realm = RealmName()
  local name = PlayerName()
  local w = RT.GetWeeklyState(realm, name)

  w.done = true
  w.inProgress = false
  w.ready = false
  w.turninPending = nil

  w.ts = Now()
  w.weekId = RT.GetWeekId(w.ts)
  w.questId = tonumber(qid) or 0
  w.activeQuestId = w.questId

  local db = RT.GetDB()
  local title = (db and db.config and db.config.weeklyQuestTitles and db.config.weeklyQuestTitles[w.questId]) or RT._questTitleById[w.questId]
  if title and title ~= "" then
    w.questTitle = title
  end
end

-- When the quest reward window opens (QUEST_COMPLETE), remember that the player is in the turn-in flow.
-- We only mark weekly DONE (green) after the quest disappears from the log AND this flag was set recently.
function RT.NoteWeeklyTurninPending()
  local w = RT.GetWeeklyState(RealmName(), PlayerName())
  if not w or w.done then return end

  local title = ""
  if GetTitleText then title = tostring(GetTitleText() or "") end

  -- Strip any formatting/links so we never corrupt our own storage or tooltips.
  title = title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  title = title:gsub("|H.-|h", ""):gsub("|h", "")
  title = title:gsub("|", "")

  -- Robust: if matcher fails but we were READY, still treat this as turn-in flow.
  if (title ~= "" and IsWeeklyRaidQuestTitle(title)) or (w and w.ready) then
    w.turninPending = Now()
    if title ~= "" then w.questTitle = title end
  end
end

-- WotLK 3.3.5 has no QUEST_TURNED_IN. Hook GetQuestReward so we mark DONE exactly when the reward is taken.
if hooksecurefunc and not RT._weeklyRewardHooked then
  RT._weeklyRewardHooked = true
  hooksecurefunc("GetQuestReward", function()
    local w = RT.GetWeeklyState(RealmName(), PlayerName())
    if not w or w.done then return end

    local now = Now()
    local pending = tonumber(w.turninPending or 0) or 0
    if pending <= 0 or (now - pending) > 300 then return end

    local title = ""
    if GetTitleText then title = tostring(GetTitleText() or "") end
    title = title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    title = title:gsub("|H.-|h", ""):gsub("|h", "")
    title = title:gsub("|", "")

    if (title ~= "" and IsWeeklyRaidQuestTitle(title)) or (w and w.ready) then
      MarkWeeklyDoneFromQuest(tonumber(w.activeQuestId or w.questId) or 0)
      w.turninPending = nil
      if RT.UI and RT.UI.Refresh then RT.UI.Refresh(true) end
    end
  end)
end



RT.DEFAULT_RAIDS = {
  -- keys are internal
  RS10  = { label = "RS10",  patterns = {"Ruby Sanctum","Sagrario Rubí","Santuario Rubí"}, maxPlayers=10 },
  RS25  = { label = "RS25",  patterns = {"Ruby Sanctum","Sagrario Rubí","Santuario Rubí"}, maxPlayers=25 },
  ICC10 = { label = "ICC10", patterns = {"Icecrown Citadel","Ciudadela de la Corona de Hielo"}, maxPlayers=10 },
  ICC25 = { label = "ICC25", patterns = {"Icecrown Citadel","Ciudadela de la Corona de Hielo"}, maxPlayers=25 },
  TOC10 = { label = "ToC10", patterns = {"Trial of the Crusader","Prueba del Cruzado"}, maxPlayers=10 },
  TOC25 = { label = "ToC25", patterns = {"Trial of the Crusader","Prueba del Cruzado"}, maxPlayers=25 },
  VOA10 = { label = "VoA10", patterns = {"Vault of Archavon","Cámara de Archavon","Bóveda de Archavon"}, maxPlayers=10 },
  VOA25 = { label = "VoA25", patterns = {"Vault of Archavon","Cámara de Archavon","Bóveda de Archavon"}, maxPlayers=25 },
  WEEKLY = { label = RT.L.WEEKLY, manual = true },
}


-- Canonicalize raid keys received from sync or stored in DB (removes invisible/control chars)
function RT.CanonRaidKey(k)
  k = tostring(k or "")
  -- Remove control chars and whitespace
  k = k:gsub("[%c%s]", "")
  -- Strip any other non-alphanumeric (defensive against weird glyphs)
  k = k:gsub("[^%w]", "")
  k = string.upper(k)
  return k
end

local function CleanCharRaids(ch)
  if not ch or not ch.raids then return end
  local new = {}
  for rk, v in pairs(ch.raids) do
    local ck = RT.CanonRaidKey(rk)
    if RT.DEFAULT_RAIDS[ck] and (not RT.DEFAULT_RAIDS[ck].manual) then
      local cur = new[ck] or { locked = false, reset = 0 }
      local resetNum = tonumber(v and v.reset) or 0
      if (tonumber(cur.reset) or 0) < resetNum then
        cur.reset = resetNum
      end
      if v and v.locked then
        cur.locked = true
      end
      new[ck] = cur
    end
  end
  ch.raids = new
end


local function EnsureDB()
  if not RaidTrackerDB then RaidTrackerDB = {} end
  RaidTrackerDB.version = RaidTrackerDB.version or 1
  RaidTrackerDB.realms = RaidTrackerDB.realms or {}
  RaidTrackerDB.config = RaidTrackerDB.config or {}
  RaidTrackerDB.config.showChars = RaidTrackerDB.config.showChars or {}
  RaidTrackerDB.config.enabledRaids = RaidTrackerDB.config.enabledRaids or {}
  if RaidTrackerDB.config.autoShowNewImported == nil then RaidTrackerDB.config.autoShowNewImported = false end
  if RaidTrackerDB.config.chatFallbackWhisper == nil then RaidTrackerDB.config.chatFallbackWhisper = true end
  if RaidTrackerDB.config.whisperOnlySync == nil then RaidTrackerDB.config.whisperOnlySync = true end
  -- Channel toggles for sync (for testing / server compatibility)
  if RaidTrackerDB.config.sniffOnlyRT == nil then RaidTrackerDB.config.sniffOnlyRT = true end
  if RaidTrackerDB.config.syncUseWhisper == nil then
    RaidTrackerDB.config.syncUseWhisper = false
  end
  if RaidTrackerDB.config.syncUseAddon == nil then RaidTrackerDB.config.syncUseAddon = true end
  if RaidTrackerDB.config.replyAllOnREQ == nil then RaidTrackerDB.config.replyAllOnREQ = true end
  if RaidTrackerDB.config.autoReqAll == nil then RaidTrackerDB.config.autoReqAll = true end

  -- Weekly raid quest IDs (Archmage Lan'dalock, WotLK): 24579-24590
  RaidTrackerDB.config.weeklyQuestIds = RaidTrackerDB.config.weeklyQuestIds or {}
  RaidTrackerDB.config.weeklyQuestTitles = RaidTrackerDB.config.weeklyQuestTitles or {}
  if next(RaidTrackerDB.config.weeklyQuestIds) == nil then
    for qid = 24579, 24590 do
      RaidTrackerDB.config.weeklyQuestIds[qid] = true
    end
  end


  -- Default raids enabled
  for key, _ in pairs(RT.DEFAULT_RAIDS) do
    if RaidTrackerDB.config.enabledRaids[key] == nil then
      RaidTrackerDB.config.enabledRaids[key] = true
    end
  end

  -- Auto-sync (forced enabled)
  RaidTrackerDB.config.autoSync = true

-- (removed stray end)

  RaidTrackerDB.sync = RaidTrackerDB.sync or { inbox = {} } -- per-account incoming exports (copy/paste later)

  return RaidTrackerDB
end

local function EnsureRealm(realm)
  local db = EnsureDB()
  db.realms[realm] = db.realms[realm] or { chars = {} }
  return db.realms[realm]
end

function RT.GetDB()
  return EnsureDB()
end

function RT.GetCharData(realm, name)
  local r = EnsureRealm(realm)
  r.chars[name] = r.chars[name] or { class = "UNKNOWN", lastUpdate = 0, raids = {}, weekly = {} }
  return r.chars[name]
end

function RT.IsCharShown(realm, name)
  local db = EnsureDB()
  local key = RT.CharKey(realm, name)
  return db.config.showChars[key] ~= false
end

function RT.SetCharShown(realm, name, shown)
  local db = EnsureDB()
  local key = RT.CharKey(realm, name)
  db.config.showChars[key] = shown and true or false
end

function RT.IsRaidEnabled(raidKey)
  local db = EnsureDB()
  return db.config.enabledRaids[raidKey] == true
end

function RT.SetRaidEnabled(raidKey, enabled)
  local db = EnsureDB()
  db.config.enabledRaids[raidKey] = enabled and true or false
end

function RT.GetWeeklyState(realm, name)
  local ch = RT.GetCharData(realm, name)
  ch.weekly = ch.weekly or {}
  local wk = RT.GetWeekId(Now())
  local cur = tonumber(ch.weekly.weekId) or 0
  if cur ~= wk then
    ch.weekly.weekId = wk
    ch.weekly.done = false
    ch.weekly.inProgress = false
    ch.weekly.ready = false
    ch.weekly.questId = 0
    ch.weekly.activeQuestId = 0
    ch.weekly.questTitle = nil
    ch.weekly.ts = 0
    ch.weekly.turninPending = nil
  end
  return ch.weekly
end


-- Auto-reset raid locks when server reset time has passed.
function RT.ResetExpiredRaids(nowTs)
  local db = RT.GetDB()
  if not db or not db.realms then return end
  local now = nowTs or Now()

  for realm, rdata in pairs(db.realms) do
    if rdata and rdata.chars then
      for name, ch in pairs(rdata.chars) do
        if ch and ch.raids then
          for rk, rd in pairs(ch.raids) do
            if rd and rd.locked and rd.reset and tonumber(rd.reset) and tonumber(rd.reset) > 0 then
              if now >= tonumber(rd.reset) then
                rd.locked = false
                rd.reset = 0
                rd.ts = Now()
              end
            end
          end
        end
      end
    end
  end
end


local function MatchRaidKey(instName, maxPlayers)
  if not instName then return nil end
  for key, def in pairs(RT.DEFAULT_RAIDS) do
    if not def.manual and def.patterns and def.maxPlayers == maxPlayers then
      for _, pat in ipairs(def.patterns) do
        if string.find(instName, pat, 1, true) then
          return key
        end
      end
    end
  end
  return nil
end

local pendingScan = false

function RT.RequestScan()
  pendingScan = true
  -- Immediate scan so the UI updates even if UPDATE_INSTANCE_INFO is delayed.
  pcall(RT.ScanNow)
  if RequestRaidInfo then
    RequestRaidInfo()
  end
end

function RT.ScanNow()
  local realm = RealmName()
  local name = PlayerName()
  local ch = RT.GetCharData(realm, name)
  ch.isLocal = true
  ch.class = PlayerClass()
  ch.lastUpdate = Now()
  RT.ResetExpiredRaids(ch.lastUpdate)
  ch.raids = ch.raids or {}

  -- Clear current tracked raids (only the ones we know)
  for rk, def in pairs(RT.DEFAULT_RAIDS) do
    if not def.manual then
      ch.raids[rk] = { locked = false, reset = 0 }
    end
  end

  local n = (GetNumSavedInstances and GetNumSavedInstances()) or 0
  for i = 1, n do
    local instName, instID, reset, difficulty, locked, extended, instIDMostSig, isRaid, maxPlayers
    if GetSavedInstanceInfo then
      instName, instID, reset, difficulty, locked, extended, instIDMostSig, isRaid, maxPlayers = GetSavedInstanceInfo(i)
    end

    if isRaid and maxPlayers and instName then
      local rk = MatchRaidKey(instName, maxPlayers)
      if rk then
        ch.raids[rk] = {
          locked = locked and true or false,
          reset = (locked and true or false) and NextRaidReset(Now()) or 0,
          name = instName,
          maxPlayers = maxPlayers,
        }
      end
    end
  end

  -- Ensure weekly key is current
  RT.GetWeeklyState(realm, name)

  if RT.UI and RT.UI.Refresh then
    RT.UI.Refresh()
  end

  -- Broadcast updated snapshot (if live sync is available)
  local db = EnsureDB()
  if db.config.autoSync and RT.Sync and RT.Sync.SendSnapshot then
    pcall(RT.Sync.SendSnapshot)
  end
end

-- Events
local f = CreateFrame("Frame")
RT._eventFrame = f

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UPDATE_INSTANCE_INFO")
f:RegisterEvent("QUEST_ACCEPTED")
f:RegisterEvent("QUEST_LOG_UPDATE")
f:RegisterEvent("QUEST_COMPLETE")
f:RegisterEvent("QUEST_FINISHED")
f:RegisterEvent("QUEST_QUERY_COMPLETE")
f:RegisterEvent("GOSSIP_SHOW")
f:RegisterEvent("QUEST_GREETING")

-- Periodic maintenance (disabled: runs only when the UI is opened to avoid background stutters)
-- Weekly auto-check (2s) and reset maintenance (60s) are intentionally disabled.
-- See UI.Toggle() for manual calls: RT.RequestScan(), RT.UpdateWeeklyAuto(), RT.ResetExpiredRaids()


-- ===== Utilities for testing / debugging =====
function RT.ForceResetAll()
  local db = EnsureDB()
  for _, r in pairs(db.realms or {}) do
    for _, ch in pairs(r.chars or {}) do
      if type(ch) == "table" then
        if type(ch.raids) == "table" then
          for rk,_ in pairs(ch.raids) do ch.raids[rk] = nil end
        end
        ch.weekly = ch.weekly or {}
        ch.weekly.weekId = RT.GetWeekId(Now())
        ch.weekly.done = false
        ch.weekly.ts = 0
    ch.weekly.turninPending = nil
      end
    end
  end
  if RT.UI and RT.UI.Refresh then RT.UI.Refresh() end
end

function RT.WipeAllData()
  local db = EnsureDB()
  db.realms = {}
  db.sync = { inbox = {} }
  -- keep enabledRaids + config, but clear shown chars (fresh start)
  db.config.showChars = {}
  if RT.UI and RT.UI.Refresh then RT.UI.Refresh() end
end

function RT.WipeChar(realm, name)
  local db = EnsureDB()
  local r = db.realms and db.realms[realm]
  if r and r.chars then r.chars[name] = nil end
  if db.config and db.config.showChars then
    db.config.showChars[RT.CharKey(realm, name)] = nil
  end
  if RT.UI and RT.UI.Refresh then RT.UI.Refresh() end
end

function RT.ShowAllChars()
  local db = EnsureDB()
  db.config.showChars = db.config.showChars or {}
  for realm, r in pairs(db.realms or {}) do
    for name,_ in pairs(r.chars or {}) do
      db.config.showChars[RT.CharKey(realm, name)] = true
    end
  end
  if RT.UI and RT.UI.Refresh then RT.UI.Refresh() end
end

function RT.DumpSyncLog()
  local db = EnsureDB()
  local out = {}
  for i, line in ipairs(db.syncLog or {}) do
    out[#out+1] = line
  end
  return table.concat(out, "\n")
end
f:SetScript("OnEvent", function(_, event, ...)
  EnsureDB()
  if RT and RT.ResetExpiredRaids then RT.ResetExpiredRaids() end
  if RT and RT.UpdateWeeklyAuto then RT.UpdateWeeklyAuto() end
  -- Weekly raid quest auto-tracking (no UI needed)
  if event == "QUEST_COMPLETE" then
    if RT and RT.NoteWeeklyTurninPending then pcall(RT.NoteWeeklyTurninPending) end
  end
  if event == "QUEST_ACCEPTED" or event == "QUEST_LOG_UPDATE" or event == "QUEST_COMPLETE" or event == "QUEST_FINISHED" then
    if RT and RT.UpdateWeeklyAuto then RT.UpdateWeeklyAuto() end
    if RT.UI and RT.UI.Refresh then RT.UI.Refresh(true) end
    return
  elseif event == "QUEST_QUERY_COMPLETE" then
    -- Weekly raid quests are repeatable; completed-quest history causes false positives.
    -- We keep this event for future debugging, but we do not auto-mark weekly DONE from it.
    RT._qc_pending = false
    if RT.UI and RT.UI.Refresh then RT.UI.Refresh(true) end
    return
  elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" then
    if RT and RT.CheckWeeklyFromGossip then RT.CheckWeeklyFromGossip() end
    if RT.UI and RT.UI.Refresh then RT.UI.Refresh(true) end
    return

  end


  if event == "PLAYER_LOGIN" then
    -- Register slash commands
    SLASH_RAIDTRACKER1 = "/rt"
    SLASH_RAIDTRACKER2 = "/raidtracker"
    SlashCmdList["RAIDTRACKER"] = function(msg)
      msg = tostring(msg or "")
      local cmd, rest = msg:match("^(%S+)%s*(.-)$")
  cmd = (cmd or ""):lower()
  if cmd == "sniff" then
    if RT.ToggleQuestSniff then RT.ToggleQuestSniff() end
    if RT.Print then RT.Print(RT.L.QUEST_SNIFF_TOGGLED) end
    return
  end
      cmd = (cmd and cmd:lower()) or ""
      rest = rest or ""

      if cmd == "scan" then
        RT.RequestScan()
        return
      end

      
      if cmd == "tools" then
        if RT and RT.UI and RT.UI.ToggleTools then RT.UI.ToggleTools() end
        return
      end

if cmd == "cf" then
        local db = EnsureDB()
        local a = (rest or ''):lower()
        if a == 'on' or a == '1' then
          db.config.syncUseWhisper = true
        elseif a == 'off' or a == '0' then
          db.config.syncUseWhisper = false
        else
          db.config.syncUseWhisper = not db.config.syncUseWhisper
        end
        -- Legacy mirrors (kept for older builds)
        db.config.whisperOnlySync = db.config.syncUseWhisper and true or false
        db.config.chatFallbackWhisper = db.config.syncUseWhisper and true or false

        if (not db.config.syncUseWhisper) and (not db.config.syncUseAddon) then
          db.config.syncUseWhisper = true
        end

        local on = db.config.syncUseWhisper and 'ON' or 'OFF'
        local msg = string.format(RT.L.WHISPER_CHANNEL_TOGGLE_FMT, on)
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
          DEFAULT_CHAT_FRAME:AddMessage(msg)
        else
          print(msg)
        end
        return
      end

      if cmd == "api" then
        local db = EnsureDB()
        local a = (rest or ''):lower()
        if a == 'on' or a == '1' then
          db.config.syncUseAddon = true
        elseif a == 'off' or a == '0' then
          db.config.syncUseAddon = false
        else
          db.config.syncUseAddon = not db.config.syncUseAddon
        end

        if (not db.config.syncUseWhisper) and (not db.config.syncUseAddon) then
          db.config.syncUseWhisper = true
        end

        local on = db.config.syncUseAddon and 'ON' or 'OFF'
        local msg = string.format(RT.L.API_CHANNEL_TOGGLE_FMT, on)
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
          DEFAULT_CHAT_FRAME:AddMessage(msg)
        else
          print(msg)
        end
        return
      end

      if cmd == "debug" then
        local db = EnsureDB()
        db.config.debugSync = not db.config.debugSync
        local on = db.config.debugSync and "ON" or "OFF"
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
          DEFAULT_CHAT_FRAME:AddMessage(string.format(RT.L.DEBUG_SYNC_FMT, on))
        else
          print(string.format(RT.L.DEBUG_SYNC_FMT, on))
        end
        return
      end

      if cmd == "sync" then
        local target = rest:gsub("^%s+",""):gsub("%s+$","")
        if target == "" then
          DEFAULT_CHAT_FRAME:AddMessage(RT.L.USAGE_SYNC)
          return
        end
        if RT.Sync and RT.Sync.RequestAllTo then
          RT.Sync.RequestAllTo(target)
          DEFAULT_CHAT_FRAME:AddMessage(string.format(RT.L.SYNC_REQALL_FMT, target))
        end
        return
      end

      if cmd == "sync1" then
        local target = rest:gsub("^%s+",""):gsub("%s+$","")
        if target == "" then
          DEFAULT_CHAT_FRAME:AddMessage(RT.L.USAGE_SYNC1)
          return
        end
        if RT.Sync and RT.Sync.RequestTo then
          RT.Sync.RequestTo(target)
          DEFAULT_CHAT_FRAME:AddMessage(string.format(RT.L.SYNC_REQ_FMT, target))
        end
        return
      end


      if cmd == "autosync" or cmd == "syncnow" then
        if RT.Sync and RT.Sync.RequestSnapshots and RT.Sync.SendSnapshot then
          RT.Sync.RequestSnapshots()
          RT.Sync.SendSnapshot()
          DEFAULT_CHAT_FRAME:AddMessage(RT.L.AUTOSYNC_TRIGGERED)
        else
          DEFAULT_CHAT_FRAME:AddMessage(RT.L.AUTOSYNC_UNAVAILABLE)
        end
        return
      end
      if cmd == "reset" then
        RT.ForceResetAll()
        DEFAULT_CHAT_FRAME:AddMessage(RT.L.RESET_APPLIED)
        return
      end

      if cmd == "wipeall" then
        RT.WipeAllData()
        DEFAULT_CHAT_FRAME:AddMessage(RT.L.WIPEALL_DONE)
        return
      end

      if cmd == "wipechar" then
        local target = rest:gsub("^%s+",""):gsub("%s+$","")
        if target == "" then
          DEFAULT_CHAT_FRAME:AddMessage(RT.L.USAGE_WIPECHAR)
          return
        end
        local realm = RealmName()
        RT.WipeChar(realm, target)
        DEFAULT_CHAT_FRAME:AddMessage(string.format(RT.L.WIPECHAR_DONE_FMT, target))
        return
      end

      if cmd == "showall" then
        RT.ShowAllChars()
        DEFAULT_CHAT_FRAME:AddMessage(RT.L.SHOW_ALL)
        return
      end

if cmd == "refresh" then
  -- Refresh ONLY RaidTracker UI. Never open/close/recenter the window.
  if RT.UI then
    if RT.UI.frame and RT.UI.frame.IsShown and RT.UI.frame:IsShown() then
      if RT.UI.Refresh then pcall(RT.UI.Refresh, true) end
      DEFAULT_CHAT_FRAME:AddMessage(RT.L.UI_REFRESH_OK)
    else
      if RT.UI.MarkDirty then RT.UI.MarkDirty() end
      DEFAULT_CHAT_FRAME:AddMessage(RT.L.UI_REFRESH_MARKED)
    end
  end
  return
end

      if cmd == "dumplog" then
        if RT.UI and RT.UI.ShowTextPopup then
          RT.UI.ShowTextPopup(RT.L.SYNC_LOG, RT.DumpSyncLog())
        else
          DEFAULT_CHAT_FRAME:AddMessage(RT.L.LOG_OPEN_FAIL)
        end
        return
      end

      -- Default: toggle UI
      if RT.UI and RT.UI.Toggle then RT.UI.Toggle() end
    end

    -- Default: new characters hidden
    local realm = RealmName()
    local name = PlayerName()
    local key = RT.CharKey(realm, name)
    local db = EnsureDB()
    if db.config.showChars[key] == nil then
      db.config.showChars[key] = true
    end

    -- Ensure current character exists in DB immediately so sync can send even before instance info arrives.
    local ch = RT.GetCharData(realm, name)
    ch.class = PlayerClass()
    ch.lastUpdate = ch.lastUpdate or 0
    RT.GetWeeklyState(realm, name)

    -- Kick an initial scan
    RT.RequestScan()

    -- Init live sync listener
    if RT.Sync and RT.Sync.Init then
      pcall(RT.Sync.Init)
    end

  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Sometimes instance info becomes available shortly after entering world
    RT.RequestScan()

  elseif event == "UPDATE_INSTANCE_INFO" then
    if pendingScan then
      pendingScan = false
      RT.ScanNow()
    end
  end
end)