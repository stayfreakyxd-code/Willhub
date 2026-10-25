
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.Version = "1.1.0"
Library._windows = {}
Library._connections = {}
Library._notifications = {}
Library._commands = {}
Library._themeName = "Graphite"
Library._reducedMotion = false
Library._soundEnabled = false
Library._scale = 1
Library._destroyed = false

local THEMES = {
    Graphite = {
        Background=Color3.fromRGB(24,25,28), Panel=Color3.fromRGB(31,32,36), Panel2=Color3.fromRGB(39,40,45),
        Hover=Color3.fromRGB(49,50,56), Text=Color3.fromRGB(238,238,240), Muted=Color3.fromRGB(157,159,166),
        Border=Color3.fromRGB(64,65,72), Accent=Color3.fromRGB(190,194,204), Accent2=Color3.fromRGB(142,148,160),
        Good=Color3.fromRGB(119,183,147), Warn=Color3.fromRGB(208,173,112), Bad=Color3.fromRGB(201,125,132),
    },
    Oxblood = {
        Background=Color3.fromRGB(25,20,22), Panel=Color3.fromRGB(35,27,30), Panel2=Color3.fromRGB(46,34,38),
        Hover=Color3.fromRGB(59,42,47), Text=Color3.fromRGB(244,234,235), Muted=Color3.fromRGB(180,153,158),
        Border=Color3.fromRGB(83,56,63), Accent=Color3.fromRGB(157,79,94), Accent2=Color3.fromRGB(194,127,137),
        Good=Color3.fromRGB(119,183,147), Warn=Color3.fromRGB(208,173,112), Bad=Color3.fromRGB(201,125,132),
    },
    AntiqueGold = {
        Background=Color3.fromRGB(24,23,21), Panel=Color3.fromRGB(32,31,28), Panel2=Color3.fromRGB(42,40,35),
        Hover=Color3.fromRGB(54,51,44), Text=Color3.fromRGB(240,237,229), Muted=Color3.fromRGB(168,162,148),
        Border=Color3.fromRGB(72,67,55), Accent=Color3.fromRGB(177,151,94), Accent2=Color3.fromRGB(205,184,133),
        Good=Color3.fromRGB(119,183,147), Warn=Color3.fromRGB(208,173,112), Bad=Color3.fromRGB(201,125,132),
    },
    Porcelain = {
        Background=Color3.fromRGB(239,237,232), Panel=Color3.fromRGB(249,248,245), Panel2=Color3.fromRGB(231,229,223),
        Hover=Color3.fromRGB(220,217,209), Text=Color3.fromRGB(45,44,42), Muted=Color3.fromRGB(111,109,103),
        Border=Color3.fromRGB(210,207,199), Accent=Color3.fromRGB(106,108,112), Accent2=Color3.fromRGB(143,139,128),
        Good=Color3.fromRGB(49,132,91), Warn=Color3.fromRGB(157,111,38), Bad=Color3.fromRGB(171,67,75),
    },
    Sage = {
        Background=Color3.fromRGB(23,28,26), Panel=Color3.fromRGB(30,37,34), Panel2=Color3.fromRGB(39,47,43),
        Hover=Color3.fromRGB(50,60,54), Text=Color3.fromRGB(234,240,235), Muted=Color3.fromRGB(151,169,157),
        Border=Color3.fromRGB(59,76,65), Accent=Color3.fromRGB(132,160,139), Accent2=Color3.fromRGB(176,192,177),
        Good=Color3.fromRGB(119,183,147), Warn=Color3.fromRGB(208,173,112), Bad=Color3.fromRGB(201,125,132),
    },
}
-- Backwards-compatible theme names.
THEMES.Midnight = THEMES.Graphite
THEMES.OLED = {
    Background=Color3.fromRGB(8,8,9), Panel=Color3.fromRGB(15,15,17), Panel2=Color3.fromRGB(25,25,28), Hover=Color3.fromRGB(36,36,40),
    Text=Color3.fromRGB(241,241,243), Muted=Color3.fromRGB(155,155,160), Border=Color3.fromRGB(49,49,53), Accent=Color3.fromRGB(178,181,190),
    Accent2=Color3.fromRGB(135,139,150), Good=Color3.fromRGB(119,183,147), Warn=Color3.fromRGB(208,173,112), Bad=Color3.fromRGB(201,125,132),
}
THEMES.Aurora = THEMES.Sage
THEMES.Crimson = THEMES.Oxblood
THEMES.Light = THEMES.Porcelain

local function theme()
    return THEMES[Library._themeName] or THEMES.Midnight
end

local function make(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        if key ~= "Parent" then
            pcall(function() obj[key] = value end)
        end
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, parent)
end

local function stroke(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or theme().Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function padding(parent, left, right, top, bottom)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function listLayout(parent, direction, gap, horizontalAlignment)
    return make("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 8),
        HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left,
    }, parent)
end

local function tween(obj, duration, props, style, direction)
    if not obj or not obj.Parent then return nil end
    if Library._reducedMotion then duration = math.min(duration or 0, 0.06) end
    local info = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function track(connection)
    table.insert(Library._connections, connection)
    return connection
end

local function textLabel(parent, text, size, color, font, xAlign)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = color or theme().Text,
        Font = font or Enum.Font.Gotham,
        TextSize = size or 13,
        TextXAlignment = xAlign or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        RichText = false,
    }, parent)
end

local function buttonBase(parent, name, height)
    local b = make("TextButton", {
        Name = name or "Button",
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.new(1, 0, 0, height or 40),
        BackgroundColor3 = theme().Panel2,
        BorderSizePixel = 0,
    }, parent)
    corner(b, 9)
    local s = stroke(b, theme().Border, 0.18)
    local pressScale = make("UIScale", {Scale=1}, b)
    b.MouseEnter:Connect(function()
        tween(b, 0.14, {BackgroundColor3 = theme().Hover})
        tween(s, 0.14, {Transparency = 0})
    end)
    b.MouseLeave:Connect(function()
        tween(b, 0.18, {BackgroundColor3 = theme().Panel2})
        tween(s, 0.18, {Transparency = 0.18})
    end)
    b.MouseButton1Down:Connect(function()
        tween(b, 0.07, {BackgroundColor3 = theme().Accent})
        tween(pressScale, 0.08, {Scale=0.985}, Enum.EasingStyle.Quad)
    end)
    b.MouseButton1Up:Connect(function()
        tween(b, 0.14, {BackgroundColor3 = theme().Hover})
        tween(pressScale, 0.18, {Scale=1}, Enum.EasingStyle.Back)
    end)
    return b
end

local function invoke(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then warn("[Will Hub] Callback error: " .. tostring(err)) end
end

local function cleanOptions(options)
    return type(options) == "table" and options or {}
end

local function normalizeColor(value)
    if typeof(value) == "Color3" then return value end
    return theme().Accent
end

local function makeComponent(section, name, height)
    local frame = make("Frame", {
        Name = name or "Component",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 40),
        AutomaticSize = Enum.AutomaticSize.None,
    }, section._content)
    return frame
end

local function labelComponent(section, opts)
    opts = cleanOptions(opts)
    local height = opts.Height or 24
    local frame = makeComponent(section, "Label", height)
    local label = textLabel(frame, opts.Text or opts.Name or "", opts.TextSize or 13,
        opts.Color or theme().Muted, opts.Font or Enum.Font.GothamMedium)
    label.Size = UDim2.new(1, 0, 1, 0)
    local object = {_instance = frame, _label = label}
    function object:SetText(value) label.Text = tostring(value or "") end
    function object:GetText() return label.Text end
    function object:SetVisible(value) frame.Visible = value == true end
    function object:Destroy() frame:Destroy() end
    return object
end

local function createSection(tab, options)
    options = cleanOptions(options)
    local frame = make("Frame", {
        Name = "Section",
        BackgroundColor3 = theme().Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 80),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, tab._content)
    corner(frame, 12)
    stroke(frame, theme().Border, 0.2)
    padding(frame, 12, 12, 10, 12)
    local title = textLabel(frame, options.Title or options.Name or "Section", 13, theme().Text, Enum.Font.GothamBold)
    title.Size = UDim2.new(1, -30, 0, 24)
    local collapse = make("TextButton", {
        Name = "Collapse",
        BackgroundTransparency = 1,
        Text = "−",
        TextSize = 20,
        Font = Enum.Font.GothamMedium,
        TextColor3 = theme().Muted,
        Size = UDim2.fromOffset(26, 24),
        Position = UDim2.new(1, -26, 0, 0),
        AutoButtonColor = false,
    }, frame)
    local content = make("Frame", {
        Name = "Components",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 31),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, frame)
    listLayout(content, Enum.FillDirection.Vertical, 7)
    local section = {_instance = frame, _content = content, _title = title, _tab = tab, _collapsed = false}
    function section:SetTitle(value) title.Text = tostring(value or "") end
    function section:SetVisible(value) frame.Visible = value == true end
    function section:SetCollapsed(value)
        self._collapsed = value == true
        collapse.Text = self._collapsed and "+" or "−"
        if Library._reducedMotion then
            content.Visible = not self._collapsed
            content.AutomaticSize = self._collapsed and Enum.AutomaticSize.None or Enum.AutomaticSize.Y
            content.Size = UDim2.new(1,0,0,0)
            frame.AutomaticSize = Enum.AutomaticSize.Y
            return
        end
        if self._collapsed then
            local measured = content.AbsoluteSize.Y
            content.AutomaticSize = Enum.AutomaticSize.None
            content.Size = UDim2.new(1,0,0,measured)
            content.Visible = true
            tween(content, .19, {Size=UDim2.new(1,0,0,0)}, Enum.EasingStyle.Quart)
            task.delay(.2,function() if content.Parent and self._collapsed then content.Visible=false end end)
        else
            content.Visible = true
            content.AutomaticSize = Enum.AutomaticSize.None
            content.Size = UDim2.new(1,0,0,0)
            local target = content.UIListLayout.AbsoluteContentSize.Y
            tween(content, .24, {Size=UDim2.new(1,0,0,target)}, Enum.EasingStyle.Back)
            task.delay(.25,function() if content.Parent and not self._collapsed then content.AutomaticSize=Enum.AutomaticSize.Y; content.Size=UDim2.new(1,0,0,0) end end)
        end
        frame.AutomaticSize = Enum.AutomaticSize.Y
    end
    collapse.MouseButton1Click:Connect(function() section:SetCollapsed(not section._collapsed) end)

    function section:CreateLabel(opts) return labelComponent(self, opts) end
    function section:CreateParagraph(opts)
        opts = cleanOptions(opts)
        local holder = makeComponent(self, "Paragraph", opts.Height or 58)
        local head = textLabel(holder, opts.Title or "Information", 12, theme().Text, Enum.Font.GothamBold)
        head.Size = UDim2.new(1, 0, 0, 18)
        local body = textLabel(holder, opts.Content or opts.Text or "", 12, theme().Muted, Enum.Font.Gotham)
        body.Position = UDim2.fromOffset(0, 19)
        body.Size = UDim2.new(1, 0, 1, -19)
        body.TextWrapped = true
        body.TextYAlignment = Enum.TextYAlignment.Top
        local obj = {_instance = holder}
        function obj:SetText(v) body.Text = tostring(v or "") end
        function obj:SetTitle(v) head.Text = tostring(v or "") end
        function obj:Destroy() holder:Destroy() end
        return obj
    end
    function section:CreateDivider()
        local f = makeComponent(self, "Divider", 12)
        local line = make("Frame", {
            BackgroundColor3 = theme().Border, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0),
        }, f)
        return { _instance = f, Destroy = function() f:Destroy() end }
    end
    function section:CreateButton(opts)
        opts = cleanOptions(opts)
        local b = buttonBase(content, "Button", opts.Height or 40)
        b.Parent = content
        local icon = textLabel(b, opts.Icon or "↗", 15, theme().Accent, Enum.Font.GothamBold)
        icon.Position = UDim2.fromOffset(12, 0)
        icon.Size = UDim2.fromOffset(24, 40)
        local nameLabel = textLabel(b, opts.Name or "Button", 12, theme().Text, Enum.Font.GothamMedium)
        nameLabel.Position = UDim2.fromOffset(42, 0)
        nameLabel.Size = UDim2.new(1, -54, 1, 0)
        local object = {_instance = b, _disabled = false}
        b.MouseButton1Click:Connect(function()
            if not object._disabled then invoke(opts.Callback, object) end
        end)
        function object:SetText(v) nameLabel.Text = tostring(v or "") end
        function object:SetDisabled(v) object._disabled = v == true; b.Active = not object._disabled; b.BackgroundTransparency = object._disabled and 0.45 or 0 end
        function object:SetLoading(v) nameLabel.Text = v and "Loading…" or (opts.Name or "Button") end
        function object:Destroy() b:Destroy() end
        return object
    end
    function section:CreateToggle(opts)
        opts = cleanOptions(opts)
        local b = buttonBase(content, "Toggle", opts.Height or 42)
        local nameLabel = textLabel(b, opts.Name or "Toggle", 12, theme().Text, Enum.Font.GothamMedium)
        nameLabel.Position = UDim2.fromOffset(12, 0)
        nameLabel.Size = UDim2.new(1, -76, 1, 0)
        local trackFrame = make("Frame", {
            BackgroundColor3 = theme().Border, BorderSizePixel = 0,
            Size = UDim2.fromOffset(38, 21), Position = UDim2.new(1, -50, 0.5, -10),
        }, b)
        corner(trackFrame, 11)
        local knob = make("Frame", {
            BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
            Size = UDim2.fromOffset(15, 15), Position = UDim2.fromOffset(3, 3),
        }, trackFrame)
        corner(knob, 8)
        local obj = {_instance = b, _value = opts.Default == true}
        local function set(v, fire)
            obj._value = v == true
            tween(trackFrame, 0.16, {BackgroundColor3 = obj._value and theme().Accent or theme().Border})
            tween(knob, 0.16, {Position = obj._value and UDim2.fromOffset(20,3) or UDim2.fromOffset(3,3)})
            if fire then invoke(opts.Callback, obj._value) end
        end
        b.MouseButton1Click:Connect(function() set(not obj._value, true) end)
        set(obj._value, false)
        function obj:SetValue(v) set(v, true) end
        function obj:GetValue() return obj._value end
        function obj:SetText(v) nameLabel.Text = tostring(v or "") end
        function obj:Destroy() b:Destroy() end
        return obj
    end
    function section:CreateSlider(opts)
        opts = cleanOptions(opts)
        local min, max = tonumber(opts.Min) or 0, tonumber(opts.Max) or 100
        if max < min then min, max = max, min end
        local step = math.max(tonumber(opts.Step) or 1, 0.000001)
        local frame = makeComponent(self, "Slider", opts.Height or 58)
        local nameLabel = textLabel(frame, opts.Name or "Slider", 12, theme().Text, Enum.Font.GothamMedium)
        nameLabel.Size = UDim2.new(1, -70, 0, 20)
        local valueLabel = textLabel(frame, "", 11, theme().Accent, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
        valueLabel.Position = UDim2.new(1, -65, 0, 0)
        valueLabel.Size = UDim2.fromOffset(65, 20)
        local bar = make("Frame", {BackgroundColor3 = theme().Border, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 31), Size = UDim2.new(1, 0, 0, 7)}, frame)
        corner(bar, 5)
        local fill = make("Frame", {BackgroundColor3 = theme().Accent, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0)}, bar)
        corner(fill, 5)
        local knob = make("Frame", {BackgroundColor3 = theme().Text, BorderSizePixel = 0, Size = UDim2.fromOffset(15,15), AnchorPoint = Vector2.new(.5,.5), Position = UDim2.new(0,0,.5,0)}, bar)
        corner(knob, 8)
        local obj = {_instance = frame, _value = tonumber(opts.Default) or min}
        local dragging = false
        local function set(value, fire)
            value = math.clamp(tonumber(value) or min, min, max)
            value = min + math.floor(((value-min)/step)+0.5)*step
            value = math.clamp(value, min, max)
            obj._value = value
            local alpha = max == min and 0 or (value-min)/(max-min)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            knob.Position = UDim2.new(alpha, 0, .5, 0)
            valueLabel.Text = tostring(value) .. tostring(opts.Suffix or "")
            if fire then invoke(opts.Callback, value) end
        end
        local function fromX(x)
            local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X,1), 0, 1)
            set(min + alpha*(max-min), true)
        end
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; fromX(input.Position.X)
            end
        end)
        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fromX(input.Position.X) end
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end))
        set(obj._value, false)
        function obj:SetValue(v) set(v, true) end
        function obj:GetValue() return obj._value end
        function obj:Destroy() frame:Destroy() end
        return obj
    end
    function section:CreateDropdown(opts)
        opts = cleanOptions(opts)
        local optionsList = opts.Options or {}
        local current = opts.Default
        local expanded = false
        local frame = makeComponent(self, "Dropdown", 42)
        local main = buttonBase(frame, "DropdownButton", 40)
        local title = textLabel(main, tostring(opts.Name or "Dropdown") .. "  ·  " .. tostring(current or "Select…"), 12, theme().Text, Enum.Font.GothamMedium)
        title.Position = UDim2.fromOffset(12,0); title.Size = UDim2.new(1,-35,1,0)
        local arrow = textLabel(main, "⌄", 17, theme().Muted, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
        arrow.Position = UDim2.new(1,-32,0,0); arrow.Size = UDim2.fromOffset(24,40)
        local choices = make("Frame", {Visible=false, BackgroundColor3=theme().Panel2, BorderSizePixel=0, Position=UDim2.fromOffset(0,44), Size=UDim2.new(1,0,0,0), ClipsDescendants=true}, frame)
        corner(choices, 9); stroke(choices, theme().Border, .2)
        local choiceLayout = listLayout(choices, Enum.FillDirection.Vertical, 2)
        padding(choices, 5,5,5,5)
        local obj = {_instance = frame}
        local function redraw()
            for _, child in ipairs(choices:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
            for _, option in ipairs(optionsList) do
                local choice = make("TextButton", {AutoButtonColor=false, Text=tostring(option), TextColor3=(option == current and theme().Accent or theme().Text), Font=Enum.Font.Gotham, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, BackgroundColor3=(option == current and theme().Hover or theme().Panel2), BorderSizePixel=0, Size=UDim2.new(1,0,0,30)}, choices)
                corner(choice, 6); padding(choice, 9,5,0,0)
                choice.MouseButton1Click:Connect(function()
                    current = option; title.Text = tostring(opts.Name or "Dropdown") .. "  ·  " .. tostring(current)
                    expanded = false; choices.Visible = false; frame.Size = UDim2.new(1,0,0,42); arrow.Text = "⌄"
                    invoke(opts.Callback, current)
                end)
            end
            choices.Size = UDim2.new(1,0,0,math.min(#optionsList*32+10, 150))
        end
        main.MouseButton1Click:Connect(function()
            expanded = not expanded
            choices.Visible = expanded
            frame.Size = UDim2.new(1,0,0,expanded and (46 + math.min(#optionsList*32+10,150)) or 42)
            arrow.Text = expanded and "⌃" or "⌄"
        end)
        redraw()
        function obj:SetValue(v)
            for _, opt in ipairs(optionsList) do if opt == v then current=v; title.Text=tostring(opts.Name or "Dropdown").."  ·  "..tostring(v); redraw(); invoke(opts.Callback,current); return end end
        end
        function obj:GetValue() return current end
        function obj:SetOptions(v) optionsList = type(v)=="table" and v or {}; if not table.find(optionsList,current) then current = optionsList[1] end; redraw() end
        function obj:Destroy() frame:Destroy() end
        return obj
    end
    function section:CreateMultiDropdown(opts)
        opts = cleanOptions(opts)
        local selected = {}
        for _, value in ipairs(opts.Default or {}) do selected[value] = true end
        local frame = makeComponent(self, "MultiDropdown", 42)
        local main = buttonBase(frame, "MultiDropdownButton", 40)
        local title = textLabel(main, opts.Name or "Multi-select", 12, theme().Text, Enum.Font.GothamMedium)
        title.Position=UDim2.fromOffset(12,0); title.Size=UDim2.new(1,-24,1,0)
        local list = make("Frame",{Visible=false,BackgroundColor3=theme().Panel2,BorderSizePixel=0,Position=UDim2.fromOffset(0,44),Size=UDim2.new(1,0,0,0),ClipsDescendants=true},frame)
        corner(list,9); stroke(list,theme().Border,.2); padding(list,6,6,5,5); listLayout(list,Enum.FillDirection.Vertical,2)
        local obj={_instance=frame}
        local function refresh()
            local names={}
            for _,v in ipairs(opts.Options or {}) do if selected[v] then table.insert(names,tostring(v)) end end
            title.Text=(opts.Name or "Multi-select").."  ·  "..(#names>0 and table.concat(names,", ") or "None")
            for _,c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for _,v in ipairs(opts.Options or {}) do
                local b=make("TextButton",{AutoButtonColor=false,Text=(selected[v] and "✓  " or "    ")..tostring(v),TextColor3=theme().Text,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=theme().Panel2,BorderSizePixel=0,Size=UDim2.new(1,0,0,28)},list)
                b.MouseButton1Click:Connect(function() selected[v]=not selected[v] or nil; refresh(); invoke(opts.Callback,obj:GetValue()) end)
            end
            list.Size=UDim2.new(1,0,0,math.min(#(opts.Options or {})*30+10,150))
        end
        main.MouseButton1Click:Connect(function()
            list.Visible=not list.Visible
            frame.Size=UDim2.new(1,0,0,list.Visible and (46+math.min(#(opts.Options or {})*30+10,150)) or 42)
        end)
        function obj:GetValue() local out={}; for _,v in ipairs(opts.Options or {}) do if selected[v] then table.insert(out,v) end end; return out end
        function obj:SetValue(values) selected={}; for _,v in ipairs(values or {}) do selected[v]=true end; refresh(); invoke(opts.Callback,obj:GetValue()) end
        function obj:SetOptions(values) opts.Options=values or {}; refresh() end
        function obj:Destroy() frame:Destroy() end
        refresh()
        return obj
    end
    function section:CreateTextbox(opts)
        opts = cleanOptions(opts)
        local frame = makeComponent(self, "Textbox", opts.Height or 42)
        local box = make("TextBox",{ClearTextOnFocus=false,Text=tostring(opts.Default or ""),PlaceholderText=opts.Placeholder or "Enter text…",TextColor3=theme().Text,PlaceholderColor3=theme().Muted,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=theme().Panel2,BorderSizePixel=0,Size=UDim2.new(1,0,1,0)},frame)
        corner(box,9); stroke(box,theme().Border,.2); padding(box,11,10,0,0)
        local obj={_instance=frame}
        box.FocusLost:Connect(function(enterPressed) if enterPressed then invoke(opts.Callback,box.Text) end end)
        function obj:SetText(v) box.Text=tostring(v or "") end
        function obj:GetValue() return box.Text end
        function obj:Destroy() frame:Destroy() end
        return obj
    end
    function section:CreateKeybind(opts)
        opts=cleanOptions(opts)
        local frame=makeComponent(self,"Keybind",42)
        local b=buttonBase(frame,"KeybindButton",40)
        local title=textLabel(b,opts.Name or "Keybind",12,theme().Text,Enum.Font.GothamMedium)
        title.Position=UDim2.fromOffset(12,0); title.Size=UDim2.new(1,-95,1,0)
        local key=opts.Default or Enum.KeyCode.RightShift
        local keyLabel=textLabel(b,key.Name,11,theme().Accent,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
        keyLabel.Position=UDim2.new(1,-82,0,0); keyLabel.Size=UDim2.fromOffset(70,40)
        local listening=false
        local obj={_instance=frame}
        b.MouseButton1Click:Connect(function() listening=true; keyLabel.Text="Press key…" end)
        track(UserInputService.InputBegan:Connect(function(input,processed)
            if processed then return end
            if listening and input.UserInputType==Enum.UserInputType.Keyboard then
                key=input.KeyCode; listening=false; keyLabel.Text=key.Name
            elseif not listening and input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==key then
                invoke(opts.Callback,key)
            end
        end))
        function obj:SetValue(v) if typeof(v)=="EnumItem" then key=v; keyLabel.Text=key.Name end end
        function obj:GetValue() return key end
        function obj:Destroy() frame:Destroy() end
        return obj
    end
    function section:CreateColorPicker(opts)
        opts=cleanOptions(opts)
        local color=normalizeColor(opts.Default)
        local frame=makeComponent(self,"ColorPicker",42)
        local b=buttonBase(frame,"ColorPickerButton",40)
        local title=textLabel(b,opts.Name or "Accent color",12,theme().Text,Enum.Font.GothamMedium)
        title.Position=UDim2.fromOffset(12,0); title.Size=UDim2.new(1,-65,1,0)
        local swatch=make("Frame",{BackgroundColor3=color,BorderSizePixel=0,Size=UDim2.fromOffset(28,22),Position=UDim2.new(1,-40,.5,-11)},b)
        corner(swatch,6); stroke(swatch,theme().Border,.1)
        local obj={_instance=frame,_value=color}
        b.MouseButton1Click:Connect(function()
            -- A compact palette of safe presets keeps the component dependency-free.
            local palette={Color3.fromRGB(155,115,255),Color3.fromRGB(74,224,190),Color3.fromRGB(255,91,131),Color3.fromRGB(92,190,255),Color3.fromRGB(255,190,92)}
            local index=table.find(palette,obj._value) or 0
            obj:SetValue(palette[index%#palette+1])
        end)
        function obj:SetValue(v) color=normalizeColor(v); obj._value=color; swatch.BackgroundColor3=color; invoke(opts.Callback,color) end
        function obj:GetValue() return obj._value end
        function obj:Destroy() frame:Destroy() end
        return obj
    end
    function section:CreateCard(opts)
        opts=cleanOptions(opts)
        local frame=makeComponent(self,"Card",opts.Height or 78)
        frame.BackgroundColor3=theme().Panel2; frame.BackgroundTransparency=0; corner(frame,10); stroke(frame,theme().Border,.25); padding(frame,12,12,8,8)
        local title=textLabel(frame,opts.Title or "Card",12,theme().Muted,Enum.Font.GothamMedium)
        title.Size=UDim2.new(1,0,0,18)
        local value=textLabel(frame,opts.Value or "—",22,theme().Text,Enum.Font.GothamBold)
        value.Position=UDim2.fromOffset(0,22); value.Size=UDim2.new(1,0,0,27)
        local obj={_instance=frame}
        function obj:SetValue(v) value.Text=tostring(v); tween(value,.2,{TextColor3=theme().Accent}); task.delay(.25,function() if value.Parent then tween(value,.2,{TextColor3=theme().Text}) end end) end
        function obj:SetTitle(v) title.Text=tostring(v) end
        function obj:Destroy() frame:Destroy() end
        return obj
    end
    function section:CreateStatCard(opts) return self:CreateCard(opts) end
    function section:CreateProfileCard(opts)
        opts=cleanOptions(opts)
        local frame=makeComponent(self,"ProfileCard",94)
        frame.BackgroundColor3=theme().Panel2; frame.BackgroundTransparency=0; corner(frame,11); stroke(frame,theme().Border,.2)
        local image=make("ImageLabel",{BackgroundColor3=theme().Hover,BorderSizePixel=0,Size=UDim2.fromOffset(66,66),Position=UDim2.fromOffset(12,14),Image=opts.Image or ""},frame)
        corner(image,12)
        local name=textLabel(frame,opts.DisplayName or opts.Name or "Player",14,theme().Text,Enum.Font.GothamBold)
        name.Position=UDim2.fromOffset(90,18); name.Size=UDim2.new(1,-102,0,24)
        local username=textLabel(frame,opts.Username and ("@"..opts.Username) or "Player profile",11,theme().Muted,Enum.Font.Gotham)
        username.Position=UDim2.fromOffset(90,44); username.Size=UDim2.new(1,-102,0,20)
        local obj={_instance=frame}
        function obj:SetImage(v) image.Image=tostring(v or "") end
        function obj:SetName(v) name.Text=tostring(v or "") end
        function obj:SetUsername(v) username.Text="@"..tostring(v or "") end
        function obj:Destroy() frame:Destroy() end
        return obj
    end
    function section:CreatePlayerPreview(opts)
        opts=cleanOptions(opts)
        local frame=makeComponent(self,"PlayerPreview",opts.Height or 230)
        frame.BackgroundColor3=theme().Panel2; frame.BackgroundTransparency=0; corner(frame,12); stroke(frame,theme().Border,.2)
        local viewport=make("ViewportFrame",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,-28),Ambient=Color3.fromRGB(180,180,200),LightColor=Color3.fromRGB(255,255,255),LightDirection=Vector3.new(-1,-1,-1)},frame)
        local caption=textLabel(frame,opts.Caption or "3D PLAYER PREVIEW",10,theme().Muted,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
        caption.Position=UDim2.new(0,0,1,-27); caption.Size=UDim2.new(1,0,0,20)
        local world=Instance.new("WorldModel"); world.Parent=viewport
        local camera=Instance.new("Camera"); camera.Parent=viewport; viewport.CurrentCamera=camera
        local obj={_instance=frame,_viewport=viewport,_world=world,_camera=camera,_model=nil,_rotating=true}
        local function loadCharacter(character)
            if obj._model then obj._model:Destroy(); obj._model=nil end
            if not character then return end
            local ok, clone=pcall(function() return character:Clone() end)
            if not ok or not clone then return end
            for _,desc in ipairs(clone:GetDescendants()) do
                if desc:IsA("Script") or desc:IsA("LocalScript") then desc:Destroy() end
            end
            clone.Parent=world
            local root=clone:FindFirstChild("HumanoidRootPart")
            if not root then clone:Destroy(); return end
            clone:PivotTo(CFrame.new(0,0,0))
            obj._model=clone
            local _,size=clone:GetBoundingBox()
            camera.CFrame=CFrame.new(Vector3.new(0, size.Y*0.12, math.max(size.Y*1.7,5)),Vector3.new(0,size.Y*0.45,0))
        end
        if opts.Character then loadCharacter(opts.Character)
        elseif LocalPlayer and LocalPlayer.Character then loadCharacter(LocalPlayer.Character) end
        function obj:SetCharacter(character) loadCharacter(character) end
        function obj:SetRotating(value) obj._rotating=value==true end
        function obj:Reset() if obj._model then obj._model:PivotTo(CFrame.new(0,0,0)) end end
        function obj:Destroy() frame:Destroy(); world:Destroy(); camera:Destroy() end
        local conn=RunService.RenderStepped:Connect(function(dt)
            if obj._rotating and obj._model and obj._model.Parent then
                obj._model:PivotTo(obj._model:GetPivot()*CFrame.Angles(0,dt*.35,0))
            end
        end)
        table.insert(Library._connections,conn)
        return obj
    end
    function section:CreateActivityFeed(opts)
        opts=cleanOptions(opts)
        local frame=makeComponent(self,"ActivityFeed",opts.Height or 150)
        frame.BackgroundColor3=theme().Panel2; frame.BackgroundTransparency=0; corner(frame,10); stroke(frame,theme().Border,.2); padding(frame,9,9,8,8)
        local scroll=make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,1,0),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=theme().Accent},frame)
        listLayout(scroll,Enum.FillDirection.Vertical,6)
        local obj={_instance=frame,_scroll=scroll}
        function obj:Add(text)
            local row=make("TextLabel",{BackgroundTransparency=1,Text="•  "..os.date("%H:%M:%S").."  "..tostring(text),TextColor3=theme().Muted,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-4,0,18)},scroll)
            return row
        end
        function obj:Clear() for _,c in ipairs(scroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end end
        function obj:Destroy() frame:Destroy() end
        return obj
    end
    return section
end

function Library:GetTheme() return Library._themeName end

function Library:SetTheme(name)
    if not THEMES[name] then return false end
    local oldTheme = theme()
    local newTheme = THEMES[name]
    Library._themeName = name
    local oldToRole = {}
    for role, color in pairs(oldTheme) do
        if typeof(color)=="Color3" and oldToRole[color]==nil then oldToRole[color]=role end
    end
    local function recolor(gui)
        local props = {"BackgroundColor3","TextColor3","ImageColor3","ScrollBarImageColor3","BorderColor3"}
        for _,prop in ipairs(props) do
            local ok, value = pcall(function() return gui[prop] end)
            if ok and typeof(value)=="Color3" then
                local role=oldToRole[value]
                if role and newTheme[role] then pcall(function() gui[prop]=newTheme[role] end) end
            end
        end
        if gui:IsA("UIStroke") then
            local role=oldToRole[gui.Color]
            if role and newTheme[role] then gui.Color=newTheme[role] end
        end
    end
    for _,win in ipairs(Library._windows) do
        if win._screen and win._screen.Parent then
            recolor(win._screen)
            for _,desc in ipairs(win._screen:GetDescendants()) do recolor(desc) end
            if win._orb then win._orb.BackgroundColor3=newTheme.Accent end
        end
    end
    return true
end

function Library:SetAccentColor(color)
    if typeof(color)~="Color3" then return end
    local t=theme()
    t.Accent=color
    for _,win in ipairs(Library._windows) do
        if win._accentBar then win._accentBar.BackgroundColor3=color end
    end
end

function Library:SetScale(value)
    Library._scale=math.clamp(tonumber(value) or 1,0.65,1.4)
    for _,win in ipairs(Library._windows) do if win._uiScale then win._uiScale.Scale=Library._scale end end
end

function Library:SetReducedMotion(value) Library._reducedMotion=value==true end
function Library:SetSoundEnabled(value) Library._soundEnabled=value==true end

function Library:Notify(options)
    options=cleanOptions(options)
    local t=theme()
    local screen
    for _,win in ipairs(self._windows) do if win._screen and win._screen.Parent then screen=win._screen; break end end
    if not screen then return end
    local holder=make("Frame",{Name="Notification",BackgroundColor3=t.Panel2,BorderSizePixel=0,Size=UDim2.fromOffset(285,78),AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,310,0,18)},screen)
    corner(holder,12); stroke(holder,t.Border,.1)
    local accentColor=options.Type=="Success" and t.Good or options.Type=="Warning" and t.Warn or options.Type=="Error" and t.Bad or t.Accent
    local stripe=make("Frame",{BackgroundColor3=accentColor,BorderSizePixel=0,Size=UDim2.new(0,4,1,-18),Position=UDim2.fromOffset(8,9)},holder); corner(stripe,3)
    local title=textLabel(holder,options.Title or "Will Hub",12,t.Text,Enum.Font.GothamBold)
    title.Position=UDim2.fromOffset(22,10); title.Size=UDim2.new(1,-34,0,20)
    local body=textLabel(holder,options.Content or options.Message or "",11,t.Muted,Enum.Font.Gotham)
    body.Position=UDim2.fromOffset(22,32); body.Size=UDim2.new(1,-34,0,34); body.TextWrapped=true; body.TextYAlignment=Enum.TextYAlignment.Top
    local bar=make("Frame",{BackgroundColor3=accentColor,BorderSizePixel=0,Position=UDim2.new(0,12,1,-5),Size=UDim2.new(1,-24,0,2)},holder); corner(bar,2)
    table.insert(self._notifications,holder)
    holder.Rotation=1.5
    tween(holder,.34,{Position=UDim2.new(1,-18,0,18+(#self._notifications-1)*88),Rotation=0},Enum.EasingStyle.Back)
    local duration=math.max(tonumber(options.Duration) or 3,0.5)
    tween(bar,duration,{Size=UDim2.new(0,0,0,2)},Enum.EasingStyle.Linear)
    task.delay(duration,function()
        if holder.Parent then
            tween(holder,.2,{Position=holder.Position+UDim2.fromOffset(24,0),Rotation=2,BackgroundTransparency=1},Enum.EasingStyle.Quart,Enum.EasingDirection.In)
            task.wait(.22)
            if holder.Parent then holder:Destroy() end
            for i,v in ipairs(self._notifications) do if v==holder then table.remove(self._notifications,i); break end end
        end
    end)
    return holder
end

function Library:CreateNotificationCenter(options)
    local history={}
    local center={}
    function center:Add(opts) table.insert(history,opts); Library:Notify(opts) end
    function center:GetHistory() return history end
    function center:Clear() table.clear(history) end
    return center
end

function Library:RegisterCommand(options)
    options=cleanOptions(options)
    if not options.Name or type(options.Callback)~="function" then return false end
    self._commands[string.lower(options.Name)]=options
    return true
end
function Library:UnregisterCommand(name) self._commands[string.lower(tostring(name))]=nil end
function Library:OpenCommandPalette()
    for _,win in ipairs(self._windows) do if win.OpenCommandPalette then win:OpenCommandPalette() end end
end

function Library:CreateWindow(options)
    options=cleanOptions(options)
    local t=theme()
    local playerGui=LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then error("Will Hub requires a LocalPlayer PlayerGui.") end
    local old=playerGui:FindFirstChild("WillHubUI")
    if old then old:Destroy() end
    local screen=make("ScreenGui",{Name="WillHubUI",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=80},playerGui)
    local desiredSize = options.Size or UDim2.fromOffset(780,520)
    local root=make("Frame",{Name="Window",BackgroundColor3=t.Background,BorderSizePixel=0,Size=desiredSize,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),ClipsDescendants=false},screen)
    corner(root,16); stroke(root,t.Border,.05,1)
    local scale=make("UIScale",{Scale=Library._scale},root)
    local topbar=make("Frame",{Name="Topbar",BackgroundColor3=t.Panel,BorderSizePixel=0,Size=UDim2.new(1,0,0,54)},root)
    corner(topbar,16)
    local cover=make("Frame",{BackgroundColor3=t.Panel,BorderSizePixel=0,Position=UDim2.new(0,0,1,-15),Size=UDim2.new(1,0,0,15)},topbar)
    local logo=make("Frame",{BackgroundColor3=t.Accent,BorderSizePixel=0,Size=UDim2.fromOffset(30,30),Position=UDim2.fromOffset(14,12)},topbar); corner(logo,9)
    local logoText=textLabel(logo,"W",15,Color3.new(1,1,1),Enum.Font.GothamBlack,Enum.TextXAlignment.Center); logoText.Size=UDim2.fromScale(1,1)
    local title=textLabel(topbar,options.Title or "Will Hub",14,t.Text,Enum.Font.GothamBold)
    title.Position=UDim2.fromOffset(54,7); title.Size=UDim2.new(0,180,0,21)
    local subtitle=textLabel(topbar,options.Subtitle or "Futuristic Control Center",10,t.Muted,Enum.Font.Gotham)
    subtitle.Position=UDim2.fromOffset(54,28); subtitle.Size=UDim2.new(0,230,0,15)
    local clock=textLabel(topbar,os.date("%H:%M:%S"),11,t.Muted,Enum.Font.Code,Enum.TextXAlignment.Right)
    clock.Position=UDim2.new(1,-174,0,0); clock.Size=UDim2.fromOffset(85,54)
    local minimize=make("TextButton",{Text="—",TextSize=18,Font=Enum.Font.GothamBold,TextColor3=t.Muted,BackgroundColor3=t.Panel2,BorderSizePixel=0,Size=UDim2.fromOffset(30,30),Position=UDim2.new(1,-76,0,12),AutoButtonColor=false},topbar); corner(minimize,8)
    local close=make("TextButton",{Text="×",TextSize=20,Font=Enum.Font.Gotham,TextColor3=t.Muted,BackgroundColor3=t.Panel2,BorderSizePixel=0,Size=UDim2.fromOffset(30,30),Position=UDim2.new(1,-38,0,12),AutoButtonColor=false},topbar); corner(close,8)
    local body=make("Frame",{Name="Body",BackgroundTransparency=1,Position=UDim2.fromOffset(0,54),Size=UDim2.new(1,0,1,-54)},root)
    local sidebar=make("Frame",{Name="Sidebar",BackgroundColor3=t.Panel,BorderSizePixel=0,Size=UDim2.new(0,172,1,0)},body)
    local nav=make("ScrollingFrame",{Name="Navigation",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(10,12),Size=UDim2.new(1,-20,1,-55),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=t.Accent},sidebar)
    listLayout(nav,Enum.FillDirection.Vertical,6)
    local foot=textLabel(sidebar,"WILL HUB  •  "..Library.Version,9,t.Muted,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
    foot.Position=UDim2.new(0,8,1,-32); foot.Size=UDim2.new(1,-16,0,20)
    local contentArea=make("Frame",{Name="ContentArea",BackgroundTransparency=1,Position=UDim2.new(0,172,0,0),Size=UDim2.new(1,-172,1,0)},body)
    local pages=make("Frame",{Name="Pages",BackgroundTransparency=1,Position=UDim2.fromOffset(14,12),Size=UDim2.new(1,-28,1,-24)},contentArea)
    local orb=make("TextButton",{Name="MinimizedOrb",Visible=false,Text="W",Font=Enum.Font.GothamBlack,TextSize=19,TextColor3=Color3.new(1,1,1),BackgroundColor3=t.Accent,BorderSizePixel=0,Size=UDim2.fromOffset(58,58),Position=UDim2.new(1,-82,1,-82),AutoButtonColor=false},screen)
    corner(orb,30); stroke(orb,t.Accent2,0,2)
    local orbScale=make("UIScale",{Scale=1},orb)
    local win={_screen=screen,_root=root,_uiScale=scale,_topbar=topbar,_sidebar=sidebar,_accentBar=logo,_tabs={},_activeTab=nil,_pages=pages,_nav=nav,_orb=orb,_title=title,_subtitle=subtitle,_closed=false}
    table.insert(self._windows,win)
    -- Gentle entrance: lift, scale and rotate into place. No constant or neon animation.
    local windowScale = scale
    win._windowScale = windowScale
    if not Library._reducedMotion then windowScale.Scale=Library._scale*.94 end
    if not Library._reducedMotion then
        root.Position = UDim2.new(.5,0,.5,16)
        root.Rotation = 1.5
        root.BackgroundTransparency = 1
        tween(root,.32,{Position=UDim2.fromScale(.5,.5),Rotation=0,BackgroundTransparency=0},Enum.EasingStyle.Quart)
        tween(windowScale,.38,{Scale=Library._scale},Enum.EasingStyle.Back)
    end
    local minimized=false
    local savedWindowPosition=UDim2.fromScale(.5,.5)
    local tabTransitionId=0
    function win:Minimize()
        if minimized or self._closed then return end
        savedWindowPosition=root.Position
        minimized=true
        orb.Visible=true; orb.Size=UDim2.fromOffset(8,8); orbScale.Scale=.55; orb.Rotation=-12
        if Library._reducedMotion then
            root.Visible=false; orb.Size=UDim2.fromOffset(58,58); orbScale.Scale=1; orb.Rotation=0
            return
        end
        tween(root,.26,{Rotation=5,Position=UDim2.new(1,-53,1,-53),BackgroundTransparency=1},Enum.EasingStyle.Back,Enum.EasingDirection.In)
        tween(windowScale,.26,{Scale=Library._scale*.18},Enum.EasingStyle.Quart,Enum.EasingDirection.In)
        task.delay(.27,function() if root.Parent and minimized then root.Visible=false end end)
        tween(orb,.36,{Size=UDim2.fromOffset(58,58),Rotation=0},Enum.EasingStyle.Back)
        tween(orbScale,.36,{Scale=1},Enum.EasingStyle.Back)
    end
    function win:Restore()
        if not minimized or self._closed then return end
        minimized=false
        root.Visible=true
        root.Position=UDim2.new(savedWindowPosition.X.Scale,savedWindowPosition.X.Offset,savedWindowPosition.Y.Scale,savedWindowPosition.Y.Offset+12); root.Rotation=-1.5
        if Library._reducedMotion then
            orb.Visible=false; orb.Size=UDim2.fromOffset(58,58); orb.Rotation=0; root.Position=savedWindowPosition; root.Rotation=0; windowScale.Scale=Library._scale
            return
        end
        tween(orb,.2,{Size=UDim2.fromOffset(8,8),Rotation=10},Enum.EasingStyle.Quad)
        tween(windowScale,.34,{Scale=Library._scale},Enum.EasingStyle.Back)
        tween(root,.3,{Position=savedWindowPosition,Rotation=0,BackgroundTransparency=0},Enum.EasingStyle.Back)
        task.delay(.21,function() if orb.Parent and not minimized then orb.Visible=false; orb.Size=UDim2.fromOffset(58,58); orb.Rotation=0 end end)
    end
    function win:Toggle() if minimized then self:Restore() else self:Minimize() end end
    function win:SetTitle(v) title.Text=tostring(v or "") end
    function win:SetSubtitle(v) subtitle.Text=tostring(v or "") end
    function win:SelectTab(name)
        local target
        for _,tab in ipairs(self._tabs) do if tab.Name==name or tab._title==name then target=tab; break end end
        if not target or self._activeTab==target then return end
        tabTransitionId+=1
        local thisTransition=tabTransitionId
        local previous=self._activeTab
        for _,tab in ipairs(self._tabs) do
            local active=tab==target
            tween(tab._button,.18,{BackgroundColor3=active and theme().Hover or theme().Panel})
            if active then
                tab._indicator.Visible=true
                tab._indicator.Position=UDim2.fromOffset(-3,6)
                tween(tab._indicator,.24,{Position=UDim2.fromOffset(0,6)},Enum.EasingStyle.Back)
            else
                tab._indicator.Visible=false
            end
        end
        self._activeTab=target
        if Library._reducedMotion then
            for _,tab in ipairs(self._tabs) do tab._page.Visible=(tab==target); tab._page.Position=UDim2.fromOffset(0,0) end
            return
        end
        if previous and previous._page and previous._page.Visible then
            tween(previous._page,.16,{Position=UDim2.fromOffset(-12,3)},Enum.EasingStyle.Quad)
            task.delay(.16,function() if previous._page.Parent and tabTransitionId==thisTransition then previous._page.Visible=false; previous._page.Position=UDim2.fromOffset(0,0) end end)
        end
        target._page.Visible=true
        target._page.Position=UDim2.fromOffset(18,7)
        tween(target._page,.26,{Position=UDim2.fromOffset(0,0)},Enum.EasingStyle.Quart)
    end
    function win:Destroy()
        if self._closed then return end
        self._closed=true
        for i,v in ipairs(Library._windows) do if v==self then table.remove(Library._windows,i); break end end
        if Library._reducedMotion or not root.Parent then screen:Destroy(); return end
        local fadeInfo=TweenInfo.new(.22,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
        local fadeTweens={}
        for _,gui in ipairs(screen:GetDescendants()) do
            if gui:IsA("GuiObject") then
                local props={}
                pcall(function() props.BackgroundTransparency=1 end)
                if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then props.TextTransparency=1 end
                if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then props.ImageTransparency=1 end
                local ok=pcall(function() local tw=TweenService:Create(gui,fadeInfo,props); table.insert(fadeTweens,tw); tw:Play() end)
            elseif gui:IsA("UIStroke") then
                local tw=TweenService:Create(gui,fadeInfo,{Transparency=1}); table.insert(fadeTweens,tw); tw:Play()
            end
        end
        tween(root,.24,{Rotation=2,Position=root.Position+UDim2.fromOffset(0,12)},Enum.EasingStyle.Back,Enum.EasingDirection.In)
        tween(scale,.24,{Scale=Library._scale*.88},Enum.EasingStyle.Quart,Enum.EasingDirection.In)
        task.delay(.27,function() if screen.Parent then screen:Destroy() end end)
    end
    local function makePalette()
        if win._palette then win._palette:Destroy(); win._palette=nil; return end
        local overlay=make("Frame",{Name="CommandPalette",BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.35,Size=UDim2.fromScale(1,1),ZIndex=50},screen)
        local panel=make("Frame",{BackgroundColor3=theme().Panel,BorderSizePixel=0,Size=UDim2.new(1,-24,0,330),Position=UDim2.new(0,12,.5,-165),ZIndex=51},overlay)
        panel.Size=UDim2.new(0,math.min(430,math.max(280,screen.AbsoluteSize.X-24)),0,math.min(330,math.max(250,screen.AbsoluteSize.Y-40)))
        panel.Position=UDim2.new(.5,-panel.Size.X.Offset/2,.5,-panel.Size.Y.Offset/2)
        corner(panel,14); stroke(panel,theme().Border,.05)
        local search=make("TextBox",{PlaceholderText="Search commands and tabs…",Text="",ClearTextOnFocus=false,TextColor3=theme().Text,PlaceholderColor3=theme().Muted,Font=Enum.Font.Gotham,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=theme().Panel2,BorderSizePixel=0,Position=UDim2.fromOffset(12,12),Size=UDim2.new(1,-24,0,40),ZIndex=52},panel)
        corner(search,8); padding(search,10,10,0,0)
        local results=make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(12,62),Size=UDim2.new(1,-24,1,-74),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ZIndex=52},panel)
        listLayout(results,Enum.FillDirection.Vertical,4)
        local function rebuild()
            for _,c in ipairs(results:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            local q=string.lower(search.Text)
            local count=0
            for _,tab in ipairs(win._tabs) do
                if q=="" or string.find(string.lower(tab.Name),q,1,true) then
                    count+=1
                    local b=make("TextButton",{Text="   ◈   "..tab.Name,TextColor3=theme().Text,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=theme().Panel2,BorderSizePixel=0,Size=UDim2.new(1,0,0,34),ZIndex=53},results)
                    corner(b,7); b.MouseButton1Click:Connect(function() win:SelectTab(tab.Name); overlay:Destroy(); win._palette=nil end)
                end
            end
            for name,cmd in pairs(Library._commands) do
                if q=="" or string.find(name,q,1,true) or string.find(string.lower(cmd.Description or ""),q,1,true) then
                    count+=1
                    local b=make("TextButton",{Text="   ↳   "..cmd.Name,TextColor3=theme().Accent,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=theme().Panel2,BorderSizePixel=0,Size=UDim2.new(1,0,0,34),ZIndex=53},results)
                    corner(b,7); b.MouseButton1Click:Connect(function() invoke(cmd.Callback); overlay:Destroy(); win._palette=nil end)
                end
            end
            if count==0 then
                make("TextLabel",{Text="No results found",TextColor3=theme().Muted,TextSize=12,Font=Enum.Font.Gotham,BackgroundTransparency=1,Size=UDim2.new(1,0,0,35),ZIndex=53},results)
            end
        end
        search:GetPropertyChangedSignal("Text"):Connect(rebuild)
        search.FocusLost:Connect(function(enter) if enter then local first=results:FindFirstChildOfClass("TextButton"); if first then first:Activate() end end end)
        overlay.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 and input.Position.X < panel.AbsolutePosition.X then overlay:Destroy(); win._palette=nil end end)
        win._palette=overlay; rebuild(); search:CaptureFocus()
    end
    function win:OpenCommandPalette() makePalette() end
    minimize.MouseButton1Click:Connect(function() win:Minimize() end)
    close.MouseButton1Click:Connect(function() win:Destroy() end)
    orb.MouseButton1Click:Connect(function() win:Restore() end)
    local dragging,dragStart,startPos=false,nil,nil
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=root.Position
        end
    end)
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-dragStart
            root.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end))
    local orbDragging,orbStart,orbPos=false,nil,nil
    orb.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then orbDragging=true; orbStart=input.Position; orbPos=orb.Position end
    end)
    track(UserInputService.InputChanged:Connect(function(input)
        if orbDragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-orbStart
            orb.Position=UDim2.new(orbPos.X.Scale,orbPos.X.Offset+delta.X,orbPos.Y.Scale,orbPos.Y.Offset+delta.Y)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then orbDragging=false end
    end))
    track(UserInputService.InputBegan:Connect(function(input,processed)
        if not processed and input.KeyCode==Enum.KeyCode.RightControl then win:OpenCommandPalette() end
    end))
    local clockConn=RunService.Heartbeat:Connect(function()
        if clock.Parent then clock.Text=os.date("%H:%M:%S") end
    end)
    table.insert(Library._connections,clockConn)
    -- Keep the window usable on narrow phone screens while preserving the requested size on desktop.
    local camera=workspace.CurrentCamera
    local function fitViewport()
        if not camera or not root.Parent then return end
        local viewport=camera.ViewportSize
        local maxW=math.max(300,viewport.X-20)
        local maxH=math.max(260,viewport.Y-24)
        local requestedW=desiredSize.X.Offset>0 and desiredSize.X.Offset or viewport.X*desiredSize.X.Scale
        local requestedH=desiredSize.Y.Offset>0 and desiredSize.Y.Offset or viewport.Y*desiredSize.Y.Scale
        root.Size=UDim2.fromOffset(math.min(requestedW,maxW),math.min(requestedH,maxH))
    end
    if camera then
        fitViewport()
        track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitViewport))
    end

    local windowObject={}
    setmetatable(windowObject,{__index=win})
    function windowObject:CreateTab(opts)
        opts=cleanOptions(opts)
        local name=opts.Name or ("Tab "..tostring(#win._tabs+1))
        local navButton=make("TextButton",{Name=name,Text="",BackgroundColor3=theme().Panel,BorderSizePixel=0,Size=UDim2.new(1,0,0,40),AutoButtonColor=false},nav)
        corner(navButton,9)
        local indicator=make("Frame",{BackgroundColor3=theme().Accent,BorderSizePixel=0,Size=UDim2.new(0,3,1,-12),Position=UDim2.fromOffset(0,6),Visible=false},navButton); corner(indicator,2)
        local icon=textLabel(navButton,opts.Icon or "◈",15,theme().Accent,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
        icon.Position=UDim2.fromOffset(7,0); icon.Size=UDim2.fromOffset(28,40)
        local navLabel=textLabel(navButton,name,11,theme().Text,Enum.Font.GothamMedium)
        navLabel.Position=UDim2.fromOffset(39,0); navLabel.Size=UDim2.new(1,-45,1,0)
        local page=make("ScrollingFrame",{Name=name.."Page",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=theme().Accent,Visible=false},pages)
        padding(page,1,4,1,8); listLayout(page,Enum.FillDirection.Vertical,11)
        local tab={Name=name,_title=name,_button=navButton,_indicator=indicator,_page=page,_content=page,_window=windowObject}
        table.insert(win._tabs,tab)
        function tab:CreateSection(sectionOptions) return createSection(self,sectionOptions) end
        function tab:SetVisible(v) navButton.Visible=v; if not v and win._activeTab==self then for _,other in ipairs(win._tabs) do if other~=self and other._button.Visible then win:SelectTab(other.Name); break end end end end
        navButton.MouseButton1Click:Connect(function() win:SelectTab(name) end)
        if #win._tabs==1 then win:SelectTab(name) end
        return tab
    end
    return windowObject
end

function Library:Destroy()
    if self._destroyed then return end
    self._destroyed=true
    for _,win in ipairs(table.clone(self._windows)) do pcall(function() win:Destroy() end) end
    for _,connection in ipairs(self._connections) do pcall(function() connection:Disconnect() end) end
    table.clear(self._connections)
    for _,notification in ipairs(self._notifications) do pcall(function() notification:Destroy() end) end
    table.clear(self._notifications)
end

return Library
