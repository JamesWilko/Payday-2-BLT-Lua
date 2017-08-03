
-- BLT Update
BLTUpdate = class()
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
	self.revision = data["revision"] or 1
	self.dir = data["install_dir"] or self.dir
	self.folder = data["install_folder"] or parent_mod:GetId()

	if type(self.revision) == "string" then
		self:LoadRevision()
	end

end

function BLTUpdate:__tostring()
	return string.format("[BLTUpdate %s (%s)]", self:GetName(), self:GetId())
end

function BLTUpdate:LoadRevision()

	local path = self.revision
	if self.revision:sub(1, 2) == "./" then
		path = self.revision:sub( 3, self.revision:len() )
		self.revision = path
	else
		path = self:GetInstallDirectory() .. self:GetInstallFolder() .. "/" .. self.revision
	end

	local file = io.open( path, "r" )
	if file then
		local data = file:read("*all")
		data = tonumber(data)
		if data then
			self.revision = data
		else
			self.revision = nil
		end
	else
		self.revision = nil
	end

	if self.revision == nil then
		log(string.format("[Error] Could not load revision file for %s!", self:GetName()))
		self.revision = 1
	end

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

	self._requesting_updates = true
	local url = "http://api.paydaymods.com/updates/retrieve/?mod[0]=" .. self:GetId()

	self._requires_update = dohttpreq( url, function( json_data, id )
		
		self._requesting_updates = false

		if json_data:is_nil_or_empty() then
			log("[Error] Could not connect to the PaydayMods.com API!")
			clbk( self, false, "Could not connect to the PaydayMods.com API." )
			return false
		end

		local server_data = json.decode( json_data )
		if server_data then
			for id, data in pairs( server_data ) do
				log(string.format("[Updates] Received update data for '%s', server revision: %i", id, data.revision))
				if id == self:GetId() then

					local revision_number = tonumber(data.revision)
					if revision_number then
						if revision_number > self:GetRevision() then
							clbk( self, true )
							return true
						else
							clbk( self, false )
							return false
						end
					else
						clbk( self, false, "Could not retrieve a valid version number from the server." )
						return false
					end

				end
			end
		end

		clbk( self, false, "No valid mod ID was returned by the server." )
		return false

	end)

end

function BLTUpdate:IsCheckingForUpdates()
	return self._requesting_updates or false
end

function BLTUpdate:GetId()
	return self.id
end

function BLTUpdate:GetName()
	return self.name
end

function BLTUpdate:GetRevision()
	return self.revision
end

function BLTUpdate:GetInstallDirectory()
	return self.dir
end

function BLTUpdate:GetInstallFolder()
	return self.folder
end
