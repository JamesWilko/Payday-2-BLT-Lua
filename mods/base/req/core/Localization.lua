
BLTLocalisation = {}

BLTLocalisation._languages = {}
BLTLocalisation.default_language = "en"
BLTLocalisation.language_key = "language"
BLTLocalisation.localisation_folder = "mods/base/loc/"

function BLTLocalisation:LoadAvailableLanguages()

	self._languages = {}

	-- Add all localisation files
	local loc_files = file.GetFiles( self.localisation_folder )
	for i, file_name in ipairs( loc_files ) do
		local loc_code = string.gsub(file_name, ".txt", "")
		if loc_code ~= "en" then
			table.insert( self._languages, loc_code )
		end
	end

	-- Sort languages alphabetically by code to ensure we always have the same order
	table.sort(self._languages)

	-- Add english as the default language
	table.insert(self._languages, 1, "en")

end

function BLTLocalisation:IndexOfLocalisationCode( code )
	for index, loc_code in ipairs( self._languages ) do
		if loc_code == code then
			return index
		end
	end
	return 1
end

function BLTLocalisation:IndexToLocalisationCode( index )
	return self._languages[index] or "en"
end

function BLTLocalisation:GetIndexOfDefaultLanguage()
	return self:IndexOfLocalisationCode( BLTLocalisation.default_language )
end

function BLTLocalisation:GetLanguageIndex()
	if type(self._active_language) ~= "string" then
		return self:GetIndexOfDefaultLanguage()
	end
	return self:IndexOfLocalisationCode( self._active_language )
end

function BLTLocalisation:GetLanguageFile()
	local lang = self._languages[self:GetLanguageIndex()]
	lang = lang or self._languages[self:GetIndexOfDefaultLanguage()]
	return string.format("%s%s.txt", self.localisation_folder, lang)
end

function BLTLocalisation:GetActiveLanguage()
	return self._active_language or self.default_language
end

function BLTLocalisation:SetActiveLanguage( loc_code )
	self._active_language = loc_code or self.default_language
end

Hooks:Add("BLTOnLoadData", "BLTOnLoadData.BLTLocalisation", function(save_data)
	BLTLocalisation:SetActiveLanguage( save_data["language"] )
end)

Hooks:Add("BLTOnSaveData", "BLTOnSaveData.BLTLocalisation", function(save_data)
	save_data["language"] = BLTLocalisation:GetActiveLanguage()
end)

Hooks:Add("LocalizationManagerPostInit", "Base_LocalizationManagerPostInit", function(loc)

	-- Load available language files
	BLTLocalisation:LoadAvailableLanguages()

	-- Load english strings to use as backup
	loc:load_localization_file( string.format("%s%s.txt", BLTLocalisation.localisation_folder, "en") )
	loc:load_localization_file( BLTLocalisation:GetLanguageFile() )

end)

Hooks:Add("MenuManager_Base_BuildModOptionsMenu", "MenuManager_Base_SetupModOptionsMenu_Localization", function( menu_manager )

	MenuCallbackHandler.blt_base_select_language = function(this, item)
		local loc_code = BLTLocalisation:IndexToLocalisationCode( tonumber(item:value()) )
		BLTLocalisation:SetActiveLanguage( loc_code )
		LuaModManager:Save()
	end

	local items = {}
	for k, v in ipairs( BLTLocalisation._languages ) do
		items[k] = "base_language_" .. v
	end

	MenuHelper:AddMultipleChoice({
		id = "base_language_select",
		title = "base_language_select",
		desc = "base_language_select_desc",
		callback = "blt_base_select_language",
		menu_id = LuaModManager.Constants:LuaModOptionsMenuID(),
		items = items,
		value = BLTLocalisation:GetLanguageIndex(),
		priority = 1001,
	})

	MenuHelper:AddDivider({
		size = 16,
		menu_id = LuaModManager.Constants:LuaModOptionsMenuID(),
		priority = 1000,
	})

end)
