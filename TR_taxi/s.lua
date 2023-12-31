local taxiRequests = {}
local botRequests = {}

local botSettings = {
    ['places'] = {
        pos = {
            Vector3(0, 0, 13),
            Vector3(0, 10, 13),
        },
        targets = {
            Vector3(10, 0, 13),
        },
    }
}

local taxiPos = {
    {
        jobID = 2,
        plate = "LS TAXI",
        positions = {
            {
                model = 438,
                pos = Vector3(1704.1467285156, -1502.0827392578, 13.3828125),
                rot = Vector3(0, 0, 113),
            },
            {
                model = 438,
                pos = Vector3(1704.1467285156, -1506.5827392578, 13.3828125),
                rot = Vector3(0, 0, 113),
            },
            {
                model = 438,
                pos = Vector3(1704.1467285156, -1511.0827392578, 13.3828125),
                rot = Vector3(0, 0, 113),
            },
            {
                model = 438,
                pos = Vector3(1704.1467285156, -1515.5827392578, 13.3828125),
                rot = Vector3(0, 0, 113),
            },
            {
                model = 420,
                pos = Vector3(1704.1467285156, -1520.0827392578, 13.1528125),
                rot = Vector3(0, 0, 113),
            },
            {
                model = 420,
                pos = Vector3(1704.1467285156, -1524.3827392578, 13.1528125),
                rot = Vector3(0, 0, 113),
            },
            {
                model = 420,
                pos = Vector3(1704.1467285156, -1528.5827392578, 13.1528125),
                rot = Vector3(0, 0, 113),
            },
            {
                model = 420,
                pos = Vector3(1704.1467285156, -1533.0827392578, 13.1528125),
                rot = Vector3(0, 0, 113),
            },
        }
    },

    {
        jobID = 5,
        plate = "SF TAXI",
        positions = {
            { --- San Fierro
                model = 420,
                pos = Vector3(-2265.6923828125,216.4091796875, 34.93),
                rot = Vector3(0, 0, 90),
            },
            {
                model = 420,
                pos = Vector3(-2265.6923828125,212.5458984375, 34.93),
                rot = Vector3(0, 0, 90),
            },
            {
                model = 420,
                pos = Vector3(-2265.6923828125,208.5693359375, 34.93),
                rot = Vector3(0, 0, 90),
            },
            {
                model = 420,
                pos = Vector3(-2265.6923828125,204.5322265625, 34.93),
                rot = Vector3(0, 0, 90),
            },
            {
                model = 420,
                pos = Vector3(-2265.6923828125,200.6142578125, 34.93),
                rot = Vector3(0, 0, 90),
            },
            {
                model = 420,
                pos = Vector3(-2265.6923828125,196.650390625, 34.93),
                rot = Vector3(0, 0, 90),
            },
            {
                model = 420,
                pos = Vector3(-2265.6923828125,192.6796875, 34.93),
                rot = Vector3(0, 0, 90),
            },
            {
                model = 420,
                pos = Vector3(-2265.6923828125,188.7158203125, 34.93),
                rot = Vector3(0, 0, 90),
            },
            {
                model = 420,
                pos = Vector3(-2265.6923828125,184.9287109375, 34.93),
                rot = Vector3(0, 0, 90),
            },
        },
    },
}

function startTaxi()
    setModelHandling(438, "maxVelocity", 84)
    for i, v in pairs(taxiPos) do
        createTaxi(v.jobID, v.plate, v.positions)
    end
end

function createTaxi(jobID, plate, pos)
    for i, v in pairs(pos) do
        local veh = createVehicle(v.model or 438, v.pos.x, v.pos.y, v.pos.z, v.rot.x, v.rot.y, v.rot.z, string.format("%s%d", plate, i))
        setElementFrozen(veh, true)
        setElementData(veh, "vehicleData", {
            fuel = 20,
            mileage = math.random(40000, 60000),
            engineType = "d",
        }, false)
        setVehicleOverrideLights(veh, 1)
        setVehicleTaxiLightOn(veh, false)

        setElementData(veh, "taxiID", jobID)

        setVehicleRespawnPosition(veh, v.pos.x, v.pos.y, v.pos.z, v.rot.x, v.rot.y, v.rot.z)
    end
end
startTaxi()

function removePlayerFromTaxi(vehicle)
    triggerClientEvent(getVehicleOccupants(vehicle), "removePlayerFromVehicle", resourceRoot)
end
addEvent("removePlayerFromTaxi", true)
addEventHandler("removePlayerFromTaxi", resourceRoot, removePlayerFromTaxi)

function removePlayerTaxi(player)
    local plr = player and player or client

    for i, v in pairs(getElementsByType("vehicle", resourceRoot)) do
        if getElementData(v, "taxiOwner") == plr then
            local occupants = getVehicleOccupants(v)
            if #occupants > 0 then
                for _, occupant in pairs(occupants) do
                    removePlayerFromVehicle(occupant)
                end
            end

            respawnVehicle(v)
            setElementFrozen(v, true)
            setVehicleOverrideLights(v, 1)
            removeElementData(v, "taxiOwner")
            removeElementData(v, "vehicleOwner")

            setElementData(v, "vehicleData", {
                fuel = 20,
                mileage = math.random(40000, 60000),
                engineType = "d",
            }, false)
        end
    end
end
addEvent("removePlayerTaxi", true)
addEventHandler("removePlayerTaxi", root, removePlayerTaxi)


function payForTaxi(driver, price)
    if not price then return end
    if not exports.TR_core:takeMoneyFromPlayer(client, price) then
        triggerClientEvent({driver, client}, "blockTaxiMoney", resourceRoot)
    end
end
addEvent("payForTaxi", true)
addEventHandler("payForTaxi", resourceRoot, payForTaxi)


function addTaxiRequest()
    if taxiRequests[client] then exports.TR_noti:create(client, "Oczekujesz już na jedną taksówkę.", "error") return end
    taxiRequests[client] = {getElementPosition(client)}

    exports.TR_noti:create(client, "Taksówka została wezwana. Aby ułatwić pracę taksówkarzowi, nie oddalaj sie zbyt daleko.", "success")
    triggerClientEvent(root, "addTaxiRequestInfo", resourceRoot)
end
addEvent("addTaxiRequest", true)
addEventHandler("addTaxiRequest", root, addTaxiRequest)


function getTaxiPanel()
    for i, v in pairs(taxiRequests) do
        if not isElement(i) then
            taxiRequests[i] = nil
        end
    end

    triggerClientEvent(client, "updateTaxiPanel", resourceRoot, taxiRequests)
end
addEvent("getTaxiPanel", true)
addEventHandler("getTaxiPanel", resourceRoot, getTaxiPanel)

function selectTaxiRequest(player)
    if taxiRequests[player] then
        taxiRequests[player] = nil
        triggerClientEvent(client, "updateTaxiPanel", resourceRoot, taxiRequests, "take")

        if isElement(player) then
            triggerClientEvent(player, "showCustomMessage", resourceRoot, string.format("#d89932Taksówkarz [%d] %s", getElementData(client, "ID"), getPlayerName(client)), "#ac7a28Zgłoszenie zostało zaakceptowane. Taksówka powinna niebawem znaleźć się we wskazanej lokalizacji.", "files/images/msg_received.png")
        end
    else
        triggerClientEvent(client, "updateTaxiPanel", resourceRoot, taxiRequests, "taken")
    end
end
addEvent("selectTaxiRequest", true)
addEventHandler("selectTaxiRequest", resourceRoot, selectTaxiRequest)

function declineTaxiRequest(player)
    if taxiRequests[player] then taxiRequests[player] = nil end
    if isElement(player) then
        triggerClientEvent(player, "showCustomMessage", resourceRoot, string.format("#d89932Taksówkarz [%d] %s", getElementData(client, "ID"), getPlayerName(client)), "#ac7a28Bardzo przepraszam, lecz musiałem anulować pańskie zgłoszenie i nie pojawie się pod wskazanym adresem. Za utrudnienia przepraszam..", "files/images/msg_received.png")
    end
end
addEvent("declineTaxiRequest", true)
addEventHandler("declineTaxiRequest", resourceRoot, declineTaxiRequest)

function playerQuit()
    removePlayerTaxi(source)
end
addEventHandler("onPlayerQuit", root, playerQuit)

function sendBotRequest()
    
end