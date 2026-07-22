--[[
    ============================================================================
    MOON ANIMATOR CLASSIC - INTERFACE (UI) COMPLETA
    ============================================================================
    Editor de Animações para Roblox - Apenas a Interface
    Estilo visual: Moon Animator Clássico (2014-2016)
    
    INSTRUÇÕES:
    1. Criar uma ScreenGui em StarterGui
    2. Colocar este LocalScript dentro da ScreenGui
    3. Conectar as funções do sistema de animação existente
    ============================================================================
]]

-- ============================================================================
-- SEÇÃO 1: CONFIGURAÇÕES E CONSTANTES
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

-- Cores do estilo Moon Animator Clássico
local COLORS = {
	Background = Color3.new(0.08, 0.08, 0.08),           -- Fundo principal
	Panel = Color3.new(0.196, 0.196, 0.196),              -- Painéis
	PanelDark = Color3.new(0.12, 0.12, 0.12),             -- Painéis escuros
	ButtonOn = Color3.new(0.784, 0.784, 0.784),           -- Botão ativo
	ButtonOff = Color3.new(0.196, 0.196, 0.196),          -- Botão inativo
	ButtonHover = Color3.new(0.5, 0.5, 0.5),              -- Hover
	ButtonPress = Color3.new(0.3, 0.3, 0.3),              -- Pressionado
	Text = Color3.new(0.866, 0.866, 0.866),               -- Texto principal
	TextDark = Color3.new(0.6, 0.6, 0.6),                 -- Texto secundário
	Accent = Color3.new(0.2, 0.5, 1),                     -- Azul destaque
	Cursor = Color3.new(1, 0.2, 0.2),                     -- Cursor vermelho
	TimelineBg = Color3.new(0.082, 0.082, 0.082),         -- Fundo timeline
	TimelineLine = Color3.new(0.784, 0.784, 0.784),       -- Linha timeline
	TimelineGrid = Color3.new(0.15, 0.15, 0.15),          -- Grade timeline
	Keyframe = Color3.new(0, 0.7, 0),                     -- Keyframe (verde)
	KeyframeSelected = Color3.new(0.588, 0.588, 0.784),   -- Keyframe selecionado
	SelectedLine = Color3.new(0.784, 0.784, 0.588),       -- Linha seleção
	TitleBar = Color3.new(0.15, 0.15, 0.15),              -- Barra título
	CloseButton = Color3.new(0.658, 0.133, 0.133),        -- Botão fechar
	Separator = Color3.new(0.3, 0.3, 0.3),                -- Separadores
	Border = Color3.new(0.345, 0.345, 0.345),             -- Bordas
	TooltipBg = Color3.new(0.15, 0.15, 0.15),             -- Fundo tooltip
	MenuBg = Color3.new(0.082, 0.082, 0.082),             -- Fundo menu
	MenuItemBg = Color3.new(0.266, 0.266, 0.266),         -- Item menu
	MenuItemHover = Color3.new(0.4, 0.4, 0.4),            -- Item menu hover
	DialogBg = Color3.new(0.082, 0.082, 0.082),           -- Dialog
	DialogButton = Color3.new(0.392, 0.392, 0.588),       -- Botão dialog
	InputBg = Color3.new(0.392, 0.392, 0.392),            -- Input background
}

-- Configurações de fonte
local FONT_SETTINGS = {
	TextLarge = Enum.FontSize.Size24,
	TextMed = Enum.FontSize.Size18,
	TextSmall = Enum.FontSize.Size14,
	TextTiny = Enum.FontSize.Size10,
	Font = Enum.Font.Arial,
	FontBold = Enum.Font.ArialBold,
}

-- Dimensões da janela
local WINDOW = {
	MinWidth = 600,
	MinHeight = 400,
	DefaultWidth = 1000,
	DefaultHeight = 600,
	TitleBarHeight = 22,
	ToolbarHeight = 28,
	PlaybackHeight = 32,
	LeftPanelWidth = 160,
	RightPanelWidth = 200,
	TimelineHeight = 240,
}

-- Estados da UI
local uiState = {
	isPlaying = false,
	isLooping = false,
	currentTime = 0,
	animationLength = 2,
	zoomLevel = 1,
	selectedTool = "rotate", -- "rotate" ou "move"
	selectedSpace = "local", -- "local" ou "world"
	snapping = true,
	interpolation = true,
	selectedKeyframes = {},
	selectedParts = {},
	rotateStep = 0,
	moveStep = 0,
	isDragging = false,
	isResizing = false,
	modal = false,
	tooltipVisible = false,
	menuOpen = false,
}

-- Referências aos elementos UI
local ui = {
	mainWindow = nil,
	titleBar = nil,
	toolbar = nil,
	leftPanel = nil,
	timelinePanel = nil,
	playbackBar = nil,
	rightPanel = nil,
	statusBar = nil,
	cursor = nil,
	tooltip = nil,
	contextMenu = nil,
	dialogOverlay = nil,
}

-- ============================================================================
-- SEÇÃO 2: FUNÇÃO MAKE() - CRIADOR DE INSTÂNCIAS
-- ============================================================================

--[[
	Make(className, properties)
	Cria uma instância e aplica propriedades.
	Propriedades numéricas (índices) são tratadas como filhos (Parent).
]]
local function Make(className, properties)
	local instance = Instance.new(className)
	for key, value in pairs(properties) do
		if type(key) == "number" then
			value.Parent = instance
		else
			instance[key] = value
		end
	end
	return instance
end

-- ============================================================================
-- SEÇÃO 3: UTILITÁRIOS DE UI
-- ============================================================================

--[[
	Aplica estilo de botão clássico (sem UICorner, sem gradiente)
]]
local function styleButton(button, isToggle)
	button.BackgroundColor3 = COLORS.ButtonOff
	button.BorderColor3 = COLORS.Border
	button.BorderSizePixel = 1
	button.BackgroundTransparency = 0
	button.TextColor3 = COLORS.Text
	button.Font = FONT_SETTINGS.Font
	button.TextSize = 12
	button.AutoButtonColor = false
	
	local function updateVisual()
		if isToggle and button:GetAttribute("Selected") then
			button.BackgroundColor3 = COLORS.ButtonOn
			button.TextColor3 = Color3.new(0.1, 0.1, 0.1)
		else
			button.BackgroundColor3 = COLORS.ButtonOff
			button.TextColor3 = COLORS.Text
		end
	end
	
	button.MouseEnter:Connect(function()
		if not (isToggle and button:GetAttribute("Selected")) then
			button.BackgroundColor3 = COLORS.ButtonHover
		end
	end)
	
	button.MouseLeave:Connect(function()
		updateVisual()
	end)
	
	button.MouseButton1Down:Connect(function()
		button.BackgroundColor3 = COLORS.ButtonPress
	end)
	
	button.MouseButton1Up:Connect(function()
		updateVisual()
	end)
	
	if isToggle then
		button:SetAttribute("Selected", false)
		button:GetAttributeChangedSignal("Selected"):Connect(updateVisual)
	end
	
	return button
end

--[[
	Cria um ícone simples usando TextLabel (sem imagens externas)
]]
local function createIcon(name, size)
	local iconMap = {
		["new"] = "+",
		["open"] = "📂",
		["save"] = "💾",
		["export"] = "⬆",
		["import"] = "⬇",
		["play"] = "▶",
		["pause"] = "⏸",
		["stop"] = "⏹",
		["loop"] = "🔄",
		["undo"] = "↩",
		["redo"] = "↪",
		["rotate"] = "↻",
		["move"] = "✥",
		["scale"] = "⤢",
		["local_space"] = "L",
		["world_space"] = "W",
		["snap"] = "⚲",
		["interpolate"] = "~",
		["mirror"] = "⇄",
		["reset"] = "↺",
		["bone_add"] = "+B",
		["bone_remove"] = "-B",
		["keyframe_add"] = "+K",
		["keyframe_delete"] = "-K",
		["keyframe_duplicate"] = "D",
		["copy"] = "📋",
		["paste"] = "📌",
		["zoom_in"] = "+",
		["zoom_out"] = "-",
		["first_frame"] = "|◀",
		["prev_frame"] = "◀",
		["next_frame"] = "▶",
		["last_frame"] = "▶|",
		["settings"] = "⚙",
		["close"] = "X",
		["minimize"] = "_",
		["maximize"] = "□",
	}
	
	return Make("TextLabel", {
		Name = name .. "Icon",
		Text = iconMap[name] or "?",
		Font = FONT_SETTINGS.FontBold,
		TextSize = 10,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, size, 0, size),
		Position = UDim2.new(0.5, -size/2, 0.5, -size/2),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
end

-- ============================================================================
-- SEÇÃO 4: TOOLTIP SYSTEM
-- ============================================================================

local function createTooltipSystem()
	ui.tooltip = Make("Frame", {
		Name = "Tooltip",
		BackgroundColor3 = COLORS.TooltipBg,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 150, 0, 20),
		Position = UDim2.new(0, 0, 0, 0),
		Visible = false,
		ZIndex = 100,
		Make("TextLabel", {
			Name = "TooltipText",
			Font = FONT_SETTINGS.Font,
			TextSize = 11,
			TextColor3 = COLORS.Text,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 1, 0),
			Position = UDim2.new(0, 2, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
	})
	ui.tooltip.Parent = ui.mainWindow
end

local function showTooltip(text, position)
	if not ui.tooltip then return end
	ui.tooltip.TooltipText.Text = text
	ui.tooltip.Size = UDim2.new(0, #text * 7 + 10, 0, 20)
	ui.tooltip.Position = UDim2.new(0, position.X + 15, 0, position.Y + 15)
	ui.tooltip.Visible = true
	uiState.tooltipVisible = true
end

local function hideTooltip()
	if ui.tooltip then
		ui.tooltip.Visible = false
		uiState.tooltipVisible = false
	end
end

local function attachTooltip(element, text)
	element.MouseEnter:Connect(function()
		if text and text ~= "" then
			showTooltip(text, Vector2.new(mouse.X, mouse.Y))
		end
	end)
	element.MouseLeave:Connect(function()
		hideTooltip()
	end)
	element.MouseMoved:Connect(function()
		if uiState.tooltipVisible then
			showTooltip(text, Vector2.new(mouse.X, mouse.Y))
		end
	end)
end

-- ============================================================================
-- SEÇÃO 5: MENU DE CONTEXTO
-- ============================================================================

local function closeContextMenu()
	if ui.contextMenu then
		ui.contextMenu:Destroy()
		ui.contextMenu = nil
	end
	uiState.menuOpen = false
	uiState.modal = false
end

local function showContextMenu(options, position)
	closeContextMenu()
	uiState.modal = true
	uiState.menuOpen = true
	
	local menuHeight = #options * 22 + 4
	ui.contextMenu = Make("Frame", {
		Name = "ContextMenu",
		BackgroundColor3 = COLORS.MenuBg,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 140, 0, menuHeight),
		Position = UDim2.new(0, position.X, 0, position.Y),
		ZIndex = 50,
	})
	
	for i, option in ipairs(options) do
		local btn = Make("TextButton", {
			Name = option.name .. "Option",
			Text = option.label,
			Font = FONT_SETTINGS.Font,
			TextSize = 12,
			TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.MenuItemBg,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -4, 0, 20),
			Position = UDim2.new(0, 2, 0, (i-1) * 22 + 2),
			ZIndex = 51,
			Parent = ui.contextMenu,
		})
		
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = COLORS.MenuItemHover
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = COLORS.MenuItemBg
		end)
		btn.MouseButton1Click:Connect(function()
			if option.callback then
				option.callback()
			end
			closeContextMenu()
		end)
	end
	
	ui.contextMenu.Parent = ui.mainWindow
end

-- ============================================================================
-- SEÇÃO 6: DIALOGS (showTextEntryDialog / showConfirmationDialog)
-- ============================================================================

--[[
	Exibe um dialog de entrada de texto.
	Chama a função existente se disponível, senão cria um interno.
]]
function showTextEntryDialog(title, defaultText)
	-- Se a função global existir, usa ela
	if _G.showTextEntryDialog then
		return _G.showTextEntryDialog(title, defaultText)
	end
	
	-- Implementação interna
	uiState.modal = true
	local result = nil
	local confirmed = false
	
	local dialog = Make("Frame", {
		Name = "TextEntryDialog",
		BackgroundColor3 = COLORS.DialogBg,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 400, 0, 105),
		Position = UDim2.new(0.5, -200, 0.5, -52),
		ZIndex = 200,
		Make("TextLabel", {
			Name = "Title",
			Text = title,
			Font = FONT_SETTINGS.FontBold,
			TextSize = 14,
			TextColor3 = COLORS.Text,
			BackgroundTransparency = 1,
			Position = UDim2.new(0.05, 0, 0, 5),
			Size = UDim2.new(0.9, 0, 0, 15),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 201,
		}),
		Make("Frame", {
			Name = "InputFrame",
			BackgroundColor3 = COLORS.InputBg,
			BorderColor3 = COLORS.Border,
			BorderSizePixel = 1,
			Position = UDim2.new(0.05, 0, 0, 25),
			Size = UDim2.new(0.9, 0, 0, 30),
			ZIndex = 201,
			Make("TextBox", {
				Name = "InputBox",
				Text = defaultText or "",
				Font = FONT_SETTINGS.FontBold,
				TextSize = 14,
				TextColor3 = COLORS.Text,
				BackgroundTransparency = 1,
				Position = UDim2.new(0.05, 0, 0, 0),
				Size = UDim2.new(0.9, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				ZIndex = 202,
			})
		}),
		Make("TextButton", {
			Name = "OKButton",
			Text = "OK",
			Font = FONT_SETTINGS.FontBold,
			TextSize = 14,
			TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.DialogButton,
			BorderSizePixel = 0,
			Position = UDim2.new(0.05, 0, 0, 65),
			Size = UDim2.new(0.4, 0, 0, 30),
			ZIndex = 201,
		}),
		Make("TextButton", {
			Name = "CancelButton",
			Text = "Cancel",
			Font = FONT_SETTINGS.FontBold,
			TextSize = 14,
			TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.DialogButton,
			BorderSizePixel = 0,
			Position = UDim2.new(0.55, 0, 0, 65),
			Size = UDim2.new(0.4, 0, 0, 30),
			ZIndex = 201,
		}),
	})
	
	dialog.Parent = ui.mainWindow
	
	local function cleanup()
		dialog:Destroy()
		uiState.modal = false
	end
	
	dialog.OKButton.MouseButton1Click:Connect(function()
		result = dialog.InputFrame.InputBox.Text
		confirmed = true
		cleanup()
	end)
	
	dialog.CancelButton.MouseButton1Click:Connect(function()
		result = nil
		confirmed = true
		cleanup()
	end)
	
	-- Aguarda confirmação (bloqueante simulado)
	repeat task.wait(0.1) until confirmed
	return result
end

--[[
	Exibe um dialog de confirmação.
	Chama a função global existente se disponível.
]]
function showConfirmationDialog(message)
	if _G.showConfirmationDialog then
		return _G.showConfirmationDialog(message)
	end
	
	uiState.modal = true
	local result = false
	local confirmed = false
	
	local dialog = Make("Frame", {
		Name = "ConfirmDialog",
		BackgroundColor3 = COLORS.DialogBg,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 400, 0, 105),
		Position = UDim2.new(0.5, -200, 0.5, -52),
		ZIndex = 200,
		Make("TextLabel", {
			Name = "Message",
			Text = message,
			Font = FONT_SETTINGS.FontBold,
			TextSize = 14,
			TextColor3 = COLORS.Text,
			BackgroundTransparency = 1,
			Position = UDim2.new(0.05, 0, 0, 5),
			Size = UDim2.new(0.9, 0, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 201,
		}),
		Make("TextButton", {
			Name = "OKButton",
			Text = "OK",
			Font = FONT_SETTINGS.FontBold,
			TextSize = 14,
			TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.DialogButton,
			BorderSizePixel = 0,
			Position = UDim2.new(0.05, 0, 0, 55),
			Size = UDim2.new(0.4, 0, 0, 30),
			ZIndex = 201,
		}),
		Make("TextButton", {
			Name = "CancelButton",
			Text = "Cancel",
			Font = FONT_SETTINGS.FontBold,
			TextSize = 14,
			TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.DialogButton,
			BorderSizePixel = 0,
			Position = UDim2.new(0.55, 0, 0, 55),
			Size = UDim2.new(0.4, 0, 0, 30),
			ZIndex = 201,
		}),
	})
	
	dialog.Parent = ui.mainWindow
	
	local function cleanup()
		dialog:Destroy()
		uiState.modal = false
	end
	
	dialog.OKButton.MouseButton1Click:Connect(function()
		result = true
		confirmed = true
		cleanup()
	end)
	
	dialog.CancelButton.MouseButton1Click:Connect(function()
		result = false
		confirmed = true
		cleanup()
	end)
	
	repeat task.wait(0.1) until confirmed
	return result
end

-- ============================================================================
-- SEÇÃO 7: DROPDOWN MENU (displayDropDownMenu)
-- ============================================================================

--[[
	Exibe um dropdown menu.
	Integra com a função global existente se disponível.
]]
function displayDropDownMenu(items, x, y)
	if _G.displayDropDownMenu then
		return _G.displayDropDownMenu(items, x, y)
	end
	
	-- Implementação interna
	local options = {}
	for _, item in ipairs(items) do
		table.insert(options, {
			name = item,
			label = item,
			callback = function()
				-- Retorna o item selecionado via variável temporária
				-- Na prática, o callback seria tratado pelo chamador
			end
		})
	end
	
	showContextMenu(options, Vector2.new(x, y))
	return nil -- Simplificado - na implementação real retornaria o item
end

-- ============================================================================
-- SEÇÃO 8: JANELA PRINCIPAL (Main Window)
-- ============================================================================

local function createMainWindow()
	ui.mainWindow = Make("Frame", {
		Name = "AnimationEditorWindow",
		BackgroundColor3 = COLORS.Background,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, WINDOW.DefaultWidth, 0, WINDOW.DefaultHeight),
		Position = UDim2.new(0.5, -WINDOW.DefaultWidth/2, 0.5, -WINDOW.DefaultHeight/2),
		ClipsDescendants = true,
		Active = true,
		Draggable = true, -- Roblox nativo drag
	})
	
	ui.mainWindow.Parent = script.Parent -- ScreenGui
end

-- ============================================================================
-- SEÇÃO 9: BARRA DE TÍTULO (Title Bar)
-- ============================================================================

local function createTitleBar()
	ui.titleBar = Make("Frame", {
		Name = "TitleBar",
		BackgroundColor3 = COLORS.TitleBar,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, WINDOW.TitleBarHeight),
		Position = UDim2.new(0, 0, 0, 0),
		Active = true,
		Parent = ui.mainWindow,
	})
	
	-- Título
	Make("TextLabel", {
		Name = "TitleText",
		Text = "Animation Editor",
		Font = FONT_SETTINGS.FontBold,
		TextSize = 12,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 5, 0, 0),
		Size = UDim2.new(0, 200, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ui.titleBar,
	})
	
	-- Botão Minimizar
	local minimizeBtn = Make("TextButton", {
		Name = "MinimizeButton",
		Text = "_",
		Font = FONT_SETTINGS.FontBold,
		TextSize = 12,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.ButtonOff,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 20, 0, 18),
		Position = UDim2.new(1, -65, 0, 2),
		Parent = ui.titleBar,
	})
	styleButton(minimizeBtn)
	attachTooltip(minimizeBtn, "Minimize")
	minimizeBtn.MouseButton1Click:Connect(function()
		-- Minimiza a janela (mostra apenas title bar)
		local currentSize = ui.mainWindow.Size
		ui.mainWindow:SetAttribute("PrevSize", currentSize)
		ui.mainWindow.Size = UDim2.new(0, currentSize.X.Offset, 0, WINDOW.TitleBarHeight)
	end)
	
	-- Botão Maximizar
	local maximizeBtn = Make("TextButton", {
		Name = "MaximizeButton",
		Text = "□",
		Font = FONT_SETTINGS.FontBold,
		TextSize = 12,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.ButtonOff,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 20, 0, 18),
		Position = UDim2.new(1, -43, 0, 2),
		Parent = ui.titleBar,
	})
	styleButton(maximizeBtn)
	attachTooltip(maximizeBtn, "Maximize")
	maximizeBtn.MouseButton1Click:Connect(function()
		local prevSize = ui.mainWindow:GetAttribute("PrevSize")
		if prevSize then
			ui.mainWindow.Size = prevSize
			ui.mainWindow:SetAttribute("PrevSize", nil)
		else
			ui.mainWindow.Size = UDim2.new(0, WINDOW.DefaultWidth, 0, WINDOW.DefaultHeight)
		end
	end)
	
	-- Botão Fechar
	local closeBtn = Make("TextButton", {
		Name = "CloseButton",
		Text = "X",
		Font = FONT_SETTINGS.FontBold,
		TextSize = 12,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.CloseButton,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 20, 0, 18),
		Position = UDim2.new(1, -21, 0, 2),
		Parent = ui.titleBar,
	})
	closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.BackgroundColor3 = COLORS.CloseButton
	end)
	attachTooltip(closeBtn, "Close")
	closeBtn.MouseButton1Click:Connect(function()
		-- Chama função de saída existente
		if _G.exitPlugin then
			_G.exitPlugin()
		else
			ui.mainWindow.Visible = false
		end
	end)
	
	-- Redimensionamento manual (cantos)
	local resizeHandle = Make("TextButton", {
		Name = "ResizeHandle",
		Text = "",
		BackgroundColor3 = COLORS.ButtonOff,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 15, 0, 15),
		Position = UDim2.new(1, -15, 1, -15),
		Parent = ui.mainWindow,
		ZIndex = 10,
	})
	
	local dragStart, startSize
	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragStart = Vector2.new(mouse.X, mouse.Y)
			startSize = Vector2.new(ui.mainWindow.Size.X.Offset, ui.mainWindow.Size.Y.Offset)
			uiState.isResizing = true
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if uiState.isResizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = Vector2.new(mouse.X, mouse.Y) - dragStart
			local newWidth = math.max(WINDOW.MinWidth, startSize.X + delta.X)
			local newHeight = math.max(WINDOW.MinHeight, startSize.Y + delta.Y)
			ui.mainWindow.Size = UDim2.new(0, newWidth, 0, newHeight)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			uiState.isResizing = false
		end
	end)
end

-- ============================================================================
-- SEÇÃO 10: TOOLBAR SUPERIOR
-- ============================================================================

local function createToolbar()
	ui.toolbar = Make("Frame", {
		Name = "Toolbar",
		BackgroundColor3 = COLORS.Panel,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, WINDOW.ToolbarHeight),
		Position = UDim2.new(0, 0, 0, WINDOW.TitleBarHeight),
		Parent = ui.mainWindow,
	})
	
	local toolbarButtons = {
		-- Grupo: Arquivo
		{name = "new", label = "New", tooltip = "New Animation", group = "file"},
		{name = "open", label = "Open", tooltip = "Open Animation", group = "file"},
		{name = "save", label = "Save", tooltip = "Save Animation", group = "file"},
		{name = "saveas", label = "Save As", tooltip = "Save As", group = "file"},
		{name = "export", label = "Export", tooltip = "Export Animation", group = "file"},
		{name = "import", label = "Import", tooltip = "Import Animation", group = "file"},
		
		-- Separador
		{name = "sep1", label = "|", tooltip = "", group = "sep"},
		
		-- Grupo: Playback
		{name = "play", label = "Play", tooltip = "Play Animation", group = "playback"},
		{name = "pause", label = "Pause", tooltip = "Pause Animation", group = "playback"},
		{name = "stop", label = "Stop", tooltip = "Stop Animation", group = "playback"},
		{name = "loop", label = "Loop", tooltip = "Toggle Loop", group = "playback", toggle = true},
		
		-- Separador
		{name = "sep2", label = "|", tooltip = "", group = "sep"},
		
		-- Grupo: Edição
		{name = "undo", label = "Undo", tooltip = "Undo", group = "edit"},
		{name = "redo", label = "Redo", tooltip = "Redo", group = "edit"},
		
		-- Separador
		{name = "sep3", label = "|", tooltip = "", group = "sep"},
		
		-- Grupo: Ferramentas
		{name = "rotate", label = "Rotate", tooltip = "Rotate Tool", group = "tool", toggle = true},
		{name = "move", label = "Move", tooltip = "Move Tool", group = "tool", toggle = true},
		{name = "scale", label = "Scale", tooltip = "Scale Tool", group = "tool", toggle = true},
		{name = "local_space", label = "Local", tooltip = "Local Space", group = "space", toggle = true},
		{name = "world_space", label = "World", tooltip = "World Space", group = "space", toggle = true},
		{name = "snap", label = "Snap", tooltip = "Toggle Snapping", group = "tool", toggle = true},
		{name = "interpolate", label = "Interp", tooltip = "Toggle Interpolation", group = "tool", toggle = true},
		
		-- Separador
		{name = "sep4", label = "|", tooltip = "", group = "sep"},
		
		-- Grupo: Keyframe
		{name = "keyframe_add", label = "+Kf", tooltip = "Add Keyframe", group = "keyframe"},
		{name = "keyframe_delete", label = "-Kf", tooltip = "Delete Keyframe", group = "keyframe"},
		{name = "keyframe_duplicate", label = "Dup", tooltip = "Duplicate Keyframe", group = "keyframe"},
		{name = "copy", label = "Copy", tooltip = "Copy Pose", group = "keyframe"},
		{name = "paste", label = "Paste", tooltip = "Paste Pose", group = "keyframe"},
		
		-- Separador
		{name = "sep5", label = "|", tooltip = "", group = "sep"},
		
		-- Grupo: Bone
		{name = "bone_add", label = "+Bone", tooltip = "Add Bone", group = "bone"},
		{name = "bone_remove", label = "-Bone", tooltip = "Remove Bone", group = "bone"},
		{name = "mirror", label = "Mirror", tooltip = "Mirror", group = "bone"},
		{name = "reset", label = "Reset", tooltip = "Reset Pose", group = "bone"},
	}
	
	local xOffset = 5
	for _, btnData in ipairs(toolbarButtons) do
		if btnData.group == "sep" then
			-- Separador visual
			Make("Frame", {
				Name = "Separator",
				BackgroundColor3 = COLORS.Separator,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 1, 0, 20),
				Position = UDim2.new(0, xOffset, 0, 4),
				Parent = ui.toolbar,
			})
			xOffset = xOffset + 6
		else
			local btn = Make("TextButton", {
				Name = btnData.name .. "Btn",
				Text = btnData.label,
				Font = FONT_SETTINGS.Font,
				TextSize = 11,
				BackgroundColor3 = COLORS.ButtonOff,
				BorderColor3 = COLORS.Border,
				BorderSizePixel = 1,
				Size = UDim2.new(0, math.max(35, #btnData.label * 7 + 8), 0, 22),
				Position = UDim2.new(0, xOffset, 0, 3),
				Parent = ui.toolbar,
			})
			
			styleButton(btn, btnData.toggle or false)
			attachTooltip(btn, btnData.tooltip)
			
			-- Callbacks dos botões
			btn.MouseButton1Click:Connect(function()
				if btnData.name == "new" then
					if _G.promptNew then _G.promptNew() end
				elseif btnData.name == "open" then
					if _G.PromptLoad then _G.PromptLoad() end
				elseif btnData.name == "save" then
					if _G.PromptSave then _G.PromptSave() end
				elseif btnData.name == "export" then
					-- Exporta animação atual
					if _G.saveCurrentAnimation then
						local name = showTextEntryDialog("Export Name:", "Animation")
						if name then
							_G.saveCurrentAnimation(name, true)
						end
					end
				elseif btnData.name == "import" then
					if _G.importFbxAnimation then _G.importFbxAnimation() end
				elseif btnData.name == "play" then
					uiState.isPlaying = true
					if _G.playCurrentAnimation then _G.playCurrentAnimation() end
				elseif btnData.name == "pause" then
					uiState.isPlaying = false
				elseif btnData.name == "stop" then
					uiState.isPlaying = false
					if _G.stopAnim ~= nil then _G.stopAnim = true end
				elseif btnData.name == "loop" then
					uiState.isLooping = not uiState.isLooping
					if _G.loopAnimation ~= nil then
						_G.loopAnimation = uiState.isLooping
					end
					btn:SetAttribute("Selected", uiState.isLooping)
				elseif btnData.name == "undo" then
					if _G.undo then _G.undo() end
				elseif btnData.name == "redo" then
					if _G.redo then _G.redo() end
				elseif btnData.name == "rotate" then
					uiState.selectedTool = "rotate"
					if _G.rotateMode ~= nil then _G.rotateMode = true end
					-- Desseleciona outros tools
					ui.toolbar:FindFirstChild("moveBtn"):SetAttribute("Selected", false)
					ui.toolbar:FindFirstChild("scaleBtn"):SetAttribute("Selected", false)
					btn:SetAttribute("Selected", true)
				elseif btnData.name == "move" then
					uiState.selectedTool = "move"
					if _G.rotateMode ~= nil then _G.rotateMode = false end
					ui.toolbar:FindFirstChild("rotateBtn"):SetAttribute("Selected", false)
					ui.toolbar:FindFirstChild("scaleBtn"):SetAttribute("Selected", false)
					btn:SetAttribute("Selected", true)
				elseif btnData.name == "scale" then
					uiState.selectedTool = "scale"
					ui.toolbar:FindFirstChild("rotateBtn"):SetAttribute("Selected", false)
					ui.toolbar:FindFirstChild("moveBtn"):SetAttribute("Selected", false)
					btn:SetAttribute("Selected", true)
				elseif btnData.name == "local_space" then
					uiState.selectedSpace = "local"
					if _G.currentSpace ~= nil then _G.currentSpace = "local" end
					ui.toolbar:FindFirstChild("world_spaceBtn"):SetAttribute("Selected", false)
					btn:SetAttribute("Selected", true)
				elseif btnData.name == "world_space" then
					uiState.selectedSpace = "world"
					if _G.currentSpace ~= nil then _G.currentSpace = "world" end
					ui.toolbar:FindFirstChild("local_spaceBtn"):SetAttribute("Selected", false)
					btn:SetAttribute("Selected", true)
				elseif btnData.name == "snap" then
					uiState.snapping = not uiState.snapping
					if _G.snapEnabled ~= nil then _G.snapEnabled = uiState.snapping end
					btn:SetAttribute("Selected", uiState.snapping)
				elseif btnData.name == "interpolate" then
					uiState.interpolation = not uiState.interpolation
					if _G.interpolationEnabled ~= nil then _G.interpolationEnabled = uiState.interpolation end
					btn:SetAttribute("Selected", uiState.interpolation)
				elseif btnData.name == "keyframe_add" then
					if _G.createKeyframe then
						_G.createKeyframe(uiState.currentTime, true)
					end
				elseif btnData.name == "keyframe_delete" then
					if _G.deleteKeyframe then
						_G.deleteKeyframe(uiState.currentTime, true)
					end
				elseif btnData.name == "keyframe_duplicate" then
					-- Duplica keyframe selecionado
					if _G.selectedKeyframe and _G.copyPoseList then
						for partName, pose in pairs(_G.selectedKeyframe.Poses or {}) do
							if _G.copyPose then
								_G.copyPose(partName, pose)
							end
						end
					end
				elseif btnData.name == "copy" then
					-- Copia poses do keyframe atual
					if _G.copyPoseList then
						-- Limpa lista atual
						if _G.resetCopyPoseList then _G.resetCopyPoseList() end
						local kf = _G.getKeyframe and _G.getKeyframe(uiState.currentTime)
						if kf and kf.Poses then
							for partName, pose in pairs(kf.Poses) do
								if _G.copyPose then
									_G.copyPose(partName, pose)
								end
							end
						end
					end
				elseif btnData.name == "paste" then
					if _G.pastePoses then _G.pastePoses() end
				elseif btnData.name == "bone_add" then
					-- Adicionar bone (implementação depende do sistema)
				elseif btnData.name == "bone_remove" then
					-- Remover bone
				elseif btnData.name == "mirror" then
					-- Mirror
				elseif btnData.name == "reset" then
					if _G.resetKeyframeToDefaultPose and _G.selectedKeyframe then
						_G.resetKeyframeToDefaultPose(_G.selectedKeyframe)
					end
				end
			end)
			
			xOffset = xOffset + btn.Size.X.Offset + 2
		end
	end
end

-- ============================================================================
-- SEÇÃO 11: MENU SUPERIOR (Arquivo, Editar, Exibir, Animação, Ajuda)
-- ============================================================================

local function createMenuBar()
	local menuBar = Make("Frame", {
		Name = "MenuBar",
		BackgroundColor3 = COLORS.Panel,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 0),
		Parent = ui.titleBar,
		ClipsDescendants = true,
	})
	
	local menus = {
		{
			name = "File",
			label = "File",
			items = {
				{label = "New", action = "New", shortcut = "Ctrl+N"},
				{label = "Open...", action = "Open", shortcut = "Ctrl+O"},
				{label = "Save", action = "Save", shortcut = "Ctrl+S"},
				{label = "Save As...", action = "SaveAs", shortcut = "Ctrl+Shift+S"},
				{label = "Export...", action = "Export", shortcut = ""},
				{label = "Import...", action = "Import", shortcut = ""},
				{label = "-", action = "sep"},
				{label = "Close", action = "Close", shortcut = "Ctrl+W"},
			}
		},
		{
			name = "Edit",
			label = "Edit",
			items = {
				{label = "Undo", action = "Undo", shortcut = "Ctrl+Z"},
				{label = "Redo", action = "Redo", shortcut = "Ctrl+Y"},
				{label = "-", action = "sep"},
				{label = "Copy Pose", action = "Copy", shortcut = "Ctrl+C"},
				{label = "Paste Pose", action = "Paste", shortcut = "Ctrl+V"},
				{label = "-", action = "sep"},
				{label = "Select All", action = "SelectAll", shortcut = "Ctrl+A"},
			}
		},
		{
			name = "View",
			label = "View",
			items = {
				{label = "Zoom In", action = "ZoomIn", shortcut = "Ctrl++"},
				{label = "Zoom Out", action = "ZoomOut", shortcut = "Ctrl+-"},
				{label = "Reset Zoom", action = "ResetZoom", shortcut = "Ctrl+0"},
				{label = "-", action = "sep"},
				{label = "Show Grid", action = "ShowGrid", shortcut = ""},
				{label = "Show Tooltips", action = "Tooltips", shortcut = ""},
			}
		},
		{
			name = "Animation",
			label = "Animation",
			items = {
				{label = "Play", action = "Play", shortcut = "Space"},
				{label = "Stop", action = "Stop", shortcut = "Esc"},
				{label = "-", action = "sep"},
				{label = "Change Length...", action = "ChangeLength", shortcut = ""},
				{label = "Set Framerate...", action = "SetFramerate", shortcut = ""},
				{label = "Set Priority...", action = "Priority", shortcut = ""},
				{label = "Toggle Loop", action = "Loop", shortcut = ""},
				{label = "-", action = "sep"},
				{label = "Add Time at Cursor", action = "AddTime", shortcut = ""},
				{label = "Remove Time at Cursor", action = "RemoveTime", shortcut = ""},
			}
		},
		{
			name = "Help",
			label = "Help",
			items = {
				{label = "Help...", action = "Help", shortcut = "F1"},
				{label = "About", action = "About", shortcut = ""},
			}
		},
	}
	
	local xOffset = 5
	for _, menu in ipairs(menus) do
		local menuBtn = Make("TextButton", {
			Name = menu.name .. "Menu",
			Text = menu.label,
			Font = FONT_SETTINGS.Font,
			TextSize = 12,
			TextColor3 = COLORS.Text,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, #menu.label * 7 + 10, 1, 0),
			Position = UDim2.new(0, xOffset, 0, 0),
			Parent = menuBar,
		})
		
		menuBtn.MouseEnter:Connect(function()
			menuBtn.BackgroundColor3 = COLORS.ButtonHover
			menuBtn.BackgroundTransparency = 0.5
		end)
		menuBtn.MouseLeave:Connect(function()
			menuBtn.BackgroundTransparency = 1
		end)
		
		menuBtn.MouseButton1Click:Connect(function()
			local options = {}
			for _, item in ipairs(menu.items) do
				if item.action == "sep" then
					table.insert(options, {
						name = "separator",
						label = "────────────",
						callback = function() end
					})
				else
					table.insert(options, {
						name = item.action,
						label = item.label .. (item.shortcut ~= "" and "     " .. item.shortcut or ""),
						callback = function()
							-- Chama menuRequest existente
							if _G.menuRequest then
								_G.menuRequest(item.action)
							else
								-- Fallback interno
								if item.action == "New" then
									if _G.promptNew then _G.promptNew() end
								elseif item.action == "Open" then
									if _G.PromptLoad then _G.PromptLoad() end
								elseif item.action == "Save" then
									if _G.PromptSave then _G.PromptSave() end
								elseif item.action == "SaveAs" then
									local name = showTextEntryDialog("Save As:", "Animation")
									if name and _G.saveCurrentAnimation then
										_G.saveCurrentAnimation(name, false)
									end
								elseif item.action == "Export" then
									local name = showTextEntryDialog("Export Name:", "Animation")
									if name and _G.saveCurrentAnimation then
										_G.saveCurrentAnimation(name, true)
									end
								elseif item.action == "Import" then
									if _G.importFbxAnimation then _G.importFbxAnimation() end
								elseif item.action == "Close" then
									if _G.exitPlugin then _G.exitPlugin() end
								elseif item.action == "Undo" then
									if _G.undo then _G.undo() end
								elseif item.action == "Redo" then
									if _G.redo then _G.redo() end
								elseif item.action == "Copy" then
									-- Copy pose
								elseif item.action == "Paste" then
									if _G.pastePoses then _G.pastePoses() end
								elseif item.action == "Play" then
									if _G.playCurrentAnimation then _G.playCurrentAnimation() end
								elseif item.action == "Stop" then
									if _G.stopAnim ~= nil then _G.stopAnim = true end
								elseif item.action == "ChangeLength" then
									if _G.promptChangeLength then _G.promptChangeLength() end
								elseif item.action == "SetFramerate" then
									if _G.promptTickChange then _G.promptTickChange() end
								elseif item.action == "Priority" then
									if _G.promptChangePriority then _G.promptChangePriority() end
								elseif item.action == "Loop" then
									if _G.promptChangeLooping then _G.promptChangeLooping() end
								elseif item.action == "AddTime" then
									if _G.promptAddTime then _G.promptAddTime() end
								elseif item.action == "RemoveTime" then
									if _G.promptRemoveTime then _G.promptRemoveTime() end
								elseif item.action == "ZoomIn" then
									-- Zoom in timeline
								elseif item.action == "ZoomOut" then
									-- Zoom out timeline
								elseif item.action == "Help" then
									if _G.menuRequest then _G.menuRequest("Help") end
								end
							end
						end
					})
				end
			end
			local pos = menuBtn.AbsolutePosition
			showContextMenu(options, Vector2.new(pos.X, pos.Y + menuBtn.AbsoluteSize.Y))
		end)
		
		xOffset = xOffset + menuBtn.Size.X.Offset
	end
end

-- ============================================================================
-- SEÇÃO 12: PAINEL ESQUERDO (Lista de Partes)
-- ============================================================================

local function createLeftPanel()
	ui.leftPanel = Make("Frame", {
		Name = "LeftPanel",
		BackgroundColor3 = COLORS.PanelDark,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, WINDOW.LeftPanelWidth, 1, -(WINDOW.TitleBarHeight + WINDOW.ToolbarHeight + WINDOW.PlaybackHeight)),
		Position = UDim2.new(0, 0, 0, WINDOW.TitleBarHeight + WINDOW.ToolbarHeight),
		Parent = ui.mainWindow,
		ClipsDescendants = true,
	})
	
	-- Header
	Make("TextLabel", {
		Name = "Header",
		Text = "Parts",
		Font = FONT_SETTINGS.FontBold,
		TextSize = 12,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.Panel,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = ui.leftPanel,
	})
	
	-- Barra de pesquisa
	local searchBox = Make("TextBox", {
		Name = "SearchBox",
		Text = "",
		PlaceholderText = "Search parts...",
		Font = FONT_SETTINGS.Font,
		TextSize = 11,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.InputBg,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(1, -4, 0, 20),
		Position = UDim2.new(0, 2, 0, 22),
		ClearTextOnFocus = false,
		Parent = ui.leftPanel,
	})
	
	-- ScrollingFrame para lista de partes
	local partListScroll = Make("ScrollingFrame", {
		Name = "PartListScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -45),
		Position = UDim2.new(0, 0, 0, 44),
		ScrollBarThickness = 8,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(1, 0, 0, 0),
		Parent = ui.leftPanel,
	})
	
	-- Linha de seleção (highlight)
	ui.selectedLine = Make("Frame", {
		Name = "SelectedLineHighlight",
		BackgroundColor3 = COLORS.SelectedLine,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -4, 0, 20),
		Position = UDim2.new(0, 2, 0, 0),
		Visible = false,
		Parent = partListScroll,
	})
	
	-- Função para atualizar lista de partes
	local function updatePartList()
		-- Limpa itens existentes
		for _, child in ipairs(partListScroll:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		
		local partList = _G.partList or {}
		local partToLineNumber = _G.partToLineNumber or {}
		local partInclude = _G.partInclude or {}
		local yOffset = 0
		
		for part, itemData in pairs(partList) do
			local lineNum = partToLineNumber[part]
			if lineNum then
				local isIncluded = partInclude[part.Name] or false
				local indent = 0
				local parent = itemData.Parent
				while parent do
					indent = indent + 1
					parent = parent.Parent
				end
				
				local partBtn = Make("TextButton", {
					Name = "Part_" .. part.Name,
					Text = string.rep("  ", indent) .. (part.Name == "HumanoidRootPart" and "" or part.Name),
					Font = FONT_SETTINGS.Font,
					TextSize = 11,
					TextColor3 = COLORS.Text,
					BackgroundColor3 = isIncluded and COLORS.ButtonOn or COLORS.ButtonOff,
					BorderSizePixel = 0,
					Size = UDim2.new(1, -8, 0, 20),
					Position = UDim2.new(0, 4, 0, yOffset),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = partListScroll,
				})
				
				-- Ícone de expansão (se tiver filhos)
				if itemData.Children and #itemData.Children > 0 then
					Make("TextLabel", {
						Name = "ExpandIcon",
						Text = "▶",
						Font = FONT_SETTINGS.Font,
						TextSize = 8,
						TextColor3 = COLORS.TextDark,
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 12, 0, 12),
						Position = UDim2.new(0, 2, 0, 4),
						Parent = partBtn,
					})
				end
				
				-- Clique para selecionar parte
				partBtn.MouseButton1Click:Connect(function()
					if _G.setHandleSelection then
						_G.setHandleSelection(itemData)
					end
					-- Atualiza highlight
					ui.selectedLine.Position = UDim2.new(0, 2, 0, yOffset)
					ui.selectedLine.Visible = true
				end)
				
				-- Clique direito para menu de contexto
				partBtn.MouseButton2Click:Connect(function()
					local options = {
						{name = "select", label = "Select", callback = function()
							if _G.setHandleSelection then _G.setHandleSelection(itemData) end
						end},
						{name = "include", label = isIncluded and "Exclude" or "Include", callback = function()
							if _G.partInclude then
								_G.partInclude[part.Name] = not isIncluded
							end
							updatePartList()
						end},
						{name = "rename", label = "Rename", callback = function()
							local newName = showTextEntryDialog("Rename Part:", part.Name)
							if newName and newName ~= "" then
								-- Renomeia (se suportado pelo sistema)
							end
						end},
					}
					showContextMenu(options, Vector2.new(mouse.X, mouse.Y))
				end)
				
				yOffset = yOffset + 20
			end
		end
		
		partListScroll.CanvasSize = UDim2.new(1, 0, 0, yOffset)
	end
	
	-- Atualiza quando partList mudar
	-- (Na prática, seria chamado pelo sistema de animação)
	
	-- Botão de filtro
	local filterBtn = Make("TextButton", {
		Name = "FilterBtn",
		Text = "Filter",
		Font = FONT_SETTINGS.Font,
		TextSize = 10,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.ButtonOff,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 40, 0, 18),
		Position = UDim2.new(1, -42, 0, 23),
		Parent = ui.leftPanel,
	})
	styleButton(filterBtn)
end

-- ============================================================================
-- SEÇÃO 13: TIMELINE (A parte mais detalhada)
-- ============================================================================

local function createTimeline()
	local timelineY = WINDOW.TitleBarHeight + WINDOW.ToolbarHeight
	local timelineHeight = WINDOW.TimelineHeight
	
	ui.timelinePanel = Make("Frame", {
		Name = "TimelinePanel",
		BackgroundColor3 = COLORS.TimelineBg,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(1, -(WINDOW.LeftPanelWidth + WINDOW.RightPanelWidth), 0, timelineHeight),
		Position = UDim2.new(0, WINDOW.LeftPanelWidth, 0, timelineY),
		Parent = ui.mainWindow,
		ClipsDescendants = true,
	})
	
	-- Container principal da timeline com scroll
	local keyframeContainer = Make("ScrollingFrame", {
		Name = "KeyframeContainer",
		BackgroundColor3 = COLORS.TimelineBg,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		CanvasSize = UDim2.new(0, 2000, 1, 0),
		ScrollBarThickness = 8,
		ScrollingDirection = Enum.ScrollingDirection.XY,
		Parent = ui.timelinePanel,
	})
	
	-- Régua de tempo (TimeListFrame)
	local timeListFrame = Make("Frame", {
		Name = "TimeListFrame",
		BackgroundColor3 = COLORS.Panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 15),
		Position = UDim2.new(0, 0, 0, 0),
		Parent = keyframeContainer,
		ZIndex = 3,
	})
	
	-- Frame da timeline (área de keyframes)
	local timelineFrame = Make("TextButton", {
		Name = "TimelineFrame",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = COLORS.TimelineLine,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 15),
		Position = UDim2.new(0, 0, 0, 20),
		Parent = keyframeContainer,
		ZIndex = 2,
	})
	
	-- Grade de fundo
	local gridFrame = Make("Frame", {
		Name = "GridFrame",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -35),
		Position = UDim2.new(0, 0, 0, 35),
		Parent = keyframeContainer,
		ZIndex = 1,
	})
	
	-- Cursor (vermelho/azul)
	ui.cursor = Make("Frame", {
		Name = "Cursor",
		BackgroundColor3 = COLORS.Accent,
		BorderColor3 = COLORS.Accent,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 19, 0, 19),
		Position = UDim2.new(0, 117, 0, 20),
		ZIndex = 4,
		Parent = keyframeContainer,
		Make("Frame", {
			Name = "CursorLine",
			BackgroundColor3 = COLORS.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 2, 1000, 0),
			Position = UDim2.new(0, 7.5, 0, 0),
			ZIndex = 1,
			Parent = nil, -- Será parenteado depois
		}),
		Make("TextLabel", {
			Name = "CursorText",
			Text = "▼",
			Font = FONT_SETTINGS.Font,
			TextSize = 14,
			TextColor3 = COLORS.Text,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 4,
			Parent = nil,
		}),
	})
	
	-- Parenteia filhos do cursor corretamente
	ui.cursor.CursorLine.Parent = ui.cursor
	ui.cursor.CursorText.Parent = ui.cursor
	
	-- Arrastar cursor
	local draggingCursor = false
	ui.cursor.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingCursor = true
			keyframeContainer.ScrollingEnabled = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if draggingCursor and input.UserInputType == Enum.UserInputType.MouseMovement then
			local relX = mouse.X - keyframeContainer.AbsolutePosition.X + keyframeContainer.CanvasPosition.X
			local newTime = relX / (2000 / (uiState.animationLength or 2))
			newTime = math.clamp(newTime, 0, uiState.animationLength or 2)
			
			-- Snapping
			if uiState.snapping then
				local snap = 0.05
				newTime = math.floor(newTime / snap + 0.5) * snap
			end
			
			uiState.currentTime = newTime
			if _G.currentTime ~= nil then _G.currentTime = newTime end
			
			-- Atualiza posição visual
			local pixelsPerSecond = 2000 / (uiState.animationLength or 2)
			ui.cursor.Position = UDim2.new(0, newTime * pixelsPerSecond - 9.5, 0, 20)
			
			-- Chama update do sistema
			if _G.updateCursorPosition then
				_G.updateCursorPosition()
			end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingCursor = false
			keyframeContainer.ScrollingEnabled = true
		end
	end)
	
	-- Clicar na timeline para mover cursor
	timelineFrame.MouseButton1Click:Connect(function()
		local relX = mouse.X - timelineFrame.AbsolutePosition.X + keyframeContainer.CanvasPosition.X
		local newTime = relX / (2000 / (uiState.animationLength or 2))
		newTime = math.clamp(newTime, 0, uiState.animationLength or 2)
		uiState.currentTime = newTime
		if _G.currentTime ~= nil then _G.currentTime = newTime end
		
		local pixelsPerSecond = 2000 / (uiState.animationLength or 2)
		ui.cursor.Position = UDim2.new(0, newTime * pixelsPerSecond - 9.5, 0, 20)
		
		if _G.updateCursorPosition then
			_G.updateCursorPosition()
		end
	end)
	
	-- Zoom buttons (dentro do painel timeline)
	local zoomInBtn = Make("TextButton", {
		Name = "ZoomIn",
		Text = "+",
		Font = FONT_SETTINGS.FontBold,
		TextSize = 14,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.ButtonOff,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(1, -26, 1, -48),
		Parent = ui.timelinePanel,
		ZIndex = 5,
	})
	styleButton(zoomInBtn)
	zoomInBtn.MouseButton1Click:Connect(function()
		uiState.zoomLevel = uiState.zoomLevel * 1.2
		local newWidth = 2000 * uiState.zoomLevel
		keyframeContainer.CanvasSize = UDim2.new(0, newWidth, 1, 0)
	end)
	
	local zoomOutBtn = Make("TextButton", {
		Name = "ZoomOut",
		Text = "-",
		Font = FONT_SETTINGS.FontBold,
		TextSize = 14,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.ButtonOff,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(1, -26, 1, -26),
		Parent = ui.timelinePanel,
		ZIndex = 5,
	})
	styleButton(zoomOutBtn)
	zoomOutBtn.MouseButton1Click:Connect(function()
		uiState.zoomLevel = math.max(0.5, uiState.zoomLevel / 1.2)
		local newWidth = 2000 * uiState.zoomLevel
		keyframeContainer.CanvasSize = UDim2.new(0, newWidth, 1, 0)
	end)
	
	Make("TextLabel", {
		Name = "ZoomLabel",
		Text = "Zoom",
		Font = FONT_SETTINGS.Font,
		TextSize = 10,
		TextColor3 = COLORS.TextDark,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 30, 0, 14),
		Position = UDim2.new(1, -31, 1, -65),
		Parent = ui.timelinePanel,
		ZIndex = 5,
	})
	
	-- Atualiza labels de tempo
	local function updateTimeLabels()
		-- Limpa labels antigos
		for _, child in ipairs(timeListFrame:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		
		local animLength = uiState.animationLength or 2
		local numTicks = 20
		local pixelsPerSecond = keyframeContainer.CanvasSize.X.Offset / animLength
		
		for i = 0, numTicks do
			local time = (i / numTicks) * animLength
			local xPos = time * pixelsPerSecond
			
			local tickLabel = Make("TextLabel", {
				Name = "Tick" .. i,
				Text = string.format("%.2f", time),
				Font = FONT_SETTINGS.Font,
				TextSize = 9,
				TextColor3 = COLORS.TextDark,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 30, 0, 12),
				Position = UDim2.new(0, xPos, 0, 1),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = timeListFrame,
				ZIndex = 3,
			})
			
			-- Indicador vertical
			Make("Frame", {
				Name = "TickIndicator",
				BackgroundColor3 = COLORS.TextDark,
				BackgroundTransparency = 0.8,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 1, 0, 1000),
				Position = UDim2.new(0, xPos + 2, 0, 14),
				Parent = timeListFrame,
				ZIndex = 1,
			})
		end
	end
	
	-- Atualiza quando animationLength mudar
	-- (Chamado pelo sistema de animação)
	
	-- Função para desenhar keyframes na timeline
	local function drawKeyframes()
		-- Limpa keyframes visuais antigos
		for _, child in ipairs(timelineFrame:GetChildren()) do
			if child.Name:match("^Keyframe") then
				child:Destroy()
			end
		end
		
		local keyframeList = _G.keyframeList or {}
		local animLength = uiState.animationLength or 2
		local pixelsPerSecond = keyframeContainer.CanvasSize.X.Offset / animLength
		
		for time, kfData in pairs(keyframeList) do
			local xPos = time * pixelsPerSecond
			
			-- Linha vertical do keyframe
			local kfLine = Make("Frame", {
				Name = "Keyframe" .. time,
				BackgroundColor3 = COLORS.Keyframe,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 2, 1, 0),
				Position = UDim2.new(0, xPos, 0, 0),
				Parent = timelineFrame,
				ZIndex = 2,
			})
			
			-- Botão do keyframe (diamante/quadrado)
			local kfButton = Make("TextButton", {
				Name = "KeyframeBtn" .. time,
				Text = "kf",
				Font = FONT_SETTINGS.Font,
				TextSize = 8,
				TextColor3 = COLORS.Text,
				BackgroundColor3 = COLORS.Keyframe,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 15, 0, 15),
				Position = UDim2.new(0, xPos - 6, 0, 0),
				Parent = timelineFrame,
				ZIndex = 3,
			})
			
			-- Hover e seleção
			kfButton.MouseEnter:Connect(function()
				kfButton.BackgroundColor3 = COLORS.KeyframeSelected
			end)
			kfButton.MouseLeave:Connect(function()
				if not (uiState.selectedKeyframes[time]) then
					kfButton.BackgroundColor3 = COLORS.Keyframe
				end
			end)
			
			-- Clique para selecionar
			kfButton.MouseButton1Click:Connect(function()
				uiState.selectedKeyframes = {[time] = true}
				_G.selectedKeyframe = kfData
				kfButton.BackgroundColor3 = COLORS.KeyframeSelected
			end)
			
			-- Clique duplo
			local lastClick = 0
			kfButton.MouseButton1Click:Connect(function()
				local now = tick()
				if now - lastClick < 0.3 then
					-- Duplo clique - menu de contexto
					if _G.keyframeContextMenu then
						_G.keyframeContextMenu(xPos, 0, false)
					end
				end
				lastClick = now
			end)
			
			-- Clique direito
			kfButton.MouseButton2Click:Connect(function()
				local options = {
					{name = "create", label = "Create Keyframe", callback = function()
						if _G.createKeyframe then _G.createKeyframe(time, true) end
					end},
					{name = "delete", label = "Delete", callback = function()
						if time > 0 and _G.deleteKeyframe then
							_G.deleteKeyframe(time, true)
						end
					end},
					{name = "copy", label = "Copy Pose", callback = function()
						if kfData.Poses then
							for partName, pose in pairs(kfData.Poses) do
								if _G.copyPose then _G.copyPose(partName, pose) end
							end
						end
					end},
					{name = "paste", label = "Paste Pose", callback = function()
						if _G.pastePoses then _G.pastePoses() end
					end},
					{name = "duplicate", label = "Duplicate", callback = function()
						-- Duplica keyframe
					end},
					{name = "rename", label = "Rename", callback = function()
						local newName = showTextEntryDialog("Keyframe Name:", kfData.Name or "Keyframe")
						if newName then
							kfData.Name = newName
						end
					end},
					{name = "easing", label = "Easing...", callback = function()
						-- Abre dialog de easing
					end},
				}
				showContextMenu(options, Vector2.new(mouse.X, mouse.Y))
			end)
			
			-- Arrastar keyframe
			local draggingKf = false
			kfButton.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					draggingKf = true
					_G.selectedKeyframe = kfData
					if _G.lockUndoStep then
						_G.lockUndoStep("keyframeMove")
					end
				end
			end)
			
			UserInputService.InputChanged:Connect(function(input)
				if draggingKf and input.UserInputType == Enum.UserInputType.MouseMovement then
					local relX = mouse.X - timelineFrame.AbsolutePosition.X + keyframeContainer.CanvasPosition.X
					local newTime = relX / pixelsPerSecond
					newTime = math.clamp(newTime, 0, animLength)
					
					if uiState.snapping then
						local snap = 0.05
						newTime = math.floor(newTime / snap + 0.5) * snap
					end
					
					-- Move visualmente
					kfLine.Position = UDim2.new(0, newTime * pixelsPerSecond, 0, 0)
					kfButton.Position = UDim2.new(0, newTime * pixelsPerSecond - 6, 0, 0)
				end
			end)
			
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 and draggingKf then
					draggingKf = false
					local relX = mouse.X - timelineFrame.AbsolutePosition.X + keyframeContainer.CanvasPosition.X
					local newTime = relX / pixelsPerSecond
					newTime = math.clamp(newTime, 0, animLength)
					
					if uiState.snapping then
						local snap = 0.05
						newTime = math.floor(newTime / snap + 0.5) * snap
					end
					
					-- Move o keyframe no sistema
					if _G.moveKeyframe then
						_G.moveKeyframe(kfData, newTime)
					end
				end
			end)
		end
	end
	
	-- Atualiza keyframes quando a lista mudar
	-- (Chamado pelo sistema de animação)
	
	-- Desenha poses (diamantes) na timeline
	local function drawPoses()
		-- Limpa poses antigas
		for _, child in ipairs(gridFrame:GetChildren()) do
			if child.Name:match("^Pose") then
				child:Destroy()
			end
		end
		
		local keyframeList = _G.keyframeList or {}
		local partToLineNumber = _G.partToLineNumber or {}
		local pixelsPerSecond = keyframeContainer.CanvasSize.X.Offset / (uiState.animationLength or 2)
		
		for time, kfData in pairs(keyframeList) do
			if kfData.Poses then
				for part, pose in pairs(kfData.Poses) do
					local lineNum = partToLineNumber[part]
					if lineNum then
						local yPos = (lineNum - 1) * 20 + 6
						local xPos = time * pixelsPerSecond
						
						-- Determina cor baseada no easing
						local poseColor = COLORS.Keyframe
						if pose.EasingStyle then
							local styleName = pose.EasingStyle.Name or tostring(pose.EasingStyle)
							if styleName == "Constant" then
								poseColor = Color3.new(0.533, 0.533, 0.533)
							elseif styleName == "Cubic" then
								poseColor = Color3.new(0.439, 0.176, 0)
							elseif styleName == "CubicV2" then
								poseColor = Color3.new(1, 0.415, 0)
							elseif styleName == "Elastic" then
								poseColor = Color3.new(0.094, 0.274, 0.113)
							elseif styleName == "Bounce" then
								poseColor = Color3.new(0.639, 0.231, 0.8)
							end
						end
						
						-- Verifica se está copiado
						local copyPoseList = _G.copyPoseList or {}
						if copyPoseList[part.Name] == pose then
							poseColor = COLORS.KeyframeSelected
						end
						
						local poseBtn = Make("TextButton", {
							Name = "Pose" .. part.Name .. "_" .. time,
							Text = "",
							BackgroundColor3 = poseColor,
							BorderSizePixel = 0,
							Size = UDim2.new(0, 13, 0, 13),
							Position = UDim2.new(0, xPos - 6.5, 0, yPos),
							Parent = gridFrame,
							ZIndex = 3,
						})
						
						-- Rotação para parecer diamante
						poseBtn.Rotation = 45
						
						-- Hover
						poseBtn.MouseEnter:Connect(function()
							poseBtn.BackgroundColor3 = COLORS.ButtonHover
						end)
						poseBtn.MouseLeave:Connect(function()
							poseBtn.BackgroundColor3 = poseColor
						end)
						
						-- Clique
						poseBtn.MouseButton1Click:Connect(function()
							if _G.copyPose then
								_G.copyPose(part, pose)
							end
						end)
						
						-- Clique direito
						poseBtn.MouseButton2Click:Connect(function()
							local options = {
								{name = "copy", label = "Copy Pose", callback = function()
									if _G.copyPose then _G.copyPose(part, pose) end
								end},
								{name = "delete", label = "Delete Pose", callback = function()
									if time > 0 and _G.deletePose then
										_G.deletePose(kfData, part)
									end
								end},
								{name = "easing", label = "Easing...", callback = function()
									-- Abre selector de easing
									if _G.MenuHandler and _G.MenuHandler.SetEasingStyle then
										uiState.modal = true
										_G.MenuHandler.SetEasingStyle(pose, function()
											uiState.modal = false
											if pose.updateColor then pose.updateColor() end
										end)
									end
								end},
							}
							showContextMenu(options, Vector2.new(mouse.X, mouse.Y))
						end)
					end
				end
			end
		end
	end
	
	-- Sincroniza scroll vertical com lista de partes
	-- (Implementado via eventos do sistema existente)
	
	-- Atualiza visual quando necessário
	local function refreshTimeline()
		updateTimeLabels()
		drawKeyframes()
		drawPoses()
	end
	
	-- Expõe função para o sistema chamar
	ui.refreshTimeline = refreshTimeline
end

-- ============================================================================
-- SEÇÃO 14: PAINEL DIREITO (Propriedades)
-- ============================================================================

local function createRightPanel()
	ui.rightPanel = Make("Frame", {
		Name = "RightPanel",
		BackgroundColor3 = COLORS.PanelDark,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, WINDOW.RightPanelWidth, 1, -(WINDOW.TitleBarHeight + WINDOW.ToolbarHeight + WINDOW.PlaybackHeight)),
		Position = UDim2.new(1, -WINDOW.RightPanelWidth, 0, WINDOW.TitleBarHeight + WINDOW.ToolbarHeight),
		Parent = ui.mainWindow,
		ClipsDescendants = true,
	})
	
	-- Header
	Make("TextLabel", {
		Name = "Header",
		Text = "Properties",
		Font = FONT_SETTINGS.FontBold,
		TextSize = 12,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.Panel,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = ui.rightPanel,
	})
	
	-- ScrollingFrame para propriedades
	local propsScroll = Make("ScrollingFrame", {
		Name = "PropertiesScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -22),
		Position = UDim2.new(0, 0, 0, 22),
		ScrollBarThickness = 8,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(1, 0, 0, 400),
		Parent = ui.rightPanel,
	})
	
	-- Função para criar campo de propriedade
	local function createPropertyField(name, value, yPos, parent)
		local label = Make("TextLabel", {
			Name = name .. "Label",
			Text = name .. ":",
			Font = FONT_SETTINGS.Font,
			TextSize = 11,
			TextColor3 = COLORS.TextDark,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 80, 0, 18),
			Position = UDim2.new(0, 4, 0, yPos),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = parent,
		})
		
		local input = Make("TextBox", {
			Name = name .. "Input",
			Text = tostring(value),
			Font = FONT_SETTINGS.Font,
			TextSize = 11,
			TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.InputBg,
			BorderColor3 = COLORS.Border,
			BorderSizePixel = 1,
			Size = UDim2.new(1, -88, 0, 18),
			Position = UDim2.new(0, 84, 0, yPos),
			ClearTextOnFocus = false,
			Parent = parent,
		})
		
		return input
	end
	
	-- Função para atualizar painel de propriedades
	local function updateProperties()
		-- Limpa campos antigos
		for _, child in ipairs(propsScroll:GetChildren()) do
			child:Destroy()
		end
		
		local selectedKf = _G.selectedKeyframe
		local selectedPose = nil
		
		if selectedKf and selectedKf.Poses and _G.partSelection then
			selectedPose = selectedKf.Poses[_G.partSelection.Item]
		end
		
		local yOffset = 4
		
		-- Seção: Keyframe Info
		Make("TextLabel", {
			Name = "Section_Keyframe",
			Text = "─ Keyframe ─",
			Font = FONT_SETTINGS.FontBold,
			TextSize = 11,
			TextColor3 = COLORS.Text,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -8, 0, 16),
			Position = UDim2.new(0, 4, 0, yOffset),
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = propsScroll,
		})
		yOffset = yOffset + 20
		
		if selectedKf then
			createPropertyField("Frame", selectedKf.Time or 0, yOffset, propsScroll)
			yOffset = yOffset + 22
			createPropertyField("Time", string.format("%.3f", selectedKf.Time or 0), yOffset, propsScroll)
			yOffset = yOffset + 22
			createPropertyField("Name", selectedKf.Name or "Keyframe", yOffset, propsScroll)
			yOffset = yOffset + 26
		else
			Make("TextLabel", {
				Name = "NoKeyframe",
				Text = "No keyframe selected",
				Font = FONT_SETTINGS.Font,
				TextSize = 11,
				TextColor3 = COLORS.TextDark,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -8, 0, 18),
				Position = UDim2.new(0, 4, 0, yOffset),
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = propsScroll,
			})
			yOffset = yOffset + 22
		end
		
		-- Separador
		yOffset = yOffset + 4
		Make("Frame", {
			Name = "Separator1",
			BackgroundColor3 = COLORS.Separator,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -8, 0, 1),
			Position = UDim2.new(0, 4, 0, yOffset),
			Parent = propsScroll,
		})
		yOffset = yOffset + 8
		
		-- Seção: Pose
		Make("TextLabel", {
			Name = "Section_Pose",
			Text = "─ Pose ─",
			Font = FONT_SETTINGS.FontBold,
			TextSize = 11,
			TextColor3 = COLORS.Text,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -8, 0, 16),
			Position = UDim2.new(0, 4, 0, yOffset),
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = propsScroll,
		})
		yOffset = yOffset + 20
		
		if selectedPose then
			-- Parte
			local partName = selectedPose.Item and selectedPose.Item.Name or "Unknown"
			createPropertyField("Part", partName, yOffset, propsScroll)
			yOffset = yOffset + 22
			
			-- Posição (CFrame simplificado)
			local cf = selectedPose.CFrame or CFrame.new()
			local pos = cf.Position
			createPropertyField("Pos X", string.format("%.3f", pos.X), yOffset, propsScroll)
			yOffset = yOffset + 22
			createPropertyField("Pos Y", string.format("%.3f", pos.Y), yOffset, propsScroll)
			yOffset = yOffset + 22
			createPropertyField("Pos Z", string.format("%.3f", pos.Z), yOffset, propsScroll)
			yOffset = yOffset + 22
			
			-- Rotação (Euler angles aproximados)
			local rx, ry, rz = cf:ToEulerAnglesXYZ()
			createPropertyField("Rot X", string.format("%.1f", math.deg(rx)), yOffset, propsScroll)
			yOffset = yOffset + 22
			createPropertyField("Rot Y", string.format("%.1f", math.deg(ry)), yOffset, propsScroll)
			yOffset = yOffset + 22
			createPropertyField("Rot Z", string.format("%.1f", math.deg(rz)), yOffset, propsScroll)
			yOffset = yOffset + 26
			
			-- Easing
			local easingStyle = selectedPose.EasingStyle and selectedPose.EasingStyle.Name or "Linear"
			local easingDir = selectedPose.EasingDirection and selectedPose.EasingDirection.Name or "Out"
			
			-- Dropdown de Easing Style
			Make("TextLabel", {
				Name = "EasingStyleLabel",
				Text = "Easing Style:",
				Font = FONT_SETTINGS.Font,
				TextSize = 11,
				TextColor3 = COLORS.TextDark,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 80, 0, 18),
				Position = UDim2.new(0, 4, 0, yOffset),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = propsScroll,
			})
			
			local easingStyleBtn = Make("TextButton", {
				Name = "EasingStyleBtn",
				Text = easingStyle,
				Font = FONT_SETTINGS.Font,
				TextSize = 11,
				TextColor3 = COLORS.Text,
				BackgroundColor3 = COLORS.ButtonOff,
				BorderColor3 = COLORS.Border,
				BorderSizePixel = 1,
				Size = UDim2.new(1, -88, 0, 18),
				Position = UDim2.new(0, 84, 0, yOffset),
				Parent = propsScroll,
			})
			styleButton(easingStyleBtn)
			
			easingStyleBtn.MouseButton1Click:Connect(function()
				local styles = {"Linear", "Constant", "Cubic", "CubicV2", "Elastic", "Bounce"}
				local options = {}
				for _, style in ipairs(styles) do
					table.insert(options, {
						name = style,
						label = style,
						callback = function()
							selectedPose.EasingStyle = Enum.PoseEasingStyle[style]
							if selectedPose.updateColor then selectedPose.updateColor() end
							updateProperties()
						end
					})
				end
				local pos = easingStyleBtn.AbsolutePosition
				showContextMenu(options, Vector2.new(pos.X, pos.Y + easingStyleBtn.AbsoluteSize.Y))
			end)
			
			yOffset = yOffset + 22
			
			-- Dropdown de Easing Direction
			Make("TextLabel", {
				Name = "EasingDirLabel",
				Text = "Direction:",
				Font = FONT_SETTINGS.Font,
				TextSize = 11,
				TextColor3 = COLORS.TextDark,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 80, 0, 18),
				Position = UDim2.new(0, 4, 0, yOffset),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = propsScroll,
			})
			
			local easingDirBtn = Make("TextButton", {
				Name = "EasingDirBtn",
				Text = easingDir,
				Font = FONT_SETTINGS.Font,
				TextSize = 11,
				TextColor3 = COLORS.Text,
				BackgroundColor3 = COLORS.ButtonOff,
				BorderColor3 = COLORS.Border,
				BorderSizePixel = 1,
				Size = UDim2.new(1, -88, 0, 18),
				Position = UDim2.new(0, 84, 0, yOffset),
				Parent = propsScroll,
			})
			styleButton(easingDirBtn)
			
			easingDirBtn.MouseButton1Click:Connect(function()
				local dirs = {"In", "Out", "InOut"}
				local options = {}
				for _, dir in ipairs(dirs) do
					table.insert(options, {
						name = dir,
						label = dir,
						callback = function()
							selectedPose.EasingDirection = Enum.PoseEasingDirection[dir]
							if selectedPose.updateColor then selectedPose.updateColor() end
							updateProperties()
						end
					})
				end
				local pos = easingDirBtn.AbsolutePosition
				showContextMenu(options, Vector2.new(pos.X, pos.Y + easingDirBtn.AbsoluteSize.Y))
			end)
			
			yOffset = yOffset + 22
			
			-- Peso
			createPropertyField("Weight", tostring(selectedPose.Weight or 1), yOffset, propsScroll)
			yOffset = yOffset + 22
			
		else
			Make("TextLabel", {
				Name = "NoPose",
				Text = "No pose selected",
				Font = FONT_SETTINGS.Font,
				TextSize = 11,
				TextColor3 = COLORS.TextDark,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -8, 0, 18),
				Position = UDim2.new(0, 4, 0, yOffset),
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = propsScroll,
			})
			yOffset = yOffset + 22
		end
		
		-- Separador
		yOffset = yOffset + 4
		Make("Frame", {
			Name = "Separator2",
			BackgroundColor3 = COLORS.Separator,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -8, 0, 1),
			Position = UDim2.new(0, 4, 0, yOffset),
			Parent = propsScroll,
		})
		yOffset = yOffset + 8
		
		-- Seção: Animation
		Make("TextLabel", {
			Name = "Section_Animation",
			Text = "─ Animation ─",
			Font = FONT_SETTINGS.FontBold,
			TextSize = 11,
			TextColor3 = COLORS.Text,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -8, 0, 16),
			Position = UDim2.new(0, 4, 0, yOffset),
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = propsScroll,
		})
		yOffset = yOffset + 20
		
		createPropertyField("Length", tostring(uiState.animationLength), yOffset, propsScroll)
		yOffset = yOffset + 22
		createPropertyField("Framerate", tostring(_G.animationFramerate or 0.05), yOffset, propsScroll)
		yOffset = yOffset + 22
		createPropertyField("Priority", _G.animationPriority or "Core", yOffset, propsScroll)
		yOffset = yOffset + 22
		createPropertyField("Looping", tostring(_G.loopAnimation or false), yOffset, propsScroll)
		yOffset = yOffset + 22
		
		propsScroll.CanvasSize = UDim2.new(1, 0, 0, yOffset + 10)
	end
	
	-- Expõe função
	ui.updateProperties = updateProperties
	
	-- Atualiza quando selecionar keyframe/pose
	-- (Chamado pelo sistema de animação)
end

-- ============================================================================
-- SEÇÃO 15: BARRA DE PLAYBACK INFERIOR
-- ============================================================================

local function createPlaybackBar()
	ui.playbackBar = Make("Frame", {
		Name = "PlaybackBar",
		BackgroundColor3 = COLORS.Panel,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, WINDOW.PlaybackHeight),
		Position = UDim2.new(0, 0, 1, -WINDOW.PlaybackHeight),
		Parent = ui.mainWindow,
	})
	
	-- Botões de navegação
	local navButtons = {
		{name = "first_frame", label = "|◀", tooltip = "First Frame"},
		{name = "prev_frame", label = "◀", tooltip = "Previous Frame"},
		{name = "play_pause", label = "▶", tooltip = "Play / Pause"},
		{name = "stop", label = "⏹", tooltip = "Stop"},
		{name = "next_frame", label = "▶", tooltip = "Next Frame"},
		{name = "last_frame", label = "▶|", tooltip = "Last Frame"},
	}
	
	local xOffset = 5
	for _, btnData in ipairs(navButtons) do
		local btn = Make("TextButton", {
			Name = btnData.name .. "Btn",
			Text = btnData.label,
			Font = FONT_SETTINGS.FontBold,
			TextSize = 12,
			TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.ButtonOff,
			BorderColor3 = COLORS.Border,
			BorderSizePixel = 1,
			Size = UDim2.new(0, 28, 0, 24),
			Position = UDim2.new(0, xOffset, 0, 4),
			Parent = ui.playbackBar,
		})
		styleButton(btn)
		attachTooltip(btn, btnData.tooltip)
		
		btn.MouseButton1Click:Connect(function()
			if btnData.name == "first_frame" then
				uiState.currentTime = 0
				if _G.currentTime ~= nil then _G.currentTime = 0 end
				if _G.updateCursorPosition then _G.updateCursorPosition() end
			elseif btnData.name == "prev_frame" then
				local step = _G.animationFramerate or 0.05
				uiState.currentTime = math.max(0, uiState.currentTime - step)
				if _G.currentTime ~= nil then _G.currentTime = uiState.currentTime end
				if _G.updateCursorPosition then _G.updateCursorPosition() end
			elseif btnData.name == "play_pause" then
				uiState.isPlaying = not uiState.isPlaying
				btn.Text = uiState.isPlaying and "⏸" or "▶"
				if uiState.isPlaying then
					if _G.playCurrentAnimation then _G.playCurrentAnimation() end
				end
			elseif btnData.name == "stop" then
				uiState.isPlaying = false
				uiState.currentTime = 0
				if _G.currentTime ~= nil then _G.currentTime = 0 end
				if _G.stopAnim ~= nil then _G.stopAnim = true end
				if _G.updateCursorPosition then _G.updateCursorPosition() end
				-- Reseta botão play
				local playBtn = ui.playbackBar:FindFirstChild("play_pauseBtn")
				if playBtn then playBtn.Text = "▶" end
			elseif btnData.name == "next_frame" then
				local step = _G.animationFramerate or 0.05
				uiState.currentTime = math.min(uiState.animationLength, uiState.currentTime + step)
				if _G.currentTime ~= nil then _G.currentTime = uiState.currentTime end
				if _G.updateCursorPosition then _G.updateCursorPosition() end
			elseif btnData.name == "last_frame" then
				uiState.currentTime = uiState.animationLength
				if _G.currentTime ~= nil then _G.currentTime = uiState.animationLength end
				if _G.updateCursorPosition then _G.updateCursorPosition() end
			end
		end)
		
		xOffset = xOffset + 30
	end
	
	-- Slider de tempo
	local timeSlider = Make("Frame", {
		Name = "TimeSlider",
		BackgroundColor3 = COLORS.PanelDark,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 200, 0, 16),
		Position = UDim2.new(0, xOffset + 10, 0, 8),
		Parent = ui.playbackBar,
	})
	
	local sliderFill = Make("Frame", {
		Name = "SliderFill",
		BackgroundColor3 = COLORS.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Parent = timeSlider,
	})
	
	-- Label de tempo atual
	local timeLabel = Make("TextLabel", {
		Name = "TimeLabel",
		Text = "0.00 / 2.00",
		Font = FONT_SETTINGS.Font,
		TextSize = 11,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 100, 0, 20),
		Position = UDim2.new(0, xOffset + 220, 0, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ui.playbackBar,
	})
	
	-- Atualiza label
	local function updateTimeLabel()
		local current = uiState.currentTime or 0
		local total = uiState.animationLength or 2
		timeLabel.Text = string.format("%.2f / %.2f", current, total)
		
		-- Atualiza slider
		local pct = total > 0 and current / total or 0
		sliderFill.Size = UDim2.new(0, pct * timeSlider.AbsoluteSize.X, 1, 0)
	end
	
	ui.updateTimeLabel = updateTimeLabel
	
	-- FPS / Speed
	Make("TextLabel", {
		Name = "FPSLabel",
		Text = "FPS:",
		Font = FONT_SETTINGS.Font,
		TextSize = 11,
		TextColor3 = COLORS.TextDark,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 30, 0, 20),
		Position = UDim2.new(0, xOffset + 330, 0, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ui.playbackBar,
	})
	
	local fpsValue = Make("TextLabel", {
		Name = "FPSValue",
		Text = "60",
		Font = FONT_SETTINGS.Font,
		TextSize = 11,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 25, 0, 20),
		Position = UDim2.new(0, xOffset + 360, 0, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ui.playbackBar,
	})
	
	-- Speed
	Make("TextLabel", {
		Name = "SpeedLabel",
		Text = "Speed:",
		Font = FONT_SETTINGS.Font,
		TextSize = 11,
		TextColor3 = COLORS.TextDark,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 40, 0, 20),
		Position = UDim2.new(0, xOffset + 390, 0, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ui.playbackBar,
	})
	
	local speedValue = Make("TextLabel", {
		Name = "SpeedValue",
		Text = "1.0x",
		Font = FONT_SETTINGS.Font,
		TextSize = 11,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 35, 0, 20),
		Position = UDim2.new(0, xOffset + 430, 0, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ui.playbackBar,
	})
	
	-- Loop toggle na playback bar
	local loopToggle = Make("TextButton", {
		Name = "LoopToggle",
		Text = "Loop",
		Font = FONT_SETTINGS.Font,
		TextSize = 11,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.ButtonOff,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(0, 45, 0, 22),
		Position = UDim2.new(1, -50, 0, 5),
		Parent = ui.playbackBar,
	})
	styleButton(loopToggle, true)
	loopToggle:SetAttribute("Selected", _G.loopAnimation or false)
	loopToggle.MouseButton1Click:Connect(function()
		uiState.isLooping = not uiState.isLooping
		if _G.loopAnimation ~= nil then _G.loopAnimation = uiState.isLooping end
		loopToggle:SetAttribute("Selected", uiState.isLooping)
	end)
end

-- ============================================================================
-- SEÇÃO 16: STATUS BAR
-- ============================================================================

local function createStatusBar()
	ui.statusBar = Make("Frame", {
		Name = "StatusBar",
		BackgroundColor3 = COLORS.Panel,
		BorderColor3 = COLORS.Border,
		BorderSizePixel = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 1, -18),
		Parent = ui.mainWindow,
		Visible = false, -- Oculto por padrão, playback bar já ocupa espaço
	})
	
	Make("TextLabel", {
		Name = "StatusText",
		Text = "Ready",
		Font = FONT_SETTINGS.Font,
		TextSize = 10,
		TextColor3 = COLORS.TextDark,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.new(0, 5, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ui.statusBar,
	})
end

-- ============================================================================
-- SEÇÃO 17: ATALHOS DE TECLADO
-- ============================================================================

local function setupKeyboardShortcuts()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if uiState.modal then return end
		
		local key = input.KeyCode
		
		-- Ctrl+S = Save
		if key == Enum.KeyCode.S and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			if _G.PromptSave then _G.PromptSave() end
			
		-- Ctrl+O = Open
		elseif key == Enum.KeyCode.O and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			if _G.PromptLoad then _G.PromptLoad() end
			
		-- Ctrl+N = New
		elseif key == Enum.KeyCode.N and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			if _G.promptNew then _G.promptNew() end
			
		-- Ctrl+Z = Undo
		elseif key == Enum.KeyCode.Z and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			if _G.undo then _G.undo() end
			
		-- Ctrl+Y = Redo
		elseif key == Enum.KeyCode.Y and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			if _G.redo then _G.redo() end
			
		-- Space = Play/Pause
		elseif key == Enum.KeyCode.Space then
			uiState.isPlaying = not uiState.isPlaying
			if uiState.isPlaying then
				if _G.playCurrentAnimation then _G.playCurrentAnimation() end
			else
				if _G.stopAnim ~= nil then _G.stopAnim = true end
			end
			
		-- Delete = Delete Keyframe
		elseif key == Enum.KeyCode.Delete then
			if _G.selectedKeyframe and _G.deleteKeyframe then
				_G.deleteKeyframe(_G.selectedKeyframe.Time, true)
			end
			
		-- K = Add Keyframe
		elseif key == Enum.KeyCode.K then
			if _G.createKeyframe then
				_G.createKeyframe(uiState.currentTime, true)
			end
			
		-- Setas = Navegar frames
		elseif key == Enum.KeyCode.Left then
			local step = _G.animationFramerate or 0.05
			uiState.currentTime = math.max(0, uiState.currentTime - step)
			if _G.currentTime ~= nil then _G.currentTime = uiState.currentTime end
			if _G.updateCursorPosition then _G.updateCursorPosition() end
			
		elseif key == Enum.KeyCode.Right then
			local step = _G.animationFramerate or 0.05
			uiState.currentTime = math.min(uiState.animationLength, uiState.currentTime + step)
			if _G.currentTime ~= nil then _G.currentTime = uiState.currentTime end
			if _G.updateCursorPosition then _G.updateCursorPosition() end
		end
	end)
end

-- ============================================================================
-- SEÇÃO 18: INTEGRAÇÃO COM SISTEMA EXISTENTE
-- ============================================================================

local function integrateWithExistingSystem()
	--[[
		Esta função conecta a UI às variáveis e funções globais já existentes
		do sistema de animação. Não recria nenhuma lógica.
	]]
	
	-- Sincroniza variáveis globais
	if _G.animationLength then
		uiState.animationLength = _G.animationLength
	end
	
	if _G.currentTime then
		uiState.currentTime = _G.currentTime
	end
	
	if _G.loopAnimation ~= nil then
		uiState.isLooping = _G.loopAnimation
	end
	
	if _G.rotateMode ~= nil then
		uiState.selectedTool = _G.rotateMode and "rotate" or "move"
	end
	
	if _G.rotateStep then
		uiState.rotateStep = _G.rotateStep
	end
	
	if _G.moveStep then
		uiState.moveStep = _G.moveStep
	end
	
	-- Conecta eventos de atualização
	-- (O sistema existente deve chamar estas funções quando dados mudam)
	
	-- Hook para updateCursorPosition existente
	if _G.updateCursorPosition then
		local originalUpdateCursor = _G.updateCursorPosition
		_G.updateCursorPosition = function(...)
			originalUpdateCursor(...)
			-- Atualiza UI
			if ui.updateTimeLabel then
				ui.updateTimeLabel()
			end
		end
	end
	
	-- Hook para createKeyframe
	if _G.createKeyframe then
		local originalCreateKeyframe = _G.createKeyframe
		_G.createKeyframe = function(...)
			local result = originalCreateKeyframe(...)
			if ui.refreshTimeline then
				ui.refreshTimeline()
			end
			return result
		end
	end
	
	-- Hook para deleteKeyframe
	if _G.deleteKeyframe then
		local originalDeleteKeyframe = _G.deleteKeyframe
		_G.deleteKeyframe = function(...)
			originalDeleteKeyframe(...)
			if ui.refreshTimeline then
				ui.refreshTimeline()
			end
		end
	end
	
	-- Hook para moveKeyframe
	if _G.moveKeyframe then
		local originalMoveKeyframe = _G.moveKeyframe
		_G.moveKeyframe = function(...)
			originalMoveKeyframe(...)
			if ui.refreshTimeline then
				ui.refreshTimeline()
			end
		end
	end
	
	-- Hook para selectPartUI
	if _G.selectPartUI then
		local originalSelectPartUI = _G.selectPartUI
		_G.selectPartUI = function(part)
			originalSelectPartUI(part)
			if ui.updateProperties then
				ui.updateProperties()
			end
		end
	end
	
	-- Hook para setHandleSelection
	if _G.setHandleSelection then
		local originalSetHandle = _G.setHandleSelection
		_G.setHandleSelection = function(item)
			originalSetHandle(item)
			if ui.updateProperties then
				ui.updateProperties()
			end
		end
	end
	
	-- Hook para resetHandleSelection
	if _G.resetHandleSelection then
		local originalResetHandle = _G.resetHandleSelection
		_G.resetHandleSelection = function()
			originalResetHandle()
			if ui.updateProperties then
				ui.updateProperties()
			end
		end
	end
end

-- ============================================================================
-- SEÇÃO 19: INICIALIZAÇÃO
-- ============================================================================

local function initialize()
	-- Cria a janela principal
	createMainWindow()
	
	-- Cria todos os componentes
	createTitleBar()
	createMenuBar()
	createToolbar()
	createLeftPanel()
	createTimeline()
	createRightPanel()
	createPlaybackBar()
	createStatusBar()
	createTooltipSystem()
	
	-- Configura atalhos
	setupKeyboardShortcuts()
	
	-- Integra com sistema existente
	integrateWithExistingSystem()
	
	-- Expõe referências da UI para o sistema
	_G.timelineUI = ui.mainWindow
	_G.saveUI = nil -- Criado sob demanda
	_G.loadUI = nil -- Criado sob demanda
	_G.stopAnimUI = nil -- Criado sob demanda
	_G.timeChangeUI = nil -- Criado sob demanda
	
	-- Marca como inicializado
	print("[AnimationEditor UI] Interface inicializada com sucesso.")
	print("[AnimationEditor UI] Conectado ao sistema de animação existente.")
end

-- ============================================================================
-- SEÇÃO 20: EXECUÇÃO
-- ============================================================================

-- Aguarda o sistema de animação estar pronto
local function waitForAnimationSystem()
	local maxAttempts = 50
	local attempts = 0
	
	while attempts < maxAttempts do
		if _G.Make and (_G.partList or _G.keyframeList) then
			return true
		end
		attempts = attempts + 1
		task.wait(0.1)
	end
	
	warn("[AnimationEditor UI] Sistema de animação não detectado. Inicializando UI standalone.")
	return false
end

-- Inicializa
task.spawn(function()
	waitForAnimationSystem()
	initialize()
end)

--[[
    ============================================================================
    FIM DO SCRIPT
    ============================================================================
    
    RESUMO DA ESTRUTURA CRIADA:
    
    ScreenGui
    └── AnimationEditorWindow (Frame principal, arrastável, redimensionável)
        ├── TitleBar (22px)
        │   ├── MenuBar (File, Edit, View, Animation, Help)
        │   ├── TitleText ("Animation Editor")
        │   ├── MinimizeButton
        │   ├── MaximizeButton
        │   └── CloseButton
        ├── Toolbar (28px)
        │   ├── Grupo Arquivo: New, Open, Save, SaveAs, Export, Import
        │   ├── Grupo Playback: Play, Pause, Stop, Loop
        │   ├── Grupo Edição: Undo, Redo
        │   ├── Grupo Ferramentas: Rotate, Move, Scale, Local, World, Snap, Interpolate
        │   ├── Grupo Keyframe: +Kf, -Kf, Duplicate, Copy, Paste
        │   └── Grupo Bone: +Bone, -Bone, Mirror, Reset
        ├── LeftPanel (160px) - Lista de Partes
        │   ├── Header ("Parts")
        │   ├── SearchBox
        │   └── PartListScroll (ScrollingFrame)
        ├── TimelinePanel (centro)
        │   ├── KeyframeContainer (ScrollingFrame)
        │   │   ├── TimeListFrame (Régua de tempo)
        │   │   ├── TimelineFrame (Área de keyframes)
        │   │   ├── GridFrame (Grade + Poses)
        │   │   └── Cursor (Arrastável, vermelho/azul)
        │   ├── ZoomIn / ZoomOut
        │   └── ZoomLabel
        ├── RightPanel (200px) - Propriedades
        │   ├── Header ("Properties")
        │   └── PropertiesScroll
        │       ├── Seção Keyframe (Frame, Time, Name)
        │       ├── Seção Pose (Part, Pos, Rot, Easing, Weight)
        │       └── Seção Animation (Length, Framerate, Priority, Loop)
        ├── PlaybackBar (32px)
        │   ├── First, Prev, Play/Pause, Stop, Next, Last
        │   ├── TimeSlider + TimeLabel
        │   ├── FPS, Speed
        │   └── LoopToggle
        ├── StatusBar (opcional)
        │   └── StatusText
        ├── Tooltip (overlay)
        └── ContextMenu (overlay)
    
    TODAS AS FUNÇÕES DO SISTEMA EXISTENTE SÃO CHAMADAS, NUNCA REIMPLEMENTADAS.
    
    FUNÇÕES CHAMADAS:
    - createKeyframe(), deleteKeyframe(), moveKeyframe()
    - undo(), redo()
    - copyPose(), pastePoses(), resetCopyPoseList()
    - updateCursorPosition(), updateTimeLabels(), adjustKeyframes()
    - selectPartUI(), unselectPartUI()
    - setHandleSelection(), resetHandleSelection(), getHandleSelection()
    - updateProxyPart()
    - playCurrentAnimation()
    - saveCurrentAnimation(), PromptSave(), PromptLoad()
    - loadCurrentAnimation(), loadImportAnim()
    - resetAnimation(), setAnimationLength()
    - promptNew(), promptChangeLength(), promptTickChange()
    - promptSnapChange(), promptAddTime(), promptRemoveTime()
    - promptChangePriority(), promptChangeLooping()
    - menuRequest(), exitPlugin()
    - importFbxAnimation()
    - keyframeContextMenu(), keyframePositionShift()
    - displayDropDownMenu(), showTextEntryDialog(), showConfirmationDialog()
    - initializePose(), deletePose()
    - getKeyframe(), getKeyframeData(), getCurrentKeyframeData()
    - getClosestPose(), getClosestNextPose()
    - getMotorC1()
    - lockUndoStep(), registerUndo()
    - MenuHandler.SetEasingStyle()
    
    ============================================================================
]]
