local ts = game:GetService("TweenService")
local remotes = game.ReplicatedStorage.Remotes
local popup = script.Parent.Parent.PopupSystem
local menu = script.Parent.Menu
local player_display = game.ReplicatedStorage.SharedAssets.UI.DisplayTemplatePlayer
local host_display = game.ReplicatedStorage.SharedAssets.UI.DisplayTemplateHost

local toggleButton = script.Parent.Menu.Toggle
local toggle = true
local toggleDeb = false
local toggleable = false

local currentRank
local currentLobby = {}
local currentHostID

local yScreen = game.Players.LocalPlayer:GetMouse().ViewSizeY
local yIncrement = 0.055
local ySize = math.floor(yScreen * yIncrement)

local playerDisplays = {}
local kickPlayerConnections = {}

local lobbyPlayerCountTitles = {
	[1] = "1",
	[2] = "2",
	[3] = "3",
	[4] = "4",
	[8] = "8",
	[999] = "-",
}

local difficultyTitles = {
	":D",
	":)",
	":|",
	":(",
	">:(",
}

toggleButton.MouseButton1Click:Connect(function() -- allows you to toggle the menu when possible
	if toggleDeb == false and toggleable then
		toggleDeb = true

		if toggle then
			toggle = not toggle
			ts:Create(
				script.Parent.Menu,
				TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Position = UDim2.fromScale(-0.225, 0) }
			):Play()
			script.Parent.Menu.Toggle.Text = ">"
		else
			toggle = not toggle
			ts:Create(
				script.Parent.Menu,
				TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Position = UDim2.fromScale(0, 0) }
			):Play()
			script.Parent.Menu.Toggle.Text = "<"
		end

		toggleDeb = false
	end
end)

local function Close()
	ts:Create(
		script.Parent.Menu,
		TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(-0.5, 0) }
	):Play()
	toggleable = false
end

local function Open()
	ts:Create(
		script.Parent.Menu,
		TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0, 0) }
	):Play()
	script.Parent.Menu.Toggle.Text = "<"
	toggleable = true
end

local function WipePlayerDisplays()
	for _, display in pairs(playerDisplays) do
		display:Destroy()
	end
	for _, connection in pairs(kickPlayerConnections) do
		connection:Disconnect()
	end

	table.clear(playerDisplays)
	table.clear(kickPlayerConnections)
end

local function GeneratePlayerDisplays()
	if remotes.AuthenticateHost:InvokeServer(currentLobby.LobbyID) then
		for i, playerid in pairs(currentLobby.Players) do
			local display
			local plr = game.Players:GetPlayerByUserId(playerid)

			if playerid == game.Players.LocalPlayer.UserId then
				display = player_display:Clone()
				display.StatusDisplay.Image = "rbxassetid://11919061440"
			else
				display = host_display:Clone()

				local connection = display.KickPlayer.MouseButton1Click:Connect(function()
					remotes.RemovePlayerFromLobby:FireServer(
						currentLobby.LobbyID,
						playerid,
						"You were removed from the lobby by the host. Don't ask me why I'm just a popup, this is my day job."
					)
				end)
				table.insert(kickPlayerConnections, connection)
			end

			display.Parent = menu.PlayersDisplay
			display.Size = UDim2.new(1, 0, 0, ySize)
			display.Position = UDim2.fromOffset(0, (i - 1) * ySize)
			display.PlayerName.Text = plr.DisplayName

			table.insert(playerDisplays, display)
		end
	else
		for i, playerid in pairs(currentLobby.Players) do
			local display = player_display:Clone()
			local plr = game.Players:GetPlayerByUserId(playerid)
			display.Parent = menu.PlayersDisplay
			display.Size = UDim2.new(1, 0, 0, ySize)
			display.Position = UDim2.fromOffset(0, (i - 1) * ySize)
			display.PlayerName.Text = plr.DisplayName

			table.insert(playerDisplays, display)

			if playerid == currentHostID then
				display.StatusDisplay.Image = "rbxassetid://11919061440"
			else
				display.StatusDisplay.Image = "rbxassetid://17193841062"
			end
		end
	end
end

remotes.UpdateLobbyViewMenu.OnClientEvent:Connect(function(lobby)
	if currentLobby.LobbyID ~= lobby.LobbyID then
		Open()
		menu.PlayerElements.Message.Text = "Waiting for host to start..."
		menu.HostElements.MessageEditor.Text = "Waiting for host to start..."
		for _, element in pairs(menu.PlayerElements:GetChildren()) do
			element.Visible = false
		end
		for _, element in pairs(menu.HostElements:GetChildren()) do
			element.Visible = false
		end
	end

	currentLobby = lobby
	if remotes.AuthenticateHost:InvokeServer(currentLobby.LobbyID) then
		currentRank = "Host"
	else
		currentRank = "Player"
	end

	currentHostID = remotes.GrabCurrentHost:InvokeServer(currentLobby.LobbyID) -- keeps the value tracking the lobby host updated

	local rankElements = menu:FindFirstChild(currentRank .. "Elements")
	if rankElements then
		for _, element in pairs(rankElements:GetChildren()) do
			element.Visible = true
		end
	end

	menu.PlayerCount.Text = #currentLobby.Players .. "/" .. lobbyPlayerCountTitles[currentLobby.Options["PlayerLimit"]]
	menu.Difficulty.Text = difficultyTitles[currentLobby.Options["Difficulty"]]

	WipePlayerDisplays()
	GeneratePlayerDisplays()
end)

remotes.RemovePlayerFromLobby.OnClientEvent:Connect(function(message)
	if message then
		script.Parent.Parent.PopupSystem.SendMessage:Fire(message, "Okay")
	end
	currentLobby = {}
	currentRank = nil
	currentHostID = nil
	Close()
end)

remotes.TeleportPlayersInLobby.OnClientEvent:Connect(function()
	Close()
end)

remotes.UpdateCurrentLobbyMessage.OnClientEvent:Connect(function(message)
	if currentRank == "Host" then
		menu.HostElements.MessageEditor.Text = message
	else
		menu.PlayerElements.Message.Text = message
	end
end)

script.Parent.Menu.HostElements.MessageEditor.FocusLost:Connect(function()
	remotes.UpdateCurrentLobbyMessage:FireServer(
		currentLobby.LobbyID,
		script.Parent.Menu.HostElements.MessageEditor.Text
	)
end)

script.Parent.Menu.PlayerElements.Leave.MouseButton1Click:Connect(function()
	remotes.RemovePlayerFromLobby:FireServer(
		currentLobby.LobbyID,
		game.Players.LocalPlayer.UserId,
		"You left your current lobby. I'm sure they'll be so lonely without you."
	)
end)

local disbandDeb = false
script.Parent.Menu.HostElements.Disband.MouseButton1Click:Connect(function()
	if disbandDeb == false then
		disbandDeb = true
		local response = popup.SendMessageWithResponse:Invoke(
			2,
			"Are you sure you wish to disband this lobby? Doing so will kick everyone else currently inside of said lobby, and you will have to create a new one.",
			"Yes",
			"No"
		)

		if response then
			print(currentLobby.LobbyID)
			remotes.DeleteLobby:FireServer(currentLobby.LobbyID)
		end
		disbandDeb = false
	end
end)

local playDeb = false
script.Parent.Menu.HostElements.Play.MouseButton1Click:Connect(function()
	if playDeb == false then
		playDeb = true
		local response = popup.SendMessageWithResponse:Invoke(
			2,
			"Are you ready to play? Make sure you have everyone you want and they're all ready because I'm just here to get y'all in, being ready is YOUR responsibility!",
			"Yes",
			"No"
		)

		if response then
			remotes.TeleportPlayersInLobby:FireServer(currentLobby.LobbyID)
		end
		playDeb = false
	end
end)
