
BLTKeybind = BLTKeybind or class()

function BLTKeybind:init( parent_mod, parameters )

	self._mod = parent_mod

	self._id = parameters.id
	self._key = parameters.key or ""
	self._file = parameters.file

	self._allow_menu = parameters.allow_menu or false
	self._allow_game = parameters.allow_game or false

	self._name = parameters.name or false
	self._desc = parameters.desc or false
	self._localize = parameters.localize or false

end

function BLTKeybind:ParentMod()
	return self._mod
end

function BLTKeybind:Id()
	return self._id
end

function BLTKeybind:SetKey( key )
	self._key = key
end

function BLTKeybind:Key()
	return self._key
end

function BLTKeybind:File()
	return self._file
end

function BLTKeybind:AllowExecutionInMenu()
	return self._allow_menu
end

function BLTKeybind:AllowExecutionInGame()
	return self._allow_game
end

function BLTKeybind:Name()
	if not self._name then
		return managers.localization:text( "blt_no_name" )
	end
	if self:IsLocalized() then
		return managers.localization:text( self._name )
	else
		return self._name
	end
end

function BLTKeybind:Description()
	if not self._desc then
		return managers.localization:text( "blt_no_desc" )
	end
	if self:IsLocalized() then
		return managers.localization:text( self._desc )
	else
		return self._desc
	end
end

function BLTKeybind:IsLocalized()
	return self._localize
end

function BLTKeybind:__tostring()
	return "[BLTKeybind " .. tostring(self:Id()) .. " | " .. (self:Key() == "" and "[unbound]" or self:Key()) .. " => " .. tostring(self:File()) .. "]"
end

--------------------------------------------------------------------------------

BLTKeybindsManager = BLTKeybindsManager or class( BLTModule )
BLTKeybindsManager.__type = "BLTKeybindsManager"

function BLTKeybindsManager:init()
	self._keybinds = {}
end

function BLTKeybindsManager:register_keybind( mod, json_data )

	local parameters = {
		id = json_data["keybind_id"],
		file = json_data["script_path"],
		allow_menu = json_data["run_in_menu"],
		allow_game = json_data["run_in_game"],
		name = json_data["name"],
		desc = json_data["description"],
		localize = json_data["localized"],
	}
	local bind = BLTKeybind:new( mod, parameters )
	table.insert( self._keybinds, bind )

	log("[Keybind] Registered keybind " .. tostring(bind))

end

function BLTKeybindsManager:keybinds()
	return self._keybinds
end

function BLTKeybindsManager:has_keybinds()
	return table.size( self:keybinds() ) > 0
end

function BLTKeybindsManager:get_keybind( id )
	for _, bind in ipairs( self._keybinds ) do
		if bind:Id() == id then
			return bind
		end
	end
end

--------------------------------------------------------------------------------

function BLTKeybindsManager:save( cache )

	cache.keybinds = {}

	for _, bind in ipairs( self:keybinds() ) do
		if bind:Key() ~= "" then
			table.insert( cache.keybinds, {
				id = bind:Id(),
				key = bind:Key()
			} )
		end
	end

end

function BLTKeybindsManager:load( cache )

	if cache.keybinds then

		for _, bind_data in ipairs( cache.keybinds ) do
			local bind = self:get_keybind( bind_data.id )
			bind:SetKey( bind_data.key )
		end

	end

end

Hooks:Add("BLTOnSaveData", "BLTOnSaveData.BLTKeybindsManager", function( cache )
	BLT.Keybinds:save( cache )
end)

Hooks:Add("BLTOnLoadData", "BLTOnLoadData.BLTKeybindsManager", function( cache )
	BLT.Keybinds:load( cache )
end)
