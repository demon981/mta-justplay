function removeColor(text)
    while string.find(text, "#%x%x%x%x%x%x") do
      text = string.gsub(text, "#%x%x%x%x%x%x", "")
    end
    return text
end

function drawTextShadowed(text, x, y, w, h, color, scale, font, vert, hori, clip, brake, post, colored, plrAlpha)
  local alphaMult = plrAlpha or 1
	local withoutColor = removeColor(text)
	dxDrawText(withoutColor, x + 1, y + 1, w + 1, h + 1, tocolor(0, 0, 0, 100 * settings.alpha * alphaMult), scale, font, vert, hori, clip, brake, post)
	dxDrawText(text, x, y, w, h, color, scale, font, vert, hori, clip, brake, post, colored)
end

function drawTextHardShadowed(text, x, y, w, h, color, scale, font, vert, hori, clip, brake, post, colored)
	local withoutColor = removeColor(text)
	dxDrawText(withoutColor, x + 1, y + 1, w + 1, h + 1, tocolor(0, 0, 0, 200 * settings.alpha), scale, font, vert, hori, clip, brake, post)
	dxDrawText(text, x, y, w, h, color, scale, font, vert, hori, clip, brake, post, colored)
end

function getPlayerData(plr)
	local data = getElementData(plr, "characterData")
	if not data then return getPlayerName(plr), "#dddddd", false end
	local color = "#dddddd"

	if data then
		if data.premium == "gold" then
			color = "#d6a306"

		elseif data.premium == "diamond" then
			color = "#31caff"
		end
	end

	local id = getElementData(plr, "ID")
    local isInZone = isInDmZone(plr)
	local hasMask = getElementData(plr, "characterMask")

	local name, color = getPlayerRealName(plr, color, hasMask, isInZone)
	return name, color, hasMask and isInZone and true or false
end


function getPlayerRealName(plr, color, hasMask, isInZone)
	local id = getElementData(plr, "ID")
	local fakeName = getElementData(plr, "fakeName")
	local name = getPlayerName(plr)
	local admin = exports.TR_admin:isPlayerOnDuty()

	if fakeName then return fakeName, "#dddddd" end
	if hasMask and isInZone then
		if admin then return string.format("Nieznajomy #%03d (%s)", id, name), "#929ea8" end
	  	return string.format("Nieznajomy #%03d", id), "#929ea8"
	end

	local usernameRP = getElementData(plr, "usernameRP")
	if getElementData(localPlayer, "wantRP") and getElementData(plr, "wantRP") and usernameRP then
		name = admin and string.format("%s (%s)", usernameRP, name) or usernameRP
	end

	return name, color
end

function getPlayerDuty(plr)
	local admin = exports.TR_admin:isPlayerOnDuty()
	local adminJob = ""
	local plrJob = getElementData(plr, "inJob")
	if admin and plrJob and type(plrJob) == "string" then
		adminJob = "\n"..plrJob
	end

	if not getElementData(plr, "characterUID") then return "(Niezalogowany)"..adminJob, {169, 39, 14} end
	local org = getElementData(plr, "characterOrg")
	local data = getElementData(plr, "characterDuty")
	if data then
		return string.format("(%s)%s", data[1], adminJob), data[2] and data[2] or {220, 220, 220}
	end
	if org then return string.format("(%s)%s", org, adminJob), {220, 220, 220} end
	return "(Obywatel)"..adminJob, {180, 180, 180}
end

function getPlayerIcons(plr)
	if not getElementData(plr, "characterUID") then return {"files/images/icons/unlogged.png"} end
	local icons = {}
	local rank = getElementData(plr, "adminDuty")

	if rank then
		if string.find(rank, "-s") then
		elseif string.find(rank, "owner") then table.insert(icons, "files/images/icons/owner.png")
		elseif string.find(rank, "guardian") then table.insert(icons, "files/images/icons/guard.png")
		elseif string.find(rank, "admin") then table.insert(icons, "files/images/icons/adm.png")
		elseif string.find(rank, "moderator") then table.insert(icons, "files/images/icons/mod.png")
		elseif string.find(rank, "support") then table.insert(icons, "files/images/icons/supp.png")
		elseif string.find(rank, "developer") then table.insert(icons, "files/images/icons/dev.png")
		elseif string.find(rank, "globalmoderator") then table.insert(icons, "files/images/icons/gmod.png")
		end
	end

	if getElementData(plr, "wantRP") then table.insert(icons, "files/images/icons/rp.png") end

	if getElementData(plr, "playerMute") then table.insert(icons, "files/images/icons/chat_mute.png")
	elseif getElementData(plr, "chatting") then table.insert(icons, "files/images/icons/chat.png")
	end

	if getElementData(plr, "afk") then table.insert(icons, "files/images/icons/afk.png") end
	if getPlayerArmor(plr) > 0 then table.insert(icons, "files/images/icons/armor.png") end
	if getElementData(plr, "beer") then table.insert(icons, "files/images/icons/beer.png") end
	if getElementData(plr, "marijuana") then table.insert(icons, "files/images/icons/marijuana.png") end
	return icons
end

function setElementSpeed(element, unit, speed)
    local unit    = unit or 0
    local speed   = tonumber(speed) or 0
	local acSpeed = getElementSpeed(element, unit)
	if (acSpeed) then
		local diff = speed/acSpeed
		if diff ~= diff then return false end
        local x, y, z = getElementVelocity(element)
		return setElementVelocity(element, x*diff, y*diff, z*diff)
	end

	return false
end

function getElementSpeed(theElement, unit)
	if not isElement(theElement) then return 0 end
    local elementType = getElementType(theElement)
    unit = unit == nil and 0 or ((not tonumber(unit)) and unit or tonumber(unit))
    local mult = (unit == 0 or unit == "m/s") and 50 or ((unit == 1 or unit == "km/h") and 180 or 111.84681456)
    return (Vector3(getElementVelocity(theElement)) * mult).length
end

function findRotation(x1,y1,x2,y2)
	local t = -math.deg(math.atan2(x2-x1,y2-y1))
	if t < 0 then t = t + 360 end
	return t
end

function getPointFromDistanceRotation(x, y, dist, angle)
	local a = math.rad(90 - angle)
	local dx = math.cos(a) * dist
	local dy = math.sin(a) * dist
	return x + dx, y + dy
end

function getPedMaxOxygenLevel(ped)
    assert(isElement(ped) and (getElementType(ped) == "ped" or getElementType(ped) == "player"), "Bad argument @ 'getPedMaxOxygenLevel' [Expected ped at argument 1, got " .. tostring(ped) .. "]")
    local underwater_stamina = getPedStat(ped, 225)
    local stamina = getPedStat(ped, 22)
    local maxoxygen = 1000 + underwater_stamina * 1.5 + stamina * 1.5
    return maxoxygen
end

function string.wrap(text, maxwidth, scale, font, colorcoded)
  local lines = {}
  local words = split(text, " ") -- this unfortunately will collapse 2+ spaces in a row into a single space
  local line = 1 -- begin with 1st line
  local word = 1 -- begin on 1st word
  local endlinecolor
  while (words[word]) do -- while there are still words to read
      repeat
          if colorcoded and (not lines[line]) and endlinecolor and (not string.find(words[word], "^#%x%x%x%x%x%x")) then -- if on a new line, and endline color is set and the upcoming word isn't beginning with a colorcode
              lines[line] = endlinecolor -- define this line as beginning with the color code
          end
          lines[line] = lines[line] or "" -- define the line if it doesnt exist

          if colorcoded then
              local rw = string.reverse(words[word]) -- reverse the string
              local x, y = string.find(rw, "%x%x%x%x%x%x#") -- and search for the first (last) occurance of a color code
              if x and y then
                  endlinecolor = string.reverse(string.sub(rw, x, y)) -- stores it for the beginning of the next line
              end
          end

          lines[line] = lines[line]..words[word] -- append a new word to the this line
          lines[line] = lines[line] .. " " -- append space to the line

          word = word + 1 -- moves onto the next word (in preparation for checking whether to start a new line (that is, if next word won't fit)
      until ((not words[word]) or dxGetTextWidth(lines[line].." "..words[word], scale, font, colorcoded) > maxwidth) -- jumps back to 'repeat' as soon as the code is out of words, or with a new word, it would overflow the maxwidth

      lines[line] = string.sub(lines[line], 1, -2) -- removes the final space from this line
      if colorcoded then
          lines[line] = string.gsub(lines[line], "#%x%x%x%x%x%x$", "") -- removes trailing colorcodes
      end
      line = line + 1 -- moves onto the next line
  end -- jumps back to 'while' the a next word exists
  return table.concat(lines, "\n")
end

function getTimeInSeconds(miliseconds)
    local durationInMillis = tonumber(miliseconds)
    if not durationInMillis or durationInMillis == nil then return "00:00.000" end
    if durationInMillis <= 0 then return "00:00.000" end

	local millis = durationInMillis % 1000;
	local second = (durationInMillis / 1000) % 60;
	local minute = (durationInMillis / (1000 * 60)) % 60;
	local hour = (durationInMillis / (1000 * 60 * 60)) % 24;
	if hour >= 1 then
		return string.format("%02d:%02d:%02d.%03d", hour, minute, second, millis)
	else
		return string.format("%02d:%02d.%03d", minute, second, millis)
	end
end

function comma_value(amount)
	local formatted = amount
	while true do
	  formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1 %2')
	  if (k==0) then
		break
	  end
	end
	return formatted
end