function giveMoneyToPlayer(plr, amount, blockOutput)
  local UID = getElementData(plr, "characterUID")
  if not UID or not isElement(plr) or not amount then return false end
  amount = getMoneyCount(amount)

  local data = getElementData(plr, "characterData")
  if not data then return end

  data.money = tonumber(data.money) + amount
  setElementData(plr, "characterData", data)

  triggerClientEvent(plr, "updatePlayerHud", resourceRoot)

  if not blockOutput then
    local resName = getResourceName(sourceResource)
    if resName then
      --local time = getRealTime()
      --exports.TR_discord:sendChannelMsg("moneyEarnings", {
      --  time = string.format("[%02d:%02d %02d.%02d]", time.hour, time.minute, time.monthday, time.month),
       ---- author = string.format("%s", getPlayerName(plr)),
      --  text = string.format("zarobił / otrzymał $%.2f z zasobu %s.", amount, resName),
      --})

      local time = getRealTime()
    local tf = string.format("[%02d:%02d %02d.%02d]", time.hour, time.minute, time.monthday, time.month)
    exports.TR_discord:remoteDsc(tf.." | "..string.format("**%s** zarobił **$%.2f** (**%s**)", getPlayerName(plr), amount, resName), "prace")
    end
  end

  return true
end

function takeMoneyFromPlayer(plr, amount)
  local UID = getElementData(plr, "characterUID")
  if not UID or not isElement(plr) or not amount then return false end
  amount = getMoneyCount(amount)

  local data = getElementData(plr, "characterData")
  if not data then return end
  data.money = tonumber(data.money)
  if data.money < amount then return false end

  data.money = data.money - amount

  setElementData(plr, "characterData", data)

  triggerClientEvent(plr, "updatePlayerHud", resourceRoot)
  return true
end

function transferMoneyToPlayer(targetID, amount)
  local UID = getElementData(source, "characterUID")
  if not UID or not isElement(source) or not targetID or not amount then triggerClientEvent(source, "showCustomMessage", resourceRoot, "#008a2eUżycie komendy", "#438f5c/przelej (ID/Nick) (kwota)", "files/images/command.png") return end
  amount = getMoneyCount(amount)
  if not amount then return end

  local target = findPlayer(source, targetID)
  if not target then return end
  if not getElementData(target, "characterUID") or not getElementData(target, "ID") then exports.TR_noti:create(source, "Ten gracz nie jest zalogowany.", "error") return end

  if source == target then exports.TR_noti:create(source, "Nie możesz przekazać pieniędzy samemu sobie.", "error") return end
  if amount < 0.01 then exports.TR_noti:create(source, "Minimalna kwota wynosi $0.01.", "error") return end

  local data = getElementData(source, "characterData")
  if not data then return end
  local plrMoney = tonumber(data.money)
  if plrMoney < amount then exports.TR_noti:create(source, "Nie posiadasz przy sobie tylu pieniędzy.", "error") return end

  if takeMoneyFromPlayer(source, amount) then
    giveMoneyToPlayer(target, amount, true)

    local plrName = getPlayerName(source)
    local id = getElementData(source, "ID")
    local targetName = getPlayerName(target)
    local idTo = getElementData(target, "ID")

    exports.TR_noti:create(source, string.format("Przekazałeś graczowi %s kwotę $%.2f.", targetName, amount), "money")
    exports.TR_noti:create(target, string.format("Gracz %s przekazał ci kwotę $%.2f.", plrName, amount), "money")

    local plrName = getPlayerName(source)
    exports.TR_admin:updateLogs(string.format("#43b60e(MONEY)#ffffff %s %d → %s %d: $%.2f", plrName, id, targetName, idTo, amount))

    local time = getRealTime()


    local tf = string.format("[%02d:%02d %02d.%02d]", time.hour, time.minute, time.monthday, time.month)
    exports.TR_discord:remoteDsc(tf.." | "..string.format("**%s** → **%s** (**$%.2f**)", plrName, targetName, amount), "przelewy")
  end
end
addEvent("transferMoneyToPlayer", true)
addEventHandler("transferMoneyToPlayer", root, transferMoneyToPlayer)
exports.TR_chat:addCommand("przelej", "transferMoneyToPlayer")







function giveBankMoneyToPlayer(plr, amount)
  local UID = getElementData(plr, "characterUID")
  if not UID or not isElement(plr) or not amount then return false end
  amount = getMoneyCount(amount)

  exports.TR_mysql:querry("UPDATE `tr_accounts` SET `bankmoney` = `bankmoney` + ? WHERE `UID` = ?", amount, UID)
  return true
end

function takeBankMoneyFromPlayer(plr, amount)
  local UID = getElementData(plr, "characterUID")
  if not UID or not isElement(plr) or not amount then return false end
  amount = getMoneyCount(amount)

  local querry = exports.TR_mysql:querry("SELECT bankmoney FROM `tr_accounts` WHERE `UID` = ?", UID)
  if not querry or not querry[1] then return false end
  querry[1].bankmoney = tonumber(querry[1].bankmoney)
  if querry[1].bankmoney < amount then return false end

  querry[1].bankmoney = querry[1].bankmoney - amount

  exports.TR_mysql:querry("UPDATE `tr_accounts` SET `bankmoney`= ? WHERE `UID` = ?", string.format("%.2f", querry[1].bankmoney), UID)
  return true
end







-- Payment
function createPayment(amount, trigger, ...)
  if not client then return end
  local UID = getElementData(client, "characterUID")
  if not UID then return end

  local querry = exports.TR_mysql:querry("SELECT bankmoney FROM `tr_accounts` WHERE `UID` = ?", UID)
  if not querry or not querry[1] then return end

  triggerClientEvent(client, "createPaymentScreen", resourceRoot, amount, tonumber(querry[1].bankmoney), trigger, ...)
end
addEvent("createPayment", true)
addEventHandler("createPayment", root, createPayment)

function performPayment(payment, money, trigger, ...)
  if not client then return end
  local UID = getElementData(client, "characterUID")
  if not UID then return end

  local paid = false
  if payment == "cash" then
    paid = takeMoneyFromPlayer(client, money)
  elseif payment == "card" then
    paid = takeBankMoneyFromPlayer(client, money)
  end

  triggerEvent(trigger, client, paid, ...)
end
addEvent("performPayment", true)
addEventHandler("performPayment", root, performPayment)

function cancelPayment(trigger, ...)
  if not client then return end
  local UID = getElementData(client, "characterUID")
  if not UID then return end

  triggerEvent(trigger, client, false, ...)
end
addEvent("cancelPayment", true)
addEventHandler("cancelPayment", root, cancelPayment)

-- Utils
function getMoneyCount(count)
  if tonumber(count) == nil then return 0 end
  local money = tonumber(string.format("%.2f", tonumber(count)))
  if money < 0 then return 0 end
  return money
end

function findPlayer(plr, id)
  local target = getElementByID("ID"..id)
  if not target then target = getPlayerFromName(id) end
  if not target or not isElement(target) then exports.TR_noti:create(plr, "Podany gracz nie został znaleziony.", "error") return false end
  return target
end