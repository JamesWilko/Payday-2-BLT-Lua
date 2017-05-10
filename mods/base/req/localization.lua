
LuaModManager._languages = {}
LuaModManager.Constants.default_language = "en"
LuaModManager.Constants.language_key = "language"
LuaModManager.Constants.localisation_folder = string.format("%sloc/", LuaModManager._base_path)

function LuaModManager:LoadAvailableLanguages()

	LuaModManager._languages = {}

	-- Add all localisation files
	local loc_files = file.GetFiles( LuaModManager.Constants.localisation_folder )
	
	if type(loc_files) ~= "table" then
		loc_files = {
			"en.txt"
		}
	end
	for i, file_name in ipairs( loc_files ) do
		local loc_code = string.gsub(file_name, ".txt", "")
		if loc_code ~= "en" then
			table.insert( LuaModManager._languages, loc_code )
		end
	end

	-- Sort languages alphabetically by code to ensure we always have the same order
	table.sort(LuaModManager._languages)

	-- Add english as the default language
	table.insert( LuaModManager._languages, 1, "en" )

end

function LuaModManager:IndexOfLocalisationCode( code )
	for index, loc_code in ipairs( LuaModManager._languages ) do
		if loc_code == code then
			return index
		end
	end
	return 1
end

function LuaModManager:IndexToLocalisationCode( index )
	return LuaModManager._languages[index] or "en"
end

function LuaModManager:GetIndexOfDefaultLanguage()
	return self:IndexOfLocalisationCode( LuaModManager.Constants.default_language )
end

function LuaModManager:GetLanguageIndex()
	local key = LuaModManager.Constants.language_key
	local lang = self._enabled_mods[key]
	if type(lang) == "number" then
		return self:GetIndexOfDefaultLanguage()
	end
	return self:IndexOfLocalisationCode( lang )
end

function LuaModManager:GetLanguageFile()
	local lang = LuaModManager._languages[self:GetLanguageIndex()]
	lang = lang or LuaModManager._languages[self:GetIndexOfDefaultLanguage()]
	return string.format("%s%s.txt", LuaModManager.Constants.localisation_folder, lang)
end

function LuaModManager:SetActiveLanguage( loc_code )
	self._enabled_mods[LuaModManager.Constants.language_key] = loc_code
end

Hooks:Add("LocalizationManagerPostInit", "Base_LocalizationManagerPostInit", function(loc)

	-- Load available language files
	LuaModManager:LoadAvailableLanguages()

	-- Load english strings to use as backup
	loc:load_localization_file( string.format("%s%s.txt", LuaModManager.Constants.localisation_folder, "en") )
	loc:load_localization_file( LuaModManager:GetLanguageFile() )

end)

Hooks:Add("MenuManager_Base_BuildModOptionsMenu", "MenuManager_Base_SetupModOptionsMenu_Localization", function( menu_manager )

	local menu_id = LuaModManager.Constants._lua_mod_options_menu_id

	MenuCallbackHandler.blt_base_select_language = function(this, item)
		local loc_code = LuaModManager:IndexToLocalisationCode( tonumber(item:value()) )
		LuaModManager:SetActiveLanguage( loc_code )
		LuaModManager:Save()
	end

	local items = {}
	for k, v in ipairs( LuaModManager._languages ) do
		items[k] = "base_language_" .. v
	end

	MenuHelper:AddMultipleChoice({
		id = "base_language_select",
		title = "base_language_select",
		desc = "base_language_select_desc",
		callback = "blt_base_select_language",
		menu_id = menu_id,
		items = items,
		value = LuaModManager:GetLanguageIndex(),
		priority = 1001,
	})

	MenuHelper:AddDivider({
		size = 16,
		menu_id = menu_id,
		priority = 1000,
	})

end)
