adminVehicles = {}
local settings = {
    technicalPause = false,
    technicalTime = 10,

    developers = {},
    fakeNames = {"Taikun", "Chiquita", "Mr.bishop", "CoSieGapisz", "Chiquita", "Mr.Chuck", "Tadek", "Tibiozaur", "Yaskacz", "PazikPL", "Trzepaczek", "Wariat321", "Agent86", "Haos", "Brave", "Backer", "Macius554", "Fafik", "Karolek12", "Parton", "Iris", "Siran", "Jassan", "Klamer", "PuszystyKloc", "Domen34", "GranterLol"},

    adminRankPayout = {
        ["owner"] = 15000,
        ["guardian"] = 9300,
        ["admin"] = 8500,
        ["globalmoderator"] = 7000,
        ["moderator"] = 6500,
        ["support"] = 5000,
    },
}

function adminDuty(...)
    local uid = getElementData(source, "characterUID")
    if not uid then return end
    local options = table.concat({...}, " ")

    if isPlayerOnDuty(source, true) then
        removePlayerDev(source)

        local adminRank = getElementData(source, "adminDuty")
        if adminRank then
            if settings.adminRankPayout[adminRank] then
                local startTimeOnDuty = getElementData(source, "adminDutyStartTick")
                local dutyTimeInSeconds = (getTickCount() - startTimeOnDuty)/1000
                local payout = math.ceil((dutyTimeInSeconds/3600 * settings.adminRankPayout[adminRank]) * 100)/100

                exports.TR_core:giveMoneyToPlayer(source, payout)
                triggerClientEvent(source, "showCustomMessage", resourceRoot, "SYSTEM", string.format("Wylogowałeś się ze służby admina.\nZa swoją służbę zarobiłeś $%.2f.", payout), "files/images/system.png")

                exports.TR_mysql:querry("UPDATE tr_admin SET dutyTime = dutyTime + ? WHERE uid = ? LIMIT 1", dutyTimeInSeconds, uid)
            else
                triggerClientEvent(source, "showCustomMessage", resourceRoot, "SYSTEM", "Wylogowałeś się ze służby admina.", "files/images/system.png")
            end
        else
            triggerClientEvent(source, "showCustomMessage", resourceRoot, "SYSTEM", "Wylogowałeś się ze służby admina.", "files/images/system.png")
        end

        triggerClientEvent(source, "closeAdminGui", resourceRoot)

        setPedWearingJetpack(source, false)
        removeAdminSpawnedVehicles(source)
        removeElementData(source, "fakeName")
        removeElementData(source, "adminDuty")
    else
        local querry = exports.TR_mysql:querry("SELECT ID, rankName, isDev, serial FROM tr_admin WHERE uid = ? LIMIT 1", uid)
        if querry and #querry > 0 then
            if querry[1].serial ~= getPlayerSerial(source) then triggerClientEvent(source, "showCustomMessage", resourceRoot, "SYSTEM", "Nie możesz się zalogować na służbę admina z tego komputera.", "files/images/system.png") return end
            if string.find(querry[1].rankName, "-sus") then triggerClientEvent(source, "showCustomMessage", resourceRoot, "SYSTEM", "Nie możesz się zalogować na służbę, ponieważ jesteś zawieszony.", "files/images/system.png") return end
            setPlayerOnDuty(source, options, querry[1])
        end
    end
end
addEvent("adminDuty", true)
addEventHandler("adminDuty", root, adminDuty)
exports.TR_chat:addCommand("duty", "adminDuty")


function setPlayerOnDuty(plr, options, data)
    local adminData = {}

    if data.isDev then
        if string.find(options, "-s") then
            data.rankName = data.rankName .. "-s"
            setElementData(plr, "fakeName", getFakeName())
        end

        adminData.isDev = true
        addPlayerDev(plr)
    end

    setElementData(plr, "adminDuty", data.rankName)
    setElementData(plr, "adminDutyStartTick", getTickCount())
    triggerClientEvent(plr, "showCustomMessage", resourceRoot, "SYSTEM", string.format("Zalogowałeś się na służbę jako %s.", getRankName(data.rankName)), "files/images/system.png")

    if data.rankName ~= "developer" then
        triggerClientEvent(plr, "openAdminGui", resourceRoot, adminData, settings.technicalPause, getPlayerPermissions(plr))
    end
end

function getRankName(rank)
    if string.find(rank, "owner") then return "#7e0f0fCzłonek Zarządu" end
    if string.find(rank, "guardian") then return "#e73f0bCzłonek drużyny Guardian" end
    if string.find(rank, "admin") then return "#da1717Członek drużyny Administracyjnej" end
    if string.find(rank, "globalmoderator") then return "#0a8f0bCzłonek drużyny Global Moderatorów" end
    if string.find(rank, "moderator") then return "#0a8f0bCzłonek drużyny Moderatorskiej" end
    if string.find(rank, "support") then return "#1ba3f3Członek drużyny Supporterów" end
    if string.find(rank, "developer") then return "#9424b4Członek drużyny Developerów" end
end

function getFakeName()
    return settings.fakeNames[math.random(1, #settings.fakeNames)]
end

-- Technical pause
function technicalPause(...)
    if not hasPlayerPermission(source, "isDev") then return end
    if isTimer(settings.technicalPauseTimer) then killTimer(settings.technicalPauseTimer) end

    settings.technicalPause = not settings.technicalPause
    if settings.technicalPause then
        settings.technicalPauseTimer = setTimer(kickTechnical, settings.technicalTime * 60000, 1)

        triggerClientEvent("performTechnicalPause", resourceRoot, settings.technicalTime)
        setMapName("Just Play")
        setGameType("Just Play")
    else
        triggerClientEvent("performTechnicalPause", resourceRoot)
        setMapName("Just Play")
        setGameType("Just Play")
    end
end
addEvent("technicalPauseCommand", true)
addEventHandler("technicalPauseCommand", root, technicalPause)
exports.TR_chat:addCommand("techpause", "technicalPauseCommand")

function kickTechnical()
    local canStay = {}
    local querry = exports.TR_mysql:querry("SELECT uid from tr_admin WHERE isDev = 1")
    for _, v in pairs(querry) do
        canStay[v.uid] = true
    end

    for _, plr in pairs(getElementsByType("player")) do
        local uid = getElementData(plr, "characterUID")
        if not uid or not canStay[uid] then
            kickPlayer(plr, "Brak dostępu!", "Nie posiadasz dostępu do tego serwera!")
        end
    end
end



-- Utils
function isPlayerOnDuty(plr, everyoneAccess)
    if everyoneAccess then
        return getElementData(plr, "adminDuty") and true or false
    else
        local adminDuty = getElementData(plr, "adminDuty")
        if not adminDuty then return false end
        if adminDuty == "developer" then return false end
        return true
    end
end

function hasPlayerPermission(plr, permission)
    local uid = getElementData(plr, "characterUID")
    if not uid then return end
    if not isPlayerOnDuty(plr) then return false end
    local querry = exports.TR_mysql:querry(string.format("SELECT ID from tr_admin WHERE uid = ? AND %s = 1 LIMIT 1", permission), uid)
    return querry and querry[1] and true or false
end

function getPlayerPermissions(plr)
    local uid = getElementData(plr, "characterUID")
    if not uid then return end
    local querry = exports.TR_mysql:querry("SELECT isDev, clearChat, itemCreate, ban, kick, tpl, bwOff, heal, playerTp, vehicleTp, vehicleFuel, air, orgLogos, resetMail from tr_admin WHERE uid = ? LIMIT 1", uid)
    return querry and querry[1] or {}
end


function kickPlayerFromServer(plr, kicker, reason)
    kickPlayer(plr, kicker, reason)
end
addEvent("kickPlayer", true)
addEventHandler("kickPlayer", root, kickPlayerFromServer)

function redirectPlayerToServer()
    -- mtasa://51.83.182.35:20172
    redirectPlayer(client, "51.83.182.35", "20172")
end
addEvent("redirectPlayerToServer", true)
addEventHandler("redirectPlayerToServer", root, redirectPlayerToServer)



-- Handlers
function playerConnect(playerNick, playerIP, playerUsername, playerSerial, playerVersionNumber)
    if not settings.technicalPause then checkSlots(playerSerial) return end
    local querry = exports.TR_mysql:querry("SELECT ID from tr_admin WHERE serial = ? LIMIT 1", playerSerial)
    if not querry or not querry[1] then
        cancelEvent(true, 'Blokada konta administracyjnego.')
    end
end
addEventHandler("onPlayerConnect", root, playerConnect)

function checkSlots(playerSerial)
    local players = #getElementsByType("player")
    if players >= 110 then
        local querry = exports.TR_mysql:querry("SELECT ID from tr_admin WHERE serial = ? AND isDev = 1 LIMIT 1", playerSerial)
        if not querry or not querry[1] then
            cancelEvent(true, "Pozostałe sloty są zarezerwowane.")
        end
    end
end

function autoLogout()
    local chatRes = getResourceFromName("TR_chat")
    local state = getResourceState(chatRes)
    local sendChat = false
    if state == "running" then sendChat = true end

    for i, v in pairs(getElementsByType("player")) do
        if getElementData(v, "adminDuty") then
            removeElementData(v, "adminDuty")
            if sendChat then triggerClientEvent(v, "showCustomMessage", resourceRoot, "SYSTEM", "Nastąpiło automatyczne wylogowanie z funkcji admina.", "files/images/system.png") end
        end
    end
end
addEventHandler("onResourceStop", getResourceRootElement(getThisResource()), autoLogout)




-- Dev server stats
function addPlayerDev(plr)
    table.insert(settings.developers, plr)
    if not settings.updateDeveloper then
        settings.updateDeveloper = setTimer(sendDevData, 2000, 0)
    end
end

function removePlayerDev(plr)
    for i, v in ipairs(settings.developers) do
        if v == plr then
            table.remove(settings.developers, i)
            break
        end
    end
    if #settings.developers < 1 then
        if isTimer(settings.updateDeveloper) then
            killTimer(settings.updateDeveloper)
            settings.updateDeveloper = nil
        end
    end
end
function adminQuit()
    removePlayerDev(source)
end
addEventHandler("onPlayerQuit", root, adminQuit)

function sendDevData()
    if #settings.developers > 0 then
        local _, timing = getPerformanceStats("Lua timing")
        local _, packets = getPerformanceStats("Server timing")
        triggerClientEvent(settings.developers, "updateServerStatus", resourceRoot, timing, packets)
    end
end

function addMysqlInfo(text)
    triggerClientEvent(settings.developers, "addMysqlInfo", resourceRoot, text)
end



function getDataToAdminPanel(obj)
    local objType = getElementType(obj)
    local dataToSend = false

    if objType == "vehicle" then
        local vehData = getElementData(obj, "vehicleData")
        if vehData then
            dataToSend = {
                fuel = vehData.fuel,
                mileage = vehData.mileage,
            }
        end
    end

    triggerClientEvent(client, "syncDataToAdminPanel", obj, dataToSend)
end
addEvent("getDataToAdminPanel", true)
addEventHandler("getDataToAdminPanel", resourceRoot, getDataToAdminPanel)

function useAdminPanelOption(element, option)
    if not element then return end
    if option == "vehicleFlip" then
        local rot = Vector3(getElementRotation(element))
        setElementRotation(element, 0, 0, rot.z)


    elseif option == "vehicleUnfreeze" then
        if getElementData(element, "wheelBlock") then exports.TR_noti:create(client, "Nie możesz zdjąć ręcznego z tego pojazdu.", "error") return end
        local frozen = not isElementFrozen(element)
        setElementFrozen(element, frozen)

        if frozen then

        else

        end

    elseif option == "warpToGarage" then
        local data = getElementData(element, "vehicleData")
        if not data then exports.TR_noti:create(client, "Nie możesz odstawić tego pojazdu.", "error") return end
        if getElementData(element, "wheelBlock") then exports.TR_noti:create(client, "Nie możesz odstawić tego pojazdu.", "error") return end

        local vehID = getElementData(element, "vehicleID")
        if vehID then
            exports.TR_vehicles:saveVehicle(element)
            exports.TR_mysql:querry("UPDATE tr_vehicles SET parking = ? WHERE ID = ? LIMIT 1", 50, data.ID)
            destroyElement(element)

            exports.TR_noti:create(client, "Pojazd został odstawiony do przechowywalni.", "success")


            return

        else
            if getElementData(element, "fractionID") then
                local x, y, z = getVehicleRespawnPosition(element)
                local rx, ry, rz = getVehicleRespawnRotation(element)
                setElementPosition(element, x, y, z)
                setElementRotation(element, rx, ry, rz)
                setElementFrozen(element, true)
                fixVehicle(element)

                exports.TR_noti:create(client, "Pojazd został odstawiony na parking frakcyjny.", "success")


                return
            end
        end
        exports.TR_noti:create(client, "Nie możesz odstawić tego pojazdu.", "error")

    elseif option == "tpHere" then
        if getElementData(element, "wheelBlock") then exports.TR_noti:create(client, "Nie możesz teleportować tego pojazdu.", "error") return end
        local pos = Vector3(getElementPosition(client))
        setElementPosition(element, pos)

        if getElementType(element) == "player" then


        else

        end

    elseif option == "fuelVehicle" then
        local data = getElementData(element, "vehicleData")
        if not data then return end

        data.fuel = math.max(data.fuel, 10)
        setElementData(element, "vehicleData", data, false)

        local plr = getVehicleOccupant(element, 0)
        if plr then
            triggerClientEvent(plr, "playerSpeedometerOpen", resourceRoot, element, data)
        end



    elseif option == "fixVehicle" then
        fixVehicle(element, 1000)
        if not isVehicleFrozen(element) then
            setVehicleDamageProof(element, false)
        end



    elseif option == "healPlayer" then
        setElementHealth(element, 100)



    elseif option == "reloadPlayer" then
        setElementPosition(element, -1917.1005859375, 889.7294921875, 35.4140625)
        setElementInterior(element, 0)
        setElementDimension(element, 0)


    end
end
addEvent("useAdminPanelOption", true)
addEventHandler("useAdminPanelOption", resourceRoot, useAdminPanelOption)



function onAdminQuit()
    removeAdminSpawnedVehicles(source)

    if adminTeleports[source] then
        destroyElement(adminTeleports[source].element)
        adminTeleports[source] = nil
    end
end
addEventHandler("onPlayerQuit", root, onAdminQuit)

function removeAdminSpawnedVehicles(plr)
    if not adminVehicles[plr] then return end
    for i, v in pairs(adminVehicles[plr]) do
        if isElement(v) then destroyElement(v) end
    end
    adminVehicles[plr] = nil
end


-- Starter
function startServer()
    setMapName("Just Play")
    setGameType("Just Play")
end
startServer()

addCommandHandler("adom", function(plr, cmd, size, price, premium)
    if getElementData(plr, 'characterUID') ~= 3 then return end;
    if not cmd or not size or not price then exports.TR_noti:create(plr, "/adom (wielkość) (cena)", "error") return end
    local houseSize = tonumber(size)
    local housePrice = tonumber(price)
    local isPremium = houseSize == 15 and true or false

    if not houseSize or not housePrice then exports.TR_noti:create(plr, "/adom (wielkość) (cena)", "error") return end

    local pos = Vector3(getElementPosition(plr))
    local housePos = string.format("%.3f,%.3f,%.3f", pos.x, pos.y, pos.z)
    exports.TR_mysql:querry(string.format("INSERT INTO `tr_houses`(`price`, `interiorSize`, `pos`, `locked`, `premium`) VALUES (?, ?, ?, ?, %s)", isPremium and "1" or "NULL"), housePrice, houseSize, housePos, "0")
end)




-- AdminLogs
function getPlayerAdminPanelData(username)
    if not isPlayerOnDuty(source) then return false end
    if not username then
        triggerClientEvent(source, "showCustomMessage", resourceRoot, "#008a2eUżycie komendy", "#438f5c/checkplayer (UID/Nick)", "files/images/command.png")
        return
    end

    local userData = false
    if tonumber(username) ~= nil then
        userData = exports.TR_mysql:querry("SELECT UID, username, email, created, lastOnline, money, bankmoney, jobPoints, online, serial FROM tr_accounts WHERE UID = ? LIMIT 1", username)
    else
        userData = exports.TR_mysql:querry("SELECT UID, username, email, created, lastOnline, money, bankmoney, jobPoints, online, serial FROM tr_accounts WHERE username = ? LIMIT 1", username)
    end

    if userData and userData[1] then
        userData[1].premium = checkPlayerPremium(userData[1].UID)

        local isAdmin = exports.TR_mysql:querry("SELECT ID FROM tr_admin WHERE serial = ? LIMIT 1", userData[1].serial)
        if isAdmin and isAdmin[1] then
            if isAdmin[1].ID then
                userData[1].isAdmin = true
            else
                userData[1].isAdmin = false
            end
        else
            userData[1].isAdmin = false
        end

        local vehicles = exports.TR_mysql:querry("SELECT ID, model FROM tr_vehicles WHERE ownedPlayer = ?", userData[1].UID)
        local houses = exports.TR_mysql:querry("SELECT ID, date, pos FROM tr_houses WHERE owner = ?", userData[1].UID)
        local organizations = exports.TR_mysql:querry("SELECT tr_organizations.ID as ID, name, money FROM tr_organizations INNER JOIN tr_organizationsPlayers ON tr_organizations.ID = tr_organizationsPlayers.orgID WHERE playerUID = ? LIMIT 1", userData[1].UID)
        local penalties = exports.TR_mysql:querry("SELECT ID, reason, time, type, timeEnd, admin, takenBy, (CASE WHEN timeEnd > NOW() AND takenBy IS NULL THEN true ELSE NULL END) as active FROM tr_penalties WHERE plrUID = ? OR username = ? ORDER BY time DESC", userData[1].UID, userData[1].username)

        triggerClientEvent(source, 'showAdminPlayerPanelInfo', resourceRoot, userData[1], vehicles, houses, organizations, penalties)
    else
        exports.TR_noti:create(source, "Taki gracz nie istnieje.", "error")
    end
end
addEvent("getPlayerAdminPanelData", true)
addEventHandler("getPlayerAdminPanelData", root, getPlayerAdminPanelData)
exports.TR_chat:addCommand("checkplayer", "getPlayerAdminPanelData")


function givePenaltyAdminPlayerPanelInfo(playerUID, playerUsername, penaltyType, penaltyMessage, penaltyTime, penaltyTimeType, player)
    local unit = panelAvaliableUnits[string.lower(penaltyTimeType)]
    if not unit then return end

    local serial = exports.TR_mysql:querry("SELECT serial FROM tr_accounts WHERE UID = ? LIMIT 1", playerUID)
    if not serial or not serial[1] then return end

    if not hasPlayerPermission(client, "isDev") then
        local isAdmin = exports.TR_mysql:querry("SELECT ID FROM tr_admin WHERE serial = ? LIMIT 1", serial[1].serial)
        if isAdmin and isAdmin[1] then
            if isAdmin[1].ID then
                exports.TR_noti:create(client, "Nie możesz zbanować tego użytkownika.", "error")
                return
            end
        end
    end

    exports.TR_mysql:querry(string.format("INSERT INTO `tr_penalties` (`plrUID`, `serial`, `reason`, `time`, `timeEnd`, `type`, `admin`) VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL %d %s), ?, ?)", penaltyTime, unit), playerUID, serial[1].serial, penaltyMessage, penaltyType, getPlayerName(client))

    local time = getRealTime()
    --exports.TR_discord:sendChannelMsg("adminPenalties", {
     --   time = string.format("[%02d:%02d %02d.%02d]", time.hour, time.minute, time.monthday, time.month),
     --   author = getPlayerName(client),
     --   text = string.format("nałożył karę (%s) na gracza %s na okres %d%s. Powód: %s", penaltyType, playerUsername, tonumber(penaltyTime), unit, penaltyMessage),
    --})

    local tf = string.format("[%02d:%02d %02d.%02d]", time.hour, time.minute, time.monthday, time.month)
    exports.TR_discord:remoteDsc(tf.." | "..string.format("**%s** nałożył karę na gracza **%s** na okres **%d%s**. Powód: **%s**", penaltyType, playerUsername, tonumber(penaltyTime), unit, penaltyMessage), "kary")

    if penaltyType == "kick" or penaltyType == "ban" then
        if player then
            kickPlayerFromServer(player, getPlayerName(client), penaltyMessage)
        end
    end
    reloadPenaltiesAdminPlayerPanelInfo(client, playerUID, playerUsername)
end
addEvent("givePenaltyAdminPlayerPanelInfo", true)
addEventHandler("givePenaltyAdminPlayerPanelInfo", root, givePenaltyAdminPlayerPanelInfo)

function reloadPenaltiesAdminPlayerPanelInfo(player, playerUID, playerUsername)
    if not playerUID or not playerUsername then return end
    local penalties = exports.TR_mysql:querry("SELECT ID, reason, time, type, timeEnd, admin, takenBy, (CASE WHEN timeEnd > NOW() AND takenBy IS NULL THEN true ELSE NULL END) as active FROM tr_penalties WHERE plrUID = ? OR username = ? ORDER BY time DESC", playerUID, playerUsername)

    triggerClientEvent(player, 'reloadPenaltiesAdminPlayerPanelInfo', resourceRoot, penalties)
end


function checkPlayerPremium(UID)
    local rank = exports.TR_mysql:querry("SELECT CASE WHEN `diamond` > NOW() THEN 'Diament' WHEN `gold` > NOW() THEN 'Gold' ELSE NULL END as 'rank' FROM tr_accounts WHERE UID = ? LIMIT 1", UID)
    if rank and rank[1] then
        return rank[1].rank
    end
    return "Standard"
end







-- Admin panel
function takeoutAdminPanelPlayerPenalty(penaltyID)
    exports.TR_mysql:querry("UPDATE tr_penalties SET takenBy = ? WHERE ID = ? LIMIT 1", getPlayerName(client), penaltyID)
end
addEvent("takeoutAdminPanelPlayerPenalty", true)
addEventHandler("takeoutAdminPanelPlayerPenalty", resourceRoot, takeoutAdminPanelPlayerPenalty)




setTimer(function()

end, 500, 1)





-- Admin chief
function openAdminListPanel()
    if not isPlayerOnDuty(source) then return end
    if not hasPlayerPermission(source, "editAdmin") then return end

    loadAdminListPanel(source, "startAdminList")
end
addEvent("openAdminListPanel", true)
addEventHandler("openAdminListPanel", root, openAdminListPanel)
exports.TR_chat:addCommand("apanel", "openAdminListPanel")

function loadAdminListPanel(plr, event)
    local admins = exports.TR_mysql:querry("SELECT rankName, dutyTime, username, tr_admin.uid as uid FROM tr_admin LEFT JOIN tr_accounts ON tr_admin.uid = tr_accounts.UID")
    local reports = exports.TR_mysql:querry("SELECT tr_accounts.username as username, COUNT(*) as count FROM tr_reports LEFT JOIN tr_accounts ON tr_accounts.username = tr_reports.admin WHERE YEARWEEK(`date`, 1) = YEARWEEK(CURDATE(), 1) GROUP BY tr_accounts.username")

    triggerClientEvent(plr, event, resourceRoot, admins, reports)
end

function removePlayerAdmin(uid, username)
    exports.TR_mysql:querry("DELETE FROM tr_admin WHERE uid = ? LIMIT 1", uid)

    local plr = getPlayerFromName(username)
    if plr then
        if isPlayerOnDuty(plr) then removePlayerDev(plr) end
    end

    loadAdminListPanel(client, "updateAdminPanelList")
end
addEvent("removePlayerAdmin", true)
addEventHandler("removePlayerAdmin", resourceRoot, removePlayerAdmin)

function suspendPlayerAdmin(uid, username, rank)
    exports.TR_mysql:querry("UPDATE tr_admin SET rankName = ? WHERE uid = ? LIMIT 1", rank, uid)

    local plr = getPlayerFromName(username)
    if plr then
        if isPlayerOnDuty(plr) then removePlayerDev(plr) end
    end

    loadAdminListPanel(client, "updateAdminPanelList")
end
addEvent("suspendPlayerAdmin", true)
addEventHandler("suspendPlayerAdmin", resourceRoot, suspendPlayerAdmin)