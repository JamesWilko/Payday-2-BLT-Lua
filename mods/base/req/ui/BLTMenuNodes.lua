
Hooks:Register( "BLTOnBuildOptions" )

-- Add the menu nodes for various menus
Hooks:Add("CoreMenuData.LoadDataMenu", "BLT.CoreMenuData.LoadDataMenu", function( menu )

	-- Create the menu node for BLT mods
	local new_node = {
		_meta = "node",
		name = "blt_mods",
		back_callback = "perform_blt_save close_blt_mods",
		menu_components = "blt_mods",
		scene_state = "crew_management",
		[1] = {
			["_meta"] = "default_item",
			["name"] = "back"
		}
	}
	table.insert( menu, new_node )

	-- Create the menu node for BLT mod options
	local new_node = {
		_meta = "node",
		name = "blt_options",
		back_callback = "perform_blt_save",
		[1] = {
			_meta = "legend",
			name = "menu_legend_select"
		},
		[2] = {
			_meta = "legend",
			name = "menu_legend_back"
		},
		[3] = {
			_meta = "default_item",
			name = "back"
		},
		[4] = {
			_meta = "item",
			name = "back",
			text_id = "menu_back",
			back = true,
			previous_node = true,
			visible_callback = "is_pc_controller"
		}
	}
	table.insert( menu, new_node )

	-- All mods to hook into the options menu to add items
	Hooks:Call( "BLTOnBuildOptions", new_node )

	-- Create the menu node for BLT mod keybinds
	local new_node = {
		_meta = "node",
		name = "blt_keybinds",
		back_callback = "perform_blt_save",
		modifier = "BLTKeybindMenuInitiator",
		refresh = "BLTKeybindMenuInitiator",
		[1] = {
			_meta = "legend",
			name = "menu_legend_select"
		},
		[2] = {
			_meta = "legend",
			name = "menu_legend_back"
		},
		[3] = {
			_meta = "default_item",
			name = "back"
		},
		[4] = {
			_meta = "item",
			name = "back",
			text_id = "menu_back",
			back = true,
			previous_node = true,
			visible_callback = "is_pc_controller"
		}
	}
	table.insert( menu, new_node )

	-- Create the menu node for the download manager
	local new_node = {
		_meta = "node",
		name = "blt_download_manager",
		menu_components = "blt_download_manager",
		back_callback = "close_blt_download_manager",
		scene_state = "crew_management",
		[1] = {
			_meta = "default_item",
			name = "back"
		}
	}
	table.insert( menu, new_node )

	-- Create options menu items
	for _, node in ipairs( menu ) do
		if node.name == "options" then

			-- Insert menu item
			for i, item in ipairs( node ) do
				if item.name == "quickplay_settings" then

					-- Insert items in reverse order
					table.insert( node, i + 1, {
						_meta = "item",
						name = "blt_keybinds",
						text_id = "blt_options_menu_keybinds",
						help_id = "blt_options_menu_keybinds_desc",
						visible_callback = "blt_show_keybinds_item",
						next_node = "blt_keybinds",
					} )

					table.insert( node, i + 1, {
						_meta = "item",
						name = "blt_options",
						text_id = "blt_options_menu_lua_mod_options",
						help_id = "blt_options_menu_lua_mod_options_desc",
						next_node = "blt_options",
					} )

					table.insert( node, i + 1, {
						_meta = "item",
						name = "blt_mods_new",
						text_id = "blt_options_menu_blt_mods",
						help_id = "blt_options_menu_blt_mods_desc",
						next_node = "blt_mods",
					} )

					table.insert( node, i + 1, {
						_meta = "item",
						name = "blt_divider",
						type = "MenuItemDivider",
						no_text = true,
						size = 8,
					} )	

				end
			end

		end
	end

end)
