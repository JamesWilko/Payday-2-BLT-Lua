
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

BLTUIButton = BLTUIButton or class()

function BLTUIButton:init( panel, parameters )

	self._parameters = parameters

	-- Main panel
	self._panel = panel:panel({
		x = parameters.x or 0,
		y = parameters.y or 0,
		w = parameters.w or 128,
		h = parameters.h or 128,
		layer = 10
	})

	-- Background
	self._background = self._panel:rect({
		color =	parameters.color or tweak_data.screen_colors.button_stage_3,
		alpha = 0.4,
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

	local title = self._panel:text({
		name = "title",
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = parameters.title or "",
		align = "center",
		vertical = "top",
		wrap = true,
		word_wrap = true,
		w = self._panel:w() - padding * 2,
	})
	make_fine_text( title )
	title:set_w( self._panel:w() )
	title:set_center_x( self._panel:w() * 0.5 )
	if parameters.image then
		title:set_top( self._panel:h() * 0.5 )
	else
		title:set_bottom( self._panel:h() * 0.5 )
	end

	local desc = self._panel:text({
		name = "desc",
		font_size = small_font_size,
		font = small_font,
		layer = 10,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = parameters.text or "",
		align = "center",
		vertical = "top",
		wrap = true,
		word_wrap = true,
		w = self._panel:w() - padding * 2,
	})
	make_fine_text( desc )
	desc:set_w( self._panel:w() )
	desc:set_center_x( self._panel:w() * 0.5 )
	desc:set_top( title:bottom() + 5 )

	if parameters.image then

		local image = self._panel:bitmap({
			name = "image",
			texture = parameters.image,
			color = Color.white,
			layer = 10,
			w = parameters.image_size or 64,
			h = parameters.image_size or 64,
		})
		image:set_center_x( self._panel:w() * 0.5 )
		image:set_top( padding )
		if parameters.texture_rect then
			image:set_texture_rect( unpack( parameters.texture_rect ) )
		end

	end

end

function BLTUIButton:panel()
	return self._panel
end

function BLTUIButton:title()
	return self._panel:child("title")
end

function BLTUIButton:text()
	return self._panel:child("desc")
end

function BLTUIButton:image()
	return self._panel:child("image")
end

function BLTUIButton:parameters()
	return self._parameters
end

function BLTUIButton:inside( x, y )
	return self._panel:inside( x, y )
end

function BLTUIButton:set_highlight( enabled, no_sound )
	if self._enabled ~= enabled then
		self._enabled = enabled
		self._background:set_color( enabled and tweak_data.screen_colors.button_stage_2 or (self:parameters().color or tweak_data.screen_colors.button_stage_3) )
		if enabled and not no_sound then
			managers.menu_component:post_event( "highlight" )
		end
	end
end
