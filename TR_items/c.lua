local sx, sy = guiGetScreenSize()
zoom = 1
local baseX = 1920
local minZoom = 2
if sx < baseX then
  zoom = math.min(minZoom, baseX/sx)
end

GUI = {}

local guiData = {
    x = sx - 600/zoom,
    y = (sy - 362/zoom)/2,
    w = 600/zoom,
    h = 362/zoom,

    accept = {
        x = (sx - 430/zoom)/2,
        y = (sy - 150/zoom)/2,
        w = 430/zoom,
        h = 150/zoom
    },

    preview = {
        x = (sx - 500/zoom)/2,
        w = 500/zoom,
    },

    rent = {
        x = (sx - 400/zoom)/2,
        y = (sy - 390/zoom)/2,
        w = 400/zoom,
        h = 390/zoom,
    },

    split = {
        x = (sx - 400/zoom)/2,
        y = (sy - 220/zoom)/2,
        w = 400/zoom,
        h = 220/zoom,
    },

    categories = {
        "favourite", "food", "clothes", "keys", "weapons", "other"
    },

    categoryNames = {
        ["favourite"] = "Ulubione",
        ["food"] = "Żywność",
        ["clothes"] = "Ubrania",
        ["keys"] = "Klucze",
        ["weapons"] = "Bronie",
        ["other"] = "Inne",
    },

    firedAmmunitions = {},

    maxCapacity = {
        standard = 15,
        addition = 35,
    },
}

Equipment = {}
Equipment.__index = Equipment

function Equipment:create(...)
    local instance = {}
    setmetatable(instance, Equipment)
    if instance:constructor(...) then
        return instance
    end
    return false
end

function Equipment:constructor()
    self.maxWidth = guiData.maxCapacity.standard

    self.alpha = 0
    self.state = "closed"
    self.selectedCategory = "favourite"
    self.scroll = 0
    self.details = {}

    self.fonts = {}
    self.fonts.title = exports.TR_dx:getFont(14)
    self.fonts.name = exports.TR_dx:getFont(13)
    self.fonts.category = exports.TR_dx:getFont(10)
    self.fonts.optionsName = exports.TR_dx:getFont(12)
    self.fonts.options = exports.TR_dx:getFont(11)
    self.fonts.preview = exports.TR_dx:getFont(11)
    self.fonts.blockInfo = exports.TR_dx:getFont(9)

    self.func = {}
    self.func.renderer = function() self:render() end
    self.func.clicker = function(...) self:click(...) end
    self.func.switcher = function(...) self:switch(...) end
    self.func.btnClicker = function(...) self:clickAccept(...) end
    self.func.scroller = function(...) self:scrollKey(...) end
    self.func.checkSprint = function(...) self:checkSprint(...) end

    bindKey("i", "down", self.func.switcher)
    return true
end

function Equipment:isPlayerOverloaded()
    if not self.details then return false end
    if not self.details.total then return false end
    return self.details.total.weight > self.maxWidth
end


function Equipment:switch()
    if self.opened then
        self:close()
    else
        self:open()
    end
end

function Equipment:open(force)
    if self.state ~= "closed" then return end
    if not exports.TR_dx:canOpenGUI() and not force then return end

    if not getElementData(localPlayer, "characterUID") then return end
    if exports.TR_chat:isChatOpened() then return end

    exports.TR_dx:setOpenGUI(true)
    addEventHandler("onClientRender", root, self.func.renderer, false, "normal-2")
    addEventHandler("onClientClick", root, self.func.clicker)

    self.opened = true

    self.selectedItems = nil
    self.splitingItem = nil
    self.scroll = 0
    self.maxWidth = guiData.maxCapacity.standard + (guiData.maxCapacity.addition * exports.TR_features:getFeatureValue("strenght")/100)

    self.category = "favourite"
    self:animateOpen()

    if self.lastSync then
        if (getTickCount() - self.lastSync)/60000 < 1 then
            self:setCategory("favourite")
            return
        end
    end

    self.loaded = false
    self.rot = 0
    triggerServerEvent("getItems", resourceRoot)
end

function Equipment:close(force)
    if not self.loaded then return end
    if not self.opened then return end
    if self.state ~= "opened" then return end
    if GUI.egg then return end

    if exports.TR_dx:isResponseEnabled() then return end

    if self.tradeOpened then return exports.TR_noti:create("Nie można zamknąć ekwipunku podczas wymiany.", "error") end
    self.opened = nil

    self.tick = getTickCount()
    self.state = "closing"
    self.alphaLast = self.alpha

    self.selectedItem = nil

    showCursor(false)
    removeEventHandler("onClientClick", root, self.func.clicker)

    unbindKey("mouse_wheel_up", "down", self.func.scroller)
    unbindKey("mouse_wheel_down", "down", self.func.scroller)

    if self.buttons then exports.TR_dx:hideButton(self.buttons) end
    if self.edits then exports.TR_dx:hideEdit(self.edits) end
    if self.btnHandler then removeEventHandler("guiButtonClick", root, self.func.btnClicker) end

    if self.boombox then
        self.boombox:close()
        self.boombox = nil
    end
    if GUI.trunk then
        GUI.trunk:close()
    end
end

function Equipment:scrollKey(...)
    if self:isMouseInPosition(guiData.x, guiData.y + 40/zoom, guiData.w - 75/zoom, 300/zoom) and not self.selectedItem and not self.blockHover then
        if arg[1] == "mouse_wheel_up" then
            if self.scroll == 0 then return end
            self.scroll = self.scroll - 1

        elseif arg[1] == "mouse_wheel_down" then
            if self.scroll >= #self.selectedItems - 5 then return end
            self.scroll = self.scroll + 1
        end
    end
end

function Equipment:checkScroll()
    if #self.selectedItems <= 5 then return end
    if self.scroll >= #self.selectedItems - 5 then
        self.scroll = #self.selectedItems - 5
    end
end


function Equipment:animateOpen()
    self.tick = getTickCount()
    self.state = "opening"
    self.alphaLast = self.alpha
    showCursor(true, false)

    bindKey("mouse_wheel_up", "down", self.func.scroller)
    bindKey("mouse_wheel_down", "down", self.func.scroller)
end


function Equipment:animate()
    if not self.tick then return end
    local progress = (getTickCount() - self.tick)/500
    if self.state == "opening" then
        self.alpha = interpolateBetween(self.alphaLast, 0, 0, 1, 0, 0, progress, "Linear")
        if progress >= 1 then
            self.alpha = 1
            self.state = "opened"
            self.tick = nil
        end

    elseif self.state == "closing" then
        self.alpha = interpolateBetween(self.alphaLast, 0, 0, 0, 0, 0, progress, "Linear")
        if progress >= 1 then
            self.alpha = 0
            self.state = "closed"
            self.tick = nil

            self.avaliableOptions = nil
            self.acceptDetails = nil
            self.blockHover = nil
            self.previewData = nil
            self.selectedItem = nil
            self.rentData = nil
            if not self.blockGui then exports.TR_dx:setOpenGUI(false) end
            if self.buttons then
                exports.TR_dx:destroyButton(self.buttons)
                self.buttons = nil
            end
            self.blockGui = nil
            removeEventHandler("onClientRender", root, self.func.renderer)
        end
    end
end

function Equipment:render()
    self:animate()
    self:drawEqBackground(guiData.x, guiData.y, guiData.w, guiData.h, tocolor(23,25,31, 255 * self.alpha), 15)
    dxDrawText("Ekwipunek", guiData.x, guiData.y, guiData.x + guiData.w - 54/zoom, guiData.y + 30/zoom, tocolor(44,181,233, 255 * self.alpha), 1/zoom, self.fonts.title, "center", "center")

    self:renderDetails()
    self:renderItems()
    self:renderCategories()
    self:renderOptions()

    self:renderAccept()
    -- self:renderPreview()
    self:renderSpliting()
    self:renderRent()

    self:renderHoveredItemDetails(self.alpha)
end

function Equipment:renderSpliting()
    if not self.splitingItem then return end

    self:drawOptionsBackground(guiData.split.x, guiData.split.y, guiData.split.w, guiData.split.h, tocolor(23,25,31, 255 * self.alpha), 9)
    dxDrawText("Dzielenie przedmiotów", guiData.split.x, guiData.split.y, guiData.split.x + guiData.split.w, guiData.split.y + 50/zoom, tocolor(44,181,233, 255 * self.alpha), 1/zoom, self.fonts.title, "center", "center", false, false, false)


end

function Equipment:renderDetails()
    if not self.loaded then return end
    dxDrawLine(guiData.x, guiData.y + guiData.h - 20/zoom, guiData.x + guiData.w, guiData.y + guiData.h - 20/zoom, tocolor(28,89,119, 255 * self.alpha))

    if self.details.total then
        if self.details.total.weight > self.maxWidth then
            dxDrawImage(guiData.x + 3/zoom, guiData.y + guiData.h - 15/zoom, 14/zoom, 14/zoom, "files/images/weight.png", 0, 0, 0, tocolor(120,120,120, 255 * self.alpha))
            dxDrawText(string.format("Waga:  %.1f / %.1f kg", self.details.total.weight, self.maxWidth), guiData.x + 24/zoom, guiData.y + guiData.h - 15/zoom, guiData.x + guiData.w, guiData.y + guiData.h, tocolor(120, 50, 50, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "center")
        else
            dxDrawImage(guiData.x + 3/zoom, guiData.y + guiData.h - 15/zoom, 14/zoom, 14/zoom, "files/images/weight.png", 0, 0, 0, tocolor(120,120,120, 255 * self.alpha))
            dxDrawText(string.format("Waga:  %.1f / %.1f kg", self.details.total.weight, self.maxWidth), guiData.x + 24/zoom, guiData.y + guiData.h - 15/zoom, guiData.x + guiData.w, guiData.y + guiData.h, tocolor(120, 120, 120, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "center")
        end

        dxDrawImage(guiData.x + 153/zoom, guiData.y + guiData.h - 15/zoom, 14/zoom, 14/zoom, "files/images/backpack.png", 0, 0, 0, tocolor(120,120,120, 255 * self.alpha))

        dxDrawText(string.format("Przedmioty:  %d", self.details.total.count), guiData.x + 174/zoom, guiData.y + guiData.h - 15/zoom, guiData.x + guiData.w, guiData.y + guiData.h, tocolor(120, 120, 120, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "center")
        dxDrawText("|", guiData.x + 275/zoom, guiData.y + guiData.h - 17/zoom, guiData.x + guiData.w, guiData.y + guiData.h, tocolor(120,120,120, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "center")

        local x = guiData.x + 290/zoom
        for i, v in pairs(guiData.categories) do
            dxDrawImage(x + (i-1) * 52/zoom, guiData.y + guiData.h - 15/zoom, 14/zoom, 14/zoom, string.format("files/images/categories/%s.png", v), 0, 0, 0, tocolor(120, 120, 120, 255 * self.alpha))

            dxDrawText(self.details[v].count, x + 20/zoom + (i-1) * 52/zoom, guiData.y + guiData.h - 15/zoom, guiData.x + guiData.w, guiData.y + guiData.h, tocolor(120, 120, 120, 255 * self.alpha), 1/zoom, self.fonts.category, "left", "center")
        end
    else
        dxDrawText("Wczytywanie danych...", guiData.x, guiData.y + guiData.h - 15/zoom, guiData.x + guiData.w, guiData.y + guiData.h, tocolor(120, 120, 120, 255 * self.alpha), 1/zoom, self.fonts.category, "center", "center")
    end
end

function Equipment:renderItems()
    if not self.loaded then
        self.rot = self.rot + 4
        if self.rot >= 360 then self.rot = self.rot - 360 end

        dxDrawImage(guiData.x + (guiData.w - 64/zoom)/2 - 27/zoom, guiData.y + 140/zoom, 64/zoom, 64/zoom, "files/images/loading.png", self.rot, 0, 0, tocolor(120, 120, 120, 255 * self.alpha))
        dxDrawText("Wczytywanie...", guiData.x, guiData.y + 220/zoom, guiData.x + guiData.w - 54/zoom, guiData.y + 30/zoom, tocolor(120, 120, 120, 255 * self.alpha), 1/zoom, self.fonts.optionsName, "center", "top")

        dxDrawRectangle(guiData.x + guiData.w - 85/zoom, guiData.y + 40/zoom, 4/zoom, 290/zoom, tocolor(23,25,31, 255 * self.alpha))
        return
    end
    if not self.selectedItems then return end
    self.hoveredItem = false
    for i = 1, 5 do
        local item = self.selectedItems[i + self.scroll]
        if item then
            local alpha = 200
            if (self:isMouseInPosition(guiData.x, guiData.y + 40/zoom + (i - 1) * 60/zoom, guiData.w - 75/zoom, 50/zoom) and not self.selectedItem and not self.blockHover) or item.ID == self.selectedItem then alpha = 230 end
            if not item.used then
                local width = dxGetTextWidth(item.name, 1/zoom, self.fonts.name)
                dxDrawImage(guiData.x + 5/zoom, guiData.y + 40/zoom + (i - 1) * 60/zoom, 50/zoom, 50/zoom, item.icon, 0, 0, 0, tocolor(220, 220, 220, alpha * self.alpha))
                dxDrawText(string.format("%s %s", item.name, item.stackable and "("..item.value2..")" or ""), guiData.x + 65/zoom, guiData.y + 43/zoom + (i - 1) * 60/zoom, guiData.x + guiData.w - 85/zoom, guiData.y + 70/zoom + (i - 1) * 60/zoom, tocolor(220, 220, 220, alpha * self.alpha), 1/zoom, self.fonts.name, "left", "top", true)
                dxDrawText(item.description, guiData.x + 65/zoom, guiData.y + 60/zoom + (i - 1) * 60/zoom, guiData.x + guiData.w - 85/zoom, guiData.y + 85/zoom + (i - 1) * 60/zoom, tocolor(150, 150, 150, alpha * self.alpha), 1/zoom, self.fonts.category, "left", "bottom", true)

                if item.isTrade then
                    dxDrawImage(guiData.x, guiData.y + 35/zoom + (i - 1) * 60/zoom, 24/zoom, 24/zoom, "files/images/transfer.png", 0, 0, 0, tocolor(28,89,119, 255 * self.alpha))
                end
            else
                dxDrawImage(guiData.x + 5/zoom, guiData.y + 40/zoom + (i - 1) * 60/zoom, 50/zoom, 50/zoom, item.icon, 0, 0, 0, tocolor(44,181,233, alpha * self.alpha))
                dxDrawText(string.format("%s %s", item.name, item.stackable and "("..item.value2..")" or ""), guiData.x + 65/zoom, guiData.y + 43/zoom + (i - 1) * 60/zoom, guiData.x + guiData.w - 85/zoom, guiData.y + 70/zoom + (i - 1) * 60/zoom, tocolor(220, 220, 220, alpha * self.alpha), 1/zoom, self.fonts.name, "left", "top", true)
                dxDrawText(item.description, guiData.x + 65/zoom, guiData.y + 60/zoom + (i - 1) * 60/zoom, guiData.x + guiData.w - 85/zoom, guiData.y + 85/zoom + (i - 1) * 60/zoom, tocolor(150, 150, 150, alpha * self.alpha), 1/zoom, self.fonts.category, "left", "bottom", true)
            end

            if (self:isMouseInPosition(guiData.x, guiData.y + 40/zoom + (i - 1) * 60/zoom, guiData.w - 75/zoom, 50/zoom) and not self.selectedItem and not self.blockHover) then
                self.hoveredItem = item
            end
        end
    end

    if #self.selectedItems > 5 then
        local b1 = 290/zoom / #self.selectedItems
        local barY = b1 * self.scroll
        local barHeight = b1 * 5
        dxDrawRectangle(guiData.x + guiData.w - 85/zoom, guiData.y + 40/zoom, 2/zoom, 290/zoom, tocolor(16,18,23, 255 * self.alpha))
        dxDrawRectangle(guiData.x + guiData.w - 85/zoom, guiData.y + 40/zoom + barY, 2/zoom, barHeight, tocolor(28,89,119, 255 * self.alpha))
    else
        dxDrawRectangle(guiData.x + guiData.w - 85/zoom, guiData.y + 40/zoom, 2/zoom, 290/zoom, tocolor(28,89,119, 255 * self.alpha))
    end
end

function Equipment:renderHoveredItemDetails(alpha)
    if self.hoveredItem then
        self:setItemPreviev(self.hoveredItem)
        local cx, cy = getCursorPosition()
        local cx, cy = cx * sx + 8, cy * sy + 8

        self:drawOptionsBackground(cx, cy, guiData.preview.w, guiData.preview.h, tocolor(16,18,23, 255 * alpha), 8, true)
        dxDrawText("Szczegółowe informacje", cx + 6/zoom, cy + 4/zoom, cx + guiData.preview.w - 6/zoom, cy + 4/zoom, tocolor(44,181,233, 255 * alpha), 1/zoom, self.fonts.optionsName, "center", "top", false, false, true, true)
        dxDrawText(string.format("Przedmiot: #8c8c8c%s", self.previewData.name), cx + 6/zoom, cy + 26/zoom, cx + guiData.preview.w, cy + 26/zoom, tocolor(190, 190, 190, 255 * alpha), 1/zoom, self.fonts.preview, "left", "top", false, false, true, true)

        if self.previewData.blockDesc then
            dxDrawText("Szczegółowe informacje są\nniedostępne dla tego przedmiotu.", cx + 6/zoom, cy + 50/zoom, cx + guiData.preview.w - 6/zoom, cy + 50/zoom, tocolor(44,181,233, 255 * alpha), 1/zoom, self.fonts.blockInfo, "left", "top", false, false, true, true)
        else
            if self.previewData.data then
                for i, v in ipairs(self.previewData.data) do
                    dxDrawText(string.format("%s: #8c8c8c%s", v.title, v.value), cx + 6/zoom, cy + 26/zoom + i * 20/zoom, cx + guiData.preview.w, cy + 26/zoom + i * 20/zoom, tocolor(190, 190, 190, 255 * alpha), 1/zoom, self.fonts.preview, "left", "top", false, false, true, true)
                end
            end
        end

        dxDrawLine(cx, cy + guiData.preview.h - 24/zoom, cx + guiData.preview.w, cy + guiData.preview.h - 24/zoom, tocolor(44,181,233, 255 * alpha), 1, true)
        dxDrawImage(cx + 6/zoom, cy + guiData.preview.h - 19/zoom, 14/zoom, 14/zoom, "files/images/weight.png", 0, 0, 0, tocolor(150, 150, 150, 255 * alpha), true)
        dxDrawText(self.previewData.weight < 1000 and string.format("Waga: %dg", self.previewData.weight) or string.format("Waga: %.1fkg", self.previewData.weight/1000), cx + 25/zoom, cy + guiData.preview.h - 19/zoom, guiData.x + guiData.w - 108/zoom, cy + guiData.preview.h - 5/zoom, tocolor(150, 150, 150, 255 * alpha), 1/zoom, self.fonts.category, "left", "center", false, false, true, true)

        dxDrawText(string.format("Ilość: %d", self.previewData.value2 or 1) or string.format("Waga: %.1fkg", self.previewData.weight/1000), cx + 25/zoom, cy + guiData.preview.h - 19/zoom, cx + guiData.preview.w - 10/zoom, cy + guiData.preview.h - 5/zoom, tocolor(150, 150, 150, 255 * alpha), 1/zoom, self.fonts.category, "right", "center", false, false, true, true)
    end
end

function Equipment:setHoveredItem(item, alpha)
    self.hoveredItem = item
    self:renderHoveredItemDetails(alpha)
end

function Equipment:renderCategories()
    for i, v in ipairs(guiData.categories) do
        local alpha = 170
        if v == self.selectedCategory then alpha = 255
        elseif (self:isMouseInPosition(guiData.x + guiData.w - 67/zoom, guiData.y + 5/zoom + (i - 1) * 56/zoom, 62/zoom, 50/zoom) and not self.selectedItem and not self.blockHover) then alpha = 220 end

        if v == self.selectedCategory then
            dxDrawImage(guiData.x + guiData.w - 52/zoom, guiData.y + 5/zoom + (i - 1) * 56/zoom, 30/zoom, 30/zoom, string.format("files/images/categories/%s.png", v), 0, 0, 0, tocolor(44,181,233, alpha * self.alpha))
            dxDrawText(guiData.categoryNames[v], guiData.x + guiData.w - 62/zoom, guiData.y + 35/zoom + (i - 1) * 56/zoom, guiData.x + guiData.w - 10/zoom, 32/zoom, tocolor(44,181,233, alpha * self.alpha), 1/zoom, self.fonts.category, "center", "top")
        else
            dxDrawImage(guiData.x + guiData.w - 52/zoom, guiData.y + 5/zoom + (i - 1) * 56/zoom, 30/zoom, 30/zoom, string.format("files/images/categories/%s.png", v), 0, 0, 0, tocolor(200, 200, 200, alpha * self.alpha))
            dxDrawText(guiData.categoryNames[v], guiData.x + guiData.w - 62/zoom, guiData.y + 35/zoom + (i - 1) * 56/zoom, guiData.x + guiData.w - 10/zoom, 32/zoom, tocolor(200, 200, 200, alpha * self.alpha), 1/zoom, self.fonts.category, "center", "top")
        end
    end
end

function Equipment:renderOptions()
    if not self.avaliableOptions then return end
    self:drawOptionsBackground(self.optionsCursor.x, self.optionsCursor.y, 200/zoom, 30/zoom * (#self.avaliableOptions + 1), tocolor(16,18,23, 255 * self.alpha), 15)
    dxDrawText("Opcje przedmiotu", self.optionsCursor.x, self.optionsCursor.y, self.optionsCursor.x + 200/zoom, self.optionsCursor.y + 30/zoom, tocolor(44,181,233, 255 * self.alpha), 1/zoom, self.fonts.optionsName, "center", "center")

    for i, v in ipairs(self.avaliableOptions) do
        if self:isMouseInPosition(self.optionsCursor.x, self.optionsCursor.y + 30/zoom * i, 200/zoom, 30/zoom) then
            dxDrawImage(self.optionsCursor.x + 5/zoom, self.optionsCursor.y + 30/zoom * i + 5/zoom, 20/zoom, 20/zoom, v.icon, 0, 0, 0, tocolor(220, 220, 220, 255 * self.alpha))
            dxDrawText(v.text, self.optionsCursor.x + 32/zoom, self.optionsCursor.y + 30/zoom * i, self.optionsCursor.x + 200/zoom, self.optionsCursor.y + 30/zoom * (i + 1), tocolor(220, 220, 220, 255 * self.alpha), 1/zoom, self.fonts.options, "left", "center")
        else
            dxDrawImage(self.optionsCursor.x + 5/zoom, self.optionsCursor.y + 30/zoom * i + 5/zoom, 20/zoom, 20/zoom, v.icon, 0, 0, 0, tocolor(170, 170, 170, 255 * self.alpha))
            dxDrawText(v.text, self.optionsCursor.x + 32/zoom, self.optionsCursor.y + 30/zoom * i, self.optionsCursor.x + 200/zoom, self.optionsCursor.y + 30/zoom * (i + 1), tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.options, "left", "center")
        end
    end
end

function Equipment:renderAccept()
    if not self.acceptDetails then return end
    self:drawOptionsBackground(guiData.accept.x, guiData.accept.y, guiData.accept.w, guiData.accept.h, tocolor(16,18,23, 255 * self.alpha), 15)

    dxDrawText(self.acceptDetails.title, guiData.accept.x, guiData.accept.y, guiData.accept.x + guiData.accept.w, guiData.accept.y + 40/zoom, tocolor(44,181,233, 255 * self.alpha), 1/zoom, self.fonts.title, "center", "center")
    dxDrawText(self.acceptDetails.description, guiData.accept.x + 10/zoom, guiData.accept.y + 40/zoom, guiData.accept.x + guiData.accept.w - 10/zoom, guiData.accept.y + guiData.accept.h - 60/zoom, tocolor(200, 200, 200, 255 * self.alpha), 1/zoom, self.fonts.optionsName, "center", "center", true, true, false, true)
end

function Equipment:renderPreview()
    if not self.previewData then return end
    self:drawOptionsBackground(guiData.preview.x, guiData.preview.y, guiData.preview.w, guiData.preview.h, tocolor(16,18,23, 255 * self.alpha), 15)

    dxDrawText("Podgląd przedmiotu", guiData.preview.x, guiData.preview.y, guiData.preview.x + guiData.preview.w, guiData.preview.y + 40/zoom, tocolor(44,181,233, 255 * self.alpha), 1/zoom, self.fonts.title, "center", "center")

    dxDrawText(string.format("Przedmiot: #999999%s", self.previewData.name), guiData.preview.x + 15/zoom, guiData.preview.y + 40/zoom, guiData.preview.x + guiData.preview.w, guiData.preview.y + 65/zoom, tocolor(220, 220, 220, 255 * self.alpha), 1/zoom, self.fonts.optionsName, "left", "top", false, false, false, true)
    if self.previewData.data then
        for i, v in ipairs(self.previewData.data) do
            dxDrawText(string.format("%s: #999999%s", v.title, v.value), guiData.preview.x + 15/zoom, guiData.preview.y + 40/zoom + i * 20/zoom, guiData.preview.x + guiData.preview.w, guiData.preview.y + 40/zoom + i * 20/zoom, tocolor(220, 220, 220, 255 * self.alpha), 1/zoom, self.fonts.optionsName, "left", "top", false, false, false, true)
        end
    end
end

function Equipment:renderRent()
    if not self.rentData then return end

    self:drawOptionsBackground(guiData.rent.x, guiData.rent.y, guiData.rent.w, guiData.rent.h, tocolor(23,25,31, 255 * self.alpha), 15)
    dxDrawText(self.rentData.title, guiData.rent.x, guiData.rent.y, guiData.rent.x + guiData.rent.w, guiData.rent.y + 40/zoom, tocolor(44,181,233, 255 * self.alpha), 1/zoom, self.fonts.title, "center", "center")

    if self.rentData.rent then
        if self.rentData.rent == "loading" then
            dxDrawText("Wczytywanie...", guiData.rent.x + 20/zoom, guiData.rent.y, guiData.rent.x + guiData.rent.w - 20/zoom, guiData.rent.y + guiData.rent.w - 100/zoom, tocolor(170, 170, 170, 255 * self.alpha), 1/zoom, self.fonts.name , "center", "center")

        else
            for i, v in pairs(self.rentData.rent) do
                if self:isMouseInPosition(guiData.rent.x, guiData.rent.y + 40/zoom + 40/zoom * (i-1), guiData.rent.w, 40/zoom) then
                    dxDrawRectangle(guiData.rent.x, guiData.rent.y + 40/zoom + 40/zoom * (i-1), guiData.rent.w, 40/zoom, tocolor(34,36,43, 255 * self.alpha))
                end
                dxDrawText(string.format("%s (%d)", v.username, v.UID), guiData.rent.x + 20/zoom, guiData.rent.y + 40/zoom + 40/zoom * (i-1), guiData.rent.x + 10/zoom, guiData.rent.y + 80/zoom + 40/zoom * (i-1), tocolor(255, 255, 255, 255 * self.alpha), 1/zoom, self.fonts.name , "left", "center")

                if self:isMouseInPosition(guiData.rent.x + guiData.rent.w - 30/zoom, guiData.rent.y + 52/zoom + 40/zoom * (i-1), 16/zoom, 16/zoom) then
                    dxDrawImage(guiData.rent.x + guiData.rent.w - 30/zoom, guiData.rent.y + 52/zoom + 40/zoom * (i-1), 16/zoom, 16/zoom, "files/images/remove.png", 0, 0, 0, tocolor(255, 255, 255, 255 * self.alpha))
                else
                    dxDrawImage(guiData.rent.x + guiData.rent.w - 30/zoom, guiData.rent.y + 52/zoom + 40/zoom * (i-1), 16/zoom, 16/zoom, "files/images/remove.png", 0, 0, 0, tocolor(200, 200, 200, 255 * self.alpha))
                end
            end
        end
    end
end

function Equipment:click(...)
    if exports.TR_dx:isResponseEnabled() then return end
    if not self.loaded then return end
    if GUI.egg then return end
    if arg[1] == "left" and arg[2] == "down" then
        if self.selectedItem and self.avaliableOptions then
            for i, v in ipairs(self.avaliableOptions) do
                if self:isMouseInPosition(self.optionsCursor.x, self.optionsCursor.y + 30/zoom * i, 200/zoom, 30/zoom) then
                    self:useItemOption(v)
                    break
                end
            end
        elseif not self.blockHover then
            for i, v in ipairs(guiData.categories) do
                if self:isMouseInPosition(guiData.x + guiData.w - 67/zoom, guiData.y + 5/zoom + (i - 1) * 56/zoom, 62/zoom, 50/zoom) then
                    self:setCategory(v)
                    break
                end
            end

        elseif self.rentData then
            local index = self:getItemIndexByID(self.selectedItem)
            if not index then return end
            local item = self.items[self.selectedCategory][index]

            for i, v in pairs(self.rentData.rent) do
                if self:isMouseInPosition(guiData.rent.x + guiData.rent.w - 30/zoom, guiData.rent.y + 52/zoom + 40/zoom * (i-1), 16/zoom, 16/zoom) then
                    table.remove(self.rentData.rent, i)
                    item.rent = self.rentData.rent

                    if item.variant == 0 then
                        triggerServerEvent("updateRentData", resourceRoot, "veh", item.vehID, v.UID)
                        self.rentData.info = string.format("Gracz %s został pomyślnie usunięty.", v.username)
                    else
                        triggerServerEvent("updateRentData", resourceRoot, "house", item.houseID, v.UID)
                        self.rentData.info = string.format("Gracz %s został pomyślnie usunięty.", v.username)
                    end
                    exports.TR_dx:setResponseEnabled(true)
                    break
                end
            end
        end

    elseif arg[1] == "right" and arg[2] == "down" and not self.selectedItem and not self.blockHover then
        for i = 1, 5 do
            local item = self.selectedItems[i + self.scroll]
            if item then
                if self:isMouseInPosition(guiData.x, guiData.y + 40/zoom + (i - 1) * 60/zoom, guiData.w - 75/zoom, 50/zoom, tocolor(27, 27, 27, 255 * self.alpha)) then
                    self.optionsCursor = Vector2(getCursorPosition())
                    self.optionsCursor.x = self.optionsCursor.x * sx
                    self.optionsCursor.y = self.optionsCursor.y * sy
                    self.optionsCursor.x = self.optionsCursor.x + 200/zoom > sx and sx - 200/zoom or self.optionsCursor.x
                    self:selectItem(item)
                    break
                end
            end
        end
    end
end



function Equipment:updateItems(data, vehicles, houses, open)
    self.items = {}
    self.details = {
        total = {
            weight = 0,
            count = 0,
        },
    }

    for i, v in pairs(guiData.categories) do
        self.details[v] = {
            weight = 0,
            count = 0,
        }
    end

    self:addPersonalItems()

    for i, v in ipairs(data) do
        local category = self:getCategory(v)
        self:addItem(category, v)
    end

    for i, v in ipairs(vehicles) do
        -- id, category, type, variant, variant2)
        self:addCustomItem("veh"..v.ID, "keys", 4, 0, 0, {vehModel = v.model, vehID = v.ID, rent = v.rent})
    end

    for i, v in ipairs(houses) do
        self:addCustomItem("house"..v.ID, "keys", 4, 1, 0, {houseID = v.ID, housePos = v.pos, rent = v.rent})
    end

    if open then
        self:setCategory("favourite")
    else
        self.selectedItems = self.items[self.selectedCategory] or {}
    end

    self.lastSync = getTickCount()
    self.loaded = true

    self:updateWeight()
end

function Equipment:addPersonalItems()
    local plrData = getElementData(localPlayer, "characterData")
    local uid = getElementData(localPlayer, "characterUID")

    self:addCustomItem("personalID", "other", 5, 0, 0, {account = plrData.premium and string.gsub(plrData.premium, "%a", string.upper, 1) or "Standard"})
    if plrData.licence then
        local licences, count = "", 0
        for i, _ in pairs(plrData.licence) do
            if string.lower(i) == "a" or string.lower(i) == "b" or string.lower(i) == "c" then
                licences = string.format("%s %s, ", licences, string.upper(i))
                count = count + 1
            end
        end
        if count > 0 then self:addCustomItem("licence", "other", 5, 1, 0, {licences = string.sub(licences, 1, -3)}) end
        if plrData.licence["WATER"] then self:addCustomItem("licence", "other", 5, 1, 1) end
        if plrData.licence["BOAT"] then self:addCustomItem("licence", "other", 5, 1, 2) end
    end
    if plrData.bankcode then self:addCustomItem("creditCard", "other", 5, 2, 0, {pinCode = plrData.bankcode}) end

    local number = string.format("55%05d", uid)
    self:addCustomItem("phone", "other", 5, 3, 0, {number = string.format("%s-%s", string.sub(number, 0, 3), string.sub(number, 4, -1))})
end

function Equipment:addItem(category, item)
    if not self.items[category] then self.items[category] = {} end
    local details = self:getItemDetailsTable(item)

    local isRod = string.find(details.name, "Wędka") and true or false
    if isRod and category ~= "favourite" then category = "other" end

    table.insert(self.items[category], {
        ID = item.ID,
        name = details.name,
        description = details.description,
        icon = string.format("files/images/items/%s.png", details.icon),
        type = item.type,
        value = self:getItemValue(item),
        value2 = tonumber(item.value2),
        variant = item.variant,
        variant2 = item.variant2,
        durability = tonumber(item.durability),
        canRemove = not details.blockRemove,
        used = self:isItemUsed(item),
        stackable = details.stackable,
    })
end

function Equipment:addCustomItem(id, category, type, variant, variant2, customData)
    if not self.items[category] then self.items[category] = {} end

    local item = {
        name = name,
        description = description,
        type = type,
        variant = variant,
        variant2 = variant2,
    }

    local details = self:getItemDetailsTable(item)
    table.insert(self.items[category], {
        ID = id,
        name = details.name,
        description = details.description,
        icon = string.format("files/images/items/%s.png", details.icon),
        type = item.type,
        variant = item.variant,
        variant2 = item.variant2,
        canRemove = false,
    })

    if customData then
        for i, v in pairs(customData) do
            self.items[category][#self.items[category]][i] = v
        end
    end
end

function Equipment:updateWeight()
    self.details = {
        total = {
            count = 0,
            weight = 0,
        },
    }

    for i, category in pairs(guiData.categories) do
        self.details[category] = {
            count = 0,
            weight = 0,
        }
    end

    for i, category in pairs(guiData.categories) do
        if self.items[category] then
            for _, item in pairs(self.items[category]) do
                local details = self:getItemDetailsTable(item)

                self.details[category].count = self.details[category].count + 1
                self.details[category].weight = self.details[category].weight + (details.weight and details.weight/1000 or 0) * (item.value2 or 1)
                self.details.total.count = self.details.total.count + 1
                self.details.total.weight = self.details.total.weight + (details.weight and details.weight/1000 or 0) * (item.value2 or 1)
            end
        end
    end
end

function Equipment:getItemValue(item)
    local value = item.value

    for i, v in ipairs(itemDetails) do
        if item.type == v.type and item.variant == v.variant and item.variant2 == v.variant2 then
            if item.type == itemTypes.food then
                for _, prev in pairs(v.preview) do
                    if prev.title == "Leczy" then
                        value = tonumber(string.sub(prev.value, 1, string.len(prev.value) - 1))
                        break
                    end
                end

            elseif item.type == itemTypes.alcohol then
                for _, prev in pairs(v.preview) do
                    if prev.title == "Stężenie alkoholu" then
                        value = tonumber(string.sub(prev.value, 1, string.len(prev.value) - 1))
                        break
                    end
                end
            elseif v.value then
                value = v.value
            end
            break
        end
    end

    return value
end


function Equipment:getItemDetails(item)
    local name, description, icon, canRemove = "Nieznany przedmiot", "Nikt nie jest pewny co to jest i skąd sie tutaj wzięło.", "unknown", true

    for i, v in ipairs(itemDetails) do
        if item.type == v.type and item.variant == v.variant and item.variant2 == v.variant2 then
            return v.name, v.description, string.format("files/images/items/%s.png", v.icon or "unknown"), not v.blockRemove
        end
    end

    return name, description, string.format("files/images/items/%s.png", icon), canRemove
end

function Equipment:getItemDetailsTable(item)
    for i, v in ipairs(itemDetails) do
        if item.type == v.type and item.variant == v.variant and item.variant2 == v.variant2 then
            return v
        end
    end
    return false
end

function Equipment:getItemPreviewData(item)
    local preview = {}

    for i, v in ipairs(itemDetails) do
        if item.type == v.type and item.variant == v.variant and item.variant2 == v.variant2 then
            preview = v.preview or {}
            break
        end
    end

    return preview
end

function Equipment:setCategory(category)
    self.selectedCategory = category
    self.scroll = 0
    self.selectedItems = self.items[category] or {}

    self.selectedItem = nil
end

function Equipment:getCategory(item)
    if item.favourite then
        return "favourite"

    elseif itemCategories[item.type] then
        return itemCategories[item.type]
    end
    return "other"
end

function Equipment:selectItem(item)
    self.selectedItem = item.ID
    local details = self:getItemDetailsTable(item)

    self.avaliableOptions = {}
    if self.tradeOpened then
        if not self.tradeBlock and not item.used and not details.blockTrade then
            if not item.isTrade then
                table.insert(self.avaliableOptions, {text = "Zaoferuj przedmiot", type = "trade", icon = "files/images/trade.png"})
            else
                table.insert(self.avaliableOptions, {text = "Cofnij przedmiot", type = "trade", icon = "files/images/trade.png"})
            end
        end
    elseif GUI.trunk then
        if not details.blockTrade then
            table.insert(self.avaliableOptions, {text = "Przenieś do schowka", type = "insertStash", icon = "files/images/insert.png"})
        end

    else
        if item.type == itemTypes.boombox then
            if getElementData(localPlayer, "boombox") then
                table.insert(self.avaliableOptions, {text = "Zmień utwór", type = "changeBoomboxSound", icon = "files/images/use.png"})
                table.insert(self.avaliableOptions, {text = "Schowaj boombox", type = "pickupBoombox", icon = "files/images/use.png"})
            else
                table.insert(self.avaliableOptions, {text = "Weź do ręki", type = "takeBoomboxToHand", icon = "files/images/use.png"})
                table.insert(self.avaliableOptions, {text = "Połóż na ziemi", type = "setBoomboxOnGround", icon = "files/images/use.png"})
            end
            if self.selectedCategory ~= "favourite" then
                table.insert(self.avaliableOptions, {text = "Dodaj do ulubionych", type = "favourite", icon = "files/images/categories/favourite.png"})
            else
                table.insert(self.avaliableOptions, {text = "Usuń z ulubionych", type = "favourite", icon = "files/images/categories/favourite.png"})
            end

        else
            if item.type ~= itemTypes.keys and item.type ~= itemTypes.documents and item.type ~= itemTypes.ammo and not details.blockUse then
                table.insert(self.avaliableOptions, {text = "Użyj", type = "use", icon = "files/images/use.png"})
            end
            if item.type ~= itemTypes.keys and item.type ~= itemTypes.documents and not details.blockFavourite then
                if self.selectedCategory ~= "favourite" then
                    table.insert(self.avaliableOptions, {text = "Dodaj do ulubionych", type = "favourite", icon = "files/images/categories/favourite.png"})
                else
                    table.insert(self.avaliableOptions, {text = "Usuń z ulubionych", type = "favourite", icon = "files/images/categories/favourite.png"})
                end
            end
            if details.stackable then
                table.insert(self.avaliableOptions, {text = "Połącz przedmioty", type = "mergeItems", icon = "files/images/merge.png"})
                table.insert(self.avaliableOptions, {text = "Rozdziel przedmioty", type = "splitItems", icon = "files/images/split.png"})
            end

            if item.canRemove and not details.blockRemove then table.insert(self.avaliableOptions, {text = "Usuń", type = "remove", icon = "files/images/remove.png"}) end
            if item.type == itemTypes.keys then table.insert(self.avaliableOptions, {text = "Udostępnij klucze", type = "rent", icon = "files/images/rent.png"}) end
        end
    end
    table.insert(self.avaliableOptions, {text = "Anuluj", type = "cancel", icon = "files/images/cancel.png"})
end

function Equipment:reselectItem()
    if not self.selectedItem then return end
    if not self.avaliableOptions then return end
    local index = self:getItemIndexByID(self.selectedItem)
    if not index then return end

    local item = self.items[self.selectedCategory][index]
    if not item then return end
    self:selectItem(item)
end

function Equipment:openItemSpliting(item)
    self.splitingItem = item

    self.buttons = {}
    self.buttons.acceptSplit = exports.TR_dx:createButton(guiData.split.x + (guiData.split.w - 250/zoom)/2, guiData.split.y + guiData.split.h - 100/zoom, 250/zoom, 40/zoom, "Podziel przedmioty", "green")
    self.buttons.cancelSplit = exports.TR_dx:createButton(guiData.split.x + (guiData.split.w - 250/zoom)/2, guiData.split.y + guiData.split.h - 50/zoom, 250/zoom, 40/zoom, "Anuluj", "red")

    self.edits = {}
    self.edits.splitting = exports.TR_dx:createEdit(guiData.split.x + (guiData.split.w - 250/zoom)/2, guiData.split.y + 60/zoom, 250/zoom, 40/zoom, "Ilość przedmiotów")

    self.blockHover = true
    self.optionsCursor = nil
    self.avaliableOptions = nil
    self.btnHandler = true
    addEventHandler("guiButtonClick", root, self.func.btnClicker)
end

function Equipment:useItemOption(option)
    if option.type == "cancel" then
        self.selectedItem = nil
        self.optionsCursor = nil
        self.avaliableOptions = nil

    elseif option.type == "use" then
        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]
        if not self:canUseItem(item) then return end

        local isRod = string.find(item.name, "Wędka")
        if isRod then
            exports.TR_fishing:setFishBait(nil, nil)

        elseif item.type == itemTypes.food then
            self.animatingItem = item
            table.remove(self.items[self.selectedCategory], index)
            self:checkScroll()

        elseif item.type == itemTypes.weapon then
            if item.used then
                setElementData(localPlayer, "weapon:used", false)
            else
                setElementData(localPlayer, "weapon:used", true)
            end
        elseif item.type == itemTypes.cigarettes then
            item.value = item.value - 1
            if item.value == 0 then
                table.remove(self.items[self.selectedCategory], index)
                self:checkScroll()
            end
            triggerEvent("startSmoking", resourceRoot, 1)
            self.blockGui = true
            self:close()

        elseif item.type == itemTypes.autograph then
            self.animatingItem = item
            item.value = item.value - 1
            if item.value == 0 then
                table.remove(self.items[self.selectedCategory], index)
                self:checkScroll()
            end

        elseif item.type == itemTypes.spray then
            local graffiti = exports.TR_gangs:getNearestGraffiti()
            if not graffiti then exports.TR_noti:create("Nie stoisz blisko żadnego graffiti.", "error") return end

            local orgType = getElementData(localPlayer, "characterOrgType")
            if orgType ~= "crime" then exports.TR_noti:create("Spraya możesz użyć tylko jeśli jesteś w organizacji przestępczej.", "error") return end

            exports.TR_dx:setResponseEnabled(false)
            triggerServerEvent("useSpayItem", resourceRoot, graffiti, item.ID)
            return

        elseif item.type == itemTypes.joints then
            triggerEvent("startSmoking", resourceRoot, 2, item.value or 1)
            table.remove(self.items[self.selectedCategory], index)

            exports.TR_features:updateState("pills", 10 * (item.value or 1))

            exports.TR_achievements:addAchievements("firstWeed")

            self.blockGui = true
            self:checkScroll()
            self:close()

            local details = self:getItemDetailsTable(item)
            if details.fakeItem then return end

        elseif item.type == itemTypes.alcohol then
            exports.TR_shaders:setScreenEsotropia(true, tonumber(item.value)/100, 600)
            table.remove(self.items[self.selectedCategory], index)
            exports.TR_noti:create(string.format("Wypiłeś %s.", item.name), "success")

            exports.TR_features:updateState("cheers", item.value/5)

            self:checkScroll()

        elseif item.type == itemTypes.armorplate then
            local armor = getPlayerArmor(localPlayer)
            if armor < 1 or armor == 100 then return end

            for i, v in pairs(self.items[self.selectedCategory]) do
                if v.type == itemTypes.armor and v.used then
                    v.value = math.min(v.value + 50, 100)
                    break
                end
            end

            table.remove(self.items[self.selectedCategory], index)
            self:checkScroll()

        elseif item.type == itemTypes.fishingbait then
            if not item.used then
                item.value = item.value - 1
                if item.value <= 0 then
                    table.remove(self.items[self.selectedCategory], index)
                    self:checkScroll()
                end

                exports.TR_fishing:setFishBait(item.name, item.ID)
            end

        elseif item.type == itemTypes.premium then
            table.remove(self.items[self.selectedCategory], index)

        elseif item.type == itemTypes.drugs then
            if item.variant == 1 then
                exports.TR_shaders:setHeroinEffect(true, (item.value or 1) * tonumber(item.value2), 300 * tonumber(item.value2))

            elseif item.variant == 2 then
                exports.TR_shaders:setCrackEffect(true, (item.value or 1) * tonumber(item.value2), 300 * tonumber(item.value2))

            elseif item.variant == 3 then
                exports.TR_shaders:setXanaxEffect(true, (item.value or 1) * tonumber(item.value2), 300 * tonumber(item.value2))
            end
            exports.TR_features:updateState("pills", 6)
            table.remove(self.items[self.selectedCategory], index)

        elseif item.type == itemTypes.gift then
            table.remove(self.items[self.selectedCategory], index)

        elseif item.type == itemTypes.paperSheet then
            local drugItemID = false
            for _, category in pairs(self.items) do
                for i, v in pairs(category) do
                    if v.type == itemTypes.drugs then
                        if v.variant == item.variant and v.variant2 == item.variant2 then
                            drugItemID = v.ID
                            break
                        end
                    end
                end
            end
            if not drugItemID then
                exports.TR_noti:create("W twoim ekwipunku nie znajduje się odpowiedni narkotyk.", "error")
                self.selectedItem = nil
                self.optionsCursor = nil
                self.avaliableOptions = nil
                return
            end

            item.value = item.value - 1
            if item.value <= 0 then
                table.remove(self.items[self.selectedCategory], index)
            end
            triggerServerEvent("removeItem", resourceRoot, drugItemID, true)
        end

        exports.TR_dx:setResponseEnabled(true)
        triggerServerEvent("useItem", resourceRoot, item.ID, not item.used, item.type, item.value, item.variant, item.variant2)
        self:updateWeight()

    elseif option.type == "favourite" then
        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]
        local category = self.selectedCategory ~= "favourite" and "favourite" or self:getCategory(item)

        table.remove(self.items[self.selectedCategory], index)
        self:addItem(category, item)

        triggerServerEvent("setItemFavourite", resourceRoot, item.ID, self.selectedCategory ~= "favourite" and true or false)
        exports.TR_dx:setResponseEnabled(true)
        self:updateWeight()


    elseif option.type == "mergeItems" then
        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]

        local changed = false
        local itemCount = item.value2
        local toRemove = {}
        for category, _ in pairs(self.items) do
            local rem = 0
            toRemove[category] = {}
            for i, v in pairs(self.items[category]) do
                if v.type == item.type and v.variant == item.variant and v.variant2 == item.variant2 and v.ID ~= item.ID then
                    itemCount = itemCount + v.value2
                    table.insert(toRemove[category], i - rem)
                    rem = rem + 1
                    changed = true
                end
            end
        end
        if not changed then
            self.selectedItem = nil
            self.optionsCursor = nil
            self.avaliableOptions = nil

            exports.TR_noti:create("Przedmioty zostały już połączone.", "info")
            return
        end

        item.value2 = itemCount
        for category, _ in pairs(toRemove) do
            for i, v in pairs(toRemove[category]) do
                table.remove(self.items[category], v)
            end
        end

        self.selectedItem = nil
        self.optionsCursor = nil
        self.avaliableOptions = nil

        triggerServerEvent("mergeItems", resourceRoot, item.ID, item.type, item.variant, item.variant2)
        exports.TR_dx:setResponseEnabled(true)
        self:updateWeight()

    elseif option.type == "splitItems" then
        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]
        local category = self.selectedCategory ~= "favourite" and "favourite" or self:getCategory(item)

        self:openItemSpliting(item)
        -- triggerServerEvent("splitItems", resourceRoot, item.ID, item.type, item.variant, item.variant2)
        -- exports.TR_dx:setResponseEnabled(true)
        -- self:updateWeight()


    elseif option.type == "remove" then
        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        self.buttons = {}
        self.buttons.accept = exports.TR_dx:createButton(guiData.accept.x + guiData.accept.w - 210/zoom, guiData.accept.y + guiData.accept.h - 50/zoom, 200/zoom, 40/zoom, "Akceptuj")
        self.buttons.decline = exports.TR_dx:createButton(guiData.accept.x + 10/zoom, guiData.accept.y + guiData.accept.h - 50/zoom, 200/zoom, 40/zoom, "Anuluj")

        self.acceptDetails = {
            title = "Usuwanie przedmiotu",
            description = "Czy jesteś pewny, że chcesz usunąć ten przedmiot? \n#b89935Ta operacja jest nieodwracalna.",
            type = "destroy",
        }
        self.blockHover = true
        self.optionsCursor = nil
        self.avaliableOptions = nil
        self.btnHandler = true
        addEventHandler("guiButtonClick", root, self.func.btnClicker)

    elseif option.type == "preview" then
        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]
        self:setItemPreviev(item, previewCount)

    elseif option.type == "trade" then
        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]
        GUI.trade:addItem(localPlayer, item)

        self.selectedItem = nil
        self.optionsCursor = nil
        self.avaliableOptions = nil

    elseif option.type == "insertStash" then
        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]
        if item.used then exports.TR_noti:create("Nie możesz schować wyekwipowanych przedmiotów.", "error") return end
        GUI.trunk:addItem(item)

        self.selectedItem = nil
        self.optionsCursor = nil
        self.avaliableOptions = nil

    elseif option.type == "rent" then
        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]

        self.buttons = {}
        self.buttons.rentAdd = exports.TR_dx:createButton(guiData.rent.x + 260/zoom, guiData.rent.y + guiData.rent.h - 100/zoom, 130/zoom, 40/zoom, "Dodaj", "green")
        self.buttons.rentClose = exports.TR_dx:createButton(guiData.rent.x + (guiData.rent.w - 250/zoom)/2, guiData.rent.y + guiData.rent.h - 50/zoom, 250/zoom, 40/zoom, "Zamknij", "red")

        self.edits = {}
        self.edits.rent = exports.TR_dx:createEdit(guiData.rent.x + 10/zoom, guiData.rent.y + guiData.rent.h - 100/zoom, 240/zoom, 40/zoom, "Wpisz nick")

        self.rentData = {
            title = item.variant == 0 and "Pojazd udostępniony" or "Posiadłość udostępniona",
            rent = "loading",
        }
        self.blockHover = true
        self.optionsCursor = nil
        self.avaliableOptions = nil
        self.btnHandler = true
        addEventHandler("guiButtonClick", root, self.func.btnClicker)

        exports.TR_dx:setResponseEnabled(true)
        if item.variant == 0 then
            triggerServerEvent("getRentKeysTable", resourceRoot, "vehicle", item.vehID)
        else
            triggerServerEvent("getRentKeysTable", resourceRoot, "house", item.houseID)
        end

    elseif option.type == "pickupBoombox" then
        triggerServerEvent("destroyPlayerBoombox", resourceRoot)

        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]
        item.used = false

        self.selectedItem = nil
        self.optionsCursor = nil
        self.avaliableOptions = nil


    elseif option.type == "changeBoomboxSound" then
        self.blockHover = true
        self.optionsCursor = nil
        self.avaliableOptions = nil

        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]
        self.boombox = Boombox:create("change", item.ID)

    elseif option.type == "takeBoomboxToHand" then
        if getPedOccupiedVehicle(localPlayer) then exports.TR_noti:create("Nie możesz korzystać z boomboxa w pojeździe.", "error") return end

        self.blockHover = true
        self.optionsCursor = nil
        self.avaliableOptions = nil

        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]
        self.boombox = Boombox:create("hand", item.ID)

    elseif option.type == "setBoomboxOnGround" then
        if getPedOccupiedVehicle(localPlayer) then exports.TR_noti:create("Nie możesz korzystać z boomboxa w pojeździe.", "error") return end

        self.blockHover = true
        self.optionsCursor = nil
        self.avaliableOptions = nil

        local index = self:getItemIndexByID(self.selectedItem)
        if not index then return end

        local item = self.items[self.selectedCategory][index]
        self.boombox = Boombox:create("ground", item.ID)
    end
end

function Equipment:clickAccept(btn)
    if btn == self.buttons.accept then
        if self.acceptDetails.type == "destroy" then
            local index = self:getItemIndexByID(self.selectedItem)

            if self.items[self.selectedCategory][index].used then exports.TR_noti:create("Nie możesz usunąć przedmiotu, który jest w trakcie używania.", "error") return end
            triggerServerEvent("removeItem", resourceRoot, self.items[self.selectedCategory][index].ID)
            table.remove(self.items[self.selectedCategory], index)

            self:updateWeight()
        end

        self.selectedItem = nil
        self.acceptDetails = nil
        self.blockHover = nil
        exports.TR_dx:destroyButton(self.buttons)
        self.buttons = nil
        self.btnHandler = nil
        removeEventHandler("guiButtonClick", root, self.func.btnClicker)

    elseif btn == self.buttons.decline then
        self.selectedItem = nil
        self.acceptDetails = nil
        self.blockHover = nil
        exports.TR_dx:destroyButton(self.buttons)
        self.buttons = nil
        self.btnHandler = nil
        removeEventHandler("guiButtonClick", root, self.func.btnClicker)

    elseif btn == self.buttons.preview then
        self.selectedItem = nil
        self.previewData = nil
        self.blockHover = nil
        exports.TR_dx:destroyButton(self.buttons)
        self.buttons = nil
        self.btnHandler = nil
        removeEventHandler("guiButtonClick", root, self.func.btnClicker)

    elseif btn == self.buttons.rentAdd then
        local name = guiGetText(self.edits.rent)
        if not name or string.len(name) < 1 then return end
        local target = getPlayerFromName(name)
        if target == localPlayer then exports.TR_noti:create("Nie możesz dodać samego siebie.", "error") return end
        if not target then exports.TR_noti:create("Podany gracz nie został znaleziony.", "error") return end
        if #self.rentData.rent >= 6 then exports.TR_noti:create("Nie można dodać więcej graczy, z powodu osiągnięcia limitu.", "error") return end

        local index = self:getItemIndexByID(self.selectedItem)
        local item = self.items[self.selectedCategory][index]

        if self.rentData.rent then
            for i, v in pairs(self.rentData.rent) do
                if v.username == name then
                    return exports.TR_noti:create("Podany gracz posiada już klucze.", "error")
                end
            end
        end

        local targetUID = getElementData(target, "characterUID")
        table.insert(self.rentData.rent, {ID = false, UID = targetUID, username = getPlayerName(target)})
        item.rent = self.rentData.rent

        if item.variant == 0 then
            triggerServerEvent("updateRentData", resourceRoot, "veh", item.vehID, targetUID, true)
            self.rentData.info = string.format("Gracz %s został pomyślnie dodany.", getPlayerName(target))
        else
            triggerServerEvent("updateRentData", resourceRoot, "house", item.houseID, targetUID, true)
            self.rentData.info = string.format("Gracz %s został pomyślnie dodany.", getPlayerName(target))
        end
        exports.TR_dx:setResponseEnabled(true)


    elseif btn == self.buttons.rentClose then
        self.rentData = nil
        self.selectedItem = nil
        self.blockHover = nil
        exports.TR_dx:destroyButton(self.buttons)
        exports.TR_dx:destroyEdit(self.edits)
        self.buttons = nil
        self.edits = nil
        self.btnHandler = nil
        removeEventHandler("guiButtonClick", root, self.func.btnClicker)

    elseif btn == self.buttons.cancelSplit then
        self.splitingItem = nil
        self.blockHover = nil
        self.optionsCursor = nil
        self.avaliableOptions = nil
        self.selectedItem = nil

        exports.TR_dx:destroyButton(self.buttons)
        exports.TR_dx:destroyEdit(self.edits)
        self.buttons = nil
        self.edits = nil
        self.btnHandler = nil
        removeEventHandler("guiButtonClick", root, self.func.btnClicker)

    elseif btn == self.buttons.acceptSplit then
        local text = guiGetText(self.edits.splitting)
        if not text then exports.TR_noti:create("Wpisana liczba jest niepoprawna.", "error") return end
        if string.len(text) < 1 then exports.TR_noti:create("Wpisana liczba jest niepoprawna.", "error") return end
        if tonumber(text) == nil then exports.TR_noti:create("Wpisana liczba jest niepoprawna.", "error") return end
        if tonumber(text) < 1 then exports.TR_noti:create("Wpisana liczba jest niepoprawna.", "error") return end
        if tonumber(text) >= tonumber(self.splitingItem.value2) then exports.TR_noti:create("Wpisana liczba jest niepoprawna.", "error") return end

        exports.TR_dx:setResponseEnabled(true)
        triggerServerEvent("splitItems", resourceRoot, self.splitingItem.ID, tonumber(text))

        self.splitingItem = nil
        self.blockHover = nil
        self.optionsCursor = nil
        self.avaliableOptions = nil
        self.selectedItem = nil

        exports.TR_dx:destroyButton(self.buttons)
        exports.TR_dx:destroyEdit(self.edits)
        self.buttons = nil
        self.edits = nil
        self.btnHandler = nil
        removeEventHandler("guiButtonClick", root, self.func.btnClicker)
    end
end



function Equipment:canUseItem(item)
    if getElementData(localPlayer, "isOnEvent") then exports.TR_noti:create("Nie możesz używać ekwipunku podczas trwania eventu.", "info") return false end

    if item.type == itemTypes.food then
        if getElementHealth(localPlayer) >= 100 then
            exports.TR_noti:create("Nie jesteś zraniony więc nie możesz użyć tego przedmiotu.", "info")
            return false
        end

    elseif item.type == itemTypes.cigarettes or item.type == itemTypes.joints then
        if getPedOccupiedVehicle(localPlayer) then
            exports.TR_noti:create("Nie możesz zapalić papierosa w pojeździe.", "error")
            return false
        end

    elseif item.type == itemTypes.weapon then
        if item.used then
            return true
        end

        local job = exports.TR_jobs:getPlayerJob()
        if job then
            if string.find(job, "fraction_") then
                exports.TR_noti:create("Nie możesz wyekwipować tego przedmiotu podczas służby frakcyjnej.", "error")
                return false
            end
        end

        local weapons = getElementData(localPlayer, "weapons") or {}
        for i, v in pairs(weapons) do
            if weaponSlots[tonumber(v)] == item.variant then
                exports.TR_noti:create("Nie możesz wyekwipować tej broni, ponieważ nosisz już jedną broń na tym slocie.", "error", 5)
                return false
            end
        end

    elseif item.type == itemTypes.fishingbait then
        if item.used then return true end
        if not exports.TR_fishing:canChangeBait() then
            exports.TR_noti:create("Nie możesz założyć przynęty na haczyk.", "error")
            return false
        end

        local selectedBait = false
        for category, _ in pairs(self.items) do
            for i, v in pairs(self.items[category]) do
                if v.type == itemTypes.fishingbait and v.used then
                    selectedBait = v
                end
            end
        end

        if selectedBait then
            exports.TR_noti:create("Masz już wybraną jedną przynęte.", "error")
            return
        end

        local fishingRod = false
        for category, _ in pairs(self.items) do
            for i, v in pairs(self.items[category]) do
                local isRod = string.find(v.name, "Wędka")
                if isRod and v.used then
                    fishingRod = v
                    break
                end
            end
        end
        if not fishingRod then
            exports.TR_noti:create("Nie masz wyekwipowanej żadnej wędki.", "error")
            self.selectedItem = nil
            self.optionsCursor = nil
            self.avaliableOptions = nil
            return false
        end

        local fishingRodLvl = fishingRod.variant2 - 3
        if item.name == "Pęczak" then
            if fishingRodLvl < 3 then exports.TR_noti:create("Twoja wędka ma zbyt niski poziom na tę przynęte.", "error") return false end

        elseif item.name == "Robaki białe" then
            if fishingRodLvl < 5 then exports.TR_noti:create("Twoja wędka ma zbyt niski poziom na tę przynęte.", "error") return false end

        elseif item.name == "Robaki czerwone" then
            if fishingRodLvl < 7 then exports.TR_noti:create("Twoja wędka ma zbyt niski poziom na tę przynęte.", "error") return false end

        elseif item.name == "Żywe ryby" then
            if fishingRodLvl < 9 then exports.TR_noti:create("Twoja wędka ma zbyt niski poziom na tę przynęte.", "error") return false end
        end
    end
    return true
end

function Equipment:response()
    if self.animatingItem then
        exports.TR_dx:setResponseEnabled(true, "Trwa używanie przedmiotu")

        if self.animatingItem.type == 16 then
            setPedAnimation(localPlayer, "BOMBER", "BOM_Plant")
            setElementData(localPlayer, "animation", {"BOMBER", "BOM_Plant"})

        elseif self.animatingItem.variant == 1 then
            setPedAnimation(localPlayer, "VENDING", "VEND_Drink2_P")
            setElementData(localPlayer, "animation", {"VENDING", "VEND_Drink2_P"})
        else
            setPedAnimation(localPlayer, "food", "EAT_Burger")
            setElementData(localPlayer, "animation", {"food", "EAT_Burger"})
        end

        setTimer(function()
            setPedAnimation(localPlayer, nil)
            setElementData(localPlayer, "animation", nil)
            exports.TR_dx:setResponseEnabled(false)

            if self.animatingItem.type == 16 then
                exports.TR_noti:create(string.format("%s wystarczyła by opatrzeć twoje rany.", self.animatingItem.name), "success")

            elseif self.animatingItem.variant == 1 then
                exports.TR_noti:create(string.format("Wypiłeś %s.", self.animatingItem.name), "success")

                if self.animatingItem.variant ~= 5 then
                    if self.animatingItem.value > 5 then
                        exports.TR_features:updateState("fat", math.ceil(self.animatingItem.value/5 or 1))
                    end
                end

            else
                exports.TR_noti:create(string.format("Spożyłeś %s.", self.animatingItem.name), "success")

                if self.animatingItem.variant ~= 5 then
                    if self.animatingItem.value > 5 then
                        exports.TR_features:updateState("fat", math.ceil(self.animatingItem.value/5 or 1))
                    end
                end
            end

            self.animatingItem = nil
        end, 5000, 1)

    else
        exports.TR_dx:setResponseEnabled(false)
    end

    self.selectedItem = nil
    self.optionsCursor = nil
    self.avaliableOptions = nil
end

function Equipment:rentResponse()
    exports.TR_dx:setResponseEnabled(false)
    if self.rentData.info then exports.TR_noti:create(self.rentData.info, "success") end
end

function Equipment:spraySuccessResponse()
    local index = self:getItemIndexByID(self.selectedItem)
    if not index then return end

    local item = self.items[self.selectedCategory][index]
    local category = self.selectedCategory ~= "favourite" and "favourite" or self:getCategory(item)

    table.remove(self.items[self.selectedCategory], index)

    self.selectedItem = nil
    self.optionsCursor = nil
    self.avaliableOptions = nil
    exports.TR_dx:setResponseEnabled(false)
end

function Equipment:isItemUsed(item)
    if item.type == itemTypes.boombox then
        local boombox = getElementData(localPlayer, "boombox")
        if boombox then
            if tonumber(boombox.itemID) == tonumber(item.ID) then
                return true
            end
        end
    end
    return item.used
end

function Equipment:isOpened()
    return self.state ~= "closed" and true or false
end

function Equipment:setTradeOpen(value)
    self.tradeOpened = value

    if not value then
        for i, _ in pairs(self.items) do
            for _, v in ipairs(self.items[i]) do
                v.isTrade = nil
            end
        end
    end
end

function Equipment:updatePlayerKeysTable(...)
    self.rentData.rent = arg[1]
    exports.TR_dx:setResponseEnabled(false)
end

function Equipment:setTradeBlock(value)
    self.tradeBlock = value
end

function Equipment:setItemUsed()
    local index = self:getItemIndexByID(self.selectedItem)
    if not index then return end

    local item = self.items[self.selectedCategory][index]
    item.used = not self:isItemUsed(item)
end

function Equipment:getItemIndexByID(id)
    for i, v in pairs(self.items[self.selectedCategory]) do
        if v.ID == id then
            return i
        end
    end
    return false
end

function Equipment:setItemPreviev(item)
    if self.blockHover then return end
    local details = self:getItemDetailsTable(item)
    if details.blockDesc then
        self.previewData = {
            name = item.name,
            weight = details.weight and details.weight * (item.value2 or 1) or 0,
            blockDesc = true,
            value2 = item.value2,
        }

        guiData.preview.h = 52/zoom + 2 * 20/zoom + 20/zoom
        guiData.preview.y = (sy - guiData.preview.h)/2

        guiData.preview.w = dxGetTextWidth(string.format("Przedmiot: %s", self.previewData.name), 1/zoom, self.fonts.preview) + 12/zoom
        local width = dxGetTextWidth("Szczegółowe informacje", 1/zoom, self.fonts.optionsName) + 40/zoom
        if width > guiData.preview.w then
            guiData.preview.w = width
        end
        return
    end

    local previewData = self:getItemPreviewData(item)
    local previewCount = #previewData

    if item.type == itemTypes.keys then
        if item.variant == 0 then
            self.previewData = {
                name = item.name,
                data = {
                    {
                        title = "ID pojazdu",
                        value = item.vehID,
                    },
                    {
                        title = "Pojazd",
                        value = self:getVehicleName(item.vehModel),
                    },
                },
            }
        elseif item.variant == 1 then
            local pos = split(item.housePos, ",")
            self.previewData = {
                name = item.name,
                data = {
                    {
                        title = "ID posiadłości",
                        value = item.houseID,
                    },
                    {
                        title = "Lokalizacja",
                        value = getZoneName(tonumber(pos[1]), tonumber(pos[2]), tonumber(pos[3])),
                    },
                },
            }
        end
        previewCount = 2

    elseif item.type == itemTypes.documents then
        if item.variant == 0 then
            self.previewData = {
                name = item.name,
                data = {
                    {
                        title = "UID gracza",
                        value = getElementData(localPlayer, "characterUID"),
                    },
                    {
                        title = "Właściciel",
                        value = getPlayerName(localPlayer),
                    },
                    {
                        title = "Typ konta",
                        value = item.account,
                    },
                },
            }
            previewCount = 3

        elseif item.variant == 1 and item.variant2 == 0 then
            self.previewData = {
                name = item.name,
                data = {
                    {
                        title = "Posiadane kategorie",
                        value = item.licences,
                    },
                },
            }
            previewCount = 1

        elseif item.variant == 1 and item.variant2 > 0 then
            self.previewData = {
                name = item.name,
            }
            previewCount = 0

        elseif item.variant == 2 then
            self.previewData = {
                name = item.name,
                data = {
                    {
                        title = "Bank",
                        value = "BBO Bank",
                    },
                    {
                        title = "PIN",
                        value = item.pinCode,
                    },
                },
            }
            previewCount = 2

        elseif item.variant == 3 then
            self.previewData = {
                name = item.name,
                data = {
                    {
                        title = "Numer telefonu",
                        value = item.number,
                    },
                },
            }
            previewCount = 1
        end

    elseif item.type == itemTypes.clothes then
        self.previewData = {
            name = item.name,
            data = {
                {
                    title = "ID skina",
                    value = item.value,
                },
            },
        }
        previewCount = 1

    elseif item.type == itemTypes.cigarettes then
        self.previewData = {
            name = item.name,
            data = {
                {
                    title = "Ilość papierosów",
                    value = item.value,
                },
            },
        }
        previewCount = 1

    elseif item.type == itemTypes.joints then
        if (item.variant == 0 and item.variant2 == 1) or (item.variant == 0 and item.variant2 == 2) then
            self.previewData = {
                name = item.name,
                data = {
                    {
                        title = "Ilość suszu",
                        value = "???",
                    },
                },
            }
        else
            self.previewData = {
                name = item.name,
                data = {
                    {
                        title = "Ilość suszu",
                        value = item.value.."g",
                    },
                },
            }
        end
        previewCount = 1

    elseif item.type == itemTypes.alcohol then
        self.previewData = {
            name = item.name,
            data = {
                {
                    title = "Stężenie alkoholu",
                    value = item.value.."%",
                },
            },
        }
        previewCount = 1

    elseif item.type == itemTypes.ammo then
        self.previewData = {
            name = item.name,
            data = {
                {
                    title = "Ilość naboi",
                    value = item.value,
                },
            },
        }
        previewCount = 1

    elseif item.type == itemTypes.armor then
        self.previewData = {
            name = item.name,
            data = {
                {
                    title = "Procent skuteczności",
                    value = item.value.."%",
                },
            },
        }
        previewCount = 1

    elseif item.type == itemTypes.fishingbait then
        self.previewData = {
            name = item.name,
            data = {
                {
                    title = "Możliwe założenia",
                    value = item.value,
                },
            },
        }
        previewCount = 1

    elseif item.type == itemTypes.weapon then
        local isRod = string.find(item.name, "Wędka") and true or false
        if isRod then
            local updateCost = {
                [2] = 80,
                [3] = 200,
                [4] = 400,
                [5] = 660,
                [6] = 900,
                [7] = 1300,
                [8] = 1800,
                [9] = 2500,
            }

            if item.variant2 ~= 12 then
                self.previewData = {
                    name = item.name,
                    data = {
                        {
                            title = "Złowione ryby",
                            value = string.format("%.2f kg", item.value),
                        },
                        {
                            title = "Kolejne ulepszenie",
                            value = string.format("%.2f kg", updateCost[item.variant2 - 2]),
                        },
                    },
                }
                previewCount = 2
            else
                self.previewData = {
                    name = item.name,
                    data = {
                        {
                            title = "Złowione ryby",
                            value = string.format("%.2f kg", item.value),
                        },
                    },
                }
                previewCount = 1
            end
        else
            self.previewData = {
                name = item.name,
                data = {
                    {
                        title = previewData[1].title,
                        value = previewData[1].value,
                    },
                    {
                        title = previewData[2].title,
                        value = previewData[2].value,
                    },
                    
                },
            }
            previewCount = 3
        end

    elseif item.type == itemTypes.premium then
        self.previewData = {
            name = item.name,
            data = {
                {
                    title = "Ilość dni",
                    value = item.value,
                },
            },
        }
        previewCount = 1

    elseif item.type == itemTypes.gift then
        if item.variant == 0 and item.variant2 == 0 then
            self.previewData = {
                name = item.name,
                data = {
                    {
                        title = "Co można wylosować",
                        value = "dostępne nagrody znajdują się poniżej",
                    },
                    {
                        title = "Pieniądze",
                        value = "$500",
                    },
                    {
                        title = "Świąteczny Strój",
                        value = "ubranie elfa świątecznego",
                    },
                    {
                        title = "Podpis jednego z właścicieli",
                        value = "leczy i napełnia głód",
                    },
                },
            }
            previewCount = 4

        elseif item.variant == 0 and item.variant2 == 1 then
            self.previewData = {
                name = item.name,
                data = {
                    {
                        title = "Co można wylosować",
                        value = "dostępne nagrody znajdują się poniżej",
                    },
                    {
                        title = "Pieniądze",
                        value = "$50 - $200",
                    },
                    {
                        title = "Konto Diamond",
                        value = "1 dzień",
                    },
                    {
                        title = "Konto Gold",
                        value = "3 dni",
                    },
                    {
                        title = "Tajemniczy przedmiot",
                        value = "???",
                    },
                },
            }
            previewCount = 5
        end

    elseif item.type == itemTypes.autograph then
        self.previewData = {
            name = item.name,
            data = {
                {
                    title = "Pozostałe użycia",
                    value = item.value,
                },
                {
                    title = "Życie",
                    value = "+100%",
                },
            },
        }
        previewCount = 2

    elseif item.type == itemTypes.paperSheet then
        self.previewData = {
            name = item.name,
            data = {
                {
                    title = "Ilość bletek",
                    value = item.value,
                },
            },
        }
        previewCount = 1

    else
        self.previewData = {
            name = item.name,
            data = previewData
        }
    end
    self.previewData.weight = details.weight and details.weight * (item.value2 or 1) or 0

    guiData.preview.h = 56/zoom + previewCount * 20/zoom + 20/zoom
    guiData.preview.y = (sy - guiData.preview.h)/2

    guiData.preview.w = dxGetTextWidth(string.format("Przedmiot: %s", self.previewData.name), 1/zoom, self.fonts.preview) + 12/zoom
    local width = dxGetTextWidth("Szczegółowe informacje", 1/zoom, self.fonts.optionsName) + 40/zoom
    if width > guiData.preview.w then
        guiData.preview.w = width
    end

    if self.previewData.data then
        for i, v in pairs(self.previewData.data) do
            local width = dxGetTextWidth(string.format("%s: %s", v.title, v.value), 1/zoom, self.fonts.preview) + 12/zoom
            if width > guiData.preview.w then
                guiData.preview.w = width
            end
        end

        self.previewData.value2 = item.value2
    end

    -- if self.tradeOpened then guiData.preview.y = guiData.preview.y + guiData.preview.h/2 + 260/zoom end
    -- self.buttons = {}
    -- self.buttons.preview = exports.TR_dx:createButton(guiData.preview.x + (guiData.preview.w - 200/zoom)/2, guiData.preview.y + guiData.preview.h - 50/zoom, 200/zoom, 40/zoom, "Zamknij podgląd")

    -- self.blockHover = true
    -- self.optionsCursor = nil
    -- self.avaliableOptions = nil
    -- self.btnHandler = true
    -- addEventHandler("guiButtonClick", root, self.func.btnClicker)
end



function Equipment:setBoomboxUsed(itemID, state)
    if not self.items then return false end
    for _, category in pairs(self.items) do
        for i, v in pairs(category) do
            if v.ID == itemID then
                v.used = state
                break
            end
        end
    end
end

function Equipment:getVehicleName(_model)
    local model = tonumber(_model)
    if model == 471 then return "Snowmobile" end
    if model == 604 then return "Christmas Manana" end
    return getVehicleNameFromID(model)
end


function Equipment:drawEqBackground(x, y, w, h, color, radius, post)
    dxDrawRectangle(x, y - radius, w, h + radius * 2, color, post)
    dxDrawRectangle(x - radius, y, radius, h, color, post)
    dxDrawCircle(x, y, radius, 180, 270, color, color, 7, 1, post)
    dxDrawCircle(x, y + h, radius, 90, 180, color, color, 7, 1, post)
end

function Equipment:drawOptionsBackground(x, y, rx, ry, color, radius, post)
    rx = rx - radius * 2
    ry = ry - radius * 2
    x = x + radius
    y = y + radius

    if (rx >= 0) and (ry >= 0) then
        dxDrawRectangle(x, y, rx, ry, color, post)
        dxDrawRectangle(x, y - radius, rx, radius, color, post)
        dxDrawRectangle(x, y + ry, rx, radius, color, post)
        dxDrawRectangle(x - radius, y, radius, ry, color, post)
        dxDrawRectangle(x + rx, y, radius, ry, color, post)

        dxDrawCircle(x, y, radius, 180, 270, color, color, 7, 1, post)
        dxDrawCircle(x + rx, y, radius, 270, 360, color, color, 7, 1, post)
        dxDrawCircle(x + rx, y + ry, radius, 0, 90, color, color, 7, 1, post)
        dxDrawCircle(x, y + ry, radius, 90, 180, color, color, 7, 1, post)
    end
end

function Equipment:isMouseInPosition(x, y, width, height)
	if (not isCursorShowing()) then
		return false
	end
  local cx, cy = getCursorPosition()
  local cx, cy = (cx*sx), (cy*sy)
  if (cx >= x and cx <= x + width) and (cy >= y and cy <= y + height) then
    return true
  else
    return false
  end
end


function Equipment:hasPlayerItem(type, variant, variant2, count)
    local type = tonumber(type)
    local variant = tonumber(variant)
    local variant2 = tonumber(variant2)
    if not self.items then return false end
    for _, category in pairs(self.items) do
        for i, v in pairs(category) do
            if tonumber(v.type) == type and tonumber(v.variant) == variant and tonumber(v.variant2) == variant2 then
                if count then
                    if v.value2 >= count then
                        return v.ID
                    end
                else
                    return v.ID
                end
            end
        end
    end
    return false
end

function Equipment:hasPlayerItem(type, variant, variant2, count)
    local type = tonumber(type)
    local variant = tonumber(variant)
    local variant2 = tonumber(variant2)
    if not self.items then return false end
    for _, category in pairs(self.items) do
        for i, v in pairs(category) do
            if tonumber(v.type) == type and tonumber(v.variant) == variant and tonumber(v.variant2) == variant2 then
                if count then
                    if v.value2 >= count then
                        return v.ID
                    end
                else
                    return v.ID
                end
            end
        end
    end
    return false
end

function Equipment:getPlayerWeapon(value)
    local variant = tonumber(variant)
    local variant2 = tonumber(variant2)
    if not self.items then return false end
    for _, category in pairs(self.items) do
        for i, v in pairs(category) do
            if tonumber(v.type) == 1 and tonumber(v.value) == value then
                return v.ID
            end
        end
    end
    return false
end

function Equipment:updatePlayerWeaponDurability(value, durability)
    if not self.items then return false end
end

function Equipment:takeWeaponAmmo(weaponID)
    if not self.items then return false end
    for _, category in pairs(self.items) do
        for i, v in pairs(category) do
            if v.type == itemTypes.ammo and v.variant == weaponAmmoType[weaponID] then
                if tonumber(v.value) > 0 then
                    v.value = tonumber(v.value) - 1

                    if tonumber(v.value) == 0 then table.remove(self.items["weapons"], i) end
                    return true
                end
            end
        end
    end
    return false
end

function Equipment:takePlayerItem(itemID, count)
    if not self.items then return false end
    for k, category in pairs(self.items) do
        for i, v in pairs(category) do
            if v.ID == itemID then
                v.value2 = tonumber(v.value2) - (count and count or 1)
                if v.value2 <= 0 then
                    table.remove(self.items[k], i)

                    if self.opened then
                        self:setCategory(self.selectedCategory)
                    end
                end
                break
            end
        end
    end
    return false
end

function Equipment:takeArmor()
    if not self.items then return false end
    local armor = getPedArmor(localPlayer)

    for _, category in pairs(self.items) do
        for i, v in pairs(category) do
            if v.type == itemTypes.armor then
                if tonumber(v.value) > 0 then
                    v.value = math.floor(armor * 100)/100
                    return true
                end
            end
        end
    end
    return false
end

function Equipment:updateRodMass(mass)
    for _, category in pairs(self.items) do
        for i, v in pairs(category) do
            local isRod = string.find(v.name, "Wędka") and true or false
            if isRod then
                v.value = v.value + mass
                break
            end
        end
    end
end



function Equipment:updateFishBait(itemID)
    local item, itemCat, itemIndex = false, false, false
    for category, _ in pairs(self.items) do
        for i, v in pairs(self.items[category]) do
            if v.ID == itemID then
                item = self.items[category][i]
                itemCat = category
                itemIndex = i
                break
            end
        end
    end
    if not item then return false end
    if not item.used then return false, true end

    local fishingRod = false
    for category, _ in pairs(self.items) do
        for i, v in pairs(self.items[category]) do
            local isRod = string.find(v.name, "Wędka")
            if isRod and v.used then
                fishingRod = v
                break
            end
        end
    end
    if not fishingRod then return false, true end

    triggerServerEvent("takeBait", resourceRoot, item.ID)
    item.value = item.value - 1
    if item.value <= 0 then
        table.remove(self.items[itemCat], itemIndex)
        return false
    end
    return true
end

function Equipment:upgradeRod(mass, lvl, clear)
    for category, _ in pairs(self.items) do
        for i, v in pairs(self.items[category]) do
            local isRod = string.find(v.name, "Wędka")
            if isRod and v.used then
                if clear then
                    v.value = 0
                else
                    v.value = v.value - mass
                end

                if lvl then
                    v.variant2 = lvl + 3
                    v.name = "Wędka +"..lvl

                    if lvl == 9 then
                        exports.TR_achievements:addAchievements("fishingRod9")
                    end
                end
                break
            end
        end
    end
    return true
end



GUI.eq = Equipment:create()
function updateItems(items, vehicles, houses, open)
    GUI.eq:updateItems(items, vehicles, houses, open)
    exports.TR_dx:setResponseEnabled(false)
end
addEvent("updateItems", true)
addEventHandler("updateItems", resourceRoot, updateItems)

function equipmentResponse(text, type, update)
    if text then exports.TR_noti:create(text, type and type or "info") end
    if update then GUI.eq:setItemUsed() end

    if text == "Założyłeś kominiarkę." then
        exports.TR_achievements:addAchievements("characterBalaclava")

    elseif text == "Skin został założony." then
        exports.TR_achievements:addAchievements("changeSkin")
    end

    GUI.eq:response()
    exports.TR_weapons:updateWeapons()
end
addEvent("equipmentResponse", true)
addEventHandler("equipmentResponse", resourceRoot, equipmentResponse)

function rentResponse()
    GUI.eq:rentResponse()
end
addEvent("rentResponse", true)
addEventHandler("rentResponse", resourceRoot, rentResponse)

function spraySuccessResponse()
    GUI.eq:spraySuccessResponse()
end
addEvent("spraySuccessResponse", true)
addEventHandler("spraySuccessResponse", root, spraySuccessResponse)

function isPlayerOverloaded(...)
    return GUI.eq:isPlayerOverloaded(...)
end

function hasPlayerItem(...)
    return GUI.eq:hasPlayerItem(...)
end

function takePlayerItem(...)
    return GUI.eq:takePlayerItem(...)
end
addEvent("takePlayerItem", true)
addEventHandler("takePlayerItem", root, takePlayerItem)

function updateFishBait(...)
    return GUI.eq:updateFishBait(...)
end

function updateRodMass(mass)
    GUI.eq:updateRodMass(mass)
end

function upgradeRod(...)
    GUI.eq:upgradeRod(...)
end
addEvent("upgradeRod", true)
addEventHandler("upgradeRod", root, upgradeRod)

function setBoomboxUsed(state)
    GUI.eq:setBoomboxUsed(state)
end

function updatePlayerKeysTable(...)
    GUI.eq:updatePlayerKeysTable(...)
end
addEvent("updatePlayerKeysTable", true)
addEventHandler("updatePlayerKeysTable", root, updatePlayerKeysTable)


function onWeaponFire(weaponID)
    if weaponsWithoutAmmo[weaponID] then return end
    if not weaponAmmoType[weaponID] then return end
    if not GUI.eq:takeWeaponAmmo(weaponID) then return end

    if not guiData.firedAmmunitions[weaponID] then guiData.firedAmmunitions[weaponID] = 0 end
    guiData.firedAmmunitions[weaponID] = guiData.firedAmmunitions[weaponID] + 1

    local weaponItemID = GUI.eq:getPlayerWeapon(weaponID)
    local durabilityTake = tonumber(string.format("%.6f", 1/weaponDurability[weaponID])) * 100
    local removed = GUI.eq:updatePlayerWeaponDurability(weaponItemID, durabilityTake)

    if guiData.firedAmmunitions[weaponID] >= 5 or removed then
        guiData.firedAmmunitions[weaponID] = 0

        triggerServerEvent("onPlayerWeapFire", resourceRoot, weaponAmmoType[weaponID], weaponItemID, durabilityTake * 5)
    end
end
addEventHandler("onClientPlayerWeaponFire", localPlayer, onWeaponFire)


function onPlayerDamage(attacker, weapon, body, loss)
    if weapon == 7 then
        cancelEvent()
        return
    end

    if source == localPlayer then
        if weapon == 23 then
            triggerServerEvent("setPlayerTazered", resourceRoot, localPlayer)
            cancelEvent()
            return
        end

        if not getElementData(localPlayer, "characterUID") then cancelEvent() end

        if attacker then
            if getElementType(attacker) == "player" then
                local plrTeam = getPlayerTeam(localPlayer)
                local targetTeam = getPlayerTeam(attacker)
                if plrTeam and targetTeam then
                    if plrTeam == targetTeam then
                        cancelEvent()
                        return
                    end
                end

                local feature = getWeaponFeature(weapon)
                if feature then
                    local attackerSkill = exports.TR_features:getFeatureValue(feature, attacker)
                    local defenceSkill = exports.TR_features:getFeatureValue("medicine")
                    local multiplayer = 1 + attackerSkill/1000 - defenceSkill/1000
                    local dmg = loss * multiplayer
                    setElementHealth(localPlayer, getElementHealth(localPlayer) - dmg)
                end
            end
        end
    end

    if attacker and weapon ~= 54 then
        -- local side = findShootSide(attacker, source)

        -- if shootAnim[body] then
        --     if shootAnim[body][side] then
        --         setPedAnimation(source, "ped", shootAnim[body][side], -1, false, false, false, false, 0)
        --     else
        --         setPedAnimation(source, "ped", shootAnim[body].front, -1, false, false, false, false, 0)
        --     end
        -- end

        if source == localPlayer then
            GUI.eq:takeArmor()
        end
    end
end
addEventHandler("onClientPlayerDamage", root, onPlayerDamage)


function getWeaponFeature(weaponID)
    if weaponID <= 9 then return "strenght" end
    if weaponID <= 34 then return "weapon" end
    return false
end

function findShootSide(attacker, player)
    local attPos = Vector3(getElementPosition(attacker))
    local plrPos = Vector3(getElementPosition(player))

    local rot = findRotation(attPos.x, attPos.y, plrPos.x, plrPos.y)
    local _, _, vrot = getElementRotation(player)

    rot = vrot - rot
    rot = rot < 0 and rot + 360 or rot

    if rot < 335 and rot >= 210 then return "right"
    elseif (rot < 30 and rot >= 0) or (rot <= 360 and rot >= 335) then return "back"
    elseif rot < 150 and rot >= 30 then return "left"
    elseif rot < 210 and rot >= 150 then return "front"
    end
end

function findRotation( x1, y1, x2, y2 )
    local t = -math.deg( math.atan2( x2 - x1, y2 - y1 ) )
    return t < 0 and t + 360 or t
end