local UnitName = UnitName

profileSettings = nil

local defaultSettings = {
    scale = 1,
    isMovable = true,
    timerPosX = 0,
    timerPosY = 0,
}

local poisonSpellId = {
    [25349] = {
        name = "Deadly Poison V",
        duration = 12,
        rank = "V",
        iconPath = "Interface\\Icons\\Ability_rogue_dualweild"
    },
    [11354] = {
        name = "Deadly Poison IV",
        duration = 12,
        rank = "IV",
        iconPath = "Interface\\Icons\\Ability_rogue_dualweild"
    },
    [52574] = {
        name = "Corrosive Poison II",
        duration = 12,
        rank = "II",
        iconPath = "Interface\\Icons\\Spell_nature_corrosivebreath"
    },
    [51922] = {
        name = "Corrosive Poison I",
        duration = 12,
        rank = "I",
        iconPath = "Interface\\Icons\\Spell_nature_corrosivebreath"
    },
}

local activeTimers = {}
local timeSinceUpdate = 0
local baseOffset = 12
local baseIconOffset = 40
local activeTimersCount = 0
local testStartTimer = nil
local isTestMode = false
local originalAnchor = {
    point = "CENTER",
    relativeTo = "UIParent",
    relativePoint = "CENTER"
}

-- Mouse movement handled via XML scripts
function BootyPoisonTwister_OnMouseDown(button)
    if button == "LeftButton" then
        this:StartMoving()
    end
end

function BootyPoisonTwister_OnMouseUp(button)
    if button == "LeftButton" then
        this:StopMovingOrSizing()

        local x, y = GetRelativeOffset(this, UIParent)
        profileSettings.timerPosX = x
        profileSettings.timerPosY = y

        RestoreAnchor(this, originalAnchor, x, y)
    end
end

function BootyPoisonTwister_OnLoad()
    this:RegisterEvent("PLAYER_ENTERING_WORLD")
    this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
    this:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
    this:RegisterEvent("UNIT_CASTEVENT")
end

function BootyPoisonTwister_OnEvent(event)
    if event == "PLAYER_ENTERING_WORLD" then
        print("|cff00ff00[BootyPoisonTwister]|r Time to twist yo Booty! Use /bpt or /booty to see options. ")
        BootyPoisonTwister_Init()

        SLASH_BPT1, SLASH_BPT2 = "/bpt", "/booty"
        SlashCmdList["BPT"] = function(msg)
            if msg == "show" then
                if getglobal("BootyPoisonTimer"):IsShown() then
                    getglobal("BootyPoisonTimer"):Hide()
                else
                    getglobal("BootyPoisonTimer"):Show()
                end
            elseif msg == "lock" then
                BootyPoisonTwister_Lock(getglobal("BootyPoisonTimer"):IsMovable())
            elseif msg == "config" then
                if getglobal("BootyPoisonTwister"):IsShown() then
                    getglobal("BootyPoisonTwister"):Hide()
                else
                    getglobal("BootyPoisonTwister"):Show()
                end
            elseif msg == "test" then
                isTestMode = true
                testStartTimer = GetTime()
                local bootyFrame = getglobal("ShakeYoBooty")
                bootyFrame:Show()
                bootyFrame.animationGroup:Play();
                local stackCounter = 1
                for k, v in pairs(poisonSpellId) do
                    local timerData = { spellId = k, name = poisonSpellId[k].name, stacks = stackCounter, duration = poisonSpellId[k].duration, endTimer = GetTime() + poisonSpellId[k].duration, rank = poisonSpellId[k].rank }
                    BootyPoisonTwister_CreateTimerIconFrame(timerData)
                    stackCounter = stackCounter + 1
                end
            elseif msg == "shake" then
                local bootyFrame = getglobal("ShakeYoBooty")
                if bootyFrame.animationGroup:IsPlaying() then
                    bootyFrame.animationGroup:Stop()
                    bootyFrame:Hide()
                else
                    bootyFrame:Show()
                    bootyFrame.animationGroup:Play();
                end
            else
                print("|cff00ff00[BootyPoisonTwister]:|r Lightweight poison timers for rogues.")
                print("|cff00ff00Usage:|r /bpt or /booty {show  | lock | config | test }")
                print("|cff00ff00 - show|r - toggle show/hide the timers")
                print("|cff00ff00 - lock|r - toggle lock/unlock the timers position")
                print("|cff00ff00 - config|r - toggle on/off the options menu")
                print("|cff00ff00 - test|r - run fake timers")
                print("|cff00ff00 - shake|r - shake yo Booty!")
            end
        end
    end
    if event == "UNIT_CASTEVENT" and UnitName(arg1) == UnitName("player") and poisonSpellId[arg4] then
        local newTimer = true
        local activeTimerData = activeTimers[arg4]
        if activeTimerData then
            newTimer = false
            if activeTimerData.stacks < 5 then
                activeTimerData.stacks = activeTimerData.stacks + 1
                BootyPoisonTwister_RefreshPoisonStacks(activeTimerData)
            end
            activeTimerData.endTimer = GetTime() + activeTimerData.duration
        end

        if newTimer then
            local timerData = { spellId = arg4, name = poisonSpellId[arg4].name, stacks = 1, duration = poisonSpellId[arg4].duration, endTimer = GetTime() + poisonSpellId[arg4].duration, rank = poisonSpellId[arg4].rank }
            BootyPoisonTwister_CreateTimerIconFrame(timerData)
        end
    end
end

function BootyPoisonTwister_Init()
    if profileSettings == nil then
        profileSettings = defaultSettings
    else
        BootyPoisonTwister_Lock(not profileSettings.isMovable)
        BootyPoisonTwister_SetScale(profileSettings.scale)
        BootyPoisonTwister_SetTimerPosition()
    end

    BootyPoisonTwister_InitBootyShake()
    BootyPoisonTwister_InitPoisonTimer()
    BootyPoisonTwister_InitOptions()
end

function BootyPoisonTwister_SetTimerPosition()
    local timerFrame = getglobal("BootyPoisonTimer")
    timerFrame:ClearAllPoints()
    timerFrame:SetPoint(
            originalAnchor.point,
            originalAnchor.relativeTo,
            originalAnchor.relativePoint,
            profileSettings.timerPosX or 200,
            profileSettings.timerPosY or 0
    )
end

function BootyPoisonTwister_Lock(isMovable)
    if isMovable then
        getglobal("BootyPoisonTimer"):SetMovable(false)
        getglobal("BootyPoisonTimer"):SetBackdrop({
            bgFile = ""
        })
        getglobal("BootyPoisonTimer"):EnableMouse(false)
        getglobal("BootyPoisonTimerClose"):Hide()
        getglobal("BootyPoisonTimerTitle"):Hide()
        profileSettings.isMovable = false
    else
        getglobal("BootyPoisonTimer"):SetMovable(true)
        getglobal("BootyPoisonTimer"):SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        getglobal("BootyPoisonTimer"):EnableMouse(true)
        getglobal("BootyPoisonTimerClose"):Show()
        getglobal("BootyPoisonTimerTitle"):Show()
        profileSettings.isMovable = true
    end
end

function BootyPoisonTwister_SetScale(scale)
    if scale and getglobal("BootyPoisonTimer") then
        profileSettings.scale = scale
        getglobal("BootyPoisonTimer"):SetScale(scale)
    end
end

function BootyPoisonTwister_OnUpdate(arg1)
    if isTestMode then
        -- Booty shake test --
        if testStartTimer + 5 < GetTime() then
            getglobal("ShakeYoBooty").animationGroup:Stop()
            getglobal("ShakeYoBooty"):Hide()
            isTestMode = false
            testStartTimer = nil
        end
    end

    timeSinceUpdate = timeSinceUpdate + arg1
    if (timeSinceUpdate > 0.25) then
        BootyPoisonTwister_UpdatePoisonTimers()
        timeSinceUpdate = 0
    end
end

function BootyPoisonTwister_UpdatePoisonTimers()
    local offsetCounter = 0
    for k, v in pairs(activeTimers) do
        BootyPoisonTwister_RefreshPoisonTimer(v, offsetCounter)
        offsetCounter = offsetCounter + 1
    end
    timeSinceUpdate = 0
end

function BootyPoisonTwister_RefreshPoisonStacks(timerData)
    getglobal(timerData.spellId .. "Stacks"):SetText(timerData.stacks);
end

function BootyPoisonTwister_RefreshPoisonTimer(timerData, offsetCounter)
    local currentTime = GetTime()
    local timerRow = getglobal(timerData.spellId)
    local timerRowText = getglobal(timerRow:GetName() .. "Text")
    local timerRowStacks = getglobal(timerRow:GetName() .. "Stacks")

    timerRowText:SetText(BootyPoisonTwister_TimeToText(timerData.endTimer - currentTime));
    if timerData.endTimer - currentTime > 0 then
        if timerData.endTimer - currentTime < 5 then
            timerRowText:SetTextColor(1, 0, 0, 1);
            if not timerRow.animationGroup:IsPlaying() then
                timerRow.animationGroup:Play()
            end
        else
            if timerRow.animationGroup:IsPlaying() then
                timerRow.animationGroup:Stop()
            end
            timerRowText:SetTextColor(1, 1, 1, 1);
        end
        timerRow:SetPoint("TOPLEFT", timerRow:GetParent(), "TOPLEFT", 5 + offsetCounter * (baseIconOffset + 5), -35)
    else
        activeTimers[timerData.spellId] = nil
        activeTimersCount = activeTimersCount - 1
        timerRowStacks:SetText(1)
        timerRowText:SetText(0)
        timerRowText:SetTextColor(1, 0, 0, 1);
        timerRow.animationGroup:Stop()
        timerRow:SetAlpha(0)
        timerRow:Hide();
    end
end

---- Progress Bar Timer - TODO ----
function BootyPoisonTwister_CreateTimerFrame(timerData)
    DebugPrint("Create timer frame - parent" .. getglobal("BootyPoisonTimer"):GetName())
    local timerFrame = nil
    if getglobal(timerData.spellId) then
        timerFrame = getglobal(timerData.spellId)
    else
        timerFrame = CreateFrame("Button", timerData.spellId, getglobal("BootyPoisonTimer"), "TimersBarTemplate")
    end
    local currentTime = GetTime()

    getglobal(timerFrame:GetName() .. "Text1"):SetText(timerData.name .. " Stacks:" .. timerData.stacks);
    getglobal(timerFrame:GetName() .. "Text1"):SetTextColor(1, 1, 1, 1);
    getglobal(timerFrame:GetName() .. "Text2"):SetText(BootyPoisonTwister_TimeToText(timerData.endTimer - currentTime));
    getglobal(timerFrame:GetName() .. "Text2"):SetTextColor(1, 1, 1, 1);
    getglobal(timerFrame:GetName() .. "StatusBar"):SetMinMaxValues(0, timerData.duration);
    getglobal(timerFrame:GetName() .. "StatusBar"):SetValue((timerData.endTimer - currentTime));
    timerFrame:SetPoint("TOPLEFT", getglobal("BootyPoisonTimer"), "TOPLEFT", 0, -30 - (activeTimersCount * baseOffset))

    timerFrame:Show()

    activeTimers[timerData.spellId] = timerData
    activeTimersCount = activeTimersCount + 1
end

function BootyPoisonTwister_CreateTimerIconFrame(timerData)
    local timerFrame = nil
    if getglobal(timerData.spellId) then
        timerFrame = getglobal(timerData.spellId)
    else
        timerFrame = CreateFrame("Button", timerData.spellId, getglobal("BootyPoisonTimer"), "TimersIconTemplate")
    end
    local currentTime = GetTime()
    getglobal(timerFrame:GetName() .. "Icon"):SetTexture(poisonSpellId[timerData.spellId].iconPath);
    getglobal(timerFrame:GetName() .. "Text"):SetText(BootyPoisonTwister_TimeToText(timerData.endTimer - currentTime))
    getglobal(timerFrame:GetName() .. "Text"):SetTextColor(1, 1, 1, 1);
    getglobal(timerFrame:GetName() .. "Stacks"):SetText(timerData.stacks)
    getglobal(timerFrame:GetName() .. "Rank"):SetText("Rank " .. timerData.rank)
    getglobal(timerFrame:GetName() .. "Rank"):SetPoint("TOP", getglobal(timerFrame:GetName() .. "Icon"), "TOP", 0, 10)
    timerFrame:SetPoint("TOPLEFT", getglobal("BootyPoisonTimer"), "TOPLEFT", 5 + activeTimersCount * (baseIconOffset + 5), -35)
    timerFrame:SetAlpha(1)
    local animationGroup = timerFrame:CreateAnimationGroup()
    animationGroup:SetLooping("BOUNCE")
    local fade = animationGroup:CreateAnimation("Alpha")
    fade:SetDuration(0.9)
    fade:SetChange(-1)
    fade:SetOrder(1)

    timerFrame.animationGroup = animationGroup
    timerFrame:Show()

    activeTimers[timerData.spellId] = timerData
    activeTimersCount = activeTimersCount + 1
end

function BootyPoisonTwister_InitBootyShake()
    local bootyFrame = CreateFrame("Button", "ShakeYoBooty", UIParent, "ShakeYoBooty")
    getglobal(bootyFrame:GetName() .. "Icon"):SetTexture("Interface\\AddOns\\BootyPoisonTwister\\icons\\booty.tga");
    getglobal(bootyFrame:GetName() .. "Text"):SetText("Shake it! Shake it!");
    getglobal(bootyFrame:GetName() .. "Text"):SetPoint("TOP", bootyFrame, "TOP", 0, 0)
    local animationGroup = bootyFrame:CreateAnimationGroup()
    animationGroup:SetLooping("BOUNCE")
    local rotate = animationGroup:CreateAnimation("Rotation")
    rotate:SetDegrees(20)
    rotate:SetDuration(0.2)
    rotate:SetEndDelay(0.5)
    rotate:SetOrder(1)

    bootyFrame.animationGroup = animationGroup
end

function BootyPoisonTwister_InitPoisonTimer()
    getglobal("BootyPoisonTimerTitle"):SetText("Booty Poison Twister !")
    getglobal("BootyPoisonTimerTitle"):SetPoint("TOP", getglobal("BootyPoisonTimer"), "TOP", 0, -10)
end

function BootyPoisonTwister_InitOptions()
    getglobal("BootyPoisonTwisterTitle"):SetText("BPT - Options")
    getglobal("BootyPoisonTwisterTitle"):SetPoint("TOP", getglobal("BootyPoisonTwister"), "TOP", 0, -10)
    getglobal("BootyPoisonTwisterScaleSlider" .. 'Low'):SetText('0.1'); --Sets the left-side slider text (default is "Low").
    getglobal("BootyPoisonTwisterScaleSlider" .. 'High'):SetText('2'); --Sets the right-side slider text (default is "High").
    getglobal("BootyPoisonTwisterScaleSlider" .. 'Text'):SetText('Scale'); --Sets the "title" text (top-centre of slider).
end

---- UTILITIES ----

function BootyPoisonTwister_GetLocalTime()
    local strtime = date("%j%H%M%S");
    local time = tonumber(string.sub(strtime, -2));
    time = time + tonumber(string.sub(strtime, -4, -3)) * 60;
    time = time + tonumber(string.sub(strtime, -6, -5)) * 3600;
    time = time + tonumber(string.sub(strtime, -9, -7)) * 86400;
    return time;
end

function BootyPoisonTwister_TimeToText(time)
    local TIME_FORMAT_S = "%2d";
    local TIME_FORMAT_M = "%02d:%02d";
    local TIME_FORMAT_H = "%02d:%02d:%02d";
    local TIME_FORMAT_D = "%02d:%02d:%02d:%02d";
    local absTime = math.abs(time);

    local days = 0;
    local hours = absTime / 3600;
    local minutes = math.mod(absTime / 60, 60);
    local seconds = math.mod(absTime, 60);

    if (hours >= 24) then
        days = hours / 24;
        hours = math.mod(hours, 24);
    end

    if (time >= 0) then
        if (days > 0) then
            return format(TIME_FORMAT_D, days, hours, minutes, seconds);
        elseif (hours > 1) then
            return format(TIME_FORMAT_H, hours, minutes, seconds);
        elseif (minutes > 1) then
            return format(TIME_FORMAT_M, minutes, seconds);
        else
            return format(TIME_FORMAT_S, seconds);
        end
    else
        return format(TIME_FORMAT_S, 0);
    end
end

function DebugPrint(msg)
    print("|cff00ff00[BootyPoisonTwister]|r " .. msg)
end

function GetRelativeOffset(frame, rel)
    local relX, relY = rel:GetCenter()
    local frameX, frameY = frame:GetCenter()

    if not (relX and relY and frameX and frameY) then
        return 0, 0
    end

    local dx = frameX - relX
    local dy = frameY - relY

    return dx, dy
end

function RestoreAnchor(frame, anchor, x, y)
    frame:ClearAllPoints()
    frame:SetPoint(anchor[1], anchor[2], anchor[3], x, y)
end

function LoadFramePosition(frame)
    frame:ClearAllPoints()
    frame:SetPoint(
            originalAnchor.timerAnchor.point,
            originalAnchor.timerAnchor.relativeTo,
            originalAnchor.timerAnchor.relativePoint,
            profileSettings.timerPosX or 200,
            profileSettings.timerPosY or 0
    )
end
