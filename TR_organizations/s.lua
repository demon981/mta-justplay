local NPCs = {
    {
        skin = 98,
        pos = Vector3(2858.3056640625, -1126.5085449219, 113.32722473145),
        int = 0,
        dim = 50,
        rot = 110,
        name = "Han Gren",
        type = "create",
        role = "Zakładanie organizacji",
    },
    {
        skin = 17,
        pos = Vector3(2858.6459960938, -1130.1217041016, 113.31999969482),
        int = 0,
        dim = 50,
        rot = 110,
        name = "Olsen Harmet",
        type = "vehicle",
        role = "Przypisywanie pojazdów",
    },
    {
        skin = 98,
        pos = Vector3(-2010.326171875, -83.890823364258, 85),
        int = 0,
        dim = 9,
        rot = 0,
        name = "John Klum",
        type = "create",
        role = "Zakładanie organizacji",
    },
    {
        skin = 17,
        pos = Vector3(-2012.3984375, -83.887687683105, 85),
        int = 0,
        dim = 9,
        rot = 0,
        name = "Troy Hart",
        type = "vehicle",
        role = "Przypisywanie pojazdów",
    },
}

function createNPCs()
    local dialogueCreate = exports.TR_npc:createDialogue()
    exports.TR_npc:addDialogueText(dialogueCreate, "Dzień dobry.", {pedResponse = "Dzień dobry."})
    exports.TR_npc:addDialogueText(dialogueCreate, "Chciałbym założyć organizację.", {pedResponse = "", responseTo = "Dzień dobry.", img = "organization", trigger = "createOrganization"})

    exports.TR_npc:addDialogueText(dialogueCreate, "Chciałbym odnowić organizację.", {pedResponse = "Koszt odnowy wynosi $10000. Czy jest to ostateczna decyzja?", responseTo = "Dzień dobry."})
    exports.TR_npc:addDialogueText(dialogueCreate, "Tak. ($10000)", {pedResponse = "", responseTo = "Chciałbym odnowić organizację.", img = "organization", trigger = "renewOrganization"})
    exports.TR_npc:addDialogueText(dialogueCreate, "Nie.", {pedResponse = "To proszę się jeszcze zastanowić i w razie co wrócić z podjętą decyzją.", responseTo = "Chciałbym odnowić organizację."})


    exports.TR_npc:addDialogueText(dialogueCreate, "Chciałbym usunąć utraconą organizację.", {pedResponse = "Organizacja zostanie trwale usunięta. Czy to ostateczna decyzja?", responseTo = "Dzień dobry."})
    exports.TR_npc:addDialogueText(dialogueCreate, "Tak.", {pedResponse = "", responseTo = "Chciałbym usunąć utraconą organizację.", trigger = "removeRemovedOrganization"})
    exports.TR_npc:addDialogueText(dialogueCreate, "Nie.", {pedResponse = "To proszę się jeszcze zastanowić i w razie co wrócić z podjętą decyzją.", responseTo = "Chciałbym usunąć utraconą organizację."})

    exports.TR_npc:addDialogueText(dialogueCreate, "Do widzenia.", {pedResponse = "Do widzenia."})

    local dialogueVehicle = exports.TR_npc:createDialogue()
    exports.TR_npc:addDialogueText(dialogueVehicle, "Chciałbym przypisać pojazd do organizacji.", {pedResponse = "", img = "car", trigger = "openVehicleOrgAdd"})
    exports.TR_npc:addDialogueText(dialogueVehicle, "Do widzenia.", {pedResponse = "Do widzenia."})

    for i, v in pairs(NPCs) do
        local ped = exports.TR_npc:createNPC(v.skin, v.pos.x, v.pos.y, v.pos.z, v.rot, v.name, v.role, "dialogue")
        setElementInterior(ped, v.int)
        setElementDimension(ped, v.dim)

        if v.type == "create" then
            exports.TR_npc:setNPCDialogue(ped, dialogueCreate)
        else
            exports.TR_npc:setNPCDialogue(ped, dialogueVehicle)
        end
    end
end
createNPCs()


function setOrganizationPosition(pos, dim, exit)
    local x, y, z = getElementPosition(client)

    if exit then
        setElementData(client, "characterQuit", {x, y, z, 0, 0}, false)
    else
        removeElementData(client, "characterQuit")
    end
    setElementPosition(client, pos[1], pos[2], pos[3])
    setElementRotation(client, 0, 0, pos[4])
    setElementDimension(client, dim)


    local attachments = getAttachedElements(client)
    if attachments then
      for i, v in pairs(attachments) do
        if getElementType(v) == "player" then
            if exit then
                setElementData(v, "characterQuit", {x, y, z, 0, 0}, false)
            else
                removeElementData(v, "characterQuit")
            end

            setElementPosition(v, pos[1], pos[2], pos[3])
            setElementRotation(v, 0, 0, pos[4])
            setElementDimension(v, dim)
        end
      end
    end
end
addEvent("setOrganizationPosition", true)
addEventHandler("setOrganizationPosition", resourceRoot, setOrganizationPosition)


function enterOrganizationInterior(type, size, data, pos)
    local attachments = getAttachedElements(client)
    if attachments then
        for i, v in pairs(attachments) do
            if getElementType(v) == "player" then
                triggerClientEvent(v, "loadOrganizationInterior", resourceRoot, type, size, data, pos)
            end
        end
    end
end
addEvent("enterOrganizationInterior", true)
addEventHandler("enterOrganizationInterior", resourceRoot, enterOrganizationInterior)

function exitOrganizationInterior()
    local attachments = getAttachedElements(client)
    if attachments then
        for i, v in pairs(attachments) do
            if getElementType(v) == "player" then
                triggerClientEvent(v, "exitOrganizationInterior", resourceRoot)
            end
        end
    end
end
addEvent("exitOrganizationInterior", true)
addEventHandler("exitOrganizationInterior", resourceRoot, exitOrganizationInterior)

function createOrganization(ped)
    local pedName = getElementData(ped, "name")
    local hasOrg = exports.TR_mysql:querry("SELECT ID FROM tr_organizations WHERE owner = ? LIMIT 1", getElementData(client, "characterUID"))
    if hasOrg and hasOrg[1] then
        if hasOrg[1].ID then
            triggerClientEvent(client, "showCustomMessage", resourceRoot, pedName, "W bazie danych jest już jedna pańska organizacja. Przepraszam, lecz niemożliwe jest założenie kolejnej.", "files/images/npc.png")
            return
        end
    end

    local uid = getElementData(client, "characterUID")
    local isInOrg = exports.TR_mysql:querry("SELECT ID FROM tr_organizationsPlayers WHERE playerUID = ? LIMIT 1", uid)
    if isInOrg and isInOrg[1] then
        if isInOrg[1].ID then
            triggerClientEvent(client, "showCustomMessage", resourceRoot, pedName, "Aby stworzyć własną organizację, proszę najpierw opuścić aktualną.", "files/images/npc.png")
            return
        end
    end

    triggerClientEvent(client, "createOrganization", resourceRoot, pedName)
    triggerClientEvent(client, "showCustomMessage", resourceRoot, pedName, "Oczywiście. Proszę wypełnić ten prosty formularz.", "files/images/npc.png")
end
addEvent("createOrganization", true)
addEventHandler("createOrganization", root, createOrganization)

function renewOrganization(ped)
    local pedName = getElementData(ped, "name")
    local uid = getElementData(client, "characterUID")
    local hasOrg = exports.TR_mysql:querry("SELECT ID FROM tr_organizations WHERE owner = ? AND removed = 1 LIMIT 1", uid)
    if hasOrg and hasOrg[1] then
        if hasOrg[1].ID then
            if exports.TR_core:takeMoneyFromPlayer(client, 10000) then
                local ownerRank = exports.TR_mysql:querry("SELECT ID FROM tr_organizationsRanks WHERE orgID = ? ORDER BY level DESC LIMIT 1", hasOrg[1].ID)
                exports.TR_mysql:querry("INSERT INTO tr_organizationsPlayers (playerUID, orgID, rankID, added, toPay, allEarn, allPaid) VALUES (?, ?, ?, NOW(), 0, 0, 0)", uid, hasOrg[1].ID, ownerRank[1].ID)
                exports.TR_mysql:querry("UPDATE tr_organizations SET rent = DATE_ADD(NOW(), INTERVAL 7 DAY), removed = NULL WHERE ID = ? LIMIT 1", hasOrg[1].ID)

                exports.TR_login:updatePlayerOrganization(client, uid)

                triggerClientEvent(client, "showCustomMessage", resourceRoot, pedName, "Organizacja została pomyślnie odnowiona. Można już korzystać z komputera.", "files/images/npc.png")
            else
                triggerClientEvent(client, "showCustomMessage", resourceRoot, pedName, "Niestety ale posiadana kwota nie wystarczy. Proszę wrócić z pełną wymaganą kwotą pieniędzy.", "files/images/npc.png")
            end
            return
        end
    end

    triggerClientEvent(client, "showCustomMessage", resourceRoot, pedName, "W bazie danych nie ma żadnej organizacji do odnowienia.", "files/images/npc.png")
end
addEvent("renewOrganization", true)
addEventHandler("renewOrganization", root, renewOrganization)

function removeRemovedOrganization(ped)
    local pedName = getElementData(ped, "name")
    local hasOrg = exports.TR_mysql:querry("SELECT ID FROM tr_organizations WHERE owner = ? AND removed = 1 LIMIT 1", getElementData(client, "characterUID"))
    if hasOrg and hasOrg[1] then
        if hasOrg[1].ID then
            exports.TR_mysql:querry("UPDATE `tr_organizations` SET owner = NULL WHERE `ID` = ?", hasOrg[1].ID)

            triggerClientEvent(client, "showCustomMessage", resourceRoot, pedName, "Organizacja została trwale usunięta. To wszystko.", "files/images/npc.png")
            return
        end
    end

    triggerClientEvent(client, "showCustomMessage", resourceRoot, pedName, "W bazie danych nie ma żadnej nie opłaconej organizacji do usunięcia.", "files/images/npc.png")
end
addEvent("removeRemovedOrganization", true)
addEventHandler("removeRemovedOrganization", root, removeRemovedOrganization)

function payForNewOrg(state, data)
    if state then
        local typ = "org"
        if data[3] and type(data[3]) == "boolean" then
            if data[3] == true then
                typ = "crime"
            end
        end
        local plrUID = getElementData(source, "characterUID")
        local _, _, orgID = exports.TR_mysql:querry("INSERT INTO tr_organizations (name, type, orgType, interior, img, created, rent, owner, money, lastPayment) VALUES (?, ?, ?, 1, NULL, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), ?, 0, NOW())", data[2], typ, typ == "crime" and "gang" or nil, getElementData(source, "characterUID"))

        exports.TR_mysql:querry("INSERT INTO `tr_organizationsRanks`(`level`, `orgID`, `rankName`, `canManage`) VALUES (1, ?, 'Nowy', NULL)", orgID)
        local _, _, leaderRankID = exports.TR_mysql:querry("INSERT INTO `tr_organizationsRanks`(`level`, `orgID`, `rankName`, `canManage`) VALUES (2, ?, 'Leader', 1)", orgID)
        exports.TR_mysql:querry("INSERT INTO tr_organizationsPlayers (`playerUID`, `orgID`, `rankID`, `added`, `toPay`, `allEarn`) VALUES (?, ?, ?, NOW(), 0, 0)", plrUID, orgID, leaderRankID)

        triggerClientEvent(source, "showCustomMessage", resourceRoot, data[1], "Organizacja została założona pomyślnie. Aby zarządzać swoją organizacją należy skorzystać z komputera (F3).", "files/images/npc.png")
        triggerClientEvent(source, "createOrganizationResponse", resourceRoot, "bought")

        exports.TR_login:updatePlayerOrganization(source, plrUID)
    else
        triggerClientEvent(source, "createOrganizationResponse", resourceRoot)
    end
end
addEvent("payForNewOrg", true)
addEventHandler("payForNewOrg", root, payForNewOrg)

function checkOrgNameFree(name)
    local hasOrgName = exports.TR_mysql:querry("SELECT ID FROM tr_organizations WHERE name = ? LIMIT 1", name)
    if hasOrgName and hasOrgName[1] then
        if hasOrgName[1].ID then
            triggerClientEvent(client, "createOrganizationResponse", resourceRoot, "cantCreate")
            return
        end
    end

    triggerClientEvent(client, "createOrganizationResponse", resourceRoot, "canCreate")
end
addEvent("checkOrgNameFree", true)
addEventHandler("checkOrgNameFree", resourceRoot, checkOrgNameFree)


function openVehicleOrgAdd(ped)
    local pedName = getElementData(ped, "name")
    local uid = getElementData(source, "characterUID")

    local isInOrg = exports.TR_mysql:querry("SELECT ID FROM tr_organizationsPlayers WHERE playerUID = ? LIMIT 1", uid)
    if isInOrg and isInOrg[1] then
        if isInOrg[1].ID then
            local vehicles = exports.TR_mysql:querry("SELECT ID, model, plateText FROM tr_vehicles WHERE ownedPlayer = ?", uid)
            if vehicles and vehicles[1] then
                if #vehicles < 1 then triggerClientEvent(source, "showCustomMessage", resourceRoot, pedName, "W bazie nie znajduje się żaden pojazd, który można dodać do organizacji.", "files/images/npc.png") return end

                triggerClientEvent(source, "createVehicleOrgAdd", resourceRoot, vehicles)
                return
            end
        end
    end
    triggerClientEvent(source, "showCustomMessage", resourceRoot, pedName, "Najpierw powinno się należeć do organizacji aby móc do niej dopisywać pojazdy.", "files/images/npc.png")
end
addEvent("openVehicleOrgAdd", true)
addEventHandler("openVehicleOrgAdd", root, openVehicleOrgAdd)

function requestVehicleOrgAdd(vehID)
    local uid = getElementData(client, "characterUID")
    local isInOrg = exports.TR_mysql:querry("SELECT ID, orgID FROM tr_organizationsPlayers WHERE playerUID = ? LIMIT 1", uid)
    if isInOrg and isInOrg[1] then
        if isInOrg[1].ID then
            exports.TR_mysql:querry("UPDATE tr_vehicles SET requestOrg = ? WHERE ID = ?", isInOrg[1].orgID, vehID)
            triggerClientEvent(client, "responseVehicleOrgAdd", resourceRoot, true)
            return
        end

    else
        triggerClientEvent(client, "responseVehicleOrgAdd", resourceRoot)
    end
end
addEvent("requestVehicleOrgAdd", true)
addEventHandler("requestVehicleOrgAdd", resourceRoot, requestVehicleOrgAdd)




function removeOldOrganizations()
    local oldOrganizations = exports.TR_mysql:querry("SELECT ID FROM `tr_organizations` WHERE rent < CURDATE()")
    if #oldOrganizations > 0 then
        for i, v in pairs(oldOrganizations) do
            local orgPlayers = exports.TR_mysql:querry("SELECT username FROM tr_organizationsPlayers LEFT JOIN tr_accounts ON tr_organizationsPlayers.playerUID = tr_accounts.UID WHERE orgID = ?", v.ID)
            exports.TR_mysql:querry("DELETE FROM `tr_organizationsPlayers` WHERE `orgID` = ?", v.ID)

            for _, plr in pairs(orgPlayers) do
                local player = getPlayerFromName(plr.username)
                if isElement(player) then
                    exports.TR_login:updatePlayerOrganization(player, getElementData(player, "characterUID"))
                end
            end

            exports.TR_mysql:querry("UPDATE `tr_organizations` SET removed = 1 WHERE `ID` = ?", v.ID)
        end
    end
end
removeOldOrganizations()
setTimer(removeOldOrganizations, 600000, 0)








-- Open list
function openOrganizationAdminListPanel()
    if not exports.TR_admin:isPlayerOnDuty(source) then return end
    if not exports.TR_admin:hasPlayerPermission(source, "editOrg") then return end

    loadOrganizationAdminListPanel(source, "startAdminOrganizationsList")
end
addEvent("openOrganizationAdminListPanel", true)
addEventHandler("openOrganizationAdminListPanel", root, openOrganizationAdminListPanel)
exports.TR_chat:addCommand("opanel", "openOrganizationAdminListPanel")

function loadOrganizationAdminListPanel(plr, event)
    local organizations = exports.TR_mysql:querry("SELECT ID, name, type, username, zoneColor, orgType FROM tr_organizations LEFT JOIN tr_accounts ON tr_organizations.owner = tr_accounts.UID WHERE owner IS NOT NULL AND removed IS NULL")

    triggerClientEvent(plr, event, resourceRoot, organizations)
end

function changeOrganizationAdminType(orgID, orgType, gangType)
    exports.TR_mysql:querry(string.format("UPDATE tr_organizations SET type = ?, orgType = %s WHERE ID = ? LIMIT 1", gangType and "\""..gangType.."\"" or "NULL"), orgType, orgID)
    loadOrganizationAdminListPanel(client, "updateAdminOrganizationsList")
end
addEvent("changeOrganizationAdminType", true)
addEventHandler("changeOrganizationAdminType", root, changeOrganizationAdminType)

function changeOrganizationAdminColor(orgID, orgColor)
    exports.TR_mysql:querry("UPDATE tr_organizations SET zoneColor = ? WHERE ID = ? LIMIT 1", orgColor, orgID)
    loadOrganizationAdminListPanel(client, "updateAdminOrganizationsList")
end
addEvent("changeOrganizationAdminColor", true)
addEventHandler("changeOrganizationAdminColor", root, changeOrganizationAdminColor)