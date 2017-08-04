
BLTKeybind = BLTKeybind or class()
BLTKeybind.StateMenu = 1
BLTKeybind.StateGame = 2

function BLTKeybind:init( parent_mod, parameters )

	self._mod = parent_mod

	self._id = parameters.id
	self._key = {}
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

function BLTKeybind:SetKey( key, force )
	if force then
		self:_SetKey( force, key )
	elseif managers and managers.menu then
		if managers.menu:is_pc_controller() then
			self:_SetKey( "pc", key )
		else
			self:_SetKey( "controller", key )
		end
	end
end

function BLTKeybind:_SetKey( idx, key )
	if not idx then
		return false
	end
	log(string.format("[Keybind] Bound %s to %s", tostring(self:Id()), tostring(key)))
	self._key[idx] = key
end

function BLTKeybind:Key()
	if managers and managers.menu then
		if managers.menu:is_pc_controller() then
			return self._key.pc
		else
			return self._key.controller
		end
	else
		return self._key.pc
	end
end

function BLTKeybind:Keys()
	return self._key
end

function BLTKeybind:HasKey()
	return (self:Key() and self:Key() ~= "")
end

function BLTKeybind:File()
	return self._file
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

function BLTKeybind:AllowExecutionInMenu()
	return self._allow_menu
end

function BLTKeybind:AllowExecutionInGame()
	return self._allow_game
end

function BLTKeybind:CanExecuteInState( state )
	if state == BLTKeybind.StateMenu then
		return self:AllowExecutionInMenu()
	elseif state == BLTKeybind.StateMenu then
		return self:AllowExecutionInGame()
	end
	return false
end

function BLTKeybind:Execute()
	local path = Application:nice_path( self:ParentMod():GetPath() .. "/" .. self:File(), false )
	dofile( path )
end

function BLTKeybind:__tostring()
	return "[BLTKeybind " .. tostring(self:Id()) .. " | " .. (self:HasKey() and "[unbound]" or tostring(self:Key())) .. " => " .. tostring(self:File()) .. "]"
end

--------------------------------------------------------------------------------

BLTKeybindsManager = BLTKeybindsManager or class( BLTModule )
BLTKeybindsManager.__type = "BLTKeybindsManager"

function BLTKeybindsManager:init()
	BLTKeybindsManager.super.init( self )
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

Hooks:Add("CustomizeControllerOnKeySet", "CustomizeControllerOnKeySet.BLTKeybindsManager", function( connection_name, button )
	local bind = BLT.Keybinds:get_keybind( connection_name )
	if bind then
		bind:SetKey( button )
	end
end)

--------------------------------------------------------------------------------
-- Run keybinds

function BLTKeybindsManager:update( t, dt, state )

	-- Create inputs if needed
	if not self._input_keyboard then
		self._input_keyboard = Input:keyboard()
	end
	if not self._input_mouse then
		self._input_mouse = Input:mouse()
	end

	-- Don't run while chatting
	if managers and managers.hud and managers.hud:chat_focus() then
		return
	end
	
	-- Run keybinds
	for _, bind in ipairs( self:keybinds() ) do
		if bind:HasKey() and bind:CanExecuteInState( state ) then

			local key = bind:Key()
			if string.find(key, "mouse ") ~= nil then
				key_pressed = self._input_mouse:pressed( key:sub(7) )
			else
				key_pressed = self._input_keyboard:pressed( Idstring(key) )
			end
			if key_pressed then
				bind:Execute()
			end

		end
	end

end

Hooks:Add("MenuUpdate", "Base_Keybinds_MenuUpdate", function( t, dt )
	BLT.Keybinds:update( t, dt, BLTKeybind.StateMenu )
end)

Hooks:Add("GameSetupUpdate", "Base_Keybinds_GameStateUpdate", function( t, dt )
	BLT.Keybinds:update( t, dt, BLTKeybind.StateGame )
end)

--------------------------------------------------------------------------------
-- Save/Load for the manager

function BLTKeybindsManager:save( cache )

	cache.keybinds = {}

	for _, bind in ipairs( self:keybinds() ) do
		if bind:Key() ~= "" then

			local data = {
				id = bind:Id()
			}
			for id, key in pairs( bind:Keys() ) do
				data[id] = key
			end
			table.insert( cache.keybinds, data )

		end
	end

end

function BLTKeybindsManager:load( cache )

	if cache.keybinds then
		for _, bind_data in ipairs( cache.keybinds ) do

			local bind = self:get_keybind( bind_data.id )
			if bind then
				for idx, key in pairs( bind_data ) do
					if idx ~= "id" then
						bind:SetKey( key, idx )
					end
				end
			end

		end
	end

end

Hooks:Add("BLTOnSaveData", "BLTOnSaveData.BLTKeybindsManager", function( cache )
	BLT.Keybinds:save( cache )
end)

Hooks:Add("BLTOnLoadData", "BLTOnLoadData.BLTKeybindsManager", function( cache )
	BLT.Keybinds:load( cache )
end)

--------------------------------------------------------------------------------
-- MenuInitiator for the keybinds menu which adds all the existing binds

BLTKeybindMenuInitiator = BLTKeybindMenuInitiator or class()
function BLTKeybindMenuInitiator:modify_node( node )

	-- Clear all previous keybinds
	node:clean_items()

	-- Add node items for each keybind
	local last_mod
	for i, bind in ipairs( BLT.Keybinds:keybinds() ) do

		-- Seperate keybinds by mod
		if last_mod and last_mod ~= bind:ParentMod() then
			self:create_divider( node, tostring(i) )
		end
		last_mod = bind:ParentMod()

		-- Create the keybind
		local data_node = {
			type = "MenuItemCustomizeController",
		}

		local params = {
			name = bind:Id(),
			text_id = bind:Name(),
			help_id = bind:Description(),
			connection_name = bind:Id(),
			binding = bind:Key(),
			button = bind:Id(),
			localize = false,
			localize_help = false,
		}

		local new_item = node:create_item( data_node, params )
		node:add_item( new_item )

	end

	-- Add back button
	self:add_back_button( node )
	return node

end

function BLTKeybindMenuInitiator:refresh_node( node )
	self:modify_node( node )
end

function BLTKeybindMenuInitiator:create_item( node, params )
	local data_node = {}
	local new_item = node:create_item( data_node, params )
	new_item:set_enabled( params.enabled )
	node:add_item( new_item )
end

function BLTKeybindMenuInitiator:create_divider( node, id, text_id, size, color )

	local params = {
		name = "divider_" .. id,
		no_text = not text_id,
		text_id = text_id,
		size    = size or 8,
		color   = color,
	}
	
	local data_node = { type = "MenuItemDivider" }
	local new_item = node:create_item( data_node, params )
	node:add_item( new_item )

end

function BLTKeybindMenuInitiator:add_back_button( node )
	node:delete_item( "back" )
	local params = {
		name = "back",
		text_id = "menu_back",
		visible_callback = "is_pc_controller",
		back = true,
		align = "right",
		previous_node = true,
	}
	local new_item = node:create_item( nil, params )
	node:add_item( new_item )
end
