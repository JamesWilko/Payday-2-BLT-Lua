
BLTViewModGui = BLTViewModGui or blt_class( MenuGuiComponentGeneric )

local padding = 10

local massive_font = tweak_data.menu.pd2_massive_font
local large_font = tweak_data.menu.pd2_large_font
local medium_font = tweak_data.menu.pd2_medium_font
local small_font = tweak_data.menu.pd2_small_font

local massive_font_size = tweak_data.menu.pd2_massive_font_size
local large_font_size = tweak_data.menu.pd2_large_font_size
local medium_font_size = tweak_data.menu.pd2_medium_font_size
local small_font_size = tweak_data.menu.pd2_small_font_size

local function make_fine_text( text )
	local x,y,w,h = text:text_rect()
	text:set_size( w, h )
	text:set_position( math.round( text:x() ), math.round( text:y() ) )
end

function BLTViewModGui:init( ws, fullscreen_ws, node )

	self._ws = ws
	self._fullscreen_ws = fullscreen_ws
	self._fullscreen_panel = self._fullscreen_ws:panel():panel({})
	self._panel = self._ws:panel():panel({})
	self._init_layer = self._ws:panel():layer()

	self._data = node:parameters().menu_component_data or {}
	self._buttons = {}

	self:_setup()

end

function BLTViewModGui:close()
	self._ws:panel():remove( self._panel )
	self._fullscreen_ws:panel():remove( self._fullscreen_panel )
end

function BLTViewModGui:_setup()

	-- Background
	self._background = self._fullscreen_panel:rect({
		color = Color.black,
		alpha = 0.4,
		layer = -1
	})

	-- Back button
	local back_button = self._panel:text({
		name = "back",
		text = managers.localization:text("menu_back"),
		align = "right",
		vertical = "bottom",
		font_size = tweak_data.menu.pd2_large_font_size,
		font = tweak_data.menu.pd2_large_font,
		color = tweak_data.screen_colors.button_stage_3,
		layer = 40,
		blend_mode = "add"
	})
	make_fine_text( back_button )
	back_button:set_right( self._panel:w() - 10 )
	back_button:set_bottom( self._panel:h() - 10 )
	back_button:set_visible( managers.menu:is_pc_controller() )
	self._back_button = back_button

	local bg_back = self._fullscreen_panel:text({
		name = "back_button",
		text = utf8.to_upper( managers.localization:text("menu_back") ),
		h = 90,
		align = "right",
		vertical = "bottom",
		blend_mode = "add",
		font_size = tweak_data.menu.pd2_massive_font_size,
		font = tweak_data.menu.pd2_massive_font,
		color = tweak_data.screen_colors.button_stage_3,
		alpha = 0.4,
		layer = 1
	})
	local x, y = managers.gui_data:safe_to_full_16_9( self._panel:child("back"):world_right(), self._panel:child("back"):world_center_y() )
	bg_back:set_world_right( x )
	bg_back:set_world_center_y( y )
	bg_back:move( 13, -9 )

	-- Create page info
	self._mod = managers.menu_component:blt_mods_gui() and managers.menu_component:blt_mods_gui():inspecting_mod()
	if self._mod then
		self:_setup_mod_info( self._mod )
		self:_setup_dev_info( self._mod )
		self:_setup_buttons( self._mod )
		self:refresh()
	else
		managers.menu:back( true )
	end

end

function BLTViewModGui:_setup_mod_info( mod )

	-- Page title
	local title = self._panel:text({
		name = "title",
		x = padding,
		y = padding,
		font_size = large_font_size,
		font = large_font,
		layer = 10,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = mod:GetName(),
		align = "left",
		vertical = "top",
	})
	make_fine_text( title )
	self._title = title

	local version = self._panel:text({
		name = "version",
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		alpha = 0.6,
		text = mod:GetVersion(),
		align = "left",
		vertical = "top",
	})
	make_fine_text( version )
	version:set_left( title:right() + padding )
	version:set_bottom( title:bottom() - 4 )

	-- Mod info panel
	local info_panel = self._panel:panel({
		x = padding,
		y = padding,
		w = self._panel:w() * 0.5 - padding * 2,
		h = self._panel:h() * 0.4 - padding * 2,
	})
	info_panel:set_top( title:bottom() + padding )
	BoxGuiObject:new( info_panel:panel({ layer = 100 }), { sides = { 1, 1, 1, 1 } } )
	self._info_panel = info_panel

	self._info_panel:rect({
		color = Color.black,
		alpha = 0.4,
		layer = -1
	})
	self._info_panel:bitmap({
		texture = "guis/textures/test_blur_df",
		w = self._info_panel:w(),
		h = self._info_panel:h(),
		render_template = "VertexColorTexturedBlur3D",
		layer = -1,
		halign = "scale",
		valign = "scale"
	})

	-- Load error
	local error_text
	if mod:Errors() then

		-- Build the errors string
		local error_str = ""
		for i, error in ipairs( mod:Errors() ) do
			error_str = error_str .. (i > 1 and "\n" or "") .. managers.localization:text( error )
		end
		error_str = error_str .. "\n"

		-- Append any missing dependencies and if they available
		for _, dependency in ipairs( mod:GetMissingDependencies() ) do
			local loc_str = dependency:GetServerData() and "blt_mod_missing_dependency_download" or "blt_mod_missing_dependency"
			error_str = error_str .. managers.localization:text( loc_str , { dependency = dependency:GetServerName() } ) .. "\n"
		end
		error_str = error_str .. (#mod:GetMissingDependencies() > 0 and "\n" or "")

		for _, dependency_mod in ipairs( mod:GetDisabledDependencies() ) do
			error_str = error_str .. managers.localization:text( "blt_mod_disabled_dependency", { dependency = dependency_mod:GetName() } ) .. "\n"
		end
		error_str = error_str .. (#mod:GetDisabledDependencies() > 0 and "\n" or "")

		-- Create the error text
		error_text = info_panel:text({
			name = "error",
			x = padding,
			y = padding,
			w = info_panel:w() - padding * 2,
			font_size = medium_font_size,
			font = medium_font,
			layer = 10,
			blend_mode = "add",
			color = tweak_data.screen_colors.important_1,
			text = error_str,
			align = "left",
			vertical = "top",
			wrap = true,
			word_wrap = true,
		})
		make_fine_text( error_text )

	end

	-- Mod description
	local desc = info_panel:text({
		name = "desc",
		x = padding,
		y = padding,
		w = info_panel:w() - padding * 2,
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = mod:GetDescription(),
		align = "left",
		vertical = "top",
		wrap = true,
		word_wrap = true,
	})
	make_fine_text( desc )
	if error_text then
		desc:set_top( error_text:bottom() + padding )
	end

	-- Mod author
	local author = info_panel:text({
		name = "author",
		x = padding,
		y = padding,
		w = info_panel:w() - padding * 2,
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = managers.localization:text("blt_mod_info_author") .. ": " .. mod:GetAuthor(),
		align = "left",
		vertical = "top",
		wrap = true,
		word_wrap = true,
	})
	make_fine_text( author )
	author:set_top( desc:bottom() )

	-- Mod contact
	local contact = info_panel:text({
		name = "contact",
		x = padding,
		y = padding,
		w = info_panel:w() - padding * 2,
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = managers.localization:text("blt_mod_info_contact") .. ": " .. mod:GetContact(),
		align = "left",
		vertical = "top",
		wrap = true,
		word_wrap = true,
	})
	make_fine_text( contact )
	contact:set_top( author:bottom() )

end

function BLTViewModGui:_setup_dev_info( mod )

	local dev_panel = self._panel:panel({
		x = padding,
		y = padding,
		w = self._panel:w() * 0.5 - padding * 2,
		h = self._panel:h() - self._info_panel:bottom() - padding * 2,
	})
	dev_panel:set_top( self._info_panel:bottom() + padding )
	BoxGuiObject:new( dev_panel:panel({ layer = 100 }), { sides = { 1, 1, 1, 1 } } )
	self._dev_panel = dev_panel

	self._dev_panel:rect({
		color = Color.black,
		alpha = 0.4,
		layer = -1
	})
	self._dev_panel:bitmap({
		texture = "guis/textures/test_blur_df",
		w = self._dev_panel:w(),
		h = self._dev_panel:h(),
		render_template = "VertexColorTexturedBlur3D",
		layer = -1,
		halign = "scale",
		valign = "scale"
	})

	self._dev_scroll = ScrollablePanel:new( dev_panel, "dev_scroll" )

	local info = self._dev_scroll:canvas():text({
		name = "dev_info",
		x = padding,
		y = padding,
		font_size = small_font_size,
		font = small_font,
		layer = 10,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = mod:GetDeveloperInfo(),
		align = "left",
		vertical = "top",
		wrap = true,
		word_wrap = true,
	})
	make_fine_text( info )

	self._dev_scroll:update_canvas_size()
	self._dev_panel:set_visible( false )

end

function BLTViewModGui:_setup_buttons( mod )

	local buttons_panel = self._panel:panel({
		x = padding,
		y = padding,
		w = self._panel:w() * 0.5 - padding * 2,
		h = self._panel:h() - padding * 2,
	})
	buttons_panel:set_top( self._info_panel:top() )
	buttons_panel:set_left( self._info_panel:right() + padding )

	local button_w = 280
	local button_h = 220
	local btn
	local next_row_height

	if not mod:IsUndisablable() then

		local icon, rect = tweak_data.hud_icons:get_icon_data( "csb_locks" )
		btn = BLTUIButton:new( buttons_panel, {
			x = 0,
			y = 0,
			w = button_w,
			h = button_h,
			title = managers.localization:text("blt_mod_state_enabled"),
			text = managers.localization:text("blt_mod_state_enabled_desc"),
			image = icon,
			image_size = 96,
			texture_rect = rect,
			callback = callback( self, self, "clbk_toggle_enable_state" )
		} )
		table.insert( self._buttons, btn )
		self._enabled_button = btn
		next_row_height = button_h + padding

	end

	if self._mod:HasUpdates() then

		local icon, rect = tweak_data.hud_icons:get_icon_data( "csb_pagers" )
		btn = BLTUIButton:new( buttons_panel, {
			x = 0,
			y = next_row_height or 0,
			w = button_w,
			h = button_h,
			title = managers.localization:text("blt_mod_updates_enabled"),
			text = managers.localization:text("blt_mod_updates_enabled_help"),
			image = icon,
			image_size = 96,
			texture_rect = rect,
			callback = callback( self, self, "clbk_toggle_updates_state" )
		} )
		table.insert( self._buttons, btn )
		self._updates_button = btn

		local icon, rect = tweak_data.hud_icons:get_icon_data( "csb_stamina" )
		btn = BLTUIButton:new( buttons_panel, {
			x = button_w + padding,
			y = next_row_height or 0,
			w = button_w,
			h = button_h,
			title = managers.localization:text("blt_mod_check_for_updates"),
			text = managers.localization:text("blt_mod_check_for_updates_desc"),
			image = icon,
			image_size = 96,
			texture_rect = rect,
			callback = callback( self, self, "clbk_check_for_updates" )
		} )
		table.insert( self._buttons, btn )
		self._check_update_button = btn

		next_row_height = (next_row_height or 0) + button_h + padding

	end

	btn = BLTUIButton:new( buttons_panel, {
		x = 0,
		y = (next_row_height or 0),
		w = button_w,
		h = button_h * 0.5,
		title = managers.localization:text("blt_mod_toggle_dev"),
		text = managers.localization:text("blt_mod_toggle_dev_desc"),
		callback = callback( self, self, "clbk_toggle_dev_info" )
	} )
	table.insert( self._buttons, btn )

end

--------------------------------------------------------------------------------

function BLTViewModGui:mouse_clicked( o, button, x, y )

	for _, item in ipairs( self._buttons ) do
		if item:inside( x, y ) then
			if item:parameters().callback then
				item:parameters().callback()
			end
			managers.menu_component:post_event( "menu_enter" )
			return true
		end
	end

	if alive(self._back_button) and self._back_button:visible() then
		if self._back_button:inside(x, y) then
			managers.menu:back()
			return true
		end
	end

end

function BLTViewModGui:mouse_moved( button, x, y )

	if managers.menu_scene and managers.menu_scene:input_focus() then
		return false
	end

	local used, pointer

	for _, item in ipairs( self._buttons ) do
		if item:inside( x, y ) then
			item:set_highlight( true )
			used, pointer = true, "link"
		else
			item:set_highlight( false )
		end
	end

	if alive(self._back_button) and self._back_button:visible() then
		if self._back_button:inside(x, y) then
			if self._back_button:color() ~= tweak_data.screen_colors.button_stage_2 then
				self._back_button:set_color( tweak_data.screen_colors.button_stage_2 )
				managers.menu_component:post_event( "highlight" )
			end
			used, pointer = true, "link"
		else
			self._back_button:set_color( tweak_data.screen_colors.button_stage_3 )
		end
	end

	return used, pointer

end

function BLTViewModGui:mouse_wheel_up( x, y )
	if alive(self._dev_scroll) then
		self._dev_scroll:scroll( x, y, 1 )
	end
end

function BLTViewModGui:mouse_wheel_down( x, y )
	if alive(self._dev_scroll) then
		self._dev_scroll:scroll( x, y, -1 )
	end
end

function BLTViewModGui:update( t, dt )
	if self._check_update_button and alive(self._check_update_button:image()) and self._mod then
		if self._mod:IsCheckingForUpdates() then
			self._check_update_button:image():set_rotation( self._check_update_button:image():rotation() + dt * 360 )
		else
			self._check_update_button:image():set_rotation( 0 )
		end
	end
end

--------------------------------------------------------------------------------

function BLTViewModGui:clbk_toggle_enable_state()
	self._mod:SetEnabled( not self._mod:IsEnabled() )
	self:refresh()
end

function BLTViewModGui:clbk_toggle_safemode_state()
	self._mod:SetSafeModeEnabled( not self._mod:IsSafeModeEnabled() )
	self:refresh()
end

function BLTViewModGui:clbk_toggle_updates_state()
	self._mod:SetUpdatesEnabled( not self._mod:AreUpdatesEnabled() )
	self:refresh()
end

function BLTViewModGui:clbk_check_for_updates()
	if not self._mod:IsCheckingForUpdates() then
		self._mod:CheckForUpdates( callback(self, self, "clbk_check_for_updates_finished") )
	end
end

function BLTViewModGui:clbk_check_for_updates_finished( cache )

	-- Does this mod need updating
	local requires_update = false
	local error_reason
	for update_id, data in pairs( cache ) do

		-- An update for this mod needs updating
		requires_update = data.requires_update or requires_update

		-- Add the update to the download manager
		if data.requires_update then
			BLT.Downloads:add_pending_download( data.update )
		end

	end

	-- Show updates dialog
	if error_reason then

		local dialog_data = {}
		dialog_data.title = managers.localization:text( "blt_update_mod_title", { name = self._mod:GetName() } )
		dialog_data.text = managers.localization:text( "blt_update_mod_error", { reason = error_reason } )

		local ok_button = {}
		ok_button.text = managers.localization:text( "dialog_ok" )
		ok_button.cancel_button = true

		dialog_data.button_list = { ok_button }
		managers.system_menu:show( dialog_data )

	elseif not requires_update then

		local dialog_data = {}
		dialog_data.title = managers.localization:text( "blt_update_mod_title", { name = self._mod:GetName() } )
		dialog_data.text = managers.localization:text( "blt_update_mod_up_to_date", { name = self._mod:GetName() } )

		local ok_button = {}
		ok_button.text = managers.localization:text( "dialog_ok" )
		ok_button.cancel_button = true

		dialog_data.button_list = { ok_button }
		managers.system_menu:show( dialog_data )

	else
		
		local dialog_data = {}
		dialog_data.title = managers.localization:text( "blt_update_mod_title", { name = self._mod:GetName() } )
		dialog_data.text = managers.localization:text( "blt_update_mod_available", { name = self._mod:GetName() } )

		local download_button = {}
		download_button.text = managers.localization:text( "blt_update_mod_goto_manager" )
		download_button.callback_func = callback( self, self, "clbk_goto_download_manager" )

		local ok_button = {}
		ok_button.text = managers.localization:text( "dialog_ok" )
		ok_button.cancel_button = true

		dialog_data.button_list = { download_button, ok_button }
		managers.system_menu:show( dialog_data )

	end

end

function BLTViewModGui:clbk_goto_download_manager()
	managers.menu:open_node( "blt_download_manager" )
end

function BLTViewModGui:clbk_toggle_dev_info()
	self._dev_panel:set_visible( not self._dev_panel:visible() )
end

function BLTViewModGui:refresh()

	-- Refresh mod enabled button
	if self._enabled_button then
		self._enabled_button:image():set_alpha( self._mod:IsEnabled() and 1 or 0.4 )
		if self._mod:WasEnabledAtStart() then
			if self._mod:IsEnabled() then
				self._enabled_button:title():set_text( managers.localization:text("blt_mod_state_enabled") )
				self._enabled_button:text():set_text( managers.localization:text("blt_mod_state_enabled_desc") )
			else
				self._enabled_button:title():set_text( managers.localization:text("blt_mod_state_disabled_on_restart") )
				self._enabled_button:text():set_text( managers.localization:text("blt_mod_state_disabled_on_restart_desc") )
			end
		else
			if self._mod:IsEnabled() then
				self._enabled_button:title():set_text( managers.localization:text("blt_mod_state_enabled_on_restart") )
				self._enabled_button:text():set_text( managers.localization:text("blt_mod_state_enabled_on_restart_desc") )
			else
				self._enabled_button:title():set_text( managers.localization:text("blt_mod_state_disabled") )
				self._enabled_button:text():set_text( managers.localization:text("blt_mod_state_disabled_desc") )
			end
		end
	end

	-- Refresh safemode
	if self._safemode_button then
		self._safemode_button:image():set_alpha( self._mod:IsSafeModeEnabled() and 1 or 0.4 )
		if self._mod:IsSafeModeEnabled() then
			self._safemode_button:title():set_text( managers.localization:text("blt_mod_safemode_enabled") )
			self._safemode_button:text():set_text( managers.localization:text("blt_mod_safemode_enabled_help") )
		else
			self._safemode_button:title():set_text( managers.localization:text("blt_mod_safemode_disabled") )
			self._safemode_button:text():set_text( managers.localization:text("blt_mod_safemode_disabled_help") )
		end
	end

	-- Refresh automatic updates
	if self._updates_button then
		self._updates_button:image():set_alpha( self._mod:AreUpdatesEnabled() and 1 or 0.4 )
		if self._mod:AreUpdatesEnabled() then
			self._updates_button:title():set_text( managers.localization:text("blt_mod_updates_enabled") )
			self._updates_button:text():set_text( managers.localization:text("blt_mod_updates_enabled_help") )
		else
			self._updates_button:title():set_text( managers.localization:text("blt_mod_updates_disabled") )
			self._updates_button:text():set_text( managers.localization:text("blt_mod_updates_disabled_help") )
		end
	end

end

--------------------------------------------------------------------------------
-- Patch MenuComponentManager to create the BLT Mods component

Hooks:Add("MenuComponentManagerInitialize", "BLTViewModGui.MenuComponentManagerInitialize", function(menu)
	menu._active_components["blt_view_mod"] = { create = callback(menu, menu, "create_blt_view_mod_gui"), close = callback(menu, menu, "close_blt_view_mod_gui") }
end)

function MenuComponentManager:blt_view_mod_gui()
	return self._blt_view_mod_gui
end

function MenuComponentManager:create_blt_view_mod_gui( node )
	if not node then
		return
	end
	self._blt_view_mod_gui = self._blt_view_mod_gui or BLTViewModGui:new( self._ws, self._fullscreen_ws, node )
	self:register_component( "blt_view_mod_gui", self._blt_view_mod_gui )
end

function MenuComponentManager:close_blt_view_mod_gui()
	if self._blt_view_mod_gui then
		self._blt_view_mod_gui:close()
		self._blt_view_mod_gui = nil
		self:unregister_component( "blt_view_mod_gui" )
	end
end

--------------------------------------------------------------------------------
-- Create the menu node for the BLT Mods menu

Hooks:Add("CoreMenuData.LoadDataMenu", "BLTViewModGui.CoreMenuData.LoadDataMenu", function( menu_id, menu )

	if menu_id ~= "start_menu" then
		return
	end

	local new_node = {
		["_meta"] = "node",
		["name"] = "view_blt_mod",
		["menu_components"] = "blt_view_mod",
		["back_callback"] = "perform_blt_save",
		["no_item_parent"] = true,
		["no_menu_wrapper"] = true,
		["scene_state"] = "crew_management",
		[1] = {
			["_meta"] = "default_item",
			["name"] = back
		}
	}
	table.insert( menu, new_node )

end)

