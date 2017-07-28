--[[ Main objective:
 Defend your containers against the zombie horde. A new zombie will spawn
every 5 seconds. Killed containers are respawned withing that same interval. ]]

KUBERURL = "localhost:8001"
counter = 0
teams = {}
--[[ Holds the npc model data ]]
model = {}
--[[ Used for data control]]
dControl = {}
model[1] = {}
model[1]["model"] = "npc_citizen"
model[1]["version"] = "v1"
model[2] = {}
model[2]["model"] = "npc_eli"
model[2]["version"] = "v2"
teams["green"] = {}
teams["red"] = {}
teams["purple"] = {}
teams["ebony"] = {}
teams["magenta"] = {}
teams["ivory"] = {}
enemy_npc = "npc_zombie"

--[[
 * The main loop, that shouldn't be named Main().
 ]]
function Main()
    --[[
     * Gets the list of running application from Marathon.
     */
    // TODO: rewrite this http.Fetch() too
	// TODO: Change API to be Kubernetes compatibl
  ]]
		
		--[[ Data required from the Pods API ]]
	http.Fetch( "http://"..KUBERURL.."/api/v1/namespaces/default/pods",
        function(pbody, len, headers, code)
			httpConnected(pbody, len, headers, code)
    	end,
    	function(error)
            httpFailed(error)
    	end
    )
    httpFailed = function(error)
        PrintMessage(HUD_PRINTTALK, "Connection failed, something bad happened:")
        PrintMessage(HUD_PRINTTALK, error)
    end
    httpConnected = function(pbody, len, headers, code)
        if code != 200 then
            PrintMessage(HUD_PRINTTALK, "Received incorrect reply from nodes API")
            return
        end
		podsTable = util.JSONToTable(pbody)
		podsTable = podsTable['items']
		local numberP = table.Count(podsTable)
		
		--[[ Amount of ]]
		--[[ Will iterate through all existing containers ]]
		for i=1, numberP do 
			contTable = podsTable[i]
			serName = contTable['metadata']['name']
			teamName = contTable['metadata']['labels']['team']
			typeName = contTable['metadata']['labels']['type']
			imageV = contTable['spec']['containers'][1]['image']
			if contTable['status']['conditions'][2] != nil then
				phase = contTable['status']['conditions'][2]['status']
			end
			nodeName = contTable['spec']['nodeName']
			--[[print(serName.." has status ".. phase)]]
			
			local version = {}
			for word in imageV:gmatch("([^:]+)") do 
				table.insert(version, word)
			end
			imageV = version[2]
		
			if phase == "True" then
				local n = entitiesSpawned(serName)
				if n < 1 then 
					print("[Kubernetes] service "..serName.." of team "..teamName)
					blazeSpawn(serName, teamName, typeName, imageV, nodeName, changedI)
					
				end
			end	
		end
		
	end
	
	--[[ USES DEPLOYMENT API TO CHECK FOR DOUBLE MODELS AND CONTAINERS ]]
	http.Fetch( "http://"..KUBERURL.."/apis/apps/v1beta1/namespaces/default/deployments",
        function(debody, len, headers, code)
			httpConnectedDeps(debody, len, headers, code)
    	end,
    	function(error)
            httpFailedDeps(error)
    	end
    )
    httpFailedDeps = function(error)
        PrintMessage(HUD_PRINTTALK, "Connection failed, something bad happened:")
        PrintMessage(HUD_PRINTTALK, error)
    end
    httpConnectedDeps = function(debody, len, headers, code)
        if code != 200 then
            PrintMessage(HUD_PRINTTALK, "Received incorrect reply from nodes API")
            return
        end
		depsTable = util.JSONToTable(debody)
		depsTable = depsTable['items']
		depsCount = table.Count(depsTable)
		for i=1, depsCount do
			deps2Table = depsTable[i]
			depsName = deps2Table['metadata']['name']
			betweenTable = deps2Table['spec']['template']['spec']['containers']
			depsImage = betweenTable[1]['image']
			
			local version = {}
			for word in depsImage:gmatch("([^:]+)") do 
				table.insert(version, word)
			end
			depsImage = version[2]
			checkEntities(depsName, depsImage)
		end
	end
	
	function checkEntities(deploymentN, im)
		podEnt = ents.GetAll()
		filtCl = {}
		for i=1, table.Count(podEnt) do
			for j=1, table.Count(model) do
				if podEnt[i]:GetClass() == model[j]["model"] then
					table.insert(filtCl, podEnt[i])
				end
			end
		end
		local hash = {}
		local res = {}
		for _,v in ipairs(filtCl) do
		   if (not hash[v]) then
			   res[#res+1] = v -- you could print here instead of saving to result table if you wanted
			   hash[v] = true
		   end
		end
		for i=1, table.Count(res) do
			local stringMatch = {}
			local containerName = res[i]:GetName()
			for word in containerName:gmatch("([^-]+)") do 
				table.insert(stringMatch, word)
			end
			if stringMatch[1] == deploymentN then
				local modelMatch = {}
				for j=1, table.Count(model) do
					if model[j]["version"] == im then
						table.insert(modelMatch, model[j]["model"])
					end
				end
				if res[i]:GetClass() != modelMatch[1] then
					res[i]:Remove()
				end
			end
		end
	end
	
	--[[ function doubleEntities(dataTable)
		podEnts = ents.GetAll()
		filtTable = {}
		for i=1, table.Count(podEnts) do
			for j=1, table.Count(model) do
				if podEnts[i]:GetClass() == model[j]["model"] then
					table.insert(filtTable, podEnts[i])
				end
			end
		end
		local hash = {}
		local rest = {}
		for _,v in ipairs(filtTable) do
		   if (not hash[v]) then
			   rest[#rest+1] = v -- you could print here instead of saving to result table if you wanted
			   hash[v] = true
		   end
		end
		for i=table.Count(dataTable),1,-1 do
			if rest[i]:GetName() == dataTable[i]['metadata']['name'] then
				print("------------".. rest[i]:GetName().."---"..dataTable[i]['metadata']['name'])
				rest[i] = "allo"
				PrintTable(rest)
				
			end
		end
		for i=1, table.Count(rest) do
			if rest[i] != "allo" then
				rest[i]:Remove()
				print("*************DESTROYED**********")
			end
		end
	end ]]
	--[[ FETCH DEPLOYMENT TO CHECK FOR NPC DELETION ]]
	
	
   --[[
     * Returns the count of all NPCs spawned for this service.
     ]]
	 
    entitiesSpawned = function(podName)
        if not podName then
            return 10000000
		end
		return table.Count(ents.FindByName(podName))
    end
	
	function is_empty(t)
		for _,_ in pairs(t) do
			return false
		end
		return true
	end
	
	
	
    --[[
     * Does the actual spawn of a NPC/entity.
     ]]
    blazeSpawn = function(what, team, type, version, nodeid, imageChange)
        if not teams[team] then
            return
        end
		--[[ Checks for different image version and provides a different model1
			 Used for rolling updates.
			]]
		local e
		if version == "v1" then
			e = model[1]["model"]
		elseif version == "v2" then
			e = model[2]["model"]
		else 
			e = model[3]["model"]
		end
		nodeC = table.Count(node)
		for i=1, nodeC do
			if nodeid == node[i]["name"] then
				xX = node[i]["x"]
				yY = node[i]["y"]
				rangeX = rangeTableX[3] - 50
				rangeY = rangeTableY[2] - 50
			end
		end
        PrintMessage(HUD_PRINTTALK, "Spawning for service "..what)
		--[[ Create entity and spawn it ]]
        ent = ents.Create(e)
        ent:SetName(what)
		local zZ = -12700
        ent:SetPos(Vector(math.random(xX-rangeX,xX+rangeX),math.random(yY-rangeY,yY+rangeY),zZ))
        ent:Spawn()
        ent:Activate()
        ent:DropToFloor()

        --[[ not everyone gets a crowbar ]]
        if math.random(1,3) == 1 then
            ent:Give("ai_weapon_crowbar")
        end

        --[[ all your base are belong to team purple ]]
        if team == "purple" then
            ent:Give("ai_weapon_rpg")
        end

        --[[ everyone should hate zombies! ]]
        for _, zombie in pairs(ents.FindByClass(enemy_npc)) do
          --[[ make entity a zombie and add Hate to 99 ]]
            ent:AddRelationship(enemy_npc.." D_HT 99")
        end

        ent:NavSetWanderGoal(400, 8000)
        ent:SetMovementActivity(ACT_WALK)
        ent:SetSchedule(SCHED_FORCED_GO)
    end

    --[[
     * This sends the DELETE to Marathon.
     */
	 // TODO: Change API to be Kubernetes compatible ]]
    doKillContainer = function(killme)
		print("container that will be killed: "..killme)
        local url = "http://"..KUBERURL.."/api/v1/namespaces/default/pods/"..killme
        local data =
        {
            url = url,
            method = "DELETE",
            parameters = {},
            success = function(code, body, headers)
                if code ~= 200 then
                    print("[ERROR] failed to shoot container!")
                    return
                end
                PrintMessage(HUD_PRINTCENTER, "Container:  "..killme.."  will go down")
				PrintMessage(HUD_PRINTTALK, "Container:  "..killme.."  will go down")
            end,
            failed = function(message)
                print("[ERROR] failed")
            end
        }
        HTTP(data)
    end
end

--[[
function changeControl(i, imageVer)
	
	http.Fetch( "http://"..MESOSURL.."/v2/apps",
        function(body, len, headers, code)
            httpConnected(body, len, headers, code)
    	end,
    	function(error)
            httpFailed(error)
    	end
    )
    httpFailed = function(error)
        PrintMessage(HUD_PRINTTALK, "Connection failed, something bad happened:")
        PrintMessage(HUD_PRINTTALK, error)
    end
    httpConnected = function(body, len, headers, code)
        if code != 200 then
            PrintMessage(HUD_PRINTTALK, "Received incorrect reply")
            return
        end
	
	newVar = {}
	if imageVer != dControl[i]['spec']['containers'][1]['image'] then
		
	end
	
end
]]

function Zombies()
	blazeSpawnKiller = function()
        local e = enemy_npc
        local entZ = ents.Create(e)
        entZ:SetName("none")
        entZ:SetPos(Vector(math.random(0,200), math.random(2000,3000), 12700))
        entZ:Spawn()
        entZ:Activate()
        entZ:DropToFloor()
        entZ:SetMovementActivity(ACT_WALK)
        entZ:SetSchedule(SCHED_FORCED_GO)
    end

    blazeSpawnKiller()
end

--[[ Do things when a NPC dies or something ]]
hook.Add("OnNPCKilled", "OnNPCKilled", function(npc, attacker, inflictor)
    local you = attacker:GetName()

    --[[ Spawn some goods when someone dies ]]
    local goodies = {
        "item_healthkit",
        "item_ammo_smg1",
        "item_ammo_ar2",
        "item_ammo_crossbow",
        "item_box_buckshot"
    }
    local goods = ents.Create(table.Random(goodies))
	goods:SetPos(npc:LocalToWorld(npc:OBBCenter()))
	goods:Spawn()

    --[[ Actually kill something on Mesos here
    // Example value of `npc`:
    //   NPC [184][npc_kleiner] --]]
    for npcid in string.gmatch(tostring(npc), "%[([%d]+)%]") do
        eid = npcid
    end
    service = tostring(npc:GetName())
    if service ~= "none" then
        doKillContainer(service)
    end

    --[[ Stuff that happens when the player inflicts death goes here ]]
    if you ~= "none" then
        local theplayer = 1
        local ply = Entity(theplayer)
        local wp = ply:GetActiveWeapon():GetClass()
        PrintMessage(HUD_PRINTTALK, you.." killed "..npc:GetName().." using "..wp)
    end
end)

--[[ headshot! ]]
hook.Add("ScaleNPCDamage", "ScaleNPCDamage", function(deadplayer, hitgroup, dmginfo)
    if (hitgroup == 0) then
        PrintMessage(HUD_PRINTTALK, "HEADSHOT!")
    end
end)

hook.Add( "PlayerSay", "SpawnZombies", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	timer.Create("Zombies()", 5 ,0 , Zombies)
	timer.Pause("Zombies()")
	print(text)
	if ( text == "spawnzombies" ) then
		timer.Start("Zombies()")
		PrintMessage(HUD_PRINTTALK, "Start Spawning Zombies")
	else
		timer.Stop("Zombies()")
		PrintMessage(HUD_PRINTTALK, "Stop Spawning Zombies")
	end
end )

--[[ Takes care of the spawning of nodes 
	 This happens through the creation of range tables and
	 .....]]
function fenceSpawn()
	--[[ Tables will be used to generate a square with 8 blocks ]]
	rangeTableX = {-200,0,200,0,-200,-200,200,200}
	rangeTableY = {0,200,0,-200,200,-200,200,-200}
	--[[ Node inlezen en tabel beginnen printen ]]
	http.Fetch( "http://"..KUBERURL.."/api/v1/nodes",
        function(body, len, headers, code)
			httpConnected(body, len, headers, code)
    	end,
    	function(error)
            httpFailed(error)
    	end
    )
    httpFailed = function(error)
        PrintMessage(HUD_PRINTTALK, "Connection failed, something bad happened:")
        PrintMessage(HUD_PRINTTALK, error)
    end
    httpConnected = function(body, len, headers, code)
        if code != 200 then
            PrintMessage(HUD_PRINTTALK, "Received incorrect reply from nodes API")
            return
        end
		local apiTable = util.JSONToTable(body)
		node = {}
		apiTable = apiTable["items"]
		for i=1, table.Count(apiTable) do
			local metaTable = apiTable[i]
			node[i] = {}
			node[i]["name"] = metaTable["metadata"]["name"]
			node[i]["x"] = 0
			if i == 1 then
				node[i]["y"] = 3000
			else
				local calcY = node[i-1]["y"] - 800
				node[i]["y"] = calcY
			end
			node[i]["z"] = -12700
			
			local memory = {}
			local mem = metaTable["status"]["capacity"]["memory"]
			--[[ TODO: Change to till letter ]]
			for word in mem:gmatch("([^a-zA-Z]+)") do 
				table.insert(memory, word)
			end
			node[i]["memory"] = tonumber(memory[1])/1500000
			
			
		end
	--[[ Counts the amount of nodes ]]
		for n=1, table.Count(node) do
			local z = node[n]["z"]
			--[[ Loops through the amount of ranges ]]
			for i=1, table.Count(rangeTableX) do
				rangeTableX[i] = rangeTableX[i] * node[n]["memory"]
				rangeTableY[i] = rangeTableY[i] * node[n]["memory"]
				xS = node[n]["x"] + (rangeTableX[i])
				yS = node[n]["y"] + (rangeTableY[i])
				--[[ Loops to put two blocks on top of each other ]]
				for j=1, 2 do 
					local ent = ents.Create("prop_physics")
					local vec = Vector(xS, yS, z)
					ent:SetModel("models/hunter/blocks/cube1x1x1.mdl")
					ent:SetPos(vec)
					ent:Spawn()
					ent:DropToFloor()
				--[[ ends 1-2 for ]]
				end
			--[[ ends ranges loop ]]	
			end
		end
		hook.Call("ThisTest")
		print("past hook call")
	end
end
	
	--[[ Fetches the amount of nodes from nodes.lua ]]


--[[ Spawn the nodes area from nodes.lua file in /includes/modules ]]
fenceSpawn()
--[[ main() ]]
timer.Create("Main()", 5, 0, Main)

local textoutput = {
	["stfu"] = {
		pos = Vector(-2680.464355, -2416.205078, -150.402771),
		{r = 0, g = 255, b = 255, a = 255, size = 100, Text = "Welcome to SammyServers!"},
		{r = 33, g = 255, b = 0, a = 255, size = 100, Text = "Enjoy your stay!"},
		{r = 0, g = 255, b = 255, a = 255, size = 100, Text = " "},
		{r = 255, g = 96, b = 0, a = 255, size = 100, Text = "Visit us online at SammyServers.com"},
	}
}

hook.Add("ThisTest", "SpawnWelcomeSigns", function()
	local textscreen = ents.Create("sammyservers_textscreen")
	print("hook called")
	print(textscreen)
	textscreen:SetPos(Vector(0,3000,-12730))
	textscreen:SetAngles(Angle(0,0,90))
	textscreen:Spawn()
	textscreen:Activate()
	textscreen:SetMoveType(MOVETYPE_NONE)
	entsE = ents.GetAll()
		for i=1, table.Count(entsE) do
			if entsE[i]:GetClass() == "sammyservers_textscreen" then
				print(entsE[i]:GetName())
			end
		end
	for k,v in pairs(textoutput["stfu"]) do
		if type(v) != "table" then continue end
		for _,o in pairs(v) do
			if _ == "Text" then
				textscreen:SetNWString(_..k, o)
				print(o)
			else
				textscreen:SetNWInt(_..k, o)
			end
		end
		
	end
end)
