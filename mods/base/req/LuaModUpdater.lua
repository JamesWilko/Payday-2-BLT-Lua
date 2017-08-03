
LuaModUpdater = {}

LuaModUpdater.Constants = {
	["blt_dll_id"] = "payday2bltdll",
	["blt_dll_name"] = "IPHLPAPI.dll",
	["blt_dll_temp_name"] = "IPHLPAPI_temp.dll",
	["updates_url"] = "http://api.paydaymods.com/updates/retrieve_hashes/?%s"
}

LuaModUpdates = {}
LuaModUpdates._updates_api_path = "http://api.paydaymods.com/updates/retrieve/?"
LuaModUpdates._updates_api_mod = "mod[{1}]={2}"
LuaModUpdates._updates_download_url = "http://download.paydaymods.com/download/latest/{1}"
LuaModUpdates._updates_notes_url = "http://download.paydaymods.com/download/patchnotes/{1}"
LuaModUpdates._notification_id = "lua_mod_updates_notif"
LuaModUpdates.__required_notification_id = "lua_mod_require_notif"

-- http://api.paydaymods.com/updates/retrieve/?mod[0]=payday2blt&mod[1]=goonmod

function LuaModUpdater:RemoveTemporaryDLL()
	print("[BLT] Attempting to remove temporary hook dll...")
	local hook_result, hook_error, error_code = os.remove( LuaModUpdater.Constants["blt_dll_temp_name"] )
	if not hook_result and error_code ~= 2 then
		print(string.format("[BLT] Warning: Could not remove hook dll: %s", tostring(hook_error)))
	end
end

function LuaModUpdater:RequestVersionHashes( callback )

	-- Utils:EscapeURL( path )

	local update_count = 0
	local updates_url = ""

	-- Get number of mods requiring updates
	for index, mod in ipairs( LuaModManager:Mods() ) do
		for index, update in ipairs( mod:GetUpdates() ) do
			update_count = update_count + 1
		end
	end

	-- Don't get anything if nothing is requesting updates
	if update_count < 1 then
		return false
	end

	log(string.format("%i MODS REQUESTING UPDATES", update_count))
	local url = string.format(LuaModUpdater.Constants["updates_url"], "")

end
