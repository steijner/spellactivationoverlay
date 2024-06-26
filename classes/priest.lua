local AddonName, SAO = ...

local function registerClass(self)
    if not self.IsEra() then
        local smite = GetSpellInfo(585);
        local flashHeal = GetSpellInfo(2061);

        local serendipityBuff1 = 63731;
        local serendipityBuff2 = 63735;
        local serendipityBuff3 = 63734;
        local ghAndPoh = { (GetSpellInfo(2060)), (GetSpellInfo(596)) };

        -- Add option links during registerClass(), not during loadOptions() which would be loaded only when the options panel is opened
        -- Add option links before RegisterAura() calls, so that options they are used by initial triggers, if any
        self:AddOverlayLink(serendipityBuff3, serendipityBuff1);
        self:AddOverlayLink(serendipityBuff3, serendipityBuff2);
        self:AddGlowingLink(serendipityBuff3, serendipityBuff1);
        self:AddGlowingLink(serendipityBuff3, serendipityBuff2);

        -- Surge of Light
        self:RegisterAura("surge_of_light", 0, 33151, "surge_of_light", "Left + Right (Flipped)", 1, 255, 255, 255, true, { smite, flashHeal });

        for talentPoints=1,3 do
            local auraName = ({ "serendipity_low", "serendipity_medium", "serendipity_high" })[talentPoints];
            local auraBuff = ({ serendipityBuff1, serendipityBuff2, serendipityBuff3 })[talentPoints];
            for nbStacks=1,3 do
                local scale = 0.4 + 0.2 * nbStacks; -- 60%, 80%, 100%
                local pulse = nbStacks == 3;
                local glowIDs = nbStacks == 3 and ghAndPoh or nil;
                self:RegisterAura(auraName, nbStacks, auraBuff, "serendipity", "Top", scale, 255, 255, 255, pulse, glowIDs);
            end
        end

        -- Healing Trance / Soul Preserver
        self:RegisterAuraSoulPreserver("soul_preserver_priest", 60514); -- 60514 = Priest buff

    elseif self.IsSoD() then
        local smite = GetSpellInfo(585);
        local flashHeal = GetSpellInfo(2061);

        -- Surge of Light
        self:RegisterAura("surge_of_light_sod", 0, 431666, "surge_of_light", "Left + Right (Flipped)", 1, 255, 255, 255, true, { smite, flashHeal });

        local serendipityBuff = 413247;
        local lesserHeal = 2050;
        local heal = 2054;
        local greaterHeal = 2060;
        local prayerOfHealing = 596;
        local serendipityImprovedSpells = { (GetSpellInfo(lesserHeal)), (GetSpellInfo(heal)), (GetSpellInfo(greaterHeal)), (GetSpellInfo(prayerOfHealing)) };
        for nbStacks=1,3 do
            local scale = 0.4 + 0.2 * nbStacks; -- 60%, 80%, 100%
            local pulse = nbStacks == 3;
            local glowIDs = nbStacks == 3 and serendipityImprovedSpells or nil;
            self:RegisterAura("serendipity_sod", nbStacks, serendipityBuff, "serendipity", "Top", scale, 255, 255, 255, pulse, glowIDs);
        end
    end
end

local function loadOptions(self)
    local smite = 585;
    local flashHeal = 2061;
    local lesserHeal = 2050;
    local heal = 2054;
    local greaterHeal = 2060;
    local prayerOfHealing = 596;

    local surgeOfLightBuff = 33151;
    local surgeOfLightTalent = 33150;
    local surgeOfLightSoDBuff = 431666;
    local surgeOfLightSoDRune = 431664;

    local serendipityBuff3 = 63734;
    local serendipityTalent = 63730;
    local serendipitySoDBuff = 413247;

    local oneOrTwoStacks = self:NbStacks(1, 2);
    local threeStacks = self:NbStacks(3);

    if not self.IsEra() then
        self:AddOverlayOption(surgeOfLightTalent, surgeOfLightBuff);
        self:AddOverlayOption(serendipityTalent, serendipityBuff3, 0, oneOrTwoStacks, nil, 2); -- setup any stacks, test with 2 stacks
        self:AddOverlayOption(serendipityTalent, serendipityBuff3, 3); -- setup 3 stacks
        self:AddSoulPreserverOverlayOption(60514); -- 60514 = Priest buff

        self:AddGlowingOption(surgeOfLightTalent, surgeOfLightBuff, smite);
        self:AddGlowingOption(surgeOfLightTalent, surgeOfLightBuff, flashHeal);
        self:AddGlowingOption(serendipityTalent, serendipityBuff3, greaterHeal, threeStacks);
        self:AddGlowingOption(serendipityTalent, serendipityBuff3, prayerOfHealing, threeStacks);
    elseif self.IsSoD() then
        self:AddOverlayOption(surgeOfLightSoDRune, surgeOfLightSoDBuff);
        self:AddOverlayOption(serendipitySoDBuff, serendipitySoDBuff, 0, oneOrTwoStacks, nil, 2); -- setup any stacks, test with 2 stacks
        self:AddOverlayOption(serendipitySoDBuff, serendipitySoDBuff, 3); -- setup 3 stacks

        self:AddGlowingOption(surgeOfLightSoDRune, surgeOfLightSoDBuff, smite);
        self:AddGlowingOption(surgeOfLightSoDRune, surgeOfLightSoDBuff, flashHeal);
        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, lesserHeal, threeStacks);
        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, heal, threeStacks);
        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, greaterHeal, threeStacks);
        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, prayerOfHealing, threeStacks);
    end
end

SAO.Class["PRIEST"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
