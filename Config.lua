-- RaidTracker - Config UI

local ADDON = ...
RaidTracker = RaidTracker or {}
local RT = RaidTracker
RT.UI = RT.UI or {}
local UI = RT.UI
RT.Config = RT.Config or {}
local Cfg = RT.Config
local L = RT.L

local PAD = 12
local SECTION_GAP = 10
local SECTION_INSET_X = 10
local SECTION_INSET_Y = 10
local SECTION_TITLE_Y = 12
local ROW_H = 24

-- Config window sizing (shown in front of the main frame)
Cfg.EMBED_W = 560
Cfg.MIN_H = 438

local function CollectCharsAll()
  local db = RT.GetDB()
  local chars = {}
  for realm, rdata in pairs(db.realms or {}) do
    for name, c in pairs(rdata.chars or {}) do
      table.insert(chars, { realm = realm, name = name, class = c.class or "UNKNOWN" })
    end
  end
  table.sort(chars, function(a,b)
    if a.realm == b.realm then return a.name < b.name end
    return a.realm < b.realm
  end)
  return chars
end

local function CollectRaidsAll()
  local raids = {}
  for rk, def in pairs(RT.DEFAULT_RAIDS) do
    table.insert(raids, { key = rk, label = def.label })
  end
  table.sort(raids, function(a,b)
    if a.key == "WEEKLY" then return false end
    if b.key == "WEEKLY" then return true end
    return a.label < b.label
  end)
  return raids
end

local function ClearChildren(frame)
  local kids = { frame:GetChildren() }
  for _, child in ipairs(kids) do
    child:Hide()
    child:SetParent(nil)
  end
end

local function ClassColor(class)
  if RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class] then
    local c = RAID_CLASS_COLORS[class]
    return c.r, c.g, c.b
  end
  return 1, 1, 1
end

local function ApplyBackdrop(frame, bgR, bgG, bgB, bgA, bdR, bdG, bdB, bdA, edgeSize, inset)
  inset = inset or 3
  frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = edgeSize or 12,
    insets = { left = inset, right = inset, top = inset, bottom = inset }
  })
  frame:SetBackdropColor(bgR or 0, bgG or 0, bgB or 0, bgA or 0.75)
  frame:SetBackdropBorderColor(bdR or 0.38, bdG or 0.38, bdB or 0.44, bdA or 0.9)
end

local function AddSectionTitle(parent, text)
  local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", parent, "TOP", 0, -SECTION_TITLE_Y)
  title:SetText(text)
  title:SetTextColor(1.00, 0.82, 0.10)

  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  line:SetVertexColor(0.72, 0.72, 0.78, 0.20)
  line:SetPoint("TOPLEFT", parent, "TOPLEFT", SECTION_INSET_X, -34)
  line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -SECTION_INSET_X, -34)
  line:SetHeight(1)

  return title, line
end

local function CreateSection(parent, titleText, x, y, w, h)
  local box = CreateFrame("Frame", nil, parent)
  box:SetPoint("TOPLEFT", x, y)
  box:SetSize(w, h)
  ApplyBackdrop(box, 0.11, 0.12, 0.16, 0.82, 0.46, 0.46, 0.52, 0.85, 12, 3)

  local title, line = AddSectionTitle(box, titleText)

  local body = CreateFrame("Frame", nil, box)
  body:SetPoint("TOPLEFT", SECTION_INSET_X, -40)
  body:SetPoint("BOTTOMRIGHT", -SECTION_INSET_X, SECTION_INSET_Y)

  box._title = title
  box._line = line
  box._body = body
  return box
end

local function CreatePlainScroll(parent)
  local scroll = CreateFrame("ScrollFrame", nil, parent)
  scroll:SetAllPoints(parent)
  scroll:EnableMouseWheel(true)

  local child = CreateFrame("Frame", nil, scroll)
  child:SetWidth(parent:GetWidth())
  child:SetHeight(1)
  scroll:SetScrollChild(child)

  scroll:SetScript("OnMouseWheel", function(self, delta)
    local viewH = parent:GetHeight()
    local childH = child:GetHeight() or 0
    local maxScroll = math.max(0, childH - viewH)
    local nextScroll = (self:GetVerticalScroll() or 0) - (delta * (ROW_H * 2))
    if nextScroll < 0 then nextScroll = 0 end
    if nextScroll > maxScroll then nextScroll = maxScroll end
    self:SetVerticalScroll(nextScroll)
  end)

  scroll._rtChild = child
  return scroll, child
end

local function ClampScroll(scroll, viewH)
  if not scroll or not scroll._rtChild then return end
  local childH = scroll._rtChild:GetHeight() or 0
  local maxScroll = math.max(0, childH - viewH)
  if (scroll:GetVerticalScroll() or 0) > maxScroll then
    scroll:SetVerticalScroll(maxScroll)
  end
end

local function CreateStripeRow(parent, y, w, index)
  local row = CreateFrame("Button", nil, parent)
  row:SetPoint("TOPLEFT", 0, -y)
  row:SetSize(w, ROW_H)

  local bg = row:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  if math.fmod(index, 2) == 0 then
    bg:SetVertexColor(1, 1, 1, 0.09)
  else
    bg:SetVertexColor(1, 1, 1, 0.04)
  end
  bg:SetAllPoints(row)
  row._bg = bg

  local hover = row:CreateTexture(nil, "HIGHLIGHT")
  hover:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  hover:SetVertexColor(1, 1, 1, 0.06)
  hover:SetAllPoints(row)

  local bottomLine = row:CreateTexture(nil, "BORDER")
  bottomLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  bottomLine:SetVertexColor(0.92, 0.92, 0.96, 0.06)
  bottomLine:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
  bottomLine:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
  bottomLine:SetHeight(1)

  return row
end

local function CreateRowText(parent, template, x, width)
  local txt = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
  txt:SetPoint("LEFT", parent, "LEFT", x or 0, 0)
  if width then txt:SetWidth(width) end
  txt:SetJustifyH("LEFT")
  return txt
end

local function EnsureFrame()
  if Cfg.frame then return Cfg.frame end

  local f = CreateFrame("Frame", "RaidTrackerConfigFrame", UIParent)
  f:SetSize(Cfg.EMBED_W, Cfg.MIN_H)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  ApplyBackdrop(f, 0.06, 0.07, 0.10, 0.92, 0.44, 0.44, 0.50, 0.92, 16, 4)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", PAD, -PAD)
  title:SetText(L.CONFIG)
  title:SetTextColor(1.00, 0.82, 0.10)

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  f._closeBtn = close
  close:SetPoint("TOPRIGHT", 2, 2)

  local dragArea = CreateFrame("Frame", nil, f)
  dragArea:SetPoint("TOPLEFT", 8, -6)
  dragArea:SetPoint("TOPRIGHT", -30, -6)
  dragArea:SetHeight(24)
  dragArea:EnableMouse(true)
  dragArea:RegisterForDrag("LeftButton")
  dragArea:SetScript("OnDragStart", function(self)
    local target = self._rtDragTarget or f
    if target and target.StartMoving then target:StartMoving() end
  end)
  dragArea:SetScript("OnDragStop", function(self)
    local target = self._rtDragTarget or f
    if target and target.StopMovingOrSizing then target:StopMovingOrSizing() end
  end)
  f._dragArea = dragArea
  f:SetScript("OnDragStart", function() f:StartMoving() end)
  f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
  f:RegisterForDrag("LeftButton")

  close:SetScript("OnClick", function()
    if RT and RT.UI and RT.UI.SetConfigPanelShown then
      RT.UI.SetConfigPanelShown(false)
    else
      f:Hide()
    end
  end)

  local contentTop = -PAD - 32
  local innerW = Cfg.EMBED_W - (PAD * 2)
  local sectionW = math.floor((innerW - (SECTION_GAP * 2)) / 3)
  local sectionH = 292
  local leftX = PAD
  local midX = leftX + sectionW + SECTION_GAP
  local rightX = midX + sectionW + SECTION_GAP

  local wlSection = CreateSection(f, L.WHITELIST, leftX, contentTop, sectionW, sectionH)
  local blSection = CreateSection(f, L.BLACKLIST, midX, contentTop, sectionW, sectionH)
  local raidsSection = CreateSection(f, L.RAIDS, rightX, contentTop, sectionW, sectionH)

  local wlScroll, wlChild = CreatePlainScroll(wlSection._body)
  local blScroll, blChild = CreatePlainScroll(blSection._body)
  local raidsPane = CreateFrame("Frame", nil, raidsSection._body)
  raidsPane:SetAllPoints(raidsSection._body)

  local manualBox = CreateFrame("Frame", nil, f)
  manualBox:SetPoint("TOPLEFT", PAD, contentTop - sectionH - 12)
  manualBox:SetPoint("TOPRIGHT", -PAD, contentTop - sectionH - 12)
  manualBox:SetHeight(86)
  ApplyBackdrop(manualBox, 0.11, 0.12, 0.16, 0.82, 0.46, 0.46, 0.52, 0.85, 12, 3)
  manualBox._title = AddSectionTitle(manualBox, L.ADD_CHARACTER)

  local manualBar = CreateFrame("Frame", nil, manualBox)
  manualBar:SetPoint("TOPLEFT", 14, -44)
  manualBar:SetPoint("TOPRIGHT", -14, -44)
  manualBar:SetHeight(24)

  local btnW = 88
  local gap = 8
  local editW = Cfg.EMBED_W - (PAD * 2) - 28 - btnW - gap - btnW - gap

  local manualEditWrap = CreateFrame("Frame", nil, manualBar)
  manualEditWrap:SetPoint("LEFT", manualBar, "LEFT", 0, 0)
  manualEditWrap:SetSize(editW, 24)
  ApplyBackdrop(manualEditWrap, 0.03, 0.03, 0.05, 0.72, 0.33, 0.33, 0.39, 0.90, 10, 3)

  local manualEdit = CreateFrame("EditBox", nil, manualEditWrap, "InputBoxTemplate")
  manualEdit:SetPoint("TOPLEFT", manualEditWrap, "TOPLEFT", 6, -4)
  manualEdit:SetPoint("BOTTOMRIGHT", manualEditWrap, "BOTTOMRIGHT", -6, 4)
  manualEdit:SetAutoFocus(false)
  manualEdit:SetText("")
  manualEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  manualEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

  local btnAdd = CreateFrame("Button", nil, manualBar, "UIPanelButtonTemplate")
  btnAdd:SetSize(btnW, 24)
  btnAdd:SetPoint("LEFT", manualEditWrap, "RIGHT", gap, 0)
  btnAdd:SetText(L.ADD)

  local btnBlock = CreateFrame("Button", nil, manualBar, "UIPanelButtonTemplate")
  btnBlock:SetSize(btnW, 24)
  btnBlock:SetPoint("LEFT", btnAdd, "RIGHT", gap, 0)
  btnBlock:SetText(L.BLOCK)

  f._wlSection = wlSection
  f._blSection = blSection
  f._raidsSection = raidsSection
  f._wlScroll = wlScroll
  f._wlChild = wlChild
  f._blScroll = blScroll
  f._blChild = blChild
  f._raidsPane = raidsPane
  f._manualEdit = manualEdit
  if f._dragArea then
    f._dragArea._rtDragTarget = f
  end

  Cfg.frame = f
  f:Hide()

  function Cfg.Refresh()
    local db = RT.GetDB()
    if db and db.config then
      db.config.syncBlacklist = db.config.syncBlacklist or {}
      db.config.approvedSyncSenders = db.config.approvedSyncSenders or {}
    end

    ClearChildren(wlChild)
    ClearChildren(blChild)
    ClearChildren(raidsPane)

    local chars = CollectCharsAll()
    local realmsSeen = {}
    for _, c in ipairs(chars) do realmsSeen[c.realm] = true end
    local realmCount = 0
    for _ in pairs(realmsSeen) do realmCount = realmCount + 1 end

    local viewW = wlSection._body:GetWidth()
    local viewH = wlSection._body:GetHeight()
    local y = 0
    for idx, c in ipairs(chars) do
      local row = CreateStripeRow(wlChild, y, viewW, idx)

      local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
      cb:SetPoint("LEFT", row, "LEFT", 0, 0)
      cb:SetChecked(RT.IsCharShown(c.realm, c.name))

      local txtW = viewW - 58
      local txt = CreateRowText(row, "GameFontHighlightSmall", 26, txtW)
      local r, g, b = ClassColor(c.class)
      txt:SetTextColor(r, g, b)
      if realmCount > 1 then
        txt:SetText(string.format("%s (%s)", c.name, c.realm))
      else
        txt:SetText(c.name)
      end

      cb.text = txt
      cb:SetScript("OnClick", function(self)
        RT.SetCharShown(c.realm, c.name, self:GetChecked())
        if RT.UI and RT.UI.Refresh then RT.UI.Refresh() end
      end)

      row:SetScript("OnClick", function()
        cb:SetChecked(not cb:GetChecked())
        RT.SetCharShown(c.realm, c.name, cb:GetChecked())
        if RT.UI and RT.UI.Refresh then RT.UI.Refresh() end
      end)

      local del = CreateFrame("Button", nil, row, "UIPanelCloseButton")
      del:SetSize(18, 18)
      del:SetPoint("RIGHT", row, "RIGHT", 2, 0)
      del:SetScript("OnClick", function()
        local db2 = RT.GetDB()
        if db2 and db2.realms and db2.realms[c.realm] and db2.realms[c.realm].chars then
          db2.realms[c.realm].chars[c.name] = nil
        end
        if db2 and db2.config and db2.config.showChars then
          local key = c.realm .. "|" .. c.name
          db2.config.showChars[key] = nil
        end
        if RT.Sync and RT.Sync.ClearApproval then
          RT.Sync.ClearApproval(c.name)
        end
        if db2 and db2.peers then
          db2.peers[c.name] = nil
        end
        Cfg.Refresh()
        if RT.UI and RT.UI.Refresh then RT.UI.Refresh(true) end
      end)

      y = y + ROW_H
    end
    wlChild:SetHeight(math.max(viewH, y + 2))
    ClampScroll(wlScroll, viewH)

    local bl = {}
    if db and db.config and db.config.syncBlacklist then
      for k, v in pairs(db.config.syncBlacklist) do
        local label = (type(v) == "string" and v or k)
        table.insert(bl, { key = k, label = label })
      end
    end
    table.sort(bl, function(a,b) return tostring(a.label) < tostring(b.label) end)

    viewW = blSection._body:GetWidth()
    viewH = blSection._body:GetHeight()
    y = 0
    for idx, e in ipairs(bl) do
      local row = CreateStripeRow(blChild, y, viewW, idx)
      local txt = CreateRowText(row, "GameFontHighlightSmall", 8, viewW - 32)
      txt:SetTextColor(1, 0.25, 0.25)
      local disp = tostring(e.label or "")
      if disp ~= "" then disp = disp:sub(1,1):upper() .. disp:sub(2) end
      txt:SetText(disp)

      local del = CreateFrame("Button", nil, row, "UIPanelCloseButton")
      del:SetSize(18, 18)
      del:SetPoint("RIGHT", row, "RIGHT", 2, 0)
      del:SetScript("OnClick", function()
        local db2 = RT.GetDB()
        if db2 and db2.config and db2.config.syncBlacklist then
          db2.config.syncBlacklist[e.key] = nil
        end
        if RT.Sync and RT.Sync.BlacklistRemove then
          RT.Sync.BlacklistRemove(e.label)
        end
        Cfg.Refresh()
        if RT.UI and RT.UI.Refresh then RT.UI.Refresh(true) end
      end)

      y = y + ROW_H
    end
    blChild:SetHeight(math.max(viewH, y + 2))
    ClampScroll(blScroll, viewH)

    local raids = CollectRaidsAll()
    y = 0
    local raidsW = raidsSection._body:GetWidth()
    for idx, r in ipairs(raids) do
      local row = CreateStripeRow(raidsPane, y, raidsW, idx)
      local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
      cb:SetPoint("LEFT", row, "LEFT", 0, 0)
      cb:SetChecked(RT.IsRaidEnabled(r.key))

      local txt = CreateRowText(row, "GameFontHighlightSmall", 26, raidsW - 32)
      txt:SetText(r.label)
      cb.text = txt

      cb:SetScript("OnClick", function(self)
        RT.SetRaidEnabled(r.key, self:GetChecked())
        if RT.UI and RT.UI.Refresh then RT.UI.Refresh() end
      end)

      row:SetScript("OnClick", function()
        cb:SetChecked(not cb:GetChecked())
        RT.SetRaidEnabled(r.key, cb:GetChecked())
        if RT.UI and RT.UI.Refresh then RT.UI.Refresh() end
      end)

      y = y + ROW_H
    end
  end

  local function NormalizeName(raw)
    raw = tostring(raw or ""):gsub("^%s+",""):gsub("%s+$","")
    if raw == "" then return nil, nil, nil end
    local realm = (GetRealmName and GetRealmName()) or "Unknown"
    local name = raw

    local n1, r1 = string.match(raw, "^([^%-@]+)[%-@](.+)$")
    if n1 and r1 then
      name = n1:gsub("^%s+",""):gsub("%s+$","")
      realm = r1:gsub("^%s+",""):gsub("%s+$","")
    end

    local lower = string.lower(name)
    name = string.upper(lower:sub(1,1)) .. lower:sub(2)
    return realm, name, lower
  end

  btnAdd:SetScript("OnClick", function()
    local realm, name, nlow = NormalizeName(manualEdit:GetText())
    if not name then return end

    if RT and RT.GetCharData then
      RT.GetCharData(realm, name)
      if RT.SetCharShown then RT.SetCharShown(realm, name, true) end
    end

    local db = RT.GetDB and RT.GetDB() or nil
    if db and db.config and db.config.syncBlacklist and nlow then
      db.config.syncBlacklist[nlow] = nil
    end

    if db then
      db.peers = db.peers or {}
      db.peers[name] = time and time() or 0
    end

    if RT.Sync and RT.Sync.RequestTo then
      RT.Sync.RequestTo(name)
    end

    manualEdit:SetText("")
    Cfg.Refresh()
    if RT.UI and RT.UI.Refresh then RT.UI.Refresh(true) end
  end)

  btnBlock:SetScript("OnClick", function()
    local realm, name, nlow = NormalizeName(manualEdit:GetText())
    if not name then return end

    local db = RT.GetDB and RT.GetDB() or nil
    if db and db.config then
      db.config.syncBlacklist = db.config.syncBlacklist or {}
      db.config.syncBlacklist[nlow] = name
    end

    if db and db.realms then
      for _, r in pairs(db.realms) do
        if r and r.chars and r.chars[name] then
          r.chars[name] = nil
        end
      end
    end
    if db and db.config and db.config.showChars then
      for k,_ in pairs(db.config.showChars) do
        local _, cn = string.match(k, "^(.-)|(.-)$")
        if cn and string.lower(cn) == nlow then
          db.config.showChars[k] = nil
        end
      end
    end

    if RT.Sync and RT.Sync.BlacklistAdd then
      RT.Sync.BlacklistAdd(name)
    end

    if db and db.peers then
      db.peers[name] = nil
    end

    manualEdit:SetText("")
    Cfg.Refresh()
    if RT.UI and RT.UI.Refresh then RT.UI.Refresh(true) end
  end)

  f:SetScript("OnShow", function() Cfg.Refresh() end)

  return f
end

-- Attach the config frame over a parent (front window mode)
function Cfg.AttachTo(parent)
  local f = EnsureFrame()
  if not f then return nil end

  parent = parent or UIParent
  f:SetParent(parent)

  f:SetMovable(false)
  f:RegisterForDrag()
  f:SetScript("OnDragStart", nil)
  f:SetScript("OnDragStop", nil)
  if f._dragArea then
    f._dragArea._rtDragTarget = parent
  end

  if f._closeBtn then f._closeBtn:Show() end

  f:ClearAllPoints()
  f:SetPoint("CENTER", parent, "CENTER", 0, -2)
  f:SetSize(Cfg.EMBED_W, Cfg.MIN_H)

  if parent.GetFrameStrata then f:SetFrameStrata(parent:GetFrameStrata()) end
  if parent.GetFrameLevel then f:SetFrameLevel(parent:GetFrameLevel() + 20) end

  return f
end

function Cfg.Toggle()
  if RT and RT.UI and RT.UI.ToggleConfigPanel then
    RT.UI.ToggleConfigPanel()
    return
  end

  local f = EnsureFrame()
  if f:IsShown() then f:Hide() else f:Show() end
end
