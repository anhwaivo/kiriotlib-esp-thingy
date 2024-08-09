--[[ 
Written by Kiriot22
Modifications made by wally and me yes
So much skidded code and random tab style
Best esp lib
If you plan to use this thing then keep the credit!
]]
-- Settings
local ESP = {
	-- flags
	Enabled = false,
	Players = true,

	-- components
	Names = false,
	Boxes = false,
	Tracers = false,
	Health = false,
	
	-- options
	FaceCamera = false,
	TeamColor = false,
	TeamMates = false,

	Font = 'UI',
	TextSize = 19,

	BoxShift = CFrame.new(0, -1.5, 0),
	BoxSize = Vector3.new(4, 6, 0),
	Color = Color3.fromRGB(255, 170, 0),
	HealthOffsetX = 4,
	HealthOffsetY = -2,
	ChamsTransparency = .5,
	ChamsOutlineTransparency = 0,
	ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
	UsePlrDistance = false,
	MaxPlrDistance = math.huge,

	Thickness = 2,
	AttachShift = 1,

	Objects = setmetatable({}, { __mode = "kv" }),
	Overrides = {},

	IgnoreHumanoids = false,
}

--Declarations--
local cam = workspace.CurrentCamera
local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local mouse = plr:GetMouse()
local V3new = Vector3.new
local WorldToViewportPoint = cam.WorldToViewportPoint
local PointToObjectSpace = CFrame.new().PointToObjectSpace
local Cross = Vector3.new().Cross
local Folder = Instance.new("Folder", game.CoreGui)
local chars = {}
local CharTable, Health = nil, nil
for _, v in pairs(getgc(true)) do
	if type(v) == "function" then
		if debug.getinfo(v).name == "getbodyparts" then
			CharTable = debug.getupvalue(v, 1)
        end
	end
    if type(v) == "table" then
        if rawget(v, "getplayerhealth") then
            Health = v
        end
    end
	if CharTable and Health then
		break
	end
end

task.spawn(function()
    while wait(1) do
        plrtable = {}
        for i,v in pairs(plrs:GetChildren()) do
            table.insert(plrtable, v)
        end
    end
end)

--Functions--
function ApplyModel(model)
    if not model:FindFirstChild("Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Parent = model.Character
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
    end
function ApplyPlayer(model)
    if not model:FindFirstChild("Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Parent = model
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
end
function BrahWth(position)
	local screenPosition, onScreen = WorldToViewportPoint(cam, position)
	return Vector2.new(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z
end

local function round(number)
	if (typeof(number) == "Vector2") then
		return Vector2.new(round(number.X), round(number.Y))
	else
		return math.floor(number)
	end
end

function GetBoundingBox(torso)
	local torsoPosition, onScreen, depth = BrahWth(torso.Position)
	local scaleFactor = 1 / (math.tan(math.rad(cam.FieldOfView * .5)) * 2 * depth) * 1e3
	local size = round(Vector2.new(4 * scaleFactor, 5 * scaleFactor))
	return onScreen, size, round(Vector2.new(torsoPosition.X - (size.X * .5), torsoPosition.Y - (size.Y * .5))), torsoPosition
end

local function Draw(obj, props)
	local new = Drawing.new(obj)
	
	props = props or {}
	for i,v in pairs(props) do
		new[i] = v
	end
	return new
end

ESP.Draw = Draw

function ESP:GetTeam(p)
	local ov = self.Overrides.GetTeam
	if ov then
		return ov(p)
	end
	
	return p and p.Team
end

function ESP:IsTeamMate(p)
	local ov = self.Overrides.IsTeamMate
	if ov then
		return ov(p)
	end
	
	return self:GetTeam(p) == self:GetTeam(plr)
end

function ESP:GetColor(obj)
	local ov = self.Overrides.GetColor
	if ov then
		return ov(obj)
	end
	local p = self:GetPlrFromChar(obj)
	return p and self.TeamColor and p.Team and p.Team.TeamColor.Color or self.Color
end

function ESP:GetPlrFromChar(char)
	local ov = self.Overrides.GetPlrFromChar
	if ov then
		return ov(char)
	end
	
	return plrs:GetPlayerFromCharacter(char)
end

function ESP:Toggle(bool)
	self.Enabled = bool
	if not bool then
		for i,v in pairs(self.Objects) do
			if v.Type == "Box" then --fov circle etc
				if v.Temporary then
					v:Remove()
				else
					for i,v in pairs(v.Components) do
						v.Visible = false
					end
				end
			end
		end
	end
end

function ESP:GetBox(obj)
	return self.Objects[obj]
end

function ESP:AddObjectListener(parent, options)
	local function NewListener(c)
		if type(options.Type) == "string" and c:IsA(options.Type) or options.Type == nil then
			if type(options.Name) == "string" and c.Name == options.Name or options.Name == nil then
				if not options.Validator or options.Validator(c) then
					local box = ESP:Add(c, {
						PrimaryPart = type(options.PrimaryPart) == "string" and c:WaitForChild(options.PrimaryPart) or type(options.PrimaryPart) == "function" and options.PrimaryPart(c),
						Color = type(options.Color) == "function" and options.Color(c) or options.Color,
						ColorDynamic = options.ColorDynamic,
						Name = type(options.CustomName) == "function" and options.CustomName(c) or options.CustomName,
						IsEnabled = options.IsEnabled,
						RenderInNil = options.RenderInNil
					})
					--TODO: add a better way of passing options
					if options.OnAdded then
						coroutine.wrap(options.OnAdded)(box)
					end
				end
			end
		end
	end

	if options.Recursive then
		parent.DescendantAdded:Connect(NewListener)
		for i,v in pairs(parent:GetDescendants()) do
			coroutine.wrap(NewListener)(v)
		end
	else
		parent.ChildAdded:Connect(NewListener)
		for i,v in pairs(parent:GetChildren()) do
			coroutine.wrap(NewListener)(v)
		end
	end
end

local boxBase = {}
boxBase.__index = boxBase

function boxBase:Remove()
	ESP.Objects[self.Object] = nil
	for i,v in pairs(self.Components) do
		v.Visible = false
		v:Remove()
		self.Components[i] = nil
	end
end

function boxBase:Update()
	if not self.PrimaryPart then
		--warn("not supposed to print", self.Object)
		return self:Remove()
	end

	local color
	if ESP.Highlighted == self.Object then
	   color = ESP.HighlightColor
	else
		color = self.Color or self.ColorDynamic and self:ColorDynamic() or ESP:GetColor(self.Object) or ESP.Color
	end

	local allow = true
	if ESP.Overrides.UpdateAllow and not ESP.Overrides.UpdateAllow(self) then
		allow = false
	end
	if self.Player and not ESP.TeamMates and ESP:IsTeamMate(self.Player) then
		allow = false
	end
	if self.Player and not ESP.Players then
		allow = false
	end
	if self.IsEnabled and (type(self.IsEnabled) == "string" and not ESP[self.IsEnabled] or type(self.IsEnabled) == "function" and not self:IsEnabled()) then
		allow = false
	end
	if not workspace:IsAncestorOf(self.PrimaryPart) and not self.RenderInNil then
		allow = false
	end

	if not allow then
		for i,v in pairs(self.Components) do
			v.Visible = false
		end
		return
	end

	if ESP.Highlighted == self.Object then
		color = ESP.HighlightColor
	end

	local IsPlrHighlighted = (ESP.Highlighted == self.Object and self.Player ~= nil)

	--calculations--
	local cf = self.PrimaryPart.CFrame
	if ESP.FaceCamera then
		cf = CFrame.new(cf.p, cam.CFrame.p)
	end

	local distance = math.floor((cam.CFrame.p - cf.p).magnitude)
	if self.Player and ESP.UsePlrDistance and distance > ESP.MaxPlrDistance then
		for i,v in pairs(self.Components) do
			v.Visible = false
		end
		return
	end

	self.Distance = distance;
	local size = self.Size
	local locs = {
		TopLeft 	= cf * ESP.BoxShift * CFrame.new(size.X   / 2,  size.Y / 2, 0),
		TopRight 	= cf * ESP.BoxShift * CFrame.new(-size.X  / 2,  size.Y / 2, 0),
		BottomLeft 	= cf * ESP.BoxShift * CFrame.new(size.X   / 2, -size.Y / 2, 0),
		BottomRight = cf * ESP.BoxShift * CFrame.new(-size.X  / 2, -size.Y / 2, 0),
		TagPos 		= cf * ESP.BoxShift * CFrame.new(0,			 	size.Y / 2, 0),
		Torso 		= cf * ESP.BoxShift
	}

	if ESP.Boxes then
		local TopLeft, Vis1 = WorldToViewportPoint(cam, locs.TopLeft.p)
		local TopRight, Vis2 = WorldToViewportPoint(cam, locs.TopRight.p)
		local BottomLeft, Vis3 = WorldToViewportPoint(cam, locs.BottomLeft.p)
		local BottomRight, Vis4 = WorldToViewportPoint(cam, locs.BottomRight.p)

		if self.Components.Quad then
			if Vis1 or Vis2 or Vis3 or Vis4 then
				self.Components.Quad.Visible = true
				self.Components.Quad.PointA = Vector2.new(TopRight.X, TopRight.Y)
				self.Components.Quad.PointB = Vector2.new(TopLeft.X, TopLeft.Y)
				self.Components.Quad.PointC = Vector2.new(BottomLeft.X, BottomLeft.Y)
				self.Components.Quad.PointD = Vector2.new(BottomRight.X, BottomRight.Y)
				self.Components.Quad.Color = color

				self.Components.Quad.ZIndex = IsPlrHighlighted and 2 or 1
			else
				self.Components.Quad.Visible = false
			end
		end
	else
		self.Components.Quad.Visible = false
	end

	if ESP.Names then
		local TagPos, Vis5 = WorldToViewportPoint(cam, locs.TagPos.p)
		
		if Vis5 then
			self.Components.Name.Visible = true
			self.Components.Name.Position = Vector2.new(TagPos.X, TagPos.Y)
			self.Components.Name.Text = self.Name
			self.Components.Name.Color = color
			


			self.Components['Name'].Size = ESP.FontSize

			self.Components['Name'].ZIndex = IsPlrHighlighted and 2 or 1

			if Drawing.Fonts and Drawing.Fonts[ESP.Font] then
				self.Components['Name'].Font = Drawing.Fonts[ESP.Font]
			end
		else
			self.Components.Name.Visible = false
		end
	else
		self.Components.Name.Visible = false
	end
	
	if ESP.Distance then
		local TagPos, Vis5 = WorldToViewportPoint(cam, locs.TagPos.p)
		
		if Vis5 then
            		self.Components.Distance.Visible = true
			self.Components.Distance.Position = Vector2.new(TagPos.X, TagPos.Y + 14)
			self.Components.Distance.Text = distance .." studs away"
			self.Components.Distance.Color = color
            		self.Components['Distance'].Size = ESP.FontSize
            		self.Components['Distance'].ZIndex = IsPlrHighlighted and 2 or 1
        		if Drawing.Fonts and Drawing.Fonts[ESP.Font] then
				self.Components['Distance'].Font = Drawing.Fonts[ESP.Font]
			end
		else
			self.Components.Distance.Visible = false
		end
	else
		self.Components.Distance.Visible = false
	end
	
	if ESP.Tracers then
		local TorsoPos, Vis6 = WorldToViewportPoint(cam, locs.Torso.p)
		if Vis6 then
			self.Components.Tracer.Visible = true
			self.Components.Tracer.From = Vector2.new(TorsoPos.X, TorsoPos.Y)
			self.Components.Tracer.To = Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/ESP.AttachShift)
			self.Components.Tracer.Color = color
			self.Components['Tracer'].ZIndex = IsPlrHighlighted and 2 or 1
		else
			self.Components.Tracer.Visible = false
		end
	else
		self.Components.Tracer.Visible = false
	end

    if ESP.Chams then
		--[[local TorsoPos, Vis12 = WorldToViewportPoint(cam, locs.Torso.p)
		if Vis12 then
			self.Components.Highlight.Enabled = true
			self.Components.Highlight.FillColor = color
			self.Components.Highlight.FillTransparency = ESP.ChamsTransparency
			self.Components.Highlight.OutlineTransparency = ESP.ChamsOutlineTransparency
			self.Components.Highlight.OutlineColor = ESP.ChamsOutlineColor
		else
			self.Components.Highlight.Enabled = false
		end
	else
		self.Components.Highlight.Enabled = false
	end]]
	
	-- this 1 is buggy but works
	for _, Player in next, game:GetService("Players"):GetChildren() do
            ApplyModel(Player) wait()
        end
        for i,v in pairs(game:GetService("Players"):GetChildren()) do
            CharacterAddedConnection = v.CharacterAdded:Connect(function(character)
                ApplyPlayer(character)
            end)
        end
    else
        for _, Player in next, plrs:GetChildren() do
            if Player.Character:FindFirstChild("Highlight") then
                Player.Character:FindFirstChild("Highlight"):Destroy()
            end
        end
        for i,v in pairs(workspace:GetDescendants()) do
            if table.find(plrtable, v.Name) then
                if v:FindFirstChild("Highlight") then v:FindFirstChild("Highlight"):Destroy() end
            end
        end
        CharacterAddedConnection:Disconnect()
    end
    end

	if ESP.Health then 
	--[[	local onScreen, size, position = GetBoundingBox(locs.Torso)
		if onScreen and size and position then
			if self.Player then
                local Health, MaxHealth = Health:getplayerhealth(self.Player)
				local healthBarSize = round(Vector2.new(1, -(size.Y * (Health / MaxHealth))))
				local healthBarPosition = round(Vector2.new(position.X - (3 + healthBarSize.X), position.Y + size.Y))
				local g = Color3.fromRGB(0, 255, 8)
				local r = Color3.fromRGB(255, 0, 0)
				self.Components.HealthBar.Visible = true
				self.Components.HealthBar.Color = r:lerp(g, Health / MaxHealth)
				self.Components.HealthBar.Transparency = 1
				self.Components.HealthBar.Size = healthBarSize
				self.Components.HealthBar.Position = healthBarPosition
				self.Components.HealthBarOutline.Visible = true
				self.Components.HealthBarOutline.Transparency = 1
				self.Components.HealthBarOutline.Size = round(Vector2.new(healthBarSize.X, -size.Y) + Vector2.new(2, -2))
				self.Components.HealthBarOutline.Position = healthBarPosition - Vector2.new(1, -1)

			end
		else
			self.Components.HealthBar.Visible = false
			self.Components.HealthBarOutline.Visible = false
		end
	else
		self.Components.HealthBar.Visible = false
		self.Components.HealthBarOutline.Visible = false
	end ]]
end

function ESP:Add(obj, options)
	if not obj.Parent and not options.RenderInNil then
		return warn(obj, "has no parent")
	end

	local box = setmetatable({
		Name = options.Name or obj.Name,
		Type = "Box",
		Color = options.Color --[[or self:GetColor(obj)]],
		Size = options.Size or self.BoxSize,
		Object = obj,
		Player = options.Player or plrs:GetPlayerFromCharacter(obj),
		PrimaryPart = options.PrimaryPart or obj.ClassName == "Model" and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj:IsA("BasePart") and obj,
		Components = {},
		IsEnabled = options.IsEnabled,
		Temporary = options.Temporary,
		ColorDynamic = options.ColorDynamic,
		RenderInNil = options.RenderInNil
	}, boxBase)

	if self:GetBox(obj) then
		self:GetBox(obj):Remove()
	end

	box.Components["Quad"] = Draw("Quad", {
		Thickness = self.Thickness,
		Color = color,
		Transparency = 1,
		Filled = false,
		Visible = self.Enabled and self.Boxes
	})

	box.Components["Name"] = Draw("Text", {
		Text = box.Name,
		Color = box.Color,
		Center = true,
		Outline = true,
		Size = self.TextSize,
		Visible = self.Enabled and self.Names
	})

	box.Components["Distance"] = Draw("Text", {
		Color = box.Color,
		Center = true,
		Outline = true,
		Size = self.TextSize,
		Visible = self.Enabled and self.Names
	})
	
	box.Components["Tracer"] = Draw("Line", {
		Thickness = ESP.Thickness,
		Color = box.Color,
		Transparency = 1,
		Visible = self.Enabled and self.Tracers
	})
	
	box.Components["HealthBarOutline"] = Draw("Square", {
		Transparency = 1,
		Thickness = 1,
		Filled = true,
		Visible = self.Enabled and self.Health
	})
	box.Components["HealthBar"] = Draw("Square", {
		Transparency = 1,
		Thickness = 1,
		Visible = self.Enabled and self.Health
	})
-- for the not working chams :/ but ill keep it here
--[[
	local h = Instance.new("Highlight")
	h.Enabled = ESP.Chams
	h.FillTransparency = .35
	h.OutlineTransparency = .35
	h.FillColor = ESP.Color
	h.OutlineColor = ESP.ChamsOutlineColor
	h.DepthMode = 0
	h.Name = GenerateName(x)
	h.Parent = Folder
	h.Adornee = obj
	box.Components["Highlight"] = h 
]]
	self.Objects[obj] = box
	obj.AncestryChanged:Connect(function(_, parent)
		if parent == nil and ESP.AutoRemove ~= false then
			box:Remove()
		end
	end)
	obj:GetPropertyChangedSignal("Parent"):Connect(function()
		if obj.Parent == nil and ESP.AutoRemove ~= false then
			box:Remove()
		end
	end)

	local hum = obj:FindFirstChildOfClass("Humanoid")
	if hum and (not ESP.IgnoreHumanoids) then
		hum.Died:Connect(function()
			if ESP.AutoRemove ~= false then
				box:Remove()
			end
		end)
	end
	return box
end

local function CharAdded(char)
	local p = plrs:GetPlayerFromCharacter(char)
	if not char:FindFirstChild("HumanoidRootPart") then
		local ev
		ev = char.ChildAdded:Connect(function(c)
			if c.Name == "HumanoidRootPart" then
				ev:Disconnect()
				ESP:Add(char, {
					Name = p.Name,
					Player = p,
					PrimaryPart = c
				})
			end
		end)
	else
		ESP:Add(char, {
			Name = p.Name,
			Player = p,
			PrimaryPart = char.HumanoidRootPart
		})
	end
end
local function PlayerAdded(p)
	p.CharacterAdded:Connect(CharAdded)
	if p.Character then
		coroutine.wrap(CharAdded)(p.Character)
	end
end
plrs.PlayerAdded:Connect(PlayerAdded)
for i,v in pairs(plrs:GetPlayers()) do
	if v ~= plr then
		PlayerAdded(v)
	end
end

game:GetService("RunService").RenderStepped:Connect(function()
	cam = workspace.CurrentCamera
	for i,v in (ESP.Enabled and pairs or ipairs)(ESP.Objects) do
		if v.Update then
			local s,e = pcall(v.Update, v)
			if not s then warn("[EU]", e, v.Object:GetFullName()) end
		end
	end
end)

return ESP
