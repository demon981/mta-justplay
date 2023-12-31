local NPCs = {
    {
        skin = 130,
        pos = Vector3(2420.9453125, 98.06640625, 26.476562),
        rot = 127,
        name = "Diana Donald",
        vegetables = true,
    },
    {
        skin = 197,
        pos = Vector3(2420.9287109375, 85.9013671875, 26.4765625),
        rot = 42,
        name = "Kali Livingston",
    },

    {
        skin = 130,
        pos = Vector3(668.197265625, -622.1259765625, 16.3359375),
        rot = 26,
        name = "Leena Wainwright",
        vegetables = true,
    },
    {
        skin = 197,
        pos = Vector3(657.9794921875, -622.060546875, 16.3359375),
        rot = 335,
        name = "Jenny Parrish",
    },
}

function createOldStallNPC()
    local dialogue = exports.TR_npc:createDialogue()
    exports.TR_npc:addDialogueText(dialogue, "Ale piękne owoce.", {pedResponse = "Proszę zabierać, ja zważę i będzie świetnie.", trigger = "openTallOldShop", triggerData = {"apple"}})
    exports.TR_npc:addDialogueText(dialogue, "Do widzenia.", {pedResponse = "Do widzenia."})

    local dialogue2 = exports.TR_npc:createDialogue()
    exports.TR_npc:addDialogueText(dialogue2, "Nie pryskane te warzywka?", {pedResponse = "Nie. Nie pryskane. W pełni naturalne. Proszę sobie coś wybrać.", trigger = "openTallOldShop", triggerData = {"carrot"}})
    exports.TR_npc:addDialogueText(dialogue2, "Do widzenia.", {pedResponse = "Do widzenia."})

    for i, v in pairs(NPCs) do
        local ped = exports.TR_npc:createNPC(v.skin, v.pos.x, v.pos.y, v.pos.z, v.rot, v.name, "Staruszka", "dialogue")
        setElementData(ped, "name", v.name)

        if v.vegetables then
            exports.TR_npc:setNPCDialogue(ped, dialogue)
        else
            exports.TR_npc:setNPCDialogue(ped, dialogue2)
        end
    end
end
createOldStallNPC()

function openTallOldShop(ped, data)
    local uid = getElementData(client, "characterUID")
    local pedName = getElementData(ped, "name")

    if data[1] == "apple" then
        triggerClientEvent(client, "createShop", resourceRoot, "Stragan z owocami", {
            {
                type = 2,
                variant = 5,
                variant2 = 0,
                price = 20,
            },
            {
                type = 2,
                variant = 5,
                variant2 = 1,
                price = 60,
            },
            {
                type = 2,
                variant = 5,
                variant2 = 2,
                price = 100,
            },
        })

    elseif data[1] == "carrot" then
        triggerClientEvent(client, "createShop", resourceRoot, "Stragan z warzywami", {
            {
                type = 2,
                variant = 5,
                variant2 = 3,
                price = 20,
            },
            {
                type = 2,
                variant = 5,
                variant2 = 4,
                price = 60,
            },
            {
                type = 2,
                variant = 5,
                variant2 = 5,
                price = 100,
            },
        })
    end
end
addEvent("openTallOldShop", true)
addEventHandler("openTallOldShop", root, openTallOldShop)