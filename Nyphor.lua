local Nyphor = {}
Nyphor.__index = Nyphor

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

local SINGLETON_TAG = "__NYPHOR_UI_LIB_INSTANCE__"

local function getParentGui()

	local success, result = pcall(function()
		if gethui then return gethui() end
		if syn and syn.protect_gui then
			local gui = Instance.new("ScreenGui")
			syn.protect_gui(gui)
			return CoreGui
		end
		return CoreGui
	end)
	if success and result then return result end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local Util = {}

local function synchronizeProperties(a, b, prop)
	a:GetPropertyChangedSignal(prop):Connect(function()
		b[prop] = a[prop]
	end)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

function Util.Dragify(dragObject)
	local dragToggle, dragInput, dragStart, dragPos
	local dragInfo = TweenInfo.new(0.15)

	dragObject.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and not UserInputService:GetFocusedTextBox() then
			dragToggle = true
			dragStart = input.Position
			dragPos = dragObject.Position
			input:GetPropertyChangedSignal("UserInputState"):Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragToggle = false
				end
			end)
		end
	end)

	dragObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	local conn = UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragToggle then
			local delta = input.Position - dragStart
			local newPos = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale, dragPos.Y.Offset + delta.Y)
			TweenService:Create(dragObject, dragInfo, {Position = newPos}):Play()
		end
	end)

	dragObject.Destroying:Connect(function()
		conn:Disconnect()
	end)
end

function Util.Scrollify(scrollObject)
	scrollObject.ScrollingEnabled = false

	local scrollInput = scrollObject:Clone()

	for _, child in ipairs(scrollInput:GetChildren()) do
		child:Destroy()
	end
	scrollInput.AutomaticCanvasSize = Enum.AutomaticSize.None
	scrollInput.CanvasSize = UDim2.fromOffset(scrollObject.AbsoluteCanvasSize.X, scrollObject.AbsoluteCanvasSize.Y)
	scrollInput.BackgroundTransparency = 1
	scrollInput.ScrollBarImageTransparency = 1
	scrollInput.ZIndex = scrollObject.ZIndex + 1
	scrollInput.Name = "_smoothinputframe"
	scrollInput.ScrollingEnabled = true
	scrollInput.Parent = scrollObject.Parent

	synchronizeProperties(scrollObject, scrollInput, "Position")
	synchronizeProperties(scrollObject, scrollInput, "Size")
	synchronizeProperties(scrollObject, scrollInput, "Visible")

	scrollObject:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		scrollInput.CanvasSize = UDim2.fromOffset(scrollObject.AbsoluteCanvasSize.X, scrollObject.AbsoluteCanvasSize.Y)
	end)

	local thread = task.spawn(function()
		while scrollObject.Parent do
			local dt = task.wait()
			scrollObject.CanvasPosition = scrollObject.CanvasPosition:Lerp(
				scrollInput.CanvasPosition,
				TweenService:GetValue(math.pi * dt, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			)
		end
	end)

	scrollObject.Destroying:Connect(function()
		pcall(task.cancel, thread)
		if scrollInput then scrollInput:Destroy() end
	end)
end

function Util.Searchify(textObject, scrollObject)
	local function search()
		for _, value in ipairs(scrollObject:GetChildren()) do
			if value:IsA("GuiObject") then
				if textObject.Text == "" then
					value.Visible = true
				else
					value.Visible = string.match(string.lower(value.Name), string.lower(textObject.Text)) and true or false
				end
			end
		end
	end

	textObject:GetPropertyChangedSignal("Text"):Connect(search)
	scrollObject.ChildAdded:Connect(search)
	scrollObject.ChildRemoved:Connect(search)
	search()
end

function Util.Buttonify(GuiButton, settings)
	settings = settings or {}
	local Setting_EnableMask = settings.UseMask
	local Setting_Color = settings.EffectColor or Color3.fromRGB(255, 255, 255)
	local Setting_xoffset = settings["X-Offset"] or 0
	local Setting_yoffset = settings["Y-Offset"] or 0
	local Setting_Lifetime = settings.Lifetime or 0.5
	local Setting_Scale = settings.EffectScale or 250
	local Setting_RippleAlpha = settings.EffectTransparency or 0.5
	local Setting_SelectionAlpha = settings.SelectionTransparency or 0.8

	local Down = false
	local inset = GuiService.TopbarInset

	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
		inset = GuiService.TopbarInset
	end)

	local MaterialSelectedColor = Instance.new("Frame")
	MaterialSelectedColor.Name = "MaterialSelectedColor"
	MaterialSelectedColor.Size = UDim2.new(1, 0, 1, 0)
	MaterialSelectedColor.BorderSizePixel = 0
	MaterialSelectedColor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MaterialSelectedColor.BackgroundTransparency = 1
	MaterialSelectedColor.ZIndex = GuiButton.ZIndex
	MaterialSelectedColor.Visible = Setting_EnableMask and true or false
	MaterialSelectedColor.Parent = GuiButton

	local ColorTween = Instance.new("Frame")
	ColorTween.Visible = false
	ColorTween.Name = "ColorTween"
	ColorTween.Position = UDim2.new(1, 0, 0, 0)
	ColorTween.Parent = MaterialSelectedColor

	ColorTween:GetPropertyChangedSignal("Position"):Connect(function()
		MaterialSelectedColor.BackgroundTransparency = ColorTween.Position.X.Scale
	end)

	local RippleTweenGoal = {ImageTransparency = 1}

	local RippleMaskGroup = Instance.new("CanvasGroup")
	RippleMaskGroup.Name = "RippleMask"
	RippleMaskGroup.Size = UDim2.new(1, 0, 1, 0)
	RippleMaskGroup.BackgroundTransparency = 1
	RippleMaskGroup.Parent = GuiButton

	if GuiButton:FindFirstChildWhichIsA("UICorner") then
		local c1 = GuiButton:FindFirstChildWhichIsA("UICorner"):Clone()
		c1.Parent = MaterialSelectedColor
		local c2 = GuiButton:FindFirstChildWhichIsA("UICorner"):Clone()
		c2.Parent = RippleMaskGroup
	end

	local BindableEvent = Instance.new("BindableEvent")

	local function MakeRippleInMask(x, y)
		local img = Instance.new("ImageLabel")
		Instance.new("UIGradient", img)
		img.Name = "MaterialRipple"
		img.Position = UDim2.new(0, x + Setting_xoffset - GuiButton.AbsolutePosition.X, 0, y + Setting_yoffset - GuiButton.AbsolutePosition.Y - inset.Height)
		img.Size = UDim2.new(0, 0, 0, 0)
		img.BackgroundTransparency = 1
		img.Image = "rbxasset://textures/whiteCircle.png"
		img.ImageColor3 = Setting_Color
		img.ImageTransparency = Setting_RippleAlpha
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.ZIndex = GuiButton.ZIndex
		img.Parent = RippleMaskGroup
		img:TweenSize(UDim2.new(0, Setting_Scale, 0, Setting_Scale), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, Setting_Lifetime, true)
		TweenService:Create(img, TweenInfo.new(Setting_Lifetime), RippleTweenGoal):Play()
		task.delay(Setting_Lifetime, function() img:Destroy() end)
	end

	local function MakeRipple(x, y)
		local img = Instance.new("ImageLabel")
		img.Name = "MaterialRipple"
		img.Position = UDim2.new(0, x + Setting_xoffset - GuiButton.AbsolutePosition.X, 0, y + Setting_yoffset - GuiButton.AbsolutePosition.Y)
		img.Size = UDim2.new(0, 0, 0, 0)
		img.BackgroundTransparency = 1
		img.Image = "rbxasset://textures/whiteCircle.png"
		img.ImageColor3 = Setting_Color
		img.ImageTransparency = Setting_RippleAlpha
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.ZIndex = GuiButton.ZIndex - 1
		img.Parent = GuiButton
		img:TweenSizeAndPosition(UDim2.new(0, Setting_Scale, 0, Setting_Scale), UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, Setting_Lifetime, true)
		BindableEvent.Event:Connect(function()
			TweenService:Create(img, TweenInfo.new(Setting_Lifetime), RippleTweenGoal):Play()
			task.delay(Setting_Lifetime, function() img:Destroy() end)
		end)
	end

	GuiButton.MouseButton1Down:Connect(function(x, y)
		Down = true
		ColorTween:TweenPosition(UDim2.new(Setting_SelectionAlpha, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.75, true)
		if not Setting_EnableMask then
			MakeRipple(x, y)
		end
	end)

	GuiButton.MouseButton1Up:Connect(function(x, y)
		if Down then
			Down = false
			ColorTween:TweenPosition(UDim2.new(1, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.3, true)
			if Setting_EnableMask then
				MakeRippleInMask(x, y)
			end
		end
		BindableEvent:Fire()
	end)

	GuiButton.MouseEnter:Connect(function()
		TweenService:Create(GuiButton, TweenInfo.new(0.25), {TextTransparency = 0.3}):Play()
	end)

	GuiButton.MouseLeave:Connect(function()
		TweenService:Create(GuiButton, TweenInfo.new(0.25), {TextTransparency = 0.5}):Play()
		Down = false
		ColorTween:TweenPosition(UDim2.new(1, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.3, true)
		BindableEvent:Fire()
	end)
end

local NotifyManager = {}
NotifyManager.__index = NotifyManager

local FADE_IN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SLIDE_OUT_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local MOVE_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local PIXEL_LIFETIME = 0.7
local PIXEL_DRIFT_SPEED = 15
local PIXEL_EMISSION_RATE = 25
local MAX_NOTIFICATIONS = 5
local VERTICAL_SPACING = 8
local BOTTOM_PADDING = 10
local TEMPLATE_SIZE = Vector2.new(250, 70)

function NotifyManager.new(parent)
	local self = setmetatable({}, NotifyManager)
	self.Active = {}
	self.Container = Instance.new("Frame")
	self.Container.Name = "NotificationContainer"
	self.Container.BackgroundTransparency = 1
	self.Container.Size = UDim2.new(0, TEMPLATE_SIZE.X + 20, 1, 0)
	self.Container.Position = UDim2.fromScale(1, 1)
	self.Container.AnchorPoint = Vector2.new(1, 1)
	self.Container.Parent = parent
	return self
end

local function calculateYOffset(index)
	local totalBelow = (index - 1) * (TEMPLATE_SIZE.Y + VERTICAL_SPACING)
	return -(totalBelow + TEMPLATE_SIZE.Y + BOTTOM_PADDING)
end

function NotifyManager:_updatePositions()
	for i, data in ipairs(self.Active) do
		if data.Instance and data.Instance.Parent then
			local targetPos = UDim2.new(1, -TEMPLATE_SIZE.X - 10, 1, calculateYOffset(i))
			if data.PositionTween then data.PositionTween:Cancel() end
			data.PositionTween = TweenService:Create(data.Instance, MOVE_INFO, {Position = targetPos})
			data.PositionTween:Play()
		end
	end
end

function NotifyManager:_createPixel(originFrame)
	local pixel = Instance.new("Frame")
	pixel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	pixel.BackgroundTransparency = 0.8
	pixel.BorderSizePixel = 0
	pixel.Size = UDim2.new(0, 3, 0, 3)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 2)
	corner.Parent = pixel

	local originAbs = originFrame.AbsolutePosition
	local originSize = originFrame.AbsoluteSize
	local containerAbs = self.Container.AbsolutePosition
	local startX = originAbs.X + math.random() * originSize.X - containerAbs.X
	local startY = originAbs.Y - containerAbs.Y
	pixel.Position = UDim2.fromOffset(startX, startY)
	pixel.Parent = self.Container

	local driftX = (math.random() - 0.5) * 2 * PIXEL_DRIFT_SPEED * PIXEL_LIFETIME
	local driftY = math.random() * 0.5 * PIXEL_DRIFT_SPEED * PIXEL_LIFETIME

	TweenService:Create(pixel, TweenInfo.new(PIXEL_LIFETIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = UDim2.fromOffset(startX + driftX, startY + driftY)}):Play()
	TweenService:Create(pixel, TweenInfo.new(PIXEL_LIFETIME * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}):Play()

	task.delay(PIXEL_LIFETIME, function()
		if pixel and pixel.Parent then pixel:Destroy() end
	end)
end

function NotifyManager:_remove(data, skipAnim)
	if data.IsRemoving then return end
	data.IsRemoving = true

	if data.TimeTween then data.TimeTween:Cancel() end
	if data.FadeTween then data.FadeTween:Cancel() end
	if data.PositionTween then data.PositionTween:Cancel() end
	if data.PixelLoop then pcall(task.cancel, data.PixelLoop) end
	if data.ExpiryThread then pcall(task.cancel, data.ExpiryThread) end

	for i = #self.Active, 1, -1 do
		if self.Active[i] == data then
			table.remove(self.Active, i)
			break
		end
	end

	if skipAnim or not data.Instance or not data.Instance.Parent then
		if data.Instance then data.Instance:Destroy() end
		self:_updatePositions()
		return
	end

	local currentY = data.Instance.Position.Y.Offset
	local slideTween = TweenService:Create(data.Instance, SLIDE_OUT_INFO, {Position = UDim2.new(1, 10, 1, currentY)})
	slideTween.Completed:Connect(function()
		if data.Instance then data.Instance:Destroy() end
		self:_updatePositions()
	end)
	slideTween:Play()
end

function NotifyManager:Show(title, content, duration)
	duration = math.min(math.floor(duration or 5), 5)

	local notif = Instance.new("CanvasGroup")
	notif.Size = UDim2.fromOffset(TEMPLATE_SIZE.X, TEMPLATE_SIZE.Y)
	notif.BackgroundColor3 = Color3.fromRGB(0, 2, 25)
	notif.BorderSizePixel = 0
	notif.GroupTransparency = 1
	notif.Parent = self.Container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = notif

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 136, 255)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = notif

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, 10, 0, 6)
	titleLabel.Size = UDim2.new(1, -50, 0, 16)
	titleLabel.Font = Enum.Font.GothamMedium
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(0, 136, 255)
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = notif

	local contentLabel = Instance.new("TextLabel")
	contentLabel.Name = "Content"
	contentLabel.BackgroundTransparency = 1
	contentLabel.Position = UDim2.new(0, 10, 0, 24)
	contentLabel.Size = UDim2.new(1, -20, 0, 36)
	contentLabel.Font = Enum.Font.Gotham
	contentLabel.Text = content
	contentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	contentLabel.TextSize = 11
	contentLabel.TextXAlignment = Enum.TextXAlignment.Left
	contentLabel.TextYAlignment = Enum.TextYAlignment.Top
	contentLabel.TextWrapped = true
	contentLabel.Parent = notif

	local counter = Instance.new("TextLabel")
	counter.Name = "Counter"
	counter.BackgroundTransparency = 1
	counter.Position = UDim2.new(1, -30, 0, 6)
	counter.Size = UDim2.new(0, 20, 0, 16)
	counter.Font = Enum.Font.Gotham
	counter.Text = tostring(duration)
	counter.TextColor3 = Color3.fromRGB(0, 136, 255)
	counter.TextSize = 12
	counter.Parent = notif

	local timeBar = Instance.new("Frame")
	timeBar.Name = "Time"
	timeBar.BackgroundColor3 = Color3.fromRGB(0, 136, 255)
	timeBar.BorderSizePixel = 0
	timeBar.Position = UDim2.new(0, 0, 1, -2)
	timeBar.Size = UDim2.new(1, 0, 0, 2)
	timeBar.Parent = notif

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.BackgroundTransparency = 1
	closeBtn.Position = UDim2.new(1, -20, 0, 24)
	closeBtn.Size = UDim2.new(0, 16, 0, 16)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 11
	closeBtn.Parent = notif

	local initialPos = UDim2.new(1, -TEMPLATE_SIZE.X - 10, 1, calculateYOffset(#self.Active + 1))
	notif.Position = initialPos

	local data = {
		Instance = notif,
		IsRemoving = false,
	}

	table.insert(self.Active, 1, data)
	if #self.Active > MAX_NOTIFICATIONS then
		local oldest = table.remove(self.Active, #self.Active)
		if oldest then self:_remove(oldest, true) end
	end
	self:_updatePositions()

	data.FadeTween = TweenService:Create(notif, FADE_IN_INFO, {GroupTransparency = 0})
	data.FadeTween:Play()

	data.TimeTween = TweenService:Create(timeBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})
	data.TimeTween:Play()

	data.PixelLoop = task.spawn(function()
		while not data.IsRemoving and data.Instance and data.Instance.Parent do
			self:_createPixel(timeBar)
			task.wait(1 / PIXEL_EMISSION_RATE)
		end
	end)

	task.spawn(function()
		for i = duration, 1, -1 do
			if data.IsRemoving then break end
			counter.Text = tostring(i)
			task.wait(1)
		end
	end)

	closeBtn.MouseButton1Click:Connect(function()
		self:_remove(data, false)
	end)

	data.ExpiryThread = task.delay(duration, function()
		if not data.IsRemoving then
			self:_remove(data, false)
		end
	end)

	return data
end

local function buildUI(parent)

	local rm = Instance.new("ScreenGui")
	rm.Name = "Nyphor"
	rm.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	rm.ResetOnSpawn = false
	rm.IgnoreGuiInset = true
	rm.Parent = parent

	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	Main.BorderSizePixel = 0
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.Size = UDim2.fromOffset(0, 306)
	Main.Parent = rm

	local mainGradient = Instance.new("UIGradient")
	mainGradient.Color = ColorSequence.new(Color3.fromRGB(255, 116, 188))
	mainGradient.Parent = Main

	local PenumbraShadow = Instance.new("ImageLabel")
	PenumbraShadow.Name = "PenumbraShadow"
	PenumbraShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	PenumbraShadow.BackgroundTransparency = 1
	PenumbraShadow.BorderSizePixel = 0
	PenumbraShadow.Position = UDim2.fromScale(0.5, 0.5)
	PenumbraShadow.Size = UDim2.new(1, 18, 1, 18)
	PenumbraShadow.ZIndex = -1
	PenumbraShadow.Image = "rbxassetid://1316045217"
	PenumbraShadow.ImageColor3 = Color3.fromRGB(0, 136, 255)
	PenumbraShadow.ImageTransparency = 0.88
	PenumbraShadow.ScaleType = Enum.ScaleType.Slice
	PenumbraShadow.SliceCenter = Rect.new(10, 10, 118, 118)
	PenumbraShadow.Parent = Main

	local AmbientShadow = Instance.new("ImageLabel")
	AmbientShadow.Name = "AmbientShadow"
	AmbientShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	AmbientShadow.BackgroundTransparency = 1
	AmbientShadow.BorderSizePixel = 0
	AmbientShadow.Position = UDim2.fromScale(0.5, 0.5)
	AmbientShadow.Size = UDim2.new(1.015, 8, 1, 8)
	AmbientShadow.ZIndex = -1
	AmbientShadow.Image = "rbxassetid://1316045217"
	AmbientShadow.ImageColor3 = Color3.fromRGB(0, 136, 255)
	AmbientShadow.ImageTransparency = 0.8
	AmbientShadow.ScaleType = Enum.ScaleType.Slice
	AmbientShadow.SliceCenter = Rect.new(10, 10, 118, 118)
	AmbientShadow.Parent = Main

	local Pages = Instance.new("Frame")
	Pages.Name = "Pages"
	Pages.BackgroundTransparency = 1
	Pages.BorderSizePixel = 0
	Pages.ClipsDescendants = true
	Pages.Size = UDim2.new(1.007, 0, 1, 0)
	Pages.ZIndex = 2
	Pages.Parent = Main

	local pagesCorner = Instance.new("UICorner")
	pagesCorner.CornerRadius = UDim.new(0.025, 0)
	pagesCorner.Parent = Pages

	local function createPage(name, position)
		local page = Instance.new("Frame")
		page.Name = name
		page.BackgroundColor3 = Color3.fromRGB(0, 2, 25)
		page.BorderSizePixel = 0
		page.Position = position
		page.Size = UDim2.fromOffset(589, 306)
		page.ZIndex = 3
		page.Parent = Pages

		local pCorner = Instance.new("UICorner")
		pCorner.CornerRadius = UDim.new(0.025, 0)
		pCorner.Parent = page

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Position = UDim2.new(0.003, 0, 0, 0)
		title.Size = UDim2.fromOffset(73, 43)
		title.ZIndex = 4
		title.Font = Enum.Font.Gotham
		title.Text = "N Y P H O R"
		title.TextColor3 = Color3.fromRGB(0, 136, 255)
		title.TextSize = 12
		title.Parent = page

		local titleBtn = Instance.new("TextButton")
		titleBtn.Name = "Button"
		titleBtn.BackgroundTransparency = 1
		titleBtn.Position = UDim2.new(0.145, 0, 0.196, 0)
		titleBtn.Size = UDim2.fromOffset(81, 30)
		titleBtn.Text = ""
		titleBtn.Parent = title

		return page, title, titleBtn
	end

	local Home, HomeTitle, HomeTitleBtn = createPage("Home", UDim2.fromScale(0, 0))

	local welcomeLabel = Instance.new("TextLabel")
	welcomeLabel.Name = "Welcome"
	welcomeLabel.BackgroundTransparency = 1
	welcomeLabel.Position = UDim2.new(0.299, 0, 0.366, 0)
	welcomeLabel.Size = UDim2.fromOffset(231, 22)
	welcomeLabel.ZIndex = 4
	welcomeLabel.Font = Enum.Font.Michroma
	welcomeLabel.Text = "WELCOME TO NYPHOR, USER."
	welcomeLabel.TextColor3 = Color3.fromRGB(0, 136, 255)
	welcomeLabel.TextScaled = true
	welcomeLabel.TextWrapped = true
	welcomeLabel.Parent = Home

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Position = UDim2.new(0.276, 0, 0.458, 0)
	subtitleLabel.Size = UDim2.fromOffset(259, 24)
	subtitleLabel.ZIndex = 4
	subtitleLabel.Font = Enum.Font.Michroma
	subtitleLabel.Text = "NO PLAN. JUST MOVE."
	subtitleLabel.TextColor3 = Color3.fromRGB(0, 136, 255)
	subtitleLabel.TextScaled = true
	subtitleLabel.TextWrapped = true
	subtitleLabel.Parent = Home

	local rotatingLetters = {}
	local letterChars = {"N", "Y", "P", "H", "O", "R"}
	for i, char in ipairs(letterChars) do
		local letter = Instance.new("TextLabel")
		letter.Name = char .. "_" .. i
		letter.BackgroundTransparency = 1
		letter.Size = UDim2.fromOffset(31, 24)
		letter.ZIndex = 4
		letter.Font = Enum.Font.Nunito
		letter.Text = char
		letter.TextColor3 = Color3.fromRGB(0, 136, 255)
		letter.TextScaled = true
		letter.Parent = Home
		table.insert(rotatingLetters, letter)
	end

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.BackgroundTransparency = 1
	hintLabel.Position = UDim2.new(0.372, 0, 0.567, 0)
	hintLabel.Size = UDim2.fromOffset(146, 22)
	hintLabel.ZIndex = 4
	hintLabel.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium, Enum.FontStyle.Italic)
	hintLabel.Text = "Press NYPHOR for menu"
	hintLabel.TextColor3 = Color3.fromRGB(0, 136, 255)
	hintLabel.TextSize = 12
	hintLabel.Parent = Home

	local homeImage = Instance.new("ImageLabel")
	homeImage.BackgroundTransparency = 1
	homeImage.BorderSizePixel = 0
	homeImage.Position = UDim2.new(0.714, 0, 0, 0)
	homeImage.Size = UDim2.fromOffset(168, 304)
	homeImage.Image = "rbxassetid://122756529010235"
	homeImage.ImageColor3 = Color3.fromRGB(14, 0, 90)
	homeImage.Parent = Home

	local homeImgGradient = Instance.new("UIGradient")
	homeImgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(39, 39, 39)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
	})
	homeImgGradient.Rotation = 17
	homeImgGradient.Parent = homeImage

	local homeImgCorner = Instance.new("UICorner")
	homeImgCorner.CornerRadius = UDim.new(0.025, 0)
	homeImgCorner.Parent = homeImage

	local Executor = createPage("Executor", UDim2.fromScale(1, 0))

	local execTitle = Instance.new("TextLabel")
	execTitle.BackgroundTransparency = 1
	execTitle.Position = UDim2.new(0.276, 0, 0.05, 0)
	execTitle.Size = UDim2.fromOffset(259, 24)
	execTitle.ZIndex = 4
	execTitle.Font = Enum.Font.Michroma
	execTitle.Text = "C O D E   E D I T O R"
	execTitle.TextColor3 = Color3.fromRGB(0, 136, 255)
	execTitle.TextSize = 14
	execTitle.Parent = Executor

	local Source = Instance.new("TextBox")
	Source.Name = "Source"
	Source.BackgroundColor3 = Color3.fromRGB(0, 2, 25)
	Source.BorderSizePixel = 0
	Source.Position = UDim2.new(0.08, 0, 0.152, 0)
	Source.Size = UDim2.fromOffset(502, 212)
	Source.ZIndex = 4
	Source.ClearTextOnFocus = false
	Source.Font = Enum.Font.Code
	Source.MultiLine = true
	Source.PlaceholderColor3 = Color3.fromRGB(204, 204, 204)
	Source.Text = "print(\"Welcome to Nyphor!\")"
	Source.TextColor3 = Color3.fromRGB(255, 255, 255)
	Source.TextSize = 15
	Source.TextXAlignment = Enum.TextXAlignment.Left
	Source.TextYAlignment = Enum.TextYAlignment.Top
	Source.Parent = Executor

	local Lines = Instance.new("TextLabel")
	Lines.Name = "Lines"
	Lines.BackgroundColor3 = Color3.fromRGB(0, 2, 25)
	Lines.BorderSizePixel = 0
	Lines.ClipsDescendants = true
	Lines.Position = UDim2.new(0.023, 0, 0.152, 0)
	Lines.Size = UDim2.new(-0.032, 30, 0.692, 0)
	Lines.ZIndex = 4
	Lines.Font = Enum.Font.Code
	Lines.Text = "1"
	Lines.TextColor3 = Color3.fromRGB(0, 136, 255)
	Lines.TextSize = 15
	Lines.TextYAlignment = Enum.TextYAlignment.Top
	Lines.Parent = Executor

	local Execute = Instance.new("TextButton")
	Execute.Name = "Execute"
	Execute.BackgroundColor3 = Color3.fromRGB(0, 2, 25)
	Execute.BorderSizePixel = 0
	Execute.Position = UDim2.new(0, 9, 0.878, 0)
	Execute.Size = UDim2.fromOffset(150, 29)
	Execute.ZIndex = 4
	Execute.AutoButtonColor = false
	Execute.Font = Enum.Font.Michroma
	Execute.Text = "EXECUTE"
	Execute.TextColor3 = Color3.fromRGB(0, 136, 255)
	Execute.TextSize = 12
	Execute.Parent = Executor

	local execCorner = Instance.new("UICorner")
	execCorner.CornerRadius = UDim.new(0.025, 0)
	execCorner.Parent = Execute

	local Clear = Instance.new("TextButton")
	Clear.Name = "Clear"
	Clear.BackgroundColor3 = Color3.fromRGB(0, 2, 25)
	Clear.BorderSizePixel = 0
	Clear.Position = UDim2.new(-0.008, 168, 0.878, 0)
	Clear.Size = UDim2.fromOffset(150, 29)
	Clear.ZIndex = 4
	Clear.AutoButtonColor = false
	Clear.Font = Enum.Font.Gotham
	Clear.Text = "CLEAR"
	Clear.TextColor3 = Color3.fromRGB(0, 136, 255)
	Clear.TextSize = 12
	Clear.Parent = Executor

	local Scripts = createPage("Scripts", UDim2.fromScale(-1, 0))

	local Search = Instance.new("TextBox")
	Search.Name = "Search"
	Search.AnchorPoint = Vector2.new(1, 0)
	Search.BackgroundColor3 = Color3.fromRGB(0, 5, 65)
	Search.BorderSizePixel = 0
	Search.Position = UDim2.new(1, -10, 0, 7)
	Search.Size = UDim2.fromOffset(174, 32)
	Search.ZIndex = 4
	Search.Font = Enum.Font.Gotham
	Search.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
	Search.PlaceholderText = "  Search"
	Search.Text = ""
	Search.TextColor3 = Color3.fromRGB(255, 255, 255)
	Search.TextSize = 12
	Search.Parent = Scripts

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 1)
	searchCorner.Parent = Search

	local ScrollFrame = Instance.new("ScrollingFrame")
	ScrollFrame.Active = true
	ScrollFrame.BackgroundColor3 = Color3.fromRGB(0, 2, 25)
	ScrollFrame.BorderSizePixel = 0
	ScrollFrame.Position = UDim2.new(0, 0, 0.15, 0)
	ScrollFrame.Size = UDim2.fromOffset(589, 260)
	ScrollFrame.ZIndex = 4
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollFrame.ScrollBarThickness = 0
	ScrollFrame.Parent = Scripts

	local listLayout = Instance.new("UIListLayout")
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = ScrollFrame

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 5)
	listPadding.Parent = ScrollFrame

	local Settings = createPage("Settings", UDim2.fromScale(0, 1))

	local settingsTitle = Instance.new("TextLabel")
	settingsTitle.BackgroundTransparency = 1
	settingsTitle.Position = UDim2.new(0.4, 0, 0.17, 0)
	settingsTitle.Size = UDim2.fromOffset(105, 46)
	settingsTitle.ZIndex = 4
	settingsTitle.Font = Enum.Font.Michroma
	settingsTitle.Text = "S E T T I N G S"
	settingsTitle.TextColor3 = Color3.fromRGB(0, 136, 255)
	settingsTitle.TextSize = 14
	settingsTitle.Parent = Settings

	local settingsFrame = Instance.new("Frame")
	settingsFrame.BackgroundColor3 = Color3.fromRGB(0, 2, 25)
	settingsFrame.BorderSizePixel = 0
	settingsFrame.Position = UDim2.new(0.012, 0, 0.45, 0)
	settingsFrame.Size = UDim2.fromOffset(575, 145)
	settingsFrame.ZIndex = 4
	settingsFrame.Parent = Settings

	local Close = Instance.new("TextButton")
	Close.Name = "Close"
	Close.BackgroundColor3 = Color3.fromRGB(0, 5, 65)
	Close.BorderSizePixel = 0
	Close.Position = UDim2.new(0.003, 0, 0.5, 0)
	Close.Size = UDim2.fromOffset(574, 33)
	Close.AutoButtonColor = false
	Close.Font = Enum.Font.Michroma
	Close.Text = "Close UI"
	Close.TextColor3 = Color3.fromRGB(0, 136, 255)
	Close.TextSize = 15
	Close.Parent = settingsFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 1)
	closeCorner.Parent = Close

	local Credits = createPage("Credits", UDim2.fromScale(0, -1))

	local creditsTitle = Instance.new("TextLabel")
	creditsTitle.BackgroundTransparency = 1
	creditsTitle.Position = UDim2.new(0.4, 0, 0.17, 0)
	creditsTitle.Size = UDim2.fromOffset(105, 46)
	creditsTitle.ZIndex = 4
	creditsTitle.Font = Enum.Font.Michroma
	creditsTitle.Text = "C R E D I T S"
	creditsTitle.TextColor3 = Color3.fromRGB(0, 136, 255)
	creditsTitle.TextSize = 14
	creditsTitle.Parent = Credits

	local creditsContainer = Instance.new("Frame")
	creditsContainer.Name = "Container"
	creditsContainer.BackgroundTransparency = 1
	creditsContainer.Position = UDim2.new(0.05, 0, 0.35, 0)
	creditsContainer.Size = UDim2.fromOffset(380, 150)
	creditsContainer.ZIndex = 4
	creditsContainer.Parent = Credits

	local creditsLayout = Instance.new("UIListLayout")
	creditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	creditsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	creditsLayout.Padding = UDim.new(0, 4)
	creditsLayout.Parent = creditsContainer

	local credImage = Instance.new("ImageLabel")
	credImage.BackgroundTransparency = 1
	credImage.BorderSizePixel = 0
	credImage.Position = UDim2.new(0.714, 0, 0.007, 0)
	credImage.Size = UDim2.fromOffset(168, 304)
	credImage.Image = "rbxassetid://122756529010235"
	credImage.ImageColor3 = Color3.fromRGB(14, 0, 90)
	credImage.Parent = Credits

	local credImgGradient = Instance.new("UIGradient")
	credImgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(39, 39, 39)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
	})
	credImgGradient.Rotation = 17
	credImgGradient.Parent = credImage

	local credImgCorner = Instance.new("UICorner")
	credImgCorner.CornerRadius = UDim.new(0.025, 0)
	credImgCorner.Parent = credImage

	local MenuMask = Instance.new("Frame")
	MenuMask.Name = "Menu"
	MenuMask.BackgroundTransparency = 1
	MenuMask.BorderSizePixel = 0
	MenuMask.ClipsDescendants = true
	MenuMask.Size = UDim2.new(-0.114, 150, 1, 0)
	MenuMask.ZIndex = 2
	MenuMask.Parent = Main

	local menuMaskCorner = Instance.new("UICorner")
	menuMaskCorner.Parent = MenuMask

	local Menu = Instance.new("Frame")
	Menu.Name = "Menu"
	Menu.BackgroundColor3 = Color3.fromRGB(0, 2, 25)
	Menu.BorderSizePixel = 0
	Menu.ClipsDescendants = true
	Menu.Position = UDim2.fromScale(-1, 0)
	Menu.Size = UDim2.new(-0.786, 150, 1, 0)
	Menu.ZIndex = 8
	Menu.Parent = MenuMask

	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0.025, 0)
	menuCorner.Parent = Menu

	local menuTitle = Instance.new("TextLabel")
	menuTitle.Name = "Title"
	menuTitle.BackgroundTransparency = 1
	menuTitle.Position = UDim2.fromScale(-0.014, 0)
	menuTitle.Size = UDim2.fromOffset(76, 48)
	menuTitle.ZIndex = 8
	menuTitle.Font = Enum.Font.Gotham
	menuTitle.Text = "M E N U"
	menuTitle.TextColor3 = Color3.fromRGB(0, 136, 255)
	menuTitle.TextSize = 12
	menuTitle.Parent = Menu

	local menuTitleBtn = Instance.new("TextButton")
	menuTitleBtn.Name = "Button"
	menuTitleBtn.BackgroundTransparency = 1
	menuTitleBtn.Position = UDim2.new(0.145, 0, 0.196, 0)
	menuTitleBtn.Size = UDim2.fromOffset(64, 30)
	menuTitleBtn.Text = ""
	menuTitleBtn.Parent = menuTitle

	local menuButtons = {}
	local function createMenuButton(name, position)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.BackgroundTransparency = 1
		btn.Position = UDim2.new(0, 0, position, 0)
		btn.Size = UDim2.fromOffset(113, 33)
		btn.ZIndex = 8
		btn.Font = Enum.Font.GothamMedium
		btn.Text = "    " .. name
		btn.TextColor3 = Color3.fromRGB(204, 204, 204)
		btn.TextSize = 13
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = Menu
		table.insert(menuButtons, btn)
		return btn
	end

	local HomeBtn = createMenuButton("Home", 0.181)
	HomeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	local ExecutorBtn = createMenuButton("Executor", 0.288)
	local ScriptsBtn = createMenuButton("Scripts", 0.398)
	local CreditsBtn = createMenuButton("Credits", 0.504)
	local SettingsBtn = createMenuButton("Settings", 0.611)

	local Open = Instance.new("Frame")
	Open.Name = "Open"
	Open.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	Open.BorderSizePixel = 0
	Open.ClipsDescendants = true
	Open.Position = UDim2.new(0.009, 0, 0.92, 0)
	Open.Size = UDim2.fromScale(0.045, 0)
	Open.Visible = false
	Open.ZIndex = 2
	Open.Parent = rm

	local openCorner = Instance.new("UICorner")
	openCorner.CornerRadius = UDim.new(0, 4)
	openCorner.Parent = Open

	local OpenBtn = Instance.new("ImageButton")
	OpenBtn.Name = "Open"
	OpenBtn.BackgroundTransparency = 1
	OpenBtn.BorderSizePixel = 0
	OpenBtn.Size = UDim2.fromScale(1, 1)
	OpenBtn.Parent = Open

	local OpenLabel = Instance.new("TextLabel")
	OpenLabel.BackgroundTransparency = 1
	OpenLabel.Position = UDim2.new(0.212, 0, 0.284, 0)
	OpenLabel.Size = UDim2.fromOffset(125, 30)
	OpenLabel.Font = Enum.Font.SciFi
	OpenLabel.Text = "Open"
	OpenLabel.TextColor3 = Color3.fromRGB(0, 136, 255)
	OpenLabel.TextScaled = true
	OpenLabel.TextWrapped = true
	OpenLabel.Parent = Open

	return {
		ScreenGui = rm,
		Main = Main,
		Pages = Pages,
		Home = Home,
		Executor = Executor,
		Scripts = Scripts,
		Settings = Settings,
		Credits = Credits,
		Menu = Menu,
		MenuButtons = {Home = HomeBtn, Executor = ExecutorBtn, Scripts = ScriptsBtn, Credits = CreditsBtn, Settings = SettingsBtn},
		Open = Open,
		OpenBtn = OpenBtn,
		Source = Source,
		Lines = Lines,
		Execute = Execute,
		Clear = Clear,
		ScrollFrame = ScrollFrame,
		Search = Search,
		Close = Close,
		WelcomeLabel = welcomeLabel,
		SubtitleLabel = subtitleLabel,
		HintLabel = hintLabel,
		RotatingLetters = rotatingLetters,
		CreditsContainer = creditsContainer,
		MenuTitleBtn = menuTitleBtn,
		PageTitleBtns = {
			[Home] = HomeTitleBtn,
		},
	}
end

function Nyphor:Init(config)
	config = config or {}

	local parent = getParentGui()
	for _, gui in ipairs(parent:GetChildren()) do
		if gui:IsA("ScreenGui") and gui:FindFirstChild(SINGLETON_TAG) then
			gui:Destroy()
		end
	end

	local ui = buildUI(parent)

	local tag = Instance.new("BoolValue")
	tag.Name = SINGLETON_TAG
	tag.Parent = ui.ScreenGui

	if config.Welcome then
		ui.WelcomeLabel.Text = config.Welcome
	else
		ui.WelcomeLabel.Text = "WELCOME TO NYPHOR, " .. (LocalPlayer.Name):upper() .. "."
	end
	if config.Subtitle then ui.SubtitleLabel.Text = config.Subtitle end
	if config.Hint then ui.HintLabel.Text = config.Hint end

	local TRANSITIONS = {
		Home     = {Executor = "Right", Scripts = "Down",  Settings = "Left",  Credits = "Up"},
		Executor = {Credits = "Right", Home = "Left",      Scripts = "Down",  Settings = "Up"},
		Scripts  = {Executor = "Up",   Settings = "Right", Home = "Down",     Credits = "Left"},
		Settings = {Scripts = "Up",    Credits = "Right", Executor = "Down",  Home = "Left"},
		Credits  = {Settings = "Up",   Home = "Right",     Scripts = "Left",  Executor = "Down"},
	}

	local PAGE_TRANSITION_INFO = TweenInfo.new(2.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local MENU_SLIDE_INFO = TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local OFFSCREEN_LEFT = UDim2.fromScale(-1, 0)
	local OFFSCREEN_RIGHT = UDim2.fromScale(1, 0)
	local OFFSCREEN_TOP = UDim2.fromScale(0, -1)
	local OFFSCREEN_BOTTOM = UDim2.fromScale(0, 1)
	local CENTER = UDim2.fromScale(0, 0)

	local currentPage = ui.Home

	local function transitionTo(targetPage)
		if currentPage == targetPage then return end

		local direction = "Left"
		if TRANSITIONS[currentPage.Name] and TRANSITIONS[currentPage.Name][targetPage.Name] then
			direction = TRANSITIONS[currentPage.Name][targetPage.Name]
		end

		local outEnd, inStart
		if direction == "Up" then
			outEnd, inStart = OFFSCREEN_TOP, OFFSCREEN_BOTTOM
		elseif direction == "Down" then
			outEnd, inStart = OFFSCREEN_BOTTOM, OFFSCREEN_TOP
		elseif direction == "Left" then
			outEnd, inStart = OFFSCREEN_LEFT, OFFSCREEN_RIGHT
		elseif direction == "Right" then
			outEnd, inStart = OFFSCREEN_RIGHT, OFFSCREEN_LEFT
		end

		for _, p in ipairs(ui.Pages:GetChildren()) do
			if p:IsA("Frame") and p ~= currentPage and p ~= targetPage then
				p.Position = OFFSCREEN_TOP
			end
		end

		targetPage.Position = inStart

		TweenService:Create(currentPage, PAGE_TRANSITION_INFO, {Position = outEnd}):Play()
		TweenService:Create(targetPage, PAGE_TRANSITION_INFO, {Position = CENTER}):Play()

		currentPage = targetPage

		for name, btn in pairs(ui.MenuButtons) do
			if name == targetPage.Name then
				TweenService:Create(btn, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			else
				TweenService:Create(btn, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(204, 204, 204)}):Play()
			end
		end
	end

	ui.MenuTitleBtn.MouseButton1Down:Connect(function()
		local target = (ui.Menu.Position.X.Scale < -0.5) and CENTER or OFFSCREEN_LEFT
		TweenService:Create(ui.Menu, MENU_SLIDE_INFO, {Position = target}):Play()
	end)

	for _, page in ipairs(ui.Pages:GetChildren()) do
		if page:IsA("Frame") then
			local titleBar = page:FindFirstChild("Title")
			if titleBar then
				local btn = titleBar:FindFirstChild("Button")
				if btn and btn:IsA("TextButton") then
					btn.MouseButton1Down:Connect(function()
						TweenService:Create(ui.Menu, MENU_SLIDE_INFO, {Position = CENTER}):Play()
					end)
				end
			end
		end
	end

	for name, btn in pairs(ui.MenuButtons) do
		btn.MouseButton1Down:Connect(function()
			TweenService:Create(ui.Menu, MENU_SLIDE_INFO, {Position = OFFSCREEN_LEFT}):Play()
			local targetPage = ui.Pages:FindFirstChild(name)
			if targetPage then transitionTo(targetPage) end
		end)
		btn.MouseEnter:Connect(function()
			if currentPage.Name ~= name then
				TweenService:Create(btn, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if currentPage.Name ~= name then
				TweenService:Create(btn, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(204, 204, 204)}):Play()
			end
		end)
	end

	local rotatingConn
	rotatingConn = RunService.RenderStepped:Connect(function()
		if not ui.Home.Parent then
			rotatingConn:Disconnect()
			return
		end
		local center = Vector2.new(ui.Home.AbsoluteSize.X / 2, ui.Home.AbsoluteSize.Y / 2)
		local radius = 100
		local speed = 0.25
		local t = tick() * speed
		local count = #ui.RotatingLetters
		for i, label in ipairs(ui.RotatingLetters) do
			local angle = t + ((2 * math.pi) / count) * (i - 1)
			local x = math.cos(angle) * radius
			local y = math.sin(angle) * radius
			label.Position = UDim2.new(0, center.X + x - label.AbsoluteSize.X / 2, 0, center.Y + y - label.AbsoluteSize.Y / 2)
		end
	end)

	local lua_keywords = {"and","break","do","else","elseif","end","false","for","function","goto","if","in","local","nil","not","or","repeat","return","then","true","until","while"}
	local function updateLines()
		local text = ui.Source.Text
		text = text:gsub("\13", ""):gsub("\t", "      ")
		ui.Source.Text = text
		local lineCount = 1
		text:gsub("\n", function() lineCount = lineCount + 1 end)
		local lines = ""
		for i = 1, lineCount do lines = lines .. i .. "\n" end
		ui.Lines.Text = lines
	end
	ui.Source:GetPropertyChangedSignal("Text"):Connect(updateLines)
	updateLines()

	Util.Dragify(ui.Main)
	Util.Scrollify(ui.ScrollFrame)
	Util.Searchify(ui.Search, ui.ScrollFrame)

	local rippleSettings = {
		EffectColor = Color3.fromRGB(255, 255, 255),
		EffectScale = 250,
		EffectTransparency = 0.5,
		Lifetime = 0.5,
		["X-Offset"] = 0,
		["Y-Offset"] = 0,
		SelectionTransparency = 0.8,
		UseMask = true,
	}
	Util.Buttonify(ui.Execute, rippleSettings)
	Util.Buttonify(ui.Clear, rippleSettings)
	Util.Buttonify(ui.Close, rippleSettings)
	Util.Buttonify(ui.OpenBtn, rippleSettings)

	ui.ScrollFrame.ChildAdded:Connect(function(child)
		if child:IsA("GuiButton") then
			Util.Buttonify(child, rippleSettings)
		end
	end)

	ui.Clear.MouseButton1Down:Connect(function()
		ui.Source.Text = ""
	end)

	local notifyMgr = NotifyManager.new(ui.ScreenGui)

	local instance = setmetatable({
		_ui = ui,
		_notifyMgr = notifyMgr,
		_executeCallback = nil,
		_scripts = {},
		_credits = {},
		_visible = true,
	}, Nyphor)

	ui.Close.MouseButton1Down:Connect(function()
		ui.Main:TweenSize(UDim2.fromOffset(0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 1, true, function(state)
			if state == Enum.TweenStatus.Completed then
				ui.Main.Visible = false
				ui.Open.Visible = true
				ui.Open:TweenSize(UDim2.new(0.12, 0, 0.07, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 1)
			end
		end)
		instance._visible = false
	end)

	ui.OpenBtn.MouseButton1Down:Connect(function()
		ui.Open:TweenSize(UDim2.new(0.045, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.5, true, function(state)
			if state == Enum.TweenStatus.Completed then
				ui.Open.Visible = false
				ui.Main.Visible = true
				ui.Main:TweenSize(UDim2.fromOffset(580, 306), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 1)
			end
		end)
		instance._visible = true
	end)

	ui.Execute.MouseButton1Down:Connect(function()
		if instance._executeCallback then
			local source = ui.Source.Text
			local ok, err = pcall(instance._executeCallback, source)
			if not ok then
				notifyMgr:Show("Execution Error", tostring(err), 5)
			end
		else

			local source = ui.Source.Text
			local func, err = loadstring(source)
			if not func then
				notifyMgr:Show("Compile Error", tostring(err), 5)
				return
			end
			local ok, runErr = pcall(func)
			if not ok then
				notifyMgr:Show("Runtime Error", tostring(runErr), 5)
			else
				notifyMgr:Show("Executed", "Script ran successfully.", 3)
			end
		end
	end)

	task.spawn(function()
		task.wait(0.3)
		ui.Main:TweenSize(UDim2.fromOffset(589, 306), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 2.0, true)
	end)

	return instance
end

function Nyphor:AddScript(name, callback)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.BackgroundColor3 = Color3.fromRGB(0, 5, 65)
	btn.BorderSizePixel = 0
	btn.Size = UDim2.fromOffset(578, 37)
	btn.ZIndex = self._ui.ScrollFrame.ZIndex + 1
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.Gotham
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 12
	btn.TextTransparency = 0.5
	btn.Parent = self._ui.ScrollFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 1)
	corner.Parent = btn

	btn.MouseButton1Down:Connect(function()
		if callback then
			local ok, err = pcall(callback)
			if not ok then
				self._notifyMgr:Show("Script Error", tostring(err), 5)
			end
		end
	end)

	table.insert(self._scripts, {Name = name, Button = btn, Callback = callback})
	return btn
end

function Nyphor:RemoveScript(name)
	for i, entry in ipairs(self._scripts) do
		if entry.Name == name then
			if entry.Button then entry.Button:Destroy() end
			table.remove(self._scripts, i)
			return true
		end
	end
	return false
end

function Nyphor:ClearScripts()
	for _, entry in ipairs(self._scripts) do
		if entry.Button then entry.Button:Destroy() end
	end
	self._scripts = {}
end

function Nyphor:AddCredit(text)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromOffset(380, 22)
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(0, 136, 255)
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 4
	label.Parent = self._ui.CreditsContainer

	table.insert(self._credits, label)
	return label
end

function Nyphor:Notify(title, content, duration)
	return self._notifyMgr:Show(title or "Notification", content or "", duration or 3)
end

function Nyphor:OnExecute(callback)
	self._executeCallback = callback
end

function Nyphor:Show()
	if self._visible then return end
	self._ui.Open.Visible = false
	self._ui.Main.Visible = true
	self._ui.Main:TweenSize(UDim2.fromOffset(589, 306), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 1)
	self._visible = true
end

function Nyphor:Hide()
	if not self._visible then return end
	self._ui.Main:TweenSize(UDim2.fromOffset(0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 1, true, function(state)
		if state == Enum.TweenStatus.Completed then
			self._ui.Main.Visible = false
			self._ui.Open.Visible = true
			self._ui.Open:TweenSize(UDim2.new(0.12, 0, 0.07, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 1)
		end
	end)
	self._visible = false
end

function Nyphor:Toggle()
	if self._visible then self:Hide() else self:Show() end
end

function Nyphor:SetWelcome(text)
	self._ui.WelcomeLabel.Text = text
end

function Nyphor:SetSubtitle(text)
	self._ui.SubtitleLabel.Text = text
end

function Nyphor:Destroy()
	if self._ui and self._ui.ScreenGui then
		self._ui.ScreenGui:Destroy()
	end
end

return Nyphor
