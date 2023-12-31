local priorityResources = {"TR_mysql", "TR_textures", "TR_dx", "TR_npc", "TR_chat", "TR_admin", "TR_vehicleExchange", "TR_vehicles", "bone_attach"}


function startPriority()
	setFPSLimit(60)
	setServerConfigSetting("bandwidth_reduction", "medium", true)

	for _, name in pairs(priorityResources) do
		local res = getResourceFromName(name)
		local state = getResourceState(res)
		if state == "loaded" then
			local started = startResource(res)
			if started then print("[TR_starter] Resource " .. name .. " restarted.") end

		-- elseif state == "running" then
		-- 	local success = restartResource(res)
		-- 	if success then print("[TR_starter] Resource " .. name .. " started.") end
		end
	end
end

function start()
	local resourceTable = getResources()
	for k, resource in ipairs(resourceTable) do
		local name = getResourceName(resource)
		if string.find(name, "TR_") then
			local state = getResourceState(resource)
			if state == "loaded" then
				local started = startResource(resource)
				if started then print("[TR_starter] Resource " .. name .. " restarted.") end

			-- elseif state == "running" then
			-- 	local success = restartResource(resource)
			-- 	if success then print("[TR_starter] Resource " .. name .. " started.") end
			end
		end
	end
end
startPriority()
setTimer(start, 1000, 1)


function startResources(resources)
	for _, v in pairs(resources) do
		local resource = getResourceFromName(v)
		if resource then
			if getResourceState(resource) == "loaded" then
				startResource(resource)
			end
		end
	end
end

function stopResources(resources)
	for _, v in pairs(resources) do
		local resource = getResourceFromName(v)
		if resource then
			if getResourceState(resource) == "running" then
				stopResource(resource)
			end
		end
	end
end

function reloadResources(resources)
	for _, v in pairs(resources) do
		local resource = getResourceFromName(v)
		if resource then restartResource(resource) end
	end
end