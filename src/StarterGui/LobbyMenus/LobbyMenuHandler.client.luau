-- variables relevant to the whole script
local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local remotes = game.ReplicatedStorage.Remotes
local mouse = game.Players.LocalPlayer:GetMouse()

local SearchMenu = script.Parent.Search
local CreateMenu = script.Parent.Create
local PopupMenu = script.Parent.Parent.PopupSystem
local CurrentLobbyMenu = script.Parent.Parent.CurrentLobby.Menu

local DifficultySlider = CreateMenu.Menu.DifficultySelector.Slider
local PlayerSlider = CreateMenu.Menu.PlayerCountSelector.Slider
local VisibilityButtons = CreateMenu.Menu.Visibility

local SearchToggle = SearchMenu.Button
local CreateToggle = CreateMenu.Button

local sendMessage = PopupMenu.SendMessage
local sendMessageWithResponse = PopupMenu.SendMessageWithResponse

-- simple opening functions for all the menus
local menuData = {
	["Search"] = {
		["Menu"] = SearchMenu,
		[true] = UDim2.fromScale(0, 0.1),
		[false] = UDim2.fromScale(0, 0.9),
		["Deb"] = false,
		["Open"] = false,
		["Lock"] = false,
	},
	["Create"] = {
		["Menu"] = CreateMenu,
		[true] = UDim2.fromScale(0.8, 0.1),
		[false] = UDim2.fromScale(0.8, 0.9),
		["Deb"] = false,
		["Open"] = false,
		["Lock"] = false,
	},
}

local function Open(menuIndex, state, force) -- handles the opening of the two menu windows
	if (menuData[menuIndex]["Deb"] == false or force == true) and menuData[menuIndex]["Lock"] == false then
		menuData[menuIndex]["Deb"] = true

		if state == "Toggle" then
			if menuData[menuIndex]["Open"] then
				ts:Create(
					menuData[menuIndex]["Menu"],
					TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{ Position = menuData[menuIndex][false] }
				):Play()
				menuData[menuIndex]["Open"] = not menuData[menuIndex]["Open"]
			else
				ts:Create(
					menuData[menuIndex]["Menu"],
					TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{ Position = menuData[menuIndex][true] }
				):Play()
				menuData[menuIndex]["Open"] = not menuData[menuIndex]["Open"]
			end
		else
			ts:Create(
				menuData[menuIndex]["Menu"],
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ Position = menuData[menuIndex][state] }
			):Play()
			menuData[menuIndex]["Open"] = state
		end

		task.delay(0.5, function()
			menuData[menuIndex]["Deb"] = false
		end)
	end
end

-- these two are toggles that activate on the menu buttons themselves
for _, button in pairs(SearchToggle:GetChildren()) do
	button.MouseButton1Click:Connect(function()
		UpdateLobbies()
		Open("Search", "Toggle")
	end)
end

for _, button in pairs(CreateToggle:GetChildren()) do
	button.MouseButton1Click:Connect(function()
		Open("Create", "Toggle")
	end)
end

-- variables and trackers relevant to the create menu
local SelectedDifficulty = 1
local SelectedCount = 1
local SelectedVisibility = 1

local mouseDown = false
local inPlr = false
local inDif = false

uis.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = true
	end
end)
uis.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = false
	end
end)
DifficultySlider.Detector.MouseEnter:Connect(function()
	inDif = true
end)
DifficultySlider.Detector.MouseLeave:Connect(function()
	inDif = false
end)
PlayerSlider.Detector.MouseEnter:Connect(function()
	inPlr = true
end)
PlayerSlider.Detector.MouseLeave:Connect(function()
	inPlr = false
end)

local MaxSize = 0.95
local MinSize = 0

local difIncrement = 4
local difficulty = 0
local difficultyTitles = {
	":D",
	":)",
	":|",
	":(",
	">:(",
}

local plrIncrement = 5
local count = 0
local playerCountTitles = {
	"1",
	"2",
	"3",
	"4",
	"8",
	"None",
}
local playerCountNumbers = {
	1,
	2,
	3,
	4,
	8,
	999,
}

-- update function for the difficulty selection slider
local function DifficultySliderUpdate()
	local pos = (mouse.X - DifficultySlider.AbsolutePosition.X) / DifficultySlider.AbsoluteSize.X
	local translatedsize = UDim2.fromScale(
		math.round(math.clamp(pos * difIncrement, MinSize * difIncrement, MaxSize * difIncrement))
			/ difIncrement
			* MaxSize,
		0.8
	)
	local difselection = math.round(translatedsize.X.Scale / MaxSize * difIncrement)

	if difficulty ~= difselection then
		difficulty = difselection
		ts:Create(
			DifficultySlider.Frame,
			TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Size = translatedsize }
		):Play()
		DifficultySlider.Parent.Nameplate.Text = difficultyTitles[difficulty + 1]
		SelectedDifficulty = difficulty + 1
	end
end

-- nearly identical update function for the player cap selection slider
local function PlayerSliderUpdate()
	local pos = (mouse.X - PlayerSlider.AbsolutePosition.X) / PlayerSlider.AbsoluteSize.X
	local translatedsize = UDim2.fromScale(
		math.round(math.clamp(pos * plrIncrement, MinSize * plrIncrement, MaxSize * plrIncrement))
			/ plrIncrement
			* MaxSize,
		0.8
	)
	local plrselection = math.round(translatedsize.X.Scale / MaxSize * plrIncrement)

	if count ~= plrselection then
		count = plrselection
		ts:Create(
			PlayerSlider.Frame,
			TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Size = translatedsize }
		):Play()
		PlayerSlider.Parent.Nameplate.Text = playerCountTitles[count + 1]
		SelectedCount = playerCountNumbers[count + 1]
	end
end

-- ensures the sliders actually work
task.spawn(function()
	while task.wait() do
		if mouseDown == true and inPlr == true then
			PlayerSliderUpdate()
		end
		if mouseDown == true and inDif == true then
			DifficultySliderUpdate()
		end
	end
end)

-- toggles the visibility setting for the lobby
for i, button in pairs(VisibilityButtons:GetChildren()) do
	button.MouseButton1Click:Connect(function()
		SelectedVisibility = i
		for _, _ in VisibilityButtons:GetChildren() do
			button.TextColor3 = Color3.fromRGB(170, 85, 255)
			button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		end
		button.TextColor3 = Color3.fromRGB(0, 0, 0)
		button.BackgroundColor3 = Color3.fromRGB(170, 85, 255)
	end)
end

-- figures out what the hell to do when the lobby is created
local createDeb = false
CreateMenu.Menu.Create.MouseButton1Click:Connect(function()
	if createDeb == false then
		createDeb = true
		local response = PopupMenu.SendMessageWithResponse:Invoke(
			2,
			"Are you sure you are happy with these settings? You cannot adjust them after creating a lobby.",
			"Yes",
			"No"
		)
		if response then
			remotes.PostLobby:FireServer({
				["Difficulty"] = SelectedDifficulty,
				["PlayerLimit"] = SelectedCount,
				["Visibility"] = SelectedVisibility,
			})
			Open("Search", false, true)
			Open("Create", false, true)
			menuData["Search"]["Lock"] = true
			menuData["Create"]["Lock"] = true
		end
		createDeb = false
	end
end)

remotes.RemovePlayerFromLobby.OnClientEvent:Connect(function()
	menuData["Search"]["Lock"] = false
	menuData["Create"]["Lock"] = false
end)

-- variables relevant to the search menu
local currentLobbies = {}
local joinConnections = {}
local lobbyDisplays = {}
local lobbyDisplayTemplate = game.ReplicatedStorage.SharedAssets.UI.LobbyTemplate

local yScreen = mouse.ViewSizeY
local yIncrement = 0.11
local ySize = math.floor(yScreen * yIncrement)

local showFriends = true
local showPublic = true

local lobbyPlayerCountTitles = {
	[1] = "1",
	[2] = "2",
	[3] = "3",
	[4] = "4",
	[8] = "8",
	[999] = "-",
}

function CreateLobbyDisplay(id, count, dif, players, visibility) -- generates a lobby display and all of its associated functions
	if (visibility == 1 and showPublic == true) or (visibility == 2 and showFriends == true) then
		local lobbyDisplay = lobbyDisplayTemplate:Clone()
		table.insert(lobbyDisplays, lobbyDisplay)

		lobbyDisplay.Parent = SearchMenu.Lobbies
		lobbyDisplay.Name = "Lobby"
		lobbyDisplay.HostID.Value = id

		lobbyDisplay.Size = UDim2.new(1, 0, 0, ySize)
		lobbyDisplay.Position = UDim2.fromOffset(0, ySize * (#lobbyDisplays - 1))

		print(id)
		lobbyDisplay.HostName.Text = game.Players:GetPlayerByUserId(tonumber(id)).DisplayName
		lobbyDisplay.PlayerCount.Text = #players .. "/" .. lobbyPlayerCountTitles[count]
		lobbyDisplay.Difficulty.Text = difficultyTitles[dif]

		joinConnections[id] = lobbyDisplay.Join.MouseButton1Click:Connect(function()
			local success = remotes.AttemptJoinLobby:InvokeServer(id)

			if success then
				Open("Search", false, true)
				Open("Create", false, true)
				menuData["Search"]["Lock"] = true
				menuData["Create"]["Lock"] = true
			else
				PopupMenu.SendMessage:Fire(
					"Oops! It looks like you weren't able to join that lobby... Try checking if the lobby still exists, or if it is already full.",
					"Okay!"
				)
			end
		end)
	end
end

function WipeLobbys() -- clears all lobby uis and connections
	for _, v in pairs(lobbyDisplays) do
		v:Destroy()
	end
	for _, v in pairs(joinConnections) do
		v:Disconnect()
	end
	table.clear(lobbyDisplays)
end

function UpdateLobbies(lobbyList) -- updates the list of lobbies in the search menu, changes with the options set above
	ts:Create(
		SearchMenu.Bar.Reload,
		TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
		{ Rotation = SearchMenu.Bar.Reload.Rotation + 360 }
	):Play()

	if not lobbyList then
		lobbyList = remotes.GatherLobbies:InvokeServer()
	end
	currentLobbies = lobbyList
	WipeLobbys()

	for i, lobby in pairs(lobbyList) do
		CreateLobbyDisplay(
			i,
			lobby.Options["PlayerLimit"],
			lobby.Options["Difficulty"],
			lobby.Players,
			lobby.Options["Visibility"]
		)
	end
end

-- toggles to view different kinds of lobbies
local friendsToggle
local publicToggle

SearchMenu.Bar.Friends.MouseButton1Click:Connect(function()
	if friendsToggle then
		SearchMenu.Bar.Friends.BackgroundColor3 = Color3.new(1, 1, 0.5)
		SearchMenu.Bar.Friends.TextColor3 = Color3.new(0, 0, 0)
		showFriends = true
	else
		SearchMenu.Bar.Friends.BackgroundColor3 = Color3.new(0, 0, 0)
		SearchMenu.Bar.Friends.TextColor3 = Color3.new(1, 1, 0.5)
		showFriends = false
	end
	friendsToggle = not friendsToggle
end)

SearchMenu.Bar.Public.MouseButton1Click:Connect(function()
	if publicToggle then
		SearchMenu.Bar.Public.BackgroundColor3 = Color3.new(1, 1, 0.5)
		SearchMenu.Bar.Public.TextColor3 = Color3.new(0, 0, 0)
		showPublic = true
	else
		SearchMenu.Bar.Public.BackgroundColor3 = Color3.new(0, 0, 0)
		SearchMenu.Bar.Public.TextColor3 = Color3.new(1, 1, 0.5)
		showPublic = false
	end
	publicToggle = not publicToggle
end)

-- listeners for search menu updates
SearchMenu.Bar.Reload.MouseButton1Click:Connect(UpdateLobbies)
remotes.SendLobbyUpdates.OnClientEvent:Connect(function(lobbies)
	UpdateLobbies(lobbies)
end)
