local markerData = {
    pos = Vector3(387.314453125, 876.2177734375, 20.784130096436),
    icon = "pickaxe",
    int = 0,
    dim = 0,
    blip = true,
    data = {
        title = "Praca w kamieniołomie",
        desc = "Wejdź w marker aby rozpocząć pracę.",
    },
}

function onMarkerHit(el, md)
    if not el or not md then return end
    if el ~= localPlayer then return end
    if getElementType(el) ~= "player" then return end
    if getPedOccupiedVehicle(el) then return end

    local markerPos = Vector3(getElementPosition(source))
    local playerPos = Vector3(getElementPosition(localPlayer))
    if playerPos.z < markerPos.z - 0.5 or playerPos.z > markerPos.z + 2 then return end

    local resourceName = getResourceName(getThisResource())
    triggerServerEvent("getPlayerJobData", resourceRoot, resourceName)
end

function createStartMarker()
    local marker = createMarker(markerData.pos.x, markerData.pos.y, markerData.pos.z - 0.9, "cylinder", 1.2, 71, 180, 201, 0)
    setElementData(marker, "markerData", markerData.data, false)
    setElementData(marker, "markerIcon", markerData.icon, false)

    setElementInterior(marker, markerData.int)
    setElementDimension(marker, markerData.dim)

    if markerData.blip then
        local blip = createBlip(markerData.pos, 0, 2, 71, 180, 201)
        setElementData(blip, "icon", 30, false)
        setElementData(blip, "blipName", markerData.data.title, false)
    end

    addEventHandler("onClientMarkerHit", marker, onMarkerHit)
end

createStartMarker()