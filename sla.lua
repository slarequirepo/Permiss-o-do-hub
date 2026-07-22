--[[
    ============================================================================
    ANIMATION EDITOR - COMPLETO (UI + LÓGICA, MOBILE-READY)
    ============================================================================
    Script ORIGINAL, único, rodando como LocalScript. Junta a interface e o
    backend de animação num só lugar (sem precisar de _G para conectar as
    duas partes), com:

      - Detecção de rig via Motor6D + Acessórios
      - Rotate / Move / Grow (crescer o personagem inteiro pelo Torso)
      - Timeline com Keyframes/Poses, easing, undo/redo
      - Mirror Pose, Insert/Remove Time, Duplicate Keyframe, Auto-Key, Onion
        Skin, Zoom to Fit
      - Salvar/Carregar no formato nativo do Roblox (KeyframeSequence)
      - Suporte a toque: toolbar com scroll, painéis em gaveta, touchpad
        virtual para as ferramentas, pinch-zoom na timeline

    Instruções:
      1) Cole este LocalScript dentro de uma ScreenGui em StarterGui (ou
         carregue via loadstring dentro de uma ScreenGui já existente).
      2) Chame Editor.init(workspace.SeuNPC) para escolher o que animar
         (por padrão, tenta usar o personagem do próprio jogador).
    ============================================================================
]]

-- ============================================================================
-- SERVIÇOS
-- ============================================================================

local Players         = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse   = player:GetMouse()
local camera  = workspace.CurrentCamera

local IS_TOUCH = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local IS_SMALL_SCREEN = camera.ViewportSize.X < 900

-- ============================================================================
-- CONFIG VISUAL
-- ============================================================================

local COLORS = {
	Background = Color3.new(0.08, 0.08, 0.08),
	Panel = Color3.new(0.157, 0.157, 0.157),
	PanelDark = Color3.new(0.11, 0.11, 0.11),
	ButtonOn = Color3.new(0.85, 0.55, 0.15),      -- âmbar (ativo)
	ButtonOff = Color3.new(0.196, 0.196, 0.196),
	ButtonHover = Color3.new(0.32, 0.32, 0.32),
	ButtonPress = Color3.new(0.45, 0.45, 0.45),
	Text = Color3.new(0.92, 0.92, 0.92),
	TextDark = Color3.new(0.6, 0.6, 0.6),
	Accent = Color3.new(0.2, 0.75, 0.95),         -- ciano (cursor/seleção)
	Keyframe = Color3.new(0.9, 0.6, 0.15),        -- âmbar
	KeyframeSelected = Color3.new(0.2, 0.75, 0.95),
	OnionPrev = Color3.new(0.2, 0.5, 1),
	OnionNext = Color3.new(0.3, 0.9, 0.4),
	TitleBar = Color3.new(0.12, 0.12, 0.12),
	CloseButton = Color3.new(0.6, 0.2, 0.2),
	Border = Color3.new(0.32, 0.32, 0.32),
	InputBg = Color3.new(0.22, 0.22, 0.22),
	DialogButton = Color3.new(0.3, 0.35, 0.5),
}

local FONT = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold
local FONT_MONO = Enum.Font.Code

-- Escala tudo um pouco maior no mobile pra facilitar o toque
local SCALE = IS_TOUCH and 1.35 or 1
local function px(n) return math.floor(n * SCALE) end

local LAYOUT = {
	TitleBarHeight = px(24),
	ToolbarHeight = px(34),
	PlaybackHeight = px(40),
	LeftPanelWidth = IS_SMALL_SCREEN and px(0) or px(160),
	RightPanelWidth = IS_SMALL_SCREEN and px(0) or px(200),
	TimelineMinHeight = px(160),
	TouchPadSize = px(140),
}

-- ============================================================================
-- ESTADO
-- ============================================================================

local State = {
	-- edição
	partList = {},          -- [Part] = PartNode
	partToLineNumber = {},
	partInclude = {},
	keyframeList = {},       -- [time] = KeyframeData
	selectedKeyframes = {},  -- [time] = true  (multi-seleção)
	selectedKeyframe = nil,
	copyPoseList = {},
	undoStack = {},
	redoStack = {},

	-- animação
	currentTime = 0,
	animationLength = 2,
	frameStep = 1/30,        -- segundos por frame
	loopAnimation = false,
	animationPriority = "Action",

	-- ferramentas
	currentTool = "rotate",  -- "rotate" | "move" | "grow"
	currentSpace = "local",
	snapEnabled = true,
	interpolationEnabled = true,
	rotateStep = 0,
	moveStep = 0,
	autoKey = false,
	onionSkinEnabled = false,

	-- seleção / rig
	rigRoot = nil,
	rootNode = nil,
	selectedNode = nil,

	-- runtime
	playing = false,
	stopAnim = false,
	zoomLevel = 1,
	modal = false,
}

local Editor = {} -- API pública, também acessível como Editor.xxx fora do script

-- ============================================================================
-- UTILITÁRIOS
-- ============================================================================

local function Make(className, properties)
	local inst = Instance.new(className)
	for key, value in pairs(properties) do
		if type(key) == "number" then
			value.Parent = inst
		else
			inst[key] = value
		end
	end
	return inst
end

local function deepCopy(tbl)
	if type(tbl) ~= "table" then return tbl end
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = (type(v) == "table") and deepCopy(v) or v
	end
	return copy
end

local function round(n, step)
	step = step or 1
	if step <= 0 then return n end
	return math.floor(n / step + 0.5) * step
end

local function clampTime(t)
	t = math.clamp(t, 0, State.animationLength)
	if State.snapEnabled then
		t = round(t, State.frameStep)
	end
	return t
end

local function styleButton(button, isToggle)
	button.BackgroundColor3 = COLORS.ButtonOff
	button.BorderColor3 = COLORS.Border
	button.BorderSizePixel = 1
	button.TextColor3 = COLORS.Text
	button.Font = FONT
	button.TextSize = px(12)
	button.AutoButtonColor = false

	local function refresh()
		if isToggle and button:GetAttribute("Selected") then
			button.BackgroundColor3 = COLORS.ButtonOn
			button.TextColor3 = Color3.new(0.05, 0.05, 0.05)
		else
			button.BackgroundColor3 = COLORS.ButtonOff
			button.TextColor3 = COLORS.Text
		end
	end
	button.MouseEnter:Connect(function() if not (isToggle and button:GetAttribute("Selected")) then button.BackgroundColor3 = COLORS.ButtonHover end end)
	button.MouseLeave:Connect(refresh)
	button.MouseButton1Down:Connect(function() button.BackgroundColor3 = COLORS.ButtonPress end)
	button.MouseButton1Up:Connect(refresh)
	if isToggle then
		button:SetAttribute("Selected", false)
		button:GetAttributeChangedSignal("Selected"):Connect(refresh)
	end
	return button
end

-- ============================================================================
-- SEÇÃO 1: DETECÇÃO DO RIG
-- ============================================================================

local function isMotorLike(inst)
	return inst:IsA("Motor6D") or inst:IsA("Weld") or inst:IsA("Motor")
end

local function buildNode(part, motor, parentNode)
	local node = {
		Part = part, Item = part, Motor = motor, Parent = parentNode,
		Children = {}, IsAccessory = false,
		OriginC0 = motor and motor.C0 or CFrame.new(),
		OriginC1 = motor and motor.C1 or CFrame.new(),
		OriginSize = part.Size,
	}
	State.partList[part] = node
	State.partInclude[part.Name] = true
	return node
end

local function scanChildren(fromPart, node)
	for _, d in ipairs(fromPart:GetDescendants()) do
		if isMotorLike(d) and d.Part0 == fromPart then
			local childPart = d.Part1
			if childPart and childPart:IsA("BasePart") and not State.partList[childPart] then
				local childNode = buildNode(childPart, d, node)
				table.insert(node.Children, childNode)
				scanChildren(childPart, childNode)
			end
		end
	end
end

local function attachAccessories(character)
	for _, acc in ipairs(character:GetChildren()) do
		if acc:IsA("Accessory") then
			local handle = acc:FindFirstChild("Handle")
			local weld = handle and (handle:FindFirstChildOfClass("Weld") or handle:FindFirstChildOfClass("Motor6D"))
			if weld and weld.Part0 and State.partList[weld.Part0] then
				local parentNode = State.partList[weld.Part0]
				local accNode = buildNode(handle, weld, parentNode)
				accNode.IsAccessory = true
				table.insert(parentNode.Children, accNode)
			end
		end
	end
end

function Editor.buildRig(character)
	State.partList, State.partToLineNumber, State.partInclude = {}, {}, {}
	local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if not root then
		warn("[AnimationEditor] Raiz não encontrada em " .. character:GetFullName())
		return nil
	end
	State.rigRoot = character
	local rootNode = buildNode(root, nil, nil)
	State.rootNode = rootNode
	scanChildren(root, rootNode)
	attachAccessories(character)

	local n = 0
	local function assign(node)
		n += 1
		State.partToLineNumber[node.Part] = n
		for _, c in ipairs(node.Children) do assign(c) end
	end
	assign(rootNode)
	return rootNode
end

-- ============================================================================
-- SEÇÃO 2: SELEÇÃO
-- ============================================================================

local function raycastToPart(x, y)
	local unitRay = camera:ViewportPointToRay(x, y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { State.rigRoot }
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, params)
	return result and result.Instance and State.partList[result.Instance] or nil
end

local onSelectionChangedCallbacks = {}
function Editor.onSelectionChanged(fn) table.insert(onSelectionChangedCallbacks, fn) end

function Editor.select(node)
	State.selectedNode = node
	for _, fn in ipairs(onSelectionChangedCallbacks) do fn(node) end
end

function Editor.deselect()
	State.selectedNode = nil
	for _, fn in ipairs(onSelectionChangedCallbacks) do fn(nil) end
end

-- ============================================================================
-- SEÇÃO 3: FERRAMENTAS (ROTATE / MOVE / GROW)
-- ============================================================================

function Editor.applyRotate(node, deltaDegreesY, deltaDegreesX)
	if not node or not node.Motor then return end
	deltaDegreesY = State.rotateStep > 0 and round(deltaDegreesY, State.rotateStep) or deltaDegreesY
	node.Motor.C0 = node.Motor.C0 * CFrame.Angles(math.rad(deltaDegreesX or 0), math.rad(deltaDegreesY), 0)
end

function Editor.applyMove(node, deltaVector)
	if not node or not node.Motor then return end
	if State.moveStep > 0 then
		deltaVector = Vector3.new(round(deltaVector.X, State.moveStep), round(deltaVector.Y, State.moveStep), round(deltaVector.Z, State.moveStep))
	end
	node.Motor.C0 = node.Motor.C0 * CFrame.new(deltaVector)
end

local function scaleRecursive(node, factor)
	node.Part.Size = node.Part.Size * factor
	for _, child in ipairs(node.Children) do
		if child.Motor then
			child.Motor.C0 = child.Motor.C0.Rotation + (child.Motor.C0.Position * factor)
		end
		scaleRecursive(child, factor)
	end
end

function Editor.applyGrow(node, factor)
	if not node or factor <= 0 then return end
	if node == State.rootNode then
		local centerCFrame = node.Part.CFrame
		scaleRecursive(node, factor)
		node.Part.CFrame = centerCFrame
	else
		scaleRecursive(node, factor)
	end
end

function Editor.captureCurrentPoseToKeyframe()
	local kf = State.keyframeList[clampTime(State.currentTime)] or Editor.createKeyframe(State.currentTime, true)
	for part, _ in pairs(State.partList) do
		Editor.capturePose(kf, part)
	end
end

function Editor.onToolDrag(delta)
	local node = State.selectedNode
	if not node then return end
	if State.currentTool == "rotate" then
		if typeof(delta) == "Vector2" then
			Editor.applyRotate(node, delta.X, delta.Y)
		else
			Editor.applyRotate(node, delta)
		end
	elseif State.currentTool == "move" then
		Editor.applyMove(node, delta)
	elseif State.currentTool == "grow" then
		Editor.applyGrow(node, delta)
	end

	if State.autoKey then
		Editor.captureCurrentPoseToKeyframe()
	end
	Editor.updateCursorPosition()
end

-- ============================================================================
-- SEÇÃO 4: KEYFRAMES / POSES
-- ============================================================================

function Editor.getKeyframe(time)
	return State.keyframeList[clampTime(time)]
end

function Editor.createKeyframe(time, shouldRegisterUndo)
	if shouldRegisterUndo ~= false and time > 0 then
		Editor.registerUndo({ action = "createKeyframe" })
	end
	local t = clampTime(time)
	if State.keyframeList[t] then return State.keyframeList[t] end
	local kf = { Time = t, Poses = {}, Name = "Keyframe" }
	State.keyframeList[t] = kf
	if t == 0 then
		for part, _ in pairs(State.partList) do Editor.capturePose(kf, part) end
	end
	if State.onRefresh then State.onRefresh() end
	return kf
end

function Editor.deleteKeyframe(time, shouldRegisterUndo)
	if shouldRegisterUndo ~= false then Editor.registerUndo({ action = "deleteKeyframe" }) end
	State.keyframeList[clampTime(time)] = nil
	if State.onRefresh then State.onRefresh() end
end

function Editor.moveKeyframe(kf, newTime)
	if not kf then return end
	local t = clampTime(newTime)
	if State.keyframeList[t] then return end
	Editor.registerUndo({ action = "keyframeMove" })
	State.keyframeList[kf.Time] = nil
	kf.Time = t
	State.keyframeList[t] = kf
	State.currentTime = t
	Editor.updateCursorPosition()
	if State.onRefresh then State.onRefresh() end
end

function Editor.capturePose(kf, part)
	local node = State.partList[part]
	if not node or not node.Motor or not State.partInclude[part.Name] then return end
	local relative = node.OriginC0:Inverse() * node.Motor.C0
	local pose = kf.Poses[part]
	if not pose then
		pose = { CFrame = relative, Size = part.Size, EasingStyle = Enum.PoseEasingStyle.Linear, EasingDirection = Enum.PoseEasingDirection.Out }
		kf.Poses[part] = pose
	else
		pose.CFrame, pose.Size = relative, part.Size
	end
	return pose
end

function Editor.deletePose(kf, part)
	if not kf or not kf.Poses[part] then return end
	Editor.registerUndo({ action = "deletePose" })
	kf.Poses[part] = nil
	Editor.updateCursorPosition()
end

function Editor.copyPose(partOrName, pose)
	local name = typeof(partOrName) == "Instance" and partOrName.Name or partOrName
	State.copyPoseList[name] = pose
end

function Editor.resetCopyPoseList() State.copyPoseList = {} end

function Editor.pastePoses()
	if next(State.copyPoseList) == nil then return end
	Editor.registerUndo({ action = "pastePoses" })
	local kf = Editor.getKeyframe(State.currentTime) or Editor.createKeyframe(State.currentTime, false)
	for partName, pose in pairs(State.copyPoseList) do
		for part, _ in pairs(State.partList) do
			if part.Name == partName then kf.Poses[part] = deepCopy(pose) end
		end
	end
	Editor.resetCopyPoseList()
	Editor.updateCursorPosition()
end

function Editor.resetKeyframeToDefaultPose(kf)
	if not kf then return end
	for part, node in pairs(State.partList) do
		kf.Poses[part] = { CFrame = CFrame.new(), Size = node.OriginSize, EasingStyle = Enum.PoseEasingStyle.Linear, EasingDirection = Enum.PoseEasingDirection.Out }
	end
	Editor.updateCursorPosition()
end

-- ============================================================================
-- SEÇÃO 5: FUNÇÕES EXTRAS DE ANIMADOR
-- ============================================================================

--[[ Mirror Pose: troca as poses de partes "Left"/"Right" no keyframe atual,
     e inverte o eixo X da rotação/posição de cada uma (espelhamento). ]]
function Editor.mirrorCurrentKeyframe()
	local kf = Editor.getKeyframe(State.currentTime)
	if not kf then return end
	Editor.registerUndo({ action = "mirrorPose" })

	local function mirrorName(name)
		if name:find("Left") then return name:gsub("Left", "Right") end
		if name:find("Right") then return name:gsub("Right", "Left") end
		return nil
	end

	local function mirrorCFrame(cf)
		local pos = cf.Position
		local rx, ry, rz = cf:ToEulerAnglesXYZ()
		return CFrame.new(-pos.X, pos.Y, pos.Z) * CFrame.Angles(rx, -ry, -rz)
	end

	local swaps = {}
	for part, pose in pairs(kf.Poses) do
		local mirroredName = mirrorName(part.Name)
		if mirroredName then
			for otherPart, _ in pairs(State.partList) do
				if otherPart.Name == mirroredName then
					table.insert(swaps, { a = part, b = otherPart })
				end
			end
		end
	end

	local newPoses = {}
	for part, pose in pairs(kf.Poses) do
		newPoses[part] = pose
	end
	for _, swap in ipairs(swaps) do
		local poseA, poseB = kf.Poses[swap.a], kf.Poses[swap.b]
		if poseA then newPoses[swap.b] = { CFrame = mirrorCFrame(poseA.CFrame), Size = poseA.Size, EasingStyle = poseA.EasingStyle, EasingDirection = poseA.EasingDirection } end
		if poseB then newPoses[swap.a] = { CFrame = mirrorCFrame(poseB.CFrame), Size = poseB.Size, EasingStyle = poseB.EasingStyle, EasingDirection = poseB.EasingDirection } end
	end
	kf.Poses = newPoses
	Editor.updateCursorPosition()
end

--[[ Insere `duration` segundos no tempo do cursor, empurrando todos os
     keyframes depois dele. ]]
function Editor.insertTimeAtCursor(duration)
	Editor.registerUndo({ action = "insertTime" })
	local shifted = {}
	for t, kf in pairs(State.keyframeList) do
		if t >= State.currentTime then
			kf.Time = t + duration
			shifted[kf.Time] = kf
		else
			shifted[t] = kf
		end
	end
	State.keyframeList = shifted
	State.animationLength += duration
	if State.onRefresh then State.onRefresh() end
end

--[[ Remove `duration` segundos a partir do cursor, puxando os keyframes
     seguintes pra trás (e deletando os que caiam dentro do intervalo). ]]
function Editor.removeTimeAtCursor(duration)
	Editor.registerUndo({ action = "removeTime" })
	local shifted = {}
	for t, kf in pairs(State.keyframeList) do
		if t >= State.currentTime and t < State.currentTime + duration then
			-- descarta: caiu dentro do intervalo removido
		elseif t >= State.currentTime + duration then
			kf.Time = t - duration
			shifted[kf.Time] = kf
		else
			shifted[t] = kf
		end
	end
	State.keyframeList = shifted
	State.animationLength = math.max(State.frameStep, State.animationLength - duration)
	if State.onRefresh then State.onRefresh() end
end

--[[ Duplica o keyframe atual para outro tempo (por padrão, +1 segundo ou o
     fim da animação, o que vier primeiro). ]]
function Editor.duplicateKeyframe(kf, targetTime)
	if not kf then return end
	Editor.registerUndo({ action = "duplicateKeyframe" })
	local t = clampTime(targetTime or math.min(kf.Time + 0.5, State.animationLength))
	local newKf = { Time = t, Poses = deepCopy(kf.Poses), Name = kf.Name }
	State.keyframeList[t] = newKf
	if State.onRefresh then State.onRefresh() end
	return newKf
end

function Editor.setAnimationLength(length)
	Editor.registerUndo({ action = "changeLength" })
	State.animationLength = math.max(State.frameStep, length)
	for t, kf in pairs(State.keyframeList) do
		if t > State.animationLength then
			kf.Time = State.animationLength
			State.keyframeList[t] = nil
			State.keyframeList[State.animationLength] = kf
		end
	end
	if State.onRefresh then State.onRefresh() end
end

function Editor.setFramerate(fps)
	State.frameStep = 1 / math.max(1, fps)
end

function Editor.setPriority(priorityName)
	State.animationPriority = priorityName
end

function Editor.setLooping(shouldLoop)
	State.loopAnimation = shouldLoop
end

function Editor.toggleAutoKey()
	State.autoKey = not State.autoKey
	return State.autoKey
end

--[[ Onion Skin: mostra marcadores fantasmas (azul = keyframe anterior,
     verde = próximo) na posição de cada parte incluída, sem alterar o rig
     de verdade. Reaproveita a mesma lógica de interpolação, só que calcula
     a pose em outro instante de tempo e desenha esferas semi-transparentes
     no lugar, ao invés de mover o modelo. ]]
local onionParts = {}
local function clearOnionSkin()
	for _, p in ipairs(onionParts) do p:Destroy() end
	onionParts = {}
end

local function sortedTimes()
	local t = {}
	for time, _ in pairs(State.keyframeList) do table.insert(t, time) end
	table.sort(t)
	return t
end

local function findSurrounding(time)
	local before, after
	for _, t in ipairs(sortedTimes()) do
		if t <= time then before = State.keyframeList[t]
		elseif not after then after = State.keyframeList[t] end
	end
	return before, after
end

-- Calcula CFrame absoluto de cada parte incluída, para um tempo arbitrário,
-- sem tocar no rig real (usado pelo Onion Skin).
local function computeWorldPoseAtTime(time)
	local worldCFrames = {}
	local before, after = findSurrounding(time)
	if not before then return worldCFrames end

	local function resolve(node, parentWorldCFrame)
		local worldCFrame
		if not node.Motor then
			worldCFrame = node.Part.CFrame
		else
			local poseBefore = before.Poses[node.Part]
			local target = poseBefore and poseBefore.CFrame or CFrame.new()
			if poseBefore and State.interpolationEnabled and after and after.Poses[node.Part] and after ~= before then
				local poseAfter = after.Poses[node.Part]
				local span = after.Time - before.Time
				local alpha = span > 0 and (time - before.Time) / span or 0
				target = poseBefore.CFrame:Lerp(poseAfter.CFrame, alpha)
			end
			worldCFrame = parentWorldCFrame * (node.OriginC0 * target) * node.OriginC1:Inverse()
		end
		worldCFrames[node.Part] = worldCFrame
		for _, child in ipairs(node.Children) do resolve(child, worldCFrame) end
	end

	if State.rootNode then resolve(State.rootNode, State.rootNode.Part.CFrame) end
	return worldCFrames
end

local function drawOnionMarkers(worldCFrames, color)
	for part, cf in pairs(worldCFrames) do
		if not part:IsA("BasePart") then continue end
		local marker = Make("Part", {
			Name = "OnionMarker",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.35, 0.35, 0.35),
			Color3 = color,
			Color = color,
			Material = Enum.Material.Neon,
			Transparency = 0.4,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CFrame = cf,
			Parent = workspace,
		})
		table.insert(onionParts, marker)
	end
end

function Editor.refreshOnionSkin()
	clearOnionSkin()
	if not State.onionSkinEnabled then return end
	local step = State.frameStep * 3 -- ~3 frames antes/depois
	local prevWorld = computeWorldPoseAtTime(math.max(0, State.currentTime - step))
	local nextWorld = computeWorldPoseAtTime(math.min(State.animationLength, State.currentTime + step))
	drawOnionMarkers(prevWorld, COLORS.OnionPrev)
	drawOnionMarkers(nextWorld, COLORS.OnionNext)
end

function Editor.toggleOnionSkin()
	State.onionSkinEnabled = not State.onionSkinEnabled
	if not State.onionSkinEnabled then clearOnionSkin() end
	Editor.refreshOnionSkin()
	return State.onionSkinEnabled
end

--[[ Zoom to Fit: devolve o fator de zoom ideal pra timeline caber todos os
     keyframes na tela (a UI usa esse valor pra ajustar o CanvasSize). ]]
function Editor.getZoomToFit()
	return 1 -- a UI recalcula com base em State.animationLength; aqui fica só o hook
end

-- ============================================================================
-- SEÇÃO 6: INTERPOLAÇÃO / CURSOR
-- ============================================================================

function Editor.updateCursorPosition()
	local before, after = findSurrounding(State.currentTime)
	if not before then return end
	for part, node in pairs(State.partList) do
		local poseBefore = before.Poses[part]
		if poseBefore then
			local targetCFrame, targetSize = poseBefore.CFrame, poseBefore.Size
			if State.interpolationEnabled and after and after.Poses[part] and after ~= before then
				local poseAfter = after.Poses[part]
				local span = after.Time - before.Time
				local alpha = span > 0 and (State.currentTime - before.Time) / span or 0
				targetCFrame = poseBefore.CFrame:Lerp(poseAfter.CFrame, alpha)
				targetSize = poseBefore.Size:Lerp(poseAfter.Size, alpha)
			end
			if node.Motor then node.Motor.C0 = node.OriginC0 * targetCFrame end
			if targetSize then node.Part.Size = targetSize end
		end
	end
	if State.onionSkinEnabled then Editor.refreshOnionSkin() end
	if State.onCursorUpdate then State.onCursorUpdate() end
end

-- ============================================================================
-- SEÇÃO 7: UNDO / REDO
-- ============================================================================

local function snapshot()
	return { keyframeList = deepCopy(State.keyframeList), animationLength = State.animationLength }
end
local function restore(snap)
	State.keyframeList = deepCopy(snap.keyframeList)
	State.animationLength = snap.animationLength
	Editor.updateCursorPosition()
	if State.onRefresh then State.onRefresh() end
end

function Editor.registerUndo(actionData)
	local last = State.undoStack[#State.undoStack]
	if last and last.action == actionData.action and last.locked then return end
	State.redoStack = {}
	actionData.snapshot = snapshot()
	table.insert(State.undoStack, actionData)
end

function Editor.lockUndoStep(actionName)
	local last = State.undoStack[#State.undoStack]
	if last and last.action == actionName then last.locked = true end
end

function Editor.undo()
	local entry = table.remove(State.undoStack)
	if not entry then return end
	local current = snapshot()
	restore(entry.snapshot)
	entry.snapshot = current
	table.insert(State.redoStack, entry)
end

function Editor.redo()
	local entry = table.remove(State.redoStack)
	if not entry then return end
	local current = snapshot()
	restore(entry.snapshot)
	entry.snapshot = current
	table.insert(State.undoStack, entry)
end

-- ============================================================================
-- SEÇÃO 8: PLAYBACK
-- ============================================================================

local playConnection = nil
function Editor.play()
	if State.playing then return end
	State.playing, State.stopAnim = true, false
	playConnection = RunService.RenderStepped:Connect(function(dt)
		if State.stopAnim then
			State.playing = false
			playConnection:Disconnect()
			return
		end
		State.currentTime += dt
		if State.currentTime > State.animationLength then
			if State.loopAnimation then
				State.currentTime = 0
			else
				State.currentTime = State.animationLength
				State.stopAnim = true
			end
		end
		Editor.updateCursorPosition()
		if State.onPlaybackStep then State.onPlaybackStep(State.currentTime) end
	end)
end
function Editor.stop() State.stopAnim = true end

-- ============================================================================
-- SEÇÃO 9: SALVAR / CARREGAR (KeyframeSequence nativo)
-- ============================================================================

local savedAnimations = {}

function Editor.saveCurrentAnimation(animName, isExport)
	local sequence = Instance.new("KeyframeSequence")
	sequence.Name = animName or "Animation"
	sequence.Priority = Enum.AnimationPriority[State.animationPriority] or Enum.AnimationPriority.Action
	sequence.Loop = State.loopAnimation
	for time, kf in pairs(State.keyframeList) do
		local keyframe = Instance.new("Keyframe")
		keyframe.Name, keyframe.Time = kf.Name or "Keyframe", time
		for part, poseData in pairs(kf.Poses) do
			local pose = Instance.new("Pose")
			pose.Name = part.Name
			pose.CFrame = poseData.CFrame
			pose.EasingStyle = poseData.EasingStyle or Enum.PoseEasingStyle.Linear
			pose.EasingDirection = poseData.EasingDirection or Enum.PoseEasingDirection.Out
			pose.Parent = keyframe
		end
		keyframe.Parent = sequence
	end
	if isExport then sequence.Parent = ReplicatedStorage end
	savedAnimations[animName] = sequence
	return sequence
end

function Editor.loadAnimation(sequence)
	State.keyframeList, State.animationLength = {}, 0
	State.loopAnimation = sequence.Loop
	for _, keyframe in ipairs(sequence:GetChildren()) do
		if keyframe:IsA("Keyframe") then
			local kf = { Time = keyframe.Time, Poses = {}, Name = keyframe.Name }
			for _, pose in ipairs(keyframe:GetChildren()) do
				if pose:IsA("Pose") then
					for part, node in pairs(State.partList) do
						if part.Name == pose.Name then
							kf.Poses[part] = { CFrame = pose.CFrame, Size = node.OriginSize, EasingStyle = pose.EasingStyle, EasingDirection = pose.EasingDirection }
						end
					end
				end
			end
			State.keyframeList[keyframe.Time] = kf
			State.animationLength = math.max(State.animationLength, keyframe.Time)
		end
	end
	Editor.updateCursorPosition()
	if State.onRefresh then State.onRefresh() end
end

function Editor.listSavedAnimations()
	local names = {}
	for name, _ in pairs(savedAnimations) do table.insert(names, name) end
	return names
end
function Editor.getSavedAnimation(name) return savedAnimations[name] end

-- ============================================================================
-- SEÇÃO 10: INICIALIZAÇÃO DO EDITOR (sem UI ainda)
-- ============================================================================

function Editor.init(character)
	local root = Editor.buildRig(character)
	if not root then return false end
	Editor.createKeyframe(0, false)
	State.currentTime = 0
	Editor.updateCursorPosition()
	return true
end

-- ============================================================================
--  A PARTIR DAQUI: INTERFACE (usa Editor.* diretamente, sem _G)
-- ============================================================================

local ui = {}

local function attachTooltip() end -- placeholder simples (mobile não usa hover)

-- ---- Dialogs ---------------------------------------------------------------

local function showTextEntryDialog(title, defaultText)
	State.modal = true
	local result, confirmed = defaultText, false
	local dialog = Make("Frame", {
		Name = "TextEntryDialog", BackgroundColor3 = COLORS.PanelDark, BorderColor3 = COLORS.Border, BorderSizePixel = 1,
		Size = UDim2.new(0, px(360), 0, px(120)), Position = UDim2.new(0.5, -px(180), 0.5, -px(60)), ZIndex = 200,
		Make("TextLabel", { Text = title, Font = FONT_BOLD, TextSize = px(14), TextColor3 = COLORS.Text, BackgroundTransparency = 1,
			Position = UDim2.new(0.05, 0, 0, 6), Size = UDim2.new(0.9, 0, 0, px(18)), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201 }),
		Make("TextBox", { Name = "InputBox", Text = defaultText or "", Font = FONT, TextSize = px(16), TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.InputBg, BorderColor3 = COLORS.Border, BorderSizePixel = 1, ClearTextOnFocus = false,
			Position = UDim2.new(0.05, 0, 0, px(30)), Size = UDim2.new(0.9, 0, 0, px(34)), ZIndex = 201 }),
		Make("TextButton", { Name = "OK", Text = "OK", Font = FONT_BOLD, TextSize = px(14), TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.DialogButton, BorderSizePixel = 0, Position = UDim2.new(0.05, 0, 0, px(74)), Size = UDim2.new(0.42, 0, 0, px(34)), ZIndex = 201 }),
		Make("TextButton", { Name = "Cancel", Text = "Cancel", Font = FONT_BOLD, TextSize = px(14), TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.DialogButton, BorderSizePixel = 0, Position = UDim2.new(0.53, 0, 0, px(74)), Size = UDim2.new(0.42, 0, 0, px(34)), ZIndex = 201 }),
	})
	dialog.Parent = ui.mainWindow
	dialog.OK.MouseButton1Click:Connect(function() result, confirmed = dialog.InputBox.Text, true end)
	dialog.Cancel.MouseButton1Click:Connect(function() result, confirmed = nil, true end)
	repeat task.wait(0.05) until confirmed
	dialog:Destroy()
	State.modal = false
	return result
end

local function showConfirmationDialog(message)
	State.modal = true
	local result, confirmed = false, false
	local dialog = Make("Frame", {
		Name = "ConfirmDialog", BackgroundColor3 = COLORS.PanelDark, BorderColor3 = COLORS.Border, BorderSizePixel = 1,
		Size = UDim2.new(0, px(360), 0, px(110)), Position = UDim2.new(0.5, -px(180), 0.5, -px(55)), ZIndex = 200,
		Make("TextLabel", { Text = message, Font = FONT, TextSize = px(13), TextColor3 = COLORS.Text, BackgroundTransparency = 1, TextWrapped = true,
			Position = UDim2.new(0.05, 0, 0, 6), Size = UDim2.new(0.9, 0, 0, px(46)), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201 }),
		Make("TextButton", { Name = "OK", Text = "OK", Font = FONT_BOLD, TextSize = px(14), TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.DialogButton, BorderSizePixel = 0, Position = UDim2.new(0.05, 0, 0, px(60)), Size = UDim2.new(0.42, 0, 0, px(34)), ZIndex = 201 }),
		Make("TextButton", { Name = "Cancel", Text = "Cancel", Font = FONT_BOLD, TextSize = px(14), TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.DialogButton, BorderSizePixel = 0, Position = UDim2.new(0.53, 0, 0, px(60)), Size = UDim2.new(0.42, 0, 0, px(34)), ZIndex = 201 }),
	})
	dialog.Parent = ui.mainWindow
	dialog.OK.MouseButton1Click:Connect(function() result, confirmed = true, true end)
	dialog.Cancel.MouseButton1Click:Connect(function() result, confirmed = false, true end)
	repeat task.wait(0.05) until confirmed
	dialog:Destroy()
	State.modal = false
	return result
end

local function closeContextMenu()
	if ui.contextMenu then ui.contextMenu:Destroy(); ui.contextMenu = nil end
	State.modal = false
end

local function showContextMenu(options, position)
	closeContextMenu()
	State.modal = true
	local itemHeight = px(28)
	local menu = Make("Frame", {
		Name = "ContextMenu", BackgroundColor3 = COLORS.PanelDark, BorderColor3 = COLORS.Border, BorderSizePixel = 1,
		Size = UDim2.new(0, px(170), 0, #options * itemHeight + 4),
		Position = UDim2.new(0, math.clamp(position.X, 0, camera.ViewportSize.X - px(170)), 0, position.Y), ZIndex = 60,
	})
	for i, option in ipairs(options) do
		local btn = Make("TextButton", {
			Text = option.label, Font = FONT, TextSize = px(13), TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.ButtonOff, BorderSizePixel = 0,
			Size = UDim2.new(1, -4, 0, itemHeight - 2), Position = UDim2.new(0, 2, 0, (i - 1) * itemHeight + 2),
			ZIndex = 61, Parent = menu,
		})
		btn.MouseButton1Click:Connect(function()
			if option.callback then option.callback() end
			closeContextMenu()
		end)
	end
	menu.Parent = ui.mainWindow
	ui.contextMenu = menu
end

-- ---- Janela principal -------------------------------------------------------

local function createMainWindow(screenGui)
	local width = IS_SMALL_SCREEN and camera.ViewportSize.X or math.min(1100, camera.ViewportSize.X - 20)
	local height = IS_SMALL_SCREEN and camera.ViewportSize.Y or math.min(650, camera.ViewportSize.Y - 20)
	ui.mainWindow = Make("Frame", {
		Name = "AnimationEditorWindow", BackgroundColor3 = COLORS.Background, BorderColor3 = COLORS.Border, BorderSizePixel = 1,
		Size = UDim2.new(0, width, 0, height),
		Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
		ClipsDescendants = true, Active = true, Draggable = not IS_SMALL_SCREEN,
		Parent = screenGui,
	})
end

local function createTitleBar()
	ui.titleBar = Make("Frame", {
		Name = "TitleBar", BackgroundColor3 = COLORS.TitleBar, BorderColor3 = COLORS.Border, BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, LAYOUT.TitleBarHeight), Parent = ui.mainWindow,
	})
	Make("TextLabel", {
		Text = "Animation Editor", Font = FONT_BOLD, TextSize = px(13), TextColor3 = COLORS.Text, BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(0, 220, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = ui.titleBar,
	})
	local closeBtn = Make("TextButton", {
		Text = "X", Font = FONT_BOLD, TextSize = px(13), TextColor3 = COLORS.Text, BackgroundColor3 = COLORS.CloseButton,
		Size = UDim2.new(0, px(26), 0, LAYOUT.TitleBarHeight - 4), Position = UDim2.new(1, -px(30), 0, 2), Parent = ui.titleBar,
	})
	closeBtn.MouseButton1Click:Connect(function()
		Editor.stop()
		ui.mainWindow.Visible = false
	end)
end

-- ---- Toolbar (com scroll horizontal, boa pra mobile) -----------------------

local function createToolbar()
	ui.toolbar = Make("ScrollingFrame", {
		Name = "Toolbar", BackgroundColor3 = COLORS.Panel, BorderColor3 = COLORS.Border, BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, LAYOUT.ToolbarHeight), Position = UDim2.new(0, 0, 0, LAYOUT.TitleBarHeight),
		ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = px(4), CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = ui.mainWindow,
	})

	local buttons = {
		{ id = "new", label = "New" }, { id = "save", label = "Save" }, { id = "load", label = "Load" }, { id = "export", label = "Export" },
		{ id = "sep" },
		{ id = "undo", label = "Undo" }, { id = "redo", label = "Redo" },
		{ id = "sep" },
		{ id = "rotate", label = "Rotate", toggle = true, group = "tool" },
		{ id = "move", label = "Move", toggle = true, group = "tool" },
		{ id = "grow", label = "Grow", toggle = true, group = "tool" },
		{ id = "sep" },
		{ id = "snap", label = "Snap", toggle = true },
		{ id = "interp", label = "Interp", toggle = true },
		{ id = "autokey", label = "Auto-Key", toggle = true },
		{ id = "onionskin", label = "Onion", toggle = true },
		{ id = "sep" },
		{ id = "keyframe_add", label = "+Kf" }, { id = "keyframe_delete", label = "-Kf" }, { id = "duplicate", label = "Dup Kf" },
		{ id = "copy", label = "Copy" }, { id = "paste", label = "Paste" }, { id = "mirror", label = "Mirror" },
		{ id = "sep" },
		{ id = "insert_time", label = "+Time" }, { id = "remove_time", label = "-Time" },
		{ id = "sep" },
		{ id = "length", label = "Length" }, { id = "framerate", label = "FPS" }, { id = "priority", label = "Priority" }, { id = "loop", label = "Loop", toggle = true },
	}

	local x = px(4)
	local toolButtons = {}
	for _, data in ipairs(buttons) do
		if data.id == "sep" then
			Make("Frame", { BackgroundColor3 = COLORS.Border, BorderSizePixel = 0, Size = UDim2.new(0, 1, 0, px(20)), Position = UDim2.new(0, x, 0, px(6)), Parent = ui.toolbar })
			x += px(8)
		else
			local w = math.max(px(46), #data.label * px(7) + px(14))
			local btn = Make("TextButton", {
				Name = data.id .. "Btn", Text = data.label, Size = UDim2.new(0, w, 0, LAYOUT.ToolbarHeight - px(8)),
				Position = UDim2.new(0, x, 0, px(4)), Parent = ui.toolbar,
			})
			styleButton(btn, data.toggle)
			toolButtons[data.id] = btn
			x += w + px(4)
		end
	end
	ui.toolbar.CanvasSize = UDim2.new(0, x + px(8), 0, 0)

	local function setActiveTool(name)
		State.currentTool = name
		for _, tid in ipairs({ "rotate", "move", "grow" }) do
			toolButtons[tid]:SetAttribute("Selected", tid == name)
		end
		if ui.touchpad then ui.touchpad.Visible = (IS_TOUCH and State.selectedNode ~= nil) end
	end
	toolButtons.rotate.MouseButton1Click:Connect(function() setActiveTool("rotate") end)
	toolButtons.move.MouseButton1Click:Connect(function() setActiveTool("move") end)
	toolButtons.grow.MouseButton1Click:Connect(function() setActiveTool("grow") end)
	toolButtons.rotate:SetAttribute("Selected", true)

	toolButtons.new.MouseButton1Click:Connect(function()
		if showConfirmationDialog("Começar uma nova animação? Edições não salvas serão perdidas.") then
			State.keyframeList, State.currentTime, State.undoStack, State.redoStack = {}, 0, {}, {}
			Editor.createKeyframe(0, false)
			Editor.updateCursorPosition()
			ui.refresh()
		end
	end)
	toolButtons.save.MouseButton1Click:Connect(function()
		local name = showTextEntryDialog("Save Animation As:", "Animation")
		if name and name ~= "" then Editor.saveCurrentAnimation(name, false) end
	end)
	toolButtons.load.MouseButton1Click:Connect(function()
		local names = Editor.listSavedAnimations()
		if #names == 0 then showConfirmationDialog("Nenhuma animação salva ainda."); return end
		local options = {}
		for _, name in ipairs(names) do
			table.insert(options, { label = name, callback = function()
				Editor.loadAnimation(Editor.getSavedAnimation(name))
				ui.refresh()
			end })
		end
		showContextMenu(options, Vector2.new(mouse.X, mouse.Y))
	end)
	toolButtons.export.MouseButton1Click:Connect(function()
		local name = showTextEntryDialog("Export Name:", "Animation")
		if name and name ~= "" then Editor.saveCurrentAnimation(name, true) end
	end)
	toolButtons.undo.MouseButton1Click:Connect(function() Editor.undo(); ui.refresh() end)
	toolButtons.redo.MouseButton1Click:Connect(function() Editor.redo(); ui.refresh() end)
	toolButtons.snap:SetAttribute("Selected", State.snapEnabled)
	toolButtons.snap.MouseButton1Click:Connect(function() State.snapEnabled = not State.snapEnabled; toolButtons.snap:SetAttribute("Selected", State.snapEnabled) end)
	toolButtons.interp:SetAttribute("Selected", State.interpolationEnabled)
	toolButtons.interp.MouseButton1Click:Connect(function() State.interpolationEnabled = not State.interpolationEnabled; toolButtons.interp:SetAttribute("Selected", State.interpolationEnabled); Editor.updateCursorPosition() end)
	toolButtons.autokey.MouseButton1Click:Connect(function() toolButtons.autokey:SetAttribute("Selected", Editor.toggleAutoKey()) end)
	toolButtons.onionskin.MouseButton1Click:Connect(function() toolButtons.onionskin:SetAttribute("Selected", Editor.toggleOnionSkin()) end)
	toolButtons.keyframe_add.MouseButton1Click:Connect(function() Editor.captureCurrentPoseToKeyframe(); ui.refresh() end)
	toolButtons.keyframe_delete.MouseButton1Click:Connect(function() if State.currentTime > 0 then Editor.deleteKeyframe(State.currentTime, true); ui.refresh() end end)
	toolButtons.duplicate.MouseButton1Click:Connect(function()
		local kf = Editor.getKeyframe(State.currentTime)
		if kf then Editor.duplicateKeyframe(kf); ui.refresh() end
	end)
	toolButtons.copy.MouseButton1Click:Connect(function()
		local kf = Editor.getKeyframe(State.currentTime)
		if kf then
			Editor.resetCopyPoseList()
			for part, pose in pairs(kf.Poses) do Editor.copyPose(part, pose) end
		end
	end)
	toolButtons.paste.MouseButton1Click:Connect(function() Editor.pastePoses(); ui.refresh() end)
	toolButtons.mirror.MouseButton1Click:Connect(function() Editor.mirrorCurrentKeyframe(); ui.refresh() end)
	toolButtons.insert_time.MouseButton1Click:Connect(function()
		local v = tonumber(showTextEntryDialog("Insert seconds at cursor:", "0.5"))
		if v then Editor.insertTimeAtCursor(v); ui.refresh() end
	end)
	toolButtons.remove_time.MouseButton1Click:Connect(function()
		local v = tonumber(showTextEntryDialog("Remove seconds at cursor:", "0.5"))
		if v then Editor.removeTimeAtCursor(v); ui.refresh() end
	end)
	toolButtons.length.MouseButton1Click:Connect(function()
		local v = tonumber(showTextEntryDialog("Animation length (seconds):", tostring(State.animationLength)))
		if v then Editor.setAnimationLength(v); ui.refresh() end
	end)
	toolButtons.framerate.MouseButton1Click:Connect(function()
		local v = tonumber(showTextEntryDialog("Framerate (FPS):", tostring(math.floor(1 / State.frameStep))))
		if v then Editor.setFramerate(v) end
	end)
	toolButtons.priority.MouseButton1Click:Connect(function()
		local options = {}
		for _, p in ipairs({ "Idle", "Movement", "Action", "Core" }) do
			table.insert(options, { label = p, callback = function() Editor.setPriority(p) end })
		end
		showContextMenu(options, Vector2.new(mouse.X, mouse.Y))
	end)
	toolButtons.loop.MouseButton1Click:Connect(function()
		State.loopAnimation = not State.loopAnimation
		toolButtons.loop:SetAttribute("Selected", State.loopAnimation)
		Editor.setLooping(State.loopAnimation)
	end)

	ui.setActiveTool = setActiveTool
end

-- ---- Painel esquerdo: lista de partes (vira gaveta no mobile) --------------

local function createLeftPanel()
	local width = IS_SMALL_SCREEN and px(190) or LAYOUT.LeftPanelWidth
	ui.leftPanel = Make("Frame", {
		Name = "LeftPanel", BackgroundColor3 = COLORS.PanelDark, BorderColor3 = COLORS.Border, BorderSizePixel = 1,
		Size = UDim2.new(0, width, 1, -(LAYOUT.TitleBarHeight + LAYOUT.ToolbarHeight + LAYOUT.PlaybackHeight)),
		Position = UDim2.new(0, 0, 0, LAYOUT.TitleBarHeight + LAYOUT.ToolbarHeight),
		Visible = not IS_SMALL_SCREEN, ZIndex = IS_SMALL_SCREEN and 20 or 1,
		Parent = ui.mainWindow,
	})
	Make("TextLabel", {
		Text = "Parts", Font = FONT_BOLD, TextSize = px(12), TextColor3 = COLORS.Text, BackgroundColor3 = COLORS.Panel,
		Size = UDim2.new(1, 0, 0, px(20)), Parent = ui.leftPanel,
	})
	local list = Make("ScrollingFrame", {
		Name = "PartListScroll", BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -px(20)), Position = UDim2.new(0, 0, 0, px(20)),
		ScrollBarThickness = px(6), CanvasSize = UDim2.new(0, 0, 0, 0), Parent = ui.leftPanel,
	})

	local function refreshList()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local y = 0
		local rowH = px(24)
		local ordered = {}
		for part, node in pairs(State.partList) do table.insert(ordered, { part = part, node = node, line = State.partToLineNumber[part] or 0 }) end
		table.sort(ordered, function(a, b) return a.line < b.line end)

		for _, entry in ipairs(ordered) do
			local included = State.partInclude[entry.part.Name]
			local btn = Make("TextButton", {
				Text = "  " .. entry.part.Name, Font = FONT, TextSize = px(12), TextColor3 = COLORS.Text,
				BackgroundColor3 = included and COLORS.ButtonOn or COLORS.ButtonOff, BorderSizePixel = 0,
				Size = UDim2.new(1, -4, 0, rowH - 2), Position = UDim2.new(0, 2, 0, y), TextXAlignment = Enum.TextXAlignment.Left,
				Parent = list,
			})
			btn.MouseButton1Click:Connect(function()
				Editor.select(entry.node)
				if IS_SMALL_SCREEN then ui.leftPanel.Visible = false end
			end)
			y += rowH
		end
		list.CanvasSize = UDim2.new(0, 0, 0, y)
	end
	ui.refreshPartList = refreshList
end

-- ---- Timeline ----------------------------------------------------------------

local function createTimeline()
	local timelineHeight = math.max(LAYOUT.TimelineMinHeight, px(160))
	ui.timelinePanel = Make("Frame", {
		Name = "TimelinePanel", BackgroundColor3 = COLORS.Background, BorderColor3 = COLORS.Border, BorderSizePixel = 1,
		Size = UDim2.new(1, -(LAYOUT.LeftPanelWidth + LAYOUT.RightPanelWidth), 0, timelineHeight),
		Position = UDim2.new(0, LAYOUT.LeftPanelWidth, 0, LAYOUT.TitleBarHeight + LAYOUT.ToolbarHeight),
		ClipsDescendants = true, Parent = ui.mainWindow,
	})

	local scroll = Make("ScrollingFrame", {
		Name = "KeyframeContainer", BackgroundColor3 = COLORS.Background, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 1600, 1, 0),
		ScrollBarThickness = px(6), ScrollingDirection = Enum.ScrollingDirection.X, Parent = ui.timelinePanel,
	})

	local ruler = Make("Frame", { Name = "Ruler", BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, px(16)), Parent = scroll })
	local track = Make("TextButton", {
		Name = "Track", Text = "", AutoButtonColor = false, BackgroundColor3 = COLORS.Panel, BackgroundTransparency = 0.6,
		BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -px(16)), Position = UDim2.new(0, 0, 0, px(16)), Parent = scroll,
	})

	local cursorLine = Make("Frame", {
		Name = "CursorLine", BackgroundColor3 = COLORS.Accent, BorderSizePixel = 0,
		Size = UDim2.new(0, px(2), 1, 0), Position = UDim2.new(0, 0, 0, 0), ZIndex = 5, Parent = scroll,
	})

	local function pixelsPerSecond()
		return scroll.CanvasSize.X.Offset / math.max(0.001, State.animationLength)
	end

	local function timeFromX(absoluteX)
		local relX = absoluteX - track.AbsolutePosition.X + scroll.CanvasPosition.X
		return math.clamp(relX / pixelsPerSecond(), 0, State.animationLength)
	end

	local function moveCursorTo(t)
		State.currentTime = clampTime(t)
		cursorLine.Position = UDim2.new(0, State.currentTime * pixelsPerSecond(), 0, 0)
		Editor.updateCursorPosition()
		if ui.updateTimeLabel then ui.updateTimeLabel() end
	end

	local scrubbing = false
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			scrubbing = true
			moveCursorTo(timeFromX(input.Position.X))
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if scrubbing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			moveCursorTo(timeFromX(input.Position.X))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			scrubbing = false
		end
	end)

	-- Pinch-to-zoom (dois dedos) para telas de toque
	if IS_TOUCH then
		local activeTouches = {}
		UserInputService.TouchPinch:Connect(function(touchPositions, scaleDelta, velocityDelta, state)
			if state == Enum.UserInputState.Change then
				State.zoomLevel = math.clamp(State.zoomLevel * scaleDelta, 0.5, 6)
				scroll.CanvasSize = UDim2.new(0, 1600 * State.zoomLevel, 1, 0)
			end
		end)
	end

	local function refreshKeyframes()
		for _, c in ipairs(track:GetChildren()) do if c.Name:match("^Kf_") then c:Destroy() end end
		local pps = pixelsPerSecond()
		local diamondSize = px(16)
		for time, kf in pairs(State.keyframeList) do
			local xPos = time * pps
			local selected = State.selectedKeyframes[time]
			local btn = Make("TextButton", {
				Name = "Kf_" .. tostring(time), Text = "", BackgroundColor3 = selected and COLORS.KeyframeSelected or COLORS.Keyframe,
				Rotation = 45, Size = UDim2.new(0, diamondSize, 0, diamondSize),
				Position = UDim2.new(0, xPos - diamondSize / 2, 0, px(6)), Parent = track, ZIndex = 3,
			})
			btn.MouseButton1Click:Connect(function()
				State.selectedKeyframe = kf
				State.selectedKeyframes = { [time] = true }
				moveCursorTo(time)
				if ui.updateProperties then ui.updateProperties() end
				refreshKeyframes()
			end)
			-- Long-press / clique direito = menu de contexto (funciona em touch como "toque e segure" simulado por tempo mínimo)
			local pressStart = 0
			btn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					pressStart = tick()
				end
			end)
			btn.InputEnded:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and tick() - pressStart > 0.45 then
					local options = {
						{ label = "Duplicate", callback = function() Editor.duplicateKeyframe(kf); ui.refresh() end },
						{ label = "Mirror", callback = function() Editor.mirrorCurrentKeyframe(); ui.refresh() end },
						{ label = "Delete", callback = function() if time > 0 then Editor.deleteKeyframe(time, true); ui.refresh() end end },
					}
					showContextMenu(options, Vector2.new(input.Position.X, input.Position.Y))
				end
			end)
			btn.MouseButton2Click:Connect(function()
				local options = {
					{ label = "Duplicate", callback = function() Editor.duplicateKeyframe(kf); ui.refresh() end },
					{ label = "Mirror", callback = function() Editor.mirrorCurrentKeyframe(); ui.refresh() end },
					{ label = "Delete", callback = function() if time > 0 then Editor.deleteKeyframe(time, true); ui.refresh() end end },
				}
				showContextMenu(options, Vector2.new(mouse.X, mouse.Y))
			end)
		end
	end

	local function refreshRuler()
		for _, c in ipairs(ruler:GetChildren()) do c:Destroy() end
		local pps = pixelsPerSecond()
		local ticks = math.max(4, math.floor(State.animationLength / State.frameStep / 6))
		for i = 0, ticks do
			local t = (i / ticks) * State.animationLength
			Make("TextLabel", {
				Text = string.format("%.2f", t), Font = FONT_MONO, TextSize = px(9), TextColor3 = COLORS.TextDark,
				BackgroundTransparency = 1, Size = UDim2.new(0, px(34), 1, 0), Position = UDim2.new(0, t * pps, 0, 0), Parent = ruler,
			})
		end
	end

	local function zoomToFit()
		State.zoomLevel = 1
		scroll.CanvasSize = UDim2.new(0, 1600, 1, 0)
		refreshRuler()
		refreshKeyframes()
		moveCursorTo(State.currentTime)
	end

	ui.refreshTimeline = function()
		refreshRuler()
		refreshKeyframes()
		cursorLine.Position = UDim2.new(0, State.currentTime * pixelsPerSecond(), 0, 0)
	end
	ui.zoomToFit = zoomToFit
	zoomToFit()
end

-- ---- Touchpad virtual (rotate/move/grow no toque) ---------------------------

local function createTouchpad()
	if not IS_TOUCH then return end
	ui.touchpad = Make("Frame", {
		Name = "ToolTouchpad", BackgroundColor3 = COLORS.PanelDark, BackgroundTransparency = 0.15, BorderColor3 = COLORS.Border, BorderSizePixel = 1,
		Size = UDim2.new(0, LAYOUT.TouchPadSize, 0, LAYOUT.TouchPadSize),
		Position = UDim2.new(1, -LAYOUT.TouchPadSize - px(10), 1, -LAYOUT.TouchPadSize - LAYOUT.PlaybackHeight - px(10)),
		Visible = false, ZIndex = 15, Parent = ui.mainWindow,
	})
	Make("TextLabel", {
		Text = "arraste para editar", Font = FONT, TextSize = px(10), TextColor3 = COLORS.TextDark, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, px(14)), Position = UDim2.new(0, 0, 1, -px(14)), Parent = ui.touchpad,
	})

	local dragging = false
	local lastPos = Vector2.new()
	ui.touchpad.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			lastPos = Vector2.new(input.Position.X, input.Position.Y)
			Editor.lockUndoStep(State.currentTool)
			Editor.registerUndo({ action = State.currentTool })
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local pos = Vector2.new(input.Position.X, input.Position.Y)
			local delta = pos - lastPos
			lastPos = pos

			if State.currentTool == "rotate" then
				Editor.onToolDrag(Vector2.new(delta.X * 0.5, delta.Y * 0.5))
			elseif State.currentTool == "move" then
				Editor.onToolDrag(Vector3.new(delta.X * 0.02, -delta.Y * 0.02, 0))
			elseif State.currentTool == "grow" then
				local factor = 1 + (-delta.Y) * 0.003
				Editor.onToolDrag(factor)
			end
			Editor.lockUndoStep(State.currentTool)
			if ui.refreshTimeline then ui.refreshTimeline() end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	Editor.onSelectionChanged(function(node)
		ui.touchpad.Visible = node ~= nil
	end)
end

-- ---- Painel direito: propriedades (vira gaveta no mobile) -------------------

local function createRightPanel()
	local width = IS_SMALL_SCREEN and px(220) or LAYOUT.RightPanelWidth
	ui.rightPanel = Make("Frame", {
		Name = "RightPanel", BackgroundColor3 = COLORS.PanelDark, BorderColor3 = COLORS.Border, BorderSizePixel = 1,
		Size = UDim2.new(0, width, 1, -(LAYOUT.TitleBarHeight + LAYOUT.ToolbarHeight + LAYOUT.PlaybackHeight)),
		Position = UDim2.new(1, -width, 0, LAYOUT.TitleBarHeight + LAYOUT.ToolbarHeight),
		Visible = not IS_SMALL_SCREEN, ZIndex = IS_SMALL_SCREEN and 20 or 1,
		Parent = ui.mainWindow,
	})
	Make("TextLabel", { Text = "Properties", Font = FONT_BOLD, TextSize = px(12), TextColor3 = COLORS.Text, BackgroundColor3 = COLORS.Panel, Size = UDim2.new(1, 0, 0, px(20)), Parent = ui.rightPanel })
	local scroll = Make("ScrollingFrame", {
		Name = "PropsScroll", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -px(20)), Position = UDim2.new(0, 0, 0, px(20)),
		ScrollBarThickness = px(6), CanvasSize = UDim2.new(0, 0, 0, 300), Parent = ui.rightPanel,
	})

	local function field(label, value, y)
		Make("TextLabel", { Text = label, Font = FONT, TextSize = px(11), TextColor3 = COLORS.TextDark, BackgroundTransparency = 1, Size = UDim2.new(0.45, 0, 0, px(18)), Position = UDim2.new(0, 4, 0, y), Parent = scroll })
		Make("TextLabel", { Text = tostring(value), Font = FONT_MONO, TextSize = px(11), TextColor3 = COLORS.Text, BackgroundTransparency = 1, Size = UDim2.new(0.55, -4, 0, px(18)), Position = UDim2.new(0.45, 0, 0, y), Parent = scroll })
	end

	local function refreshProperties()
		for _, c in ipairs(scroll:GetChildren()) do c:Destroy() end
		local y = px(4)
		field("Frame", State.currentTime, y); y += px(20)
		field("Length", State.animationLength, y); y += px(20)
		field("FPS", math.floor(1 / State.frameStep), y); y += px(20)
		field("Priority", State.animationPriority, y); y += px(26)

		if State.selectedNode then
			local part = State.selectedNode.Part
			field("Part", part.Name, y); y += px(20)
			local kf = Editor.getKeyframe(State.currentTime)
			local pose = kf and kf.Poses[part]
			if pose then
				local pos = pose.CFrame.Position
				field("Pos X", string.format("%.2f", pos.X), y); y += px(18)
				field("Pos Y", string.format("%.2f", pos.Y), y); y += px(18)
				field("Pos Z", string.format("%.2f", pos.Z), y); y += px(18)

				local easingBtn = Make("TextButton", {
					Text = "Easing: " .. (pose.EasingStyle and pose.EasingStyle.Name or "Linear"),
					Size = UDim2.new(1, -8, 0, px(24)), Position = UDim2.new(0, 4, 0, y), Parent = scroll,
				})
				styleButton(easingBtn)
				easingBtn.MouseButton1Click:Connect(function()
					local styles = { "Linear", "Constant", "Cubic", "CubicV2", "Elastic", "Bounce" }
					local options = {}
					for _, s in ipairs(styles) do
						table.insert(options, { label = s, callback = function()
							pose.EasingStyle = Enum.PoseEasingStyle[s]
							refreshProperties()
						end })
					end
					showContextMenu(options, Vector2.new(mouse.X, mouse.Y))
				end)
				y += px(30)
			else
				field("Pose", "sem keyframe aqui", y); y += px(20)
			end
		else
			field("Seleção", "nenhuma parte", y); y += px(20)
		end

		scroll.CanvasSize = UDim2.new(0, 0, 0, y + px(10))
	end
	ui.updateProperties = refreshProperties
	Editor.onSelectionChanged(refreshProperties)
end

-- ---- Playback bar --------------------------------------------------------

local function createPlaybackBar()
	ui.playbackBar = Make("Frame", {
		Name = "PlaybackBar", BackgroundColor3 = COLORS.Panel, BorderColor3 = COLORS.Border, BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, LAYOUT.PlaybackHeight), Position = UDim2.new(0, 0, 1, -LAYOUT.PlaybackHeight), Parent = ui.mainWindow,
	})

	local btnSize = px(34)
	local x = px(4)
	local function navBtn(label, callback)
		local b = Make("TextButton", { Text = label, Size = UDim2.new(0, btnSize, 0, btnSize), Position = UDim2.new(0, x, 0, (LAYOUT.PlaybackHeight - btnSize) / 2), Parent = ui.playbackBar })
		styleButton(b)
		b.MouseButton1Click:Connect(callback)
		x += btnSize + px(4)
		return b
	end

	navBtn("|<", function() State.currentTime = 0; Editor.updateCursorPosition(); ui.refresh() end)
	navBtn("<", function() State.currentTime = math.max(0, State.currentTime - State.frameStep); Editor.updateCursorPosition(); ui.refresh() end)
	local playBtn = navBtn(">", function()
		if State.playing then Editor.stop() else Editor.play() end
	end)
	navBtn(">", function() State.currentTime = math.min(State.animationLength, State.currentTime + State.frameStep); Editor.updateCursorPosition(); ui.refresh() end)
	navBtn(">|", function() State.currentTime = State.animationLength; Editor.updateCursorPosition(); ui.refresh() end)

	local timeLabel = Make("TextLabel", {
		Text = "0.00 / 2.00", Font = FONT_MONO, TextSize = px(12), TextColor3 = COLORS.Text, BackgroundTransparency = 1,
		Size = UDim2.new(0, px(120), 1, 0), Position = UDim2.new(0, x + px(6), 0, 0), Parent = ui.playbackBar,
	})

	-- Botões de gaveta (só aparecem no mobile) pra abrir/fechar os painéis
	if IS_SMALL_SCREEN then
		local partsBtn = Make("TextButton", { Text = "Parts", Size = UDim2.new(0, px(60), 0, btnSize), Position = UDim2.new(1, -px(190), 0, (LAYOUT.PlaybackHeight - btnSize) / 2), Parent = ui.playbackBar })
		styleButton(partsBtn)
		partsBtn.MouseButton1Click:Connect(function() ui.leftPanel.Visible = not ui.leftPanel.Visible; ui.rightPanel.Visible = false end)

		local propsBtn = Make("TextButton", { Text = "Props", Size = UDim2.new(0, px(60), 0, btnSize), Position = UDim2.new(1, -px(125), 0, (LAYOUT.PlaybackHeight - btnSize) / 2), Parent = ui.playbackBar })
		styleButton(propsBtn)
		propsBtn.MouseButton1Click:Connect(function() ui.rightPanel.Visible = not ui.rightPanel.Visible; ui.leftPanel.Visible = false end)
	end

	local fitBtn = Make("TextButton", { Text = "Fit", Size = UDim2.new(0, px(50), 0, btnSize), Position = UDim2.new(1, -px(60), 0, (LAYOUT.PlaybackHeight - btnSize) / 2), Parent = ui.playbackBar })
	styleButton(fitBtn)
	fitBtn.MouseButton1Click:Connect(function() if ui.zoomToFit then ui.zoomToFit() end end)

	ui.updateTimeLabel = function()
		timeLabel.Text = string.format("%.2f / %.2f", State.currentTime, State.animationLength)
		playBtn.Text = State.playing and "||" or ">"
	end
end

-- ---- Refresh geral ---------------------------------------------------------

function ui.refresh()
	if ui.refreshPartList then ui.refreshPartList() end
	if ui.refreshTimeline then ui.refreshTimeline() end
	if ui.updateProperties then ui.updateProperties() end
	if ui.updateTimeLabel then ui.updateTimeLabel() end
end

-- ============================================================================
-- SEÇÃO 11: SELEÇÃO POR TOQUE/CLIQUE NO VIEWPORT
-- ============================================================================

local function setupViewportSelection()
	local function tryHandle(input)
		if State.modal then return end
		local guiInset = game:GetService("GuiService"):GetGuiInset()
		local x, y = input.Position.X, input.Position.Y - guiInset.Y
		local node = raycastToPart(x, y)
		if node then Editor.select(node) end
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tryHandle(input)
		end
	end)
end

-- ============================================================================
-- SEÇÃO 12: HOOKS DE ATUALIZAÇÃO CRUZADA
-- ============================================================================

State.onRefresh = function() ui.refresh() end
State.onCursorUpdate = function() if ui.updateTimeLabel then ui.updateTimeLabel() end end

Editor.onSelectionChanged(function(node)
	if ui.setActiveTool then ui.setActiveTool(State.currentTool) end
end)

-- ============================================================================
-- SEÇÃO 13: BUILD DA UI + INICIALIZAÇÃO
-- ============================================================================

function Editor.buildUI(screenGui)
	createMainWindow(screenGui)
	createTitleBar()
	createToolbar()
	createLeftPanel()
	createTimeline()
	createTouchpad()
	createRightPanel()
	createPlaybackBar()
	setupViewportSelection()
	ui.refresh()
end

-- Cria a ScreenGui automaticamente se este script estiver solto numa
-- ScreenGui (comportamento padrão); senão, use Editor.buildUI(minhaScreenGui).
local hostScreenGui = script:FindFirstAncestorOfClass("ScreenGui")
if not hostScreenGui then
	hostScreenGui = Make("ScreenGui", { Name = "AnimationEditorGui", ResetOnSpawn = false, Parent = playerGui })
end

if player.Character then
	Editor.init(player.Character)
end

Editor.buildUI(hostScreenGui)

_G.AnimationEditor = Editor -- opcional, pra debug via console
return Editor