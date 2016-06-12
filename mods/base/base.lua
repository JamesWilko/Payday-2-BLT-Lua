
-- Create our console
if false then
	console.CreateConsole()
end

-- Only run if we have the global table
if not _G then
	return
end

-- Localise globals
local _G = _G
local io = io
local file = file
_G.BLTBase = {}

-- Load Mod Manager
if not _G.LuaModManager then
	dofile("mods/base/req/lua_mod_manager.lua")
end
local C = LuaModManager.Constants

-- Load JSON and modules
if not _G.json then
	for index, path in ipairs( C.json_modules ) do
		dofile( C.mods_directory .. C.lua_base_directory .. path )
	end
end
dofile( C.mods_directory .. C.lua_base_directory .. "req/io_extension.lua" )

-- Set logs and saves paths
rawset(_G, C.logs_path_global, C.mods_directory .. C.logs_directory)
rawset(_G, C.save_path_global, C.mods_directory .. C.saves_directory)

-- BLT base functions
function BLTBase:Initialize()

	-- Create hook tables
	self.hook_tables = {
		pre = {},
		post = {},
		wildcards = {}
	}

	-- Run initialization
	self:OverrideRequire()
	self:LoadSavedModList()
	LuaModManager.Mods = self:ProcessModsList( self:FindMods() )

end

function BLTBase:GetOS()
	return os.getenv("HOME") == nil and "windows" or "linux"
end

function BLTBase:RunHookTable( hooks_table, path )
	if not hooks_table or not hooks_table[path] then
		return false
	end
	for k, v in pairs( hooks_table[path] ) do
		self:RunHookFile( path, v.mod_path, v.script )
	end
end

function BLTBase:RunHookFile( path, mod, script )
	rawset(_G, C.required_script_global, path or false)
	rawset(_G, C.mod_path_global, mod or false)
	dofile( script )
end

function BLTBase:OverrideRequire()

	if self.require then
		return false
	end

	-- Cache original require function
	self.require = _G.require

	-- Override require function to run hooks
	_G.require = function( path )

		local path_lower = path:lower()
		local require_result = nil

		self:RunHookTable( self.hook_tables.pre, path_lower )
		require_result = self.require( path )
		self:RunHookTable( self.hook_tables.post, path_lower )

		for k, v in ipairs( self.hook_tables.wildcards ) do
			self:RunHookFile( path, v.mod_path, v.script )
		end

		return require_result

	end

end

function BLTBase:LoadSavedModList()
	if not self._loaded_mod_manager then
		LuaModManager:Load()
		self._loaded_mod_manager = true
	end
end

function BLTBase:FindMods()

	local log = function(str)
		log(string.format("[Mods] %s", str))
	end

	log(string.format("Loading mods for state (%s)", tostring(_G)))

	local mods_list = {}
	local folders = file.GetDirectories( C.mods_directory )

	if not folders then
		return {}
	end

	for k, v in pairs( folders ) do

		if not C.excluded_mods_directories[v] then

			log(string.format("Loading mod: %s...", tostring(v)))

			local mod_path = C.mods_directory .. v .. "/"
			local mod_def_file = mod_path .. C.mod_definition_file
			local is_readable = io.file_is_readable and io.file_is_readable(mod_def_file) or false
			if is_readable then

				local file = io.open(mod_def_file)
				if file then

					local file_contents = file:read("*all")
					file:close()

					local mod_content = nil
					local json_success = pcall(function()
						mod_content = json.decode(file_contents)
					end)

					if json_success and mod_content then
						local data = {
							path = mod_path,
							definition = mod_content,
							priority = tonumber(mod_content.priority) or 0,
						}
						table.insert( mods_list, data )
					else
						log(string.format("An error occured while loading mod.txt from: %s", tostring(mod_path)))
					end

				end

			else
				log(string.format("Could not read or find %s for modification: %s", tostring(C.mod_definition_file), tostring(v)))
			end

		end

	end

	return mods_list

end

function BLTBase:ProcessModsList( mods_list )

	-- Prioritize
	table.sort( mods_list, function(a, b)
		return a.priority > b.priority
	end)

	-- Add mod hooks to tables
	for index, mod in ipairs( mods_list ) do

		if LuaModManager:IsModEnabled( mod.path ) and LuaModManager:HasRequiredMod( mod ) then

			-- Load pre- and post- hooks
			self:_AddHooksTable( mod, C.mod_hooks_key, self.hook_tables.post )
			self:_AddHooksTable( mod, C.mod_prehooks_key, self.hook_tables.pre )

			-- Load persist scripts
			self:_AddPersistScript( mod )

			-- Load keybinds
			self:_AddKeybindScript( mod )

			-- Load updates
			self:_AddUpdate( mod )

		else
			log(string.format("[Mods] Mod '%s' is disabled!", mod.path))
		end

	end

	return mods_list

end

function BLTBase:_AddUpdate( mod )

	local updates = mod.definition[C.mod_update_key]
	if updates then
		for k, update in pairs( updates ) do
			LuaModManager:AddUpdateCheck( mod.definition, mod.path, update )
		end
	end

end

function BLTBase:_AddHooksTable( mod, table_key, destination_table )

	local hooks = mod.definition[table_key]
	if hooks then

		for i, hook in pairs( hooks ) do
			local hook_id = hook[ C.mod_hook_id_key ]
			local script = hook[ C.mod_script_path_key ]
			if hook_id and script then

				hook_id = hook_id:lower()
				local tbl = {
					mod_path = mod.path,
					script = mod.path .. script
				}

				if hook_id ~= C.mod_hook_wildcard_key then
					destination_table[ hook_id ] = destination_table[ hook_id ] or {}
					table.insert( destination_table[ hook_id ], tbl )
				else
					table.insert( self.hook_tables.wildcards, tbl )
				end

			end
		end

	end

end

function BLTBase:_AddPersistScript( mod )

	local persists = mod.definition[C.mod_persists_key]
	if persists then
		for k, v in pairs( persists ) do
			LuaModManager:AddPersistScript( v, mod.path )
		end
	end

end

function BLTBase:_AddKeybindScript( mod )

	local keybinds = mod.definition[C.mod_keybinds_key]
	if keybinds then
		for k, v in pairs( keybinds ) do
			LuaModManager:AddJsonKeybinding( v, mod.path )
		end
	end

end

-- Perform startup
BLTBase:Initialize()
