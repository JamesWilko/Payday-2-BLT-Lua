
--[[
Hooks:Add( "MenuUpdate", "MenuUpdate_Base_UpdatePersistScripts", function(t, dt)
	LuaModManager:UpdatePersistScripts()
end )

Hooks:Add( "GameSetupUpdate", "GameSetupUpdate_Base_UpdatePersistScripts", function(t, dt)
	LuaModManager:UpdatePersistScripts()
end )

function LuaModManager:UpdatePersistScripts()

	for k, v in pairs( LuaModManager:PersistScripts() ) do

		local global = v[ C.mod_persists_global_key ]
		local script = v[ C.mod_script_path_key ]
		local path = v[ C.mod_persists_path_key ]
		local exists = _G[global]

		if not exists then
			rawset(_G, "PersistScriptPath", path)
			dofile( script )
		end
		
	end
	rawset(_G, "PersistScriptPath", nil)

end
]]
