local LobbyManager = require(script.LobbyManager)
local ReplicatedStorage = game.ReplicatedStorage
local Remotes = ReplicatedStorage.Remotes
local MiscUtils = require(game.ReplicatedStorage.MiscUtils)

Remotes.PostLobby.OnServerEvent:Connect(function(plr, info)
	if not LobbyManager.GetLobbyByHostID(plr.UserId) then
		LobbyManager.Create(plr.UserId, info)
		LobbyManager.UpdateLobbyListsGlobal()
	end
end)

Remotes.RemovePlayerFromLobby.OnServerEvent:Connect(function(_, lobbyid, removedPlayerID, message)
	local lobby = LobbyManager.GetLobbyByLobbyID(lobbyid)

	if message then
		lobby:RemovePlayer(removedPlayerID, message)
	else
		lobby:RemovePlayer(removedPlayerID)
	end

	print(lobby["Players"])
	print(LobbyManager.GetLobbyByLobbyID(lobbyid)["Players"])
	LobbyManager.UpdateLobbyListsGlobal()
end)

Remotes.DeleteLobby.OnServerEvent:Connect(function(plr, lobbyid)
	local lobby = LobbyManager.GetLobbyByLobbyID(lobbyid)

	if LobbyManager.GetLobbyByHostID(plr.UserId) then
		if LobbyManager.GetLobbyByHostID(plr.UserId).LobbyID == lobbyid then
			lobby:RemovePlayer(
				plr.UserId,
				"You successfully disbanded the lobby, and left all those poor schmucks behind! Smell ya later losers!"
			)
			lobby:Delete()
			LobbyManager.UpdateLobbyListsGlobal()
		end
	end
end)

Remotes.TeleportPlayersInLobby.OnServerEvent:Connect(function(plr, lobbyid)
	local lobby = LobbyManager.GetLobbyByHostID(plr.UserId)

	if lobby then
		if lobby.LobbyID == lobbyid then
			lobby:Teleport()
			LobbyManager.UpdateLobbyListsGlobal()
		end
	end
end)

Remotes.UpdateCurrentLobbyMessage.OnServerEvent:Connect(function(plr, lobbyid, message)
	if LobbyManager.AuthenticateHost(plr.UserId, lobbyid) then
		for _, playerid in pairs(LobbyManager.GetLobbyByLobbyID(lobbyid).Players) do
			local filteredMessage = game:GetService("TextService")
				:FilterStringAsync(message, plr.UserId, Enum.TextFilterContext.PrivateChat)
				:GetNonChatStringForBroadcastAsync()
			Remotes.UpdateCurrentLobbyMessage:FireClient(game.Players:GetPlayerByUserId(playerid), filteredMessage)
		end
	end
end)

Remotes.GatherLobbies.OnServerInvoke = function(plr)
	local lobbies = {}

	for i, v in pairs(LobbyManager.GetAllAvailableLobbies(plr)) do
		lobbies[i] = MiscUtils.ParseLobby(v)
	end

	return lobbies
end

Remotes.AttemptJoinLobby.OnServerInvoke = function(plr, HostID)
	local lobby = LobbyManager.GetLobbyByHostID(HostID)
	local result = lobby:AttemptAddPlayer(plr.UserId)
	if result then
		LobbyManager.UpdateLobbyListsGlobal()
	end
	return result
end

Remotes.AuthenticateHost.OnServerInvoke = function(plr, lobbyid)
	return LobbyManager.AuthenticateHost(plr.UserId, lobbyid)
end

Remotes.GrabCurrentHost.OnServerInvoke = function(_, check)
	return LobbyManager.GrabCurrentHost(check)
end

game.Players.PlayerRemoving:Connect(function(plr)
	local plrLobby = LobbyManager.GetPlayersLobby(plr.UserId)
	if plrLobby then
		if LobbyManager.AuthenticateHost(plr.UserId, plrLobby.LobbyID) then
			plrLobby:Delete()
		else
			plrLobby:RemovePlayer(plr.UserId)
		end
	end
end)
