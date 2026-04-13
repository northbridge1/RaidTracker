-- RaidTracker - Sync (Export/Import + Live Sync)
-- Live sync can use both SendAddonMessage (API) and/or chat whisper fallback (RTSYNC), selectable in the Config window.

local ADDON = ...
RaidTracker = RaidTracker or {}
local RT = RaidTracker
RT.Sync = RT.Sync or {}
local SYNC = RT.Sync
local L = RT.L

local PREFIX = "RTSYNC"

-- Transport chunking (prevents truncation on some cores/servers)
local MAX_WIRE = 235  -- conservative payload budget (bytes), excluding prefix/tag overhead


-- Time helper (stable across cores)
local function Now()
  if GetServerTime then return GetServerTime() end
  return time()
end

-- Reassembly buffers: key = sender|id, value = { total=..., parts={...}, t=Now() }
SYNC._chunks = SYNC._chunks or {}
SYNC._reqBack = SYNC._reqBack or {}
local REQBACK_COOLDOWN = 60

local function PruneChunks()
  local now = Now()
  for k, v in pairs(SYNC._chunks) do
    if (not v) or (not v.t) or (now - v.t) > 30 then
      SYNC._chunks[k] = nil
    end
  end
end

local CHAT_TAG = 'RTSYNC' -- chat whisper fallback tag

-- Incoming sync approval (unknown characters)
SYNC._pendingApprovals = SYNC._pendingApprovals or {} -- key=lowerName -> { t=Now(), kind='REQ'/'REQALL' }
SYNC._denied = SYNC._denied or {} -- key=lowerName -> ts
local APPROVAL_COOLDOWN = 120

local function IsKnownCharacterName(name)
  if not name or name == "" then return false end
  local db = RT.GetDB and RT.GetDB() or nil
  if not db or not db.realms then return false end
  local nlow = string.lower(tostring(name))
  for _, r in pairs(db.realms) do
    if r and r.chars then
      for cn, _ in pairs(r.chars) do
        if string.lower(tostring(cn)) == nlow then
          return true
        end
      end
    end
  end
  return false
end

local function IsApprovedSender(name)
  if not name or name == "" then return false end
  local db = RT.GetDB and RT.GetDB() or nil
  if not db or not db.config then return false end
  db.config.approvedSyncSenders = db.config.approvedSyncSenders or {}
  return db.config.approvedSyncSenders[string.lower(tostring(name))] == true
end

local function SetApprovedSender(name, v)
  if not name or name == "" then return end
  local db = RT.GetDB and RT.GetDB() or nil
  if not db or not db.config then return end
  db.config.approvedSyncSenders = db.config.approvedSyncSenders or {}
  db.config.approvedSyncSenders[string.lower(tostring(name))] = (v and true or nil)
end


local function IsBlacklistedSender(name)
  if not name or name == "" then return false end
  local db = RT.GetDB and RT.GetDB() or nil
  if not db or not db.config then return false end
  db.config.syncBlacklist = db.config.syncBlacklist or {}
  return db.config.syncBlacklist[string.lower(tostring(name))] and true or false
end

local function SetBlacklistedSender(name, v)
  if not name or name == "" then return end
  local db = RT.GetDB and RT.GetDB() or nil
  if not db or not db.config then return end
  db.config.syncBlacklist = db.config.syncBlacklist or {}
  local k = string.lower(tostring(name))
  if v then
    db.config.syncBlacklist[k] = tostring(name)
  else
    db.config.syncBlacklist[k] = nil
  end
end

local function EnsureApprovalPopup()
  if StaticPopupDialogs and StaticPopupDialogs["RAIDTRACKER_SYNC_APPROVE"] then return end
  if not StaticPopupDialogs then return end

  StaticPopupDialogs["RAIDTRACKER_SYNC_APPROVE"] = {
    text = L.APPROVAL_REQ,
    button1 = L.ACCEPT,
    button2 = L.DENY,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,

    OnAccept = function(self, data)
      if not data or not data.sender then return end
      if SYNC and SYNC.ApproveIncoming then
        SYNC.ApproveIncoming(data.sender, data.kind)
      end
    end,

    OnCancel = function(self, data)
      if not data or not data.sender then return end
      if SYNC and SYNC.DenyIncoming then
        SYNC.DenyIncoming(data.sender)
      end
    end,
  }
end

function SYNC.MaybeAskApproval(sender, kind)
  if not sender or sender == "" then return true end
  local selfName = UnitName and UnitName("player") or nil
  if selfName and sender == selfName then return true end

  -- Blacklist: always ignore (no popup)
  if IsBlacklistedSender(sender) then
    SYNC._denied[string.lower(tostring(sender))] = Now()
    return false
  end

  -- Already known (in your list) or previously approved
  if IsKnownCharacterName(sender) or IsApprovedSender(sender) then
    return true
  end

  local key = string.lower(tostring(sender))
  local now = Now()

  local deniedTs = SYNC._denied[key]
  if deniedTs and (now - deniedTs) < APPROVAL_COOLDOWN then
    return false
  end

  local p = SYNC._pendingApprovals[key]
  if p and p.t and (now - p.t) < APPROVAL_COOLDOWN then
    return false
  end

  SYNC._pendingApprovals[key] = { t = now, kind = kind or "REQ" }

  EnsureApprovalPopup()
  if StaticPopupDialogs and StaticPopupDialogs["RAIDTRACKER_SYNC_APPROVE"] and StaticPopup_Show then
    local label = sender
    if kind == "REQALL" then
      StaticPopupDialogs["RAIDTRACKER_SYNC_APPROVE"].text = L.APPROVAL_REQALL
    else
      StaticPopupDialogs["RAIDTRACKER_SYNC_APPROVE"].text = L.APPROVAL_REQ
    end
    StaticPopup_Show("RAIDTRACKER_SYNC_APPROVE", label, nil, { sender = sender, kind = kind or "REQ" })
  end

  return false
end

function SYNC.ApproveIncoming(sender, kind)
  if not sender or sender == "" then return end
  local key = string.lower(tostring(sender))
  SYNC._pendingApprovals[key] = nil

  -- Remember approval so we don't ask again next time
  SetApprovedSender(sender, true)

  -- Process the pending request now
  if kind == "REQALL" and SYNC.HandleIncomingREQALL then
    SYNC.HandleIncomingREQALL(sender, true)
  elseif SYNC.HandleIncomingREQ then
    SYNC.HandleIncomingREQ(sender, true)
  end
end

function SYNC.DenyIncoming(sender)
  if not sender or sender == "" then return end
  local key = string.lower(tostring(sender))
  SYNC._pendingApprovals[key] = nil
  SYNC._denied[key] = Now()
end


-- Public helpers for Config UI
function SYNC.ClearApproval(sender)
  if not sender or sender == "" then return end
  SetApprovedSender(sender, false)
  local key = string.lower(tostring(sender))
  SYNC._pendingApprovals[key] = nil
end

function SYNC.BlacklistAdd(sender)
  if not sender or sender == "" then return end
  SetBlacklistedSender(sender, true)
  SYNC.ClearApproval(sender)
end

function SYNC.BlacklistRemove(sender)
  if not sender or sender == "" then return end
  SetBlacklistedSender(sender, false)
end



local function EscapeForChat(s)
  s = tostring(s or '')
  s = s:gsub('\r', ' '):gsub('\n', ' '):gsub('\t', ' ')
  -- WoW chat uses '|' as escape char; duplicate it to preserve literal pipes
  s = s:gsub('|', '||')
  return s
end


local function NormalizeName(name)
  if not name or name == "" then return name end
  name = tostring(name)
  name = name:match("^([^%-]+)") or name
  local f = name:sub(1,1)
  local r = name:sub(2)
  return f:upper() .. r:lower()
end

local function DebugPrint(...)
  local db = RT.GetDB and RT.GetDB() or nil

  local parts = {}
  for i = 1, select('#', ...) do
    parts[#parts+1] = tostring(select(i, ...))
  end
  local line = table.concat(parts, ' ')

  -- Persist a ring-buffer log for easier debugging across accounts
  if db then
    db.syncLog = db.syncLog or {}
    local ts = date and date('%H:%M:%S') or ''
    db.syncLog[#db.syncLog+1] = ts .. ' ' .. line
    if #db.syncLog > 300 then
      table.remove(db.syncLog, 1)
    end
  end

  if not (db and db.config and db.config.debugSync) then return end

  local msg = '|cffffcc00RaidTracker:|r ' .. line
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(msg)
  else
    print(msg)
  end
end


-- Small scheduler (3.3.5 doesn't have C_Timer)
do
  local schedF
  local tasks = {}
  function SYNC.After(sec, fn)
    if type(fn) ~= "function" then return end
    if not schedF then
      schedF = CreateFrame("Frame")
      schedF:SetScript("OnUpdate", function(_, elapsed)
        for i = #tasks, 1, -1 do
          local t = tasks[i]
          t.left = t.left - elapsed
          if t.left <= 0 then
            table.remove(tasks, i)
            pcall(t.fn)
          end
        end
        if #tasks == 0 then schedF:Hide() end
      end)
      schedF:Hide()
    end
    table.insert(tasks, { left = sec or 0, fn = fn })
    schedF:Show()
  end
end

local function MarkUIRefresh()
  if SYNC._refreshPending then return end
  SYNC._refreshPending = true
  SYNC.After(0.25, function()
    SYNC._refreshPending = false
    if RT.UI then
      if RT.UI.frame and RT.UI.frame.IsShown and RT.UI.frame:IsShown() then
        if RT.UI.Refresh then pcall(RT.UI.Refresh, true) end
      else
        if RT.UI.MarkDirty then RT.UI.MarkDirty() end
      end
    end
  end)
end

local function PickChannel()
  -- Prefer true group contexts only. We intentionally do NOT use GUILD broadcast:
  -- it would spam the guild and we also don't want to rely on it for direct sync.
  if IsInRaid and IsInRaid() then return "RAID" end
  if IsInGroup and IsInGroup() then return "PARTY" end
  if UnitInBattleground and UnitInBattleground("player") then return "BATTLEGROUND" end
  return nil
end

-- Known peers (character names) stored per account to allow WHISPER sync when not in group/guild.
local function AddPeer(name)
  if not name or name == "" then return end
  local db = RT.GetDB()
  db.peers = db.peers or {}
  db.peers[name] = Now()
end

local function GetKnownPeers()
  local db = RT.GetDB()
  local out = {}
  for n,_ in pairs(db.peers or {}) do table.insert(out, n) end
  return out
end

local function GetOnlineFriends()
  local out = {}
  if not GetNumFriends or not GetFriendInfo then return out end
  local n = GetNumFriends()
  for i=1,n do
    local fname, _, _, _, connected = GetFriendInfo(i)
    if fname and connected then table.insert(out, fname) end
  end
  return out
end

local function WhisperTargets()
  local targets, seen = {}, {}
  local selfName = UnitName and UnitName("player") or nil
  local function add(n)
    if not n or n == "" then return end
    if selfName and n == selfName then return end
    if not seen[n] then seen[n]=true; table.insert(targets, n) end
  end
  for _,n in ipairs(GetOnlineFriends()) do add(n) end
  for _,n in ipairs(GetKnownPeers()) do add(n) end
  return targets
end

-- Forward declaration (needed because ThrottledWhisper uses it)
local function SafeSend(msg, channel, target) end

local function ThrottledWhisper(msg)
  local list = WhisperTargets()
  if #list == 0 then return false end
  DebugPrint("Whisper queue:", #list, "targets")
  local i = 1
  local function step()
    if i > #list then return end
    DebugPrint("-> WHISPER", list[i], msg:sub(1, 12))
    SafeSend(msg, "WHISPER", list[i])
    i = i + 1
    if i <= #list then SYNC.After(0.35, step) end
  end
  step()
  return true
end

-- Safe wrapper around SendAddonMessage.
-- Supports an optional WHISPER chat fallback (useful for some 3.3.5 setups / server quirks).
SafeSend = function(msg, channel, target, allowChatFallback)
  if not channel then return false end
  msg = tostring(msg or '')

  -- Forced: ONLY SendAddonMessage transport (no SendChatMessage whisper fallback)
  local useAddon = (SendAddonMessage ~= nil)

  local addonMsg = msg
  -- Some servers/cores filter addon WHISPER payloads containing pipes. Use a pipe-less encoding for addon channel.
  if msg:sub(1,3) == 'DAT' and string.match(msg:sub(4,4), '%s') then
    local payload = msg:sub(5)

    -- Transport-safe encoding (Warmane-safe, no pipes):
    -- 1) Percent-escape '%' and ',' so we can safely use ',' as the transport substitute for '|'
    -- 2) Add a simple checksum prefix to detect truncated/corrupted packets
    local enc = payload:gsub('%%', '%%25'):gsub(',', '%%2C')

    local sum = 0
    for i = 1, #enc do
      sum = (sum + (string.byte(enc, i) or 0)) % 1000
    end

    local transport = tostring(sum) .. ',' .. enc:gsub('|', ',')
    local wire = 'DTA ' .. transport

    -- Chunk if needed (server-safe on addon WHISPER)
    if #wire > MAX_WIRE then
      local id = tostring(Now()) .. tostring(math.random(100,999))
      local body = transport
      local maxChunk = MAX_WIRE - 40
      if maxChunk < 80 then maxChunk = 80 end

      local total = math.ceil(#body / maxChunk)
      local part = 1

      local function send_one(chunkMsg)
        if (not useAddon) or (not SendAddonMessage) then return false end
        if channel == 'WHISPER' then
          if target and target ~= '' then
            local ok = pcall(SendAddonMessage, PREFIX, chunkMsg, 'WHISPER', NormalizeName(target))
            return ok and true or false
          end
          return false
        else
          local ok = pcall(SendAddonMessage, PREFIX, chunkMsg, channel)
          return ok and true or false
        end
      end

      while part <= total do
        local s = (part-1)*maxChunk + 1
        local e = math.min(#body, part*maxChunk)
        local chunk = body:sub(s, e)
        local chunkMsg = 'DTB ' .. id .. ',' .. tostring(part) .. ',' .. tostring(total) .. ',' .. chunk
        send_one(chunkMsg)
        part = part + 1
      end
      return true
    end

    addonMsg = wire
  end

  local sent = false

  -- AddonMessage (API)
  if useAddon and SendAddonMessage then
    if channel == 'WHISPER' then
      if target and target ~= '' then
        local ok = pcall(SendAddonMessage, PREFIX, addonMsg, 'WHISPER', NormalizeName(target))
        sent = sent or ok
      end
    else
      local ok = pcall(SendAddonMessage, PREFIX, addonMsg, channel)
      sent = sent or ok
    end
  end

  return sent
end


local function Esc(s)
  s = tostring(s or "")
  s = s:gsub("\\", "\\\\")
  s = s:gsub("\n", "\\n")
  s = s:gsub("\t", "\\t")
  return s
end

local function EscapePipesForUI(s)
  -- In WoW editboxes/chat, '|' starts escape sequences. Doubling it makes it literal.
  return (tostring(s or ""):gsub("|", "||"))
end

local function Unesc(s)
  s = tostring(s or "")
  s = s:gsub("\\t", "\t")
  s = s:gsub("\\n", "\n")
  s = s:gsub("\\\\", "\\")
  return s
end


-- Some strings coming from the client (especially quest links) may contain '|' which breaks our field delimiter.
-- Keep weekly quest title transport-safe by stripping link formatting and pipes.
local function CleanQuestTitle(t)
  t = tostring(t or "")
  if t == "" then return t end
  if string.find(t, "|", 1, true) then
    -- If it's a quest link, prefer the [Title] portion.
    local br = string.match(t, "%[(.-)%]")
    if br and br ~= "" then
      t = br
    else
      -- Strip common WoW link/color sequences if present
      t = t:gsub("%|c%x%x%x%x%x%x%x%x", "")
      t = t:gsub("%|r", "")
      t = t:gsub("%|H.-%|h", "")
      t = t:gsub("%|h", "")
    end
    -- Finally, remove any remaining pipes
    t = t:gsub("%|", "")
  end
  -- Avoid breaking comma-transport parsing
  t = t:gsub(',', ' ')
  return t
end


-- Export format (Copy/Paste safe lines):
-- RT2|<realm>|<char>|<class>|<lastUpdate>|<weekId>|<weeklyDone>|<weeklyTs>|<raidKey>:<locked>:<resetAt>;...
-- NOTE: We intentionally avoid TABs here because some 3.3.5 editboxes / copy-paste paths may
-- replace or strip TAB characters.

function RT.ExportData(opts)
  opts = opts or {}
  if opts.onlyShown == nil then opts.onlyShown = true end
  local db = RT.GetDB()
  local out = {}
  table.insert(out, "RT1")

  for realm, rdata in pairs(db.realms or {}) do
    for name, c in pairs(rdata.chars or {}) do
      local shown = RT.IsCharShown(realm, name)
      if (not opts.onlyShown) or shown then
        local raids = {}
  -- Always export a full raid set (including 0/0) so receivers can clear stale lockouts.
  local raidKeys = RT.RAID_KEYS or {}
  c.raids = c.raids or {}
  for _, rk in ipairs(raidKeys) do
    if RT.IsRaidEnabled(rk) then
      local v = c.raids[rk]
      local locked = (v and v.locked) and 1 or 0
      local resetAt = v and tonumber(v.reset) or 0
      table.insert(raids, string.format("%s:%d:%d", rk, locked, resetAt))
    end
  end
local weeklyKey = (c.weekly and c.weekly.key) or ""
        local weeklyDone = (c.weekly and c.weekly.done) and 1 or 0

        local line = table.concat({
          "RT1",
          Esc(realm),
          Esc(name),
          Esc(c.class or "UNKNOWN"),
          tostring(tonumber(c.lastUpdate) or 0),
          Esc(weeklyKey),
          tostring(weeklyDone),
          Esc(table.concat(raids, ";")),
        }, "|")
        -- Make it safe to COPY from WoW editboxes (prevents |R etc being interpreted)
        table.insert(out, EscapePipesForUI(line))
      end
    end
  end

  return table.concat(out, "\n")
end

local function ExportCharLine(realm, name)
  local db = RT.GetDB()
  local rdata = db.realms and db.realms[realm]
  local c = rdata and rdata.chars and rdata.chars[name]
  if not c then return nil end

  local raids = {}
  if c.raids then
    local seen = {}
    for rk, v in pairs(c.raids) do
      local ck = (RT.CanonRaidKey and RT.CanonRaidKey(rk)) or rk
      if ck and RT.DEFAULT_RAIDS and RT.DEFAULT_RAIDS[ck] and (not RT.DEFAULT_RAIDS[ck].manual) then
        if RT.IsRaidEnabled(ck) and (not seen[ck]) then
          local locked = (v and v.locked) and 1 or 0
          local resetAt = (v and tonumber(v.reset)) or 0
          table.insert(raids, string.format("%s:%d:%d", ck, locked, resetAt))
          seen[ck] = true
        elseif RT.IsRaidEnabled(ck) and seen[ck] then
          -- if there are duplicate dirty keys in the DB, keep the "strongest" (locked or newer reset)
          for i=1,#raids do
            local kk, ll, rr = string.match(raids[i], "([^:]+):([^:]+):([^:]+)")
            if kk == ck then
              local curL = tonumber(ll) or 0
              local curR = tonumber(rr) or 0
              local newL = ((v and v.locked) and 1 or 0)
              local newR = (v and tonumber(v.reset)) or 0
              if newR > curR then curR = newR end
              if newL > curL then curL = newL end
              raids[i] = string.format("%s:%d:%d", ck, curL, curR)
              break
            end
          end
        end
      end
    end
  end
  local weekId = tostring((c.weekly and tonumber(c.weekly.weekId)) or 0)
  local weeklyDone = (c.weekly and c.weekly.done) and 1 or 0
  local weeklyTs = tostring((c.weekly and tonumber(c.weekly.ts)) or 0)

  local weeklyProg = 0
  if c.weekly then
    if c.weekly.done then
      weeklyProg = 3
    elseif c.weekly.ready then
      weeklyProg = 2
    elseif c.weekly.inProgress then
      weeklyProg = 1
    end
  end

  return table.concat({
    "RT3",
    Esc(realm),
    Esc(name),
    Esc(c.class or "UNKNOWN"),
    tostring(tonumber(c.lastUpdate) or 0),
    weekId,
    tostring(weeklyDone),
    weeklyTs,
    tostring(weeklyProg),
    tostring((c.weekly and tonumber(c.weekly.questId)) or 0),
    Esc(CleanQuestTitle((c.weekly and c.weekly.questTitle) or "")),
    Esc(table.concat(raids, ";")),
  }, "|")
end

local function MergeChar(realm, name, class, lastUpdate, weekId, weeklyDone, weeklyTs, weeklyProg, weeklyQid, weeklyTitle, raidsBlob)
  local db0 = RT.GetDB()
  local existed0 = (db0 and db0.realms and db0.realms[realm] and db0.realms[realm].chars and db0.realms[realm].chars[name]) and true or false
  local c = RT.GetCharData(realm, name)
  local lu = tonumber(lastUpdate) or 0
  if (tonumber(c.lastUpdate) or 0) < lu then
    c.class = class or c.class
    c.lastUpdate = lu
  end
  local db = RT.GetDB()
  -- NEW CHAR POLICY:
  -- Do not auto-add newly synced characters to the visible table.
  -- This prevents deleted/hidden chars from reappearing.
  -- If you want them visible, enable them in Config.
  local existed = existed0
  if (not existed) and db and db.config and db.config.showChars then
    local autoShow = (db.config.autoShowNewImported == true)
    if RT.SetCharShown then
      RT.SetCharShown(realm, name, autoShow)
    else
      local key = (RT.CharKey and RT.CharKey(realm, name)) or nil
      if key then db.config.showChars[key] = autoShow and true or false end
    end
  end
  c.weekly = c.weekly or {}
do
  local srcWeek = tonumber(weekId) or 0
  local srcProgN = tonumber(weeklyProg) or 0
  local srcDone = ((tonumber(weeklyDone) or 0) == 1) or (srcProgN == 3)
  local srcTs = tonumber(weeklyTs) or 0
  local srcReady = (srcProgN == 2)
  local srcInProg = (srcProgN == 1)
  local srcQid = tonumber(weeklyQid) or 0
  local srcTitle = Unesc(weeklyTitle or "")

  local dstWeek = tonumber(c.weekly.weekId) or 0
  local dstTs = tonumber(c.weekly.ts) or 0

  local function apply()
    c.weekly.weekId = (srcWeek > 0) and srcWeek or dstWeek
    c.weekly.done = srcDone and true or false
    c.weekly.ready = (not c.weekly.done) and (srcReady and true or false) or false
    c.weekly.inProgress = (not c.weekly.done) and (not c.weekly.ready) and (srcInProg and true or false) or false
    c.weekly.ts = srcTs
    c.weekly.questId = srcQid
    if srcTitle ~= "" then c.weekly.questTitle = srcTitle end
    if c.weekly.done then
      c.weekly.ready = false
      c.weekly.inProgress = false
    elseif c.weekly.ready then
      c.weekly.inProgress = false
    end
  end

  -- Week change: only ever move forward in time.
  if srcWeek > 0 and dstWeek ~= srcWeek then
    if srcWeek > dstWeek then
      apply()
    end
  else
    -- Same week: accept only newer writes; never allow older data to clear newer true.
    if srcTs > dstTs then
      apply()
    else
      if srcDone then
        c.weekly.done = true
        c.weekly.ready = false
        c.weekly.inProgress = false
      elseif srcReady and (not c.weekly.done) then
        -- Promote READY over INPROGRESS; never allow older updates to clear
        c.weekly.ready = true
        c.weekly.inProgress = false
      elseif srcInProg and (not c.weekly.done) and (not c.weekly.ready) then
        -- don't allow older updates to clear progress; only promote
        c.weekly.inProgress = true
      end
    end
  end
end

  c.raids = c.raids or {}

  raidsBlob = Unesc(raidsBlob or "")
  for token in string.gmatch(raidsBlob, "[^;]+") do
    local rk, locked, resetAt = string.match(token, "([^:]+):([^:]+):([^:]+)")
    if rk then rk = rk:gsub("^%s+",""):gsub("%s+$","") end
    if rk and RT.DEFAULT_RAIDS[rk] and (not RT.DEFAULT_RAIDS[rk].manual) then
      local resetNum = tonumber(resetAt) or 0
      local cur = c.raids[rk] or { locked = false, reset = 0 }
      -- take the newer reset timestamp
      if (tonumber(cur.reset) or 0) < resetNum then
        cur.reset = resetNum
      end
      if (tonumber(locked) or 0) == 1 then
        cur.locked = true
      end
      c.raids[rk] = cur
    end
  end
end

function RT.ImportData(text)
  if not text or text == "" then return false, L.EMPTY_TEXT end
  -- normalize newlines
  text = tostring(text):gsub("\r\n", "\n"):gsub("\r", "\n")
  -- Normalize different "vertical bar" glyphs that can appear with copy/paste on 3.3.5.
  -- Also collapse doubled pipes ("||") which can happen because WoW uses '|' as an escape char.
  text = text
    :gsub("¦", "|")   -- broken bar
    :gsub("∣", "|")   -- divides
    :gsub("│", "|")   -- box drawings light vertical
    :gsub("┃", "|")   -- box drawings heavy vertical
    :gsub("￨", "|")   -- halfwidth vertical line
    :gsub("︱", "|")
  -- NOTE: Do NOT collapse '||' here. In network payloads, empty fields are encoded as '||'.
   -- presentation form for vertical line
  -- Collapse any doubled pipes to single pipes.
  while string.find(text, "||", 1, true) do
    text = text:gsub("||", "|")
  end

  local function Trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
  end

  local function ParseLine(line)
    line = Trim(line)
    if line == "" then return nil end
    if line == "RT1" then return "HDR" end

    -- Some copy/paste paths may prepend invisible characters; anchor at first "RT1".
    local s = string.find(line, "RT1", 1, true)
    if s and s > 1 then
      line = string.sub(line, s)
    end

    -- Accept both legacy TSV (tabs) and current pipe-separated format.
    if string.find(line, "\t", 1, true) then
      local tag, realm, name, class, lastUpdate, weeklyKey, weeklyDone, raidsBlob =
        string.match(line, "([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]+)\t(.*)")
      if tag == "RT1" and realm and name then
        return tag, realm, name, class, lastUpdate, weeklyKey, weeklyDone, raidsBlob
      end
      return nil
    end

    -- Pipe separated (copy/paste safe). We support empty fields, so we can't use [^|]+.
    if string.find(line, "|", 1, true) then
      -- Fast path: strict pattern match (preserves empties).
      local tag, realm, name, class, lastUpdate, weeklyKey, weeklyDone, raidsBlob =
        string.match(line, "^([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|(.*)$")
      if tag == "RT1" and realm ~= "" and name ~= "" then
        return tag, realm, name, class, lastUpdate, weeklyKey, weeklyDone, raidsBlob
      end

      -- Fallback: manual split preserving empties.
      local parts = {}
      local cur = ""
      for i = 1, #line do
        local ch = string.sub(line, i, i)
        if ch == "|" then
          table.insert(parts, Trim(cur))
          cur = ""
        else
          cur = cur .. ch
        end
      end
      table.insert(parts, Trim(cur))
      if parts[1] == "RT1" and parts[2] and parts[2] ~= "" and parts[3] and parts[3] ~= "" and parts[8] then
        return parts[1], parts[2], parts[3], parts[4] or "UNKNOWN", parts[5] or "0", parts[6] or "", parts[7] or "0", parts[8] or ""
      end
    end
    return nil
  end

  local count = 0
  for line in string.gmatch(text, "[^\r\n]+") do
    local tag, realm, name, class, lastUpdate, weeklyKey, weeklyDone, raidsBlob = ParseLine(line)
    if tag and tag ~= "HDR" then
      MergeChar(Unesc(realm), Unesc(name), Unesc(class), lastUpdate, Unesc(weeklyKey), weeklyDone, raidsBlob)
      count = count + 1
    end
  end

  if count == 0 then
    return false, L.NO_VALID_LINES
  end

  MarkUIRefresh()
  return true, string.format("Importados %d personajes", count)
end

-- =========================
-- Live sync via addon messages
-- =========================

local function SendAllSnapshotsTo(target)
  if not target or target == "" then return false end
  target = tostring(target)
  local db = RT.GetDB()
  if not (db and db.realms) then return false end

  local includeHidden = (db and db.config and db.config.syncHiddenChars) and true or false
  local lines = {}
  for realm, rdata in pairs(db.realms) do
    for name, _ in pairs(rdata.chars or {}) do
      if includeHidden or RT.IsCharShown(realm, name) then
      local c = db.realms and db.realms[realm] and db.realms[realm].chars and db.realms[realm].chars[name]
      if c and c.isLocal then
        local line = ExportCharLine(realm, name)
        if line then
          lines[#lines+1] = line
        end
      end
      end
    end
  end

  if #lines == 0 then return false end

  DebugPrint("REQALL -> sending", #lines, "lines to", target)

  local i = 1
  local function step()
    if i > #lines then
      SafeSend("DONE", "WHISPER", target, true)
      return
    end
    SafeSend("DAT " .. lines[i], "WHISPER", target, true)
    i = i + 1
    SYNC.After(0.15, step)
  end
  step()
  return true
end

local function HandleRTLine(line)
  line = tostring(line or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
  line = line
    :gsub("¦", "|")
    :gsub("∣", "|")
    :gsub("│", "|")
    :gsub("┃", "|")
    :gsub("￨", "|")
    :gsub("︱", "|")
  line = line:gsub("^%s+", ""):gsub("%s+$", "")

  -- Strip optional checksum prefix used by transport encoders (e.g. "929,RT3,...")
  if string.match(line, "^%d+[,|]RT%d") then
    line = string.gsub(line, "^%d+[,|]", "")
  end



  -- Parse formats:
  -- RT3|realm|char|class|lastUpdate|weekId|weeklyDone|weeklyTs|weeklyProg|weeklyQid|weeklyTitle|raidsBlob
  -- RT2|realm|char|class|lastUpdate|weekId|weeklyDone|weeklyTs|raidsBlob
  -- RT1|realm|char|class|lastUpdate|weeklyKey|weeklyDone|raidsBlob (legacy)

  -- Try legacy TSV first (RT1 only)
  local tag, realm, name, class, lastUpdate, a, b, c1, raidsBlob =
    string.match(line, "([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]+)\t([^\t]*)\t?(.*)")

  if not (tag and realm and name) then
    -- Pipe separated (RT2 or RT1)
    tag, realm, name, class, lastUpdate, a, b, c1, raidsBlob =
      string.match(line, "([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]*)|([^|]*)|([^|]*)|(.*)")
  end


  local commaMode = false
  if not (tag and realm and name) then
    -- Comma separated (transport-safe / sniff output)
    commaMode = true
    tag, realm, name, class, lastUpdate, a, b, c1, raidsBlob =
      string.match(line, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]*),([^,]*),([^,]*),(.*)")
  end

  tag = tag and tag:gsub("^%s+",""):gsub("%s+$","")

  if tag == "RT3" and realm and name then
    local weekId = tonumber(a) or 0
    local weeklyDone = b
    local weeklyTs = tonumber(c1) or 0
    local wp, wqid, wtitle, rb
    if commaMode then
      wp, wqid, wtitle, rb = string.match(raidsBlob or "", "^([^,]*),([^,]*),([^,]*),(.*)$")
    else
      wp, wqid, wtitle, rb = string.match(raidsBlob or "", "^([^|]*)|([^|]*)|([^|]*)|(.*)$")
    end
    MergeChar(Unesc(realm), Unesc(name), Unesc(class), lastUpdate, weekId, weeklyDone, weeklyTs, wp, wqid, wtitle, rb)
    return true
  elseif tag == "RT2" and realm and name then
    local weekId = tonumber(a) or 0
    local weeklyDone = b
    local weeklyTs = tonumber(c1) or 0
    MergeChar(Unesc(realm), Unesc(name), Unesc(class), lastUpdate, weekId, weeklyDone, weeklyTs, 0, 0, "", raidsBlob)
    return true
  elseif tag == "RT1" and realm and name then
    local weeklyKey = Unesc(a or "")
    local weeklyDone = b
    -- best-effort: treat lastUpdate as weeklyTs; weekId computed from lastUpdate if possible
    local lu = tonumber(lastUpdate) or 0
    local weekId = (RT.GetWeekId and RT.GetWeekId(lu > 0 and lu or nil)) or 0
    local weeklyTs = lu
    MergeChar(Unesc(realm), Unesc(name), Unesc(class), lastUpdate, weekId, weeklyDone, weeklyTs, raidsBlob)
    return true
  end
  return false
end

function SYNC.SendSnapshot()
  local channel = PickChannel()
  -- Prefer broadcast channels when available, otherwise whisper to online friends/known peers.
  local useWhisper = (not channel)
  local realm = GetRealmName and GetRealmName() or "Unknown"
  local name = UnitName and UnitName("player") or "Unknown"
  local line = ExportCharLine(realm, name)
  local db2 = RT.GetDB and RT.GetDB() or nil
  local includeHidden = (db2 and db2.config and db2.config.syncHiddenChars) and true or false
  if (not includeHidden) and (not RT.IsCharShown(realm, name)) then return false end
  if not line then return false end
  -- One message only (fits under the limit with our small raid set)
  if useWhisper then
    ThrottledWhisper("DAT\t" .. line)
  else
    SafeSend("DAT\t" .. line, channel)
  end
  return true
end

function SYNC.RequestTo(target)
  if not target or target == "" then return false end
  SafeSend("REQ", "WHISPER", target, true)
  return true
end

function SYNC.RequestAllTo(target)
  if not target or target == "" then return false end
  SafeSend("REQALL", "WHISPER", target, true)
  return true
end

function SYNC.RequestSnapshots()
  local channel = PickChannel()
  if channel then
    SafeSend("REQ", channel)
  else
    local db = RT.GetDB and RT.GetDB() or nil
    local autoAll = (db and db.config and db.config.autoReqAll) and true or false
    if autoAll then
      ThrottledWhisper("REQALL")
    else
      ThrottledWhisper("REQ")
    end
  end
  return true
end



-- Handle incoming REQ/REQALL with optional approval for unknown senders.
function SYNC.HandleIncomingREQALL(sender, skipApproval)
  if not sender or sender == "" then return end
  if (not skipApproval) and (not SYNC.MaybeAskApproval(sender, 'REQALL')) then
    return
  end

  SafeSend('ACK ALL', 'WHISPER', sender, true)
  SendAllSnapshotsTo(sender)

  -- Request-back once (prevents one-way sync) with cooldown to avoid loops
  local db = RT.GetDB and RT.GetDB() or nil
  local now = Now()
  local key = NormalizeName(sender)
  local last = SYNC._reqBack[key] or 0
  if (now - last) > REQBACK_COOLDOWN then
    SYNC._reqBack[key] = now
    if db and db.config and db.config.autoReqAll then
      SafeSend('REQALL', 'WHISPER', sender, true)
    else
      SafeSend('REQ', 'WHISPER', sender, true)
    end
  end
end

function SYNC.HandleIncomingREQ(sender, skipApproval)
  if not sender or sender == "" then return end
  if (not skipApproval) and (not SYNC.MaybeAskApproval(sender, 'REQ')) then
    return
  end

  local db = RT.GetDB and RT.GetDB() or nil
  local replyAll = (db and db.config and db.config.replyAllOnREQ ~= false) and true or false
  local includeHidden = (db and db.config and db.config.syncHiddenChars) and true or false

  if replyAll then
    SafeSend('ACK ALL', 'WHISPER', sender, true)
    SendAllSnapshotsTo(sender)
    return
  end

  SafeSend('ACK ONE', 'WHISPER', sender, true)
  local realm = GetRealmName and GetRealmName() or 'Unknown'
  local name = UnitName and UnitName('player') or 'Unknown'
  local line = ExportCharLine(realm, name)
  if (not includeHidden) and (not RT.IsCharShown(realm, name)) then line = nil end
  if line then SafeSend('DAT ' .. line, 'WHISPER', sender, false) end

  -- Request-back once with cooldown
  local now = Now()
  local key = NormalizeName(sender)
  local last = SYNC._reqBack[key] or 0
  if (now - last) > REQBACK_COOLDOWN then
    SYNC._reqBack[key] = now
    SafeSend('REQ', 'WHISPER', sender, true)
  end
end

function SYNC.Init()
  if SYNC._inited then return end
  SYNC._inited = true

  local db = RT.GetDB()
  local auto = (db and db.config and db.config.autoSync) and true or false

  if RegisterAddonMessagePrefix then
    pcall(RegisterAddonMessagePrefix, PREFIX)
  end


  -- Hide RTSYNC chat-whisper payloads from the chat frame unless debug is enabled.
  local ef = CreateFrame("Frame")
  ef:RegisterEvent("CHAT_MSG_ADDON")
  ef:RegisterEvent("FRIENDLIST_UPDATE")

  local didInitial = false
  local function DoInitialSync()
    if didInitial then return end
    didInitial = true
    if not auto then return end
    SYNC.RequestSnapshots()
    SYNC.SendSnapshot()
  end

  ef:SetScript("OnEvent", function(_, event, ...)
  -- Friends list can take a moment to populate after login; trigger a sync when it updates.
  if event == "FRIENDLIST_UPDATE" then
    SYNC.After(0.5, DoInitialSync)
    return
  end

  local channel, sender, msg

  if event == "CHAT_MSG_ADDON" then
    local prefix, m, ch, snd = ...
    if prefix ~= PREFIX then return end
    msg, channel, sender = m, ch, snd
  else
    return
  end

  if not msg then return end

  -- Handle chunked transport payloads: DTB <id>,<part>,<total>,<chunk>
  if type(msg) == 'string' and msg:sub(1,4) == 'DTB ' then
    PruneChunks()
    local rest = msg:sub(5)
    local id, partS, totalS, chunk = string.match(rest, "^([^,]+),(%d+),(%d+),(.+)$")
    if id and partS and totalS and chunk and sender then
      local part = tonumber(partS) or 0
      local total = tonumber(totalS) or 0
      if part >= 1 and total >= 1 and part <= total then
        local key = (NormalizeName(sender) or tostring(sender)) .. '|' .. id
        local buf = SYNC._chunks[key]
        if not buf then
          buf = { total = total, parts = {}, t = Now() }
          SYNC._chunks[key] = buf
        end
        buf.t = Now()
        buf.total = total
        buf.parts[part] = chunk

        local have = 0
        for i = 1, total do
          if buf.parts[i] then have = have + 1 end
        end
        if have == total then
          local body = ""
          for i = 1, total do body = body .. (buf.parts[i] or "") end
          SYNC._chunks[key] = nil
          msg = 'DTA ' .. body
        else
          return
        end
      else
        return
      end
    else
      return
    end
  end

  -- Decode pipe-less transport payloads (Warmane-safe).
  -- DTA format: "DTA <cksum>,<payload-with-|->, and percent-escaped % and ,>"
  if type(msg) == 'string' and msg:sub(1,4) == 'DTA ' then
    local rest = msg:sub(5)
    local ckStr, transport = string.match(rest, "^(%d+),(.*)$")
    if ckStr and transport then
      -- Restore pipes first (transport uses ',' where DAT uses '|')
      local enc = transport:gsub(',', '|')

      -- Verify checksum
      local sum = 0
      for i = 1, #enc do
        sum = (sum + (string.byte(enc, i) or 0)) % 1000
      end
      if sum ~= (tonumber(ckStr) or -1) then
        DebugPrint('drop DTA (bad checksum)', ckStr, sum)
        return
      end

      -- Percent-decode back to original DAT payload
      local payload = enc:gsub('%%2C', ','):gsub('%%25', '%%')
      msg = 'DAT ' .. payload
    else
      -- Backward-compat: old DTA without checksum
      local payload = rest:gsub(',', '|')
      msg = 'DAT ' .. payload
    end
  end
  if sender and sender ~= '' then
    local remember = true
    -- Don't remember unknown whisper requesters until you approve them (prevents accidental future outgoing sync)
    if channel == 'WHISPER' and (msg == 'REQ' or msg == 'REQALL') then
      if (not IsKnownCharacterName(sender)) and (not IsApprovedSender(sender)) then
        remember = false
      end
    end
    if remember then AddPeer(NormalizeName(sender)) end
  end
  DebugPrint('<=', 'ADDON', channel or '?', sender or '?', msg:sub(1, 18))

  -- Basic de-dup to avoid processing the same payload twice (addon+chat fallback).
  SYNC._seen = SYNC._seen or {}
  local sig = (channel or '?') .. '|' .. (sender or '?') .. '|' .. msg
  local now = Now()
  local last = SYNC._seen[sig]
  if last and (now - last) < 2 then return end
  SYNC._seen[sig] = now

  if msg == 'REQALL' then
    if channel == 'GUILD' then return end
    if channel == 'WHISPER' and sender and sender ~= '' then
      SYNC.HandleIncomingREQALL(sender, false)
    end
    return
  end

if msg == 'REQ' then
  if channel == 'GUILD' then return end
  if channel == 'WHISPER' and sender and sender ~= '' then
    SYNC.HandleIncomingREQ(sender, false)
  else
    SYNC.SendSnapshot()
  end
  return
end

  local kind, payload = msg:match('^(%u%u%u)%s+(.+)$')
  if not kind then
    kind = msg
  end

  if kind == 'ACK' then
    DebugPrint('<= ACK', payload or '', 'from', sender or '?')
    return
  end

  if kind == 'DONE' then
    DebugPrint('<= DONE', sender or '?')
    MarkUIRefresh()
    return
  end

  if kind == 'DAT' and payload then
    if HandleRTLine(payload) then
      MarkUIRefresh()
    end
  end

  if kind == 'DTA' and payload then
    local line = payload:gsub(',', '|')
    if HandleRTLine(line) then
      MarkUIRefresh()
    end
  end
end)

  -- Kick initial sync a moment after login so raid info scan has time to populate
  SYNC.After(8.0, function()
    -- Also request friends list, then sync. FRIENDLIST_UPDATE may do it earlier.
    if ShowFriends then pcall(ShowFriends) end
    DoInitialSync()
  end)
end