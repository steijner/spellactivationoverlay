local AddonName, SAO = ...

-- Optimize frequent calls
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID

--[[
    OverpowerHandler guesses when Overpower is available

    The following conditions must be met:
    - an enemy dodged recently
    - that enemy is the current target

    This stops if either:
    - Overpower has been cast
    - the current target is not the enemy who dodged
    - more than 5 seconds have elapsed since last dodge

    The Overpower button will glow/unglow successively when
    switching the target back and forth the enemy who dodged.
    This prevents players from switching to Battle Stance
    and then wondering "why am I unable to cast Overpower?"

    If multiple enemies have dodged recently, Overpower
    can only be cast on the last enemy who dodged.
    This matches behavior on current Wrath phase (Ulduar).
    May need testing for Classic Era and other Wrath phases.
]]
local OverpowerHandler = {

    initialized = false,

    -- Variables

    targetGuid = nil,
    vanishTime = nil,

    -- Constants

    maxDuration = 5,
    tolerance = 0.2,

    -- Methods

    init = function(self, id, name)
        SAO.GlowInterface:bind(self);
        self:initVars(id, name);
        self.initialized = true;
    end,

    dodge = function(self, guid)
        self.targetGuid = guid;
        self.vanishTime = GetTime() + self.maxDuration - self.tolerance;
        C_Timer.After(self.maxDuration, function()
            self:timeout();
        end)

        if UnitGUID("target") == guid then
            self:glow();
        end
    end,

    overpower = function(self)
        self.targetGuid = nil;
        -- Always unglow, even if not needed. Better unglow too much than not enough.
        self:unglow();
    end,

    timeout = function(self)
        if self.targetGuid and GetTime() > self.vanishTime then
            self.targetGuid = nil;
            self:unglow();
        end
    end,

    retarget = function(self, ...)
        if not self.targetGuid then return end

        if self.glowing and UnitGUID("target") ~= self.targetGuid then
            self:unglow();
        elseif not self.glowing and UnitGUID("target") == self.targetGuid then
            self:glow();
        end
    end,

    cleu = function(self, ...)
        local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...; -- For all events

        if sourceGUID ~= UnitGUID("player") then return end

        if event == "SWING_MISSED" and select(12, ...) == "DODGE"
        or event == "SPELL_MISSED" and select(15, ...) == "DODGE" then
            self:dodge(destGUID);
        elseif event == "SPELL_CAST_SUCCESS" and select(13, ...) == self.spellName then
            self:overpower();
        end
    end,
}

local function customLogin(self, ...)
    local overpower = 7384;
    local overpowerName = GetSpellInfo(overpower);
    if (overpowerName) then
        OverpowerHandler:init(overpower, overpowerName);
    end
end

local function customCLEU(self, ...)
    if OverpowerHandler.initialized then
        OverpowerHandler:cleu(CombatLogGetCurrentEventInfo());
    end
end

local function retarget(self, ...)
    if OverpowerHandler.initialized then
        OverpowerHandler:retarget(...);
    end
end

local function registerClass(self)
    local tasteforBlood = 60503; -- Unused as of now, might be used in the future.
    local overpower = 7384;
    local execute = 5308;
    local revenge = 6572;
    local victoryRush = 34428;
    local slam = 1464;
    local shieldSlam = 23922;

    self:RegisterAura("bloodsurge", 0, 46916, "blood_surge", "Top", 1, 255, 255, 255, true, { (GetSpellInfo(slam)) });
    self:RegisterAura("sudden_death", 0, 52437, "sudden_death", "Left + Right (Flipped)", 1, 255, 255, 255, true, { (GetSpellInfo(execute)) });
    self:RegisterAura("sword_and_board", 0, 50227, "sword_and_board", "Left + Right (Flipped)", 1, 255, 255, 255, true, { (GetSpellInfo(shieldSlam)) });

    -- Overpower
    self:RegisterAura("overpower", 0, overpower, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(overpower)) });
    self:RegisterCounter("overpower"); -- Must match name from above call

    -- Execute
    self:RegisterAura("execute", 0, execute, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(execute)) });
    self:RegisterCounter("execute"); -- Must match name from above call

    -- Revenge
    self:RegisterAura("revenge", 0, revenge, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(revenge)) });
    self:RegisterCounter("revenge"); -- Must match name from above call

    -- Victory Rush
    self:RegisterAura("victory_rush", 0, victoryRush, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(victoryRush)) });
    self:RegisterCounter("victory_rush"); -- Must match name from above call
end

local function loadOptions(self)
    local overpower = 7384;
    local execute = 5308;
    local revenge = 6572;
    local victoryRush = 34428;
    local slam = 1464;
    local shieldSlam = 23922;

    local bloodsurgeBuff = 46916;
    local bloodsurgeTalent = 46913;

    local suddenDeathBuff = 52437;
    local suddenDeathTalent = 29723;

    local swordAndBoardBuff = 50227;
    local swordAndBoardTalent = 46951;

    local battleStance = GetSpellInfo(2457);
    local defensiveStance = GetSpellInfo(71);
    local berserkerStance = GetSpellInfo(2458);

    self:AddOverlayOption(suddenDeathTalent, suddenDeathBuff);
    self:AddOverlayOption(bloodsurgeTalent, bloodsurgeBuff);
    self:AddOverlayOption(swordAndBoardTalent, swordAndBoardBuff);

    self:AddGlowingOption(nil, overpower, overpower, nil, string.format("%s = %s", DEFAULT, string.format(RACE_CLASS_ONLY, battleStance)));
    if OverpowerHandler.initialized then
        self:AddGlowingOption(nil, OverpowerHandler.fakeSpellID, overpower, nil, string.format("%s, %s, %s", battleStance, defensiveStance, berserkerStance));
    end
    self:AddGlowingOption(nil, revenge, revenge, nil, string.format("%s = %s", DEFAULT, string.format(RACE_CLASS_ONLY, defensiveStance)));
    --self:AddGlowingOption(nil, ---, revenge, nil, string.format("%s, %s, %s", battleStance, defensiveStance, berserkerStance));
    self:AddGlowingOption(nil, execute, execute, nil, string.format("%s = %s", DEFAULT, string.format("%s, %s", battleStance, berserkerStance)));
    --self:AddGlowingOption(nil, ---, execute, nil, string.format("%s, %s, %s", battleStance, defensiveStance, berserkerStance));
    self:AddGlowingOption(nil, victoryRush, victoryRush);
    self:AddGlowingOption(suddenDeathTalent, suddenDeathBuff, execute);
    self:AddGlowingOption(bloodsurgeTalent, bloodsurgeBuff, slam);
    self:AddGlowingOption(swordAndBoardTalent, swordAndBoardBuff, shieldSlam);
end

SAO.Class["WARRIOR"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
    ["COMBAT_LOG_EVENT_UNFILTERED"] = customCLEU,
    ["PLAYER_LOGIN"] = customLogin,
    ["PLAYER_TARGET_CHANGED"] = retarget,
}
