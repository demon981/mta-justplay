local settings = {
    spawnPositions = {
        [1] = "1722.05,-1710.48,13.5,0,0",
        [2] = "1718.54,-1712.46,13.5,0,0",
        [3] = "1725.54,-1712.46,13.5,0,0",
    },

    coroutines = {}
}

function getUpdates(limit)
    local updates = exports.TR_mysql:querry("SELECT text FROM `tr_updates` ORDER BY `ID` DESC LIMIT ?", limit + 5)
    if updates and updates[1] then
        triggerClientEvent(client, "updateLoginUpdates", resourceRoot, updates)
    else
        triggerClientEvent(client, "updateLoginUpdates", resourceRoot, {{text = "Nie udało się pobrać listy zmian"}})
    end
end
addEvent("getUpdates", true)
addEventHandler("getUpdates", resourceRoot, getUpdates)


function getBanData()
    local banData = exports.TR_mysql:querry("SELECT ID, tr_accounts.username as username, tr_penalties.serial, reason, time, timeEnd, admin FROM `tr_penalties` LEFT JOIN tr_accounts ON tr_accounts.UID = tr_penalties.plrUID WHERE tr_penalties.serial = ? AND timeEnd > NOW() AND type = 'ban' AND takenBy IS NULL LIMIT 1", getPlayerSerial(client))
    if banData and banData[1] then
        triggerClientEvent(client, "setPlayerBanData", resourceRoot, true, banData[1])
    else
        triggerClientEvent(client, "setPlayerBanData", resourceRoot, false)
    end
end
addEvent("getBanData", true)
addEventHandler("getBanData", resourceRoot, getBanData)

function checkBanAccount(plrUID)
    if not username then return false end
    local banData = exports.TR_mysql:querry("SELECT ID FROM `tr_penalties` WHERE plrUID = ? AND timeEnd > NOW() AND type = 'ban' LIMIT 1", plrUID)
    if banData and banData[1] then
        return true
    end
    return false
end


function registerAccount(login, password, email, reference)
    local checkUsername = exports.TR_mysql:querry("SELECT UID FROM `tr_accounts` WHERE `login` = ? LIMIT 1", login)
    if checkUsername and checkUsername[1] then
        triggerClientEvent(client, "loginResponseServer", resourceRoot, "Użytkownik o takim loginie już istnieje.", "error")
        return
    end

    local serial = getPlayerSerial(client)
    local checkSerial = exports.TR_mysql:querry("SELECT UID FROM `tr_accounts` WHERE `serial` = ? LIMIT 2", serial)
    if checkSerial and #checkSerial == 2 then
        triggerClientEvent(client, "loginResponseServer", resourceRoot, "Wykorzystałeś już limit zakładania kont na jednym serialu (2).", "error")
        return
    end

    local checkEmail = exports.TR_mysql:querry("SELECT UID FROM `tr_accounts` WHERE `email` = ? LIMIT 1", email)
    if checkEmail and checkEmail[1] then
        triggerClientEvent(client, "loginResponseServer", resourceRoot, "Ten email jest już przypisany do jednego konta.", "error")
        return
    end


    local referenceUID = false
    if reference then
        referenceUID = teaDecodeBinary(reference, "XayDpN36bGKGvfbD")
        if tonumber(referenceUID) == nil or string.len(referenceUID) < 1 then
            triggerClientEvent(client, "loginResponseServer", resourceRoot, "Kod referencyjny jest nieprawidłowy.", "error", "reference")
            return
        end
    end

    exports.TR_mysql:querry("INSERT INTO `tr_accounts` (`login`, `password`, `email`, `serial`, `createIP`, `position`, `referencedPlayer`, `money`, `phoneBlocked`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, '[[]]')", login, teaEncode(password, 'keY%@'), email, getPlayerSerial(client), getPlayerIP(client), settings.spawnPositions[math.random(1, #settings.spawnPositions)], referenceUID and referenceUID or false, referenceUID and 500 or 0)
    triggerClientEvent(client, "loginResponseServer", resourceRoot, false, "success", "accountCreate")
end
addEvent("registerAccount", true)
addEventHandler("registerAccount", resourceRoot, registerAccount)

function loginAccount(login, password)
    local performLogin = exports.TR_mysql:querry("SELECT UID, password, username FROM `tr_accounts` WHERE `login` = ? LIMIT 1", login)
    if performLogin and performLogin[1] then
        if (performLogin[1]["password"] == teaEncode(password, 'keY%@')) then
        --if passwordVerify(password, performLogin[1]["password"]) then
            if isPlayerLogged(performLogin[1]["UID"]) then triggerClientEvent(client, "loginResponseServer", resourceRoot, "Te konto jest już zalogowane.", "error") return end
            if checkBanAccount(performLogin[1]["UID"]) then triggerClientEvent(client, "loginResponseServer", resourceRoot, "Te konto jest zbanowane i nie możesz się na nie zalogować.", "error") return end

            if performLogin[1].username then
                setPlayerName(client, performLogin[1].username)
            end
            setElementData(client, "tempUID", performLogin[1].UID)
            exports.TR_mysql:querry("UPDATE tr_accounts SET isOnline = 1, lastOnline = NOW() WHERE `UID` = ? LIMIT 1", performLogin[1].UID)

            triggerClientEvent(client, "loginPlayer", resourceRoot, performLogin[1].username)

            local serial = getPlayerSerial(client)
            local ip = getPlayerIP(client)
            exports.TR_mysql:querry("INSERT INTO `tr_logs` (player, text, serial, ip, type) VALUES (?, ?, ?, ?, ?)", performLogin[1].UID, "Pomyślnie zalogowano na konto.", serial, ip, "login")
            exports.TR_mysql:querry("UPDATE `tr_accounts` SET `lastOnline` = NOW() WHERE UID = ? LIMIT 1;", performLogin[1].UID)
        else
            triggerClientEvent(client, "loginResponseServer", resourceRoot, "Wpisane hasło jest niepoprawne.", "error")
            exports.TR_mysql:querry("INSERT INTO `tr_logs` (player, text, serial, ip, type) VALUES (?, ?, ?, ?, ?)", performLogin[1].UID, "Podano błędne hasło.", serial, ip, "login")
        end
    else
        triggerClientEvent(client, "loginResponseServer", resourceRoot, "Taki użytkownik nie istnieje.", "error")
    end
end
addEvent("loginAccount", true)
addEventHandler("loginAccount", resourceRoot, loginAccount)


function checkPlayerPremium(UID)
    local rank = exports.TR_mysql:querry("SELECT CASE WHEN `diamond` > NOW() THEN 'diamond' WHEN `gold` > NOW() THEN 'gold' ELSE NULL END as 'rank' FROM tr_accounts WHERE UID = ? LIMIT 1", UID)
    if rank and rank[1] then
        return rank[1].rank
    end
    return false
end

function onLoadCharacterData(data, plrData)
    local client = data.plr
    removeElementData(client, "tempUID")
    setElementData(client, "characterUID", data.plrUID)

    local uid = getElementData(client, 'characterUID');

    local pos = split(data.respawnPos or plrData[1].position, ",")
    spawnPlayer(client, pos[1], pos[2], pos[3], data.respawnRot or 0, 0, 0)
    setElementInterior(client, pos[4])
    setElementDimension(client, pos[5])

    setTimer(setElementRotation, 100, 1, client, 0, 0, data.respawnRot or 0)

    if tonumber(plrData[1].skin) ~= nil then
        setElementModel(client, tonumber(plrData[1].skin))
        setElementData(client, "customModel", nil)
    else
        setElementModel(client, 0)
        setElementData(client, "customModel", tostring(plrData[1].skin))
    end

    setElementHealth(client, tonumber(plrData[1].health))
    setPlayerName(client, plrData[1].username)

    local data = {
        skin = tostring(plrData[1].skin),
        premium = checkPlayerPremium(data.plrUID),
        money = plrData[1].money,
        licence = plrData[1].licence and fromJSON(plrData[1].licence) or {},
        bankcode = plrData[1].bankcode or false,
        enterTime = getTickCount()
    }
    setElementData(client, "characterData", data)
    setElementData(client, "characterPoints", tonumber(plrData[1].jobPoints))

    local features = {}
    for i, v in pairs(split(plrData[1].features, ",")) do
        features[i] = tonumber(v)
    end
    setElementData(client, "characterFeatures", features)

    setPedStat(client, 22, (features[2] or 0) * 10)
    setPedStat(client, 225, (features[2] or 0) * 10)

    if plrData[1].usernameRP then
        setElementData(client, "usernameRP", plrData[1].usernameRP)
    end

    if plrData[1].ticketPrice then
        setElementData(client, "ticketPrice", tonumber(plrData[1].ticketPrice))
    end

    if plrData[1].bwTime then
        triggerClientEvent(client, "openBW", resourceRoot, plrData[1].bwTime)
    else
        triggerEvent("updatePlayerMask", resourceRoot, client)
    end

    triggerEvent("setPlayerID", resourceRoot, client)
    triggerEvent("updatePlayerWeather", resourceRoot, client)
    triggerEvent("updatePlayerPhone", resourceRoot, client)
    triggerEvent("loadPlayerAchievements", resourceRoot, client)

    triggerClientEvent(client, "loadSpawnSelectCharacter", resourceRoot, nil)
end
addEvent("onLoadCharacterData", true)
addEventHandler("onLoadCharacterData", root, onLoadCharacterData)

function spawnPlayerCharacter(respawnPos, respawnRot)
    if not client then return end
    local plrUID = getElementData(client, "tempUID")
    if not plrUID then return end

    exports.TR_mysql:querryAsync({
        callback = "onLoadCharacterData",
        plr = client,
        respawnPos = respawnPos,
        respawnRot = respawnRot,
        plrUID = plrUID,
    }, "SELECT username, usernameRP, skin, health, position, money, bankcode, licence, bwTime, ticketPrice, features, jobPoints FROM `tr_accounts` WHERE `UID` = ? LIMIT 1", plrUID)
end
addEvent("spawnPlayerCharacter", true)
addEventHandler("spawnPlayerCharacter", root, spawnPlayerCharacter)


function loadPlayerData(plr, plrUID)
    if not plr or not plrUID then return end
    local plrData = exports.TR_mysql:querry("SELECT skin, money, licence FROM `tr_accounts` WHERE `UID` = ? LIMIT 1", plrUID)

    local data = {
        skin = tonumber(plrData[1].skin),
        premium = checkPlayerPremium(plrUID),
        money = plrData[1].money,
        licence = plrData[1].licence and fromJSON(plrData[1].licence) or {},
        enterTime = getTickCount()
    }

    setElementData(plr, "characterData", data)
end
addEvent("loadPlayerData", true)
addEventHandler("loadPlayerData", resourceRoot, loadPlayerData)


function updatePlayerOrganization(plr, plrUID)
    local orgPlr = exports.TR_mysql:querry("SELECT tr_organizations.ID as ID, name, tr_organizations.type as type, moneyBonus, orgType FROM tr_organizations INNER JOIN tr_organizationsPlayers ON tr_organizations.ID = tr_organizationsPlayers.orgID WHERE playerUID = ? AND tr_organizations.removed IS NULL LIMIT 1", plrUID)
    if orgPlr and orgPlr[1] then
        setElementData(plr, "characterOrg", orgPlr[1].name)
        setElementData(plr, "characterOrgID", orgPlr[1].ID)
        setElementData(plr, "characterOrgType", orgPlr[1].type)
        setElementData(plr, "characterOrgMoneyPercent", orgPlr[1].moneyBonus)
        setElementData(plr, "characterGangType", orgPlr[1].orgType)
    else
        removeElementData(plr, "characterOrg")
        removeElementData(plr, "characterOrgID")
        removeElementData(plr, "characterOrgType")
        removeElementData(plr, "characterOrgMoneyPercent")
        removeElementData(plr, "characterGangType")
    end
end

-- Utils
function isPlayerLogged(uid)
    local isOnline = exports.TR_mysql:querry("SELECT UID FROM tr_accounts WHERE `UID` = ? AND isOnline IS NOT NULL LIMIT 1", uid)
    if isOnline and isOnline[1] then
        return true
    end
    return false
end

function checkUsernameFree(username)
    local isFree = exports.TR_mysql:querry("SELECT UID FROM `tr_accounts` WHERE `username` = ? LIMIT 1", username)
    if isFree and isFree[1] then
        triggerClientEvent(client, "checkUsernameValid", resourceRoot, username)
    else
        triggerClientEvent(client, "checkUsernameValid", resourceRoot, username, true)
    end
end
addEvent("checkUsernameFree", true)
addEventHandler("checkUsernameFree", root, checkUsernameFree)

function setPlayerUsername(username)
    local uid = getElementData(client, "tempUID")
    if not uid then return end

    exports.TR_mysql:querry("UPDATE `tr_accounts` SET username = ? WHERE UID = ? LIMIT 1", username, uid)

    triggerClientEvent(client, "loginPlayer", resourceRoot, username, true)
end
addEvent("setPlayerUsername", true)
addEventHandler("setPlayerUsername", root, setPlayerUsername)



function teaDecodeBinary(data, key)
    return base64Decode(teaDecode(data, key))
end

function openPlayerSpawnSelect()
    local uid = getElementData(client, "tempUID")
    if not uid then return end

	loadPlayerData(client, uid)
	updatePlayerOrganization(client, uid)

	local orgID = getElementData(client, "characterOrgID")
	local panelData = {}

    local playerData = exports.TR_mysql:querry("SELECT skin, position, bwTime, prisonData FROM `tr_accounts` WHERE UID = ? LIMIT 1", uid)
	panelData.lastPos = playerData[1].position
	panelData.bwTime = playerData[1].bwTime

    if playerData[1].prisonData then
        local prisonData = fromJSON(playerData[1].prisonData)

        if prisonData then
            prisonData.position = exports.TR_jail:getFreePrizonPosition(prisonData.prisonIndex)
            panelData.prisonData = prisonData
            setElementData(client, "prisonIndex", tonumber(prisonData.prisonIndex))
        end
    end

    if orgID then
        local playerHouses = exports.TR_mysql:querry("SELECT pos, ownedOrg FROM `tr_houses` WHERE (owner = ? OR ownedOrg = ?) AND date > NOW()", uid, orgID)
        panelData.houses = playerHouses
    else
        local playerHouses = exports.TR_mysql:querry("SELECT pos, ownedOrg FROM `tr_houses` WHERE owner = ? AND date > NOW()", uid)
        panelData.houses = playerHouses
    end
    panelData.rentHouses = exports.TR_mysql:querry("SELECT tr_houses.pos, tr_houses.ownedOrg FROM `tr_houses` LEFT JOIN tr_housesRent ON tr_houses.ID = tr_housesRent.houseID WHERE tr_housesRent.plrUID = ? AND tr_houses.date > NOW()", uid)

    local fractionData = exports.TR_mysql:querry("SELECT fractionID FROM `tr_fractionsPlayers` WHERE playerUID = ? LIMIT 1", uid)
    if fractionData and fractionData[1] then
        panelData.fractionID = fractionData[1].fractionID
    end
    triggerClientEvent(client, "createSpawnSelect", resourceRoot, playerData[1].skin, panelData)
end
addEvent("openPlayerSpawnSelect", true)
addEventHandler("openPlayerSpawnSelect", root, openPlayerSpawnSelect)