local NPCs = {
    {
        skin = 211,
        pos = Vector3(208.83096313477, -98.705436706543, 1005.2578125),
        int = 15,
        dim = 1,
        rot = 177,
        name = "Judie White",
        role = "Sprzedawca",
        shop = "binco",
    },
    {
        skin = 211,
        pos = Vector3(208.83096313477, -98.705436706543, 1005.2578125),
        int = 15,
        dim = 2,
        rot = 177,
        name = "Melanie Light",
        role = "Sprzedawca",
        shop = "binco",
    },
    {
        skin = 211,
        pos = Vector3(208.83096313477, -98.705436706543, 1005.2578125),
        int = 15,
        dim = 3,
        rot = 177,
        name = "Lucia Brown",
        role = "Sprzedawca",
        shop = "binco",
    },
    {
        skin = 211,
        pos = Vector3(208.83096313477, -98.705436706543, 1005.2578125),
        int = 15,
        dim = 4,
        rot = 177,
        name = "Octavia Grom",
        role = "Sprzedawca",
        shop = "binco",
    },

    {
        skin = 128,
        pos = Vector3(1911.5119628906, -1230.6209716797, 173.55155944824),
        int = 0,
        dim = 2,
        rot = 177,
        name = "Richard Jones",
        role = "Sprzedawca",
        shop = "ranch",
    },

    {
        skin = 211,
        pos = Vector3(203.80952453613, -41.670997619629, 1001.8046875),
        int = 1,
        dim = 1,
        rot = 181,
        name = "Jessica Molt",
        role = "Sprzedawca",
        shop = "urban",
    },
    {
        skin = 211,
        pos = Vector3(203.80952453613, -41.670997619629, 1001.8046875),
        int = 1,
        dim = 2,
        rot = 181,
        name = "Nicole Turner",
        role = "Sprzedawca",
        shop = "urban",
    },
    {
        skin = 211,
        pos = Vector3(203.80952453613, -41.670997619629, 1001.8046875),
        int = 1,
        dim = 3,
        rot = 181,
        name = "Tiana Garcie",
        role = "Sprzedawca",
        shop = "urban",
    },

    {
        skin = 211,
        pos = Vector3(160.42553710938, -81.1904296875, 1001.8046875),
        int = 18,
        dim = 1,
        rot = 178,
        name = "Tiana Crone",
        role = "Sprzedawca",
        shop = "zip",
    },
    {
        skin = 211,
        pos = Vector3(160.42553710938, -81.1904296875, 1001.8046875),
        int = 18,
        dim = 2,
        rot = 178,
        name = "Pauline Willson",
        role = "Sprzedawca",
        shop = "zip",
    },
    {
        skin = 211,
        pos = Vector3(160.42553710938, -81.1904296875, 1001.8046875),
        int = 18,
        dim = 3,
        rot = 178,
        name = "Sylvia Cina",
        role = "Sprzedawca",
        shop = "zip",
    },
    {
        skin = 211,
        pos = Vector3(160.42553710938, -81.1904296875, 1001.8046875),
        int = 18,
        dim = 4,
        rot = 178,
        name = "Maya Banks",
        role = "Sprzedawca",
        shop = "zip",
    },

    {
        skin = 217,
        pos = Vector3(204.27568054199, -157.8302154541, 1000.5234375),
        int = 14,
        dim = 1,
        rot = 182,
        name = "Paul Versetti",
        role = "Sprzedawca",
        shop = "didier",
    },

    {
        skin = 211,
        pos = Vector3(204.85377502441, -8.0486392974854, 1001.2109375),
        int = 5,
        dim = 1,
        rot = 273,
        name = "Katie Jefferson",
        role = "Sprzedawca",
        shop = "victim",
    },
    {
        skin = 211,
        pos = Vector3(204.85377502441, -8.0486392974854, 1001.2109375),
        int = 5,
        dim = 2,
        rot = 273,
        name = "Emilie Post",
        role = "Sprzedawca",
        shop = "victim",
    },
    {
        skin = 211,
        pos = Vector3(204.85377502441, -8.0486392974854, 1001.2109375),
        int = 5,
        dim = 3,
        rot = 273,
        name = "Dominica Flower",
        role = "Sprzedawca",
        shop = "victim",
    },

    {
        skin = 217,
        pos = Vector3(207.00144958496, -127.78814697266, 1003.5078125),
        int = 3,
        dim = 1,
        rot = 182,
        name = "Victor Black",
        role = "Sprzedawca",
        shop = "prolaps",
    },
    {
        skin = 217,
        pos = Vector3(207.00144958496, -127.78814697266, 1003.5078125),
        int = 3,
        dim = 2,
        rot = 182,
        name = "Simon Gras",
        role = "Sprzedawca",
        shop = "prolaps",
    },

    {
        skin = 217,
        pos = Vector3(157.56181335449, -150.62013244629, 1023.168762207),
        int = 14,
        dim = 2,
        rot = 182,
        name = "Mark Vans",
        role = "Sprzedawca",
        shop = "kc",
    },

    {
        skin = 217,
        pos = Vector3(153.70928955078, -13.722857475281, 1005.3690185547),
        int = 18,
        dim = 3,
        rot = 182,
        name = "Philip Grant",
        role = "Sprzedawca",
        shop = "gnocchi",
    },
}

function createNPCs()
    local dialogue = exports.TR_npc:createDialogue()
    exports.TR_npc:addDialogueText(dialogue, "Dzień dobry.", {pedResponse = "Dzień dobry. W czym mogę pomóc?"})
    exports.TR_npc:addDialogueText(dialogue, "Chciałbym coś przymierzyć.", {pedResponse = "Proszę się nie krępować. Przebieralnia znajduję się tam.", responseTo = "Dzień dobry.", img = "tshirt", trigger = "openClothesShop"})
    exports.TR_npc:addDialogueText(dialogue, "Dziękuję, nie trzeba. Poradzę sobie.", {pedResponse = "Jasne. Jeżeli zaszłaby taka potrzeba to proszę pytać.", responseTo = "Dzień dobry."})
    exports.TR_npc:addDialogueText(dialogue, "Do widzenia.", {pedResponse = "Do widzenia."})

    for i, v in pairs(NPCs) do
        local ped = exports.TR_npc:createNPC(v.skin, v.pos.x, v.pos.y, v.pos.z, v.rot, v.name, v.role, "dialogue")
        setElementInterior(ped, v.int)
        setElementDimension(ped, v.dim)
        exports.TR_npc:setNPCDialogue(ped, dialogue)

        setElementData(ped, "shop", v.shop, false)
    end
end
createNPCs()


function playerBuySkin(state, data)
    if state then
        local uid = getElementData(source, "characterUID")
        if not uid then return end
        exports.TR_mysql:querry("INSERT INTO `tr_items`(`owner`, `type`, `variant`, `variant2`, `value`, `used`, `favourite`) VALUES (?,?,?,?,?,NULL,NULL)", uid, 3, itemValues[data[1]], 0, data[2])
        exports.TR_items:updateItems(source)

        triggerClientEvent(source, "responseSkinShop", resourceRoot, true)
    else
        triggerClientEvent(source, "responseSkinShop", resourceRoot, false)
    end
end
addEvent("playerBuySkin", true)
addEventHandler("playerBuySkin", root, playerBuySkin)


function openClothesShop(ped)
    local shop = getElementData(ped, "shop")
    triggerClientEvent(source, "createSkinShop", resourceRoot, shop)
end
addEvent("openClothesShop", true)
addEventHandler("openClothesShop", root, openClothesShop)