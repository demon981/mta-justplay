local sx, sy = guiGetScreenSize()

local guiInfo = {
    x = (sx - 350/zoom)/2,
    y = sy - 210/zoom,
    w = 350/zoom,
    h = 100/zoom,

    speedChecks = {60, 90, 120}
}

HandSpeedCamera = {}
HandSpeedCamera.__index = HandSpeedCamera

function HandSpeedCamera:create(...)
    local instance = {}
    setmetatable(instance, HandSpeedCamera)
    if instance:constructor(...) then
        return instance
    end
    return false
end

function HandSpeedCamera:constructor(...)
    self.alpha = 0
    self.checkSpeed = guiInfo.speedChecks[1]
    self.checkSpeedIndex = 1

    self.fonts = {}
    self.fonts.speed = exports.TR_dx:getFont(34)
    self.fonts.km = exports.TR_dx:getFont(14)
    self.fonts.category = exports.TR_dx:getFont(12)
    self.fonts.limit = exports.TR_dx:getFont(10)

    self.func = {}
    self.func.render = function() self:render() end
    self.func.giveTicket = function() self:giveTicket() end
    self.func.checkSpeedLimit = function(...) self:checkSpeedLimit(...) end

    self:open()
    return true
end


function HandSpeedCamera:open()
    self.state = "opening"
    self.tick = getTickCount()

    bindKey("mouse1", "down", self.func.giveTicket)
    bindKey("mouse_wheel_up", "down", self.func.checkSpeedLimit)
    bindKey("mouse_wheel_down", "down", self.func.checkSpeedLimit)

    addEventHandler("onClientRender", root, self.func.render)
end


function HandSpeedCamera:close()
    if self.state ~= "opening" and self.state ~= "opened" then return end

    self.state = "closing"
    self.tick = getTickCount()

    unbindKey("mouse1", "down", self.func.giveTicket)
    unbindKey("mouse_wheel_up", "down", self.func.checkSpeedLimit)
    unbindKey("mouse_wheel_down", "down", self.func.checkSpeedLimit)
end


function HandSpeedCamera:destroy()
    removeEventHandler("onClientRender", root, self.func.render)

    guiInfo.HandSpeedCamera = nil
    self = nil
end

function HandSpeedCamera:checkSpeedLimit(btn)
    if btn == "mouse_wheel_up" then
        self.checkSpeedIndex = math.min(self.checkSpeedIndex + 1, #guiInfo.speedChecks)
        self.checkSpeed = guiInfo.speedChecks[self.checkSpeedIndex]

    elseif btn == "mouse_wheel_down" then
        self.checkSpeedIndex = math.max(self.checkSpeedIndex - 1, 1)
        self.checkSpeed = guiInfo.speedChecks[self.checkSpeedIndex]
    end
end

function HandSpeedCamera:checkObject()
    if getPedTargetStart(localPlayer) then
        local x, y, z = getPedTargetStart(localPlayer)
        local lx, ly, lz = getPedTargetEnd(localPlayer)

        local hit, _, _, _, hitElement = processLineOfSight(x, y, z, lx, ly, lz, true, true, false, true, false, false, false, false, localPlayer)
        if hit and hitElement then
            if getElementType(hitElement) == "vehicle" then
                if self.selectedElement == hitElement then return end
                self.selectedElement = hitElement

                local driver = getVehicleOccupant(hitElement)
                self.vehicleData = {
                    vehicle = hitElement,
                    name = self:getVehicleName(getElementModel(hitElement)),
                    driver = driver and getPlayerName(driver) or "Brak",
                    passangers = #getVehicleOccupants(hitElement),
                    plate = getVehiclePlateText(hitElement),
                }
            end
        else
            self.selectedElement = nil
            self.vehicleData = nil
        end
    else
        self.selectedElement = nil
        self.vehicleData = nil
    end
end

function HandSpeedCamera:updateVehicleInFront()
    if self:isPedAiming(localPlayer) then
        self:checkObject()
    else
        self.vehicleData = nil
        self.selectedElement = nil
    end
end

function HandSpeedCamera:getVehicleName(model)
    if model == 471 then return "Snowmobile" end
    if model == 604 then return "Christmas Manana" end
    return getVehicleNameFromID(model)
end

function HandSpeedCamera:animate()
    if not self.tick then return end
    local progress = (getTickCount() - self.tick)/500
    if self.state == "opening" then
        self.alpha = interpolateBetween(0, 0, 0, 1, 0, 0, progress, "Linear")
        if progress >= 1 then
            self.alpha = 1
            self.state = "opened"
            self.tick = nil
        end

    elseif self.state == "closing" then
      self.alpha = interpolateBetween(1, 0, 0, 0, 0, 0, progress, "Linear")
      if progress >= 1 then
            self.alpha = 0
            self.state = "closed"
            self.tick = nil

            self:destroy()
            return true
        end
    end
end

function HandSpeedCamera:render()
    self:updateVehicleInFront()

    self:animate()
    self:drawBackground(guiInfo.x, guiInfo.y, guiInfo.w, guiInfo.h, tocolor(23,25,31, 255 * self.alpha), 15)

    if self.vehicleData then
        local speed = self:getElementSpeed(self.vehicleData.vehicle, 1)
        if speed >= (self.checkSpeed + 10) then
            dxDrawText(string.format("%02d", speed), guiInfo.x + 22/zoom, guiInfo.y, guiInfo.x + 107/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(44,181,233, 255 * self.alpha), 1/zoom, self.fonts.speed, "center", "top")
        else
            dxDrawText(string.format("%02d", speed), guiInfo.x + 22/zoom, guiInfo.y, guiInfo.x + 107/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(220, 220, 220, 255 * self.alpha), 1/zoom, self.fonts.speed, "center", "top")
        end

        dxDrawText("KM/H", guiInfo.x + 22/zoom, guiInfo.y + 48/zoom, guiInfo.x + 107/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.km, "center", "top")
        dxDrawText(string.format("Limit: %dkm/h", self.checkSpeed), guiInfo.x + 22/zoom, guiInfo.y + 72/zoom, guiInfo.x + 107/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.limit, "center", "top")

        dxDrawText(string.format("Pojazd: #2cb5e9%s", self.vehicleData.name), guiInfo.x + 129/zoom, guiInfo.y + 8/zoom, guiInfo.x + 100/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "top", false, false, false, true)
        dxDrawText(string.format("Kierowca: #2cb5e9%s", self.vehicleData.driver), guiInfo.x + 129/zoom, guiInfo.y + 28/zoom, guiInfo.x + 100/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "top", false, false, false, true)
        dxDrawText(string.format("Rejestracja: #2cb5e9%s", self.vehicleData.plate), guiInfo.x + 129/zoom, guiInfo.y + 48/zoom, guiInfo.x + 100/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "top", false, false, false, true)
        dxDrawText(string.format("Ilość pasażerów: #2cb5e9%d", self.vehicleData.passangers), guiInfo.x + 129/zoom, guiInfo.y + 68/zoom, guiInfo.x + 100/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "top", false, false, false, true)
    else
        dxDrawText("00", guiInfo.x + 22/zoom, guiInfo.y, guiInfo.x + 107/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(220, 220, 220, 255 * self.alpha), 1/zoom, self.fonts.speed, "center", "top")
        dxDrawText("KM/H", guiInfo.x + 22/zoom, guiInfo.y + 48/zoom, guiInfo.x + 107/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.km, "center", "top")
        dxDrawText(string.format("Limit: %dkm/h", self.checkSpeed), guiInfo.x + 22/zoom, guiInfo.y + 72/zoom, guiInfo.x + 107/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.limit, "center", "top")

        dxDrawText("Pojazd: #2cb5e9Brak", guiInfo.x + 129/zoom, guiInfo.y + 8/zoom, guiInfo.x + 100/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "top", false, false, false, true)
        dxDrawText("Kierowca: #2cb5e9Brak", guiInfo.x + 129/zoom, guiInfo.y + 28/zoom, guiInfo.x + 100/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "top", false, false, false, true)
        dxDrawText("Rejestracja: #2cb5e9Brak", guiInfo.x + 129/zoom, guiInfo.y + 48/zoom, guiInfo.x + 100/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "top", false, false, false, true)
        dxDrawText("Ilość pasażerów: #2cb5e9Brak", guiInfo.x + 129/zoom, guiInfo.y + 68/zoom, guiInfo.x + 100/zoom, guiInfo.y + guiInfo.h - 10/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "top", false, false, false, true)
    end
end


function HandSpeedCamera:giveTicket()
    if not self.vehicleData then return end
    if not self.vehicleData.vehicle then return end
    local driver = getVehicleOccupant(self.vehicleData.vehicle, 0)
    if not driver then return end

    local speed = self:getElementSpeed(self.vehicleData.vehicle, 1)
    if speed <= (self.checkSpeed + 10) then return end

    local overspeed = math.max(speed - self.checkSpeed - 10, 0)
    if overspeed == 0 then return end

    if self.lastTicket then
        if (getTickCount() - self.lastTicket)/5000 <= 1 then return end
    end
    self.lastTicket = getTickCount()

    if overspeed <= 50 then
        calc = 400
    else
        calc = 900
    end
    exports.TR_noti:create(string.format("Gracz %s otrzymuje mandat w wysokości $%.2f, a ty otrzymujesz $20.", getPlayerName(driver), calc), "success")
    triggerServerEvent("givePlayerTicket", resourceRoot, driver, calc)
    triggerServerEvent("givePoliceHandcamMoney", resourceRoot)
end

function HandSpeedCamera:isPedAiming(thePedToCheck)
	if isElement(thePedToCheck) then
		if getElementType(thePedToCheck) == "player" or getElementType(thePedToCheck) == "ped" then
			if getPedTask(thePedToCheck, "secondary", 0) == "TASK_SIMPLE_USE_GUN" or isPedDoingGangDriveby(thePedToCheck) then
				return true
			end
		end
	end
	return false
end

function HandSpeedCamera:drawBackground(x, y, w, h, color, radius, post)
    dxDrawRectangle(x, y, w, h, color, post)
    dxDrawRectangle(x + radius, y - radius, w - radius * 2, radius, color, post)
    dxDrawRectangle(x + radius, y + h, w - radius * 2, radius, color, post)
    dxDrawCircle(x + radius, y, radius, 180, 270, color, color, 7, 1, post)
    dxDrawCircle(x + radius, y + h, radius, 90, 180, color, color, 7, 1, post)

    dxDrawCircle(x + w - radius, y, radius, 270, 360, color, color, 7, 1, post)
    dxDrawCircle(x + w - radius, y + h, radius, 0, 90, color, color, 7, 1, post)
end

function HandSpeedCamera:getPosition(element, vec)
	local rot = Vector3(getElementRotation(element))
	local mat = Matrix(Vector3(getElementPosition(element)), rot)
	local newPos = mat:transformPosition(vec)
	return newPos.x, newPos.y, newPos.z, rot.z
end

function HandSpeedCamera:getElementSpeed(theElement, unit)
	if not isElement(theElement) then return 0 end
    local elementType = getElementType(theElement)
    unit = unit == nil and 0 or ((not tonumber(unit)) and unit or tonumber(unit))
    local mult = (unit == 0 or unit == "m/s") and 50 or ((unit == 1 or unit == "km/h") and 180 or 111.84681456)
    return math.max((Vector3(getElementVelocity(theElement)) * mult).length - 3, 0)
end



function checkSpeedHandcam()
    local weapon = getPlayerWeapon(localPlayer)

    if weapon == 26 then
        if guiInfo.HandSpeedCamera then return end
        guiInfo.HandSpeedCamera = HandSpeedCamera:create()
    else
        if not guiInfo.HandSpeedCamera then return end
        guiInfo.HandSpeedCamera:close()
    end
end
setTimer(checkSpeedHandcam, 1000, 0)