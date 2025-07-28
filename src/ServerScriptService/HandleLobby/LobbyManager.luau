local remotes = game.ReplicatedStorage.Remotes
local TPS = game:GetService("TeleportService")
local MiscUtils = require(game.ReplicatedStorage.MiscUtils)

local LobbyManager = {}
LobbyManager.__index = LobbyManager
LobbyManager.Lobbies = {}

local Lobby = {}
Lobby.__index = Lobby
Lobby.HostID = 0
Lobby.LobbyID = 0
Lobby.Options = {}
Lobby.Players = {}

function Lobby:Delete() -- kicks out all players before deleting the lobby
	for _, playerid in pairs(self.Players) do
		self:RemovePlayer(
			playerid,
			"You were removed from the lobby because the lobby was disbanded. The host must've HATED you guys... "
		)
	end

	LobbyManager.Lobbies[self.HostID] = nil
end

function Lobby:RemovePlayer(playerid, message) -- checks for a player, then removes them
	table.remove(self.Players, table.find(self.Players, playerid))

	if game.Players:GetPlayerByUserId(playerid) then
		if message then
			remotes.RemovePlayerFromLobby:FireClient(game.Players:GetPlayerByUserId(playerid), message)
		else
			remotes.RemovePlayerFromLobby:FireClient(game.Players:GetPlayerByUserId(playerid))
		end
	end

	for _, v in pairs(self.Players) do
		if game.Players:GetPlayerByUserId(v) then
			local ClientData = MiscUtils.ParseLobby(self)

			remotes.UpdateLobbyViewMenu:FireClient(game.Players:GetPlayerByUserId(v), ClientData)
		end
	end
end

function Lobby:AttemptAddPlayer(JoinID) -- attempts to add a player to the lobby, returning a boolean to indicate if it was successful
	local NewPlr = game.Players:GetPlayerByUserId(JoinID)

	-- this big ol if statement checks if the player limit is not exceeded, the visibility rules are correct, and the joining player does not have their own lobby
	if
		self.Options["PlayerLimit"] > #self.Players
		and (
			self.Options["Visibility"] == 1
			or (self.Options["Visibility"] == 2 and NewPlr:IsFriendsWith(self.HostID))
				and LobbyManager[JoinID] == nil
		)
	then
		table.insert(self.Players, JoinID)

		local ClientData = MiscUtils.ParseLobby(self)

		for _, v in pairs(self.Players) do
			remotes.UpdateLobbyViewMenu:FireClient(game.Players:GetPlayerByUserId(v), ClientData)
		end

		return true
	else
		return false
	end
end

function Lobby:Teleport()
	local TPoptions = Instance.new("TeleportOptions")
	TPoptions.ShouldReserveServer = true

	local players = {}
	local chars = {}

	for _, v in pairs(self.Players) do
		local plr = game.Players:GetPlayerByUserId(v)
		table.insert(players, plr)

		chars[plr] = plr.Backpack.CharSelection.Value
		remotes.TeleportPlayersInLobby:FireClient(plr)
	end

	local playernum = #players
	local data = { playernum, chars, self.Options["Difficulty"] }
	TPoptions:SetTeleportData(data)
	TPS:TeleportPartyAsync(83429685910917, players, TPoptions)

	self:Delete()
end

function LobbyManager.GenerateLobbyID() -- just generates a unique number for a lobby
	local id = math.random(1, 100000)

	for _, lobby in pairs(LobbyManager.Lobbies) do
		if lobby.LobbyID == id then
			return LobbyManager.GenerateLobbyID()
		end
	end

	return id
end

function LobbyManager.Create(HostID, Options) -- creates a lobby and stores it inside of the LobbyManager table
	if LobbyManager.Lobbies[HostID] then
		warn("This player already has a lobby! Do not give them any more!")
		return LobbyManager.Lobbies[HostID]
	else
		print("beep boop making lobby....")
		local newLobby = table.clone(Lobby)

		newLobby.HostID = HostID
		newLobby.LobbyID = LobbyManager.GenerateLobbyID()
		newLobby.Options = Options
		newLobby.Players = { HostID }

		LobbyManager.Lobbies[HostID] = newLobby

		local ClientData = MiscUtils.ParseLobby(newLobby)

		remotes.UpdateLobbyViewMenu:FireClient(game.Players:GetPlayerByUserId(HostID), ClientData)

		return newLobby
	end
end

function LobbyManager.GetAllLobbies()
	return LobbyManager.Lobbies
end

function LobbyManager.GetAllAvailableLobbies(plr)
	local availableLobbies = {}

	for i, lobby in pairs(LobbyManager.Lobbies) do
		if
			(lobby.Options["PlayerLimit"] > 1)
			and (
				lobby.Options["Visibility"] == 1
				or (lobby.Options["Visibility"] == 2 and plr:IsFriendsWith(lobby.HostID))
			)
		then
			availableLobbies[i] = lobby
		end
	end

	return availableLobbies
end

function LobbyManager.GetLobbyByHostID(HostID)
	if LobbyManager.Lobbies[tonumber(HostID)] then
		return LobbyManager.Lobbies[tonumber(HostID)]
	else
		return nil
	end
end

function LobbyManager.GetLobbyByLobbyID(LobbyID)
	for _, lobby in pairs(LobbyManager.Lobbies) do
		if lobby.LobbyID == LobbyID then
			return lobby
		end
	end

	return nil
end

function LobbyManager.GetPlayersLobby(PlayerID)
	for _, lobby in pairs(LobbyManager.Lobbies) do
		if table.find(lobby.Players, PlayerID) then
			return lobby
		end
	end

	return nil
end

function LobbyManager.AuthenticateHost(PlayerID, LobbyID)
	local lobby = LobbyManager.GetLobbyByLobbyID(LobbyID)

	if lobby and lobby.HostID == PlayerID then
		return true
	end

	return false
end

function LobbyManager.GrabCurrentHost(LobbyID)
	local lobby = LobbyManager.GetLobbyByLobbyID(LobbyID)

	if lobby then
		return lobby.HostID
	end

	return nil
end

function LobbyManager.UpdateLobbyListsGlobal()
	for _, plr in pairs(game.Players:GetPlayers()) do
		local lobbies = {}

		for i, v in pairs(LobbyManager.GetAllAvailableLobbies(plr)) do
			lobbies[i] = MiscUtils.ParseLobby(v)
		end

		remotes.SendLobbyUpdates:FireClient(plr, lobbies)
	end
end

return LobbyManager
