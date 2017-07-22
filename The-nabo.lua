--[[ Script AutoUpdater ]]
 local version = "2.0"
 local author = "Vankatze"
 local SCRIPT_NAME = "The_Nabo"
 local AUTOUPDATE = true
 local UPDATE_HOST = "raw.githubusercontent.com"
 local ran = math.random
 local UPDATE_PATH = "vankatze/vktz/master/The-nabo.lua".."?rand="..ran(3500,5500)
 local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
 local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

--[[ Local General ]]
local ScriptName = "The Nabo"
local AUTOUPDATES = true
local Author = "Vankatze"
local version = 1
local mh = myHero
local cha = mh.charName
local pi, pi2, sin, cos, huge, sqrt, floor, ceil, max, random, round = math.pi, 2*math.pi, math.sin, math.cos, math.huge, math.sqrt, math.floor, math.ceil, math.max, math.random, math.round
local clock = os.clock
local pairs, ipairs = pairs, ipairs
local insert, remove = table.insert, table.remove
local TEAM_ALLY, TEAM_ENEMY
local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil
local PredictedDamage = {}
local RefreshTime = 0.4
local DefensiveItems = nil 
local CastableItems = {
    Bork        = { Range = 650 , Slot = function() return FindItemSlot("SwordOfFeastAndFamine") end, reqTarget = true, IsReady = function() return (FindItemSlot("SwordOfFeastAndFamine") ~= nil and mh:CanUseSpell(FindItemSlot("SwordOfFeastAndFamine")) == READY) end, Damage = function(target) return getDmg("RUINEDKING", target, mh) end},
    Bwc         = { Range = 650 , Slot = function() return FindItemSlot("BilgewaterCutlass") end, reqTarget = true, IsReady = function() return (FindItemSlot("BilgewaterCutlass") ~= nil and mh:CanUseSpell(FindItemSlot("BilgewaterCutlass")) == READY) end, Damage = function(target) return getDmg("BWC", target, mh) end},
    Hextech     = { Range = 750 , Slot = function() return FindItemSlot("HextechGunblade") end, reqTarget = true, IsReady = function() return (FindItemSlot("HextechGunblade") ~= nil and mh:CanUseSpell(FindItemSlot("HextechGunblade")) == READY) end, Damage = function(target) return getDmg("HXG", target, mh) end},
	}

if cha ~= "Ezreal" then return end

--[[ Script Menu ]]
function OnLoad() BaseUlt()
    print("<b><font color=\"#FF0077\">EzzY - The truly Nabo : </font></b><font color=\"#FFCB0F\"> Funny for you ! </font><font color=\"#FF0077\">| Vankatze |</font>")
    local r = _Required()
    r:Add({Name = "SimpleLib", Url = "raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua"})
    r:Check()
    if OrbwalkManager.GotReset then return end
    if r:IsDownloading() then return end
    if OrbwalkManager == nil then print("Check your SimpleLib file, isn't working... The script can't load without SimpleLib. Try to copy-paste the entire SimpleLib.lua on your common folder.") return end
    DelayAction(function() CheckUpdate() end, 5)
    DelayAction(function() _arrangePriorities() end, 10)
    TS = _SimpleTargetSelector(TARGET_LESS_CAST_PRIORITY, 1150, DAMAGE_PHYSICAL)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."24052015")
    DefensiveItems = {
            Zhonyas     = _Spell({Range = 1000, Type = SPELL_TYPE.SELF}):AddSlotFunction(function() return FindItemSlot("ZhonyasHourglass") end),
        }
    Q = _Spell({Slot = _Q, DamageName = "Q", Range = 1050, Width = 58, Delay = 0.25, Speed = 2000, Aoe = false, Collision = true, Type = SPELL_TYPE.LINEAR}):AddDraw()
    W = _Spell({Slot = _W, DamageName = "W", Range = 1000, Width = 80, Delay = 0.25, Speed = 1600, Aoe = false, Collision = false, Type = SPELL_TYPE.LINEAR}):AddDraw()
    E = _Spell({Slot = _E, DamageName = "E", Range = 475, Width = 60, Delay = 0.25, Speed = 2000, Aoe = false, Collision = false, Type = SPELL_TYPE.CIRCULAR}):AddDraw()
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})
    R = _Spell({Slot = _R, DamageName = "R", Range = 2500, Width = 160, Delay = 1, Speed = 2000, Collision = false, Aoe = true, Type = SPELL_TYPE.LINEAR}):AddDraw()

    TS:AddToMenu(Menu)

    Menu:addSubMenu(cha.." - Combo Settings", "Combo")
        Menu.Combo:addParam("Overkill", "Overkill % for Dmg Predict..", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
        Menu.Combo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useE", "Use E to mouse pos", SCRIPT_PARAM_ONOFF, false)
        Menu.Combo:addParam("useR", "Use Smart R", SCRIPT_PARAM_ONOFF, false)
        Menu.Combo:addParam("useR2", "Use R If Enemies >=", SCRIPT_PARAM_SLICE, math.min(#GetEnemyHeroes(), 3), 0, 5, 0)
        Menu.Combo:addParam("Zhonyas", "Use Zhonyas if HP % <=", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)

    Menu:addSubMenu(cha.." - Harass Settings", "Harass")
        Menu.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(cha.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(cha.." - LastHit Settings", "LastHit")
        Menu.LastHit:addParam("useQ", "Use Q", SCRIPT_PARAM_LIST, 2, {"Never", "Smart", "Always"})
        Menu.LastHit:addParam("Mana", "Min. Mana Percent:", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

    Menu:addSubMenu(cha.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(cha.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useR", "Use R (Not Recomended)", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

        Menu:addSubMenu(cha.." - Auto Settings", "Auto")
            Menu.Auto:addSubMenu("Use E To Evade", "UseE")
            _Evader(Menu.Auto.UseE):CheckCC():AddCallback(
                function(target)
                    if E:IsReady() and IsValidTarget(target) then
                        local Position = Vector(mh) + Vector(Vector(target) - Vector(mh)):normalized():perpendicular() * E.Range
                        local Position2 = Vector(mh) + Vector(Vector(target) - Vector(mh)):normalized():perpendicular2() * E.Range
                        if not Collides(Position) then
                            E:CastToVector(Position)
                        elseif not Collides(Position2) then
                            E:CastToVector(Position2)
                        else
                            E:CastToVector(Position)
                        end
                    end
                end)

    Menu:addSubMenu(cha.." - Misc Settings", "Misc")
        Menu.Misc:addParam("SetSkin", "Select Skin", SCRIPT_PARAM_LIST, 14, {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14"})

    Menu:addSubMenu(cha.." - Keys Settings", "Keys")
        OrbwalkManager:LoadCommonKeys(Menu.Keys)
        Menu.Keys:addParam("HarassToggle", "Harass (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))
        OrbwalkManager:AddKey({Name = "AssistedUltimate", Text = "Assisted Ultimate (Near Mouse)", Key = string.byte("T"), Mode = ORBWALK_MODE.COMBO})
        Menu.Keys:addParam("Flee", "Run Pussy Run", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("S"))
        Menu.Keys:permaShow("HarassToggle")
        Menu.Keys:permaShow("Flee")
        Menu.Keys.HarassToggle = false
        Menu.Keys.AssistedUltimate = false
        Menu.Keys.Flee = false

    Menu:addSubMenu(cha.." - BaseUlt Settings", "BaseUlt")
        Menu.BaseUlt:addParam("BaseUlt", "Enable base ult", 1, true)
        Menu.BaseUlt:addParam("BaseUltDraw", "Draw base ult", 1, true)
        Menu.BaseUlt:addParam("Verbose", "Track enemy recall in chat", 1, true)
end

--[[ Script Start ]]
function OnTick()
    if Menu == nil then return end
    TS:update()
    KillSteal()
    SetSkin(mh, Menu.Misc.SetSkin)
    RState = mh:CanUseSpell(_R) == READY
    if OrbwalkManager:IsCombo() then
        Combo()
    elseif OrbwalkManager:IsHarass() then
        Harass()
    elseif OrbwalkManager:IsClear() then
        Clear()
    elseif OrbwalkManager:IsLastHit() then
        LastHit()
    end
    if Menu.Keys.HarassToggle then Harass() end
    if Menu.Keys.Flee then Correr() end
    if Menu.Keys.AssistedUltimate then
        local BestEnemy = nil
        for idx, enemy in ipairs(GetEnemyHeroes()) do
            if R:ValidTarget(enemy) then
                if BestEnemy == nil then BestEnemy = enemy
                elseif GetDistanceSqr(mousePos, BestEnemy) > GetDistanceSqr(mousePos, enemy) then BestEnemy = enemy end
            end
        end
        if R:ValidTarget(BestEnemy) then
            R:Cast(BestEnemy)
        end
    end
end

--[[ Auto Lantern ]]
class "ThreshLantern"
function ThreshLantern:__init()
    self.lantern = nil
    AddTickCallback(function() self:OnTick() end)
    AddCreateObjCallback(function(a) self:OnCreateObj(a) end)
    AddDeleteObjCallback(function(a) self:OnDeleteObj(a) end)
end
function ThreshLantern:OnTick()
    if self.lantern ~= nil and LulzMenu.Hotkeys.FleeKey then
        if GetDistanceSqr(self.lantern) < 90000 then
            self.lantern:Interact()
        end
    end
end
function ThreshLantern:OnCreateObj(obj)
    if obj.name == "ThreshLantern" then
        self.lantern = obj
    end
end
function ThreshLantern:OnDeleteObj(obj)
    if obj.name == "ThreshLantern" then
        self.lantern = nil
    end
end
function Collides(vec)
    return IsWall(D3DXVECTOR3(vec.x, vec.y, vec.z))
end

--[[ Script Code ]]
function KillSteal()
    for idx, enemy in ipairs(GetEnemyHeroes()) do
        local ok = enemy.health/enemy.maxHealth <= 0.3
        if ValidTarget(enemy, TS.range) and enemy.health > 0 and ok then
            local q, w, e, r, dmg = GetBestCombo(enemy)
            if dmg >= enemy.health and not enemy.dead then
                if Menu.KillSteal.useQ and Q:Damage(enemy) >= enemy.health then Q:Cast(enemy) end
                if Menu.KillSteal.useW and W:Damage(enemy) >= enemy.health then W:Cast(enemy) end
                if Menu.KillSteal.useR and R:Damage(enemy) >= enemy.health then R:Cast(enemy) end
            end
            if Menu.KillSteal.useIgnite and Ignite:IsReady() and Ignite:Damage(enemy) >= enemy.health and not enemy.dead then Ignite:Cast(enemy) end
        end
    end
end

function Combo()
    local target = TS.target
    local q, w, e, r, dmg = GetBestCombo(target)
    if ValidTarget(target) then
        if Menu.Combo.Zhonyas > 0 and PercentageHealth() <= Menu.Combo.Zhonyas and DefensiveItems.Zhonyas:IsReady() and CountEnemyHeroInRange(600) >= 1 then
            DefensiveItems.Zhonyas:Cast()
        end
        if Menu.Combo.useE then
            CastSpell(_E, mousePos.x, mousePos.z)
        end
        if Menu.Combo.useQ then
            Q:Cast(target)
        end
        if Menu.Combo.useW then
            W:Cast(target)
        end
        if Menu.Combo.useR and target.health < R:Damage(target) + Q:Damage(target) + W:Damage(target) then
            R:Cast(target)
        end
        if Menu.Combo.useR2 > 0 then
            if R:IsReady() then
                for i, enemy in ipairs(GetEnemyHeroes()) do
                    local CastPosition, WillHit, NumberOfHits = R:GetPrediction(enemy, {TypeOfPrediction = "VPrediction"})
                    if NumberOfHits and type(NumberOfHits) == "number" and NumberOfHits >= Menu.Combo.useR2 and WillHit then
                        CastSpell(R.Slot, CastPosition.x, CastPosition.z)
                    end
                end
            end
        end
        UseItems(target)
    end
end

function Correr()
    local target = TS.target
    if Menu.Keys.Flee then
        mh:MoveTo(mousePos.x, mousePos.z)
    end
    if E:IsReady() then
        CastSpell(_E, mousePos.x, mousePos.z)
    end
end

function Harass()
    local target = TS.target
    local kek = mh.mana / mh.maxMana * 100 >= Menu.Harass.Mana
    if kek then
        if ValidTarget(target) then
            if Menu.Harass.useQ then
                Q:Cast(target)
            end
            if Menu.Harass.useW then
                W:Cast(target)
            end
        end
    end
end

function Clear()
    local kek = mh.mana / mh.maxMana * 100 >= Menu.Harass.Mana
    if kek then
        if Menu.LaneClear.useQ then
            Q:LaneClear()
        end
    end
    if Menu.JungleClear.useQ then
        Q:JungleClear()
    end
end

function LastHit()
    local kek = mh.mana/mh.maxMana * 100 >= Menu.LastHit.Mana
    if kek then
        Q:LastHit({Mode = Menu.LastHit.Q})
    end
end

function PercentageMana(u)
    local unit = u ~= nil and u or mh
    return unit and unit.mana/unit.maxMana * 100 or 0
end

function PercentageHealth(u)
    local unit = u ~= nil and u or mh
    return unit and unit.health/unit.maxHealth * 100 or 0
end


function GetOverkill()
    local over = (100 + Menu.Combo.Overkill)/100
    return over
end

function GetBestCombo(target)
    if not IsValidTarget(target) then return false, false, false, false, 0 end
    local q = {false}
    local w = {false}
    local e = {false}
    local r = {false}
    local damagetable = PredictedDamage[target.networkID]
    if damagetable ~= nil then
        local time = damagetable[6]
        local osc = os.clock()
        if osc - time <= RefreshTime then 
            return damagetable[1], damagetable[2], damagetable[3], damagetable[4], damagetable[5] 
        else
            if Q:IsReady() then q = {false, true} end
            if W:IsReady() then w = {false, true} end
            if E:IsReady() then e = {false, true} end
            if R:IsReady() then r = {false, true} end
            local bestdmg = 0
            local best = {Q:IsReady(), W:IsReady(), E:IsReady(), R:IsReady()}
            local dmg, mana = GetComboDamage(target, Q:IsReady(), W:IsReady(), E:IsReady(), R:IsReady() )
            bestdmg = dmg
            if dmg > target.health then
                for qCount = 1, #q do
                    for wCount = 1, #w do
                        for eCount = 1, #e do
                            for rCount = 1, #r do
                                local d, m = GetComboDamage(target, q[qCount], w[wCount], e[eCount], r[rCount])
                                if d >= target.health and mh.mana >= m then
                                    if d < bestdmg then 
                                        bestdmg = d 
                                        best = {q[qCount], w[wCount], e[eCount], r[rCount]} 
                                    end
                                end
                            end
                        end
                    end
                end
                --return best[1], best[2], best[3], best[4], bestdmg
                damagetable[1] = best[1]
                damagetable[2] = best[2]
                damagetable[3] = best[3]
                damagetable[4] = best[4]
                damagetable[5] = bestdmg
                damagetable[6] = os.clock()
            else
                local table2 = {false,false,false,false}
                local bestdmg, mana = 0, 0
                for qCount = 1, #q do
                    for wCount = 1, #w do
                        for eCount = 1, #e do
                            for rCount = 1, #r do
                                local d, m = GetComboDamage(target, q[qCount], w[wCount], e[eCount], r[rCount])
                                if d > bestdmg and mh.mana > m then 
                                    table2 = {q[qCount],w[wCount],e[eCount],r[rCount]}
                                    bestdmg = d
                                end
                            end
                        end
                    end
                end
                --return table2[1],table2[2],table2[3],table2[4], bestdmg
                damagetable[1] = table2[1]
                damagetable[2] = table2[2]
                damagetable[3] = table2[3]
                damagetable[4] = table2[4]
                damagetable[5] = bestdmg
                damagetable[6] = os.clock()
            end
            return damagetable[1], damagetable[2], damagetable[3], damagetable[4], damagetable[5]
        end
    else
        local dmg, mana = GetComboDamage(target, Q:IsReady(), W:IsReady(), E:IsReady(), R:IsReady())
        PredictedDamage[target.networkID] = {false, false, false, false, dmg, os.clock() - RefreshTime * 2}
        return GetBestCombo(target)
    end
end

function GetComboDamage(target, q, w, e, r)
    local comboDamage = 0
    local currentManaWasted = 0
    if IsValidTarget(target) then
        if q then
            comboDamage = comboDamage + Q:Damage(target)
            currentManaWasted = currentManaWasted + Q:Mana()
        end
        if w then
            comboDamage = comboDamage + W:Damage(target)
            currentManaWasted = currentManaWasted + W:Mana()
        end
        if e then
            comboDamage = comboDamage + E:Damage(target)
            currentManaWasted = currentManaWasted + E:Mana()
        end
        if r then
            comboDamage = comboDamage + R:Damage(target)
            currentManaWasted = currentManaWasted + R:Mana()
        end
        if Ignite:IsReady() then comboDamage = comboDamage + Ignite:Damage(target) end
        comboDamage = comboDamage + getDmg("AD", target, mh) * 2
    end
    comboDamage = comboDamage * GetOverkill()
    return comboDamage, currentManaWasted
end

function Cast_Item(item, target)
    if item.IsReady() and ValidTarget(target, item.Range) then
        if item.reqTarget then
            CastSpell(item.Slot(), target)
        else
            CastSpell(item.Slot())
        end
    end
end

function UseItems(unit)
    if ValidTarget(unit) then
        for _, item in pairs(CastableItems) do
            Cast_Item(item, unit)
        end
    end
end

--[[ Script Base Ult ]]
class "BaseUlt"
function BaseUlt:__init()
    self.enemyHeros = GetEnemyHeroes()
    self.print,self.PrintChat = _G.print, _G.PrintChat
    self.manaPercent = nil
    self.castTime = 0
    self.SpellTable = {
       				  R = {range = 9999, speed = 2000, delay = 1, width = 150, collision = false}
   					  }
    self.spellDmg = {
         			[_R] = function(unit) return mh:CalcMagicDamage(unit, ((((mh:GetSpellData(_R).level * 150) + 200) + (mh.ap * 0.9)) + mh.addDamage)) end
    				}
    self.BaseSpots = {
             		 D3DXVECTOR3(396,182.132,462),
            		 D3DXVECTOR3(14340.418,171.9777,14391.075)
        			 }
    self.recallStatus = {}
    self.recallTimes = {
        			   ['recall'] = 7.9,
        			   ['odinrecall'] = 4.4,
        			   ['odinrecallimproved'] = 3.9,
        			   ['recallimproved'] = 6.9,
        			   ['superrecall'] = 3.9,
    				   }
    self.activeRecalls = {}
    self.lasttime={}

    for i, enemy in pairs(self.enemyHeros) do
        self.recallStatus[enemy.charName] = enemy.recall
    end
    AddDrawCallback(function() self:DrawBaseUlt() end)
    AddTickCallback(function() self:BaseUlt() end)
    AddTickCallback(function()
        for i, enemy in pairs(self.enemyHeros) do
            if enemy.recall ~= self.recallStatus[enemy.charName] then
                self:recallFunction(enemy, enemy.recall)
            end
            self.recallStatus[enemy.charName] = enemy.recall
        end
    end)
end

function BaseUlt:BaseUltGetBaseCoords()
	local okey = mh.team == 100
    if okey then
        return self.BaseSpots[2]
    else
        return self.BaseSpots[1]
    end
end
function BaseUlt:GetDamage(spell, unit)
    if spell == "ALL" then
        local sum = 0
          for spell, func in pairs(self.spellDmg) do
            sum = sum + (func(unit) or 0)
          end
         return sum
       else
          return self.spellDmg[spell](unit) or 0
       end
end
function BaseUlt:BaseUltPredictIfUltCanKill(target)
	if self:GetDamage(_R, target.object) > target.startHP + (target.hpRegen * 7.9)  then
		return true
	else
		return false
	end
end
function BaseUlt:BaseUlt()
    if not mh.dead and Menu.BaseUlt.BaseUlt then
        self.time = GetDistance(mh, self.BaseSpots[2]) / 2000
        for i, snipeTarget in pairs(self.activeRecalls) do
            if (snipeTarget.endT - os.clock()) <= self.time + 1 and (snipeTarget.endT - os.clock()) >= self.time + .5 and self:BaseUltPredictIfUltCanKill(snipeTarget) then
                CastSpell(_R, self:BaseUltGetBaseCoords().x, self:BaseUltGetBaseCoords().z)
            end
        end
    end
end
function BaseUlt:recallFunction(Hero, Status)
    local o = Hero
    if o and o.valid and o.type == 'AIHeroClient' then
        local str = Status
        if self.recallTimes[str:lower()] then
            if Menu.BaseUlt.Verbose then
                if not o.visible and self.lasttime[o.networkID]  then
                    print(r.name.." is recalling. Last seen "..string.format("%.1f", os.clock() -self.lasttime[o.networkID], 1).." seconds ago." )
                end
            end
            self.activeRecalls[o.networkID] = {
                                name = o.charName,
                                startT = os.clock(),
                                duration = self.recallTimes[str:lower()],
                                endT = os.clock() + self.recallTimes[str:lower()],
                                startHP = o.health,
                                hpRegen = o.hpRegen,
                                object = o
                           		}
            return
        elseif self.activeRecalls[o.networkID] then
            if self.activeRecalls[o.networkID] and self.activeRecalls[o.networkID].endT > os.clock() then
                if Menu.BaseUlt.Verbose then
                    print(self.activeRecalls[o.networkID].name.." canceled recall")
                end
                recallTime = nil
                recallName = nil
                blockName = nil
                self.activeRecalls[o.networkID] = nil
                return
            else
                if junglerName == self.activeRecalls[o.networkID].name then
                    jungleText = "Recalled"
                end
                if Menu.BaseUlt.Verbose then
                    print(self.activeRecalls[o.networkID].name.." finished recall")
                end
                self.activeRecalls[o.networkID] = nil
                recallTime = nil
                recallName = nil
                blockName = nil
                return
            end
        end
    end
end
function BaseUlt:DrawBaseUlt()
    local function ReturnColor(color) return ARGB(color[1],color[2],color[3],color[4]) end
    local function BaseUltProgressBar(x, y, percent, text, tick)
        DrawRectangle(x, y - 5, 300, 40, ARGB(255,100,100,100))
        DrawRectangle(x + 5, y, 290, 30, ARGB(255,30,30,30))
        DrawRectangle(x + 5, y, (percent/100)*290, 30, ARGB(255,255,0,0))
        DrawRectangle(x + (6.9 / 7.9 * 290), y, (100/100)*290 - x + (6.9 / 7.9 * 290), 30, ARGB(100,30,30,30))
        if tick <= 100 then
            DrawRectangle(x + 5 + (tick/100)*290, y, 2, 30, ARGB(255,0,255,0))
        else
            DrawRectangle(x + 5 + (100/100)*290, y, 2, 30, ARGB(255,0,255,0))
        end
        DrawText(text,20,y + 8,x + 5,ARGB(255,255,255,255))
    end
    
    if Menu.BaseUlt.BaseUlt and Menu.BaseUlt.BaseUltDraw then
        for i, enemy in pairs(self.activeRecalls) do
             if self:BaseUltPredictIfUltCanKill(enemy) then
                 BaseUltProgressBar(500,500,(enemy.endT - os.clock()) / 7.9 * 100, enemy.name, ((GetDistance(mh, self:BaseUltGetBaseCoords()) / 2000) + 1) / 8 * 100)
             end
        end
    end
end

--[[ Script S1mple Lib ]]
class "_Required"
function _Required:__init()
    self.requirements = {}
    self.downloading = {}
    return self
end

function _Required:Add(t)
    assert(t and type(t) == "table", "_Required: table is invalid!")
    local name = t.Name
    assert(name and type(name) == "string", "_Required: name is invalid!")
    local url = t.Url
    assert(url and type(url) == "string", "_Required: url is invalid!")
    local extension = t.Extension ~= nil and t.Extension or "lua"
    local usehttps = t.UseHttps ~= nil and t.UseHttps or true
    table.insert(self.requirements, {Name = name, Url = url, Extension = extension, UseHttps = usehttps})
end

function _Required:Check()
    for i, tab in pairs(self.requirements) do
        local name = tab.Name
        local url = tab.Url
        local extension = tab.Extension
        local usehttps = tab.UseHttps
        if not FileExist(LIB_PATH..name.."."..extension) then
            print("Downloading a required library called "..name.. ". Please wait...")
            local d = _Downloader(tab)
            table.insert(self.downloading, d)
        end
    end
    
    if #self.downloading > 0 then
        for i = 1, #self.downloading, 1 do 
            local d = self.downloading[i]
            AddTickCallback(function() d:Download() end)
        end
        self:CheckDownloads()
    else
        for i, tab in pairs(self.requirements) do
            local name = tab.Name
            local url = tab.Url
            local extension = tab.Extension
            local usehttps = tab.UseHttps
            if FileExist(LIB_PATH..name.."."..extension) and extension == "lua" then
                require(name)
            end
        end
    end
end

function _Required:CheckDownloads()
    if #self.downloading == 0 then 
        print("Required libraries downloaded. Please reload with 2x F9.")
    else
        for i = 1, #self.downloading, 1 do
            local d = self.downloading[i]
            if d.GotScript then
                table.remove(self.downloading, i)
                break
            end
        end
        DelayAction(function() self:CheckDownloads() end, 2) 
    end 
end

function _Required:IsDownloading()
    return self.downloading ~= nil and #self.downloading > 0 or false
end

class "_Downloader"
function _Downloader:__init(t)
    local name = t.Name
    local url = t.Url
    local extension = t.Extension ~= nil and t.Extension or "lua"
    local usehttps = t.UseHttps ~= nil and t.UseHttps or true
    self.SavePath = LIB_PATH..name.."."..extension
    self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(usehttps and '5' or '6')..'.php?script='..self:Base64Encode(url)..'&rand='..math.random(99999999)
    self:CreateSocket(self.ScriptPath)
    self.DownloadStatus = 'Connect to Server'
    self.GotScript = false
end

function _Downloader:CreateSocket(url)
    if not self.LuaSocket then
        self.LuaSocket = require("socket")
    else
        self.Socket:close()
        self.Socket = nil
        self.Size = nil
        self.RecvStarted = false
    end
    self.Socket = self.LuaSocket.tcp()
    if not self.Socket then
        print('Socket Error')
    else
        self.Socket:settimeout(0, 'b')
        self.Socket:settimeout(99999999, 't')
        self.Socket:connect('sx-bol.eu', 80)
        self.Url = url
        self.Started = false
        self.LastPrint = ""
        self.File = ""
    end
end

function _Downloader:Download()
    if self.GotScript then return end
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading Script (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</si'..'ze>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading Script (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
        local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
            local newf = newf:gsub('\r','')
            if newf:len() ~= self.Size then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
                return
            end
            local newf = Base64Decode(newf)
            if type(load(newf)) ~= 'function' then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
            else
                local f = io.open(self.SavePath,"w+b")
                f:write(newf)
                f:close()
                if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                    self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
                end
            end
        end
        self.GotScript = true
    end
end

function _Downloader:Base64Encode(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

--[[ Script Autodownloader ]]
	function Update()
		if AUTOUPDATE then
			local ServerData = GetWebResult(UPDATE_HOST, "/vankatze/vktz/master/The-nabo.version")
				if ServerData then
					ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
						if ServerVersion then
							if tonumber(version) < ServerVersion then
								DelayAction(function() print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">New version found for The Nabo... <font color=\"#000000\"> | </font><font color=\"#FF0000\"></font><font color=\"#FF0000\"><b> Version "..ServerVersion.."</b></font>") end, 3)
								DelayAction(function() print("<font color=\"#FFFFFF\"><b> >> Updating, please don't press F9 << </b></font>") end, 4)
								DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">The Nabo</font> <font color=\"#000000\"> | </font><font color=\"#FF0000\">UPDATED <font color=\"#FF0000\"><b>("..version.." => "..ServerVersion..")</b></font> Press F9 twice to load the updated version.") end) end, 5)
							else
								DelayAction(function() print("<b><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">The Nabo</font><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FF0000\"> Version "..ServerVersion.."</b></font>") end, 1)
								end
						end
					else
				DelayAction(function() print("<font color=\"#FFFFFF\">The Nabo - Error while downloading version info, RE-DOWNLOAD MANUALLY.</font>")end, 1)
			end
		end
	end
