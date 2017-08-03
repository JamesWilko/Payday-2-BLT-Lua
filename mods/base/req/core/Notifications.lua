
NotificationsManager = NotificationsManager or {}
local Notify = NotificationsManager
Notify._notifications = {}
Notify._current_notification = 1

Hooks:RegisterHook("NotificationManagerOnNotificationsUpdated")

function NotificationsManager:GetNotifications()
	return self._notifications
end

function NotificationsManager:GetCurrentNotification()
	return self._notifications[ self._current_notification ]
end

function NotificationsManager:GetCurrentNotificationIndex()
	return self._current_notification
end

function NotificationsManager:AddNotification( id, title, message, priority, callback )

	if not id then
		log("[Error] Attempting to add notification with no id!")
		return false
	end

	for k, v in ipairs( self._notifications ) do
		if v.id == id then
			local error_str = ("[Error] Notification already has a notification with id '{1}'! Can not add duplicate id's!"):gsub("{1}", id)
			log( error_str )
			return false
		end
	end

	local tbl = {
		id = id,
		title = title or "",
		message = message or "",
		priority = priority or 0,
		callback = callback or nil,
		read = false
	}

	table.insert( self._notifications, tbl )
	table.sort( self._notifications, function(a, b)
		return a.priority > b.priority
	end)

	self:_OnUpdated()
	return true

end

function NotificationsManager:UpdateNotification( id, new_title, new_message, new_priority, new_callback )

	if not id then
		log("[Error] Attempting to update notification with no id!")
		return false
	end
	
	local updated = false
	for k, v in ipairs( self._notifications ) do

		if v.id == id then

			v.title = new_title or v.title
			v.message = new_message or v.message
			v.priority = new_priority or v.priority
			v.callback = new_callback or v.callback
			v.read = false

			updated = true

		end

	end

	if not updated then
		local error_str = ("[Warning] Could not find notification with id '{1}', it has not been updated!"):gsub("{1}", id)
		log( error_str )
		return false
	end

	self:_OnUpdated()
	return true

end

function NotificationsManager:RemoveNotification( id )

	if not id then
		log("[Error] Attempting to remove notification with no id!")
		return false
	end

	local tbl = {}

	for k, v in ipairs( self._notifications ) do
		if v.id ~= id then
			table.insert( tbl, v )
		end
	end

	self._notifications = tbl
	self:_OnUpdated()
	return true

end

function NotificationsManager:ClearNotifications()
	self._notifications = {}
	self:_OnUpdated()
end

function NotificationsManager:NotificationExists( id )

	for k, v in ipairs( self._notifications ) do
		if v.id == id then
			return true
		end
	end

	return false

end

function NotificationsManager:ShowNextNotification( suppress_sound )

	self._current_notification = self._current_notification + 1
	if self._current_notification > #self._notifications then
		self._current_notification = 1
	end
	if not suppress_sound then
		managers.menu_component:post_event("highlight")
	end
	self:_OnUpdated()
	self:_ResetTimeToNextNotification()

end

function NotificationsManager:ShowPreviousNotification( suppress_sound )

	self._current_notification = self._current_notification - 1
	if self._current_notification < 1 then
		self._current_notification = #self._notifications
	end
	if not suppress_sound then
		managers.menu_component:post_event("highlight")
	end
	self:_OnUpdated()
	self:_ResetTimeToNextNotification()

end

function NotificationsManager:ClickNotification( suppress_sound )

	local notif = self:GetCurrentNotification()
	if notif and notif.callback then
		notif.callback()
		if not suppress_sound then
			managers.menu_component:post_event("menu_enter")
		end
	end

end

function Notify:MarkNotificationAsRead( id )

	if not id then
		log("[Error] Attempting to mark notification with no id!")
		return false
	end

	for k, v in ipairs( self._notifications ) do
		if v.id == id then
			v.read = true
			return true
		end
	end

	return false

end

function NotificationsManager:_OnUpdated()
	if not self:GetCurrentNotification().read then
		managers.menu_component:post_event("job_appear")
	end
	Hooks:Call("NotificationManagerOnNotificationsUpdated", self, self._notifications)
end
