local walton = createVehicle(478, 915.08209228516, -374.29446411133, 51.786607513428, 14, 14, 208)
setElementFrozen(walton, true)
setVehicleLocked(walton, true)
setVehicleVariant(walton, 3, 1)
setTimer(setVehicleDoorOpenRatio, 1000, 1, walton, 1, 1, 0)

local walton2 = createVehicle(478, 1013.3, -335.70001, 74.1, 0, 0, 60)
setElementFrozen(walton2, true)
setVehicleLocked(walton2, true)
setVehicleVariant(walton2, 3, 1)
setTimer(setVehicleDoorOpenRatio, 1000, 1, walton2, 1, 1, 0)


local dialogue = exports.TR_npc:createDialogue()
exports.TR_npc:addDialogueText(dialogue, "Siema. Dlaczego nie pracujesz?", {pedResponse = "Co?! Ja nie pracuję?! A może sam weźmiesz się do roboty? Ładuj jabłka na furę a nie gadasz mi tutaj bez sensu."})
exports.TR_npc:addDialogueText(dialogue, "Nara.", {pedResponse = "No cześć."})

local ped = exports.TR_npc:createNPC(158, 916.904296875, -374.56094360352, 52.418647766113, 301, "Wieslaw Norter", "Wieśniak", "dialogue")
exports.TR_npc:setNPCDialogue(ped, dialogue)