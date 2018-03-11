m4xGroupTimerDB = m4xGroupTimerDB or {}

local timertick, chatinput, timerdata, wrntext
local timerrunning = false

local timerframe = CreateFrame("Frame", "TimerGTFrame", UIParent)
timerframe:SetPoint("BOTTOM", UIParent, "CENTER", 0, 200)
timerframe:SetSize(210, 45)
timerframe:SetFrameStrata("HIGH")
timerframe:EnableMouse(true);
timerframe:SetScript("OnDragStart", timerframe.StartMoving);
timerframe:SetScript("OnDragStop", timerframe.StopMovingOrSizing);

timerframe.Text = timerframe:CreateFontString("TimerGTFrameText", "OVERLAY")
timerframe.Text:SetPoint("CENTER", timerframe)
timerframe.Text:SetFont("Fonts\\FRIZQT__.TTF", 30, "OUTLINE")

local buttonframe = CreateFrame("Button", "ButtonGTFrame", UIParent, "UIPanelButtonTemplate")
buttonframe:SetPoint("LEFT", UIParent, "CENTER", 200, 0)
buttonframe:SetSize(150, 33)
buttonframe:SetFrameStrata("HIGH")
buttonframe:EnableMouse(true);
buttonframe:SetScript("OnDragStart", buttonframe.StartMoving);
buttonframe:SetScript("OnDragStop", buttonframe.StopMovingOrSizing);

buttonframe.Text:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")

local optionbuttonframe = CreateFrame("Button", "OptionButtonGTFrame", buttonframe)
optionbuttonframe:SetPoint("BOTTOM", buttonframe, "TOP", 0, -6)
optionbuttonframe:SetSize(36, 12)
optionbuttonframe:Hide()

optionbuttonframe.bg = optionbuttonframe:CreateTexture(nil, "ARTWORK")
optionbuttonframe.bg:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-FlyoutButton")
optionbuttonframe.bg:SetTexCoord(0.15625, 0.84375, 0, 0.5)
optionbuttonframe.bg:SetPoint("CENTER", 0, -2)
optionbuttonframe.bg:SetSize(38, 16)

local optionframe = CreateFrame("Frame", "OptionGTFrame", optionbuttonframe)
optionframe:SetPoint("BOTTOM", optionbuttonframe, "TOP", 0, -5)
optionframe:SetSize(200, 128)
optionframe:Hide()

optionframe:SetBackdrop({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
	insets = { left = 4, right = 4, top = 4,  bottom = 4 },
})
optionframe:SetBackdropColor(0, 0, 0)
optionframe:SetBackdropBorderColor(0.8, 0.8, 0.8)

optionframe.bg = optionframe:CreateTexture(nil, "BORDER")
optionframe.bg:SetPoint("BOTTOMLEFT", 5, 5)
optionframe.bg:SetPoint("TOPRIGHT", -5, -5)
optionframe.bg:SetAtlas("collections-background-tile")
optionframe.bg:SetAlpha(0.5)

optionframe.Text = optionframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
optionframe.Text:SetPoint("TOP")
optionframe.Text:SetHeight(32)
optionframe.Text:SetText("m4x-GroupTimer")

optionframe.div = optionframe:CreateTexture(nil, "ARTWORK")
optionframe.div:SetPoint("TOPLEFT", 8, -25)
optionframe.div:SetPoint("TOPRIGHT", -8, -25)
optionframe.div:SetHeight(8)
optionframe.div:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")

optionframe.optmin = CreateFrame("EditBox", nil, optionframe, "InputBoxTemplate")
optionframe.optmin:SetPoint("TOPLEFT", 25, -40)
optionframe.optmin:SetSize(35, 20)
optionframe.optmin:SetAutoFocus(false)
optionframe.optmin:SetNumeric(true)
optionframe.optmin:SetMaxLetters(3)
optionframe.optmin:SetText(2)
optionframe.optmin.Text = optionframe.optmin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
optionframe.optmin.Text:SetPoint("LEFT", optionframe.optmin, "RIGHT", 5, 0)
optionframe.optmin.Text:SetText("Min")

optionframe.optsec = CreateFrame("EditBox", nil, optionframe, "InputBoxTemplate")
optionframe.optsec:SetPoint("LEFT", optionframe.optmin, "RIGHT", 60, 0)
optionframe.optsec:SetSize(30, 20)
optionframe.optsec:SetAutoFocus(false)
optionframe.optsec:SetNumeric(true)
optionframe.optsec:SetMaxLetters(2)
optionframe.optsec:SetText(0)
optionframe.optsec.Text = optionframe.optsec:CreateFontString(nil, "OVERLAY", "GameFontNormal")
optionframe.optsec.Text:SetPoint("LEFT", optionframe.optsec, "RIGHT", 5, 0)
optionframe.optsec.Text:SetText("Sec")

optionframe.optwrn = CreateFrame("EditBox", nil, optionframe, "InputBoxTemplate")
optionframe.optwrn:SetPoint("TOPLEFT", optionframe.optmin, "BOTTOMLEFT", 0, -30)
optionframe.optwrn:SetSize(160, 20)
optionframe.optwrn:SetAutoFocus(false)
optionframe.optwrn:SetMaxLetters(20)
optionframe.optwrn:SetText("LOOT LOOT LOOT")
optionframe.optwrn.Text = optionframe.optwrn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
optionframe.optwrn.Text:SetPoint("BOTTOM", optionframe.optwrn, "TOP", 0, 5)
optionframe.optwrn.Text:SetText("Warning Message")

RegisterAddonMessagePrefix("GroupTimerDATA")
timerframe:RegisterEvent("PLAYER_ENTERING_WORLD")
timerframe:RegisterEvent("CHAT_MSG_ADDON")
timerframe:RegisterEvent("READY_CHECK_FINISHED")
timerframe:RegisterEvent("GROUP_LEFT")
timerframe:RegisterEvent("PARTY_LEADER_CHANGED")

local function ClearFrames(clr)
	_G[clr .. "GTFrame"]:Hide()
	_G[clr .. "GTFrameText"]:SetText("")
	_G[clr .. "GTFrameText"]:SetTextColor(1, 0.82, 0)
	if timerrunning and clr == "Timer" then
		timertick:Cancel()
		timerrunning = false
	end
end

local function StartButton(btntext)
	if UnitIsGroupLeader("player") then
		buttonframe.Text:SetText(btntext)
		buttonframe:Show()
		if btntext == "Start Timer" or btntext == "Stop Timer" then
			optionbuttonframe:Show()
		else
			optionbuttonframe:Hide()
		end
	end
end

local function StartWarning()
	ClearFrames("Timer")
	RaidNotice_AddMessage(RaidBossEmoteFrame, wrntext, ChatTypeInfo["RAID_WARNING"])
	PlaySound(SOUNDKIT.RAID_WARNING)
	StartButton("Ready Check")
end

local function StartTimer()
	local mins = 0
	local secs = timerdata
	if secs > 0 then
		if secs > 59 then
			mins = floor(secs / 60)
			secs = secs - (mins * 60)
		end
		timerframe.Text:SetFormattedText(mins > 0 and "%02d:%02d" or "%2$d", mins, secs)
	else
		StartWarning()
	end
	timerdata = timerdata - 1
end

local function StartFrameMove(frm)
	if not _G[frm .. "GTFrame"]:IsMovable() then
		_G[frm .. "GTFrameText"]:SetTextColor(1, 0, 0)
		_G[frm .. "GTFrameText"]:SetText("Move " .. frm)
		_G[frm .. "GTFrame"]:SetMovable(true)
		_G[frm .. "GTFrame"]:RegisterForDrag("LeftButton")
		_G[frm .. "GTFrame"]:Show()
	else
		_G[frm .. "GTFrame"]:SetMovable(false)
		_G[frm .. "GTFrame"]:RegisterForDrag()
		m4xGroupTimerDB[frm .. "Pos"][1], m4xGroupTimerDB[frm .. "Pos"][2], m4xGroupTimerDB[frm .. "Pos"][3], m4xGroupTimerDB[frm .. "Pos"][4], m4xGroupTimerDB[frm .. "Pos"][5] = _G[frm .. "GTFrame"]:GetPoint()
		ClearFrames(frm)
	end
end

local function SaveOptions()
	chatinput = ((optionframe.optmin:GetNumber() * 60) + optionframe.optsec:GetNumber())
	wrntext = optionframe.optwrn:GetText()
end

buttonframe:SetScript("OnClick", function()
	if UnitIsGroupLeader("player") then
		if buttonframe.Text:GetText() == "Start Timer" then
			SaveOptions()
			SendAddonMessage("GroupTimerDATA", chatinput .. ":" .. wrntext, "PARTY")
			StartButton("Stop Timer")
		elseif buttonframe.Text:GetText() == "Ready Check" then
			DoReadyCheck()
		elseif buttonframe.Text:GetText() == "Stop Timer" then
			SendAddonMessage("GroupTimerDATA", "STOP", "PARTY")
		end
	end
end)

optionbuttonframe:SetScript("OnClick", function()
	if not optionframe:IsShown() then
		optionframe:Show()
		optionbuttonframe.bg:SetTexCoord(0.15625, 0.84375, 0.5, 0)
	else
		optionframe:Hide()
		optionbuttonframe.bg:SetTexCoord(0.15625, 0.84375, 0, 0.5)
		SaveOptions()
	end
end)

optionframe.optmin:SetScript("OnEnterPressed", function(self)
	self:ClearFocus()
end)
optionframe.optsec:SetScript("OnEnterPressed", function(self)
	self:ClearFocus()
end)
optionframe.optwrn:SetScript("OnEnterPressed", function(self)
	self:ClearFocus()
end)

timerframe:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		ClearFrames("Timer")
		ClearFrames("Button")
		SaveOptions()
		if m4xGroupTimerDB.ButtonPos then
			buttonframe:ClearAllPoints()
			buttonframe:SetPoint(unpack(m4xGroupTimerDB.ButtonPos))
			timerframe:ClearAllPoints()
			timerframe:SetPoint(unpack(m4xGroupTimerDB.TimerPos))
		else
			m4xGroupTimerDB.ButtonPos = {}
			m4xGroupTimerDB.TimerPos = {}
		end
	elseif event == "CHAT_MSG_ADDON" then
		local _, msgdata = ...
		if msgdata == "STOP" then
			ClearFrames("Timer")
			StartButton("Start Timer")
		else
			timerdata, wrntext = strsplit(":", msgdata, 2)
			timerdata = tonumber(timerdata)
			if timerdata == 0 then
				timerdata = 120
			end
			if timerframe:IsMovable() then
				StartFrameMove("Timer")
				StartFrameMove("Button")
			end
			timerframe:Show()
			timerrunning = true
			timertick = C_Timer.NewTicker(1, StartTimer, timerdata+1)
		end
	elseif event == "READY_CHECK_FINISHED" then
		ClearFrames("Timer")
		StartButton("Start Timer")
	elseif event == "GROUP_LEFT" or event == "PARTY_LEADER_CHANGED" then
		ClearFrames("Timer")
		ClearFrames("Button")
	end
end)

SlashCmdList["M4XGROUPTIMER"] = function(chat)
	if chat == "lock" then
		if not timerrunning then
			StartFrameMove("Timer")
			StartFrameMove("Button")
			optionbuttonframe:Hide()
		else
			print("Can't move frames while a countdown is on.")
		end
	elseif chat == "hide" then
		ClearFrames("Timer")
		ClearFrames("Button")
	elseif chat == "help" then
		print("/gtimer - Start timer control")
		print("/gtimer lock - Lock/Unlock timer frames position")
		print("/gtimer hide - Hide timer frames")
	elseif UnitIsGroupLeader("player") then
		if timerframe:IsMovable() then
			StartFrameMove("Timer")
			StartFrameMove("Button")
		end
		if not timerrunning then
			StartButton("Start Timer")
		end
	else
		print("To control the group timer you need to be the leader of a group.")
		print("For some commands do /gtimer help")
	end
end

SLASH_M4XGROUPTIMER1 = "/gtimer"