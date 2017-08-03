
BLTPersistScripts = class(BLTModule)
BLTPersistScripts.__type = "BLTPersistScripts"

function BLTPersistScripts:init()

	BLTPersistScripts.super.init(self)

	print("BLTPersistScripts:init()")

	Hooks:Add( "MenuUpdate", "BLTPersistScripts.MenuUpdate", function(t, dt)
		self:update_persists()
	end )

	Hooks:Add( "GameSetupUpdate", "BLTPersistScripts.GameSetupUpdate", function(t, dt)
		self:update_persists()
	end )

end

function BLTPersistScripts:update_persists()

	print("BLTPersistScripts:update_persists")

end
