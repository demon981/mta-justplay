local settings = {
	driver = {[22] = true, [23] = true, [24] = true, [28] = true, [29] = true, [32] = true},
	passenger = {22,23,24,28,29,32,25,30,31},
	blockedVehicles = {432,601,437,431,592,553,577,488,497,548,563,512,476,447,425,519,520,460,417,469,487,513,441,464,501,465,564,538,449,537,539,570,472,473,493,595,484,430,453,452,446,454,606,591,607,611,610,590,569,611,435,608,584,450},
	steerCars = true,
	steerBikes = true,
	autoEquip = false,

	seatWindows = {
		[0] = 4,
		[1] = 2,
		[2] = 5,
		[3] = 3,
	},

	withoutRoof = {
		[536] = true, -- Blade
		[575] = true, -- Broadway
		[567] = true, -- Savanna
		[533] = true, -- Feltzer
		[480] = true, -- Commet
		[429] = true, -- Banshee
		[555] = true, -- Vindsor
		[506] = true, -- Super-GT
		[531] = true, -- Tractor
		[572] = true, -- Mower
		[485] = true, -- Baggage
		[471] = true, -- Quad
		[571] = true, -- Cart
		[424] = true, -- BF Injector
		[568] = true, -- Bandito
	},
}

local _temp = {}
for i, v in pairs(settings.passenger) do
    _temp[v] = true
end
settings.passenger = _temp


Driveby = {}
Driveby.__index = Driveby

function Driveby:create()
    local instance = {}
    setmetatable(instance, Driveby)
    if instance:constructor() then
        return instance
    end
    return false
end

function Driveby:constructor()
    self.tick = getTickCount()

    self.func = {}
    self.func.render = function(...) self:render(...) end
    self.func.switchWeapon = function(...) self:switchWeapon(...) end
    self.func.switchDriveby = function(...) self:switchDriveby(...) end
    self.func.changeShooting = function(...) self:changeShooting(...) end
    self.func.onPlayerVehicleEnter = function(...) self:onPlayerVehicleEnter(...) end
    self.func.onPlayerVehicleStartExit = function(...) self:stopDriveby(...) end

    addCommandHandler("Switch driveby", self.func.switchDriveby)
    addCommandHandler("Next weapon", self.func.switchWeapon)
    addCommandHandler("Fire driveby", self.func.changeShooting)
    bindKey("mouse2", "down", "Switch driveby", "")

    addEventHandler("onClientPlayerVehicleEnter", localPlayer, self.func.onPlayerVehicleEnter)

    if getPedOccupiedVehicle(localPlayer) then
        self:onPlayerVehicleEnter(nil, getPedOccupiedVehicleSeat(localPlayer))
    end
    return true
end

function Driveby:render()
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then return end

    if self:getElementSpeed(veh, 1) >= 190 then
        self:stopDriveby()
        return
    end
end

function Driveby:switchDriveby()
    if (getTickCount() - self.tick)/500 < 1 then return end
    self.tick = getTickCount()

    if isPedDoingGangDriveby(localPlayer) then
        self:stopDriveby()
    else
        self:startDriveby()
    end
end

function Driveby:changeShooting(...)
    setControlState("vehicle_fire", arg[2] == "down" and true or false)
end

function Driveby:startDriveby()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then return end
    if not isControlEnabled("fire") then return end
    if getElementData(localPlayer, "cuffedBy") then return end
    if self:getElementSpeed(vehicle, 1) >= 190 then return end
    local seat = getPedOccupiedVehicleSeat(localPlayer)
    local vehicleID = getElementModel(vehicle)
    if getVehicleType(vehicle) ~= "Bike" and getVehicleType(vehicle) ~= "BMX" and not isVehicleWindowOpen(vehicle, settings.seatWindows[seat]) and not settings.withoutRoof[vehicleID] then
        exports.TR_noti:create("Aby móc strzelać z pojazdu musisz najpierw otworzyć szybę.", "info")
        return
    end

    local weapons = exports.TR_weaponSlots:getWeaponsTable()
    if not weapons then return end
    if #weapons < 2 then return end

    local avaliableWeapons = self:getPlayerAvaliableWeapons()

    self.weaponSlot = false
    for i, v in pairs(weapons) do
        if avaliableWeapons[v[1]] then
            self.weaponSlot = i
            break
        end
    end

    if self.weaponSlot then
        exports.TR_weaponSlots:setWeaponSlot(2)
        setTimer(setPedDoingGangDriveby, 200, 1, localPlayer, true)

        bindKey("e", "down", "Next weapon", "e")
        bindKey("q", "down", "Next weapon", "q")
        bindKey("mouse1", "down", "Fire driveby", "down")
        bindKey("mouse1", "up", "Fire driveby", "up")

        toggleControl("vehicle_look_left", false)
		toggleControl("vehicle_look_right", false)
		toggleControl("vehicle_secondary_fire", false)

        addEventHandler("onClientRender", root, self.func.render)
        addEventHandler("onClientPlayerVehicleStartExit", localPlayer, self.func.onPlayerVehicleStartExit)
    end
end

function Driveby:stopDriveby()
    self:changeShooting("up")
    setPedDoingGangDriveby(localPlayer, false)
    exports.TR_weaponSlots:setWeaponSlot(1)

    unbindKey("e", "down", "Next weapon", "e")
    unbindKey("q", "down", "Next weapon", "q")
    unbindKey("mouse1", "down", "Fire driveby", "down")
    unbindKey("mouse1", "up", "Fire driveby", "up")

    setControlState("vehicle_fire", false)
    toggleControl("vehicle_look_left", true)
    toggleControl("vehicle_look_right", true)
    toggleControl("vehicle_secondary_fire", true)

    removeEventHandler("onClientRender", root, self.func.render)
    removeEventHandler("onClientPlayerVehicleStartExit", localPlayer, self.func.onPlayerVehicleStartExit)
end

function Driveby:switchWeapon(...)
    local avaliableWeapons = self:getPlayerAvaliableWeapons()

    if arg[2] == "q" then
        local newSlot = self:getPreviousWeapon()
        if not newSlot then return end
        if self.weaponSlot ~= newSlot then
            self.weaponSlot = newSlot
            exports.TR_weaponSlots:setWeaponSlot(self.weaponSlot)
        end

    elseif arg[2] == "e" then
        local newSlot = self:getNextWeapon()
        if not newSlot then return end
        if self.weaponSlot ~= newSlot then
            self.weaponSlot = newSlot
            exports.TR_weaponSlots:setWeaponSlot(self.weaponSlot)
        end
    end
end

function Driveby:getPlayerAvaliableWeapons()
    return self.isDriver and settings.driver or settings.passenger
end

function Driveby:getNextWeapon()
    local avaliableWeapons = self:getPlayerAvaliableWeapons()
    local weapons = exports.TR_weaponSlots:getWeaponsTable()
    if not weapons then return end
    if #weapons < 2 then return end

    for i, v in pairs(weapons) do
        if avaliableWeapons[v[1]] and i > self.weaponSlot then
            return i
        end
    end
    return false
end

function Driveby:getPreviousWeapon()
    local avaliableWeapons = self:getPlayerAvaliableWeapons()
    local weapons = exports.TR_weaponSlots:getWeaponsTable()
    if not weapons then return end
    if #weapons < 2 then return end

    local previousID = false
    for i, v in pairs(weapons) do
        if avaliableWeapons[v[1]] and i < self.weaponSlot then
            previousID = i
        end
    end
    return previousID
end

function Driveby:onPlayerVehicleEnter(_, seat)
    self.isDriver = seat == 0 and true or false
end

function Driveby:getElementSpeed(theElement, unit)
	if not isElement(theElement) then return 0 end
    local elementType = getElementType(theElement)
    unit = unit == nil and 0 or ((not tonumber(unit)) and unit or tonumber(unit))
    local mult = (unit == 0 or unit == "m/s") and 50 or ((unit == 1 or unit == "km/h") and 180 or 111.84681456)
    return (Vector3(getElementVelocity(theElement)) * mult).length
end


Driveby:create()