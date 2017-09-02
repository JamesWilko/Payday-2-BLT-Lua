
BLTModItem = BLTModItem or blt_class()

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

BLTModItem.layout = {
	x = 4,
	y = 4,
}
BLTModItem.image_size = 108

function BLTModItem:init( panel, index, mod )

	local w = (panel:w() - (self.layout.x + 1) * padding) / self.layout.x
	local h = 256
	local column, row = self:_get_col_row( index )

	self._mod = mod

	local bg_color = mod:GetColor()
	local text_color = tweak_data.screen_colors.title
	if mod:LastError() then
		bg_color = tweak_data.screen_colors.important_1
		text_color = tweak_data.screen_colors.important_1
	end

	-- Main panel
	self._panel = panel:panel({
		x = (w + padding) * (column - 1),
		y = (h + padding) * (row - 1),
		w = w,
		h = h,
		layer = 10
	})

	-- Background
	self._background = self._panel:rect({
		color = bg_color,
		alpha = 0.2,
		blend_mode = "add",
		layer = -1
	})
	BoxGuiObject:new( self._panel, { sides = { 1, 1, 1, 1 } } )

	self._panel:bitmap({
		texture = "guis/textures/test_blur_df",
		w = self._panel:w(),
		h = self._panel:h(),
		render_template = "VertexColorTexturedBlur3D",
		layer = -1,
		halign = "scale",
		valign = "scale"
	})

	-- Mod name
	local mod_name = self._panel:text({
		name = "mod_name",
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		blend_mode = "add",
		color = text_color,
		text = mod:GetName(),
		align = "center",
		vertical = "top",
		wrap = true,
		word_wrap = true,
		w = self._panel:w() - padding * 2,
	})
	make_fine_text( mod_name )
	mod_name:set_center_x( self._panel:w() * 0.5 )
	mod_name:set_top( self._panel:h() * 0.5 )

	-- Mod description
	local mod_desc = self._panel:text({
		name = "mod_desc",
		font_size = small_font_size,
		font = small_font,
		layer = 10,
		blend_mode = "add",
		color = text_color,
		text = string.sub( mod:GetDescription(), 1, 120 ),
		align = "left",
		vertical = "top",
		wrap = true,
		word_wrap = true,
		w = self._panel:w() - padding * 2,
	})
	make_fine_text( mod_desc )
	mod_desc:set_center_x( self._panel:w() * 0.5 )
	mod_desc:set_top( mod_name:bottom() + 5 )

	-- Mod image
	local image_path
	if mod:HasModImage() then
		image_path = mod:GetModImage()
	end

	if image_path then
		local image = self._panel:bitmap({
			name = "image",
			texture = image_path,
			color = Color.white,
			layer = 10,
			w = BLTModItem.image_size,
			h = BLTModItem.image_size,
		})
		image:set_center_x( self._panel:w() * 0.5 )
		image:set_top( padding )
	else

		local no_image_panel = self._panel:panel({
			w = BLTModItem.image_size,
			h = BLTModItem.image_size,
			layer = 10
		})
		no_image_panel:set_center_x( self._panel:w() * 0.5 )
		no_image_panel:set_top( padding )

		BoxGuiObject:new( no_image_panel, { sides = { 1, 1, 1, 1 } } )

		local no_image_text = no_image_panel:text({
			name = "no_image_text",
			font_size = small_font_size,
			font = small_font,
			layer = 10,
			blend_mode = "add",
			color = tweak_data.screen_colors.title,
			text = "No Image",
			align = "center",
			vertical = "center",
			w = no_image_panel:w(),
			h = no_image_panel:h()
		})

	end

	-- Mod settings
	local icon_size = 32
	local icon_y = padding

	if not mod:IsUndisablable() then

		local icon, rect = tweak_data.hud_icons:get_icon_data( "csb_locks" )
		local icon_enabled = self._panel:bitmap({
			name = "",
			texture = icon,
			texture_rect = rect,
			color = Color.white,
			alpha = 1,
			layer = 10,
			w = icon_size,
			h = icon_size,
		})
		icon_enabled:set_left( padding )
		icon_enabled:set_top( icon_y )
		icon_y = icon_y + icon_size + 4

		if mod:WasEnabledAtStart() then
			icon_enabled:set_alpha( mod:IsEnabled() and 1 or 0.4 )
		else
			icon_enabled:set_alpha( mod:IsEnabled() and 1 or 0.4 )
			icon_enabled:set_color( mod:IsEnabled() and Color.yellow or Color.white )
		end

	end

	if mod:HasUpdates() then

		local icon, rect = tweak_data.hud_icons:get_icon_data( "csb_pagers" )
		local icon_updates = self._panel:bitmap({
			name = "",
			texture = icon,
			texture_rect = rect,
			color = Color.white,
			alpha = mod:AreUpdatesEnabled() and 1 or 0.4,
			layer = 10,
			w = icon_size,
			h = icon_size,
		})
		icon_updates:set_left( padding )
		icon_updates:set_top( icon_y )

	end

end

function BLTModItem:_get_col_row( index )
	local column = 1
	local row = 1
	for i = 1, index - 1 do
		column = column + 1
		if column > self.layout.x then
			row = row + 1
			column = 1
		end
	end
	return column, row
end

function BLTModItem:inside( x, y )
	return self._panel:inside( x, y )
end

function BLTModItem:mod()
	return self._mod
end

function BLTModItem:set_highlight( enabled, no_sound )
	if self._enabled ~= enabled then
		self._enabled = enabled
		self._background:set_alpha( enabled and 0.4 or 0.2 )
		if enabled and not no_sound then
			managers.menu_component:post_event( "highlight" )
		end
	end
end
