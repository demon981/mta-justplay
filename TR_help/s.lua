function getHelpUpdates()
    local updates = exports.TR_mysql:querry("SELECT text FROM `tr_updates` ORDER BY `ID` DESC LIMIT ?", 10)
    if updates and updates[1] then
      triggerClientEvent(client, "updateHelpUpdates", resourceRoot, updates)
    else
      triggerClientEvent(client, "updateHelpUpdates", resourceRoot, {{text = "Nie udało się pobrać listy zmian."}})
    end
  end
  addEvent("getHelpUpdates", true)
  addEventHandler("getHelpUpdates", resourceRoot, getHelpUpdates)