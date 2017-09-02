
BLTDownloadManagerGui = BLTDownloadManagerGui or blt_class( MenuGuiComponentGeneric )

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

function BLTDownloadManagerGui:init( ws, fullscreen_ws, node )

	self._ws = ws
	self._fullscreen_ws = fullscreen_ws
	self._fullscreen_panel = self._fullscreen_ws:panel():panel({})
	self._panel = self._ws:panel():panel({})
	self._init_layer = self._ws:panel():layer()

	self._data = node:parameters().menu_component_data or {}
	self._buttons = {}
	self._downloads_map = {}

	self:_setup()

end

function BLTDownloadManagerGui:close()
	self._ws:panel():remove( self._panel )
	self._fullscreen_ws:panel():remove( self._fullscreen_panel )
	BLT.Downloads:flush_complete_downloads()
end

function BLTDownloadManagerGui:_setup()

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
		text = managers.localization:text("blt_download_manager"),
		align = "left",
		vertical = "top",
	})

	-- Download scroll panel
	local scroll_panel = self._panel:panel({
		h = self._panel:h() - large_font_size - back_button:h() - padding * 2,
		y = large_font_size + padding,
	})
	BoxGuiObject:new( scroll_panel:panel({layer=100}), { sides = { 1, 1, 1, 1 } })
	BoxGuiObject:new( scroll_panel:panel({layer=100}), { sides = { 1, 1, 2, 2 } })

	self._scroll = ScrollablePanel:new( scroll_panel, "downloads_scroll", {} )

	-- Add download items
	local h = 80
	for i, download in ipairs( BLT.Downloads:pending_downloads() ) do

		local data = {
			y = (h + padding) * (i - 1),
			w = self._scroll:canvas():w(),
			h = h,
			update = download.update,
		} 
		local button = BLTDownloadControl:new( self._scroll:canvas(), data )
		table.insert( self._buttons, button )

		self._downloads_map[ download.update:GetId() ] = button

	end

	local num_downloads = table.size( BLT.Downloads:pending_downloads() )
	if num_downloads > 0 then
		local w, h = 80, 80
		local button = BLTUIButton:new( self._scroll:canvas(), {
			x = self._scroll:canvas():w() - w,
			y = (h + padding) * num_downloads,
			w = w,
			h = h,
			text = managers.localization:text("blt_download_all"),
			center_text = true,
			callback = callback( self, self, "clbk_download_all" )
		} )
		table.insert( self._buttons, button )
	end

	-- Update scroll
	self._scroll:update_canvas_size()

end

function BLTDownloadManagerGui:clbk_download_all()
	BLT.Downloads:download_all()
end

--------------------------------------------------------------------------------

function BLTDownloadManagerGui:update( t, dt )

	for _, download in ipairs( BLT.Downloads:downloads() ) do
		local id = download.update:GetId()
		local button = self._downloads_map[ id ]
		if button then
			button:update_download( download )
		end
	end

end

function BLTDownloadManagerGui:mouse_clicked( o, button, x, y )

	for _, item in ipairs( self._buttons ) do
		if item:inside( x, y ) then
			if item:parameters().callback then
				item:parameters().callback()
			end
			if item.mouse_clicked then
				item:mouse_clicked( button, x, y )
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

function BLTDownloadManagerGui:mouse_moved( button, x, y )

	if managers.menu_scene and managers.menu_scene:input_focus() then
		return false
	end

	local used, pointer

	for _, item in ipairs( self._buttons ) do
		if item.mouse_moved then
			item:mouse_moved( button, x, y )
		end
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

function BLTDownloadManagerGui:mouse_wheel_up( x, y )
	if alive(self._scroll) then
		self._scroll:scroll( x, y, 1 )
	end
end

function BLTDownloadManagerGui:mouse_wheel_down( x, y )
	if alive(self._scroll) then
		self._scroll:scroll( x, y, -1 )
	end
end

--------------------------------------------------------------------------------
-- Patch MenuComponentManager to create the BLT Download Manager component

Hooks:Add("MenuComponentManagerInitialize", "BLTDownloadManagerGui.MenuComponentManagerInitialize", function(menu)
	menu._active_components["blt_download_manager"] = { create = callback(menu, menu, "create_blt_downloads_gui"), close = callback(menu, menu, "close_blt_downloads_gui") }
end)

function MenuComponentManager:blt_downloads_gui()
	return self._blt_downloads_gui
end

function MenuComponentManager:create_blt_downloads_gui( node )
	if not node then
		return
	end
	self._blt_downloads_gui = self._blt_downloads_gui or BLTDownloadManagerGui:new( self._ws, self._fullscreen_ws, node )
	self:register_component( "blt_downloads_gui", self._blt_downloads_gui )
end

function MenuComponentManager:close_blt_downloads_gui()
	if self._blt_downloads_gui then
		self._blt_downloads_gui:close()
		self._blt_downloads_gui = nil
		self:unregister_component( "blt_downloads_gui" )
	end
end
