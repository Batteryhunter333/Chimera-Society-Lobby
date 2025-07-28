local ts = game:GetService("TweenService")

local template = script.Parent.PopupTemplate
local messageOrder = script.Parent.SendMessage
local responseMessageOrder = script.Parent.SendMessageWithResponse

local conversion = { true, false }

messageOrder.Event:Connect(function(messageText, buttonText)
	print("hi")
	local popup = template:Clone()
	popup.Visible = true
	popup.Parent = script.Parent.Messages

	ts:Create(
		popup.Pattern,
		TweenInfo.new(24000, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, true),
		{ Position = UDim2.fromScale(0, 0) }
	):Play()

	popup.Position = UDim2.fromScale(0.35, -0.4)
	ts:Create(
		popup,
		TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.35, 0.25) }
	):Play()

	popup.SingleOption.Button.Visible = true
	popup.SingleOption.Button.Text = buttonText
	popup.Message.Text = messageText

	popup.SingleOption.Button.MouseButton1Click:Wait()
	ts:Create(
		popup,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.35, -0.8) }
	):Play()
	task.delay(0.5, function()
		popup:Destroy()
	end)
end)

local falseConnection
local trueConnection

responseMessageOrder.OnInvoke = function(state, messageText, buttonText, buttonText2)
	if state == 1 then
		local popup = template:Clone()
		popup.Visible = true
		popup.Parent = script.Parent.Messages

		ts:Create(
			popup.Pattern,
			TweenInfo.new(24000, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, true),
			{ Position = UDim2.fromScale(0, 0) }
		):Play()

		popup.Position = UDim2.fromScale(0.35, -0.4)
		ts:Create(
			popup,
			TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.fromScale(0.35, 0.25) }
		):Play()

		popup.SingleOption.Button.Visible = true
		popup.SingleOption.Button.Text = buttonText
		popup.Message.Text = messageText

		popup.SingleOption.Button.MouseButton1Click:Wait()
		ts:Create(
			popup,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Position = UDim2.fromScale(0.35, -0.8) }
		):Play()
		task.delay(0.5, function()
			popup:Destroy()
		end)
		return true
	elseif state == 2 then
		local popup = template:Clone()
		popup.Visible = true
		popup.Parent = script.Parent.Messages

		ts:Create(
			popup.Pattern,
			TweenInfo.new(24000, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, true),
			{ Position = UDim2.fromScale(0, 0) }
		):Play()

		popup.Position = UDim2.fromScale(0.35, -0.4)
		ts:Create(
			popup,
			TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.fromScale(0.35, 0.25) }
		):Play()

		popup.TwoOptions.True.Visible = true
		popup.TwoOptions.True.Text = buttonText
		popup.TwoOptions.False.Visible = true
		popup.TwoOptions.False.Text = buttonText2
		popup.Message.Text = messageText

		trueConnection = popup.TwoOptions.True.MouseButton1Click:Once(function()
			popup.TwoOptions:SetAttribute("Decision", 1)
			falseConnection:Disconnect()
		end)

		falseConnection = popup.TwoOptions.False.MouseButton1Click:Once(function()
			popup.TwoOptions:SetAttribute("Decision", 2)
			trueConnection:Disconnect()
		end)

		popup.TwoOptions.AttributeChanged:Wait()
		ts:Create(
			popup,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Position = UDim2.fromScale(0.35, -0.8) }
		):Play()
		task.delay(0.5, function()
			popup:Destroy()
		end)
		return conversion[popup.TwoOptions:GetAttribute("Decision")]
	end

	return false
end
