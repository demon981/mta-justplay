local sx, sy = guiGetScreenSize()

exports.TR_dx:setOpenGUI(false)
exports.TR_dx:setResponseEnabled(false)
setElementData(localPlayer, "blockAction", nil)

local skinSex = {
    -- Fire
    [279] = "m",
    [277] = "m",
    [137] = "k",
    [278] = "k",
}


Interaction = {}
Interaction.__index = Interaction

function Interaction:create(...)
    local instance = {}
    setmetatable(instance, Interaction)
    if instance:constructor(...) then
        return instance
    end
    return false
end

function Interaction:constructor(...)
    self.elements = {}
    self.action = {}
    self.iconSize = 0.3
    self.groundSize = 3
    self.groundCount = 3
    self.anim = 0
    self.blockHelp = false

    self.fonts = {}
    self.fonts.title = exports.TR_dx:getFont(14)
    self.fonts.text = exports.TR_dx:getFont(13)
    self.fonts.info = exports.TR_dx:getFont(20)
    self.fonts.small = exports.TR_dx:getFont(9)

    self.func = {}
    self.func.renderer = function() self:render() end
    self.func.preRenderer = function() self:preRender() end
    self.func.switcher = function() self:switch() end
    self.func.clicker = function(btn, state) self:click(btn, state) end
    self.func.action = function(...) self:updateAction(...) end


    self.func.renderClose = function(...) self:renderClose(...) end
    addEventHandler("onClientRender", root, self.func.renderClose)

    self.colSphere = createColSphere(0, 0, 0, 5)
    setElementInterior(self.colSphere, getElementInterior(localPlayer))
    setElementDimension(self.colSphere, getElementDimension(localPlayer))
    attachElements(self.colSphere, localPlayer, 0, 0, 0)

    bindKey("e", "down", self.func.switcher)
    return true
end

function Interaction:blockHelpWindows(state)
    self.blockHelp = state
end

function Interaction:renderClose()
    if self.blockHelp then return end
    local peds = getElementsWithinColShape(self.colSphere, "ped")
    local objects = getElementsWithinColShape(self.colSphere, "object")

    local cam = Vector3(getCameraMatrix())
    local plrPos = Vector3(getElementPosition(localPlayer))
    local plrInt = getElementInterior(localPlayer)
    local plrDim = getElementDimension(localPlayer)

    for i, v in pairs(peds) do
        if v ~= localPlayer then
            local pos = Vector3(getPedBonePosition(v, 1))
            local dist = getDistanceBetweenPoints3D(plrPos, pos)

            if dist < 3 and self:canInteractObject(plrPos, cam, v, plrInt, plrDim) then
                local alpha = 1 - self.anim
                if dist < 2 then alpha = alpha * 1
                else alpha = alpha * (1 - (dist - 2))
                end

                local cx, cy = getScreenFromWorldPosition(pos)
                if cx and cy then
                    self:drawBackground(cx - 115, cy - 25, 230, 50, tocolor(23,25,31, 180 * alpha), 11)
                    dxDrawImage(cx - 106, cy - 16, 32, 32, "files/images/interaction/talk.png", 0, 0, 0, tocolor(255, 255, 255, 180 * alpha))
                    dxDrawText("Możliwa rozmowa! Naciśnij\n#2cb5e9E #ffffffaby otworzyć #2cb5e9panel interakcji.", cx - 65, cy - 20, cx + 40, cy + 20, tocolor(255, 255, 255, 180 * alpha), 1, self.fonts.small, "left", "center", false, false, false, true)
                end
            end
        end
    end

    for i, v in pairs(objects) do
        local model = self:getElementModel(v)
        if avaliableObjects[model] then
            local pos = Vector3(getElementPosition(v))
            local dist = getDistanceBetweenPoints3D(plrPos, pos)

            if dist < 3 then
                if self:canInteractObject(plrPos, cam, v, plrInt, plrDim) then
                    local alpha = 1 - self.anim
                    if dist < 2 then alpha = alpha * 1
                    else alpha = alpha * (1 - (dist - 2))
                    end

                    local x0, y0, z0, x1, y1, z1 = getElementBoundingBox(v)
                    local centerPos = pos + Vector3(0, 0, (math.abs(z1) - math.abs(z0))/2)
                    local cx, cy = getScreenFromWorldPosition(centerPos)
                    if cx and cy then
                        self:drawBackground(cx - 115, cy - 25, 230, 50, tocolor(23,25,31, 180 * alpha), 11)
                        dxDrawImage(cx - 106, cy - 16, 32, 32, string.format("files/images/interaction/%s.png", objectIcons[model] or "arrow"), 0, 0, 0, tocolor(255, 255, 255, 180 * alpha))
                        dxDrawText("Dostępna interakcja! Naciśnij\n#2cb5e9E #ffffffaby otworzyć #2cb5e9panel interakcji.", cx - 65, cy - 20, cx + 40, cy + 20, tocolor(255, 255, 255, 180 * alpha), 1, self.fonts.small, "left", "center", false, false, false, true)
                    end
                end
            end
        end
    end

    -- if not avaliableObjects[model]
end

function Interaction:rebuildKey()
    bindKey("e", "down", self.func.switcher)
end

function Interaction:switch(force)
    if not self.opened then
        if not exports.TR_dx:canOpenGUI() then return end
        if getPedOccupiedVehicle(localPlayer) then return end
        if not getElementData(localPlayer, "characterUID") then return end
        if self.state then return end

        setElementInterior(self.colSphere, getElementInterior(localPlayer))
        setElementDimension(self.colSphere, getElementDimension(localPlayer))

        self.opened = true
        self.arrow = dxCreateTexture("files/images/interaction/arrow.png", "argb", true, "clamp")
        self.groundEffect = dxCreateTexture("files/images/interaction/ground.png", "argb", true, "clamp")

        self:buildElements()
        addEventHandler("onClientPreRender", root, self.func.preRenderer)
        addEventHandler("onClientRender", root, self.func.renderer)
        addEventHandler("onClientClick", root, self.func.clicker)
        showCursor(true, true)

        self:togglePlayerControl(false)
        self:startAnim()
        exports.TR_dx:setOpenGUI(true)

        self.tick = getTickCount()
        self.anim = 0
        self.state = "show"

    elseif self.opened then
        if self.state ~= "showed" and not force then return end
        if self.blockUse and not force then return end
        self.force = force

        self.tick = getTickCount()
        self.anim = 1
        self.state = "hide"

        self.opened = nil

        removeEventHandler("onClientClick", root, self.func.clicker)
        showCursor(false)

        self:togglePlayerControl(true)
    end
end

function Interaction:close()
    if isElement(self.arrow) then destroyElement(self.arrow) end
    if isElement(self.groundEffect) then  destroyElement(self.groundEffect) end
    self.arrow = nil
    self.groundEffect = nil

    self:clearOptions()
    if not self.force then exports.TR_dx:setOpenGUI(false) end
    self.force = nil
    self.blockUse = nil

    removeEventHandler("onClientPreRender", root, self.func.preRenderer)
    removeEventHandler("onClientRender", root, self.func.renderer)

    self.elements = nil
end

function Interaction:togglePlayerControl(state)
    toggleControl("forwards", state)
    toggleControl("backwards", state)
    toggleControl("left", state)
    toggleControl("right", state)
    -- toggleControl("enter_exit", state)
    cancelEvent()
end

function Interaction:clearOptions()
    self.options = nil
    self.element = nil
    self.x = nil
    self.y = nil
end

function Interaction:startAnim()
    self.tickArrow = getTickCount()
    self.animArrow = 0
    self.stateArrow = "up"

    self.ground = {}
    for i = 1, self.groundCount do
        self.ground[i] = {value = 0, tick = getTickCount() - 1000 * i}
    end
end

function Interaction:animate()
    if self.state == "show" then
        local progress = (getTickCount() - self.tick)/600
        self.anim = interpolateBetween(0, 0, 0, 1, 0, 0, progress, "InOutQuad")

        if progress >= 1 then
            self.tick = getTickCount()
            self.anim = 1
            self.state = "showed"
        end

    elseif self.state == "hide" then
        local progress = (getTickCount() - self.tick)/400
        self.anim = interpolateBetween(1, 0, 0, 0, 0, 0, progress, "InOutQuad")

        if progress >= 1 then
            self.tick = nil
            self.anim = 0
            self.state = nil
            self:close()
        end
    end
end


function Interaction:animateArrow()
    if self.stateArrow == "up" then
        local progress = (getTickCount() - self.tickArrow)/1500
        self.animArrow = interpolateBetween(0, 0, 0, 0.2, 0, 0, progress, "InOutQuad")

        if progress >= 1 then
            self.tickArrow = getTickCount()
            self.animArrow = 0.2
            self.stateArrow = "down"
        end

    elseif self.stateArrow == "down" then
        local progress = (getTickCount() - self.tickArrow)/1500
        self.animArrow = interpolateBetween(0.2, 0, 0, 0, 0, 0, progress, "InOutQuad")

        if progress >= 1 then
            self.tickArrow = getTickCount()
            self.animArrow = 0
            self.stateArrow = "up"
        end
    end
end

function Interaction:preRender()
    self:animateArrow()
    if not self.arrow then return end
    local _, _, worldX, worldY, worldZ = getCursorPosition()
    local cam = Vector3(getCameraMatrix())
    local plrPos = Vector3(getElementPosition(localPlayer))

    local hit, x, y, z, elementHit = nil, nil, nil, nil, nil
    if worldX then
        hit, x, y, z, elementHit = processLineOfSight(cam, worldX, worldY, worldZ, true, true, true, true, true, false, false, false, localPlayer)
    end

    local plrInt = getElementInterior(localPlayer)
    local plrDim = getElementDimension(localPlayer)

    for i, v in pairs(self.elements) do
        if isElement(v) then
            local pos = self:getPos(v)
            if pos then
                if (hit and elementHit == v) or self.element == v then
                    dxDrawMaterialLine3D(pos.x, pos.y, pos.z + self.iconSize + self.animArrow, pos.x, pos.y, pos.z + self.animArrow, self.arrow, self.iconSize, tocolor(255, 255, 255, 255 * self.anim))
                else
                    dxDrawMaterialLine3D(pos.x, pos.y, pos.z + self.iconSize + self.animArrow, pos.x, pos.y, pos.z + self.animArrow, self.arrow, self.iconSize, tocolor(255, 255, 255, 200 * self.anim))
                end

                if not self:canInteractObject(plrPos, cam, v, plrInt, plrDim) then
                    table.remove(self.elements, i)
                    if self.element == v then self:clearOptions() end
                end
            end
        end
    end
end

function Interaction:render()
    self:animate()
    if not isElement(self.groundEffect) then return end
    if getPedOccupiedVehicle(localPlayer) and self.opened then self:switch() return end
    dxDrawImage(0, 0, sx, sy, "files/images/interaction/bg.png", 0, 0, 0, tocolor(255, 255, 255, 255 * self.anim), true)
    dxDrawText("Menu interakcji", 0, sy - 70/zoom, sx, sy, tocolor(44,181,233, 255 * self.anim), 1/zoom, self.fonts.info, "center", "top", false, false, true)
    dxDrawText("Naciśnij myszką na obiekt, z którym chcesz wejść w interakcję.", 0, sy - 35/zoom, sx, sy, tocolor(200, 200, 200, 255 * self.anim), 1/zoom, self.fonts.title, "center", "top", false, false, true)

    if self.options then
        self:drawBackground(self.x, self.y, self.width, (#self.options + 1) * 36/zoom, tocolor(23,25,31, 255 * self.anim), 11)
        dxDrawText(self.name, self.x, self.y, self.x + self.width, self.y + 36/zoom, tocolor(44,181,233, 255 * self.anim), 1/zoom, self.fonts.title, "center", "center")

        for i, v in ipairs(self.options) do
            local color = tocolor(150, 150, 150, 255 * self.anim)
            if self:isMouseInPosition(self.x, self.y + 36/zoom * i, self.width, 36/zoom) then
                color = tocolor(200, 200, 200, 255 * self.anim)
            end
            dxDrawImage(self.x + 8/zoom, self.y + 36/zoom * i + 8/zoom, 18/zoom, 18/zoom, string.format("files/images/interaction/%s.png", v.icon or "cancel"), 0, 0, 0, color)
            dxDrawText(v.text, self.x + 35/zoom, self.y + 36/zoom * i, self.x + self.width, self.y + 36/zoom * (i+1), color, 1/zoom, self.fonts.text, "left", "center")
        end
    end

    local plrPos = Vector3(getElementPosition(localPlayer))
    plrPos.z = getGroundPosition(plrPos.x, plrPos.y, plrPos.z) + 0.03
    for i = 1, self.groundCount do
        local progress = (getTickCount() - self.ground[i].tick)/(self.groundCount * 1000)
        if progress >= 0 then
            self.ground[i].value = interpolateBetween(0, 0, 0, 1, 0, 0, progress, "OutQuad")
            if progress >= 1 then
                self.ground[i].tick = getTickCount()
                self.ground[i].value = 0
            end

            local size = self.groundSize * self.ground[i].value
            dxDrawMaterialLine3D(plrPos.x - size, plrPos.y, plrPos.z, plrPos.x + size, plrPos.y, plrPos.z, self.groundEffect, size * 2, tocolor(255, 255, 255, 255 * (1 - self.ground[i].value) * self.anim), false, plrPos.x, plrPos.y, plrPos.z + 0.5)
        end
    end
end


function Interaction:click(btn, state)
    if btn == "right" or state == "up" then return end
    if self.x then self:clickGui() return end

    local scx, scy, worldX, worldY, worldZ = getCursorPosition()
    local cam = Vector3(getCameraMatrix())

    local hit, x, y, z, elementHit = processLineOfSight(cam, worldX, worldY, worldZ, true, true, true, true, true, false, false, false, localPlayer)
    local obj = false
    for i, v in pairs(self.elements) do
        if v == elementHit then
            obj = elementHit
            break
        end
    end

    if not obj then return end
    self.x, self.y = getScreenFromWorldPosition(x, y, z)
    self:getData(obj)

    self.x = math.min(self.x, sx - self.width)

    if self.y + (#self.options + 1) * 36/zoom >= sy then
        self.y = sy - (#self.options + 1) * 36/zoom
    end
end

function Interaction:clickGui()
    for i, _ in ipairs(self.options) do
        if self:isMouseInPosition(self.x, self.y + 36/zoom * i, self.width, 36/zoom) then
            self:performInteraction(i)
            break
        end
    end
end


function Interaction:updateAction(type, state, notiText)
    if type then
        if type == "jobInfo" then
            exports.TR_jobs:updateLockerInfo()
        else
            self.action[type] = state
        end
    end
    if notiText then exports.TR_noti:create(notiText, "error") end
    self:getData(self.element)
    self.blockUse = nil

    exports.TR_weapons:updateWeapons()
end

function Interaction:buildElements(...)
    self.elements = {}

    local plrPos = Vector3(getElementPosition(localPlayer))
    local plrInt = getElementInterior(localPlayer)
    local plrDim = getElementDimension(localPlayer)
    local camPos = Vector3(getCameraMatrix())

    local peds = getElementsWithinColShape(self.colSphere, "ped")
    local objects = getElementsWithinColShape(self.colSphere, "object")
    local vehicles = getElementsWithinColShape(self.colSphere, "vehicle")
    local players = getElementsWithinColShape(self.colSphere, "player")

    for i, v in pairs(vehicles) do
        if self:canInteractObject(plrPos, camPos, v, plrInt, plrDim) then
            table.insert(self.elements, v)
        end
    end

    for i, v in pairs(players) do
        if v ~= localPlayer and not getPedOccupiedVehicle(v) then
            if self:canInteractObject(plrPos, camPos, v, plrInt, plrDim) then
                table.insert(self.elements, v)
            end
        end
    end

    for i, v in pairs(peds) do
        if self:canInteractObject(plrPos, camPos, v, plrInt, plrDim) then
            table.insert(self.elements, v)
        end
    end

    for i, v in pairs(objects) do
        if self:canInteractObject(plrPos, camPos, v, plrInt, plrDim) then
            table.insert(self.elements, v)
        end
    end
end


function Interaction:getData(element)
    if not element then return end
    self.element = element

    self.options = {}

    local type = getElementType(element)
    local job, jobType = exports.TR_jobs:getPlayerJob()
    if type == "player" then
        table.insert(self.options, {text = "Przywitaj się", action = "trigger", trigger = "interactWithPlayer", data = "welcome", blocked = {"bench"}, icon = "handshake"})
        table.insert(self.options, {text = "Pocałuj się", action = "trigger", trigger = "interactWithPlayer", data = "kiss", blocked = {"bench"}, icon = "heart"})
        table.insert(self.options, {text = "Handluj", action = "trigger", trigger = "interactWithPlayer", data = "trade", icon = "transfer"})
        --table.insert(self.options, {text = "Dodaj do znajomych"})
        self.name = getPlayerName(element)

        local orgID = getElementData(localPlayer, "characterOrgID")
        local orgType = getElementData(localPlayer, "characterOrgType")
        if orgID and orgType == "crime" then
            if getElementData(self.element, "hasBw") and exports.TR_hud:isInDmZone(self.element) then
                table.insert(self.options, {text = "Przeszukaj gracza", action = "openStashItems", icon = "insert"})
            end
        end

        if getElementData(localPlayer, 'characterUID') == 2 then
            table.insert(self.options, {text = "Przeszukaj gracza", action = "openStashItems", icon = "insert"})
            if getElementData(self.element, "hasBw") then
                table.insert(self.options, {text = "Reanimuj gracza", action = "trigger", trigger = "setPlayerReanimation", icon = "reanimation"})
            elseif getElementHealth(self.element) < 100 then
                table.insert(self.options, {text = "Ulecz gracza", action = "healPlayer", icon = "reanimation"})
            end
        end;

        if getElementData(localPlayer, 'characterUID') == 1 then
            table.insert(self.options, {text = "Przeszukaj gracza", action = "openStashItems", icon = "insert"})
        end;

        if job then
            if jobType == "police" then
                local cuffed = getElementData(localPlayer, "cuffed")
                if isElement(cuffed) then
                    if cuffed == element then
                        table.insert(self.options, {text = "Zdejmij kajdanki", action = "trigger", trigger = "setPlayerCuffed", icon = "handcuff"})
                    end
                else
                    if not isElement(getElementData(element, "cuffed")) and not isElement(getElementData(element, "cuffedBy")) then
                        table.insert(self.options, {text = "Zakuj w kajdanki", action = "trigger", trigger = "setPlayerCuffed", icon = "handcuff"})
                    end
                end

                table.insert(self.options, {text = "Sprawdź prawo jazdy", action = "trigger", trigger = "getPlayerLicences", icon = "licence"})
                table.insert(self.options, {text = "Wystaw mandat", action = "givePlayerTicket", icon = "ticket"})


            elseif jobType == "fire" then
                local plrPos = Vector3(getElementPosition(localPlayer))
                local stretch = false
                for i, v in pairs(getElementsByType("object", root, true)) do
                    local model = self:getElementModel(v)
                    if model == 1936 or model == 1938 then
                        if getDistanceBetweenPoints3D(Vector3(getElementPosition(v)), plrPos) < 5 then
                            stretch = v
                            break
                        end
                    end
                end

                if stretch then
                    local model = self:getElementModel(stretch)
                    local plrStretch = getElementData(self.element, "plrStretch")

                    if not plrStretch and model == 1936 then
                        table.insert(self.options, {text = "Połóż na nosze", action = "trigger", trigger = "placePlayerOnStretch", icon = "stretcher", data = stretch})

                    elseif plrStretch then
                        table.insert(self.options, {text = "Zdejmij z noszy", action = "trigger", trigger = "takePlayerFromStretch", icon = "stretcher", data = stretch})
                    end
                end

                if getElementData(self.element, "hasBw") then
                    table.insert(self.options, {text = "Reanimuj gracza", action = "trigger", trigger = "setPlayerReanimation", icon = "reanimation"})
                end

            elseif jobType == "medic" then
                if getElementData(self.element, "hasBw") then
                    table.insert(self.options, {text = "Reanimuj gracza", action = "trigger", trigger = "setPlayerReanimation", icon = "reanimation"})

                elseif getElementHealth(self.element) < 100 then
                    table.insert(self.options, {text = "Ulecz gracza", action = "healPlayer", icon = "reanimation"})
                end

                local plrPos = Vector3(getElementPosition(localPlayer))
                local stretch = false
                for i, v in pairs(getElementsByType("object", root, true)) do
                    local model = self:getElementModel(v)
                    if model == 1936 or model == 1938 then
                        if getDistanceBetweenPoints3D(Vector3(getElementPosition(v)), plrPos) < 5 then
                            stretch = v
                            break
                        end
                    end
                end

                if stretch then
                    local model = self:getElementModel(stretch)
                    local plrStretch = getElementData(self.element, "plrStretch")

                    if not plrStretch and model == 1936 then
                        table.insert(self.options, {text = "Połóż na nosze", action = "trigger", trigger = "placePlayerOnStretch", icon = "stretcher", data = stretch})

                    elseif plrStretch then
                        table.insert(self.options, {text = "Zdejmij z noszy", action = "trigger", trigger = "takePlayerFromStretch", icon = "stretcher", data = stretch})
                    end
                end
            end
        end

    elseif type == "vehicle" then
        local model = self:getElementModel(element)
        local vehType = self:getVehicleType(element)
        local isForSale = getElementData(element, "exchangeData")

        if exports.TR_vehicles:isVehicleOwner(element) then
            if vehType == "Automobile" then
                if isVehicleLocked(self.element) then
                    table.insert(self.options, {text = "Odblokuj zamek", action = "trigger", trigger = "vehicleOpen", icon = "remote"})
                else
                    table.insert(self.options, {text = "Zablokuj zamek", action = "trigger", trigger = "vehicleOpen", icon = "remote"})
                end
            end

            if not withoutHood[model] and vehType ~= "Plane" and vehType ~= "Bike" and vehType ~= "Helicopter" and vehType ~= "Boat" and vehType ~= "Train" and vehType ~= "Trailer" and vehType ~= "BMX" and vehType ~= "Quad" then
                if getVehicleDoorOpenRatio(element, 0) == 0 then
                    table.insert(self.options, {text = "Otwórz maskę", action = "trigger", trigger = "openVehicleDoor", data = "hood", icon = "hood"})
                else
                    table.insert(self.options, {text = "Zamknij maskę", action = "trigger", trigger = "openVehicleDoor", data = "hood", icon = "hood"})
                end
            end

            if not withoutTrunk[model] and vehType ~= "Plane" and vehType ~= "Bike" and vehType ~= "Helicopter" and vehType ~= "Boat" and vehType ~= "Train" and vehType ~= "Trailer" and vehType ~= "BMX" and vehType ~= "Quad" then
                if getVehicleDoorOpenRatio(element, 1) == 0 then
                    table.insert(self.options, {text = "Otwórz bagażnik", action = "trigger", trigger = "openVehicleDoor", data = "trunk", icon = "trunk"})
                else
                    table.insert(self.options, {text = "Zamknij bagażnik", action = "trigger", trigger = "openVehicleDoor", data = "trunk", icon = "trunk"})

                    local vehicleOwners = getElementData(element, "vehicleOwners")
                    if vehicleOwners then
                        if vehicleOwners[1] == getElementData(localPlayer, "characterUID") then
                            table.insert(self.options, {text = "Zawartość bagażnika", action = "openStashItems", icon = "insert"})
                        end
                    end
                end
            end

            if vehType == "Automobile" then
                local rot = getElementRotation(self.element)
                local can = true
                for i, v in pairs(getVehicleOccupants(self.element)) do
                    can = false
                    break
                end
                if can then
                    if rot > 100 and rot < 260 then
                        table.insert(self.options, {text = "Obróć pojazd", action = "trigger", trigger = "flipVehicle", icon = "vehicleFlip"})
                    end
                end
            end
        end

        local vehicleJobOwner = getElementData(self.element, "vehicleOwner")
        if vehicleJobOwner then
            if vehicleJobOwner == localPlayer then
                if model == 448 then
                    table.insert(self.options, {text = "Zabierz pizzę", action = "getPizzaFromVehicle", icon = "pizza"})

                elseif model == 499 and exports.TR_courier:canTakeBoxFromVehicle(self.element) then
                    table.insert(self.options, {text = "Weź paczkę", action = "getBoxFromVehicle", icon = "box"})

                elseif model == 456 then
                    if not self.action["fuelHose"] then
                        table.insert(self.options, {text = "Weź wąż", action = "getFuelHose", type = "water", icon = "firehose"})

                    elseif self.action["fuelHose"] then
                        table.insert(self.options, {text = "Odłóż wąż", action = "getFuelHose", type = "water", icon = "firehose"})
                    end
                end
            end
        end

        if isForSale then
            if isForSale.owner ~= getPlayerName(localPlayer) then
                table.insert(self.options, {text = "Zakup pojazd", action = "trigger", trigger = "buyVehicleExchange", icon = "exchange"})
            end
        end

        local admin = exports.TR_admin:isPlayerOnDuty()
        if admin then
            local block = getElementData(element, "wheelBlock")
            if block then
                table.insert(self.options, {text = "Zdejmij blokadę na koło", action = "blockVehicleWheel", data = block, icon = "blockWheel"})
            end
        end


        if job then
            if jobType == "ers" then
                if self:getVehicleType(element) ~= "bike" then
                    local block = getElementData(element, "wheelBlock")
                    if block then
                        table.insert(self.options, {text = "Zdejmij blokadę na koło", action = "blockVehicleWheel", data = block, icon = "blockWheel"})
                    else
                        table.insert(self.options, {text = "Załóż blokadę na koło", action = "blockVehicleWheel", data = "block", icon = "blockWheel"})
                    end
                end

                if self:getElementModel(element) == 428 or self:getElementModel(element) == 573 then
                    if getElementData(element, "towedVeh") then
                        table.insert(self.options, {text = "Włącz zciągarkę", action = "startVehicleDewinch", icon = "power"})
                    else
                        if not self.action["winchHose"] and not getElementData(localPlayer, "hoseEndPos") then
                            table.insert(self.options, {text = "Weź linę holowniczą", action = "getWinchHose", type = "fuel", icon = "rope"})

                        elseif not getElementData(localPlayer, "hoseEndPos") then
                            table.insert(self.options, {text = "Odłóż linę", action = "getWinchHose", type = "fuel", icon = "rope"})

                        elseif self.action["winchHose"] and getElementData(localPlayer, "hoseEndPos") and getElementData(self.element, "winchPlayer") == localPlayer then
                            table.insert(self.options, {text = "Włącz wciągarkę", action = "startVehicleWinch", icon = "power"})
                        end

                        local plrPos = Vector3(getElementPosition(localPlayer))
                        local gasoline = false
                        for i, v in pairs(getElementsByType("object", root, true)) do
                            local model = self:getElementModel(v)
                            if model == 1650 then
                                if getDistanceBetweenPoints3D(Vector3(getElementPosition(v)), plrPos) < 5 then
                                    gasoline = v
                                    break
                                end
                            end
                        end
                        local data = getElementData(element, "vehicleData")
                        if gasoline and data then
                            if data.fuel < 10 then
                                table.insert(self.options, {text = "Dolej benzynę", action = "trigger", trigger = "giveVehicleGasoline", icon = "gasoline"})
                            end
                        end
                    end

                else
                    if self.action["winchHose"] and not getElementData(localPlayer, "hoseEndPos") then
                        table.insert(self.options, {text = "Zaczep linę holowniczą", action = "setWinchHose", type = "fuel", icon = "rope"})

                    elseif self.action["winchHose"] and getElementData(localPlayer, "hoseEndPos") and getElementData(element, "winchedByPlayer") then
                        if getElementData(element, "winchedByPlayer") == localPlayer or not isElement(getElementData(element, "winchedByPlayer")) then
                            table.insert(self.options, {text = "Odczep linę holowniczą", action = "setWinchHose", type = "fuel", icon = "rope"})
                        end
                    end

                    if isElementFrozen(element) then
                        table.insert(self.options, {text = "Zrzuć ręczny", action = "trigger", trigger = "setVehicleUnfrozen", icon = "handbrake"})
                    end
                end

                local plrModel = self:getElementModel(localPlayer)
                if plrModel == 291 then
                    local skins = exports.TR_jobs:getLockerOptions()
                     if skins then
                        for i, v in pairs(skins) do
                            if plrModel ~= v[2] then
                                table.insert(self.options, {text = string.format("Ubierz %s", v[1]), action = "trigger", trigger = "changeJobSkin", data = v[2], icon = "shirt"})
                            end
                        end
                    end
                else
                    table.insert(self.options, {text = "Ubierz kombinezon nurka", action = "trigger", trigger = "changeJobSkin", data = 291, icon = "shirt"})
                end

            elseif jobType == "police" then
                if getVehicleOccupant(element) then
                    table.insert(self.options, {text = "Sprawdź prawo jazdy kierowcy", action = "trigger", trigger = "getPlayerLicences", icon = "licence"})
                    table.insert(self.options, {text = "Wystaw mandat kierowcy", action = "givePlayerTicket", icon = "ticket"})
                end
                table.insert(self.options, {text = "Wyrzuć kierowcę", action = "trigger", trigger = "removePlayerFromVehicle", data = 0})
                table.insert(self.options, {text = "Wyrzuć pasażera", action = "trigger", trigger = "removePlayerFromVehicle", data = 1})
                table.insert(self.options, {text = "Wyrzuć lewo tył", action = "trigger", trigger = "removePlayerFromVehicle", data = 2})
                table.insert(self.options, {text = "Wyrzuć prawo tył", action = "trigger", trigger = "removePlayerFromVehicle", data = 3})

                if self:getVehicleType(element) ~= "bike" then
                    local block = getElementData(element, "wheelBlock")
                    if block then
                        table.insert(self.options, {text = "Zdejmij blokadę na koło", action = "blockVehicleWheel", data = block, icon = "blockWheel"})
                    else
                        table.insert(self.options, {text = "Załóż blokadę na koło", action = "blockVehicleWheel", data = "block", icon = "blockWheel"})
                    end
                end

                local cuffed = getElementData(localPlayer, "cuffed")
                if cuffed and (model == 598 or model == 560 or model == 426 or model == 426 or model == 551 or model == 421 or model == 490 or model == 427 or model == 497 or model == 507 or model == 482 or model == 597 or model == 596) and getElementData(element, "fractionID") then
                    if isElementAttached(cuffed) then
                        table.insert(self.options, {text = "Wsadź skutą osobę do pojazdu", action = "trigger", trigger = "insertCuffedVehicle", icon = "handcuff"})
                    else
                        table.insert(self.options, {text = "Wysadź skutą osobę z pojazdu", action = "trigger", trigger = "insertCuffedVehicle", icon = "handcuff"})
                    end
                end

            elseif jobType == "fire" then
                if model == 544 then
                    table.insert(self.options, {text = "Steruj drabiną", action = "fireLadder", icon = "fireladder"})

                    local canAODO, haveAODO = self:getAODO()
                    if canAODO then
                        if haveAODO then
                            table.insert(self.options, {text = "Zdejmij SCBA", action = "trigger", trigger = "changePlayerAODO", icon = "gasMask"})
                        else
                            table.insert(self.options, {text = "Załóż SCBA", action = "trigger", trigger = "changePlayerAODO", icon = "gasMask"})
                        end
                    end

                    local canAODO, haveAODO = self:getDoorRemover()
                    if canAODO then
                        if haveAODO then
                            table.insert(self.options, {text = "Odłóż rozpieracz", action = "trigger", trigger = "changePlayerDoorRemover", icon = "hydraulic"})
                        else
                            table.insert(self.options, {text = "Weź rozpieracz", action = "trigger", trigger = "changePlayerDoorRemover", icon = "hydraulic"})
                        end
                    end

                    if not self.action["waterHose"] and self.action["fireHose"] then
                        table.insert(self.options, {text = "Wejdź na drabinę", action = "goFireVehicleWithHose", type = "fire", icon = "firehose"})
                    end

                elseif model == 407 then
                    if not self.action["waterHose"] and not self.action["fireHose"] then
                        table.insert(self.options, {text = "Weź wąż gaśniczy", action = "getFireHose", type = "fire", icon = "firehose"})
                        table.insert(self.options, {text = "Weź wąż uzupełniający", action = "getFireHose", type = "water", icon = "firehose"})

                    elseif self.action["waterHose"] and not self.action["fireHose"] then
                        table.insert(self.options, {text = "Odłóż wąż uzupełniający", action = "getFireHose", type = "water", icon = "firehose"})

                    elseif not self.action["waterHose"] and self.action["fireHose"] then
                        table.insert(self.options, {text = "Odłóż wąż gaśniczy", action = "getFireHose", type = "fire", icon = "firehose"})
                    end

                    local plrModel = self:getElementModel(localPlayer)
                    if plrModel == 290 or plrModel == 292 or plrModel == 291 then
                        local skins = exports.TR_jobs:getLockerOptions()
                        if skins and self.skinSex then
                            for i, v in pairs(skins) do
                                if string.find(v[1], string.format("%%(%s%%)", self.skinSex)) and plrModel ~= v[2] then
                                    table.insert(self.options, {text = string.format("Ubierz %s", string.sub(v[1], 1, -4)), action = "trigger", trigger = "changeJobSkin", data = v[2], icon = "shirt"})
                                end
                            end
                        end

                    elseif plrModel == 278 or plrModel == 277 then
                        local skins = exports.TR_jobs:getLockerOptions()
                        if skins and self.skinSex then
                            for i, v in pairs(skins) do
                                if string.find(v[1], string.format("%%(%s%%)", self.skinSex)) and plrModel ~= v[2] then
                                    table.insert(self.options, {text = string.format("Ubierz %s", string.sub(v[1], 1, -4)), action = "trigger", trigger = "changeJobSkin", data = v[2], icon = "shirt"})
                                end
                            end
                        end

                        table.insert(self.options, {text = "Ubierz kombinezon chemiczny", action = "trigger", trigger = "changeJobSkin", data = 290, icon = "shirt"})
                        table.insert(self.options, {text = "Ubierz ubranie wysokościowe", action = "trigger", trigger = "changeJobSkin", data = 292, icon = "shirt"})
                        table.insert(self.options, {text = "Ubierz kombinezon nurka", action = "trigger", trigger = "changeJobSkin", data = 291, icon = "shirt"})

                    elseif self.skinSex then
                        if plrModel == 137 then
                            table.insert(self.options, {text = "Ubierz ubranie specjalne", action = "trigger", trigger = "changeJobSkin", data = 278, icon = "shirt"})
                        elseif plrModel == 296 or plrModel == 279 then
                            table.insert(self.options, {text = "Ubierz ubranie specjalne", action = "trigger", trigger = "changeJobSkin", data = 277, icon = "shirt"})
                        end

                        table.insert(self.options, {text = "Ubierz kombinezon chemiczny", action = "trigger", trigger = "changeJobSkin", data = 290, icon = "shirt"})
                        table.insert(self.options, {text = "Ubierz ubranie wysokościowe", action = "trigger", trigger = "changeJobSkin", data = 292, icon = "shirt"})
                        table.insert(self.options, {text = "Ubierz kombinezon nurka", action = "trigger", trigger = "changeJobSkin", data = 291, icon = "shirt"})
                    end

                    local canAODO, haveAODO = self:getAODO()
                    if canAODO then
                        if haveAODO then
                            table.insert(self.options, {text = "Zdejmij SCBA", action = "trigger", trigger = "changePlayerAODO", icon = "gasMask"})
                        else
                            table.insert(self.options, {text = "Załóż SCBA", action = "trigger", trigger = "changePlayerAODO", icon = "gasMask"})
                        end
                    end

                    local canAODO, haveAODO = self:getDoorRemover()
                    if canAODO then
                        if haveAODO then
                            table.insert(self.options, {text = "Odłóż rozpieracz", action = "trigger", trigger = "changePlayerDoorRemover", icon = "hydraulic"})
                        else
                            table.insert(self.options, {text = "Weź rozpieracz", action = "trigger", trigger = "changePlayerDoorRemover", icon = "hydraulic"})
                        end
                    end

                elseif model == 433 then
                    local canAODO, haveAODO = self:getDoorRemover()
                    if canAODO then
                        if haveAODO then
                            table.insert(self.options, {text = "Odłóż rozpieracz", action = "trigger", trigger = "changePlayerDoorRemover", icon = "hydraulic"})
                        else
                            table.insert(self.options, {text = "Weź rozpieracz", action = "trigger", trigger = "changePlayerDoorRemover", icon = "hydraulic"})
                        end
                    end
                else
                    table.insert(self.options, {text = "Wyrzuć kierowcę", action = "trigger", trigger = "removePlayerFromVehicle", data = 0})
                    table.insert(self.options, {text = "Wyrzuć pasażera", action = "trigger", trigger = "removePlayerFromVehicle", data = 1})
                    table.insert(self.options, {text = "Wyrzuć lewo tył", action = "trigger", trigger = "removePlayerFromVehicle", data = 2})
                    table.insert(self.options, {text = "Wyrzuć prawo tył", action = "trigger", trigger = "removePlayerFromVehicle", data = 3})
                end
            end

            if jobType == "fire" or jobType == "medic" then
                if model == 416 then
                    local stretchVeh = getElementData(localPlayer, "stretchVeh")
                    if getElementData(self.element, "stretch") and not stretchVeh then
                        table.insert(self.options, {text = "Weź nosze", action = "trigger", trigger = "changePlayerStretch", icon = "stretcher"})

                    elseif getElementData(localPlayer, "stretchVeh") == self.element then
                        table.insert(self.options, {text = "Odłóż nosze", action = "trigger", trigger = "changePlayerStretch", icon = "stretcher"})
                    end
                end
            end
        end
        
        local plrModel = self:getElementModel(localPlayer)
        
        if plrModel == 305 then
            table.insert(self.options, {text = "Zaoferuj malowanie", action = "paintVehicle", icon = "paint"})
        end
        

        self.name = self:getVehicleName(element)

    elseif type == "ped" then
        table.insert(self.options, {text = "Rozpocznij rozmowę", action = "trigger", trigger = "triggerNPC", blocked = {"bench"}, icon = "talk"})
        self.name = getElementData(element, "name")

    elseif type == "object" then
        local model = self:getElementModel(element)
        self.name = avaliableObjects[self:getElementModel(element)]

        if self.name == "Ławka" or self.name == "Fotel" or self.name == "Krzesło" or self.name == "Kanapa" then
            if not self.action["bench"] then
                table.insert(self.options, {text = "Usiądź", action = "benchSit", blocked = {"bench"}, icon = objectIcons[model]})
            elseif element == self.action["bench"] then
                table.insert(self.options, {text = "Zsiądź", action = "benchSit", icon = "bench"})
            end

        elseif self.name == "Automat z przekąskami" or self.name == "Automat z piciem" then
            table.insert(self.options, {text = "Skorzystaj z automatu", action = "vending", blocked = {"bench"}, icon = "vending"})

        elseif self.name == "Bankomat" then
            table.insert(self.options, {text = "Skorzystaj z bankomatu", action = "trigger", trigger = "openAtm", blocked = {"bench"}, icon = "atm"})

        elseif self.name == "Dystrybutor" then
            if not self.action["fueling"] then
                table.insert(self.options, {text = "Weź Standard", action = "fuelStation", fuel = "Standard", blocked = {"bench"}, icon = "fuel"})
                table.insert(self.options, {text = "Weź Plus", action = "fuelStation", fuel = "Plus", blocked = {"bench"}, icon = "fuel"})
                table.insert(self.options, {text = "Weź Premium", action = "fuelStation", fuel = "Premium", blocked = {"bench"}, icon = "fuel"})
                table.insert(self.options, {text = "Weź Diesel", action = "fuelStation", fuel = "ON", blocked = {"bench"}, icon = "fuel"})

            else
                table.insert(self.options, {text = "Odłóż pistolet", action = "fuelStation", fuel = "remove", blocked = {"bench"}, icon = "fuel"})
            end

        elseif self.name == "Szafka na ubrania" then
            local plrSkin = getElementData(localPlayer, "characterData").skin

            if tostring(self:getElementModel(localPlayer)) ~= tostring(plrSkin) then
                table.insert(self.options, {text = "Zdejmij ubranie robocze", action = "trigger", trigger = "changeJobSkin", data = plrSkin, icon = "shirt"})
            else
                local skins = exports.TR_jobs:getLockerOptions()
                if not skins then return end
                for i, v in pairs(skins) do
                    table.insert(self.options, {text = string.format("Ubierz %s", v[1]), action = "trigger", trigger = "changeJobSkin", data = v[2], icon = "shirt"})
                end
            end

        elseif getElementData(element, "gateID") then
            self.name = "Brama wjazdowa"
            local opened = getElementData(self.element, "open")
            if opened then
                table.insert(self.options, {text = "Zamknij bramę", action = "trigger", trigger = "switchGate", data="close", icon = "gate"})
            else
                table.insert(self.options, {text = "Otwórz bramę", action = "trigger", trigger = "switchGate", data="open", icon = "gate"})
            end

        elseif self.name == "Hydrant" then
            if not getElementData(localPlayer, "hoseEndPos") then
                table.insert(self.options, {text = "Podepnij wąż", action = "attachHoseToHydrant", icon = "hydrant"})

            elseif self.hydrant == self.element then
                table.insert(self.options, {text = "Odepnij wąż", action = "attachHoseToHydrant", icon = "hydrant"})
            end

        elseif self.name == "Zawór ropy" then
            if not getElementData(localPlayer, "hoseEndPos") then
                table.insert(self.options, {text = "Podepnij wąż", action = "attachHoseToValve", icon = "valve"})

            elseif self.hydrant == self.element then
                table.insert(self.options, {text = "Odepnij wąż", action = "attachHoseToValve", icon = "valve"})
            end

        elseif self.name == "Komputer" then
            table.insert(self.options, {text = "Otwórz komputer", action = "openComputer", icon = "computer"})

        elseif self.name == "Skrzynia z wyposażeniem" then
            table.insert(self.options, {text = "Tonfa", action = "giveLoudoutWeapons", data = {3,1}, icon = "weapon"})
            table.insert(self.options, {text = "Paralizator", action = "giveLoudoutWeapons", data = {23,2}, icon = "weapon"})
            table.insert(self.options, {text = "Desert Eagle", action = "giveLoudoutWeapons", data = {24,2}, icon = "weapon"})
            table.insert(self.options, {text = "Shotgun", action = "giveLoudoutWeapons", data = {25,3}, icon = "weapon"})
            table.insert(self.options, {text = "HK416", action = "giveLoudoutWeapons", data = {31,5}, icon = "weapon"})
            table.insert(self.options, {text = "HK MP5", action = "giveLoudoutWeapons", data = {29,4}, icon = "weapon"})
            table.insert(self.options, {text = "Nightvision", action = "giveLoudoutWeapons", data = {44,11}, icon = "weapon"})
            table.insert(self.options, {text = "Kamizelka kuloodporna", action = "giveLoudoutWeapons", data = "armor", icon = "weapon"})
            table.insert(self.options, {text = "Pistoler pomiarowy prędkości", action = "giveLoudoutWeapons", data = {26,3}, icon = "weapon"})
            table.insert(self.options, {text = "Odłóż broń", action = "giveLoudoutWeapons", data = "remove", icon = "weapon"})



        elseif self.name == "Nosze medyczne" then
            local _, jobType = exports.TR_jobs:getPlayerJob()
            if jobType == "fire" or jobType == "medic" then
                if not getElementData(localPlayer, "stretchVeh") then
                    table.insert(self.options, {text = "Weź nosze", action = "trigger", trigger = "pickupStretch", icon = "stretcher"})

                    if self:getElementModel(self.element) == 1938 then
                        table.insert(self.options, {text = "Złóż nosze", action = "trigger", trigger = "changeStretchHeight", icon = "stretcher"})
                    else
                        table.insert(self.options, {text = "Rozłóż nosze", action = "trigger", trigger = "changeStretchHeight", icon = "stretcher"})
                    end
                end
            end

        elseif self.name == "Bieżnia" then
            table.insert(self.options, {text = "Skorzystaj z bieżni", action = "useTreadmill", icon = "treadmill"})

        elseif self.name == "Ławka do ćwiczeń" then
            table.insert(self.options, {text = "Skorzystaj z ławeczki", action = "useBenchPress", icon = "benchpress"})

        elseif self.name == "Rower treningowy" then
            table.insert(self.options, {text = "Skorzystaj z roweru", action = "useBikeGym", icon = "stationaryBike"})

        elseif self.name == "Sejf na przedmioty" then
            table.insert(self.options, {text = "Zawartość sejfu", action = "openStashItems", icon = "insert"})

        elseif self.name == "Sterta skrzyń" then
            table.insert(self.options, {text = "Przeszukaj skrzynie", action = "openStashItems", icon = "insert"})

        elseif self.name == "Doniczka" then
            if getElementData(localPlayer, "characterGangType") == "gang" then
                local drugState = getElementData(self.element, "drugState") or false
                if drugState then
                    local homeEnterTick = getTickCount() - drugState.tick
                    local growthPercent = math.max(math.min(1 - ((drugState.growth - homeEnterTick/1000)/86400), 1), 0)
                    local fertilizerPercent = math.max(math.min(1 - ((drugState.fertilizer + homeEnterTick/1000)/21600), 1), 0)
                    self.name = string.format("%s (%.2f%%)", self.name, growthPercent * 100)

                    if fertilizerPercent <= 0 then
                        setElementData(self.element, "drugState", nil, false)
                        local homeID = getElementData(localPlayer, "characterHomeID")
                        local plantID = getElementData(self.element, "objectIndex")

                        triggerServerEvent("removeInteriorDrug", resourceRoot, homeID, plantID)

                        table.insert(self.options, {text = "Zasadź Marichuane  (1 Nasiono)", action = "plantDrugs", data = "marichuana", icon = "flowerPot"})
                        table.insert(self.options, {text = "Zasadź Haszysz  (1 Nasiono)", action = "plantDrugs", data = "haszysz", icon = "flowerPot"})

                    elseif growthPercent >= 1 then
                        table.insert(self.options, {text = "Zbierz plony", action = "takePlantedDrugs", icon = "flowerPot"})
                    else
                        table.insert(self.options, {text = string.format("Nawieź (%.2f%%)", fertilizerPercent * 100), action = "addFertilizer", icon = "flowerPot"})
                    end
                else
                    table.insert(self.options, {text = "Zasadź Marichuane  (1 Nasiono)", action = "plantDrugs", data = "marichuana", icon = "flowerPot"})
                    table.insert(self.options, {text = "Zasadź Haszysz  (1 Nasiono)", action = "plantDrugs", data = "haszysz", icon = "flowerPot"})
                end
            end

        elseif self.name == "Stół do tworzenia narkotyków" then
            --if getElementData(localPlayer, "characterGangType") == "gang" then
            local orgID = getElementData(localPlayer, "characterOrgID")
            local orgType = getElementData(localPlayer, "characterOrgType")
            if orgID and orgType == "crime" then
                table.insert(self.options, {text = "Stwórz Crack  (5 Liści Krasnodrzewu)", action = "createItem", data = {needed = {{type = 24, variant = 1, variant2 = 2, count = 5}}, create = {type = 18, variant = 1, variant2 = 4, value2 = {25, 40}}}, icon = "flowerPot"})
                table.insert(self.options, {text = "Stwórz Metaamfetaminę  (1 Fenyloaceton, 1 Metyloamina)", action = "createItem", data = {needed = {{type = 24, variant = 1, variant2 = 0, count = 1}, {type = 24, variant = 1, variant2 = 1, count = 1}}, create = {type = 18, variant = 2, variant2 = 2, value2 = {25, 40}}}, icon = "flowerPot"})
            end

        elseif self.name == "Stół do tworzenia broni" then
            --if getElementData(localPlayer, "characterGangType") == "gang" then
            local orgID = getElementData(localPlayer, "characterOrgID")
            local orgType = getElementData(localPlayer, "characterOrgType")
            if orgID and orgType == "crime" then
                table.insert(self.options, {text = "Stwórz Glock 19  (400 Części)", action = "createItem", data = {needed = {{type = 24, variant = 2, variant2 = 0, count = 400}}, create = {type = 1, variant = 2, variant2 = 0, value = 22}}, icon = "weapon"})
                -- table.insert(self.options, {text = "Stwórz SIG Mosquito  (400 Części, 1 Tłumik)", action = "createItem", data = {needed = {{type = 24, variant = 2, variant2 = 0, count = 400}, {type = 24, variant = 2, variant2 = 1, count = 1}}, create = {type = 1, variant = 2, variant2 = 2, value = 23}}, icon = "weapon"})
                table.insert(self.options, {text = "Stwórz Mac-10  (1500 Części, 1 Kolba)", action = "createItem", data = {needed = {{type = 24, variant = 2, variant2 = 0, count = 1500}, {type = 24, variant = 2, variant2 = 2, count = 1}}, create = {type = 1, variant = 4, variant2 = 0, value = 28}}, icon = "weapon"})
                table.insert(self.options, {text = "Stwórz HK MP5  (3000 Części, 1 Kolba)", action = "createItem", data = {needed = {{type = 24, variant = 2, variant2 = 0, count = 3000}, {type = 24, variant = 2, variant2 = 2, count = 1}}, create = {type = 1, variant = 4, variant2 = 1, value = 29}}, icon = "weapon"})
                table.insert(self.options, {text = "Stwórz Tec-9  (1250 Części, 1 Kolba)", action = "createItem", data = {needed = {{type = 24, variant = 2, variant2 = 0, count = 1250}, {type = 24, variant = 2, variant2 = 2, count = 1}}, create = {type = 1, variant = 4, variant2 = 2, value = 32}}, icon = "weapon"})
                table.insert(self.options, {text = "Stwórz AK-47  (4000 Części, 2 Kolby)", action = "createItem", data = {needed = {{type = 24, variant = 2, variant2 = 0, count = 4000}, {type = 24, variant = 2, variant2 = 2, count = 2}}, create = {type = 1, variant = 5, variant2 = 0, value = 30}}, icon = "weapon"})
                --table.insert(self.options, {text = "Stwórz HK416  (4000 Części, 2 Kolby, 2 Tłumik)", action = "createItem", data = {needed = {{type = 24, variant = 2, variant2 = 0, count = 4000}, {type = 24, variant = 2, variant2 = 1, count = 2}, {type = 24, variant = 2, variant2 = 2, count = 2, value = 31}}, create = {type = 1, variant = 5, variant2 = 1}}, icon = "weapon"})
                table.insert(self.options, {text = "Remington Model 7400  (2500 Części, 2 Kolby)", action = "createItem", data = {needed = {{type = 24, variant = 2, variant2 = 0, count = 2500}, {type = 24, variant = 2, variant2 = 2, count = 2}}, create = {type = 1, variant = 6, variant2 = 1, value = 34}}, icon = "weapon"})
            end

        elseif self.name == "Ściana wydobywcza" then
            local jobState = exports.TR_mine:getJobState()

            if getElementData(element, "rock") and jobState == "getRock" then
                self.name = "Kamień"
                table.insert(self.options, {text = "Podnieś kamień", action = "updateMinerJob", data = "getRock", icon = "arrowUP"})

            elseif jobState == "placeDynamite" then
                table.insert(self.options, {text = "Umieść ładunki", action = "updateMinerJob", data = "placingDynamite", icon = "dynamite"})
            end

        elseif self.name == "Paczka dynamitu" then
            local jobState = exports.TR_mine:getJobState()

            if jobState == "getDynamite" then
                table.insert(self.options, {text = "Weź dynamity", action = "updateMinerJob", data = "placeDynamite", icon = "dynamite"})
            end
        end
    end

    table.insert(self.options, {text = "Anuluj", action = "close"})

    local optionsTable = {}
    self.width = dxGetTextWidth(self.name, 1/zoom, self.fonts.title)
    for i, v in ipairs(self.options) do
        local can = true
        if v.blocked then
            can = self:checkBlocked(i, v.blocked)
        end

        if can then
            local width = dxGetTextWidth(v.text, 1/zoom, self.fonts.text)
            if self.width < width then
                self.width = width
            end
            table.insert(optionsTable, v)
        end
    end

    self.width = self.width + 47/zoom
    self.options = optionsTable
end

function Interaction:checkBlocked(index, blocked)
    for _, type in ipairs(blocked) do
        if self.action[type] then
            table.remove(self.options, index)
            return false
        end
    end
    return true
end


function Interaction:getElementSpeed(theElement, unit)
	if not isElement(theElement) then return 0 end
    local elementType = getElementType(theElement)
    unit = unit == nil and 0 or ((not tonumber(unit)) and unit or tonumber(unit))
    local mult = (unit == 0 or unit == "m/s") and 50 or ((unit == 1 or unit == "km/h") and 180 or 111.84681456)
    return (Vector3(getElementVelocity(theElement)) * mult).length
end

function Interaction:performInteraction(index)
    if self:getElementSpeed(localPlayer, 1) > 1 and not isElementInWater(localPlayer) then exports.TR_noti:create("Musisz się zatrzymać aby móc wykonać tę interakcję.", "error") return end
    if getPedOccupiedVehicle(localPlayer) then exports.TR_noti:create("Nie możesz użyć interakcji siedząc w pojeździe.", "error") return end

    local isEntering = getPedTask(localPlayer, "primary", 3)
    if isEntering then
        if string.find(string.lower(isEntering), "car") then
            return exports.TR_noti:create("Musisz się zatrzymać aby móc wykonać tę interakcję.", "error")
        end
    end

    local data = self.options[index]
    if not data then return end
    if data.action == "close" then
        self:clearOptions()
        return
    end
    if getElementData(self.element, "blockAction") and getElementData(self.element, "blockAction") ~= localPlayer then exports.TR_noti:create("Nie możesz użyć interakcji na tym obiekcie.", "error") return end
    if getElementData(localPlayer, "blockAction") and data.action ~= "benchSit" and data.action ~= "getFireHose" and data.action ~= "attachHoseToHydrant" and data.action ~= "goFireVehicleWithHose" and data.action ~= "getWinchHose" then exports.TR_noti:create("Nie możesz użyć interakcji, ponieważ już jakąś wykonujesz.", "error") return end
    if getElementData(localPlayer, "plrStretch") then exports.TR_noti:create("Nie możesz użyć interakcji.", "error") return end
    if self.blockUse then exports.TR_noti:create("Nie możesz użyć interakcji, ponieważ już jakąś wykonujesz.", "error") return end
    if exports.TR_jail:isPlayerInPrizon() then exports.TR_noti:create("Nie możesz użyć interakcji, ponieważ jesteś w celi.", "error") return end

    if isElement(getElementData(localPlayer, "cuffedBy")) then exports.TR_noti:create("Nie możesz użyć interakcji kiedy jesteś zakuty.", "error") return end
    if getDistanceBetweenPoints3D(Vector3(getElementPosition(self.element)), Vector3(getElementPosition(localPlayer))) > 5 then
        exports.TR_noti:create("Jesteś za daleko od obiektu interakcji.", "error")
        return
    end

    self.lastInteractedObject = self.element

    if data.action == "trigger" then
        if not data.trigger then
            self:clearOptions()
            exports.TR_noti:create("Wystąpił nieoczekiwany błąd.", "error")
            return
        end
        triggerServerEvent(data.trigger, resourceRoot, self.element, data.data)

        if data.trigger == "triggerNPC" then
            exports.TR_dx:setResponseEnabled(true)

        elseif data.trigger == "openAtm" then
            self:switch(true)
            return

        elseif data.trigger == "getPlayerLicences" then
            exports.TR_dx:setResponseEnabled(true)
            self:switch(true)
            return

        elseif data.trigger == "setPlayerCuffed" then
            self:clearOptions()
            return

        elseif data.trigger == "insertCuffedVehicle" then
            self:clearOptions()
            return

        elseif data.data == "trade" then
            self:clearOptions()
            return

        elseif data.trigger == "buyVehicleExchange" then
            self:switch(false)
            return

        elseif data.trigger == "flipVehicle" then
            self:clearOptions()
            return

        elseif data.trigger == "changeJobSkin" then
            if skinSex[data.data] then
                self.skinSex = skinSex[data.data]
            end
            self:clearOptions()

        else
            self:clearOptions()
        end

    elseif data.action == "goFireVehicleWithHose" then
        local x, y, z = self:getPosition(self.element, Vector3(0, -4.5, 1))
        setElementPosition(localPlayer, x, y, z)
        self:clearOptions()
        return

    elseif data.action == "healPlayer" then
        triggerServerEvent("healMedicPlayer", resourceRoot, self.element)
        self:clearOptions()
        return

    elseif data.action == "benchSit" then
        exports.TR_bench:benchSit(self.element)

        self:clearOptions()
        return

    elseif data.action == "fireLadder" then
        if getVehicleEngineState(self.element) then exports.TR_noti:create("Nie możesz sterować drabiną kiedy silnik jest odpalony.", "error") return end
        exports.TR_fractions:controlFireLadder(self.element)
        self:switch(true)
        return

    elseif data.action == "getFireHose" then
        if not isElementFrozen(self.element) then exports.TR_noti:create("Nie możesz wziąć węza, jeśli pojazd nie stoi na hamulcu ręcznym.", "error") return end

        if not self.action["fireHose"] and not self.action["waterHose"] then
            exports.TR_fractions:plrTakeFireHose(self.element, data.type)
        else
            exports.TR_fractions:plrTakeoutFireHose(self.element, data.type)
        end
        self:clearOptions()
        return

    elseif data.action == "attachHoseToHydrant" then
        if not getElementData(localPlayer, "hoseEndPos") then
            local hosePos = self:getHydrantPos(self.element)
            if not hosePos then exports.TR_noti:create("Nie możesz podłączyć węża z tej strony.", "error") return end

            setElementData(localPlayer, "hoseEndPos", {x = hosePos.x, y = hosePos.y, z = hosePos.z})
            self.hydrant = self.element
        else
            local hydrantUsed = getElementData(self.element, "hydrantUsed")
            hydrantUsed[self.hydrantIndex] = nil
            setElementData(self.element, "hydrantUsed", hydrantUsed)

            setElementData(localPlayer, "hoseEndPos", nil)
            self.hydrant = nil
        end
        self:clearOptions()
        return

    elseif data.action == "getFuelHose" then
        if not isElementFrozen(self.element) then exports.TR_noti:create("Nie możesz wziąć węza, jeśli pojazd nie stoi na hamulcu ręcznym.", "error") return end

        if not self.action["fuelHose"] then
            local x, y, z = self:getPosition(self.element, Vector3(-1.1, -0.06, 0.36))

            self:updateAction("fuelHose", true)
            exports.TR_objectManager:createHose(localPlayer, {x = x, y = y, z = z}, "fire", 15)
            toggleControl("enter_exit", false)
        else
            self:updateAction("fuelHose", nil)
            exports.TR_objectManager:removeHose(localPlayer)
            toggleControl("enter_exit", true)
        end
        self:clearOptions()
        return

    elseif data.action == "attachHoseToValve" then
        if not getElementData(localPlayer, "hoseEndPos") then
            local x, y, z = self:getPosition(self.element, Vector3(0.2, 0, -0.3))

            setElementData(localPlayer, "hoseEndPos", {x = x, y = y, z = z})
            self.hydrant = self.element
        else
            setElementData(localPlayer, "hoseEndPos", nil)
            self.hydrant = nil
        end


        self:clearOptions()
        return

    elseif data.action == "getWinchHose" then
        if not isElementFrozen(self.element) then exports.TR_noti:create("Nie możesz wziąć liny, jeśli pojazd nie stoi na hamulcu ręcznym.", "error") return end
        if isElement(getElementData(self.element, "winchPlayer")) and getElementData(self.element, "winchPlayer") ~= localPlayer then exports.TR_noti:create("Nie możesz wziąć liny, ponieważ inny gracz już ją zabrał.", "error") return end

        if not self.action["winchHose"] then
            local x, y, z = self:getPosition(self.element, Vector3(0, 0, 0.1))
            if getElementModel(self.element) == 573 then
                x, y, z = self:getPosition(self.element, Vector3(-1, 0, -0.12))
            end
            exports.TR_objectManager:createHose(localPlayer, Vector3(x, y, z), "fuel", 100)
            self.action["winchHose"] = true
            setElementData(self.element, "winchPlayer", localPlayer)

        else
            exports.TR_objectManager:removeHose(localPlayer)
            self.action["winchHose"] = nil

            setElementData(self.element, "winchPlayer", nil)
        end
        self:clearOptions()
        return

    elseif data.action == "startVehicleWinch" then
        setElementData(self.element, "wheelBlock", nil)
        setElementData(self.element, "blockAction", true)
        setElementData(self.element, "winchVeh", self.action["winchVehicle"])
        triggerServerEvent("startVehicleWinch", resourceRoot, self.element, self.action["winchVehicle"])

        self.action["winchHose"] = nil
        self:clearOptions()
        return

    elseif data.action == "startVehicleDewinch" then
        if not isElementFrozen(self.element) then exports.TR_noti:create("Aby opuścić pojazd z lawety musi ona stać na ręcznym.", "error") return end

        setElementData(self.element, "blockAction", true)
        triggerServerEvent("startVehicleDewinch", resourceRoot, self.element)
        self:clearOptions()
        return

    elseif data.action == "setWinchHose" then
        if not getElementData(localPlayer, "hoseEndPos") then
            if getElementModel(self.element) == 573 then exports.TR_noti:create("Nie możesz podpiąć liny do tego samego pojazdu.", "error") return end
            if getElementData(self.element, 'vehicleID') == 324 then exports.TR_noti:create("Nie masz uprawnień by podpiać linę do tego pojazdu.", "error") return end
            if getElementData(self.element, "winchedByPlayer") then exports.TR_noti:create("Nie możesz podpiąć kolejnej liny do tego samego pojazdu.", "error") return end
            local x, y, z = self:getPosition(self.element, Vector3(0, 2, 0))
            setElementData(self.element, "winchedByPlayer", localPlayer)
            setElementData(localPlayer, "hoseEndPos", {x = x, y = y, z = z})
            self.action["winchVehicle"] = self.element
        else
            setElementData(self.element, "winchedByPlayer", nil)
            setElementData(localPlayer, "hoseEndPos", nil)
            self.action["winchVehicle"] = nil
        end
        self:clearOptions()
        return

    elseif data.action == "fuelStation" then
        exports.TR_fuelStation:openFuelStation(self.element, data.fuel)
        self:clearOptions()
        return

    elseif data.action == "vending" then
        self:openVendingShop(self:getElementModel(self.element))
        self:switch(true)

    elseif data.action == "givePlayerTicket" then
        if getElementType(self.element) == "vehicle" then
            local driver = getVehicleOccupant(self.element)
            if not driver then exports.TR_noti:create("W pojeździe nie ma kierowcy.", "error"); self:clearOptions() return end

            exports.TR_fractions:openTicketWindow(driver)
            self:switch(true)

        else
            exports.TR_fractions:openTicketWindow(self.element)
            self:switch(true)
        end

    elseif data.action == "fixVehicle" then
        local driver = getVehicleOccupant(self.element)
        if not driver then exports.TR_noti:create("W pojeździe nie ma kierowcy.", "error"); self:clearOptions() return end

       -- exports.TR_mechanic:createMechanic(driver, self.element)
        self:switch(true)

    elseif data.action == "blockVehicleWheel" then
        if not getElementID(self.element) then exports.TR_noti:create("Nie możesz założyć blokady na koło na ten pojazd.", "error"); self:clearOptions() return end

        if data.data == "block" then
            local driver = getVehicleOccupant(self.element)
            if driver then exports.TR_noti:create("Nie możesz założyć blokady na koło jeżeli siedzi w nim kierowca.", "error"); self:clearOptions() return end

            local wheel = exports.TR_vehicles:getNearestWhellID(self.element)
            if not wheel then return end

            triggerServerEvent("setVehicleWheelBlock", resourceRoot, self.element, wheel)

        else
            local wheel = exports.TR_vehicles:getNearestWhellID(self.element)
            if not wheel then return end

            if data.data ~= wheel then exports.TR_noti:create("Stoisz zbyt daleko od założonej blokady by ją zdjąć.", "error"); self:clearOptions() return end

            triggerServerEvent("setVehicleWheelBlock", resourceRoot, self.element, false)
        end

        self:clearOptions()
        return

    elseif data.action == "paintVehicle" then
        local driver = getVehicleOccupant(self.element)
        if not driver then exports.TR_noti:create("W pojeździe nie ma kierowcy.", "error"); self:clearOptions() return end
        if not self:isVehiclePartsFixed(self.element) then exports.TR_noti:create("Pojazd musi być w pełni sprawny aby można było go pomalować.", "error"); self:clearOptions() return end

        triggerServerEvent("requestVehiclePaint", resourceRoot, driver, self.element)
        self:switch()

    elseif data.action == "openComputer" then
        exports.TR_computer:openComputer()
        self:switch(true)

    elseif data.action == "getPizzaFromVehicle" then
        if exports.TR_pizzaboy:getPizzaFromVehicle() then
            self:switch(true)
        else
            self:clearOptions()
        end
        return

    elseif data.action == "getBoxFromVehicle" then
        if getVehicleDoorOpenRatio(self.element, 1) < 1 then
            exports.TR_noti:create("Aby wyjąć paczkę z pojazdu musisz najpierw otworzyć bagażnik.", "error")
            return
        end
        if exports.TR_courier:getBoxFromVehicle() then
            self:switch(true)
            triggerServerEvent("openVehicleDoor", resourceRoot, self.element, "trunk")
        else
            self:clearOptions()
        end
        return

    elseif data.action == "openStashItems" then
        local openType, openID, openModel = false, false, false
        if getElementType(self.element) == "vehicle" then
            if getVehicleDoorOpenRatio(self.element, 1) < 1 then
                exports.TR_noti:create("Aby zarządzać przedmiotami musisz najpierw otworzyć bagażnik.", "error")
                return
            end
            openType = 1
            openID = getElementData(self.element, "vehicleID")
            openModel = self:getElementModel(self.element)

        elseif getElementType(self.element) == "object" then
            if self:getElementModel(self.element) == 2991 then
                openType = 20
                openID = getElementData(self.element, "dockZone")
                openModel = self:getElementModel(self.element)

            else
                openType = 2
                openID = getElementData(localPlayer, "canUseHouseStash")
                openModel = self:getElementModel(self.element)
            end

        elseif getElementType(self.element) == "player" then
            openType = 0
            openID = getElementData(self.element, "characterUID")
            openModel = self:getElementModel(self.element)
        end

        if not openType or not openID then return end
        self:switch(true)
        triggerServerEvent("openTrunkItems", resourceRoot, openType, openID, openModel)


    elseif data.action == "giveLoudoutWeapons" then
        local plrWeapons = self:getPedWeapons(localPlayer)
        if data.data ~= "remove" and data.data ~= "armor" then
            for i, v in pairs(weaponsSlots) do
                local slot = plrWeapons[v]
                if slot == data.data[2] then
                    exports.TR_noti:create("Masz już jedną broń na tym slocie.", "error")
                    return
                end
            end
        end

        if data.data == "remove" then
            if skin == 46 or skin == 59 or skin == 185 or skin == 12 or skin == 216 or skin == 91 then
                exports.TR_jobs:createInformation("San Andreas Police Department", "Udaj się na strzelnicę i odbierz swoje wyposażenie.")
            else
                exports.TR_jobs:createInformation("San Andreas Police Department", "Udaj się do przebieralni i ubierz odpowiedniego skina lub od razu wybierz się na strzelnicę i odbierz swoje wyposażenie.")
            end
        elseif data.data ~= "armor" then
            if #plrWeapons < 1 then exports.TR_jobs:hideInformation() end
        end

        triggerServerEvent("giveLoudoutWeapons", resourceRoot, data.data)
        self:clearOptions()

    elseif data.action == "useTreadmill" then
        if not exports.TR_gym:canUseGym(self.element) then return end

        exports.TR_gym:startTreadmillWorkout(self.element)
        self:switch(true)
        return

    elseif data.action == "useBenchPress" then
        if not exports.TR_gym:canUseGym(self.element) then return end

        exports.TR_gym:startBenchPressWorkout(self.element)
        self:switch(true)
        return

    elseif data.action == "useBikeGym" then
        if not exports.TR_gym:canUseGym(self.element) then return end

        exports.TR_gym:startBikeWorkout(self.element)
        self:switch(true)
        return

    elseif data.action == "createItem" then
        local itemsToRemove = {}
        for i, v in pairs(data.data.needed) do
            local hasItem = exports.TR_items:hasPlayerItem(v.type, v.variant, v.variant2, v.count)
            if not hasItem then exports.TR_noti:create("Nie posiadasz wszystkich składników aby móc stworzyć nowy przedmiot.", "error") return end
            table.insert(itemsToRemove, {
                ID = hasItem,
                count = v.count,
            })
        end

        for i, v in pairs(itemsToRemove) do
            exports.TR_items:takePlayerItem(v.ID, v.count)
            triggerServerEvent("takeItemCount", resourceRoot, v.ID, v.count)
        end

        if type(data.data.create.value2) == "table" then
            triggerServerEvent("createInteractionItem", resourceRoot, data.data.create.type, data.data.create.variant, data.data.create.variant2, data.data.create.value, math.random(data.data.create.value2[1], data.data.create.value2[2]))
        else
            triggerServerEvent("createInteractionItem", resourceRoot, data.data.create.type, data.data.create.variant, data.data.create.variant2, data.data.create.value, data.data.create.value2)
        end

    elseif data.action == "takePlantedDrugs" then
        local drugState = getElementData(self.element, "drugState")
        local homeID = getElementData(localPlayer, "characterHomeID")
        local plantID = getElementData(self.element, "objectIndex")

        triggerServerEvent("removeInteriorDrug", resourceRoot, homeID, plantID)

        setElementData(self.element, "drugState", nil)

        if tonumber(drugState.plantType) == 1 then
            triggerServerEvent("createInteractionItem", resourceRoot, 18, 0, 1, 1, math.random(15, 30))
        else
            triggerServerEvent("createInteractionItem", resourceRoot, 18, 0, 0, 1, math.random(15, 30))
        end

    elseif data.action == "addFertilizer" then
        local hasItem = exports.TR_items:hasPlayerItem(24, 0, 2, 1)
        if not hasItem then exports.TR_noti:create("Nie posiadasz nawozu.", "error") return end

        exports.TR_items:takePlayerItem(hasItem, 1)
        triggerServerEvent("takeItemCount", resourceRoot, hasItem, 1)

        local homeID = getElementData(localPlayer, "characterHomeID")
        local plantID = getElementData(self.element, "objectIndex")

        local drugState = getElementData(self.element, "drugState")
        local homeEnterTick = getTickCount() - drugState.tick
        drugState.fertilizer = -homeEnterTick/1000
        setElementData(self.element, "drugState", drugState, false)

        triggerServerEvent("refilFertilizerInteriorDrugs", resourceRoot, homeID, plantID)
        self:clearOptions()
        exports.TR_noti:create("Roślina została pomyślnie nawieziona.", "success")
        return


    elseif data.action == "plantDrugs" then
        if data.data == "marichuana" then
            local hasItem = exports.TR_items:hasPlayerItem(24, 0, 0, 1)
            if not hasItem then exports.TR_noti:create("Nie posiadasz nasion aby móc je zasadzić.", "error") return end

            exports.TR_items:takePlayerItem(hasItem, 1)
            triggerServerEvent("takeItemCount", resourceRoot, hasItem, 1)

            local homeID = getElementData(localPlayer, "characterHomeID")
            local plantID = getElementData(self.element, "objectIndex")

            triggerServerEvent("plantInteriorDrugs", resourceRoot, homeID, plantID, 1)

            setElementData(self.element, "drugState", {
                tick = getTickCount(),
                growth = 86400,
                fertilizer = 0,
                plantType = 1,
                tick = getTickCount(),
            }, false)

        elseif data.data == "haszysz" then
            local hasItem = exports.TR_items:hasPlayerItem(24, 0, 1, 1)
            if not hasItem then exports.TR_noti:create("Nie posiadasz nasion aby móc je zasadzić.", "error") return end

            exports.TR_items:takePlayerItem(hasItem, 1)
            triggerServerEvent("takeItemCount", resourceRoot, hasItem, 1)

            local homeID = getElementData(localPlayer, "characterHomeID")
            local plantID = getElementData(self.element, "objectIndex")

            triggerServerEvent("plantInteriorDrugs", resourceRoot, homeID, plantID, 2)

            setElementData(self.element, "drugState", {
                tick = getTickCount(),
                growth = 86400,
                fertilizer = 0,
                plantType = 2,
                tick = getTickCount(),
            }, false)
        end

        self:clearOptions()
        exports.TR_noti:create("Nasiono zostało pomyślnie zasadzone.", "success")
        return

    elseif data.action == "updateMinerJob" then
        if data.data == "getRock" then destroyElement(self.element) end

        exports.TR_mine:setStage(data.data)
        if data.data == "placingDynamite" then
            self:switch(true)
            return
        end

        self:clearOptions()
        return
    end
    self.blockUse = true
end

function Interaction:canInteractObject(plrPos, camPos, object, int, dim)
    if getPedOccupiedVehicle(localPlayer) then return false end
    if not isElement(object) then return false end
    if getElementData(object, "blockAction") and object ~= self.lastInteractedObject then return false end
    if getElementInterior(object) ~= int or getElementDimension(object) ~= dim then return false end
    local pos = Vector3(getElementPosition(object))
    local type = getElementType(object)
    local distance = self.groundSize + 0.1
    if type == "vehicle" then distance = self.groundSize + 2 end

    if type == "object" then
        local model = self:getElementModel(object)
        if not avaliableObjects[model] and not getElementData(object, "gateID") then return false end
        if model == 3465 then
            pos.z = pos.z + 0.2
        elseif model == 2943 then
            pos.z = pos.z + 0.2
        elseif model == 14782 or model == 2200 then
            local skins = exports.TR_jobs:getLockerOptions()
            if not skins then return end
        elseif getElementData(object, "gateID") then
            if model == 2909 then
                pos.z = pos.z + 1
            elseif model == 10184 then
                pos.z = pos.z - 1
                distance = distance + 50
            else
                pos.z = pos.z - 1
                distance = distance + 2
            end

        elseif model == 1211 then
            if getElementData(localPlayer, "firehose") ~= "water" then return false end

        elseif model == 1880 then
            if not self.action["fuelHose"] then return false end
            if not exports.TR_dieselTransport:canUnloadOil(object) and getElementData(object, "removeValve") then return false end
            if not exports.TR_dieselTransport:canLoadFuel(object) and getElementData(object, "fuelValve") then return false end

        elseif model == 2190 then
            if not exports.TR_computer:canUseComputer() then return false end
            -- if getElementInterior(localPlayer) < 1 or getElementDimension(localPlayer) < 1 then return false end
        elseif model == 964 then
            local _, jobType = exports.TR_jobs:getPlayerJob()
            if jobType ~= "police" then return false end

        elseif model == 3931 then
            local job = exports.TR_jobs:getPlayerJob()
            if job ~= "TR_mine" then return false end

            local jobState = exports.TR_mine:getJobState()
            if getElementData(object, "rock") and jobState ~= "getRock" then return false end
            if not getElementData(object, "rock") and jobState ~= "placeDynamite" then return false end

        elseif model == 1654 then
            local job = exports.TR_jobs:getPlayerJob()
            if job ~= "TR_mine" then return false end

            local jobState = exports.TR_mine:getJobState()
            if jobState ~= "getDynamite" then return false end

        elseif model == 1938 or model == 1936 then
            local _, jobType = exports.TR_jobs:getPlayerJob()
            if jobType ~= "fire" and jobType ~= "medic" then return false end
            pos.z = pos.z + 1

        elseif model == 2627 or model == 2629 or model == 2630 then
            pos.z = pos.z + 1

        elseif model == 2332 then
            if not getElementData(localPlayer, "canUseHouseStash") then return false end
            pos.z = pos.z + 0.1

        elseif model == 2991 then
            if not getElementData(object, "dockZone") then return false end
            pos.z = pos.z + 0.1

        elseif model == 2203 then
            if not getElementData(localPlayer, "canUseHouseStash") then return false end
            if getElementData(localPlayer, "characterOrgType") ~= "crime" then return false end
            if getElementData(localPlayer, "characterGangType") ~= "gang" then return false end
            pos.z = pos.z + 0.1

        elseif model == 3001 then
            if not getElementData(localPlayer, "canUseHouseStash") then return false end
            if getElementData(localPlayer, "characterOrgType") ~= "crime" then return false end
            --if getElementData(localPlayer, "characterGangType") ~= "mafia" then return false end
            pos.z = pos.z + 0.1

        elseif model == 3002 then
            if not getElementData(localPlayer, "canUseHouseStash") then return false end
            if getElementData(localPlayer, "characterOrgType") ~= "crime" then return false end
            --if getElementData(localPlayer, "characterGangType") ~= "weapon" then return false end
            pos.z = pos.z + 0.1
        end

    elseif type == "vehicle" then
        local job, jobType = exports.TR_jobs:getPlayerJob()
        if job then
            if jobType == "police" then return true end
            if jobType == "ers" then return true end
        end
        if self:getVehicleType(object) == "BMX" then return false end
        if getElementData(object, "exchangeData") then return true end
        -- exports.TR_painting:canBePainted(object) and 
        --if exports.TR_mechanic:canBeFixed(object) and self:getElementModel(localPlayer) == 50 then return true end
        if self:getElementModel(localPlayer) == 305 then return true end
        local vehicleJobOwner = getElementData(object, "vehicleOwner")
        if vehicleJobOwner == localPlayer then return true end
        if not exports.TR_vehicles:isVehicleOwner(object) then return false end
    end

    if getDistanceBetweenPoints3D(plrPos, pos) < distance and isLineOfSightClear(camPos, pos, true, false, false, false, false, false, false, localPlayer) then
        return true
    end
    return false
end


function Interaction:getAODO()
    local plrModel = self:getElementModel(localPlayer)
    if plrModel ~= 278 and plrModel ~= 277 then return false, false end

    local weapons = getElementData(localPlayer, "fakeWeapons")
    if weapons then
        local have = false
        for i, v in pairs(weapons) do
            if v == "aodoF" or v == "aodo" then
                have = true
                break
            end
        end

        if have then
            return true, true
        else
            return true, false
        end
    end
    return true, false
end

function Interaction:getDoorRemover()
    local plrModel = self:getElementModel(localPlayer)
    if plrModel ~= 278 and plrModel ~= 277 then return false, false end

    local weapons = getElementData(localPlayer, "fakeWeapons")
    if weapons then
        local have = false
        for i, v in pairs(weapons) do
            if v == "dRemove" then
                have = true
                break
            end
        end

        if have then
            return true, true
        else
            return true, false
        end
    end
    return true, false
end

function Interaction:getPos(element)
    local pos = Vector3(getElementPosition(element))
    local type = getElementType(element)
    if not pos then return false end

    if type == "player" or type == "ped" then
        pos = Vector3(getPedBonePosition(element, 8))
        pos.z = pos.z + 0.55
        return pos

    elseif type == "vehicle" then
        local bound, _, _, _, _, maxZ = getElementBoundingBox(element)
        if not bound then
            pos.z = pos.z + 0.2
            return pos
        end
        pos.z = pos.z + maxZ + 0.2
        return pos

    elseif type == "object" then
        local model = self:getElementModel(element)
        if model == 3465 then
            pos.z = pos.z + 2.3
        elseif model == 2943 then
            pos.z = pos.z + 1.9
            return pos
        elseif model == 2190 then
            local x, y, z = self:getPosition(element, Vector3(-0.3, -0.2, 0.8))
            return Vector3(x, y, z)
        elseif model == 964 then
            pos.z = pos.z + 0.8
            return pos
        end

        local _, _, _, _, _, maxZ = getElementBoundingBox(element)
        pos.z = pos.z + maxZ + 0.2
        return pos
    end
    return pos
end

function Interaction:isVehiclePartsFixed(veh)
    for i = 5, 6 do
        if getVehiclePanelState(veh, i) > 0 then
            return false
        end
    end
    for i = 0, 5 do
        if getVehicleDoorState(veh, i) > 0 then
            return false
        end
    end
    return true
end

function Interaction:getHydrantPos(el)
    local hydrantUsed = getElementData(el, "hydrantUsed") or {}
    local plrPos = Vector3(getElementPosition(localPlayer))
    local x, y, z = self:getPosition(el, Vector3(0.3, 0, 0.2))
    local x2, y2, z2 = self:getPosition(el, Vector3(-0.3, 0, 0.2))

    if getDistanceBetweenPoints3D(plrPos, x, y, z) < getDistanceBetweenPoints3D(plrPos, x2, y2, z2) then
        if isElement(hydrantUsed[1]) then return false end

        hydrantUsed[1] = localPlayer
        setElementData(el, "hydrantUsed", hydrantUsed)
        self.hydrantIndex = 1
        return Vector3(x, y, z)
    else
        if isElement(hydrantUsed[2]) then return false end

        hydrantUsed[2] = localPlayer
        setElementData(el, "hydrantUsed", hydrantUsed)
        self.hydrantIndex = 2
        return Vector3(x2, y2, z2)
    end
    return false
end

function Interaction:getPedWeapons(ped)
	local playerWeapons = {}
	if ped and isElement(ped) and getElementType(ped) == "ped" or getElementType(ped) == "player" then
		for i=2,9 do
			local wep = getPedWeapon(ped, i)
			if wep and wep ~= 0 then
				table.insert(playerWeapons, wep)
			end
		end
	else
		return false
	end
	return playerWeapons
end

function Interaction:getVehicleType(veh)
	return getVehicleType(self:getElementModel(veh))
end

function Interaction:getElementModel(veh)
	return getElementData(veh, "oryginalModel") or getElementModel(veh)
end

function Interaction:getVehicleName(veh)
    local model = self:getElementModel(veh)
    if model == 471 then return "Snowmobile" end
    if model == 604 then return "Christmas Manana" end
    return getVehicleNameFromID(model)
end

function Interaction:getPosition(element, vec)
	local rot = Vector3(getElementRotation(element))
	local mat = Matrix(Vector3(getElementPosition(element)), rot)
	local newPos = mat:transformPosition(vec)
	return newPos.x, newPos.y, newPos.z, rot.z
end


function Interaction:drawBackground(x, y, rx, ry, color, radius, post)
    rx = rx - radius * 2
    ry = ry - radius * 2
    x = x + radius
    y = y + radius

    if (rx >= 0) and (ry >= 0) then
        dxDrawRectangle(x, y, rx, ry, color, post)
        dxDrawRectangle(x, y - radius, rx, radius, color, post)
        dxDrawRectangle(x, y + ry, rx, radius, color, post)
        dxDrawRectangle(x - radius, y, radius, ry, color, post)
        dxDrawRectangle(x + rx, y, radius, ry, color, post)

        dxDrawCircle(x, y, radius, 180, 270, color, color, 7, 1, post)
        dxDrawCircle(x + rx, y, radius, 270, 360, color, color, 7, 1, post)
        dxDrawCircle(x + rx, y + ry, radius, 0, 90, color, color, 7, 1, post)
        dxDrawCircle(x, y + ry, radius, 90, 180, color, color, 7, 1, post)
    end
end

function Interaction:isMouseInPosition(psx,psy,pssx,pssy)
    if not isCursorShowing() then return end
    cx,cy=getCursorPosition()
    cx,cy=cx*sx,cy*sy
    if cx >= psx and cx <= psx+pssx and cy >= psy and cy <= psy+pssy then
        return true,cx,cy
    else
        return false
    end
end

function Interaction:openVendingShop(model)
    if model == 1776 then
        exports.TR_items:createShop("Automat z jedzeniem", {
            {
                type = 2,
                variant = 0,
                variant2 = 0,
                price = 3.50,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 1,
                price = 7.50,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 2,
                price = 3,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 3,
                price = 4.20,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 4,
                price = 3.50,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 5,
                price = 4,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 6,
                price = 5.50,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 7,
                price = 3,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 8,
                price = 2.50,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 9,
                price = 3.60,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 10,
                price = 4.50,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 11,
                price = 3,
            },
            {
                type = 2,
                variant = 0,
                variant2 = 12,
                price = 4,
            },
        })

    elseif model == 955 or model == 1775 then
        exports.TR_items:createShop("Automat z piciem", {
            {
                type = 2,
                variant = 1,
                variant2 = 0,
                price = 3.50,
            },
            {
                type = 2,
                variant = 1,
                variant2 = 1,
                price = 3,
            },
            {
                type = 2,
                variant = 1,
                variant2 = 2,
                price = 5,
            },
            {
                type = 2,
                variant = 1,
                variant2 = 3,
                price = 2,
            },
            {
                type = 2,
                variant = 1,
                variant2 = 4,
                price = 2.50,
            },
            {
                type = 2,
                variant = 1,
                variant2 = 5,
                price = 6,
            },
            {
                type = 2,
                variant = 1,
                variant2 = 6,
                price = 4,
            },
            {
                type = 2,
                variant = 1,
                variant2 = 7,
                price = 7,
            },
            {
                type = 2,
                variant = 1,
                variant2 = 8,
                price = 6.50,
            },
            {
                type = 2,
                variant = 1,
                variant2 = 9,
                price = 4,
            },
        })
    end
end

local action = Interaction:create()
function closeInteraction()
    if action.opened then
        action.blockUse = nil
        action:switch(true)
    end
end

function updateInteraction(...)
    action:updateAction(...)
end
addEvent("updateInteraction", true)
addEventHandler("updateInteraction", root, updateInteraction)

function rebuildKey()
    action:rebuildKey()
end

function blockHelpWindows(state)
    action:blockHelpWindows(state)
end


setElementData(localPlayer, "hoseEndPos", nil)
toggleControl("enter_exit", true)