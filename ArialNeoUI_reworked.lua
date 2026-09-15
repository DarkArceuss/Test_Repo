local UI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local COLORS = {
	Surface = Color3.fromRGB(206, 206, 206),
	SurfaceActive = Color3.fromRGB(180, 180, 180),
	SurfaceHover = Color3.fromRGB(218, 218, 218),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(235, 235, 235),
	Dark = Color3.fromRGB(34, 34, 34),
	Mid = Color3.fromRGB(150, 150, 150)
}

local FONT = Font.new(
	"rbxasset://fonts/families/SourceSansPro.json",
	Enum.FontWeight.Bold,
	Enum.FontStyle.Normal
)

local CONTROL_WIDTH = 430
local CORNER = UDim.new(0, 3)
local FAST_TWEEN = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SMOOTH_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function create(className, properties)
	local obj = Instance.new(className)
	for property, value in pairs(properties) do
		obj[property] = value
	end
	return obj
end

local function tween(object, info, goal)
	local tw = TweenService:Create(object, info, goal)
	tw:Play()
	return tw
end

local function addCorner(parent, radius)
	return create("UICorner", {
		CornerRadius = radius or CORNER,
		Parent = parent
	})
end

local function styleText(object, size, color)
	object.TextSize = size or 14
	object.TextColor3 = color or COLORS.Text
	object.FontFace = FONT
end

local function animateButton(button)
	local defaultColor = button.BackgroundColor3
	local hovered = false

	button.MouseEnter:Connect(function()
		hovered = true
		tween(button, FAST_TWEEN, {BackgroundColor3 = COLORS.SurfaceHover})
	end)

	button.MouseLeave:Connect(function()
		hovered = false
		tween(button, FAST_TWEEN, {BackgroundColor3 = defaultColor})
	end)

	button.MouseButton1Down:Connect(function()
		tween(button, FAST_TWEEN, {BackgroundColor3 = COLORS.SurfaceActive})
	end)

	button.MouseButton1Up:Connect(function()
		tween(button, FAST_TWEEN, {
			BackgroundColor3 = hovered and COLORS.SurfaceHover or defaultColor
		})
	end)
end

local function normalizeOptions(options)
	local result = {}

	for _, value in ipairs(options or {}) do
		if value ~= nil then
			table.insert(result, tostring(value))
		end
	end

	return result
end

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function roundToIncrement(value, minimum, increment)
	if increment <= 0 then
		return value
	end

	return minimum + math.round((value - minimum) / increment) * increment
end

local function formatNumber(value)
	if math.floor(value) == value then
		return tostring(math.floor(value))
	end

	return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
end

local function callSafely(callback, ...)
	if typeof(callback) == "function" then
		task.spawn(function(...)
			local ok, err = pcall(callback, ...)
			if not ok then
				warn("[ArialNeoUi] Callback error:", err)
			end
		end, ...)
	end
end

local function bindDrag(guiObject, handle)
	handle.Active = true
	handle.Selectable = false

	local dragging = false
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		guiObject.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			update(input)
		end
	end)
end

local function bindCanvas(scrollFrame, layout, extraPadding)
	local function update()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + extraPadding)
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	update()
end


function UI:CreateWindow(options)
	options = options or {}

	local window = {}
	local tabs = {}
	local activeTab = nil
	local opened = false
	local animating = false

	local windowName = options.Name or "ArialNeoUi"
	local titleText = options.Title or "Arial Neo Ui test"
	local iconImage = options.Icon or ""

	local screenGui = create("ScreenGui", {
		Name = windowName,
		ResetOnSpawn = false,
		Parent = PlayerGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	})

	local main = create("Frame", {
		Name = "Main",
		Parent = screenGui,
		Visible = false,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.7,
		Size = UDim2.new(0, 590, 0, 330),
		Position = UDim2.new(0, 148, 0, 6),
		AnchorPoint = Vector2.new(0, 0),
		ZIndex = 2,
		ClipsDescendants = false
	})
	addCorner(main, UDim.new(0, 5))

	local mainScale = create("UIScale", {
		Scale = 0,
		Parent = main
	})

	create("ImageLabel", {
		Name = "Dropshadow",
		Parent = main,
		ZIndex = 1,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.7,
		ImageColor3 = Color3.fromRGB(3, 3, 3),
		Image = "rbxassetid://1316045217",
		Size = UDim2.new(0, 670, 0, 392),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -40, 0, -30),
		ScaleType = Enum.ScaleType.Stretch
	})

	local title = create("TextLabel", {
		Name = "Title",
		Parent = main,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(192, 192, 192),
		BackgroundTransparency = 0.4,
		Size = UDim2.new(0, 454, 0, 32),
		Text = titleText,
		Position = UDim2.new(0, 64, 0, 12),
		ZIndex = 3
	})
	styleText(title, 18)
	addCorner(title, UDim.new(0, 5))

	local iconImg = create("ImageLabel", {
		Name = "IconImg",
		Parent = title,
		BorderSizePixel = 0,
		BackgroundColor3 = COLORS.Text,
		Size = UDim2.new(0, 34, 0, 32),
		BackgroundTransparency = 1,
		Image = iconImage,
		Position = UDim2.new(0, -50, 0, 0),
		ZIndex = 4,
		ScaleType = Enum.ScaleType.Stretch
	})
	addCorner(iconImg, UDim.new(1, 0))

	local closeButton = create("TextButton", {
		Name = "Close",
		Parent = title,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(192, 192, 192),
		BackgroundTransparency = 0.4,
		Size = UDim2.new(0, 42, 0, 32),
		Text = "X",
		Position = UDim2.new(0, 468, 0, 0),
		AutoButtonColor = false,
		ZIndex = 4
	})
	styleText(closeButton, 18)
	addCorner(closeButton, UDim.new(0, 5))

	closeButton.MouseEnter:Connect(function()
		tween(closeButton, FAST_TWEEN, {BackgroundColor3 = Color3.fromRGB(175, 175, 175)})
	end)
	closeButton.MouseLeave:Connect(function()
		tween(closeButton, FAST_TWEEN, {BackgroundColor3 = Color3.fromRGB(192, 192, 192)})
	end)
	closeButton.MouseButton1Down:Connect(function()
		tween(closeButton, FAST_TWEEN, {BackgroundColor3 = Color3.fromRGB(155, 155, 155)})
	end)

	local tabFrame = create("ScrollingFrame", {
		Name = "TabFrame",
		Parent = main,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(192, 192, 192),
		Size = UDim2.new(0, 104, 0, 258),
		Position = UDim2.new(0, 14, 0, 58),
		ScrollBarThickness = 0,
		BackgroundTransparency = 0.4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 3
	})
	addCorner(tabFrame, UDim.new(0, 5))

	create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = tabFrame
	})

	local tabLayout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = tabFrame
	})

	local pagesHolder = create("Frame", {
		Name = "PagesHolder",
		Parent = main,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 446, 0, 258),
		Position = UDim2.new(0, 128, 0, 58),
		ClipsDescendants = true,
		ZIndex = 3
	})

	local openGui = create("ImageButton", {
		Name = "OpenGui",
		Parent = screenGui,
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(192, 192, 192),
		Size = UDim2.new(0, 50, 0, 50),
		Position = UDim2.new(0, 62, 0, 16),
		AnchorPoint = Vector2.new(0, 0),
		Image = iconImage,
		AutoButtonColor = false,
		Visible = true,
		BackgroundTransparency = 0,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 2
	})
	addCorner(openGui, UDim.new(0, 3))

	local openScale = create("UIScale", {
		Scale = 1,
		Parent = openGui
	})

	bindDrag(main, title)
	bindDrag(openGui, openGui)

	local function refreshTabs()
		for _, tabData in ipairs(tabs) do
			local target = tabData == activeTab and COLORS.SurfaceActive or COLORS.Surface
			tween(tabData.Button, FAST_TWEEN, {BackgroundColor3 = target})
		end
	end

	local function transitionToPage(newPage, oldPage)
		if not newPage then
			return
		end

		local info = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		newPage.Visible = true
		newPage.BackgroundTransparency = 1
		newPage.Position = UDim2.new(0, 12, 0, 0)

		tween(newPage, info, {
			BackgroundTransparency = 0.4,
			Position = UDim2.new(0, 0, 0, 0)
		})

		if oldPage and oldPage ~= newPage then
			tween(oldPage, info, {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, -12, 0, 0)
			}).Completed:Once(function()
				if oldPage ~= newPage then
					oldPage.Visible = false
					oldPage.Position = UDim2.new(0, 0, 0, 0)
					oldPage.BackgroundTransparency = 0.4
				end
			end)
		end
	end

	local function setActiveTab(tabData)
		if activeTab == tabData then
			return
		end

		local previous = activeTab
		activeTab = tabData
		refreshTabs()

		for _, tab in ipairs(tabs) do
			if tab ~= tabData then
				tab.Page.Visible = false
				tab.Page.BackgroundTransparency = 0.4
				tab.Page.Position = UDim2.new(0, 0, 0, 0)
			end
		end

		transitionToPage(tabData.Page, previous and previous.Page or nil)
	end

	local function showWindow()
		if animating or opened then
			return
		end

		animating = true
		main.Visible = true
		openGui.Visible = true
		mainScale.Scale = 0
		openScale.Scale = 1

		local mainTween = tween(mainScale, SMOOTH_TWEEN, {Scale = 1})
		tween(openScale, SMOOTH_TWEEN, {Scale = 0})

		mainTween.Completed:Once(function()
			openGui.Visible = false
			opened = true
			animating = false
		end)
	end

	local function hideWindow()
		if animating or not opened then
			return
		end

		animating = true
		main.Visible = true
		openGui.Visible = true
		mainScale.Scale = 1
		openScale.Scale = 0

		local mainTween = tween(mainScale, SMOOTH_TWEEN, {Scale = 0})
		tween(openScale, SMOOTH_TWEEN, {Scale = 1})

		mainTween.Completed:Once(function()
			main.Visible = false
			opened = false
			animating = false
		end)
	end

	closeButton.MouseButton1Click:Connect(hideWindow)
	openGui.MouseButton1Click:Connect(showWindow)

	function window:AddTab(tabOptions)
		tabOptions = tabOptions or {}

		local tabName = tabOptions.TabName or "Test tab"

		local tabButton = create("TextButton", {
			Name = "TabButton",
			Parent = tabFrame,
			TextWrapped = true,
			BorderSizePixel = 0,
			BackgroundColor3 = COLORS.Surface,
			Size = UDim2.new(0, 90, 0, 36),
			Text = tabName,
			AutoButtonColor = false,
			ZIndex = 4
		})
		styleText(tabButton, 14)
		addCorner(tabButton)
		animateButton(tabButton)

		local pageFrame = create("ScrollingFrame", {
			Name = "PageFrame",
			Parent = pagesHolder,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(192, 192, 192),
			Size = UDim2.new(0, 446, 0, 258),
			Position = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 0,
			BackgroundTransparency = 0.4,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			ZIndex = 3
		})
		addCorner(pageFrame)

		create("UIPadding", {
			Parent = pageFrame,
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8)
		})

		local pageLayout = create("UIListLayout", {
			Parent = pageFrame,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center
		})

		bindCanvas(pageFrame, pageLayout, 16)

		local tabData = {
			Button = tabButton,
			Page = pageFrame
		}

		function tabData:AddButton(buttonOptions)
			buttonOptions = buttonOptions or {}

			local buttonName = buttonOptions.Name or "Test button"
			local callback = buttonOptions.Callback

			local button = create("TextButton", {
				Name = "Button",
				Parent = pageFrame,
				TextWrapped = true,
				BorderSizePixel = 0,
				BackgroundColor3 = COLORS.Surface,
				Size = UDim2.new(0, CONTROL_WIDTH, 0, 36),
				Text = buttonName,
				AutoButtonColor = false,
				ZIndex = 4
			})
			styleText(button, 14)
			addCorner(button)
			animateButton(button)

			button.MouseButton1Click:Connect(function()
				callSafely(callback)
			end)

			return button
		end

		function tabData:AddSlider(sliderOptions)
			sliderOptions = sliderOptions or {}

			local minimum = tonumber(sliderOptions.Min) or 0
			local maximum = tonumber(sliderOptions.Max) or 100
			local increment = math.abs(tonumber(sliderOptions.Increment) or 1)
			local suffix = tostring(sliderOptions.Suffix or "")
			local value = clamp(tonumber(sliderOptions.Default) or minimum, minimum, maximum)
			value = clamp(roundToIncrement(value, minimum, increment), minimum, maximum)

			local holder = create("Frame", {
				Name = "Slider",
				Parent = pageFrame,
				BackgroundColor3 = COLORS.Surface,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Size = UDim2.new(0, CONTROL_WIDTH, 0, 58),
				ZIndex = 4
			})
			addCorner(holder)

			local label = create("TextLabel", {
				Name = "Label",
				Parent = holder,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -76, 0, 22),
				Position = UDim2.new(0, 12, 0, 4),
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = tostring(sliderOptions.Name or "Slider"),
				ZIndex = 5
			})
			styleText(label, 14)

			local valueLabel = create("TextLabel", {
				Name = "Value",
				Parent = holder,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 62, 0, 22),
				Position = UDim2.new(1, -72, 0, 4),
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = formatNumber(value) .. suffix,
				ZIndex = 5
			})
			styleText(valueLabel, 13, COLORS.Muted)

			local track = create("Frame", {
				Name = "Track",
				Parent = holder,
				BackgroundColor3 = Color3.fromRGB(184, 184, 184),
				BorderSizePixel = 0,
				Size = UDim2.new(1, -24, 0, 8),
				Position = UDim2.new(0, 12, 0, 39),
				ZIndex = 5
			})
			addCorner(track, UDim.new(1, 0))

			local fill = create("Frame", {
				Name = "Fill",
				Parent = track,
				BackgroundColor3 = COLORS.SurfaceActive,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 0, 1, 0),
				ZIndex = 6
			})
			addCorner(fill, UDim.new(1, 0))

			local knob = create("Frame", {
				Name = "Knob",
				Parent = track,
				BackgroundColor3 = COLORS.Text,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 14, 0, 14),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				ZIndex = 7
			})
			addCorner(knob, UDim.new(1, 0))

			local dragButton = create("TextButton", {
				Name = "Input",
				Parent = holder,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -20, 0, 26),
				Position = UDim2.new(0, 10, 0, 32),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 8
			})

			local function render(newValue, fireCallback)
				value = clamp(roundToIncrement(newValue, minimum, increment), minimum, maximum)
				local alpha = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)

				valueLabel.Text = formatNumber(value) .. suffix
				tween(fill, FAST_TWEEN, {Size = UDim2.new(alpha, 0, 1, 0)})
				tween(knob, FAST_TWEEN, {Position = UDim2.new(alpha, 0, 0.5, 0)})

				if fireCallback then
					callSafely(sliderOptions.Callback, value)
				end
			end

			local function updateFromPosition(x)
				local left = track.AbsolutePosition.X
				local width = track.AbsoluteSize.X
				local alpha = width <= 0 and 0 or clamp((x - left) / width, 0, 1)
				render(minimum + (maximum - minimum) * alpha, true)
			end

			local dragging = false

			dragButton.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					updateFromPosition(input.Position.X)

					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
						end
					end)
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromPosition(input.Position.X)
				end
			end)

			holder.MouseEnter:Connect(function()
				tween(track, FAST_TWEEN, {BackgroundColor3 = Color3.fromRGB(174, 174, 174)})
				tween(knob, FAST_TWEEN, {Size = UDim2.new(0, 16, 0, 16)})
			end)

			holder.MouseLeave:Connect(function()
				tween(track, FAST_TWEEN, {BackgroundColor3 = Color3.fromRGB(184, 184, 184)})
				tween(knob, FAST_TWEEN, {Size = UDim2.new(0, 14, 0, 14)})
			end)

			render(value, false)

			local slider = holder
			function slider:Set(newValue)
				render(tonumber(newValue) or minimum, true)
			end

			function slider:Get()
				return value
			end

			return slider
		end

		function tabData:AddTextbox(textboxOptions)
			textboxOptions = textboxOptions or {}

			local holder = create("Frame", {
				Name = "Textbox",
				Parent = pageFrame,
				BackgroundColor3 = COLORS.Surface,
				BorderSizePixel = 0,
				Size = UDim2.new(0, CONTROL_WIDTH, 0, 58),
				ZIndex = 4
			})
			addCorner(holder)

			local label = create("TextLabel", {
				Name = "Label",
				Parent = holder,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -20, 0, 20),
				Position = UDim2.new(0, 12, 0, 4),
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = tostring(textboxOptions.Name or "Textbox"),
				ZIndex = 5
			})
			styleText(label, 14)

			local box = create("TextBox", {
				Name = "Input",
				Parent = holder,
				BackgroundColor3 = Color3.fromRGB(192, 192, 192),
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -24, 0, 27),
				Position = UDim2.new(0, 12, 0, 27),
				ClearTextOnFocus = textboxOptions.ClearOnFocus == true,
				PlaceholderText = tostring(textboxOptions.PlaceholderText or ""),
				Text = tostring(textboxOptions.Default or ""),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 5
			})
			styleText(box, 13)
			addCorner(box)

			create("UIPadding", {
				Parent = box,
				PaddingLeft = UDim.new(0, 9),
				PaddingRight = UDim.new(0, 9)
			})

			box.Focused:Connect(function()
				tween(box, FAST_TWEEN, {BackgroundTransparency = 0})
				tween(holder, FAST_TWEEN, {BackgroundColor3 = COLORS.SurfaceHover})
			end)

			box.FocusLost:Connect(function(enterPressed)
				tween(box, FAST_TWEEN, {BackgroundTransparency = 0.12})
				tween(holder, FAST_TWEEN, {BackgroundColor3 = COLORS.Surface})
				callSafely(textboxOptions.Callback, box.Text, enterPressed)
			end)

			local textbox = holder
			function textbox:Set(valueToSet)
				box.Text = tostring(valueToSet or "")
			end

			function textbox:Get()
				return box.Text
			end

			textbox.Input = box
			return textbox
		end

		function tabData:AddToggle(toggleOptions)
			toggleOptions = toggleOptions or {}

			local enabled = toggleOptions.Default == true

			local holder = create("TextButton", {
				Name = "Toggle",
				Parent = pageFrame,
				BackgroundColor3 = COLORS.Surface,
				BorderSizePixel = 0,
				Size = UDim2.new(0, CONTROL_WIDTH, 0, 48),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 4
			})
			addCorner(holder)

			local label = create("TextLabel", {
				Name = "Label",
				Parent = holder,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -86, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = tostring(toggleOptions.Name or "Toggle"),
				ZIndex = 5
			})
			styleText(label, 14)

			local switch = create("Frame", {
				Name = "Switch",
				Parent = holder,
				BackgroundColor3 = Color3.fromRGB(186, 186, 186),
				BorderSizePixel = 0,
				Size = UDim2.new(0, 48, 0, 24),
				Position = UDim2.new(1, -60, 0.5, -12),
				ZIndex = 5
			})
			addCorner(switch, UDim.new(1, 0))

			local switchKnob = create("Frame", {
				Name = "Knob",
				Parent = switch,
				BackgroundColor3 = COLORS.Text,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(0, 3, 0.5, -9),
				ZIndex = 6
			})
			addCorner(switchKnob, UDim.new(1, 0))

			local indicator = create("Frame", {
				Name = "Indicator",
				Parent = switchKnob,
				BackgroundColor3 = COLORS.SurfaceActive,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 5, 0, 5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				ZIndex = 7
			})
			addCorner(indicator, UDim.new(1, 0))

			local function render(state, fireCallback)
				enabled = state == true

				tween(switch, FAST_TWEEN, {
					BackgroundColor3 = enabled and COLORS.SurfaceActive or Color3.fromRGB(186, 186, 186)
				})

				tween(switchKnob, SMOOTH_TWEEN, {
					Position = enabled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
				})

				tween(indicator, FAST_TWEEN, {
					BackgroundColor3 = enabled and COLORS.Dark or COLORS.SurfaceActive
				})

				if fireCallback then
					callSafely(toggleOptions.Callback, enabled)
				end
			end

			holder.MouseEnter:Connect(function()
				tween(holder, FAST_TWEEN, {BackgroundColor3 = COLORS.SurfaceHover})
				tween(switch, FAST_TWEEN, {Size = UDim2.new(0, 50, 0, 25)})
			end)

			holder.MouseLeave:Connect(function()
				tween(holder, FAST_TWEEN, {BackgroundColor3 = COLORS.Surface})
				tween(switch, FAST_TWEEN, {Size = UDim2.new(0, 48, 0, 24)})
			end)

			holder.MouseButton1Click:Connect(function()
				render(not enabled, true)
			end)

			render(enabled, false)

			function holder:Set(state)
				render(state == true, true)
			end

			function holder:Get()
				return enabled
			end

			return holder
		end

		function tabData:AddDropdown(dropdownOptions)
			dropdownOptions = dropdownOptions or {}

			local optionsList = normalizeOptions(dropdownOptions.Options)
			local selected = dropdownOptions.Default ~= nil and tostring(dropdownOptions.Default) or optionsList[1]
			local expanded = false
			local itemHeight = 30
			local baseHeight = 42
			local expandedHeight = baseHeight + (#optionsList * itemHeight) + (#optionsList > 0 and 6 or 0)

			local holder = create("Frame", {
				Name = "Dropdown",
				Parent = pageFrame,
				BackgroundColor3 = COLORS.Surface,
				BorderSizePixel = 0,
				Size = UDim2.new(0, CONTROL_WIDTH, 0, baseHeight),
				ClipsDescendants = true,
				ZIndex = 4
			})
			addCorner(holder)

			local button = create("TextButton", {
				Name = "Button",
				Parent = holder,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, baseHeight),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 6
			})

			local label = create("TextLabel", {
				Name = "Label",
				Parent = button,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(0.5, -12, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = tostring(dropdownOptions.Name or "Dropdown"),
				ZIndex = 7
			})
			styleText(label, 14)

			local selectedLabel = create("TextLabel", {
				Name = "Selected",
				Parent = button,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(0.5, -42, 1, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = selected or "Select...",
				ZIndex = 7
			})
			styleText(selectedLabel, 13, COLORS.Muted)

			local chevron = create("TextLabel", {
				Name = "Chevron",
				Parent = button,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 22, 1, 0),
				Position = UDim2.new(1, -30, 0, 0),
				Text = "⌄",
				ZIndex = 7
			})
			styleText(chevron, 16)

			local list = create("Frame", {
				Name = "Options",
				Parent = holder,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -16, 0, #optionsList * itemHeight),
				Position = UDim2.new(0, 8, 0, baseHeight + 4),
				ZIndex = 6
			})

			local listLayout = create("UIListLayout", {
				Parent = list,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 3)
			})

			local function setExpanded(state)
				expanded = state
				tween(holder, SMOOTH_TWEEN, {
					Size = UDim2.new(0, CONTROL_WIDTH, 0, expanded and expandedHeight or baseHeight)
				})
				tween(chevron, FAST_TWEEN, {
					Rotation = expanded and 180 or 0
				})
			end

			local function select(value, fireCallback)
				selected = tostring(value)
				selectedLabel.Text = selected
				setExpanded(false)

				if fireCallback then
					callSafely(dropdownOptions.Callback, selected)
				end
			end

			for index, option in ipairs(optionsList) do
				local optionButton = create("TextButton", {
					Name = "Option" .. index,
					Parent = list,
					BackgroundColor3 = Color3.fromRGB(192, 192, 192),
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, itemHeight),
					Text = option,
					AutoButtonColor = false,
					ZIndex = 7,
					LayoutOrder = index
				})
				styleText(optionButton, 13)
				addCorner(optionButton)
				animateButton(optionButton)

				optionButton.MouseButton1Click:Connect(function()
					select(option, true)
				end)
			end

			button.MouseEnter:Connect(function()
				tween(holder, FAST_TWEEN, {BackgroundColor3 = COLORS.SurfaceHover})
			end)

			button.MouseLeave:Connect(function()
				if not expanded then
					tween(holder, FAST_TWEEN, {BackgroundColor3 = COLORS.Surface})
				end
			end)

			button.MouseButton1Click:Connect(function()
				setExpanded(not expanded)
				tween(holder, FAST_TWEEN, {
					BackgroundColor3 = expanded and COLORS.SurfaceHover or COLORS.Surface
				})
			end)

			local dropdown = holder

			function dropdown:Set(value)
				if value == nil then
					return false
				end

				local valueText = tostring(value)
				for _, option in ipairs(optionsList) do
					if option == valueText then
						select(option, true)
						return true
					end
				end

				return false
			end

			function dropdown:SetOptions(newOptions)
				optionsList = normalizeOptions(newOptions)
				selected = optionsList[1]
				selectedLabel.Text = selected or "Select..."

				for _, child in ipairs(list:GetChildren()) do
					if child:IsA("TextButton") then
						child:Destroy()
					end
				end

				for index, option in ipairs(optionsList) do
					local optionButton = create("TextButton", {
						Name = "Option" .. index,
						Parent = list,
						BackgroundColor3 = Color3.fromRGB(192, 192, 192),
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, itemHeight),
						Text = option,
						AutoButtonColor = false,
						ZIndex = 7,
						LayoutOrder = index
					})
					styleText(optionButton, 13)
					addCorner(optionButton)
					animateButton(optionButton)
					optionButton.MouseButton1Click:Connect(function()
						select(option, true)
					end)
				end

				expandedHeight = baseHeight + (#optionsList * itemHeight) + (#optionsList > 0 and 6 or 0)
				list.Size = UDim2.new(1, -16, 0, #optionsList * itemHeight)
				setExpanded(expanded)
			end

			function dropdown:Get()
				return selected
			end

			return dropdown
		end

		tabButton.MouseButton1Click:Connect(function()
			setActiveTab(tabData)
		end)

		table.insert(tabs, tabData)

		if not activeTab then
			activeTab = tabData
			tabData.Page.Visible = true
			tabData.Page.BackgroundTransparency = 0.4
			tabData.Page.Position = UDim2.new(0, 0, 0, 0)
			refreshTabs()
		else
			refreshTabs()
		end

		return tabData
	end

	function window:Show()
		showWindow()
	end

	function window:Hide()
		hideWindow()
	end

	function window:SetTitle(text)
		title.Text = tostring(text or "")
	end

	window.ScreenGui = screenGui
	window.Main = main
	window.Dropshadow = main:FindFirstChild("Dropshadow")
	window.Title = title
	window.IconImg = iconImg
	window.Close = closeButton
	window.OpenGui = openGui
	window.TabFrame = tabFrame
	window.PagesHolder = pagesHolder

	return window
end

return UI
