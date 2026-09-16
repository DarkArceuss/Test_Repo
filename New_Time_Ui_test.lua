-- NewTimeUI v3
-- Reworked UI library with stable layout, mobile scaling and smoother animations.
-- API kept compatible with NewTimeUI v2.

local UI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("[NewTimeUI] LocalPlayer is not available")
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local COLORS = {
    Surface = Color3.fromRGB(206, 206, 206),
    SurfaceActive = Color3.fromRGB(180, 180, 180),
    SurfaceHover = Color3.fromRGB(218, 218, 218),
    Text = Color3.fromRGB(255, 255, 255),
    Muted = Color3.fromRGB(235, 235, 235),
    Dark = Color3.fromRGB(34, 34, 34),
    Mid = Color3.fromRGB(150, 150, 150),
    Track = Color3.fromRGB(184, 184, 184),
    Input = Color3.fromRGB(192, 192, 192),
}

local FONT = Font.new(
    "rbxasset://fonts/families/SourceSansPro.json",
    Enum.FontWeight.Bold,
    Enum.FontStyle.Normal
)

local CONTROL_WIDTH = 430
local CORNER = UDim.new(0, 3)

local FAST_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local SMOOTH_TWEEN = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SPRING_TWEEN = TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SOFT_TWEEN = TweenInfo.new(0.24, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local function create(className, properties)
    local obj = Instance.new(className)
    for property, value in pairs(properties or {}) do
        local ok, err = pcall(function()
            obj[property] = value
        end)
        if not ok then
            warn("[NewTimeUI] Failed to set property", property, "on", className, err)
        end
    end
    return obj
end

local function tween(object, info, goal)
    if not object or object.Parent == nil then
        return nil
    end

    local ok, tw = pcall(TweenService.Create, TweenService, object, info, goal)
    if not ok then
        warn("[NewTimeUI] Tween error:", tw)
        return nil
    end

    tw:Play()
    return tw
end

local function cancelTween(tweenObject)
    if tweenObject then
        pcall(function()
            tweenObject:Cancel()
        end)
    end
end

local function addCorner(parent, radius)
    return create("UICorner", {
        CornerRadius = radius or CORNER,
        Parent = parent,
    })
end

local function styleText(object, size, color)
    object.TextSize = size or 14
    object.TextColor3 = color or COLORS.Text
    object.FontFace = FONT
end

local function addStroke(parent, transparency)
    return create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
        Transparency = transparency or 0.82,
        Parent = parent,
    })
end

local function animateButton(button, options)
    options = options or {}

    local defaultColor = button.BackgroundColor3
    local hoverColor = options.HoverColor or COLORS.SurfaceHover
    local activeColor = options.ActiveColor or COLORS.SurfaceActive
    local hoverScale = options.HoverScale or 1.018
    local activeScale = options.ActiveScale or 0.985

    local scale = create("UIScale", {
        Scale = 1,
        Parent = button,
    })

    local colorTween
    local scaleTween
    local hovered = false

    local function paint(color, scaleValue, info)
        cancelTween(colorTween)
        cancelTween(scaleTween)
        colorTween = tween(button, info, {BackgroundColor3 = color})
        scaleTween = tween(scale, info, {Scale = scaleValue})
    end

    button.MouseEnter:Connect(function()
        hovered = true
        paint(hoverColor, hoverScale, FAST_TWEEN)
    end)

    button.MouseLeave:Connect(function()
        hovered = false
        paint(defaultColor, 1, SOFT_TWEEN)
    end)

    button.MouseButton1Down:Connect(function()
        paint(activeColor, activeScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    end)

    button.MouseButton1Up:Connect(function()
        paint(hovered and hoverColor or defaultColor, hovered and hoverScale or 1, FAST_TWEEN)
    end)

    return scale
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
    if minimum > maximum then
        minimum, maximum = maximum, minimum
    end
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
                warn("[NewTimeUI] Callback error:", err)
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
        if not dragging or not dragStart or not startPos then
            return
        end

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

function UI:CreateWindow(options)
    options = options or {}

    local window = {}
    local tabs = {}
    local activeTab = nil
    local opened = false
    local animating = false
    local activePageTween

    local windowName = tostring(options.Name or "NewTimeUI")
    local titleText = tostring(options.Title or "New Time UI")
    local iconImage = tostring(options.Icon or "")

    local existing = PlayerGui:FindFirstChild(windowName)
    if existing then
        existing:Destroy()
    end

    local screenGui = create("ScreenGui", {
        Name = windowName,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = PlayerGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    local main = create("Frame", {
        Name = "Main",
        Parent = screenGui,
        Visible = false,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.7,
        Size = UDim2.new(0, 590, 0, 330),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 2,
        ClipsDescendants = false,
    })
    addCorner(main, UDim.new(0, 5))

    local mainScale = create("UIScale", {
        Scale = 0.92,
        Parent = main,
    })

    local mainAspect = create("UIAspectRatioConstraint", {
        AspectRatio = 590 / 330,
        Parent = main,
    })

    local dropshadow = create("ImageLabel", {
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
        ScaleType = Enum.ScaleType.Stretch,
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
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    })
    styleText(title, 18)
    addCorner(title, UDim.new(0, 5))

    local titlePadding = create("UIPadding", {
        Parent = title,
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 52),
    })

    local iconImg = create("ImageLabel", {
        Name = "IconImg",
        Parent = main,
        BorderSizePixel = 0,
        BackgroundColor3 = COLORS.Text,
        Size = UDim2.new(0, 34, 0, 32),
        BackgroundTransparency = 1,
        Image = iconImage,
        Position = UDim2.new(0, 20, 0, 12),
        ZIndex = 4,
        ScaleType = Enum.ScaleType.Stretch,
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
        Position = UDim2.new(1, -42, 0, 0),
        AutoButtonColor = false,
        ZIndex = 4,
    })
    styleText(closeButton, 18)
    addCorner(closeButton, UDim.new(0, 5))
    animateButton(closeButton, {
        HoverColor = Color3.fromRGB(175, 175, 175),
        ActiveColor = Color3.fromRGB(155, 155, 155),
        HoverScale = 1.04,
    })

    local tabFrame = create("ScrollingFrame", {
        Name = "TabFrame",
        Parent = main,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(192, 192, 192),
        Size = UDim2.new(0, 104, 0, 258),
        Position = UDim2.new(0, 14, 0, 58),
        ScrollBarThickness = 0,
        ScrollingEnabled = true,
        Active = true,
        BackgroundTransparency = 0.4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        ZIndex = 3,
    })
    addCorner(tabFrame, UDim.new(0, 5))

    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        Parent = tabFrame,
    })

    local tabLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = tabFrame,
    })

    local pagesHolder = create("Frame", {
        Name = "PagesHolder",
        Parent = main,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 446, 0, 258),
        Position = UDim2.new(0, 128, 0, 58),
        ClipsDescendants = true,
        ZIndex = 3,
    })

    local openGui = create("ImageButton", {
        Name = "OpenGui",
        Parent = screenGui,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(192, 192, 192),
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0, 0),
        Image = iconImage,
        AutoButtonColor = false,
        Visible = true,
        BackgroundTransparency = 0,
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = 2,
    })
    addCorner(openGui, UDim.new(0, 5))
    local openScale = create("UIScale", {
        Scale = 1,
        Parent = openGui,
    })
    animateButton(openGui, {
        HoverColor = Color3.fromRGB(218, 218, 218),
        ActiveColor = Color3.fromRGB(170, 170, 170),
        HoverScale = 1.05,
    })

    bindDrag(main, title)
    bindDrag(openGui, openGui)

    local function updateResponsiveScale()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        if viewport.X <= 0 or viewport.Y <= 0 then
            return
        end

        local maxWidth = math.max(280, viewport.X - 24)
        local maxHeight = math.max(220, viewport.Y - 24)
        local fitScale = math.min(maxWidth / 590, maxHeight / 330)
        fitScale = math.clamp(fitScale, 0.54, 1.06)

        if not opened then
            mainScale.Scale = fitScale * 0.92
        else
            mainScale.Scale = fitScale
        end
    end

    local function refreshTabs()
        for _, tabData in ipairs(tabs) do
            local active = tabData == activeTab
            local target = active and COLORS.SurfaceActive or COLORS.Surface
            tween(tabData.Button, FAST_TWEEN, {BackgroundColor3 = target})
            if tabData.Indicator then
                tween(tabData.Indicator, SOFT_TWEEN, {
                    BackgroundTransparency = active and 0 or 1,
                    Size = active and UDim2.new(0, 3, 1, -10) or UDim2.new(0, 3, 0, 0),
                })
            end
        end
    end

    local function transitionToPage(newPage, oldPage)
        if not newPage then
            return
        end

        cancelTween(activePageTween)

        newPage.Visible = true
        newPage.BackgroundTransparency = 1
        newPage.Position = UDim2.new(0, 18, 0, 0)

        activePageTween = tween(newPage, SMOOTH_TWEEN, {
            BackgroundTransparency = 0.4,
            Position = UDim2.new(0, 0, 0, 0),
        })

        if oldPage and oldPage ~= newPage then
            tween(oldPage, SOFT_TWEEN, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, -18, 0, 0),
            })

            task.delay(0.24, function()
                if oldPage ~= newPage and oldPage.Parent then
                    oldPage.Visible = false
                    oldPage.Position = UDim2.new(0, 0, 0, 0)
                    oldPage.BackgroundTransparency = 0.4
                end
            end)
        end
    end

    local function setActiveTab(tabData)
        if not tabData then
            return
        end
        if activeTab == tabData then
            refreshTabs()
            return
        end

        local previous = activeTab
        activeTab = tabData
        refreshTabs()

        transitionToPage(tabData.Page, previous and previous.Page or nil)
    end

    local function showWindow()
        if animating or opened then
            return
        end

        animating = true
        opened = true
        main.Visible = true
        openGui.Visible = true
        updateResponsiveScale()
        local targetScale = mainScale.Scale / 0.92
        mainScale.Scale = math.max(0.72, targetScale * 0.86)
        openScale.Scale = 0.82

        local mainTween = tween(mainScale, SPRING_TWEEN, {Scale = targetScale})
        tween(openScale, SOFT_TWEEN, {Scale = 1})

        if mainTween then
            mainTween.Completed:Once(function()
                animating = false
                if opened then
                    openGui.Visible = false
                end
            end)
        else
            animating = false
            openGui.Visible = false
        end
    end

    local function hideWindow()
        if animating or not opened then
            return
        end

        animating = true
        openGui.Visible = true
        main.Visible = true
        updateResponsiveScale()

        local targetScale = mainScale.Scale
        tween(openScale, SOFT_TWEEN, {Scale = 1})
        local mainTween = tween(mainScale, SMOOTH_TWEEN, {Scale = targetScale * 0.84})

        if mainTween then
            mainTween.Completed:Once(function()
                if mainTween.PlaybackState == Enum.PlaybackState.Completed then
                    main.Visible = false
                    opened = false
                    updateResponsiveScale()
                    mainScale.Scale = math.max(0.54, mainScale.Scale)
                end
                animating = false
            end)
        else
            main.Visible = false
            opened = false
            animating = false
        end
    end

    closeButton.MouseButton1Click:Connect(hideWindow)
    openGui.MouseButton1Click:Connect(showWindow)

    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale)
    end
    task.defer(updateResponsiveScale)

    function window:AddTab(tabOptions)
        tabOptions = tabOptions or {}

        local tabName = tostring(tabOptions.TabName or "Test tab")

        local tabButton = create("TextButton", {
            Name = "TabButton",
            Parent = tabFrame,
            TextWrapped = true,
            BorderSizePixel = 0,
            BackgroundColor3 = COLORS.Surface,
            Size = UDim2.new(0, 90, 0, 36),
            Text = tabName,
            AutoButtonColor = false,
            ZIndex = 4,
        })
        styleText(tabButton, 14)
        addCorner(tabButton)
        addStroke(tabButton, 0.9)
        animateButton(tabButton, {
            HoverScale = 1.025,
            ActiveScale = 0.98,
        })

        local indicator = create("Frame", {
            Name = "Indicator",
            Parent = tabButton,
            BackgroundColor3 = COLORS.Dark,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 3, 0, 0),
            Position = UDim2.new(0, 4, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            ZIndex = 5,
        })
        addCorner(indicator, UDim.new(1, 0))

        local pageFrame = create("ScrollingFrame", {
            Name = "PageFrame",
            Parent = pagesHolder,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(192, 192, 192),
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Color3.fromRGB(160, 160, 160),
            ScrollingEnabled = true,
            Active = true,
            ClipsDescendants = true,
            BackgroundTransparency = 0.4,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            Visible = false,
            ZIndex = 3,
        })
        addCorner(pageFrame)

        create("UIPadding", {
            Parent = pageFrame,
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        })

        local content = create("Frame", {
            Name = "Content",
            Parent = pageFrame,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -16, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 4,
        })

        local pageLayout = create("UIListLayout", {
            Parent = content,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        })

        local function updateCanvas()
            if not pageFrame.Parent then
                return
            end
            local height = math.max(content.AbsoluteSize.Y, pageLayout.AbsoluteContentSize.Y) + 18
            local viewportHeight = pageFrame.AbsoluteWindowSize.Y
            pageFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(height, viewportHeight))
        end

        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
        content:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
        pageFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateCanvas)
        task.defer(updateCanvas)

        local tabData = {
            Button = tabButton,
            Page = pageFrame,
            Content = content,
            Indicator = indicator,
        }

        function tabData:AddButton(buttonOptions)
            buttonOptions = buttonOptions or {}

            local buttonName = tostring(buttonOptions.Name or "Test button")
            local callback = buttonOptions.Callback

            local button = create("TextButton", {
                Name = "Button",
                Parent = content,
                TextWrapped = true,
                BorderSizePixel = 0,
                BackgroundColor3 = COLORS.Surface,
                Size = UDim2.new(1, 0, 0, 36),
                Text = buttonName,
                AutoButtonColor = false,
                ZIndex = 4,
                LayoutOrder = #content:GetChildren() + 1,
            })
            styleText(button, 14)
            addCorner(button)
            addStroke(button, 0.9)
            animateButton(button)

            button.MouseButton1Click:Connect(function()
                tween(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = COLORS.SurfaceActive,
                })
                task.delay(0.08, function()
                    if button.Parent then
                        tween(button, FAST_TWEEN, {BackgroundColor3 = COLORS.Surface})
                    end
                end)
                callSafely(callback)
            end)

            return button
        end

        function tabData:AddSlider(sliderOptions)
            sliderOptions = sliderOptions or {}

            local minimum = tonumber(sliderOptions.Min) or 0
            local maximum = tonumber(sliderOptions.Max) or 100
            if minimum > maximum then
                minimum, maximum = maximum, minimum
            end

            local increment = math.abs(tonumber(sliderOptions.Increment) or 1)
            local suffix = tostring(sliderOptions.Suffix or "")
            local value = clamp(tonumber(sliderOptions.Default) or minimum, minimum, maximum)
            value = clamp(roundToIncrement(value, minimum, increment), minimum, maximum)

            local holder = create("Frame", {
                Name = "Slider",
                Parent = content,
                BackgroundColor3 = COLORS.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 58),
                ZIndex = 4,
                LayoutOrder = #content:GetChildren() + 1,
            })
            addCorner(holder)
            addStroke(holder, 0.9)

            local label = create("TextLabel", {
                Name = "Label",
                Parent = holder,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -84, 0, 22),
                Position = UDim2.new(0, 12, 0, 4),
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = tostring(sliderOptions.Name or "Slider"),
                ZIndex = 5,
            })
            styleText(label, 14)

            local valueLabel = create("TextLabel", {
                Name = "Value",
                Parent = holder,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 68, 0, 22),
                Position = UDim2.new(1, -78, 0, 4),
                TextXAlignment = Enum.TextXAlignment.Right,
                Text = formatNumber(value) .. suffix,
                ZIndex = 5,
            })
            styleText(valueLabel, 13, COLORS.Muted)

            local track = create("Frame", {
                Name = "Track",
                Parent = holder,
                BackgroundColor3 = COLORS.Track,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -24, 0, 8),
                Position = UDim2.new(0, 12, 0, 39),
                ZIndex = 5,
            })
            addCorner(track, UDim.new(1, 0))

            local fill = create("Frame", {
                Name = "Fill",
                Parent = track,
                BackgroundColor3 = COLORS.SurfaceActive,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 0, 1, 0),
                ZIndex = 6,
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
                ZIndex = 7,
            })
            addCorner(knob, UDim.new(1, 0))
            addStroke(knob, 0.75)

            local dragButton = create("TextButton", {
                Name = "Input",
                Parent = holder,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -20, 0, 30),
                Position = UDim2.new(0, 10, 0, 31),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 8,
            })

            local currentTweenFill
            local currentTweenKnob

            local function render(newValue, fireCallback, animate)
                value = clamp(roundToIncrement(tonumber(newValue) or minimum, minimum, increment), minimum, maximum)
                local alpha = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
                alpha = math.clamp(alpha, 0, 1)

                valueLabel.Text = formatNumber(value) .. suffix

                cancelTween(currentTweenFill)
                cancelTween(currentTweenKnob)

                local info = animate and TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) or TweenInfo.new(0, Enum.EasingStyle.Linear)
                currentTweenFill = tween(fill, info, {Size = UDim2.new(alpha, 0, 1, 0)})
                currentTweenKnob = tween(knob, info, {Position = UDim2.new(alpha, 0, 0.5, 0)})

                if fireCallback then
                    callSafely(sliderOptions.Callback, value)
                end
            end

            local function updateFromPosition(x)
                local left = track.AbsolutePosition.X
                local width = track.AbsoluteSize.X
                if width <= 0 then
                    return
                end
                local alpha = math.clamp((x - left) / width, 0, 1)
                render(minimum + (maximum - minimum) * alpha, true, true)
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
                tween(track, FAST_TWEEN, {BackgroundColor3 = COLORS.Track})
                tween(knob, FAST_TWEEN, {Size = UDim2.new(0, 14, 0, 14)})
            end)

            render(value, false, false)

            local slider = holder
            function slider:Set(newValue)
                render(newValue, true, true)
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
                Parent = content,
                BackgroundColor3 = COLORS.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 58),
                ZIndex = 4,
                LayoutOrder = #content:GetChildren() + 1,
            })
            addCorner(holder)
            addStroke(holder, 0.9)

            local label = create("TextLabel", {
                Name = "Label",
                Parent = holder,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 12, 0, 4),
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = tostring(textboxOptions.Name or "Textbox"),
                ZIndex = 5,
            })
            styleText(label, 14)

            local box = create("TextBox", {
                Name = "Input",
                Parent = holder,
                BackgroundColor3 = COLORS.Input,
                BackgroundTransparency = 0.12,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -24, 0, 27),
                Position = UDim2.new(0, 12, 0, 27),
                ClearTextOnFocus = textboxOptions.ClearOnFocus == true,
                PlaceholderText = tostring(textboxOptions.PlaceholderText or ""),
                Text = tostring(textboxOptions.Default or ""),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
            })
            styleText(box, 13)
            addCorner(box)
            addStroke(box, 0.85)

            create("UIPadding", {
                Parent = box,
                PaddingLeft = UDim.new(0, 9),
                PaddingRight = UDim.new(0, 9),
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
                Parent = content,
                BackgroundColor3 = COLORS.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 48),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 4,
                LayoutOrder = #content:GetChildren() + 1,
            })
            addCorner(holder)
            addStroke(holder, 0.9)

            local label = create("TextLabel", {
                Name = "Label",
                Parent = holder,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -86, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = tostring(toggleOptions.Name or "Toggle"),
                ZIndex = 5,
            })
            styleText(label, 14)

            local switch = create("Frame", {
                Name = "Switch",
                Parent = holder,
                BackgroundColor3 = Color3.fromRGB(186, 186, 186),
                BorderSizePixel = 0,
                Size = UDim2.new(0, 48, 0, 24),
                Position = UDim2.new(1, -60, 0.5, -12),
                ZIndex = 5,
            })
            addCorner(switch, UDim.new(1, 0))

            local switchKnob = create("Frame", {
                Name = "Knob",
                Parent = switch,
                BackgroundColor3 = COLORS.Text,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 3, 0.5, -9),
                ZIndex = 6,
            })
            addCorner(switchKnob, UDim.new(1, 0))
            addStroke(switchKnob, 0.8)

            local knobScale = create("UIScale", {
                Scale = 1,
                Parent = switchKnob,
            })

            local indicator = create("Frame", {
                Name = "Indicator",
                Parent = switchKnob,
                BackgroundColor3 = COLORS.SurfaceActive,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 5, 0, 5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                ZIndex = 7,
            })
            addCorner(indicator, UDim.new(1, 0))

            local switchTween
            local knobTween
            local function render(state, fireCallback)
                enabled = state == true

                cancelTween(switchTween)
                cancelTween(knobTween)

                switchTween = tween(switch, FAST_TWEEN, {
                    BackgroundColor3 = enabled and COLORS.SurfaceActive or Color3.fromRGB(186, 186, 186),
                })

                knobTween = tween(switchKnob, SPRING_TWEEN, {
                    Position = enabled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
                })

                tween(knobScale, SOFT_TWEEN, {Scale = enabled and 1.06 or 1})
                tween(indicator, FAST_TWEEN, {
                    BackgroundColor3 = enabled and COLORS.Dark or COLORS.SurfaceActive,
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
            local expandedHeight = baseHeight + (#optionsList * itemHeight) + (#optionsList > 0 and 8 or 0)

            local holder = create("Frame", {
                Name = "Dropdown",
                Parent = content,
                BackgroundColor3 = COLORS.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, baseHeight),
                ClipsDescendants = true,
                ZIndex = 10,
                LayoutOrder = #content:GetChildren() + 1,
            })
            addCorner(holder)
            addStroke(holder, 0.9)

            local button = create("TextButton", {
                Name = "Button",
                Parent = holder,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, baseHeight),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 12,
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
                ZIndex = 13,
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
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = selected or "Select...",
                ZIndex = 13,
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
                ZIndex = 13,
            })
            styleText(chevron, 16)

            local list = create("Frame", {
                Name = "Options",
                Parent = holder,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -16, 0, #optionsList * itemHeight + (#optionsList > 0 and 3 or 0)),
                Position = UDim2.new(0, 8, 0, baseHeight + 4),
                ZIndex = 11,
            })

            local listLayout = create("UIListLayout", {
                Parent = list,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 3),
            })

            local expandedTween
            local function setExpanded(state)
                expanded = state == true
                cancelTween(expandedTween)
                expandedTween = tween(holder, SMOOTH_TWEEN, {
                    Size = UDim2.new(1, 0, 0, expanded and expandedHeight or baseHeight),
                })
                tween(chevron, FAST_TWEEN, {
                    Rotation = expanded and 180 or 0,
                })
                tween(button, FAST_TWEEN, {
                    BackgroundTransparency = expanded and 0.04 or 1,
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

            local function makeOption(index, option)
                local optionButton = create("TextButton", {
                    Name = "Option" .. index,
                    Parent = list,
                    BackgroundColor3 = COLORS.Input,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, itemHeight),
                    Text = option,
                    AutoButtonColor = false,
                    ZIndex = 13,
                    LayoutOrder = index,
                })
                styleText(optionButton, 13)
                addCorner(optionButton)
                animateButton(optionButton, {
                    HoverColor = COLORS.SurfaceHover,
                    ActiveColor = COLORS.SurfaceActive,
                    HoverScale = 1.01,
                })

                optionButton.MouseButton1Click:Connect(function()
                    select(option, true)
                end)
            end

            for index, option in ipairs(optionsList) do
                makeOption(index, option)
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
                    BackgroundColor3 = expanded and COLORS.SurfaceHover or COLORS.Surface,
                })
            end)

            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                expandedHeight = baseHeight + listLayout.AbsoluteContentSize.Y + 10
                list.Size = UDim2.new(1, -16, 0, listLayout.AbsoluteContentSize.Y)
                if expanded then
                    setExpanded(true)
                end
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
                    makeOption(index, option)
                end

                task.defer(function()
                    expandedHeight = baseHeight + listLayout.AbsoluteContentSize.Y + 10
                    list.Size = UDim2.new(1, -16, 0, listLayout.AbsoluteContentSize.Y)
                    setExpanded(expanded)
                end)
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

        task.defer(updateCanvas)
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
    window.Dropshadow = dropshadow
    window.Title = title
    window.IconImg = iconImg
    window.Close = closeButton
    window.OpenGui = openGui
    window.TabFrame = tabFrame
    window.PagesHolder = pagesHolder
    window.MainScale = mainScale
    window.MainAspect = mainAspect

    return window
end

return UI
