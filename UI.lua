-- RaidTracker - UI

local ADDON = ...
RaidTracker = RaidTracker or {}
local RT = RaidTracker
RT.UI = RT.UI or {}
local UI = RT.UI
local L = RT.L

UI.configOpen = UI.configOpen or false

-- Default size is now just a fallback. The main frame auto-sizes to the table.
local FRAME_W, FRAME_H = 560, 440
local CELL_H = 22
local LEFT_W = 120
local CELL_W = 64
local HEADER_H = 28
local PAD = 12
local HIDDEN_SCROLLBAR_GAP = 0

local THEME_OUTER_BG = { 0.06, 0.07, 0.10, 0.92 }
local THEME_OUTER_BORDER = { 0.44, 0.44, 0.50, 0.92 }
local THEME_PANEL_BG = { 0.11, 0.12, 0.16, 0.86 }
local THEME_PANEL_BORDER = { 0.46, 0.46, 0.52, 0.85 }
local THEME_HEADER_BG = { 0.09, 0.10, 0.14, 0.95 }
local THEME_HEADER_BORDER = { 0.42, 0.42, 0.48, 0.92 }
local THEME_ROW_BG_A = { 0.11, 0.12, 0.16, 0.94 }
local THEME_ROW_BG_B = { 0.14, 0.15, 0.19, 0.94 }
local THEME_ROW_BORDER = { 0.34, 0.34, 0.40, 0.88 }

local function ApplyThemeBackdrop(frame, bg, border, edgeSize, inset)
  edgeSize = edgeSize or 12
  inset = inset or 3
  frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = edgeSize,
    insets = { left = inset, right = inset, top = inset, bottom = inset }
  })
  bg = bg or THEME_PANEL_BG
  border = border or THEME_PANEL_BORDER
  frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
  if frame.SetBackdropBorderColor then
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
  end
end

local function Clamp(v, mn, mx)
  if v < mn then return mn end
  if v > mx then return mx end
  return v
end

local function SortKeys(t)
  local a = {}
  for k in pairs(t or {}) do table.insert(a, k) end
  table.sort(a)
  return a
end

local function CollectShownChars()
  local db = RT.GetDB()
  local chars = {}
  for realm, rdata in pairs(db.realms or {}) do
    for name, c in pairs(rdata.chars or {}) do
      if RT.IsCharShown(realm, name) then
        table.insert(chars, { realm = realm, name = name, class = c.class or "UNKNOWN" })
      end
    end
  end
  table.sort(chars, function(a,b)
    if a.realm == b.realm then return a.name < b.name end
    return a.realm < b.realm
  end)
  return chars
end

local function CollectEnabledRaids()
  local raids = {}
  for rk, def in pairs(RT.DEFAULT_RAIDS) do
    if RT.IsRaidEnabled(rk) then
      table.insert(raids, { key = rk, def = def })
    end
  end
  table.sort(raids, function(a,b)
    -- Keep weekly at bottom
    if a.key == "WEEKLY" then return false end
    if b.key == "WEEKLY" then return true end
    return a.def.label < b.def.label
  end)
  return raids
end

local function FormatReset(ts)
  if not ts or ts <= 0 then return "" end
  local now = (GetServerTime and GetServerTime()) or time()
  local d = ts - now
  if d <= 0 then return "(reset)" end
  local days = math.floor(d / 86400)
  local hrs = math.floor((d % 86400) / 3600)
  if days > 0 then
    return string.format("%dd %dh", days, hrs)
  end
  local mins = math.floor((d % 3600) / 60)
  return string.format("%dh %dm", hrs, mins)
end

local function ClassColor(class)
  if RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class] then
    local c = RAID_CLASS_COLORS[class]
    return c.r, c.g, c.b
  end
  return 1, 1, 1
end

local function EnsureFrame()
  if UI.frame then return UI.frame end

  local f = CreateFrame("Frame", "RaidTrackerFrame", UIParent)
  f:SetSize(FRAME_W, FRAME_H)
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() f:StartMoving() end)
  f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
  f:SetFrameStrata("DIALOG")

  ApplyThemeBackdrop(f, THEME_OUTER_BG, THEME_OUTER_BORDER, 16, 4)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", PAD, -PAD - 3)
  title:SetText("RaidTracker")
  title:SetTextColor(1.00, 0.82, 0.10)

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)

  -- Config button (compact, next to title)
  local btnCfg = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnCfg:SetSize(108, 22) -- ~40% narrower
  btnCfg:SetPoint("TOPLEFT", title, "TOPRIGHT", 10, 3)
  btnCfg:SetText(L.CONFIG)

  local tableBox = CreateFrame("Frame", nil, f)
  tableBox:SetPoint("TOPLEFT", PAD, -PAD - 28)
  tableBox:SetPoint("BOTTOMRIGHT", -PAD, PAD + 2)
  ApplyThemeBackdrop(tableBox, THEME_PANEL_BG, THEME_PANEL_BORDER, 12, 3)

  -- Scroll area
  local scroll = CreateFrame("ScrollFrame", "RaidTrackerScroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", tableBox, "TOPLEFT", 8, -8)
  scroll:SetPoint("BOTTOMRIGHT", tableBox, "BOTTOMRIGHT", -8 - HIDDEN_SCROLLBAR_GAP, 8)

  -- Hide the visual scroll bar (we keep the scroll frame for future large tables,
  -- but the bar/buttons are noisy when the content fits).
  local sb = _G["RaidTrackerScrollScrollBar"]
  if sb then
    sb:Hide()
    sb.Show = function() end
  end
  local up = _G["RaidTrackerScrollScrollBarScrollUpButton"]
  if up then
    up:Hide()
    up.Show = function() end
  end
  local down = _G["RaidTrackerScrollScrollBarScrollDownButton"]
  if down then
    down:Hide()
    down.Show = function() end
  end

  -- Hide scroll bar by default; we resize the frame to fit content in normal use.
  if scroll.ScrollBar then scroll.ScrollBar:Hide() end
  -- UIPanelScrollFrameTemplate creates global children by name in 3.3.5
  local sb = _G[scroll:GetName() .. "ScrollBar"]
  if sb then sb:Hide() end
  local sbu = _G[scroll:GetName() .. "ScrollBarScrollUpButton"]
  if sbu then sbu:Hide() end
  local sbd = _G[scroll:GetName() .. "ScrollBarScrollDownButton"]
  if sbd then sbd:Hide() end

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1,1)
  scroll:SetScrollChild(content)

  local shade = CreateFrame("Frame", nil, f)
  shade:SetPoint("TOPLEFT", 4, -4)
  shade:SetPoint("BOTTOMRIGHT", -4, 4)
  shade:SetFrameStrata(f:GetFrameStrata())
  shade:SetFrameLevel(f:GetFrameLevel() + 8)
  shade:EnableMouse(true)
  shade:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    tile = true, tileSize = 16,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  })
  shade:SetBackdropColor(0, 0, 0, 0.45)
  shade:Hide()

  f._title = title
  f._scroll = scroll
  f._content = content
  f._tableBox = tableBox
  f._btnCfg = btnCfg
  f._cfgShade = shade

  f:Hide() -- do not auto-open on background refresh/sync
  UI.frame = f

  -- Modal dialog for export/import (small, centered)
  local m = CreateFrame("Frame", "RaidTrackerModal", UIParent)
  m:SetSize(520, 320)
  m:SetPoint("CENTER")
  m:SetFrameStrata("DIALOG")
  m:Hide()
  m:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  m:SetBackdropColor(0,0,0,0.95)

  local mt = m:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  mt:SetPoint("TOPLEFT", PAD, -PAD)
  mt:SetText(L.EXPORT_IMPORT)

  -- Scrollable multi-line editbox (WoW 3.3.5 friendly)
  local scroll2 = CreateFrame("ScrollFrame", "RaidTrackerModalScroll", m, "UIPanelScrollFrameTemplate")
  scroll2:SetPoint("TOPLEFT", PAD, -PAD - 30)
  scroll2:SetPoint("BOTTOMRIGHT", -PAD - 26, PAD + 34)

  -- In 3.3.5, the scrollframe expects its scroll child to be a named, sizeable widget.
  -- Use an EditBox directly as the scroll child (classic pattern) so it actually displays multi-line text.
  local eb = CreateFrame("EditBox", "RaidTrackerModalEditBox", scroll2)
  eb:SetMultiLine(true)
  eb:SetAutoFocus(false)
  eb:SetFontObject("ChatFontNormal")
  eb:SetWidth(470)
  eb:SetTextInsets(6, 6, 6, 6)
  eb:SetScript("OnEscapePressed", function() m:Hide() end)
  eb:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  eb:SetBackdropColor(0,0,0,0.55)

  scroll2:SetScrollChild(eb)

  local function ResizeToText(self)
    local lines = (self.GetNumLines and self:GetNumLines()) or 1
    local h = math.max(220, lines * 14 + 20)
    self:SetHeight(h)
  end

  eb:SetScript("OnTextChanged", function(self)
    ResizeToText(self)
    if self._rtSelectAll then
      self:HighlightText()
      self:SetFocus()
      self._rtSelectAll = nil
    end
  end)

  local ok = CreateFrame("Button", nil, m, "UIPanelButtonTemplate")
  ok:SetSize(120, 22)
  ok:SetPoint("BOTTOMRIGHT", -PAD, PAD)
  ok:SetText(L.CLOSE)
  ok:SetScript("OnClick", function() m:Hide() end)

  local act = CreateFrame("Button", nil, m, "UIPanelButtonTemplate")
  act:SetSize(120, 22)
  act:SetPoint("RIGHT", ok, "LEFT", -8, 0)
  act:SetText(L.IMPORT)

  m._title = mt
  m._edit = eb
  m._action = act
  UI.modal = m

  -- Button behaviors
  btnCfg:SetScript("OnClick", function() if UI and UI.ToggleConfigPanel then UI.ToggleConfigPanel() end end)
  f:Hide()
  return f
end


function UI.SetConfigPanelShown(show)
  local f = EnsureFrame()
  if not f then return end

  show = show and true or false
  UI.configOpen = show

  if show then
    if RT and RT.Config and RT.Config.AttachTo then
      f._cfg = RT.Config.AttachTo(f)
      if f._cfg then
        f._cfg:Show()
        if RT.Config.Refresh then RT.Config.Refresh() end
      end
    end
    if f._cfgShade then f._cfgShade:Show() end
    if f._btnCfg then f._btnCfg:Disable() end
  else
    if f._cfg then f._cfg:Hide() end
    if f._cfgShade then f._cfgShade:Hide() end
    if f._btnCfg then f._btnCfg:Enable() end
  end

  UI.Refresh(true)
end

function UI.ToggleConfigPanel()
  UI.SetConfigPanelShown(not UI.configOpen)
end



-- Tools window (buttons + channel toggles)
local function EnsureToolsFrame()
  if UI.toolsFrame then return UI.toolsFrame end

  local f = CreateFrame("Frame", "RaidTrackerToolsFrame", UIParent)
  f:SetSize(320, 310)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() f:StartMoving() end)
  f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

  f:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  f:SetBackdropColor(0,0,0,0.90)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", PAD, -PAD)
  title:SetText(L.TOOLS_TITLE)

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)

  -- Buttons grid (2x2)
  local b1 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  b1:SetSize(140, 24)
  b1:SetPoint("TOPLEFT", PAD, -PAD - 34)
  b1:SetText(L.EXPORT)

  local b2 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  b2:SetSize(140, 24)
  b2:SetPoint("TOPLEFT", b1, "TOPRIGHT", 10, 0)
  b2:SetText(L.IMPORT)

  local b3 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  b3:SetSize(140, 24)
  b3:SetPoint("TOPLEFT", b1, "BOTTOMLEFT", 0, -8)
  b3:SetText(L.RESCAN)

  local b4 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  b4:SetSize(140, 24)
  b4:SetPoint("TOPLEFT", b2, "BOTTOMLEFT", 0, -8)
  b4:SetText(L.RESET)

  local function EnsureModal()
    if UI and UI.modal then return UI.modal end
    return nil
  end

  b1:SetScript("OnClick", function()
    local m = EnsureModal()
    if not m then return end
    local txt = RT.ExportData({ onlyShown = true })
    m._title:SetText(L.EXPORT)
    m._edit:SetText(txt or "")
    m._edit:SetCursorPosition(0)
    m._action:Hide()
    m:Show()
  end)

  b2:SetScript("OnClick", function()
    local m = EnsureModal()
    if not m then return end
    m._title:SetText(L.IMPORT)
    m._edit:SetText("")
    m._edit._rtSelectAll = true
    m._action:SetText(L.IMPORT)
    m._action:Show()
    m._action:SetScript("OnClick", function()
      local ok, err = RT.ImportData(m._edit:GetText() or "")
      if ok then
        UI.Print(L.IMPORT_OK)
        if RT.Refresh then RT.Refresh() end
      else
        UI.Print(string.format(L.IMPORT_ERROR_FMT, tostring(err or "?")))
      end
    end)
    m:Show()
  end)

  b3:SetScript("OnClick", function()
    if RT and RT.RequestScan then RT.RequestScan() end
  end)

  b4:SetScript("OnClick", function()
    if RT and RT.ForceResetAll then RT.ForceResetAll() end
  end)

  -- Channel toggles
  local syncUseAddon = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  syncUseAddon:SetPoint("TOPLEFT", b3, "BOTTOMLEFT", 0, -14)
  syncUseAddon.text = syncUseAddon:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  syncUseAddon.text:SetPoint("LEFT", syncUseAddon, "RIGHT", 4, 0)
  syncUseAddon.text:SetText(L.API_CHANNEL)

  local syncUseWhisper = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  syncUseWhisper:SetPoint("TOPLEFT", syncUseAddon, "BOTTOMLEFT", 0, -6)
  syncUseWhisper.text = syncUseWhisper:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  syncUseWhisper.text:SetPoint("LEFT", syncUseWhisper, "RIGHT", 4, 0)
  syncUseWhisper.text:SetText(L.WHISPER_CHANNEL)


  -- AddonMessage sniffer (debug)
  local sniffOnlyRT = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  sniffOnlyRT:SetPoint("TOPLEFT", syncUseWhisper, "BOTTOMLEFT", 0, -10)
  sniffOnlyRT.text = sniffOnlyRT:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sniffOnlyRT.text:SetPoint("LEFT", sniffOnlyRT, "RIGHT", 4, 0)
  sniffOnlyRT.text:SetText(L.SNIFFER_ONLY)

  local btnSniff = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnSniff:SetSize(140, 22)
  btnSniff:SetPoint("TOPLEFT", sniffOnlyRT, "BOTTOMLEFT", 0, -6)
  btnSniff:SetText(L.SNIFFER_OFF)

  local function SniffMsg(prefix, msg, channel, sender)
    local p = tostring(prefix or "")
    local m = tostring(msg or "")
    local c = tostring(channel or "")
    local s = tostring(sender or "")
    local len = (msg and #msg) or 0
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff66ccffADDONMSG|r %s %s %s len=%d msg=[%s]", p, c, s, len, m))
    end
  end

  local function SnifferEnable()
    if not UI._sniffFrame then
      UI._sniffFrame = CreateFrame("Frame")
    end
    UI._sniffFrame:UnregisterAllEvents()
    UI._sniffFrame:RegisterEvent("CHAT_MSG_ADDON")
    UI._sniffFrame:SetScript("OnEvent", function(_, _, prefix, msg, channel, sender)
      if sniffOnlyRT:GetChecked() then
        if tostring(prefix or "") ~= "RTSYNC" then return end
      end
      SniffMsg(prefix, msg, channel, sender)
    end)
    UI._sniffOn = true
  end

  local function SnifferDisable()
    if UI._sniffFrame then
      UI._sniffFrame:UnregisterEvent("CHAT_MSG_ADDON")
      UI._sniffFrame:SetScript("OnEvent", nil)
    end
    UI._sniffOn = false
  end

  local function RefreshSnifferBtn()
    if UI._sniffOn then
      btnSniff:SetText(L.SNIFFER_ON)
    else
      btnSniff:SetText(L.SNIFFER_OFF)
    end
  end

  btnSniff:SetScript("OnClick", function()
    if UI._sniffOn then
      SnifferDisable()
      UI.Print(L.SNIFFER_OFF)
    else
      SnifferEnable()
      UI.Print(L.SNIFFER_ON)
    end
    RefreshSnifferBtn()
  end)


  -- Quest sniffer toggle (debug weekly)
  local btnQSniff = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  btnQSniff:SetSize(140, 22)
  btnQSniff:SetPoint("TOPLEFT", btnSniff, "BOTTOMLEFT", 0, -6)
  btnQSniff:SetText(L.QUESTSNIFF_OFF)

  local function RefreshQSniffBtn()
    if RT and RT._qsOn then
      btnQSniff:SetText(L.QUESTSNIFF_ON)
    else
      btnQSniff:SetText(L.QUESTSNIFF_OFF)
    end
  end

  btnQSniff:SetScript("OnClick", function()
    if RT and RT.ToggleQuestSniff then RT.ToggleQuestSniff() end
    RefreshQSniffBtn()
  end)



  local function RefreshChecks()
    local db = RT.GetDB()
    syncUseAddon:SetChecked(db.config.syncUseAddon and true or false)
    syncUseWhisper:SetChecked(db.config.syncUseWhisper == true)
  end

  syncUseAddon:SetScript("OnClick", function(self)
    local db = RT.GetDB()
    db.config.syncUseAddon = self:GetChecked() and true or false
    if (not db.config.syncUseAddon) and (db.config.syncUseWhisper == false) then
      db.config.syncUseWhisper = true
      syncUseWhisper:SetChecked(true)
    end
    db.config.chatFallbackWhisper = (db.config.syncUseWhisper ~= false)
    db.config.whisperOnlySync = (db.config.syncUseWhisper ~= false)
  end)

  sniffOnlyRT:SetScript("OnClick", function(self)
    local db = RT.GetDB()
    db.config.sniffOnlyRT = self:GetChecked() and true or false
  end)

  syncUseWhisper:SetScript("OnClick", function(self)
    local db = RT.GetDB()
    db.config.syncUseWhisper = self:GetChecked() and true or false
    if (db.config.syncUseWhisper == false) and (not db.config.syncUseAddon) then
      db.config.syncUseWhisper = true
    end
    db.config.chatFallbackWhisper = (db.config.syncUseWhisper ~= false)
    db.config.whisperOnlySync = (db.config.syncUseWhisper ~= false)
    RefreshChecks()
  end)

  f:SetScript("OnShow", RefreshChecks)
  UI.toolsFrame = f
  f:Hide()
  return f
end

function UI.ToggleTools()
  local f = EnsureToolsFrame()
  if f:IsShown() then f:Hide() else f:Show() end
end


local function Clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

function UI.Print(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00RaidTracker:|r " .. tostring(msg))
  end
end

-- Grid rendering
local function ClearChildren(frame)
  local kids = { frame:GetChildren() }
  for _, child in ipairs(kids) do
    child:Hide()
    child:SetParent(nil)
  end
end

local function MakeCell(parent, x, y, w, h)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  b:SetPoint("TOPLEFT", x, -y)
  ApplyThemeBackdrop(b, THEME_ROW_BG_A, THEME_ROW_BORDER, 10, 2)
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetPoint("CENTER", 0, 0)
  b.text:SetText("")
  return b
end

function UI.Refresh(force)
  -- If the frame was never opened, don't create it just to refresh.
  local f = UI.frame
  if not f then
    UI._dirty = true
    return
  end

  if (not f:IsShown()) and (not force) then
    UI._dirty = true
    return
  end

  UI._dirty = false

  local content = f._content
  ClearChildren(content)

  local db = RT.GetDB()
  local chars = CollectShownChars()
  local raids = CollectEnabledRaids()


  -- Header: raid names (top)
  local y = 0
  local headerBg = CreateFrame("Frame", nil, content)
  headerBg:SetPoint("TOPLEFT", 0, 0)
  headerBg:SetSize(LEFT_W + (#raids * CELL_W), HEADER_H)

  local headerCells = {}
  local leftCells = {}

  local hLeft = MakeCell(content, 0, 0, LEFT_W, HEADER_H)
  hLeft.text:SetText(L.CHARACTER)
  hLeft:SetBackdropColor(THEME_HEADER_BG[1], THEME_HEADER_BG[2], THEME_HEADER_BG[3], THEME_HEADER_BG[4])
  hLeft:SetBackdropBorderColor(THEME_HEADER_BORDER[1], THEME_HEADER_BORDER[2], THEME_HEADER_BORDER[3], THEME_HEADER_BORDER[4])

  for ri, r in ipairs(raids) do
    local x = LEFT_W + (ri-1) * CELL_W
    local cell = MakeCell(content, x, 0, CELL_W, HEADER_H)
    cell:SetBackdropColor(THEME_HEADER_BG[1], THEME_HEADER_BG[2], THEME_HEADER_BG[3], THEME_HEADER_BG[4])
    cell:SetBackdropBorderColor(THEME_HEADER_BORDER[1], THEME_HEADER_BORDER[2], THEME_HEADER_BORDER[3], THEME_HEADER_BORDER[4])
    cell.text:SetText(r.def.label)
    headerCells[ri] = cell
  end

  y = HEADER_H

  local function SetHi(ci, ri, on)
    local hc = headerCells[ri]
    local lc = leftCells[ci]
    if hc then
      if on then
        hc:SetBackdropColor(0.24, 0.21, 0.10, 0.96)
        hc:SetBackdropBorderColor(0.62, 0.52, 0.18, 0.96)
      else
        hc:SetBackdropColor(THEME_HEADER_BG[1], THEME_HEADER_BG[2], THEME_HEADER_BG[3], THEME_HEADER_BG[4])
        hc:SetBackdropBorderColor(THEME_HEADER_BORDER[1], THEME_HEADER_BORDER[2], THEME_HEADER_BORDER[3], THEME_HEADER_BORDER[4])
      end
    end
    if lc then
      local base = lc._rtBaseBg or THEME_ROW_BG_A
      if on then
        lc:SetBackdropColor(0.22, 0.19, 0.10, 0.95)
        lc:SetBackdropBorderColor(0.58, 0.48, 0.18, 0.94)
      else
        lc:SetBackdropColor(base[1], base[2], base[3], base[4])
        lc:SetBackdropBorderColor(THEME_ROW_BORDER[1], THEME_ROW_BORDER[2], THEME_ROW_BORDER[3], THEME_ROW_BORDER[4])
      end
    end
  end

  -- Rows: characters
  for ci, c in ipairs(chars) do
    local rowBg = (math.fmod(ci, 2) == 0) and THEME_ROW_BG_B or THEME_ROW_BG_A

    local left = MakeCell(content, 0, y, LEFT_W, CELL_H)
    left:SetBackdropColor(rowBg[1], rowBg[2], rowBg[3], rowBg[4])
    left:SetBackdropBorderColor(THEME_ROW_BORDER[1], THEME_ROW_BORDER[2], THEME_ROW_BORDER[3], THEME_ROW_BORDER[4])
    left._rtBaseBg = rowBg
    local r,g,b = ClassColor(c.class)
    left.text:SetText(c.name)
    left.text:SetTextColor(r,g,b)
    leftCells[ci] = left

    for ri, r in ipairs(raids) do
      local rk = r.key
      local x = LEFT_W + (ri-1) * CELL_W
      local cell = MakeCell(content, x, y, CELL_W, CELL_H)
      cell:SetBackdropColor(rowBg[1], rowBg[2], rowBg[3], rowBg[4])
      cell:SetBackdropBorderColor(THEME_ROW_BORDER[1], THEME_ROW_BORDER[2], THEME_ROW_BORDER[3], THEME_ROW_BORDER[4])

      local ch = (db.realms[c.realm] and db.realms[c.realm].chars and db.realms[c.realm].chars[c.name])
      if rk == "WEEKLY" then
        local w = RT.GetWeeklyState(c.realm, c.name)
        if w and w.done then
          cell:SetBackdropColor(0.10, 0.36, 0.12, 0.96)
          cell:SetBackdropBorderColor(0.22, 0.55, 0.25, 0.96)
          cell.text:SetText("OK")
        elseif w and w.ready then
          cell:SetBackdropColor(0.46, 0.34, 0.07, 0.96)
          cell:SetBackdropBorderColor(0.66, 0.52, 0.16, 0.96)
          cell.text:SetText("!")
        elseif w and w.inProgress then
          cell:SetBackdropColor(0.50, 0.24, 0.07, 0.96)
          cell:SetBackdropBorderColor(0.70, 0.36, 0.14, 0.96)
          cell.text:SetText("...")
        else
          cell:SetBackdropColor(rowBg[1], rowBg[2], rowBg[3], rowBg[4])
          cell:SetBackdropBorderColor(THEME_ROW_BORDER[1], THEME_ROW_BORDER[2], THEME_ROW_BORDER[3], THEME_ROW_BORDER[4])
          cell.text:SetText("")
        end
        -- Weekly is auto-tracked (no manual toggle)
        cell:SetScript("OnClick", nil)
        cell:SetScript("OnEnter", function()
          SetHi(ci, ri, true)
          GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
          GameTooltip:AddLine(L.WEEKLY)
          if w and w.questTitle then GameTooltip:AddLine(w.questTitle, 1,1,0) end
          if w and w.done then
            GameTooltip:AddLine(L.DONE, 0.3,1,0.3)
          elseif w and w.ready then
            GameTooltip:AddLine(L.READY_TO_TURN_IN, 1,0.9,0.2)
          elseif w and w.inProgress then
            GameTooltip:AddLine(L.IN_PROGRESS, 1,0.6,0.1)
          else
            GameTooltip:AddLine(L.PENDING, 0.8,0.8,0.8)
          end
          GameTooltip:Show()
        end)
        cell:SetScript("OnLeave", function() GameTooltip:Hide(); SetHi(ci, ri, false) end)
      else
        local def = r.def
        local rd = ch and ch.raids and ch.raids[rk]
        local locked = rd and rd.locked
        if locked then
          cell:SetBackdropColor(0.10, 0.36, 0.12, 0.96)
          cell:SetBackdropBorderColor(0.22, 0.55, 0.25, 0.96)
          cell.text:SetText("OK")
        else
          cell:SetBackdropColor(rowBg[1], rowBg[2], rowBg[3], rowBg[4])
          cell:SetBackdropBorderColor(THEME_ROW_BORDER[1], THEME_ROW_BORDER[2], THEME_ROW_BORDER[3], THEME_ROW_BORDER[4])
          cell.text:SetText("")
        end

        cell:SetScript("OnEnter", function()
          SetHi(ci, ri, true)
          GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
          GameTooltip:AddLine(def.label)
          if locked then
            GameTooltip:AddLine(L.LOCKED, 0.3,1,0.3)
          else
            GameTooltip:AddLine(L.NOT_LOCKED, 1,0.3,0.3)
          end
          if rd and rd.reset and rd.reset > 0 then
            GameTooltip:AddLine(string.format(L.RESET_AT_FMT, FormatReset(rd.reset)), 0.8,0.8,0.8)
          end
          if ch and ch.lastUpdate then
            GameTooltip:AddLine(string.format(L.UPDATED_AT_FMT, date("%d/%m %H:%M", ch.lastUpdate)), 0.8,0.8,0.8)
          end
          GameTooltip:Show()
        end)
        cell:SetScript("OnLeave", function() GameTooltip:Hide(); SetHi(ci, ri, false) end)
      end
    end

    y = y + CELL_H
  end
  -- Content size for scrolling
  local totalW = LEFT_W + (#raids * CELL_W) + 6
  local totalH = y + 14
  content:SetSize(totalW, totalH)

  -- Let the scroll frame update its child rect (prevents "stale" view on some clients)
  if f._scroll and f._scroll.UpdateScrollChildRect then
    pcall(function() f._scroll:UpdateScrollChildRect() end)
  end

  -- Auto-size the main frame to the current table.
  do
    if f._tableBox then
      f._tableBox:ClearAllPoints()
      f._tableBox:SetPoint("TOPLEFT", PAD, -PAD - 28)
      f._tableBox:SetPoint("BOTTOMRIGHT", -PAD, PAD + 2)
    end
    if f._scroll and f._tableBox then
      f._scroll:ClearAllPoints()
      f._scroll:SetPoint("TOPLEFT", f._tableBox, "TOPLEFT", 8, -8)
      f._scroll:SetPoint("BOTTOMRIGHT", f._tableBox, "BOTTOMRIGHT", -8 - HIDDEN_SCROLLBAR_GAP, 8)
    end

    local baseW = totalW + (PAD * 2) + HIDDEN_SCROLLBAR_GAP + 12
    local topInset = PAD + 28
    local bottomInset = PAD + 2
    local baseH = totalH + topInset + bottomInset + 4

    local w = Clamp(baseW, 420, 1400)
    local h = Clamp(baseH, 150, 900)
    f:SetSize(w, h)

    if UI.configOpen and f._cfg and RT and RT.Config and RT.Config.AttachTo then
      RT.Config.AttachTo(f)
    end
    if f._cfgShade then
      if UI.configOpen then f._cfgShade:Show() else f._cfgShade:Hide() end
    end
  end
end

function UI.Toggle()
  local f = EnsureFrame()
  if f:IsShown() then
    if UI.configOpen then
      UI.configOpen = false
      if f._cfg then f._cfg:Hide() end
      if f._cfgShade then f._cfgShade:Hide() end
      if f._btnCfg then f._btnCfg:Enable() end
    end
    f:Hide()
    if UI.modal then UI.modal:Hide() end
  else
    f:Show()
    if RT and RT.ResetExpiredRaids then RT.ResetExpiredRaids() end
    if RT and RT.RequestScan then RT.RequestScan() end
    if RT and RT.UpdateWeeklyAuto then RT.UpdateWeeklyAuto() end
    UI.Refresh(true)
    -- On open: request sync from all known characters (except self)
    if RT.Sync and RT.Sync.RequestAllTo then
      local db = RT.GetDB and RT.GetDB() or nil
      local realmMe = (GetRealmName and GetRealmName()) or 'Unknown'
      local nameMe = (UnitName and UnitName('player')) or 'Unknown'
      if db and db.realms then
        for realm, rdata in pairs(db.realms) do
          if rdata and rdata.chars then
            for name, ch in pairs(rdata.chars) do
              if not (realm == realmMe and name == nameMe) then
                RT.Sync.RequestAllTo(name)
              end
            end
          end
        end
      end
    end
  end
end

function RT.UI.ShowTextPopup(titleText, bodyText)
  EnsureFrame()
  local m = UI.modal
  m._title:SetText(titleText or L.TEXT)
  m._edit:SetText(tostring(bodyText or ""))
  m._action:Hide()
  m:Show()
  m._edit:HighlightText()
  m._edit:SetFocus()
end