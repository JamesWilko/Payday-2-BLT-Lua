
-- Add the menu nodes for various menus

Hooks:Add("CoreMenuData.LoadDataMenu", "BLT.CoreMenuData.LoadDataMenu", function( menu )

	-- Create the menu node for BLT mods
	local new_node = {
		["_meta"] = "node",
		["name"] = "blt_mods",
		["back_callback"] = "perform_blt_save",
		["menu_components"] = "blt_mods",
		["no_item_parent"] = true,
		["no_menu_wrapper"] = true,
		["scene_state"] = "crew_management",
		[1] = {
			["_meta"] = "default_item",
			["name"] = "back"
		}
	}
	table.insert( menu, new_node )

	-- Create the menu node for BLT mod options
	local new_node = {
		["_meta"] = "node",
		["name"] = "lua_mod_options_menu",
		["back_callback"] = "save_progress",
		["no_item_parent"] = true,
		["no_menu_wrapper"] = true,
		["scene_state"] = "crew_management",
		[1] = {
			["_meta"] = "default_item",
			["name"] = "back"
		}
	}
	table.insert( menu, new_node )

	-- Create the menu node for the download manager
	local new_node = {
		["_meta"] = "node",
		["name"] = "blt_download_manager",
		["back_callback"] = "perform_blt_save",
		["menu_components"] = "blt_download_manager",
		["no_item_parent"] = true,
		["no_menu_wrapper"] = true,
		["scene_state"] = "crew_management",
		[1] = {
			["_meta"] = "default_item",
			["name"] = "back"
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
						["_meta"] = "item",
						["name"] = "blt_options",
						["text_id"] = "base_options_menu_lua_mod_options",
						["help_id"] = "base_options_menu_lua_mod_options_desc",
						["next_node"] = "lua_mod_options_menu",
					} )

					table.insert( node, i + 1, {
						["_meta"] = "item",
						["name"] = "blt_mods_new",
						["text_id"] = "base_options_menu_blt_mods",
						["help_id"] = "base_options_menu_blt_mods_desc",
						["next_node"] = "blt_mods",
					} )

					table.insert( node, i + 1, {
						["_meta"] = "item",
						["name"] = "blt_divider",
						["type"] = "MenuItemDivider",
						["no_text"] = true,
						["size"] = 8,
					} )	

				end
			end

		end
	end

end)
