--[[ Script AutoUpdater ]]
 local version = "1"
 local author = "Vankatze"
 local SCRIPT_NAME = "The-nabo"
 local AUTOUPDATE = true
 local UPDATE_HOST = "raw.githubusercontent.com"
 local ran = math.random
 local UPDATE_PATH = "/vankatze/vktz/edit/master/The-nabo.lua".."?rand="..ran(3500,5500)
 local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
 local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local cha = myHero.charName

if cha ~= "Ezreal" then return end

function OnLoad() Menu() Skills()
    print("<b><font color="#ff0077">EzzY - The true Nabo : </font></b><font color="#ffcb0f"> Funny for you ! </font><font color="#ff0077">| Vankatze |</font>")
    local r = _Required()
    local sb = string.byte

    r:Add({Name = "SimpleLib", Url = "raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua"})
    r:Check()

    if r:IsDownloading() then return end
    if OrbwalkManager == nil then print("Check your SimpleLib file, isn't working... The script can't load without SimpleLib. Try to copy-paste the entire SimpleLib.lua on your common folder.") return end
  
    DelayAction(function() CheckUpdate() end, 5)
    DelayAction(function() _arrangePriorities() end, 10)
    
    inload = false
end

function Menu()
ts = _SimpleTargetSelector(TARGET_LESS_CAST_PRIORITY, 1400, DAMAGE_MAGIC)
end

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



--[[ AutoUpdater by Jaikor ]]
    function Update()
        if AUTOUPDATE then
            local ServerData = GetWebResult(UPDATE_HOST, "/RK1K/RKScriptFolder/master/RKBundle.version")
                if ServerData then
                    ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
                        if ServerVersion then
                            if tonumber(version) < ServerVersion then
                                DelayAction(function() print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">New version found for RK Utility... <font color=\"#000000\"> | </font><font color=\"#FF0000\"></font><font color=\"#FF0000\"><b> Version "..ServerVersion.."</b></font>") end, 3)
                                DelayAction(function() print("<font color=\"#FFFFFF\"><b> >> Updating, please don't press F9 << </b></font>") end, 4)
                                DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">RK Utility</font> <font color=\"#000000\"> | </font><font color=\"#FF0000\">UPDATED <font color=\"#FF0000\"><b>("..version.." => "..ServerVersion..")</b></font> Press F9 twice to load the updated version.") end) end, 5)
                            else
                                DelayAction(function() print("<b><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">RK Utility</font><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FF0000\"> Version "..ServerVersion.."</b></font>") end, 1)
                                end
                        end
                    else
                DelayAction(function() print("<font color=\"#FFFFFF\">RK Utility - Error while downloading version info, RE-DOWNLOAD MANUALLY.</font>")end, 1)
            end
        end
    end

function OnTick()
	if inload then return end

	TargetSelector:update()
	Target = GetCustomTarget()

	if Sx then
		SxOrb:ForceTarget(Target)
	end
	if SAC then
		if _G.AutoCarry.Keys.AutoCarry then
			_G.AutoCarry.Orbwalker:Orbwalk(Target)
		end
	end
	KillSteall()
	Checks()


	ComboKey = Settings.combo.comboKey

	if ComboKey then
		Combo(Target)
	end

	if (Settings.harass.toggle or Settings.harass.key) and not ComboKey then
		Harass(Target)
	end

	if (Settings.laneclear.toggle or Settings.laneclear.key) and not ComboKey then
		LaneClear()
	end
end

function LaneClear()
	enemyMinions:update()
	if not IsMyManaLowLaneClear() then
		for i, minion in pairs(enemyMinions.objects) do
			if ValidTarget(minion) and minion ~= nil then
				if Settings.laneclear.useQ and GetDistance(minion) <= SkillQ.range and SkillQ.ready then
					CastSpell(_Q, minion.x, minion.z)
				end
			end		 
		end
	end
end

function Harass(unit)
	if ValidTarget(unit) and unit ~= nil and unit.type == myHero.type and not IsMyManaLowHarass() then
	
		if Settings.harass.useQ then 
			CastQ(unit)
		end	

		if Settings.harass.useW then
			CastW(unit)
		end
	end
end

function Combo(unit)
	if ValidTarget(unit) and unit ~= nil and unit.type == myHero.type then
	
		if Settings.combo.useQ then 
			CastQ(unit)
		end	
		if Settings.combo.useW then 
			CastW(unit)
		end	

		if Settings.combo.RifKilable then
				local dmgR = getDmg("R", unit, myHero) + ((myHero.damage)*0.44) + ((myHero.ap)*0.9)
				if unit.health < dmgR then
					CastR(unit)
				end
		end
	end
end

function KillSteall()
	for _, unit in pairs(GetEnemyHeroes()) do
		local health = unit.health
		local dmgW = getDmg("W", unit, myHero) + ((myHero.ap)*0.8)
		local dmgQ = getDmg("Q", unit, myHero) + ((myHero.damage)*1.1) + ((myHero.ap)*0.4)
			if health < dmgW and Settings.killsteal.useW and ValidTarget(unit) then
				CastW(unit)
			end
			if health < dmgQ and Settings.killsteal.useQ and ValidTarget(unit) then
				CastQ(unit)
			end
	 end
end

function IsMyManaLowLaneClear()
    if myHero.mana < (myHero.maxMana * ( Settings.laneclear.mManager / 100)) then
        return true
    else
        return false
    end
end

function IsMyManaLowHarass()
    if myHero.mana < (myHero.maxMana * ( Settings.harass.mManager / 100)) then
        return true
    else
        return false
    end
end

function Checks()
	SkillQ.ready = (myHero:CanUseSpell(_Q) == READY)
	SkillW.ready = (myHero:CanUseSpell(_W) == READY)
	SkillR.ready = (myHero:CanUseSpell(_R) == READY)
	
	if Settings.drawing.lfc.lfc then 
		_G.DrawCircle = DrawCircle2 
	else 
		_G.DrawCircle = _G.oldDrawCircle 
	end
end

function GetCustomTarget()
	if SelectedTarget ~= nil and ValidTarget(SelectedTarget, 1500) then
		return SelectedTarget
	end
	TargetSelector:update()	
	if TargetSelector.target and not TargetSelector.target.dead and TargetSelector.target.type == myHero.type then
		return TargetSelector.target
	else
		return nil
	end
end

function CastQ(unit)
	if unit ~= nil and GetDistance(unit) <= SkillQ.range and SkillQ.ready then
		CastPosition,  HitChance,  Position = VP:GetLineCastPosition(unit, SkillQ.delay, SkillQ.width, SkillQ.range, SkillQ.speed, myHero, true)
				
		if HitChance >= 2 then
			CastSpell(_Q, CastPosition.x, CastPosition.z)
		end
	end
end

function CastW(unit)
	if unit ~= nil and GetDistance(unit) <= SkillW.range and SkillW.ready then
		CastPosition,  HitChance,  Position = VP:GetLineCastPosition(unit, SkillW.delay, SkillW.width, SkillW.range, SkillW.speed, myHero, false)
				
		if HitChance >= 2 then
			CastSpell(_W, CastPosition.x, CastPosition.z)
		end
	end
end

function CastR(unit)
	if unit ~= nil and SkillR.ready then
		CastPosition,  HitChance,  Position = VP:GetLineAOECastPosition(unit, SkillR.delay, SkillR.width, SkillR.range, SkillR.speed, myHero)
				
		if HitChance >= 2 then
			CastSpell(_R, CastPosition.x, CastPosition.z)
		end
	end
end

function OnProcessSpell(unit, spell)
	if table.contains(GapCloserList, spell.name) and Settings.antigap.useE then
		if (spell and spell.target and spell.target.isMe or GetDistance(spell.endPos or Geometry.Vector3(0,0,0) <= myHero.boundingRadius + 10)) then 
			local jmpToPos = Target + (Vector(myHero) - Target):normalized() * 2000
			CastSpell(_E, jmpToPos.x , jmpToPos.z)
		end
	end
end

function Skills()
	SkillQ = { name = "Mystic Shot", range = 1150, delay = 0.25, speed = 2000, width = 60, ready = false }
	SkillW = { name = "Essence Flux", range = 950, delay = 0.25, speed = 1600, width = 80, ready = false }
	SkillE = { name = "Arcane Shift", range = 475, delay = nil, speed = nil, width = nil, ready = false }
	SkillR = { name = "Trueshot Barrage", range = math.huge, delay = 1.0, speed = 2000, width = 160, ready = false }

	GapCloserList = {
			"LeonaZenithBlade",
			"AatroxQ",
			"AkaliShadowDance",
			"Headbutt",
			"FioraQ",
			"DianaTeleport",
			"EliseSpiderQCast",
			"FizzPiercingStrike",
			"GragasE",
			"HecarimUlt",
			"JarvanIVDragonStrike",
			"IreliaGatotsu",
			"JaxLeapStrike",
			"KhazixE",
			"khazixelong",
			"LeblancSlide",
			"LeblancSlideM",
			"BlindMonkQTwo",
			"LeonaZenithBlade",
			"UFSlash",
			"Pantheon_LeapBash",
			"PoppyHeroicCharge",
			"RenektonSliceAndDice",
			"RivenTriCleave",
			"SejuaniArcticAssault",
			"slashCast",
			"ViQ",
			"MonkeyKingNimbus",
			"XenZhaoSweep",
			"YasuoDashWrapper"
		}

	enemyMinions = minionManager(MINION_ENEMY, SkillQ.range, myHero, MINION_SORT_HEALTH_ASC)

	lastSkin = 0
	
	_G.oldDrawCircle = rawget(_G, 'DrawCircle')
	_G.DrawCircle = DrawCircle2
end

function Menu()
	Settings = scriptConfig("| Ezreal - The true carry |", "Linkpad")
	
	Settings:addSubMenu("["..myHero.charName.."] - Combo Settings", "combo")
		Settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		Settings.combo:addParam("useQ", "Use (Q) in Combo", SCRIPT_PARAM_ONOFF, true)
		Settings.combo:addParam("useW", "Use (W) in Combo", SCRIPT_PARAM_ONOFF, true)
		Settings.combo:addParam("RifKilable", "Use (R) if enemy is kilable", SCRIPT_PARAM_ONOFF, true)
		
	Settings:addSubMenu("["..myHero.charName.."] - AntiGap Closer", "antigap")
		Settings.antigap:addParam("useE", "Use (E)", SCRIPT_PARAM_ONOFF, true)

	Settings:addSubMenu("["..myHero.charName.."] - KillSteal", "killsteal")
		Settings.killsteal:addParam("useQ", "Steal With (Q)", SCRIPT_PARAM_ONOFF, true)
		Settings.killsteal:addParam("useW", "Steal With (W)", SCRIPT_PARAM_ONOFF, true)

	Settings:addSubMenu("["..myHero.charName.."] - Harass", "harass")
		Settings.harass:addParam("key", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		Settings.harass:addParam("toggle", "Toggle Harass", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("L"))
		Settings.harass:addParam("useQ", "Harass With (Q)", SCRIPT_PARAM_ONOFF, true)
		Settings.harass:addParam("useW", "Harass With (W)", SCRIPT_PARAM_ONOFF, true)
		Settings.harass:addParam("mManager", "Min. Mana To Harass", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)

	Settings:addSubMenu("["..myHero.charName.."] - Lane Clear", "laneclear")
		Settings.laneclear:addParam("key", "Lane Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
		Settings.laneclear:addParam("toggle", "Toggle Lane Clear", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("T"))
		Settings.laneclear:addParam("useQ", "Lane Clear With (Q)", SCRIPT_PARAM_ONOFF, true)
		Settings.laneclear:addParam("mManager", "Min. Mana To Lane Clear", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
		
	Settings.combo:permaShow("comboKey")
	Settings.combo:permaShow("RifKilable")
	Settings.killsteal:permaShow("useQ")
	Settings.killsteal:permaShow("useW")
	Settings.harass:permaShow("toggle")
	Settings.laneclear:permaShow("toggle")
	
	
	Settings:addSubMenu("["..myHero.charName.."] - Draw Settings", "drawing")	
		Settings.drawing:addParam("mDraw", "Disable All Range Draws", SCRIPT_PARAM_ONOFF, false)
		Settings.drawing:addParam("myHero", "Draw My Range", SCRIPT_PARAM_ONOFF, true)
		Settings.drawing:addParam("myColor", "Draw My Range Color", SCRIPT_PARAM_COLOR, {255, 100, 44, 255})
		Settings.drawing:addParam("qDraw", "Draw "..SkillQ.name.." (Q) Range", SCRIPT_PARAM_ONOFF, true)
		Settings.drawing:addParam("qColor", "Draw "..SkillQ.name.." (Q) Color", SCRIPT_PARAM_COLOR, {255, 100, 44, 255})
		Settings.drawing:addParam("wDraw", "Draw "..SkillW.name.." (W) Range", SCRIPT_PARAM_ONOFF, true)
		Settings.drawing:addParam("wColor", "Draw "..SkillW.name.." (W) Color", SCRIPT_PARAM_COLOR, {255, 100, 44, 255})
		Settings.drawing:addParam("tColor", "Draw Target Color", SCRIPT_PARAM_COLOR, {255, 100, 44, 255})
		Settings.drawing:addParam("tText", "Draw Current Target Text", SCRIPT_PARAM_ONOFF, true)

	Settings.drawing:addSubMenu("Lag Free Circles", "lfc")	
		Settings.drawing.lfc:addParam("lfc", "Lag Free Circles", SCRIPT_PARAM_ONOFF, false)
		Settings.drawing.lfc:addParam("CL", "Quality", 4, 75, 75, 2000, 0)
		Settings.drawing.lfc:addParam("Width", "Width", 4, 1, 1, 10, 0)


	Settings:addSubMenu("["..myHero.charName.."] - Orbwalking Settings", "Orbwalking")
	if Sx then
		SxOrb:LoadToMenu(Settings.Orbwalking)
	else
		Settings.Orbwalking:addParam("info","SAC Detected", SCRIPT_PARAM_INFO, "")
	end

	Settings:addTS(TargetSelector)
end

function OnDraw()
	if inload then return end

	if not myHero.dead and not Settings.drawing.mDraw then
		if SkillQ.ready and Settings.drawing.qDraw then 
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillQ.range, RGB(Settings.drawing.qColor[2], Settings.drawing.qColor[3], Settings.drawing.qColor[4]))
		end
		if SkillW.ready and Settings.drawing.wDraw then 
			DrawCircle(myHero.x, myHero.y, myHero.z, SkillW.range, RGB(Settings.drawing.wColor[2], Settings.drawing.wColor[3], Settings.drawing.wColor[4]))
		end
		
		if Settings.drawing.myHero then
			
			DrawCircle(myHero.x, myHero.y, myHero.z, myHero.range + GetDistance(myHero, myHero.minBBox), RGB(Settings.drawing.myColor[2], Settings.drawing.myColor[3], Settings.drawing.myColor[4]))
		end

		if Target ~= nil and ValidTarget(Target) then
			if Settings.drawing.tText then
				DrawText3D("Current Target",Target.x-100, Target.y-50, Target.z, 20, 0xFFFFFF00)
			end
			DrawCircle(Target.x, Target.y, Target.z, 200, RGB(Settings.drawing.tColor[2], Settings.drawing.tColor[3], Settings.drawing.tColor[4]))
		end
	end
end

function OnWndMsg(Msg, Key)
	if inload then return end
	if Msg == WM_LBUTTONDOWN then
		local minD = 0
		local starget = nil
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				if GetDistance(enemy, mousePos) <= minD or starget == nil then
					minD = GetDistance(enemy, mousePos)
					starget = enemy
				end
			end
		end
		
		if starget and minD < 500 then
			if SelectedTarget and starget.charName == SelectedTarget.charName then
				SelectedTarget = nil
			else
				SelectedTarget = starget
			end
		end
	end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
  radius = radius or 300
  quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
  quality = 2 * math.pi / quality
  radius = radius*.92
  
  local points = {}
  for theta = 0, 2 * math.pi + quality, quality do
    local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
    points[#points + 1] = D3DXVECTOR2(c.x, c.y)
  end
  
  DrawLines2(points, width or 1, color or 4294967295)
end

function round(num) 
  local kek = math.floor(num+.5)
  local kok =  math.ceil(num-.5)
  if num >= 0 then return kek else return kok end
end

function DrawCircle2(x, y, z, radius, color)
  local vPos1 = Vector(x, y, z)
  local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
  local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
  local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))

  if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
    DrawCircleNextLvl(x, y, z, radius, Settings.drawing.lfc.Width, color, Settings.drawing.lfc.CL) 
  end
end
