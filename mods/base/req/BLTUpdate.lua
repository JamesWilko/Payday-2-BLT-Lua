
-- BLT Update
BLTUpdate = blt_class()
BLTUpdate.enabled = true
BLTUpdate.parent_mod = nil
BLTUpdate.id = ""
BLTUpdate.name = "BLT Update"
BLTUpdate.revision = 1
BLTUpdate.dir = "mods/"
BLTUpdate.folder = ""

function BLTUpdate:init( parent_mod, data )

	assert( parent_mod, "BLTUpdates can not be created without a parent mod!" )
	assert( data, "BLTUpdates can not be created without json update data!" )

	self.parent_mod = parent_mod
	self.id = data["identifier"]
	self.name = data["display_name"] or parent_mod:GetName()
	self.dir = data["install_dir"] or "mods/"
	self.folder = data["install_folder"] or parent_mod:GetId()
	self.disallow_update = data["disallow_update"] or false
	self.hash_file = data["hash_file"] or false
	self.critical = data["critical"] or false

end

function BLTUpdate:__tostring()
	return string.format("[BLTUpdate %s (%s)]", self:GetName(), self:GetId())
end

function BLTUpdate:IsEnabled()
	return self.enabled
end

function BLTUpdate:SetEnabled( enable )
	self.enabled = enable
end

function BLTUpdate:RequiresUpdate()
	return self._requires_update
end

function BLTUpdate:CheckForUpdates( clbk )

	-- Flag this update as already requesting updates
	self._requesting_updates = true

	-- Perform the request from the server
	local url = "http://api.paydaymods.com/updates/retrieve/?mod[0]=" .. self:GetId()
	dohttpreq( url, function( json_data, http_id )
		self:clbk_got_update_data( clbk, json_data, http_id )
	end)

end

function BLTUpdate:clbk_got_update_data( clbk, json_data, http_id )

	self._requesting_updates = false

	if json_data:is_nil_or_empty() then
		log("[Error] Could not connect to the PaydayMods.com API!")
		return self:_run_update_callback( clbk, false, "Could not connect to the PaydayMods.com API." )
	end

	local server_data = json.decode( json_data )
	if server_data then

		for _, data in pairs( server_data ) do
			log(string.format("[Updates] Received update data for '%s'", data.ident))
			if data.ident == self:GetId() then

				self._server_hash = data.hash
				local local_hash = self:GetHash()
				log(string.format("[Updates] Comparing hash data:\nServer: %s\n Local: %s", data.hash, local_hash))
				if data.hash then
					if data.hash ~= local_hash then
						return self:_run_update_callback( clbk, true )
					else
						return self:_run_update_callback( clbk, false )
					end
				else
					return self:_run_update_callback( clbk, false )
				end

			end
		end
		
	end

	return self:_run_update_callback( clbk, false, "No valid mod ID was returned by the server." )

end

function BLTUpdate:_run_update_callback( clbk, requires_update, error_reason )
	self._requires_update = requires_update
	clbk( self, requires_update, error_reason )
	return requires_update
end

function BLTUpdate:IsCheckingForUpdates()
	return self._requesting_updates or false
end

function BLTUpdate:GetParentMod()
	return self.parent_mod
end

function BLTUpdate:GetId()
	return self.id
end

function BLTUpdate:GetName()
	return self.name
end

function BLTUpdate:GetHash()
	if self.hash_file then
		return SystemFS:exists(self.hash_file) and file.FileHash(self.hash_file) or nil
	else
		local directory = Application:nice_path( self:GetInstallDirectory() .. "/" .. self:GetInstallFolder(), true )
		return SystemFS:exists(directory) and file.DirectoryHash(directory) or nil
	end
end

function BLTUpdate:GetServerHash()
	return self._server_hash
end

function BLTUpdate:GetInstallDirectory()
	return self.dir
end

function BLTUpdate:GetInstallFolder()
	return self.folder
end

function BLTUpdate:DisallowsUpdate()
	return self.disallow_update ~= false
end

function BLTUpdate:GetDisallowCallback()
	return self.disallow_update
end

function BLTUpdate:IsCritical()
	return self.critical
end

function BLTUpdate:ViewPatchNotes()
	local url = "http://download.paydaymods.com/download/patchnotes/" .. self:GetId()
	if Steam:overlay_enabled() then
		Steam:overlay_activate( "url", url )
	else
		os.execute( "cmd /c start " .. url )
	end
end
