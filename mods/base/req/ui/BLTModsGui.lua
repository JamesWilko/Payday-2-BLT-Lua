
BLT:Require("req/ui/BLTUIControls")
BLT:Require("req/ui/BLTModItem")
BLT:Require("req/ui/BLTViewModGui")

BLTModsGui = BLTModsGui or class( MenuGuiComponentGeneric )

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

function BLTModsGui:init( ws, fullscreen_ws, node )

	self._ws = ws
	self._fullscreen_ws = fullscreen_ws
	self._fullscreen_panel = self._fullscreen_ws:panel():panel({})
	self._panel = self._ws:panel():panel({})
	self._init_layer = self._ws:panel():layer()

	self._data = node:parameters().menu_component_data or {}
	self._buttons = {}

	self:_setup()

end

function BLTModsGui:close()
	self._ws:panel():remove( self._panel )
	self._fullscreen_ws:panel():remove( self._fullscreen_panel )
end

function BLTModsGui:_setup()

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

	-- Title
	local title = self._panel:text({
		name = "title",
		x = padding,
		y = padding,
		font_size = large_font_size,
		font = large_font,
		h = large_font_size,
		layer = 10,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = "Installed Mods",
		align = "left",
		vertical = "top",
	})

	-- Mods scroller
	local scroll_panel = self._panel:panel({
		h = self._panel:h() - large_font_size,
		y = large_font_size,
	})
	self._scroll = ScrollablePanel:new( scroll_panel, "mods_scroll", {} )

	-- Create download manager button
	local icon, rect = tweak_data.hud_icons:get_icon_data( "csb_pagers" )
	local button = BLTUIButton:new( self._scroll:canvas(), {
		x = 0,
		y = 0,
		w = (self._scroll:canvas():w() - (BLTModItem.layout.x + 1) * padding) / BLTModItem.layout.x,
		h = 256,
		title = "Download Manager",
		text = "Update your BLT Mods.\nFor the love of god update your mods.",
		image = icon,
		image_size = 108,
		texture_rect = rect,
		callback = callback( self, self, "clbk_open_download_manager" )
	} )
	table.insert( self._buttons, button )

	-- Create mod boxes
	for i, mod in ipairs( BLT.Mods:Mods() ) do
		local item = BLTModItem:new( self._scroll:canvas(), i + 1, mod )
		table.insert( self._buttons, item )
	end

	-- Update scroll size
	self._scroll:update_canvas_size()

end

function BLTModsGui:inspecting_mod()
	return self._inspecting
end

function BLTModsGui:clbk_open_download_manager()
	managers.menu:open_node( "blt_download_manager" )
end

--------------------------------------------------------------------------------

function BLTModsGui:mouse_moved( button, x, y )

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

function BLTModsGui:mouse_pressed( button, x, y )
	
	if managers.menu_scene and managers.menu_scene:input_focus() then
		return false
	end

	for _, item in ipairs( self._buttons ) do
		if item:inside( x, y ) then

			if item.mod then
				self._inspecting = item:mod()
				managers.menu:open_node( "view_blt_mod" )
				managers.menu_component:post_event( "menu_enter" )
			elseif item.parameters then
				local clbk = item:parameters().callback
				if clbk then
					clbk()
				end
			end

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

--------------------------------------------------------------------------------
-- Patch MenuComponentManager to create the BLT Mods component

Hooks:Add("MenuComponentManagerInitialize", "BLTModsGui.MenuComponentManagerInitialize", function(menu)
	menu._active_components["blt_mods"] = { create = callback(menu, menu, "create_blt_mods_gui"), close = callback(menu, menu, "close_blt_mods_gui") }
end)

function MenuComponentManager:blt_mods_gui()
	return self._blt_mods_gui
end

function MenuComponentManager:create_blt_mods_gui( node )
	if not node then
		return
	end
	self._blt_mods_gui = self._blt_mods_gui or BLTModsGui:new( self._ws, self._fullscreen_ws, node )
	self:register_component( "blt_mods_gui", self._blt_mods_gui )
end

function MenuComponentManager:close_blt_mods_gui()
	if self._blt_mods_gui then
		self._blt_mods_gui:close()
		self._blt_mods_gui = nil
		self:unregister_component( "blt_mods_gui" )
	end
end
