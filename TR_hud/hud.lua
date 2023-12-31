local sx, sy = guiGetScreenSize()
local zoom = 1
local baseX = 1900
local minZoom = 2
if sx < baseX then
	zoom = math.min(minZoom, baseX/sx)
end

local guiInfo = {
	hud = {
		x = sx - 280/zoom,
		y = 60/zoom,
		w = 150/zoom,
		h = 90/zoom,
	},

	bar = {
		w = 235/zoom,
		h = 19/zoom,
	},

	weekDays = {
		[0] = "Niedz.",
		[1] = "Pon.",
		[2] = "Wt.",
		[3] = "Śr.",
		[4] = "Czw.",
		[5] = "Pt.",
		[6] = "Sob."
	},

	bars = {
		{name = "hp", img = dxCreateTexture("files/images/hud/heart.png", "argb", true, "clamp"), percentage = 1},
		{name = "armor", img = dxCreateTexture("files/images/hud/armor.png", "argb", true, "clamp"), percentage = 0},
		{name = "oxygen", img = dxCreateTexture("files/images/hud/oxygen.png", "argb", true, "clamp"), percentage = 0},
	},

	speedo = {
		x = sx - 380/zoom,
		y = sy - 370/zoom,
		w = 380/zoom,
		h = 380/zoom,

		alpha = 0,
		startRot = -151,
		maxRot = 100,
		speedDowngrade = 0.84,

		mileageHeight = 240,
		mileageInfo = {},
	},

	version = "1.0.2",
}

function renderServerVersion()
	dxDrawText(string.format("Just Play v%s |", guiInfo.version), sx, sy, sx - 83, sy + 1, tocolor(255, 255, 255, 110), 1, "default", "right", "bottom")
end
addEventHandler("onClientRender", root, renderServerVersion, false, "low-1")

HUD = {}
HUD.__index = HUD

function HUD:create()
	local instance = {}
	setmetatable(instance, HUD)
	if instance:constructor() then
		return instance
	end
	return false
end

function HUD:constructor()
	self.inputeMode = getTickCount()

	self.textures = {}
	self.textures.bar = dxCreateTexture("files/images/hud/bar_bg.png", "argb", true, "clamp")

	self.fonts = {}
	self.fonts.speed = exports.TR_dx:getFont(46)
	self.fonts.race = exports.TR_dx:getFont(40, "myriadBold")
	self.fonts.mileage = exports.TR_dx:getFont(22)
	self.fonts.money = exports.TR_dx:getFont(16)
	self.fonts.name = exports.TR_dx:getFont(13)
	self.fonts.speedoBig = exports.TR_dx:getFont(11)
	self.fonts.speedo = exports.TR_dx:getFont(10)
	self.fonts.role = exports.TR_dx:getFont(10)
	self.fonts.info = exports.TR_dx:getFont(7)

	self.fonts.digitalUltraLarge = dxCreateFont("files/fonts/digital.ttf", 42, true)
	self.fonts.digitalLarge = dxCreateFont("files/fonts/digital.ttf", 28)
	self.fonts.digitalSmall = dxCreateFont("files/fonts/digital.ttf", 14)

	self.func = {}
	self.func.render = function() self:render() end

	addEventHandler("onClientRender", root, self.func.render)

	-- Load speedo on restart
	local veh = getPedOccupiedVehicle(localPlayer)
	if veh then triggerServerEvent("getVehicleSpeedoData", resourceRoot, localPlayer, veh) end
	return true
end

function HUD:updateData()
	local data = getElementData(localPlayer, "characterData")
	if not data then
		self.money = 0
		return
	end
	self.money = data.money and data.money or 0
end


function HUD:animate()
	if not settings.tick then return end
	local progress = (getTickCount() - settings.tick)/settings.hudSpeedAnim

	if settings.state == "opening" then
		settings.alpha = interpolateBetween(settings.currAlpha, 0, 0, 1, 0, 0, progress, "Linear")
		if progress >= 1 then
			settings.alpha = 1
			settings.state = "opened"
			settings.tick = nil
			settings.currAlpha = nil
		end

	elseif settings.state == "closing" then
		settings.alpha = interpolateBetween(settings.currAlpha, 0, 0, 0, 0, 0, progress, "Linear")
		if progress >= 1 then
			settings.alpha = 0
			settings.state = "closed"
			settings.tick = nil
			settings.currAlpha = nil
		end
	end
end

function HUD:animateSpeedometer()
	if not guiInfo.speedo.tick then return end
	local progress = (getTickCount() - guiInfo.speedo.tick)/500

	if guiInfo.speedo.state == "opening" then
		guiInfo.speedo.alpha = interpolateBetween(guiInfo.speedo.currAlpha, 0, 0, 1, 0, 0, progress, "Linear")
		if progress >= 1 then
			guiInfo.speedo.alpha = 1
			guiInfo.speedo.state = "opened"
			guiInfo.speedo.tick = nil
			guiInfo.speedo.currAlpha = nil
		end

  elseif guiInfo.speedo.state == "closing" then
	guiInfo.speedo.alpha = interpolateBetween(guiInfo.speedo.currAlpha, 0, 0, 0, 0, 0, progress, "Linear")
		if progress >= 1 then
			guiInfo.speedo.alpha = 0
			guiInfo.speedo.state = "closed"
			guiInfo.speedo.tick = nil
			guiInfo.speedo.currAlpha = nil

			guiInfo.speedo.vehicle = nil
			guiInfo.speedo.vehicleData = nil
			guiInfo.speedo.updateTick = nil
			guiInfo.speedo.checkTick = nil
		end
	end
end


function HUD:render()
	self:updateInputMode()
	self:renderNametags()

	if settings.blockHud then return end
	self:animate()

	if settings.hudRaceMode then
		self:renderRaceGUI()
	else
		self:renderGUI()
	end
	self:renderSpeedometer()

	self:checkHourGift()

	self:calculateVehicleData()

	self:renderFPS()
end


function HUD:renderFPS()
	if settings.blockFPS then return end

	drawTextHardShadowed(string.format("%d FPS", getCurrentFPS()), 0, 0, sx - 5/zoom, sy - 20/zoom, tocolor(200, 200, 200, 255 * settings.alpha), 1/zoom, self.fonts.role, "right", "top")
end

function HUD:updateInputMode()
	if (getTickCount() - self.inputeMode)/10000 >= 1 then
		self.inputeMode = getTickCount()
		guiSetInputMode("no_binds_when_editing")
	end
end


function HUD:renderRaceGUI()
	if settings.hudRaceMode == "Sprint" or settings.hudRaceMode == "Drag" then
		drawTextShadowed("CZAS WYŚCIGU", guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.money, "right", "bottom")
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom + 1, guiInfo.hud.y + 2/zoom + 1, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(0, 0, 0, 40))
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom, guiInfo.hud.y + 2/zoom, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(255, 255, 255, 255))
		if settings.hudRaceTick then
			drawTextShadowed(getTimeInSeconds(getTickCount() - settings.hudRaceTick), guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		else
			drawTextShadowed(getTimeInSeconds(), guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		end


		drawTextShadowed("PROCENT TRASY", guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y + 115/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.money, "right", "bottom")
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom + 1, guiInfo.hud.y + 117/zoom + 1, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(0, 0, 0, 40))
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom, guiInfo.hud.y + 117/zoom, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(255, 255, 255, 255))
		if settings.hudRaceDetails then
			drawTextShadowed(settings.hudRaceDetails.percent.."%", guiInfo.hud.x, guiInfo.hud.y + 115/zoom, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		else
			drawTextShadowed("0%", guiInfo.hud.x, guiInfo.hud.y + 115/zoom, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		end

	elseif settings.hudRaceMode == "Okrążenia" then
		drawTextShadowed("CZAS WYŚCIGU", guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.money, "right", "bottom")
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom + 1, guiInfo.hud.y + 2/zoom + 1, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(0, 0, 0, 40))
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom, guiInfo.hud.y + 2/zoom, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(255, 255, 255, 255))
		if settings.hudRaceTick then
			drawTextShadowed(getTimeInSeconds(getTickCount() - settings.hudRaceTick), guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		else
			drawTextShadowed(getTimeInSeconds(), guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		end

		drawTextShadowed("TOP OKRĄŻENIE", guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y + 115/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.money, "right", "bottom")
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom + 1, guiInfo.hud.y + 117/zoom + 1, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(0, 0, 0, 40))
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom, guiInfo.hud.y + 117/zoom, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(255, 255, 255, 255))
		if settings.hudRaceDetails then
			drawTextShadowed(getTimeInSeconds(settings.hudRaceDetails.bestTime or 0), guiInfo.hud.x, guiInfo.hud.y + 115/zoom, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		else
			drawTextShadowed("00:00.000", guiInfo.hud.x, guiInfo.hud.y + 115/zoom, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		end

		drawTextShadowed("ILOŚĆ OKRĄŻEŃ", guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y + 230/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.money, "right", "bottom")
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom + 1, guiInfo.hud.y + 232/zoom + 1, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(0, 0, 0, 40))
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom, guiInfo.hud.y + 232/zoom, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(255, 255, 255, 255))
		if settings.hudRaceDetails then
			drawTextShadowed(string.format("%d/%d", settings.hudRaceDetails.lap, settings.hudRaceDetails.laps), guiInfo.hud.x, guiInfo.hud.y + 230/zoom, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		else
			drawTextShadowed("?/?", guiInfo.hud.x, guiInfo.hud.y + 230/zoom, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		end

	elseif settings.hudRaceMode == "Drift" then
		drawTextShadowed("CZAS WYŚCIGU", guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.money, "right", "bottom")
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom + 1, guiInfo.hud.y + 2/zoom + 1, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(0, 0, 0, 40))
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom, guiInfo.hud.y + 2/zoom, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(255, 255, 255, 255))
		if settings.hudRaceTick then
			drawTextShadowed(getTimeInSeconds(getTickCount() - settings.hudRaceTick), guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		else
			drawTextShadowed(getTimeInSeconds(), guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		end

		drawTextShadowed("ILOŚĆ PUNKTÓW", guiInfo.hud.x, guiInfo.hud.y, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y + 115/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.money, "right", "bottom")
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom + 1, guiInfo.hud.y + 117/zoom + 1, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(0, 0, 0, 40))
		dxDrawImage(guiInfo.hud.x + guiInfo.hud.w - 120/zoom, guiInfo.hud.y + 117/zoom, 200/zoom, 4/zoom, "files/images/hud/separator.png", 0, 0, 0, tocolor(255, 255, 255, 255))
		if settings.hudRaceDetails then
			drawTextShadowed(comma_value(settings.hudRaceDetails.driftScore or 0), guiInfo.hud.x, guiInfo.hud.y + 115/zoom, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		else
			drawTextShadowed("0", guiInfo.hud.x, guiInfo.hud.y + 115/zoom, guiInfo.hud.x + guiInfo.hud.w + 80/zoom, guiInfo.hud.y - 5/zoom, tocolor(255, 255, 255, 255), 1/zoom, self.fonts.race, "right", "top")
		end
	end
end

function HUD:renderGUI()
	local i, scale = 0, 1
	for _, v in ipairs(guiInfo.bars) do
		self:calculateBarPercent(v)
		if v.percentage >= 0 then
			self:drawBar(i, scale, v)
			i = i + 1
			scale = scale - 0.1
		end
	end

	drawTextHardShadowed(string.format("$%.2f", self.money), guiInfo.hud.x, guiInfo.hud.y + (guiInfo.bar.h + 14/zoom) * i - 5/zoom, guiInfo.hud.x + guiInfo.bar.w + guiInfo.bar.h + 10/zoom, guiInfo.hud.y + guiInfo.hud.h, tocolor(200, 200, 200, 255 * settings.alpha), 1/zoom, self.fonts.money, "right", "top")
	if settings.insideCasino then
		i = i + 1
		drawTextHardShadowed(settings.casinoChips or 0, guiInfo.hud.x, guiInfo.hud.y + (guiInfo.bar.h + 14/zoom) * i - 10/zoom, guiInfo.hud.x + guiInfo.bar.w + guiInfo.bar.h - 18/zoom, guiInfo.hud.y + guiInfo.hud.h, tocolor(200, 200, 200, 255 * settings.alpha), 1/zoom, self.fonts.money, "right", "top")
		dxDrawImage(guiInfo.hud.x + guiInfo.bar.w + guiInfo.bar.h - 13/zoom, guiInfo.hud.y + (guiInfo.bar.h + 14/zoom) * i - 7/zoom, 23/zoom, 23/zoom, "files/images/hud/chip.png", 0, 0, 0, tocolor(255, 255, 255, 255 * settings.alpha))
	end

	dxDrawImage(guiInfo.hud.x + guiInfo.bar.w + 3/zoom, guiInfo.hud.y - guiInfo.bar.h - 19/zoom, guiInfo.bar.h + 10/zoom, guiInfo.bar.h + 10/zoom, "files/images/hud/img_bg.png", 0, 0, 0, tocolor(255, 255, 255, 255 * settings.alpha))
	dxDrawImage(guiInfo.hud.x + guiInfo.bar.w + 8/zoom, guiInfo.hud.y - guiInfo.bar.h - 14/zoom, guiInfo.bar.h, guiInfo.bar.h, "files/images/hud/clock.png", 0, 0, 0, tocolor(200, 200, 200, 255 * settings.alpha))

	local time = getRealTime()
	drawTextHardShadowed(string.format("%s %02d:%02d", guiInfo.weekDays[time.weekday], time.hour, time.minute), guiInfo.hud.x + guiInfo.bar.w - 3/zoom, guiInfo.hud.y - guiInfo.bar.h - 19/zoom, guiInfo.hud.x + guiInfo.bar.w - 3/zoom, guiInfo.hud.y - 10/zoom, tocolor(200, 200, 200, 255 * settings.alpha), 1/zoom, self.fonts.money, "right", "top")


	local currentWeapon = getPedWeapon(localPlayer)
	if currentWeapon and fileExists(string.format("files/images/weapons/%d.png", currentWeapon)) then
		if weaponWithoutAmmo[currentWeapon] then
			dxDrawImage(sx - 160/zoom, guiInfo.hud.y + (guiInfo.bar.h + 14/zoom) * i + 25/zoom, 150/zoom, 64/zoom, string.format("files/images/weapons/%d.png", currentWeapon), 0, 0, 0, tocolor(255, 255, 255, 255 * settings.alpha))

		else
			local clipAmmo = getPedAmmoInClip(localPlayer)
			local totalAmmo = getPedTotalAmmo(localPlayer)

			dxDrawImage(sx - 240/zoom, guiInfo.hud.y + (guiInfo.bar.h + 14/zoom) * i + 25/zoom, 150/zoom, 64/zoom, string.format("files/images/weapons/%d.png", currentWeapon), 0, 0, 0, tocolor(255, 255, 255, 255 * settings.alpha))
			drawTextHardShadowed("NABOJE", sx - 60/zoom, guiInfo.hud.y + (guiInfo.bar.h + 14/zoom) * i + 40/zoom, guiInfo.hud.x + guiInfo.bar.w + guiInfo.bar.h + 10/zoom, guiInfo.hud.y + guiInfo.hud.h, tocolor(200, 200, 200, 255 * settings.alpha), 1/zoom, self.fonts.role, "right", "top")
			drawTextHardShadowed(string.format("%d/%d", clipAmmo, totalAmmo - clipAmmo), sx - 60/zoom, guiInfo.hud.y + (guiInfo.bar.h + 14/zoom) * i + 50/zoom, guiInfo.hud.x + guiInfo.bar.w + guiInfo.bar.h + 10/zoom, guiInfo.hud.y + guiInfo.hud.h, tocolor(200, 200, 200, 255 * settings.alpha), 1/zoom, self.fonts.money, "right", "top")
		end
	end
end

function HUD:renderNametags()
	if settings.blockNames then return end
	-- Nametags
	local px, py, pz = getCameraMatrix(localPlayer)
	for _, plr in pairs(getElementsByType("player", root, true)) do
		if plr ~= localPlayer then
			local plrAlpha = getElementAlpha(plr)
			local id = getElementData(plr, "ID")
			local characterDesc = getElementData(plr, "characterDesc")
			local rpName = getElementData(plr, "usernameRP")
			local x, y, z = getPedBonePosition(plr, 8)
			local dist = getDistanceBetweenPoints3D(px, py, pz, x, y, z)
			local psx, psy = getScreenFromWorldPosition(x, y, z + 0.4 - 0.00001 * dist)
			local clear = isLineOfSightClear(px, py, pz, x, y, z, true, false, false, true, true, true)
			if psx and psy and dist < 30 and clear then
				local name, color, hasMask = getPlayerData(plr)
				local rank, rankColor = getPlayerDuty(plr)

				local alpha = dist <= 20 and 1 or math.max(1 - (dist - 20)/10, 0)
				local iconSize = 26/zoom - dist
				local iconSpace = 5/zoom - 5/zoom * dist/30

				local icons = getPlayerIcons(plr)
				local iconsX = psx - #icons/2 * (iconSize + iconSpace)
				for i, v in pairs(icons) do
					dxDrawImage(iconsX, psy - 16/zoom + 16/zoom * dist/30 - iconSize, iconSize, iconSize, v, 0, 0, 0, tocolor(255, 255, 255, plrAlpha * alpha * settings.alpha))
					iconsX = iconsX + iconSize + iconSpace
				end
				
				if not hasMask then
					if id then
						drawTextShadowed(string.format("#cccccc[%d] %s%s", id, color, name), psx, psy, psx, psy, tocolor(255, 255, 255, plrAlpha * alpha * settings.alpha), 1 - dist/30, self.fonts.name, "center", "center", false, false, false, true, plrAlpha/255)

						if not isInDmZone(plr) then
							drawTextShadowed(rank, psx, psy + 20/zoom - 20/zoom * dist/30, psx, psy + 20/zoom - 20/zoom * dist/30, tocolor(rankColor[1], rankColor[2], rankColor[3], plrAlpha * alpha * settings.alpha), 1 - dist/30, self.fonts.role, "center", "center", false, false, false, true, plrAlpha/255)
						end
					else
						drawTextShadowed(string.format("%s%s", color, name), psx, psy, psx, psy, tocolor(255, 255, 255, plrAlpha * alpha * settings.alpha), 1 - dist/30, self.fonts.name, "center", "center", false, false, false, true, plrAlpha/255)

						if not isInDmZone(plr) then
							drawTextShadowed(rank, psx, psy + 20/zoom - 20/zoom * dist/30, psx, psy + 20/zoom - 20/zoom * dist/30, tocolor(rankColor[1], rankColor[2], rankColor[3], plrAlpha * alpha * settings.alpha), 1 - dist/30, self.fonts.role, "center", "center", false, false, false, true, plrAlpha/255)
						end
					end
				else
					drawTextShadowed(string.format("%s%s", color, name), psx, psy, psx, psy, tocolor(255, 255, 255, plrAlpha * alpha * settings.alpha), 1 - dist/30, self.fonts.name, "center", "center", false, false, false, true, plrAlpha/255)
					drawTextShadowed("(Czarna bawełniana kominiarka)", psx, psy + 20/zoom - 20/zoom * dist/30, psx, psy + 20/zoom - 20/zoom * dist/30, tocolor(120, 130, 138, plrAlpha * alpha * settings.alpha), 1 - dist/30, self.fonts.role, "center", "center", false, false, false, true, plrAlpha/255)
				end

				

				if characterDesc and settings.characterDescVisible then
					local psx, psy = getScreenFromWorldPosition(x, y, z - 0.4 - 0.00001 * dist)
					if psx and psy then
						drawTextShadowed(string.wrap(characterDesc, 300, 1/zoom, self.fonts.role, true), psx, psy + 20/zoom - 20/zoom * dist/30, psx, psy + 20/zoom - 20/zoom * dist/30, tocolor(150, 150, 150, plrAlpha * alpha * settings.alpha), 1 - dist/30, self.fonts.role, "center", "center", false, false, false, true, plrAlpha/255)
					end
				end
			end
		end
	end

	for _, plr in pairs(getElementsByType("ped", root, true)) do
		local name = getElementData(plr, "name")
		if name then
			local plrAlpha = getElementAlpha(plr)
			local x, y, z = getPedBonePosition(plr, 8)
			local dist = getDistanceBetweenPoints3D(px, py, pz, x, y, z)
			local psx, psy = getScreenFromWorldPosition(x, y, z + 0.4 - 0.1 * dist/20)
			local clear = isLineOfSightClear(px, py, pz, x, y, z, true, false, false, true, true, true)
			if psx and psy and dist < 30 and clear then

				local role = getElementData(plr, "role")
				local alpha = dist <= 20 and 1 or (20 - dist)/10
				dist = dist/30

				drawTextShadowed(string.format("#dddddd%s\n#999999(%s)", name, role), psx, psy, psx, psy, tocolor(255, 255, 255, plrAlpha * alpha * settings.alpha), 1 - dist, self.fonts.role, "center", "center", false, false, false, true, plrAlpha/255)
			end
		end
	end
end


function HUD:renderSpeedometer()
	if settings.blockHud and not guiInfo.speedo.isTuning then return end
	if not getPedOccupiedVehicle(localPlayer) and guiInfo.speedo.state == "opened" and not guiInfo.speedo.isTuning then exitVehicle(localPlayer, 0) end
	if not isElement(guiInfo.speedo.vehicle) and not guiInfo.speedo.isTuning then guiInfo.speedo.vehicle = nil; guiInfo.speedo.vehicleData = nil; return end
	self:animateSpeedometer()
	if not guiInfo.speedo.vehicleData then return end

	local alpha = settings.alpha * guiInfo.speedo.alpha
	if guiInfo.speedo.isTuning then alpha = 1 end
	if settings.hudRaceMode == "Drag" then alpha = 0 end

	if guiInfo.speedo.type == "standard" then
		self:renderStandardSpeedometer(alpha)
		--self:renderSuperSpeedometer(alpha)

	elseif guiInfo.speedo.type == "old" then
		self:renderOldSpeedometer(alpha)

	elseif guiInfo.speedo.type == "super" then
		self:renderSuperSpeedometer(alpha)

	elseif guiInfo.speedo.type == "motorbike" then
		self:renderMotorbikeSpeedometer(alpha)

	elseif guiInfo.speedo.type == "boat" then
		self:renderBoatSpeedometer(alpha)
	end

	-- Check fuel state
	if guiInfo.speedo.vehicleData.fuel <= 0.5 then
		setVehicleEngineState(guiInfo.speedo.vehicle, false)
	end

	-- Check speed
	local speed = getElementSpeed(guiInfo.speedo.vehicle, 1)
	local maxSpeed = getElementData(guiInfo.speedo.vehicle, "maxSpeed") or guiInfo.speedo.maxSpeed
	if speed > maxSpeed then
		setElementSpeed(guiInfo.speedo.vehicle, 1, maxSpeed)
	end
	if guiInfo.speedo.control then
		if speed > guiInfo.speedo.control then
			setElementSpeed(guiInfo.speedo.vehicle, 1, guiInfo.speedo.control)
			setPedControlState(localPlayer, "accelerate", true)

		elseif speed < 20 or guiInfo.speedo.vehicleData.fuel <= 0.5 then
			guiInfo.speedo.control = nil
			setPedControlState(localPlayer, "accelerate", false)
			toggleControl("accelerate", true)
		end
	end

	if not guiInfo.speedo.above240 and speed >= 240 then
		guiInfo.speedo.above240 = true
		exports.TR_achievements:addAchievements("vehicle240")
	end
end

function HUD:renderStandardSpeedometer(alpha)
	local color = self:getVehicleSpeedoColor()

	-- Speedo
	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/speedo.png", 0, 0, 0, tocolor(color[1], color[2], color[3], 255 * alpha))
	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/speedoRed.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))

	-- Fuel
	local rotFuel = 90 * math.max(math.min((1 - guiInfo.speedo.vehicleData.fuel / guiInfo.speedo.vehicleData.maxFuel), 1), 0)
	dxDrawText("FUEL", guiInfo.speedo.x - 8/zoom, 0, guiInfo.speedo.x - 8/zoom, guiInfo.speedo.y + guiInfo.speedo.h - 64/zoom, tocolor(255, 255, 255, 255 * alpha), 1/zoom, self.fonts.speedo, "center", "bottom")
	dxDrawImage(guiInfo.speedo.x - 100/zoom, guiInfo.speedo.y + guiInfo.speedo.h - 130/zoom, 110/zoom, 110/zoom, "files/images/speedo/fuel.png", 0, 0, 0, tocolor(color[1], color[2], color[3], 255 * alpha))
	dxDrawImage(guiInfo.speedo.x - 100/zoom, guiInfo.speedo.y + guiInfo.speedo.h - 130/zoom, 110/zoom, 110/zoom, "files/images/speedo/fuelRed.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	dxDrawImage(guiInfo.speedo.x - 78/zoom, guiInfo.speedo.y + guiInfo.speedo.h - 108/zoom, 140/zoom, 140/zoom, "files/images/speedo/fuelNeedle.png", -rotFuel, 0, 0, tocolor(255, 255, 255, 255 * alpha))

	-- Icons
	local state = settings.indicators:getVehicleState(guiInfo.speedo.vehicle)
	if state == "left" or state == "all" then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 70/zoom, guiInfo.speedo.y + 90/zoom, 50/zoom, 50/zoom, "files/images/speedo/on_indicatorl.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 70/zoom, guiInfo.speedo.y + 90/zoom, 50/zoom, 50/zoom, "files/images/speedo/indicatorl.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	end
	if state == "right" or state == "all" then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 20/zoom, guiInfo.speedo.y + 90/zoom, 50/zoom, 50/zoom, "files/images/speedo/on_indicatorr.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 20/zoom, guiInfo.speedo.y + 90/zoom, 50/zoom, 50/zoom, "files/images/speedo/indicatorr.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	end

	local health = getElementHealth(guiInfo.speedo.vehicle)
	if health > 700 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 60/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 105/zoom, 50/zoom, 50/zoom, "files/images/speedo/engine1.png", 0, 0, 0, tocolor(210, 210, 210, 255 * alpha))
	elseif health <= 700 and health > 400 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 60/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 105/zoom, 50/zoom, 50/zoom, "files/images/speedo/engine2.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	elseif health < 400 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 60/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 105/zoom, 50/zoom, 50/zoom, "files/images/speedo/engine3.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	end

	if isVehicleFrozen(guiInfo.speedo.vehicle) then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 20/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 105/zoom, 50/zoom, 50/zoom, "files/images/speedo/on_handbrake.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 20/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 105/zoom, 50/zoom, 50/zoom, "files/images/speedo/handbrake.png", 0, 0, 0, tocolor(210, 210, 210, 255 * alpha))
	end

	if getVehicleOverrideLights(guiInfo.speedo.vehicle) == 2 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 20/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 105/zoom, 50/zoom, 50/zoom, "files/images/speedo/on_lights.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 20/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 105/zoom, 50/zoom, 50/zoom, "files/images/speedo/lights.png", 0, 0, 0, tocolor(210, 210, 210, 255 * alpha))
	end

	if guiInfo.speedo.control then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 60/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 105/zoom, 50/zoom, 50/zoom, "files/images/speedo/on_control.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
		dxDrawText("("..guiInfo.speedo.control..")", guiInfo.speedo.x + guiInfo.speedo.w/2 + 60/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 136/zoom, guiInfo.speedo.x + guiInfo.speedo.w/2 + 110/zoom, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(152, 196, 47, 255 * alpha), 1/zoom, self.fonts.speedo, "center", "top")
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 60/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 105/zoom, 50/zoom, 50/zoom, "files/images/speedo/control.png", 0, 0, 0, tocolor(210, 210, 210, 255 * alpha))
		dxDrawText("(c)", guiInfo.speedo.x + guiInfo.speedo.w/2 + 60/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 136/zoom, guiInfo.speedo.x + guiInfo.speedo.w/2 + 110/zoom, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(210, 210, 210, 255 * alpha), 1/zoom, self.fonts.speedo, "center", "top")
	end

	if not getElementData(localPlayer, "belt") then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 100/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 105/zoom, 50/zoom, 50/zoom, "files/images/speedo/no_belt.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 100/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 105/zoom, 50/zoom, 50/zoom, "files/images/speedo/belt.png", 0, 0, 0, tocolor(210, 210, 210, 255 * alpha))
	end

	-- Mileage
	local mileage = string.format("%06d", guiInfo.speedo.vehicleData.mileage)
	for i = 0, 5 do
		if not guiInfo.speedo.mileageInfo[i] then guiInfo.speedo.mileageInfo[i] = 0 end
		local number = tonumber(string.sub(mileage, i + 1, i + 1)) or 0
		if number ~= guiInfo.speedo.mileageInfo[i] then
			if number > guiInfo.speedo.mileageInfo[i] then
				guiInfo.speedo.mileageInfo[i] = guiInfo.speedo.mileageInfo[i] + 0.04

				if number < guiInfo.speedo.mileageInfo[i] then
					guiInfo.speedo.mileageInfo[i] = number
				end

			elseif number < guiInfo.speedo.mileageInfo[i] then
				guiInfo.speedo.mileageInfo[i] = guiInfo.speedo.mileageInfo[i] + 0.04

				if guiInfo.speedo.mileageInfo[i] >= 10 then
					guiInfo.speedo.mileageInfo[i] = 0
				end
			end
		end

		if guiInfo.speedo.type == "old" then
			dxDrawRectangle(guiInfo.speedo.x + guiInfo.speedo.w/2 - (3 * 26/zoom) + i * 26/zoom - 1/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 55/zoom, 24/zoom, 24/zoom, tocolor(27, 27, 27, 255 * alpha))
			dxDrawImageSection(guiInfo.speedo.x + guiInfo.speedo.w/2 - (3 * 26/zoom) + i * 26/zoom - 1/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 55/zoom, 24/zoom, 24/zoom, 0, guiInfo.speedo.mileageHeight - 24 - (guiInfo.speedo.mileageInfo[i] * 24), 24, 24, "files/images/speedo/mileage.png", 0, 0, 0, tocolor(170, 170, 170, 255 * alpha))
		else
			dxDrawRectangle(guiInfo.speedo.x + 130/zoom + i * 20/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 55/zoom, 18/zoom, 18/zoom, tocolor(17, 17, 17, 255 * alpha))
			dxDrawImageSection(guiInfo.speedo.x + 130/zoom + i * 20/zoom, guiInfo.speedo.y + guiInfo.speedo.h/2 + 55/zoom, 18/zoom, 18/zoom, 0, guiInfo.speedo.mileageHeight - 24 - (guiInfo.speedo.mileageInfo[i] * 24), 24, 24, "files/images/speedo/mileage.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
		end
	end
	dxDrawText("KM", guiInfo.speedo.x + guiInfo.speedo.w/2, 0, guiInfo.speedo.x + guiInfo.speedo.w/2, guiInfo.speedo.y + guiInfo.speedo.h/2 + 50/zoom, tocolor(255, 255, 255, 255 * alpha), 1/zoom, self.fonts.speedo, "center", "bottom")
	self:renderSpeedometerWater(alpha)

	-- Needle
	local speed = getElementSpeed(guiInfo.speedo.vehicle, 1) * guiInfo.speedo.speedDowngrade
	local rot = guiInfo.speedo.startRot + speed >= guiInfo.speedo.maxRot and guiInfo.speedo.maxRot or guiInfo.speedo.startRot + speed
	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/needle.png", rot, 0, 0, tocolor(255, 255, 255, 255 * alpha))
end


-- Old speedometer
function HUD:renderOldSpeedometer(alpha)
	local color = self:getVehicleSpeedoColor()

	-- Speedo
	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/old/speedo.png", 0, 0, 0, tocolor(color[1], color[2], color[3], 255 * alpha))
	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/old/speedoRed.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))


	-- Fuel
	local fuel = math.max(math.min((guiInfo.speedo.vehicleData.fuel / guiInfo.speedo.vehicleData.maxFuel), 1), 0)
	dxDrawImage(guiInfo.speedo.fuel.x, guiInfo.speedo.fuel.y, 91/zoom, 86/zoom, "files/images/speedo/old/gasoline.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	if fuel > 0 then dxDrawImage(guiInfo.speedo.fuel.x + 17/zoom, guiInfo.speedo.fuel.y + 59/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/1.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel >= 0.09 then dxDrawImage(guiInfo.speedo.fuel.x + 21/zoom, guiInfo.speedo.fuel.y + 55/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/2.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel >= 0.18 then dxDrawImage(guiInfo.speedo.fuel.x + 25/zoom, guiInfo.speedo.fuel.y + 51/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/3.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel >= 0.27 then dxDrawImage(guiInfo.speedo.fuel.x + 29/zoom, guiInfo.speedo.fuel.y + 47/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/4.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel >= 0.36 then dxDrawImage(guiInfo.speedo.fuel.x + 33/zoom, guiInfo.speedo.fuel.y + 43/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/5.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel >= 0.45 then dxDrawImage(guiInfo.speedo.fuel.x + 38/zoom, guiInfo.speedo.fuel.y + 39/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/6.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel >= 0.54 then dxDrawImage(guiInfo.speedo.fuel.x + 43/zoom, guiInfo.speedo.fuel.y + 35/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/7.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel >= 0.63 then dxDrawImage(guiInfo.speedo.fuel.x + 47/zoom, guiInfo.speedo.fuel.y + 31/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/8.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel >= 0.72 then dxDrawImage(guiInfo.speedo.fuel.x + 52/zoom, guiInfo.speedo.fuel.y + 28/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/9.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel >= 0.81 then dxDrawImage(guiInfo.speedo.fuel.x + 57/zoom, guiInfo.speedo.fuel.y + 25/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/10.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel >= 0.90 then dxDrawImage(guiInfo.speedo.fuel.x + 62/zoom, guiInfo.speedo.fuel.y + 22/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/11.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel >= 0.98 then dxDrawImage(guiInfo.speedo.fuel.x + 67/zoom, guiInfo.speedo.fuel.y + 19/zoom, 16/zoom, 18/zoom, "files/images/speedo/old/fuel/12.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end


	-- Mileage
	local mileage = string.format("%06d", guiInfo.speedo.vehicleData.mileage)
	for i = 0, 5 do
		if not guiInfo.speedo.mileageInfo[i] then guiInfo.speedo.mileageInfo[i] = 0 end
		local number = tonumber(string.sub(mileage, i + 1, i + 1)) or 0
		if number ~= guiInfo.speedo.mileageInfo[i] then
			if number > guiInfo.speedo.mileageInfo[i] then
				guiInfo.speedo.mileageInfo[i] = guiInfo.speedo.mileageInfo[i] + 0.04

				if number < guiInfo.speedo.mileageInfo[i] then
					guiInfo.speedo.mileageInfo[i] = number
				end

			elseif number < guiInfo.speedo.mileageInfo[i] then
				guiInfo.speedo.mileageInfo[i] = guiInfo.speedo.mileageInfo[i] + 0.04

				if guiInfo.speedo.mileageInfo[i] >= 10 then
					guiInfo.speedo.mileageInfo[i] = 0
				end
			end
		end

		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - (24/zoom * 6)/2 + 1/zoom + i * 24/zoom, guiInfo.speedo.y + 105/zoom, 20/zoom, 34/zoom, "files/images/speedo/old/mileage_bg.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
		dxDrawImageSection(guiInfo.speedo.x + guiInfo.speedo.w/2 - (24/zoom * 6)/2 + 1/zoom + i * 24/zoom, guiInfo.speedo.y + 105/zoom, 20/zoom, 34/zoom, 0, (guiInfo.speedo.mileageInfo[i] * 34), 20, 34, "files/images/speedo/old/mileage.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	end


	-- Icons
	local health = getElementHealth(guiInfo.speedo.vehicle)
	local indicator = settings.indicators:getVehicleState(guiInfo.speedo.vehicle)

	if getVehicleOverrideLights(guiInfo.speedo.vehicle) == 2 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 100/zoom, guiInfo.speedo.y + 151/zoom, 30/zoom, 30/zoom, "files/images/speedo/old/lights_on.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 100/zoom, guiInfo.speedo.y + 151/zoom, 30/zoom, 30/zoom, "files/images/speedo/old/lights_off.png", 0, 0, 0, tocolor(170, 170, 170, 255 * alpha))
	end
	if indicator == "left" or indicator == "right" then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 60/zoom, guiInfo.speedo.y + 146/zoom, 40/zoom, 40/zoom, "files/images/speedo/old/indicator_on.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 60/zoom, guiInfo.speedo.y + 146/zoom, 40/zoom, 40/zoom, "files/images/speedo/old/indicator_off.png", 0, 0, 0, tocolor(170, 170, 170, 255 * alpha))
	end
	if isVehicleFrozen(guiInfo.speedo.vehicle) then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 10/zoom, guiInfo.speedo.y + 151/zoom, 30/zoom, 30/zoom, "files/images/speedo/old/handbrake_on.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 10/zoom, guiInfo.speedo.y + 151/zoom, 30/zoom, 30/zoom, "files/images/speedo/old/handbrake_off.png", 0, 0, 0, tocolor(170, 170, 170, 255 * alpha))
	end
	if indicator == "all" then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 30/zoom , guiInfo.speedo.y + 151/zoom, 30/zoom, 30/zoom, "files/images/speedo/old/emergency_on.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 30/zoom, guiInfo.speedo.y + 151/zoom, 30/zoom, 30/zoom, "files/images/speedo/old/emergency_off.png", 0, 0, 0, tocolor(170, 170, 170, 255 * alpha))
	end
	if health > 700 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 70/zoom, guiInfo.speedo.y + 151/zoom, 30/zoom, 30/zoom, "files/images/speedo/old/engine_full.png", 0, 0, 0, tocolor(170, 170, 170, 255 * alpha))
	elseif health <= 700 and health > 400 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 70/zoom, guiInfo.speedo.y + 151/zoom, 30/zoom, 30/zoom, "files/images/speedo/old/engine_med.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	elseif health < 400 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 70/zoom, guiInfo.speedo.y + 151/zoom, 30/zoom, 30/zoom, "files/images/speedo/old/engine_low.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	end

	-- Needle
	local speed = getElementSpeed(guiInfo.speedo.vehicle, 1) * 0.38
	local rot = guiInfo.speedo.minRot + speed >= guiInfo.speedo.maxRot and guiInfo.speedo.maxRot or guiInfo.speedo.minRot + speed
	dxDrawImage(guiInfo.speedo.x + (guiInfo.speedo.w - 200/zoom)/2, guiInfo.speedo.y + 75/zoom, 200/zoom, 200/zoom, "files/images/speedo/old/needle.png", rot, 0, 450/zoom, tocolor(255, 255, 255, 255 * alpha))
end



-- super speedometer
function HUD:renderSuperSpeedometer(alpha)
	local color = self:getVehicleSpeedoColor()

	-- Speedo
	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/super/speedoRed.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/super/speedo.png", 0, 0, 0, tocolor(color[1], color[2], color[3], 255 * alpha))

	-- Needle
	local speed = getElementSpeed(guiInfo.speedo.vehicle, 1)
	local rotSpeed = speed * 0.9
	local rot = guiInfo.speedo.minRot + rotSpeed >= guiInfo.speedo.maxRot and guiInfo.speedo.maxRot or guiInfo.speedo.minRot + rotSpeed
	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/super/needle.png", rot, 0, 0, tocolor(255, 255, 255, 255 * alpha))

	if guiInfo.speedo.section == 1 then
		dxDrawText(math.ceil(speed), guiInfo.speedo.x, guiInfo.speedo.y + 110/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(207, 208, 222, 255 * alpha), 1/zoom, self.fonts.speed, "center", "top")
		dxDrawText("km/h", guiInfo.speedo.x, guiInfo.speedo.y + 180/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(207, 208, 222, 255 * alpha), 1/zoom, self.fonts.speedoBig, "center", "top")

	elseif guiInfo.speedo.section == 2 then
		local mileage = string.format("%06d", guiInfo.speedo.vehicleData.mileage)
		local mileageString = ""
		for i = 0, 5 do
			local number = tonumber(string.sub(mileage, i + 1, i + 1)) or 0
			mileageString = mileageString .. string.format("%s%d", i == 3 and " " or "", number)
		end

		dxDrawText("Aktualny przebieg:", guiInfo.speedo.x, guiInfo.speedo.y + 135/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(207, 208, 222, 200 * alpha), 1/zoom, self.fonts.speedo, "center", "top")
		dxDrawText(mileageString, guiInfo.speedo.x, guiInfo.speedo.y + 150/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(207, 208, 222, 255 * alpha), 1/zoom, self.fonts.mileage, "center", "top")

	elseif guiInfo.speedo.section == 3 then
		local fuel = math.max(math.min((guiInfo.speedo.vehicleData.fuel / guiInfo.speedo.vehicleData.maxFuel), 1), 0)

		dxDrawText("Ilość paliwa:", guiInfo.speedo.x, guiInfo.speedo.y + 135/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(207, 208, 222, 200 * alpha), 1/zoom, self.fonts.speedo, "center", "top")
		dxDrawText(math.ceil(fuel * 100).."%", guiInfo.speedo.x, guiInfo.speedo.y + 150/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(207, 208, 222, 255 * alpha), 1/zoom, self.fonts.mileage, "center", "top")
	end

	-- Icons
	local health = getElementHealth(guiInfo.speedo.vehicle)
	local indicator = settings.indicators:getVehicleState(guiInfo.speedo.vehicle)

	if getVehicleOverrideLights(guiInfo.speedo.vehicle) == 2 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 60/zoom, guiInfo.speedo.y + 205/zoom, 20/zoom, 20/zoom, "files/images/speedo/old/lights_on.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 60/zoom, guiInfo.speedo.y + 205/zoom, 20/zoom, 20/zoom, "files/images/speedo/old/lights_off.png", 0, 0, 0, tocolor(100, 100, 100, 255 * alpha))
	end
	if indicator == "left" or indicator == "right" then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 35/zoom, guiInfo.speedo.y + 205/zoom, 20/zoom, 20/zoom, "files/images/speedo/old/indicator_on.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 35/zoom, guiInfo.speedo.y + 205/zoom, 20/zoom, 20/zoom, "files/images/speedo/old/indicator_off.png", 0, 0, 0, tocolor(100, 100, 100, 255 * alpha))
	end
	if isVehicleFrozen(guiInfo.speedo.vehicle) then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 10/zoom, guiInfo.speedo.y + 205/zoom, 20/zoom, 20/zoom, "files/images/speedo/old/handbrake_on.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 10/zoom, guiInfo.speedo.y + 205/zoom, 20/zoom, 20/zoom, "files/images/speedo/old/handbrake_off.png", 0, 0, 0, tocolor(100, 100, 100, 255 * alpha))
	end
	if indicator == "all" then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 15/zoom, guiInfo.speedo.y + 205/zoom, 20/zoom, 20/zoom, "files/images/speedo/old/emergency_on.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 15/zoom, guiInfo.speedo.y + 205/zoom, 20/zoom, 20/zoom, "files/images/speedo/old/emergency_off.png", 0, 0, 0, tocolor(100, 100, 100, 255 * alpha))
	end
	if health > 700 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 40/zoom, guiInfo.speedo.y + 205/zoom, 20/zoom, 20/zoom, "files/images/speedo/old/engine_full.png", 0, 0, 0, tocolor(100, 100, 100, 255 * alpha))
	elseif health <= 700 and health > 400 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 40/zoom, guiInfo.speedo.y + 205/zoom, 20/zoom, 20/zoom, "files/images/speedo/old/engine_med.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	elseif health < 400 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 40/zoom, guiInfo.speedo.y + 205/zoom, 20/zoom, 20/zoom, "files/images/speedo/old/engine_low.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	end

	dxDrawText("X - zmiana informacji\nC - tempomat", guiInfo.speedo.x, guiInfo.speedo.y + 230/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(207, 208, 222, 100 * alpha), 1/zoom, self.fonts.info, "center", "top")
end



-- super speedometer
function HUD:renderMotorbikeSpeedometer(alpha)
	local color = self:getVehicleSpeedoColor()

	-- Speedo
	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/motorbike/speedoRed.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/motorbike/speedo.png", 0, 0, 0, tocolor(color[1], color[2], color[3], 255 * alpha))


	-- Clock
	local time = getRealTime()
	dxDrawText(string.format("%02d:%02d", time.hour, time.minute), guiInfo.speedo.x + 277/zoom, guiInfo.speedo.y + 115/zoom, guiInfo.speedo.x + 340/zoom, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(80, 80, 80, 255 * alpha), 1/zoom, self.fonts.digitalSmall, "center", "top")


	-- Gear
	local gear = getVehicleCurrentGear(guiInfo.speedo.vehicle)
	dxDrawText("GEAR", guiInfo.speedo.x + 345/zoom, guiInfo.speedo.y + 118/zoom, guiInfo.speedo.x + guiInfo.speedo.w - 70/zoom, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(80, 80, 80, 255 * alpha), 1/zoom, self.fonts.info, "right", "top")
	dxDrawText(gear == 0 and "N" or gear, guiInfo.speedo.x + 384/zoom, guiInfo.speedo.y + 123/zoom, guiInfo.speedo.x + 398/zoom, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(80, 80, 80, 255 * alpha), 1/zoom, self.fonts.digitalSmall, "center", "top")

	if guiInfo.speedo.currGear ~= gear then
		guiInfo.speedo.currGear = gear

		guiInfo.speedo.gearTick = getTickCount()
		guiInfo.speedo.gearCount = 0
	end

	if guiInfo.speedo.gearTick then
		if (getTickCount() - guiInfo.speedo.gearTick)/60 >= 1 then
			guiInfo.speedo.gearTick = getTickCount()
			guiInfo.speedo.gearCount = guiInfo.speedo.gearCount + 1

			guiInfo.speedo.gearLight = not guiInfo.speedo.gearLight

			if guiInfo.speedo.gearCount >= 4 then
				guiInfo.speedo.gearTick = nil
				guiInfo.speedo.gearCount = nil
				guiInfo.speedo.gearLight = false
			end
		end
	end

	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/motorbike/gearLight.png", 0, 0, 0, tocolor(255, 255, 255, (guiInfo.speedo.gearLight and 255 or 100) * alpha))


	-- Speed
	local speed = getElementSpeed(guiInfo.speedo.vehicle, 1)
	local rotSpeed = speed * 0.75
	local rot = guiInfo.speedo.minRot + rotSpeed >= guiInfo.speedo.maxRot and guiInfo.speedo.maxRot or guiInfo.speedo.minRot + rotSpeed
	dxDrawImage(guiInfo.speedo.x + 112/zoom, guiInfo.speedo.y + 61/zoom, 180/zoom, 180/zoom, "files/images/speedo/motorbike/needle.png", rot, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	dxDrawText(math.ceil(speed), guiInfo.speedo.x + 320/zoom, guiInfo.speedo.y + 135/zoom, guiInfo.speedo.x + 340/zoom, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(80, 80, 80, 255 * alpha), 1/zoom, self.fonts.digitalLarge, "right", "top")
	dxDrawText("km/h", guiInfo.speedo.x + 345/zoom, guiInfo.speedo.y + 165/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(80, 80, 80, 255 * alpha), 1/zoom, self.fonts.info, "left", "top")

	-- Fuel
	local fuel = math.max(math.min((guiInfo.speedo.vehicleData.fuel / guiInfo.speedo.vehicleData.maxFuel), 1), 0)
	dxDrawImageSection(guiInfo.speedo.x + 15/zoom, guiInfo.speedo.y + 46/zoom + 213/zoom * (1-fuel), 74/zoom, 213/zoom * fuel, 0, 213 * (1-fuel), 74, 213 * fuel, "files/images/speedo/motorbike/fuel.png", 0, 0, 0, tocolor(255, 255, 255, 150 * alpha))
	-- dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/super/speedo.png", 0, 0, 0, tocolor(color[1], color[2], color[3], 255 * alpha))


	-- Mileage
	local mileage = string.format("%06d", guiInfo.speedo.vehicleData.mileage)
	dxDrawText(mileage, guiInfo.speedo.x + 290/zoom, guiInfo.speedo.y + 190/zoom, guiInfo.speedo.x + 360/zoom, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(80, 80, 80, 255 * alpha), 1/zoom, self.fonts.digitalSmall, "right", "top")
	dxDrawText("km", guiInfo.speedo.x + 362/zoom, guiInfo.speedo.y + 201/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(80, 80, 80, 255 * alpha), 1/zoom, self.fonts.info, "left", "top")


	-- Icons
	local health = getElementHealth(guiInfo.speedo.vehicle)
	local indicator = settings.indicators:getVehicleState(guiInfo.speedo.vehicle)

	if getVehicleOverrideLights(guiInfo.speedo.vehicle) == 2 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 20/zoom, guiInfo.speedo.y + 235/zoom, 22/zoom, 22/zoom, "files/images/speedo/old/lights_on.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 20/zoom, guiInfo.speedo.y + 235/zoom, 22/zoom, 22/zoom, "files/images/speedo/old/lights_off.png", 0, 0, 0, tocolor(160, 160, 160, 255 * alpha))
	end
	if indicator == "left" or indicator == "right" then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 9/zoom, guiInfo.speedo.y + 235/zoom, 22/zoom, 22/zoom, "files/images/speedo/old/indicator_on.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 9/zoom, guiInfo.speedo.y + 235/zoom, 22/zoom, 22/zoom, "files/images/speedo/old/indicator_off.png", 0, 0, 0, tocolor(160, 160, 160, 255 * alpha))
	end
	if indicator == "all" then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 38/zoom, guiInfo.speedo.y + 235/zoom, 22/zoom, 22/zoom, "files/images/speedo/old/emergency_on.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	else
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 + 38/zoom, guiInfo.speedo.y + 235/zoom, 22/zoom, 22/zoom, "files/images/speedo/old/emergency_off.png", 0, 0, 0, tocolor(160, 160, 160, 255 * alpha))
	end
	if health > 700 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 20/zoom, guiInfo.speedo.y + 260/zoom, 22/zoom, 22/zoom, "files/images/speedo/old/engine_full.png", 0, 0, 0, tocolor(160, 160, 160, 255 * alpha))
	elseif health <= 700 and health > 400 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 20/zoom, guiInfo.speedo.y + 260/zoom, 22/zoom, 22/zoom, "files/images/speedo/old/engine_med.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	elseif health < 400 then
		dxDrawImage(guiInfo.speedo.x + guiInfo.speedo.w/2 - 20/zoom, guiInfo.speedo.y + 260/zoom, 22/zoom, 22/zoom, "files/images/speedo/old/engine_low.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	end
end


function HUD:renderBoatSpeedometer(alpha)
	dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/boat/speedoRed.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))

	-- Speed
	local speed = math.max((getElementSpeed(guiInfo.speedo.vehicle, 1) * 0.53995680) - 1, 0) * 2
	dxDrawText(string.format("%02d", math.ceil(speed)), guiInfo.speedo.x, guiInfo.speedo.y + 62/zoom, guiInfo.speedo.x + 225/zoom, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(14, 246, 255, 255 * alpha), 1/zoom, self.fonts.digitalUltraLarge, "right", "top")
	dxDrawText("nm/h", guiInfo.speedo.x + 230/zoom, guiInfo.speedo.y + 108/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(14, 246, 255, 255 * alpha), 1/zoom, self.fonts.role, "left", "top")


	-- Fuel
	local fuel = math.max(math.min((guiInfo.speedo.vehicleData.fuel / guiInfo.speedo.vehicleData.maxFuel), 1), 0)
	if fuel > 0.1 then dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/boat/fuel/5.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel > 0.3 then dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/boat/fuel/4.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel > 0.5 then dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/boat/fuel/3.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel > 0.7 then dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/boat/fuel/2.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end
	if fuel > 0.9 then dxDrawImage(guiInfo.speedo.x, guiInfo.speedo.y, guiInfo.speedo.w, guiInfo.speedo.h, "files/images/speedo/boat/fuel/1.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha)) end

	-- Mileage
	local mileage = string.format("%06d", guiInfo.speedo.vehicleData.mileage)
	dxDrawText(mileage, guiInfo.speedo.x, guiInfo.speedo.y + 172/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(14, 246, 255, 255 * alpha), 1/zoom, self.fonts.digitalSmall, "center", "top")
	dxDrawText("nm", guiInfo.speedo.x + 230/zoom, guiInfo.speedo.y + 182/zoom, guiInfo.speedo.x + guiInfo.speedo.w, guiInfo.speedo.y + guiInfo.speedo.h, tocolor(14, 246, 255, 255 * alpha), 1/zoom, self.fonts.info, "left", "top")
end


function HUD:renderSpeedometerWater(alpha)
	if not guiInfo.speedo.vehicleData then return end
	if guiInfo.speedo.vehicleModel ~= 407 then return end

	local water = getElementData(guiInfo.speedo.vehicle, "waterTank") or 0
	local rotWater = 90 * math.max(math.min((1 - water / 40000), 1), 0)

	dxDrawText("WATER", guiInfo.speedo.x - 138/zoom, 0, guiInfo.speedo.x - 138/zoom, guiInfo.speedo.y + guiInfo.speedo.h - 64/zoom, tocolor(255, 255, 255, 255 * alpha), 1/zoom, self.fonts.speedo, "center", "bottom")
	dxDrawImage(guiInfo.speedo.x - 230/zoom, guiInfo.speedo.y + guiInfo.speedo.h - 130/zoom, 110/zoom, 110/zoom, "files/images/speedo/fuel.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	dxDrawImage(guiInfo.speedo.x - 230/zoom, guiInfo.speedo.y + guiInfo.speedo.h - 130/zoom, 110/zoom, 110/zoom, "files/images/speedo/fuelRed.png", 0, 0, 0, tocolor(255, 255, 255, 255 * alpha))
	dxDrawImage(guiInfo.speedo.x - 208/zoom, guiInfo.speedo.y + guiInfo.speedo.h - 108/zoom, 140/zoom, 140/zoom, "files/images/speedo/fuelNeedle.png", -rotWater, 0, 0, tocolor(255, 255, 255, 255 * alpha))
end

function HUD:drawBar(i, scale, bar)
	local x, y = guiInfo.hud.x + (guiInfo.bar.w - guiInfo.bar.w * scale), guiInfo.hud.y + (guiInfo.bar.h + 14/zoom) * i
	local w = math.ceil(guiInfo.bar.w * scale)
	dxDrawImage(guiInfo.hud.x + guiInfo.bar.w + 3/zoom, y - 5/zoom, guiInfo.bar.h + 10/zoom, guiInfo.bar.h + 10/zoom, "files/images/hud/img_bg.png", 0, 0, 0, tocolor(255, 255, 255, 255 * settings.alpha))
	dxDrawImage(guiInfo.hud.x + guiInfo.bar.w + 8/zoom, y, guiInfo.bar.h, guiInfo.bar.h, bar.img, 0, 0, 0, tocolor(200, 200, 200, 255 * settings.alpha))

	dxDrawImageSection(x - 4/zoom, y - 3/zoom, w + 7/zoom, guiInfo.bar.h + 6/zoom, 1, 1, 240, 25, self.textures.bar, 0, 0, 0, tocolor(17, 17, 17, 255 * settings.alpha))
	dxDrawImageSection(x + (w * (1 - bar.percentage)), y, w * bar.percentage, guiInfo.bar.h, 1, 1, 240 * bar.percentage, 25, self.textures.bar, 0, 0, 0, tocolor(200, 200, 200, 255 * settings.alpha))
end

function HUD:calculateBarPercent(bar)
	local percent = bar.percentage
	if bar.name == "hp" then
		percent = getElementHealth(localPlayer)/100

	elseif bar.name == "armor" then
		percent = guiInfo.isTutorial and 40 or getPedArmor(localPlayer)/100
		if percent == 0 then bar.percentage = -1 return end

	elseif bar.name == "oxygen" then
		if guiInfo.isTutorial then bar.percentage = 1 return end
		if not isElementInWater(localPlayer) then bar.percentage = -1 return end
		bar.percentage = getPedOxygenLevel(localPlayer)/getPedMaxOxygenLevel(localPlayer)

	end

	if bar.percentage < percent then
		bar.percentage = bar.percentage + 0.005
		if bar.percentage >= percent then bar.percentage = percent end
	elseif bar.percentage > percent then
		bar.percentage = bar.percentage - 0.005
		if bar.percentage <= percent then bar.percentage = percent end
	end

	bar.percentage = math.min(math.max(bar.percentage, 0), 1)
end


function HUD:calculateVehicleData()
	if not guiInfo.speedo.checkTick or not guiInfo.speedo.vehicle then return end
	if getElementData(guiInfo.speedo.vehicle, "vehicleOwner") then return end
	-- Client render update
	if (getTickCount() - guiInfo.speedo.checkTick)/1000 >= 1 then
		if not guiInfo.speedo.vehicle then return end
		local speed = getElementSpeed(guiInfo.speedo.vehicle, 1)
		local mileage = speed / 3600
		local handling = getVehicleHandling(guiInfo.speedo.vehicle)

		guiInfo.speedo.vehicleData.mileage = tonumber(string.format("%.6f", guiInfo.speedo.vehicleData.mileage + mileage * 2))

		if getVehicleEngineState(guiInfo.speedo.vehicle) then
			guiInfo.speedo.vehicleData.fuel = tonumber(string.format("%.6f", math.max(guiInfo.speedo.vehicleData.fuel - math.max((handling["engineAcceleration"] * math.sqrt(speed))/6000, 0.0001)), 0))
		end

		guiInfo.speedo.checkTick = getTickCount()
	end

	-- Trigger vehicle update
	if getPedOccupiedVehicleSeat(localPlayer) == 0 then
		if (getTickCount() - guiInfo.speedo.updateTick)/10000 >= 1 then
			triggerServerEvent("updateVehicleData", guiInfo.speedo.vehicle, guiInfo.speedo.vehicleData)
			guiInfo.speedo.updateTick = getTickCount()
		end
	end

	if settings.blockHud then
		for i = 0, 5 do
			if not guiInfo.speedo.mileageInfo[i] then guiInfo.speedo.mileageInfo[i] = 0 end
			local mileage = string.format("%06d", guiInfo.speedo.vehicleData.mileage)
			local number = tonumber(string.sub(mileage, i + 1, i + 1)) or 0
			guiInfo.speedo.mileageInfo[i] = number
		end
	end
end

function HUD:getVehicleSpeedoColor()
	local color = {255, 255, 255}
	if not guiInfo.speedo.vehicle then return color end
	local visualTuning = getElementData(guiInfo.speedo.vehicle, "visualTuning")
	if visualTuning then
		if visualTuning.speedoColor then
			color = {tonumber(visualTuning.speedoColor[1]), tonumber(visualTuning.speedoColor[2]), tonumber(visualTuning.speedoColor[3])}
		end
	end
	return color
end

function HUD:checkHourGift()
	if not self.giftTick then self.giftTick = getTickCount(); self.giftCount = 0 end
	if (getTickCount() - self.giftTick)/3600000 > 1 then
		self.giftTick = getTickCount()

		local data = getElementData(localPlayer, "characterData")
		if data.premium then
			self.giftCount = self.giftCount + 1
			exports.TR_noti:create(string.format("W nagrodę, za przegranie %d godziny na serwerze, otrzymujesz $%d.", self.giftCount, data.premium == "diamond" and 500 or 200), "money", 7)
			triggerServerEvent("giveHourGift", resourceRoot, data.premium)
		end
	end
end



function setRadarCustomLocation(location, blockRadar)
	if location then
		settings.customLocation = location
		settings.blockRadar = blockRadar

		if string.find(string.lower(location), "casino") then
			settings.insideCasino = true
			triggerServerEvent("getPlayerCasinoCount", resourceRoot)
		end
	else
		settings.customLocation = nil
		settings.blockRadar = nil
		settings.insideCasino = nil
	end
end
addEvent("setRadarCustomLocation", true)
addEventHandler("setRadarCustomLocation", root, setRadarCustomLocation)

function updateCasinoCount(chips)
	settings.casinoChips = tonumber(chips)
end
addEvent("updateCasinoCount", true)
addEventHandler("updateCasinoCount", root, updateCasinoCount)

function getCasinoCount()
	return settings.casinoChips or 0
end


function setHudVisible(state, tick)
	settings.tick = getTickCount()
	settings.state = state and "opening" or "closing"
	settings.currAlpha = settings.alpha
	settings.hudSpeedAnim = tick or 500
	guiInfo.enabled = state
end

function getSpeedoType(model, maxVelocity)
	local speedoType = vehicleSpeedometer[vehModel] or "super"

	if (vehicleSpeedometer[model] == 'motorbike') then
		guiInfo.speedo.type = 'motorbike'
		return "motorbike"
	end

	if maxVelocity <= 160 then return "old" end
	if speedoType == "old" then
		if maxVelocity <= 160 then return "old" end
		guiInfo.speedo.type = 'old'
		return "old"

	elseif speedoType == "standard" then
		if maxVelocity <= 310 then return "super" end
		guiInfo.speedo.type = 'super'
		return "super"
	elseif speedType == "motorbike" then
		guiInfo.speedo.type = 'motorbike'
		return "motorbike"
	end
	return speedoType
end

function playerSpeedometerOpen(vehicle, data, isTuning)
	if not vehicle then
		guiInfo.speedo.vehicle = nil
		guiInfo.speedo.vehicleData = nil
		return
	end

	local vehModel = getElementData(vehicle, "oryginalModel") or getElementModel(vehicle)
	if vehModel == 512 then return end

	local handling = getVehicleHandling(vehicle)

	local speedoType = getSpeedoType(vehModel, handling["maxVelocity"])
	if isTuning then
		guiInfo.speedo = vehicleSpeedometerTuningData[speedoType]
	else
		guiInfo.speedo = vehicleSpeedometerData[speedoType]
	end

	-- guiInfo.speedo.type = speedoType
	guiInfo.speedo.isTuning = isTuning
	guiInfo.speedo.type = speedoType
	guiInfo.speedo.section = 1
	guiInfo.speedo.maxSpeed = handling["maxVelocity"]

	if not guiInfo.speedo.alpha then guiInfo.speedo.alpha = 0 end
	guiInfo.speedo.mileageInfo = {}

	guiInfo.speedo.tick = getTickCount()
	guiInfo.speedo.state = "opening"
	guiInfo.speedo.currAlpha = guiInfo.speedo.alpha

	guiInfo.speedo.vehicle = vehicle
	guiInfo.speedo.vehicleModel = vehModel
	guiInfo.speedo.updateTick = getTickCount()
	guiInfo.speedo.checkTick = getTickCount()
	guiInfo.speedo.vehicleType = getVehicleType(vehicle)

	if not data then
		data = {
			fuel = 25,
			mileage = 0,
		}
	end
	guiInfo.speedo.vehicleData = data
	guiInfo.speedo.vehicleData.maxFuel = vehicleData[vehModel].capacity or 25

	local mileage = string.format("%06d", data.mileage)
	for i = 0, 5 do
		guiInfo.speedo.mileageInfo[i] = tonumber(string.sub(mileage, i + 1, i + 1))
	end

	settings.indicators:updateNewState(vehicle)

	if getPedOccupiedVehicleSeat(localPlayer) == 0 then
		bindKey("c", "down", switchSpeedControl)
		bindKey("x", "down", switchSpeedDisplay)
	end
end
addEvent("playerSpeedometerOpen", true)
addEventHandler("playerSpeedometerOpen", root, playerSpeedometerOpen)


function switchSpeedControl()
	if getElementData(localPlayer, "inJob") then return end
	if settings.hudRaceMode then return end
	--if guiInfo.speedo.type == "old" then return end
	if guiInfo.speedo.control then
		guiInfo.speedo.control = nil
		setPedControlState(localPlayer, "accelerate", false)
		toggleControl("accelerate", true)
	else
		if getVehicleCurrentGear(guiInfo.speedo.vehicle) < 1 then return end
		local speed = math.floor(getElementSpeed(guiInfo.speedo.vehicle, 1))
		if speed >= 20 then
			guiInfo.speedo.control = speed
			setPedControlState(localPlayer, "accelerate", true)
			toggleControl("accelerate", false)
		end
	end
end

function switchSpeedDisplay()
	--if getElementData(localPlayer, "inJob") then return end
	--if guiInfo.speedo.type ~= "super" or guiInfo.speedo.type ~= "standard" then return end
	guiInfo.speedo.section = guiInfo.speedo.section + 1

	if guiInfo.speedo.section > 3 then
		guiInfo.speedo.section = 1
	end
end

function exitVehicle(plr, seat)
	if plr == localPlayer and seat == 0 then
		guiInfo.speedo.tick = getTickCount()
		guiInfo.speedo.state = "closing"
		guiInfo.speedo.currAlpha = guiInfo.speedo.alpha
		unbindKey("c", "down", switchSpeedControl)
		unbindKey("x", "down", switchSpeedDisplay)

		if guiInfo.speedo.control then
			setPedControlState(localPlayer, "accelerate", false)
			toggleControl("accelerate", true)
			guiInfo.speedo.control = nil
		end
	end
end
addEventHandler("onClientVehicleStartExit", root, exitVehicle)


-- FPS
local FPSdata = {
	tick = getTickCount(),
	fps = 0,
	last = {},
}
function getCurrentFPS()
    return FPSdata.fps
end

local function updateFPS(msSinceLastFrame)
	if (getTickCount() - FPSdata.tick)/1000 > 1 then
		local fps = (1 / msSinceLastFrame) * 1000
		if #FPSdata.last == 5 then
			local curr = 0
			for _, v in pairs(FPSdata.last) do
				curr = curr + v
			end
			FPSdata.fps = math.ceil(curr / 5)

		else
			FPSdata.fps = fps
		end

		table.insert(FPSdata.last, 1, fps)
		if #FPSdata.last == 6 then
			table.remove(FPSdata.last, 6)
		end

		FPSdata.tick = getTickCount()
	end
end
addEventHandler("onClientPreRender", root, updateFPS)

function setGUITutorial(state)
	guiInfo.isTutorial = state
end