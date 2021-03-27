require("ts3init")
require("ts3defs")
require("ts3errors")

local Group = {
	HIGHT_SERVER_ADMIN = 27,
	ADMIN              = 18,
	MODERATOR          = 21,
	FRIEND             = 29,
	CLAN_LEADER        = 23,
	REGISTERED         = 25,
	GIRL               = 28,
	GUEST              = 19,
}

local GroupTranslate = {
	HIGHT_SERVER_ADMIN = "Старший Admin Server",
	ADMIN              = "Администратор",
	MODERATOR          = "Модератор",
	FRIEND             = "Друг",
	CLAN_LEADER        = "Клан лидер",
	REGISTERED         = "Зарегистрирован",
	GIRL               = "Девушка",
	GUEST              = "Гость",
}

local GroupName = {
	HIGHT_SERVER_ADMIN = "HIGHT_SERVER_ADMIN",
	ADMIN              = "ADMIN",
	MODERATOR          = "MODERATOR",
	FRIEND             = "FRIEND",
	CLAN_LEADER        = "CLAN_LEADER",
	REGISTERED         = "REGISTERED",
	GIRL               = "GIRL",
	GUEST              = "GUEST",
}

local REGISTRATION_REQUIREMENTS = {
	CLIENT_TOTALCONNECTIONS = 10,
	DAYS_ON_SERVER = 30
}

local MenuIDs = {
	MENU_ID_COUNT_GROUP_MEMBERS = 1,
	MENU_ID_REGISTER_ALL = 2,
	MENU_ID_TEST = 3
}

local moduleMenuItemID = 0

local function spairs(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function getClients(serverConnectionHandlerID)
	local clients, error = ts3.getClientList(serverConnectionHandlerID)
	if error == ts3errors.ERROR_not_connected then
		ts3.printMessageToCurrentTab("[COLOR=#ff0000]Not connected[/COLOR]")
		return nil
	elseif error ~= ts3errors.ERROR_ok then
		ts3.printMessageToCurrentTab("[COLOR=#ff0000]Error getting client list: [/COLOR]" .. error)
		return nil
	end
	return clients
end

local function getCountGroupMembers(serverConnectionHandlerID)
	local clients = getClients(serverConnectionHandlerID)
	local groups = {}
	for k,v in pairs(Group) do 
		groups[k] = 0
	end
	for _, client_id in ipairs(clients) do
		local client_groups, error = ts3.getClientVariableAsString(serverConnectionHandlerID, client_id, ts3defs.ClientProperties.CLIENT_SERVERGROUPS)
		if error == ts3errors.ERROR_ok then
			for group_id in string.gmatch(client_groups, "%d+") do
				for k, v in pairs(Group) do
					if tonumber(group_id) == v then
						groups[k] = groups[k] + 1
					end
				end	
			end
		end
	end
	return groups
end

local function countGroupMembers(serverConnectionHandlerID, ...)
	local groups = getCountGroupMembers(serverConnectionHandlerID)
	if groups == nil then
		return
	end
	ts3.printMessageToCurrentTab("\n[B][COLOR=#aa007f]# Количество участников групп (online):[/COLOR][/B]")
	for k,v in spairs(groups, function(t,a,b) return t[b] < t[a] end) do
		ts3.printMessageToCurrentTab(GroupTranslate[k] .. " - " .. v)
	end
end

local function registerAll(serverConnectionHandlerID, ...)
	local groups = getCountGroupMembers(serverConnectionHandlerID)
	if groups == nil then
		return
	end
	ts3.printMessageToCurrentTab("\n[B][COLOR=#5500ff]# Регистрация пользователей[/COLOR][/B]")
	ts3.printMessageToCurrentTab("[B]Количество участников групп (online):[/B]")
	for k,v in spairs(groups, function(t,a,b) return t[b] < t[a] end) do
		if k == GroupName.REGISTERED or k == GroupName.GUEST then
			ts3.printMessageToCurrentTab(GroupTranslate[k] .. " - " .. v)
		end
	end
	local clients = getClients(serverConnectionHandlerID)
	if clients == nil then 
		return 
	end
	for _, client_id in ipairs(clients) do
		local client_groups, error = ts3.getClientVariableAsString(serverConnectionHandlerID, client_id, ts3defs.ClientProperties.CLIENT_SERVERGROUPS)
		if error == ts3errors.ERROR_ok then
			for group_id in string.gmatch(client_groups, "%d+") do
				if tonumber(group_id) == Group.GUEST then
					local rrr, error =  ts3.getClientVariableAsInt(serverConnectionHandlerID, client_id, ts3defs.ClientProperties.CLIENT_TOTALCONNECTIONS)
					if error == ts3errors.ERROR_ok then
						ts3.printMessageToCurrentTab("user id: " .. client_id .. " | connections: " .. rrr)
					end
				end
			end
		end
	end
end

local function testt(serverConnectionHandlerID)
	ts3.printMessageToCurrentTab("1")
	local myClientID, error = ts3.getClientID(serverConnectionHandlerID)
	--ts3.requestServerGroupAddClient(serverConnectionHandlerID, 19,)
	--https://pytson.4qt.de/ts3lib-module.html#requestServerGroupAddClient
	--requestServerGroupAddClient(serverConnectionHandlerID, serverGroupID, clientDatabaseID, returnCode) 
	--CLIENT_DATABASE_ID
	ts3.requestClientVariables(serverConnectionHandlerID, myClientID)
	ts3.printMessageToCurrentTab("2")
	local myDB_ID, error = ts3.getClientVariableAsInt(serverConnectionHandlerID, myClientID, ts3defs.ClientProperties.CLIENT_DATABASE_ID)
	ts3.printMessageToCurrentTab("myDB_ID: " .. myDB_ID)
	
	ts3.requestServerGroupAddClient(serverConnectionHandlerID, 19, 32) 
	ts3.printMessageToCurrentTab("3") ---------------------------------------------------------------------
end

local function onMenuItemEvent(serverConnectionHandlerID, menuType, menuItemID, selectedItemID)
	if menuItemID == MenuIDs.MENU_ID_COUNT_GROUP_MEMBERS then
		countGroupMembers(serverConnectionHandlerID)
	elseif menuItemID == MenuIDs.MENU_ID_REGISTER_ALL then
		registerAll(serverConnectionHandlerID)
	elseif menuItemID == MenuIDs.MENU_ID_TEST then
		testt(serverConnectionHandlerID)
	end
end

function onUpdateClientEvent(serverConnectionHandlerID, clientID, invokerID, invokerName, invokerUniqueIdentifier)

end

local function onClientMoveEvent(serverConnectionHandlerID, clientID, oldChannelID, newChannelID, visibility, moveMessage)
	if oldChannelID == 0 then
		ts3.requestClientVariables(serverConnectionHandlerID, clientID)
	end
end

function onClientMoveSubscriptionEvent(serverConnectionHandlerID, clientID, oldChannelID, newChannelID, visibility)
	ts3.requestClientVariables(serverConnectionHandlerID, clientID)
end

testmodule_events = {
	MenuIDs = MenuIDs,
	moduleMenuItemID = moduleMenuItemID,
	onConnectStatusChangeEvent = onConnectStatusChangeEvent,
	onNewChannelEvent = onNewChannelEvent,
	onTalkStatusChangeEvent = onTalkStatusChangeEvent,
	onTextMessageEvent = onTextMessageEvent,
	onPluginCommandEvent = onPluginCommandEvent,
	onMenuItemEvent = onMenuItemEvent
}

local function createMenus(moduleMenuItemID)
	testmodule_events.moduleMenuItemID = moduleMenuItemID
	return {
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL,  testmodule_events.MenuIDs.MENU_ID_COUNT_GROUP_MEMBERS,  "Количество участников групп",  "../test_plugin/1.png"},
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL,  testmodule_events.MenuIDs.MENU_ID_REGISTER_ALL,  "Зарегистрировать всех",  "../test_plugin/2.png"},
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL,  testmodule_events.MenuIDs.MENU_ID_TEST,  "test",  "../test_plugin/2.png"}
	}
end

cosma = {
	countGroupMembers = countGroupMembers,
	createMenus = createMenus,
	onUpdateClientEvent = onUpdateClientEvent,
	onClientMoveEvent = onClientMoveEvent,
	onClientMoveSubscriptionEvent = onClientMoveSubscriptionEvent,
	
	onConnectStatusChangeEvent = testmodule_events.onConnectStatusChangeEvent,
	onNewChannelEvent = testmodule_events.onNewChannelEvent,
	onTalkStatusChangeEvent = testmodule_events.onTalkStatusChangeEvent,
	onTextMessageEvent = testmodule_events.onTextMessageEvent,
	onPluginCommandEvent = testmodule_events.onPluginCommandEvent,
	onMenuItemEvent = testmodule_events.onMenuItemEvent
}

ts3RegisterModule("cosma", cosma)
