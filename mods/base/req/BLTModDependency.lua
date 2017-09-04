
BLTModDependency = BLTModDependency or blt_class()

function BLTModDependency:init( parent_mod, id )

	self._id = id
	self._parent_mod = parent_mod

end

function BLTModDependency:GetId()
	return self._id
end

function BLTModDependency:GetParentMod()
	return self._parent_mod
end

function BLTModDependency:GetServerData()
	return self._server_data
end

function BLTModDependency:GetServerName()
	return self:GetServerData() and self:GetServerData().name or self._id
end

function BLTModDependency:GetName()
	local macros = {
		dependency = self:GetServerName(),
		mod = self:GetParentMod():GetName()
	}
	return managers.localization:text( "blt_download_dependency", macros )
end

function BLTModDependency:DisallowsUpdate()
	return false
end

function BLTModDependency:GetInstallDirectory()
	return "mods/"
end

function BLTModDependency:Retrieve( clbk )

	-- Don't run twice at the same time
	if self._retrieving then
		return
	end

	-- Flag this as already retrieving data
	self._retrieving = true

	-- Perform the request from the server
	local url = "http://api.paydaymods.com/updates/retrieve/?mod[0]=" .. self:GetId()
	dohttpreq( url, function( json_data, http_id )
		self:clbk_got_data( clbk, json_data, http_id )
	end)

end

function BLTModDependency:clbk_got_data( clbk, json_data, http_id )

	self._retrieving = false

	if json_data:is_nil_or_empty() then
		log("[Error] Could not connect to the PaydayMods.com API!")
		return self:_run_update_callback( clbk, false, "Could not connect to the PaydayMods.com API." )
	end

	local server_data = json.decode( json_data )
	if server_data then
		for idx, data in pairs( server_data ) do
			if data.ident == self:GetId() then
				log(string.format("[Dependencies] Received server data for '%s'", data.ident))
				self._server_data = data
				break
			end
		end
	end

	clbk( self, self._server_data ~= nil )

end

function BLTModDependency:ViewPatchNotes()
	BLTUpdate.ViewPatchNotes( self )
end

function BLTModDependency:IsCritical()
	return true
end
