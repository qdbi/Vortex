local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

local Config = {
    MainColor = Color3.fromRGB(40, 40, 40),
    AccentColor = Color3.fromRGB(60, 60, 60),
    HighlightColor = Color3.fromRGB(80, 80, 80),
    TextColor = Color3.fromRGB(255, 255, 255),
    Padding = 10,
    Font = Enum.Font.SourceSansBold,
    WindowSize = UDim2.new(0, 400, 0, 500)
}

local ScreenGui
local MainFrame
local TabContainer
local CurrentWindow

local function CreateUIInstance(instanceType, properties)
    local instance = Instance.new(instanceType)
    for prop, value in pairs(properties) do
        instance[prop] = value
    end
    return instance
end

function Library:CreateWindow(config)
    CurrentWindow = setmetatable({
        Name = config.Name or "Vortex UI",
        Tabs = {}
    }, Library)

    ScreenGui = CreateUIInstance("ScreenGui", {
        Name = "VortexLibraryGui",
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    MainFrame = CreateUIInstance("Frame", {
        Size = Config.WindowSize,
        Position = UDim2.new(0.5, -Config.WindowSize.X.Offset / 2, 0.5, -Config.WindowSize.Y.Offset / 2),
        BackgroundColor3 = Config.MainColor,
        BorderSizePixel = 0,
        BorderColor3 = Color3.fromRGB(20, 20, 20),
        ClipsDescendants = true,
        Parent = ScreenGui
    })

    CreateUIInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = MainFrame })
    CreateUIInstance("UIStroke", { Thickness = 1, Color = Color3.fromRGB(20, 20, 20), ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = MainFrame })
    
    local TitleBar = CreateUIInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Config.AccentColor,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    
    CreateUIInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = TitleBar })
    
    CreateUIInstance("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = CurrentWindow.Name,
        Font = Config.Font,
        TextColor3 = Config.TextColor,
        TextSize = 18,
        BackgroundTransparency = 1,
        Parent = TitleBar
    })

    local dragging
    local dragStart
    local frameStart
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            frameStart = MainFrame.Position
            input.Changed:Wait()
        end
    end)
    
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging and MainFrame.Parent then
            local mousePos = LocalPlayer:GetMouse().Position
            local delta = mousePos - dragStart
            MainFrame.Position = UDim2.new(0, frameStart.X.Offset + delta.X, 0, frameStart.Y.Offset + delta.Y)
        end
    end)
    
    TabContainer = CreateUIInstance("Frame", {
        Size = UDim2.new(0, 100, 1, -30),
        Position = UDim2.new(0, 100, 0, 30),
        BackgroundColor3 = Config.AccentColor,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    
    local TabListLayout = CreateUIInstance("UIListLayout", {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = TabContainer
    })
    
    local ContentFrame = CreateUIInstance("Frame", {
        Size = UDim2.new(1, -100, 1, -30),
        Position = UDim2.new(0, 100, 0, 30),
        BackgroundColor3 = Config.MainColor,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    
    local ContentListLayout = CreateUIInstance("UIListLayout", {
        Padding = UDim.new(0, Config.Padding),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = ContentFrame
    })
    ContentListLayout:Clone().Parent = ContentFrame

    CurrentWindow.ContentFrame = ContentFrame
    CurrentWindow.ActiveTab = nil

    if config.LoadingScreen then
        local LoadingScreen = CreateUIInstance("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Config.MainColor,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 10,
            Parent = MainFrame
        })
        
        CreateUIInstance("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            Text = "Loading " .. CurrentWindow.Name .. "...",
            Font = Config.Font,
            TextColor3 = Config.TextColor,
            TextSize = 24,
            BackgroundTransparency = 1,
            Parent = LoadingScreen
        })
        
        task.wait(1)
        LoadingScreen:TweenSizeAndPosition(
            UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 1, 0), 
            Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 
            0.5, true, function()
                LoadingScreen:Destroy()
            end
        )
    end

    return CurrentWindow
end

function CurrentWindow:Destroy()
    if ScreenGui then
        ScreenGui:Destroy()
    end
    ScreenGui = nil -- Safely clear the global variable reference
end

function CurrentWindow:CreateTab(name)
    local tab = {
        Name = name,
        Sections = {}
    }

    local TabButton = CreateUIInstance("TextButton", {
        Size = UDim2.new(1, -10, 0, 25),
        Text = name,
        Font = Config.Font,
        TextColor3 = Config.TextColor,
        TextSize = 16,
        BackgroundColor3 = Config.AccentColor,
        BorderSizePixel = 0,
        Parent = TabContainer
    })
    
    CreateUIInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = TabButton })

    local TabContentFrame = CreateUIInstance("ScrollingFrame", {
        Size = UDim2.new(1, -Config.Padding * 2, 1, -Config.Padding * 2),
        Position = UDim2.new(0, Config.Padding, 0, Config.Padding),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        Parent = self.ContentFrame
    })
    
    local TabContentLayout = CreateUIInstance("UIListLayout", {
        Padding = UDim.new(0, Config.Padding),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Parent = TabContentFrame
    })
    
    TabContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    tab.Frame = TabContentFrame
    
    TabButton.MouseButton1Click:Connect(function()
        if self.ActiveTab then
            self.ActiveTab.Frame.Visible = false
            self.ActiveTab.Button.BackgroundColor3 = Config.AccentColor
        end
        TabContentFrame.Visible = true
        TabButton.BackgroundColor3 = Config.HighlightColor
        self.ActiveTab = tab
    end)
    
    tab.Button = TabButton
    table.insert(self.Tabs, tab)
    
    if not self.ActiveTab then
        TabButton:FireServer("Click")
        TabButton.BackgroundColor3 = Config.HighlightColor
        TabContentFrame.Visible = true
        self.ActiveTab = tab
    end

    function tab:CreateSection(sectionName)
        local sectionFrame = CreateUIInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = TabContentFrame
        })
        
        CreateUIInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Text = "— " .. sectionName .. " —",
            Font = Config.Font,
            TextColor3 = Config.TextColor,
            TextSize = 14,
            BackgroundTransparency = 1,
            Parent = sectionFrame
        })
        
        local SectionListLayout = CreateUIInstance("UIListLayout", {
            Padding = UDim.new(0, 5),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            Parent = sectionFrame
        })
        SectionListLayout.Name = "SectionLayout"

        local section = {
            Name = sectionName,
            Frame = sectionFrame,
            Layout = SectionListLayout
        }
        table.insert(self.Sections, section)
        
        RunService.RenderStepped:Wait()
        local contentHeight = TabContentLayout.AbsoluteContentSize.Y
        TabContentFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 20) 

        return setmetatable(section, Section)
    end
    
    return tab
end

local Section = {}

function Section:CreateElementFrame(height)
    local elementFrame = CreateUIInstance("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = self.Frame
    })
    return elementFrame
end

function Section:CreateLabel(text)
    local element = self:CreateElementFrame(20)
    
    CreateUIInstance("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        Text = text,
        Font = Enum.Font.SourceSans,
        TextColor3 = Config.TextColor,
        TextSize = 14,
        BackgroundTransparency = 1,
        Parent = element
    })
end

function Section:CreateToggle(config)
    local element = self:CreateElementFrame(25)
    local default = config.Default or false
    
    local label = CreateUIInstance("TextLabel", {
        Size = UDim2.new(0.8, -10, 1, 0),
        Text = config.Name,
        Position = UDim2.new(0, 0, 0, 0),
        Font = Config.Font,
        TextColor3 = Config.TextColor,
        TextSize = 16,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = element
    })
    
    local toggleButton = CreateUIInstance("TextButton", {
        Size = UDim2.new(0.2, 0, 1, 0),
        Position = UDim2.new(0.8, 0, 0, 0),
        Text = default and "ON" or "OFF",
        Font = Config.Font,
        TextColor3 = Color3.fromRGB(0, 0, 0),
        TextSize = 14,
        BackgroundColor3 = default and Color3.fromRGB(0, 200, 0) or Config.HighlightColor,
        BorderSizePixel = 0,
        Parent = element
    })
    
    local state = default
    
    toggleButton.MouseButton1Click:Connect(function()
        state = not state
        if state then
            toggleButton.Text = "ON"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        else
            toggleButton.Text = "OFF"
            toggleButton.BackgroundColor3 = Config.HighlightColor
        end
        if config.Callback then
            config.Callback(state)
        end
    end)
    
    if config.Callback then
        config.Callback(default)
    end
end

function Section:CreateSlider(config)
    local element = self:CreateElementFrame(50)
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or min
    local step = config.Step or 1
    
    local currentValue = default
    
    local displayLabel = CreateUIInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0.4, 0),
        Text = config.Name .. ": " .. tostring(math.floor(currentValue * 10) / 10),
        Font = Config.Font,
        TextColor3 = Config.TextColor,
        TextSize = 16,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = element
    })
    
    local sliderFrame = CreateUIInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Config.AccentColor,
        BorderSizePixel = 0,
        Parent = element
    })
    
    CreateUIInstance("UICorner", { CornerRadius = UDim.new(0, 5), Parent = sliderFrame })
    
    local sliderHandle = CreateUIInstance("TextButton", {
        Size = UDim2.new(0, 10, 2, 0),
        Position = UDim2.new((currentValue - min) / (max - min), 0, -0.5, 0),
        Text = "",
        BackgroundColor3 = Config.TextColor,
        BorderSizePixel = 0,
        Parent = sliderFrame
    })
    
    CreateUIInstance("UICorner", { CornerRadius = UDim.new(0, 5), Parent = sliderHandle })

    local function updateValue(x)
        local frameWidth = sliderFrame.AbsoluteSize.X
        local handleWidth = sliderHandle.AbsoluteSize.X
        local range = max - min
        
        local xClamped = math.max(0, math.min(frameWidth - handleWidth, x))
        local percent = xClamped / (frameWidth - handleWidth)
        
        local newValue = min + (range * percent)
        
        if step > 0 then
            newValue = math.round(newValue / step) * step
        end
        
        newValue = math.max(min, math.min(max, newValue))
        
        currentValue = newValue
        
        local newXScale = (newValue - min) / range
        sliderHandle.Position = UDim2.new(newXScale, -handleWidth / 2, -0.5, 0)
        displayLabel.Text = config.Name .. ": " .. tostring(math.floor(currentValue * 10) / 10)
        
        if config.Callback then
            config.Callback(currentValue)
        end
    end

    local dragging = false
    
    sliderHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    
    sliderHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if dragging and sliderHandle.Parent then
            local mouseX = LocalPlayer:GetMouse().X
            local x = mouseX - sliderFrame.AbsolutePosition.X
            updateValue(x)
        end
    end)

    if config.Callback then
        config.Callback(default)
    end
end

function Section:CreateButton(config)
    local element = self:CreateElementFrame(30)
    
    local button = CreateUIInstance("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        Text = config.Name,
        Font = Config.Font,
        TextColor3 = Config.TextColor,
        TextSize = 16,
        BackgroundColor3 = Config.AccentColor,
        BorderSizePixel = 0,
        Parent = element
    })
    
    CreateUIInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = button })
    
    button.MouseButton1Click:Connect(function()
        if config.Callback then
            config.Callback()
        end
    end)
end

function Section:CreateInput(config)
    local element = self:CreateElementFrame(30)
    
    local input = CreateUIInstance("TextBox", {
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        PlaceholderText = config.Placeholder or "Enter value...",
        Font = Config.Font,
        TextColor3 = Config.TextColor,
        TextSize = 16,
        BackgroundColor3 = Config.AccentColor,
        BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = element
    })
    
    CreateUIInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = input })
    
    input.TextStrokeTransparency = 0

    input.FocusLost:Connect(function(enterPressed)
        if enterPressed and config.Callback then
            config.Callback(input.Text)
            input.Text = ""
        end
    end)
end

function Section:CreateDropdown(config)
    local element = self:CreateElementFrame(30)
    
    local options = config.Options or {}
    local default = config.Default or options[1]
    local currentValue = default
    local optionsVisible = false

    local dropdownButton = CreateUIInstance("TextButton", {
        Name = "DropdownButton",
        Size = UDim2.new(1, 0, 1, 0),
        Text = config.Name .. ": " .. currentValue,
        Font = Config.Font,
        TextColor3 = Config.TextColor,
        TextSize = 16,
        BackgroundColor3 = Config.AccentColor,
        BorderSizePixel = 0,
        Parent = element
    })

    CreateUIInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = dropdownButton })

    local optionsFrame = CreateUIInstance("Frame", {
        Name = "OptionsFrame",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 5),
        BackgroundColor3 = Config.AccentColor,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 2,
        Parent = element
    })
    
    local optionLayout = CreateUIInstance("UIListLayout", {
        Name = "OptionLayout",
        Padding = UDim.new(0, 1),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Parent = optionsFrame
    })
    
    local optionsHeight = #options * 25

    optionsFrame.Size = UDim2.new(1, 0, 0, optionsHeight)
    
    CreateUIInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = optionsFrame })

    for _, optionText in ipairs(options) do
        local optionButton = CreateUIInstance("TextButton", {
            Name = "Option_" .. optionText,
            Size = UDim2.new(1, 0, 0, 24),
            Text = optionText,
            Font = Enum.Font.SourceSans,
            TextColor3 = Config.TextColor,
            TextSize = 14,
            BackgroundColor3 = Config.HighlightColor,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Parent = optionsFrame
        })

        optionButton.MouseButton1Click:Connect(function()
            currentValue = optionText
            dropdownButton.Text = config.Name .. ": " .. currentValue
            optionsVisible = false
            optionsFrame.Visible = false
            
            if config.Callback then
                config.Callback(currentValue)
            end
        end)
    end
    
    dropdownButton.MouseButton1Click:Connect(function()
        optionsVisible = not optionsVisible
        optionsFrame.Visible = optionsVisible
    end)
    
    if config.Callback then
        config.Callback(default)
    end
end

function Section:CreateColorPicker(config)
    self:CreateLabel(config.Name .. " (ColorPicker not implemented)")
end

function Library:Notify(config)
    print(string.format("[Vortex Notify] %s: %s (Duration: %s)", config.Title, config.Content, config.Duration))
end

return Library
