local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Library = {
    Connections = {}
}

local LocalPlayer = Players.LocalPlayer
local Config = {
    Name = "Vortex UI",
    Theme = {
        Background = Color3.fromRGB(25, 25, 25),
        Sidebar = Color3.fromRGB(30, 30, 30),
        Section = Color3.fromRGB(35, 35, 35),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(150, 150, 150),
        Accent = Color3.fromRGB(0, 120, 255),
        Outline = Color3.fromRGB(50, 50, 50)
    },
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold
}

local IsResizing = false

local function GetParent()
    if gethui then return gethui() end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function AddConnection(conn)
    table.insert(Library.Connections, conn)
    return conn
end

function Library:Destroy()
    for _, conn in ipairs(Library.Connections) do
        if typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        end
    end
    Library.Connections = {}
    
    if Library.ScreenGui and Library.ScreenGui.Parent then
        Library.ScreenGui:Destroy()
    end
end

local function Tween(obj, props, info)
    info = info or TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

local function Create(class, props)
    local instance = Instance.new(class)
    for k, v in pairs(props) do
        if type(k) == "string" then 
            instance[k] = v
        end
    end
    return instance
end

local function AddCorner(instance, radius)
    local corner = Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = instance
    })
    return corner
end

local function AddStroke(instance, thickness, color)
    local stroke = Create("UIStroke", {
        Thickness = thickness or 1,
        Color = color or Config.Theme.Outline,
        Parent = instance,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    return stroke
end

local function MakeDraggable(frame, trigger)
    trigger = trigger or frame
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        if IsResizing then return end
        
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
        Tween(frame, {Position = newPos}, TweenInfo.new(0.1))
    end

    AddConnection(trigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if IsResizing then return end
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))

    AddConnection(trigger.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end))
end

local function MakeResizable(frame, handle)
    local resizing, resizeStart, startSize

    AddConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsResizing = true
            resizing = true
            resizeStart = input.Position
            startSize = frame.Size
            
            UserInputService:SetMouseIcon("rbxassetid://257697472")
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    IsResizing = false
                    resizing = false
                    UserInputService:SetMouseIcon("")
                end
            end)
        end
    end))

    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newSize = UDim2.new(
                startSize.X.Scale, 
                math.max(startSize.X.Offset + delta.X, 350), 
                startSize.Y.Scale, 
                math.max(startSize.Y.Offset + delta.Y, 250)
            )
            Tween(frame, {Size = newSize}, TweenInfo.new(0.1))
        end
    end))
    
    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if resizing then
                IsResizing = false
                resizing = false
                UserInputService:SetMouseIcon("")
            end
        end
    end))
end

function Library:ShowLoadingScreen(parentGui, targetFrame, duration, callback)
    local DelayDuration = 3
    local TweenDuration = 0.5

    local TargetSize = targetFrame.Size
    local TargetPosition = targetFrame.Position
    local TargetName = targetFrame.Parent.Name or Config.Name

    local InitialSizeX = TargetSize.X.Offset * 0.6
    local InitialSizeY = TargetSize.Y.Offset * 0.6

    local LoaderFrame = Create("Frame", {
        Parent = parentGui,
        BackgroundColor3 = Config.Theme.Background,
        Position = UDim2.new(0.5, -InitialSizeX / 2, 0.5, -InitialSizeY / 2),
        Size = UDim2.new(0, InitialSizeX, 0, InitialSizeY),
        ClipsDescendants = true,
        ZIndex = 20
    })
    AddCorner(LoaderFrame, 8)
    AddStroke(LoaderFrame, 2, Config.Theme.Accent)
    
    local TitleLabel = Create("TextLabel", {Parent = LoaderFrame, BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.35, 0), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, -20, 0, 30), Font = Config.FontBold, Text = TargetName, TextColor3 = Config.Theme.Accent, TextSize = 24, TextScaled = true })
    local IndicatorLabel = Create("TextLabel", {Parent = LoaderFrame, BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.55, 0), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, -20, 0, 20), Font = Config.Font, Text = "Loading Assets...", TextColor3 = Config.Theme.SubText, TextSize = 14, TextScaled = true})
    local ProgressBarContainer = Create("Frame", {Parent = LoaderFrame, BackgroundColor3 = Config.Theme.Sidebar, Position = UDim2.new(0.5, 0, 0.75, 0), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0.8, 0, 0, 8)})
    AddCorner(ProgressBarContainer, 4)
    local ProgressBarFill = Create("Frame", {Parent = ProgressBarContainer, BackgroundColor3 = Config.Theme.Accent, Size = UDim2.new(0, 0, 1, 0)})
    AddCorner(ProgressBarFill, 4)

    local Flashing = true
    task.spawn(function()
        while Flashing do
            Tween(IndicatorLabel, {TextTransparency = 0.8}, TweenInfo.new(0.6, Enum.EasingStyle.Quad))
            task.wait(0.6)
            Tween(IndicatorLabel, {TextTransparency = 0}, TweenInfo.new(0.6, Enum.EasingStyle.Quad))
            task.wait(0.6)
        end
    end)
    
    task.spawn(function()
        Tween(ProgressBarFill, {Size = UDim2.new(1, 0, 1, 0)}, TweenInfo.new(DelayDuration, Enum.EasingStyle.Linear))
    end)

    task.wait(DelayDuration)
    
    Flashing = false
    
    local tInfo = TweenInfo.new(TweenDuration, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
    
    local ExpansionTween = TweenService:Create(LoaderFrame, tInfo, {
        Size = TargetSize,
        Position = TargetPosition,
        BackgroundTransparency = 0
    })
    
    Tween(TitleLabel, {TextTransparency = 1}, TweenInfo.new(TweenDuration * 0.8))
    Tween(IndicatorLabel, {TextTransparency = 1}, TweenInfo.new(TweenDuration * 0.8))

    ExpansionTween:Play()
    ExpansionTween.Completed:Wait()
    
    LoaderFrame:Destroy()
    
    if callback then
        callback()
    end
end

function Library:CreateWindow(options)
    options = options or {}
    local TitleText = options.Name or Config.Name
    local IntroEnabled = options.LoadingScreen or false

    local ScreenGui = Create("ScreenGui", {
        Name = Config.Name,
        Parent = GetParent(),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })
    
    Library.ScreenGui = ScreenGui
    
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        BackgroundColor3 = Config.Theme.Background,
        Position = UDim2.new(0.5, -275, 0.5, -175),
        Size = UDim2.new(0, 550, 0, 350),
        ClipsDescendants = true,
        Visible = not IntroEnabled
    })
    AddCorner(MainFrame, 8)
    AddStroke(MainFrame, 1, Config.Theme.Outline)

    local TopBar = Create("Frame", {
        Name = "TopBar",
        Parent = MainFrame,
        BackgroundColor3 = Config.Theme.Sidebar,
        Size = UDim2.new(1, 0, 0, 30),
        ZIndex = 3
    })
    
    local TitleLabel = Create("TextLabel", {
        Parent = TopBar, BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), 
        Size = UDim2.new(1, -20, 1, 0), Font = Config.FontBold, Text = TitleText, TextColor3 = Config.Theme.Text, TextSize = 18
    })

    if IntroEnabled then
        Library:ShowLoadingScreen(ScreenGui, MainFrame, 3, function() 
            MainFrame.Visible = true
            MakeDraggable(MainFrame, TopBar) 
        end)
    else
        MainFrame.Visible = true
        MakeDraggable(MainFrame, TopBar)
    end

    local ResizeHandle = Create("Frame", {
        Name = "ResizeHandle",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 20, 0, 20),
        ZIndex = 10,
    })
    
    local ArrowIcon = Create("TextLabel", {
        Parent = ResizeHandle, BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 0, 1, 0), Font = Config.Font, Text = "→", TextColor3 = Config.Theme.Accent, TextSize = 20,
        Rotation = 45, TextScaled = true
    })
    
    MakeResizable(MainFrame, ResizeHandle)

    local Sidebar = Create("Frame", {
        Parent = MainFrame, BackgroundColor3 = Config.Theme.Sidebar, Position = UDim2.new(0, 0, 0, 30), 
        Size = UDim2.new(0, 140, 1, -30), ZIndex = 2
    })
    AddCorner(Sidebar, 8)
    
    local SidebarFix = Create("Frame", {Parent = Sidebar, BackgroundColor3 = Config.Theme.Sidebar, BorderSizePixel = 0, Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0, 10, 1, 0)})

    local TabContainer = Create("ScrollingFrame", {
        Parent = Sidebar, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 10), Size = UDim2.new(1, 0, 1, -20), 
        ScrollBarThickness = 2, ScrollBarImageColor3 = Config.Theme.Accent, CanvasSize = UDim2.new(0,0,0,0)
    })
    local TabListLayout = Create("UIListLayout", {
        Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)
    })
    AddConnection(TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0,0,0,TabListLayout.AbsoluteContentSize.Y)
    end))

    local ContentContainer = Create("Frame", {
        Parent = MainFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 150, 0, 40), 
        Size = UDim2.new(1, -160, 1, -50), ClipsDescendants = true
    })

    local NotificationHolder = Create("Frame", {
        Parent = ScreenGui, BackgroundTransparency = 1, Position = UDim2.new(1, -260, 1, -20),
        Size = UDim2.new(0, 250, 0, 300), AnchorPoint = Vector2.new(0, 1), ZIndex = 100
    })
    local NotificationLayout = Create("UIListLayout", {
        Parent = NotificationHolder, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 5)
    })

    function Library:Notify(notifOpts)
        local Title = notifOpts.Title or "Notification"
        local Desc = notifOpts.Content or "Description"
        local Duration = notifOpts.Duration or 3

        local NotifFrame = Create("Frame", {
            Parent = NotificationHolder, BackgroundColor3 = Config.Theme.Sidebar, Size = UDim2.new(1, 0, 0, 0), 
            ClipsDescendants = true, BackgroundTransparency = 0.1
        })
        AddCorner(NotifFrame, 6)
        AddStroke(NotifFrame, 1, Config.Theme.Accent)

        local NotifTitle = Create("TextLabel", {Parent = NotifFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -10, 0, 20), Font = Config.FontBold, Text = Title, TextColor3 = Config.Theme.Accent, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
        local NotifDesc = Create("TextLabel", {Parent = NotifFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 25), Size = UDim2.new(1, -10, 0, 20), Font = Config.Font, Text = Desc, TextColor3 = Config.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true})

        Tween(NotifFrame, {Size = UDim2.new(1, 0, 0, 60)}, TweenInfo.new(0.3))
        
        task.delay(Duration, function()
            local t = Tween(NotifFrame, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, TweenInfo.new(0.3))
            t.Completed:Connect(function()
                NotifFrame:Destroy()
            end)
        end)
    end

    local ToggleBtn = Create("ImageButton", { 
        Parent = ScreenGui, BackgroundColor3 = Config.Theme.Sidebar, Image = "rbxassetid://111387516855046", 
        ImageTransparency = 0, Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0, 50, 0, 50), AutoButtonColor = false, ZIndex = 100
    })
    AddCorner(ToggleBtn, 25)
    AddStroke(ToggleBtn, 2, Config.Theme.Accent)
    
    MakeDraggable(ToggleBtn)

    local Open = true
    local function ToggleUI()
        Open = not Open
        if Open then
            MainFrame.Visible = true
            Tween(MainFrame, {Size = UDim2.new(0, 550, 0, 350)}, TweenInfo.new(0.3))
        else
            Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, TweenInfo.new(0.3)).Completed:Connect(function()
                if not Open then MainFrame.Visible = false end
            end)
        end
    end
    AddConnection(ToggleBtn.MouseButton1Click:Connect(ToggleUI))

    local Window = {}
    Window.Destroy = Library.Destroy
    local FirstTab = true

    function Window:CreateTab(name)
        local TabButton = Create("TextButton", {
            Parent = TabContainer, BackgroundColor3 = Config.Theme.Background, BackgroundTransparency = 1, 
            Size = UDim2.new(1, -10, 0, 35), Text = "", Position = UDim2.new(0, 5, 0, 0)
        })
        AddCorner(TabButton, 6)
        
        local TabLabel = Create("TextLabel", {
            Parent = TabButton, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 1, 0), 
            Font = Config.Font, Text = name, TextColor3 = Config.Theme.SubText, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
        })

        local TabPage = Create("ScrollingFrame", {
            Parent = ContentContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, 
            ScrollBarThickness = 2, ScrollBarImageColor3 = Config.Theme.Accent, CanvasSize = UDim2.new(0, 0, 0, 0)
        })
        local PageLayout = Create("UIListLayout", {
            Parent = TabPage, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)
        })
        
        AddConnection(PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end))

        local function Activate()
            for _, v in pairs(ContentContainer:GetChildren()) do
                if v:IsA("ScrollingFrame") then v.Visible = false end
            end
            for _, v in pairs(TabContainer:GetChildren()) do
                if v:IsA("TextButton") then
                    Tween(v, {BackgroundTransparency = 1}, TweenInfo.new(0.2))
                    local txt = v:FindFirstChild("TextLabel")
                    if txt then Tween(txt, {TextColor3 = Config.Theme.SubText}, TweenInfo.new(0.2)) end
                end
            end

            TabPage.Visible = true
            Tween(TabButton, {BackgroundTransparency = 0}, TweenInfo.new(0.2))
            Tween(TabLabel, {TextColor3 = Config.Theme.Text}, TweenInfo.new(0.2))
        end

        AddConnection(TabButton.MouseButton1Click:Connect(Activate))

        if FirstTab then
            FirstTab = false
            Activate()
        end

        local Tab = {}

        function Tab:CreateSection(secName)
            local SectionFrame = Create("Frame", {
                Parent = TabPage, BackgroundColor3 = Config.Theme.Section, Size = UDim2.new(1, -5, 0, 30), ClipsDescendants = true
            })
            AddCorner(SectionFrame, 6)

            local SecLabel = Create("TextLabel", {Parent = SectionFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -20, 0, 20), Font = Config.FontBold, Text = secName, TextColor3 = Config.Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})

            local ItemsContainer = Create("Frame", {
                Parent = SectionFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 30), Size = UDim2.new(1, -20, 0, 0)
            })
            local ItemsLayout = Create("UIListLayout", {
                Parent = ItemsContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)
            })

            AddConnection(ItemsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                ItemsContainer.Size = UDim2.new(1, -20, 0, ItemsLayout.AbsoluteContentSize.Y)
                SectionFrame.Size = UDim2.new(1, -5, 0, ItemsLayout.AbsoluteContentSize.Y + 40)
            end))

            local Section = {}

            function Section:CreateButton(bArgs)
                local bName = bArgs.Name or "Button"
                local callback = bArgs.Callback or function() end

                local Button = Create("TextButton", {
                    Parent = ItemsContainer, BackgroundColor3 = Config.Theme.Background, Size = UDim2.new(1, 0, 0, 30),
                    Font = Config.Font, Text = bName, TextColor3 = Config.Theme.Text, TextSize = 12, AutoButtonColor = false
                })
                AddCorner(Button, 4)
                
                AddConnection(Button.MouseButton1Click:Connect(function()
                    callback()
                    Tween(Button, {BackgroundColor3 = Config.Theme.Accent}, TweenInfo.new(0.1))
                    task.wait(0.1)
                    Tween(Button, {BackgroundColor3 = Config.Theme.Background}, TweenInfo.new(0.2))
                end))
            end

            function Section:CreateToggle(tArgs)
                local tName = tArgs.Name or "Toggle"
                local def = tArgs.Default or false
                local callback = tArgs.Callback or function() end
                local toggled = def

                local ToggleFrame = Create("Frame", {Parent = ItemsContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30)})
                local ToggleLabel = Create("TextLabel", {Parent = ToggleFrame, BackgroundTransparency = 1, Size = UDim2.new(0.7, 0, 1, 0), Font = Config.Font, Text = tName, TextColor3 = Config.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
                local ToggleBtn = Create("TextButton", {Parent = ToggleFrame, BackgroundColor3 = toggled and Config.Theme.Accent or Config.Theme.Background, Position = UDim2.new(1, -45, 0.5, -10), Size = UDim2.new(0, 45, 0, 20), Text = ""})
                AddCorner(ToggleBtn, 10)
                local Circle = Create("Frame", {Parent = ToggleBtn, BackgroundColor3 = Config.Theme.Text, Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), Size = UDim2.new(0, 16, 0, 16)})
                AddCorner(Circle, 8)

                local function Update()
                    toggled = not toggled
                    Tween(ToggleBtn, {BackgroundColor3 = toggled and Config.Theme.Accent or Config.Theme.Background}, TweenInfo.new(0.2))
                    Tween(Circle, {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, TweenInfo.new(0.2))
                    callback(toggled)
                end

                AddConnection(ToggleBtn.MouseButton1Click:Connect(Update))
            end

            function Section:CreateLabel(text)
                local Label = Create("TextLabel", {
                    Parent = ItemsContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Font = Config.Font, 
                    Text = text, TextColor3 = Config.Theme.SubText, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
                })
            end

            function Section:CreateInput(iArgs)
                local iName = iArgs.Name or "Input"
                local placeholder = iArgs.Placeholder or "Type here..."
                local callback = iArgs.Callback or function() end

                local InputFrame = Create("Frame", {Parent = ItemsContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 45)})
                local InputLabel = Create("TextLabel", {Parent = InputFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), Font = Config.Font, Text = iName, TextColor3 = Config.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
                local TextBox = Create("TextBox", {
                    Parent = InputFrame, BackgroundColor3 = Config.Theme.Background, Position = UDim2.new(0, 0, 0, 20),
                    Size = UDim2.new(1, 0, 0, 25), Font = Config.Font, Text = "", PlaceholderText = placeholder, TextColor3 = Config.Theme.Text, TextSize = 12
                })
                AddCorner(TextBox, 4)

                AddConnection(TextBox.FocusLost:Connect(function()
                    callback(TextBox.Text)
                end))
            end

            function Section:CreateSlider(sArgs)
                local sName = sArgs.Name or "Slider"
                local min = sArgs.Min or 0
                local max = sArgs.Max or 100
                local def = sArgs.Default or min
                local callback = sArgs.Callback or function() end
                
                def = math.clamp(def, min, max)

                local SliderFrame = Create("Frame", {Parent = ItemsContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 45)})
                local SliderLabel = Create("TextLabel", {Parent = SliderFrame, BackgroundTransparency = 1, Size = UDim2.new(0.7, 0, 0, 15), Font = Config.Font, Text = sName, TextColor3 = Config.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
                local ValueLabel = Create("TextLabel", {Parent = SliderFrame, BackgroundTransparency = 1, Size = UDim2.new(0.3, 0, 0, 15), Position = UDim2.new(0.7, 0, 0, 0), Font = Config.FontBold, Text = tostring(math.floor(def)), TextColor3 = Config.Theme.Accent, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right})
                local Bar = Create("Frame", {Parent = SliderFrame, BackgroundColor3 = Config.Theme.Background, Position = UDim2.new(0, 0, 0, 25), Size = UDim2.new(1, 0, 0, 8)})
                AddCorner(Bar, 4)
                local initialScale = (def - min) / (max - min)
                local Fill = Create("Frame", {Parent = Bar, BackgroundColor3 = Config.Theme.Accent, Size = UDim2.new(initialScale, 0, 1, 0)})
                AddCorner(Fill, 4)
                local Trigger = Create("TextButton", {Parent = Bar, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = ""})

                local function UpdateSlide(input)
                    local SizeX = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    local Value = math.floor(min + ((max - min) * SizeX))
                    
                    Tween(Fill, {Size = UDim2.new(SizeX, 0, 1, 0)}, TweenInfo.new(0.1))
                    ValueLabel.Text = tostring(Value)
                    callback(Value)
                end

                local Sliding = false
                AddConnection(Trigger.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        Sliding = true
                        UpdateSlide(input)
                    end
                end))
                
                AddConnection(UserInputService.InputChanged:Connect(function(input)
                    if Sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateSlide(input)
                    end
                end))
                
                AddConnection(UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        Sliding = false
                    end
                end))
            end

            function Section:CreateDropdown(dArgs)
                local dName = dArgs.Name or "Dropdown"
                local options = dArgs.Options or {"Option 1", "Option 2"}
                local def = dArgs.Default or options[1]
                local callback = dArgs.Callback or function() end
                
                local DropdownFrame = Create("Frame", {Parent = ItemsContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 45)})
                
                local DropdownLabel = Create("TextLabel", {Parent = DropdownFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15), Font = Config.Font, Text = dName, TextColor3 = Config.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
                
                local SelectedText = Create("TextButton", {
                    Parent = DropdownFrame, BackgroundColor3 = Config.Theme.Background, Position = UDim2.new(0, 0, 0, 20),
                    Size = UDim2.new(1, 0, 0, 25), Font = Config.Font, Text = def, TextColor3 = Config.Theme.Text, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, TextWrapped = true
                })
                AddCorner(SelectedText, 4)
                
                local ArrowLabel = Create("TextLabel", {
                    Parent = SelectedText, BackgroundTransparency = 1, Position = UDim2.new(1, -15, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
                    Size = UDim2.new(0, 15, 1, 0), Font = Config.FontBold, Text = "▼", TextColor3 = Config.Theme.SubText, TextSize = 10, ZIndex = 2
                })

                local OptionsContainer = Create("ScrollingFrame", {
                    Parent = DropdownFrame, BackgroundColor3 = Config.Theme.Background,
                    Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(1, 0, 0, 0), 
                    ClipsDescendants = true, ZIndex = 5, Visible = false,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Config.Theme.Accent,
                    CanvasSize = UDim2.new(0, 0, 0, 0)
                })
                AddCorner(OptionsContainer, 4)
                AddStroke(OptionsContainer, 1, Config.Theme.Accent)

                local OptionsList = Create("UIListLayout", {
                    Parent = OptionsContainer, SortOrder = Enum.SortOrder.LayoutOrder
                })

                local DropdownOpen = false
                
                local function CloseDropdown()
                    if DropdownOpen and OptionsContainer.Parent then
                        Tween(OptionsContainer, {Size = UDim2.new(1, 0, 0, 0)}, TweenInfo.new(0.2)).Completed:Connect(function()
                            OptionsContainer.Visible = false
                        end)
                        Tween(ArrowLabel, {Rotation = 0}, TweenInfo.new(0.2))
                        DropdownOpen = false
                    end
                end

                local function ToggleDropdown()
                    DropdownOpen = not DropdownOpen
                    OptionsContainer.Visible = true
                    
                    if DropdownOpen then
                        local itemHeight = 25
                        local totalContentHeight = #options * itemHeight
                        local maxHeight = 200 
                        
                        OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, totalContentHeight)
                        
                        local visibleHeight = math.min(totalContentHeight, maxHeight)
                        Tween(OptionsContainer, {Size = UDim2.new(1, 0, 0, visibleHeight)}, TweenInfo.new(0.2))
                        Tween(ArrowLabel, {Rotation = 180}, TweenInfo.new(0.2))
                    else
                        CloseDropdown()
                    end
                end
                
                AddConnection(SelectedText.MouseButton1Click:Connect(ToggleDropdown))

                for i, option in ipairs(options) do
                    local OptionButton = Create("TextButton", {
                        Parent = OptionsContainer, BackgroundColor3 = Config.Theme.Background, BackgroundTransparency = 0,
                        Size = UDim2.new(1, 0, 0, 25), Text = option, Font = Config.Font, TextColor3 = Config.Theme.Text,
                        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextPadding = Insets.new(5, 0, 0, 0), AutoButtonColor = false
                    })
                    
                    if option == SelectedText.Text then
                         OptionButton.BackgroundColor3 = Config.Theme.Accent
                    end

                    AddConnection(OptionButton.MouseEnter:Connect(function()
                        if OptionButton.Text ~= SelectedText.Text then
                            Tween(OptionButton, {BackgroundColor3 = Config.Theme.Sidebar}, TweenInfo.new(0.1))
                        end
                    end))
                    
                    AddConnection(OptionButton.MouseLeave:Connect(function()
                        if OptionButton.Text ~= SelectedText.Text then
                            Tween(OptionButton, {BackgroundColor3 = Config.Theme.Background}, TweenInfo.new(0.1))
                        end
                    end))

                    AddConnection(OptionButton.MouseButton1Click:Connect(function()
                        for _, v in OptionsContainer:GetChildren() do
                            if v:IsA("TextButton") then
                                Tween(v, {BackgroundColor3 = Config.Theme.Background}, TweenInfo.new(0.1))
                            end
                        end
                        
                        SelectedText.Text = option
                        Tween(OptionButton, {BackgroundColor3 = Config.Theme.Accent}, TweenInfo.new(0.1))
                        callback(option)
                        CloseDropdown()
                    end))
                end
            end

            return Section
        end
        return Tab
    end
    
    return Window
end

return Library
