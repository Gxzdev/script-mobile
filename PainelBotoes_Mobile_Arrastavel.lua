-- PainelBotoes.lua
-- COMO USAR:
-- 1. StarterPlayer > StarterPlayerScripts > novo LocalScript > cole este código
-- 2. Dê Play para testar
--
-- COMO FUNCIONA:
-- - Versão MOBILE: não depende de F1/F3/F4 nem de teclado.
-- - Cada ação possui um botão de toque para executar a mensagem.
-- - Na Página 2: 🚁 Drone e 🚀 Míssil expandem os campos e possuem botões de toque.
-- - O FLY usa o joystick padrão do Roblox + botões de subir/descer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

-- SOMENTE MOBILE/TABLET
if not UserInputService.TouchEnabled then
    return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local canalGeral = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

local contador = 0
local botoes = {}
local todosBotoesFloat = {}
local visaoAtiva = false
local highlights = {}
local pickerAlvo = nil
local pickerHue, pickerSat, pickerVal = 0, 1, 1

local FORMAS = {
	redondo = UDim.new(1, 0),
	quadrado = UDim.new(0, 6),
	arredondado = UDim.new(0, 14),
}

local tamanhoAtual = 56
local formaAtual = "redondo"
local tamanhoStaged = tamanhoAtual
local formaStaged = formaAtual

local COR_FUNDO = Color3.fromRGB(30, 30, 36)
local COR_FUNDO_CLARO = Color3.fromRGB(42, 42, 50)
local COR_TITULO_BG = Color3.fromRGB(22, 22, 27)
local COR_ACCENT_1 = Color3.fromRGB(99, 102, 241)
local COR_ACCENT_2 = Color3.fromRGB(59, 130, 246)
local COR_SUCESSO = Color3.fromRGB(52, 199, 89)
local COR_SUCESSO_2 = Color3.fromRGB(34, 160, 70)
local COR_PERIGO = Color3.fromRGB(255, 69, 58)
local COR_PERIGO_2 = Color3.fromRGB(210, 45, 40)
local COR_NEUTRO = Color3.fromRGB(120, 120, 130)
local COR_TEXTO = Color3.new(1, 1, 1)
local COR_TEXTO_SEC = Color3.fromRGB(190, 190, 200)

local function estilizar(obj, corBorda)
	obj.BackgroundTransparency = 0
	local stroke = Instance.new("UIStroke")
	stroke.Color = corBorda
	stroke.Transparency = 0
	stroke.Thickness = 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = obj
end

local function criarBarraTitulo(pai, icone, texto)
	local barra = Instance.new("Frame")
	barra.Size = UDim2.new(1, 0, 0, 38)
	barra.BackgroundColor3 = COR_TITULO_BG
	barra.BackgroundTransparency = 0
	barra.BorderSizePixel = 0
	barra.ZIndex = pai.ZIndex
	barra.Active = true
	barra.Parent = pai

	local barraCorner = Instance.new("UICorner")
	barraCorner.CornerRadius = UDim.new(0, 16)
	barraCorner.Parent = barra

	local mascara = Instance.new("Frame")
	mascara.Size = UDim2.new(1, 0, 0, 16)
	mascara.Position = UDim2.new(0, 0, 1, -16)
	mascara.BackgroundColor3 = COR_TITULO_BG
	mascara.BackgroundTransparency = 0
	mascara.BorderSizePixel = 0
	mascara.ZIndex = pai.ZIndex
	mascara.Parent = barra

	local iconeLabel = Instance.new("TextLabel")
	iconeLabel.Size = UDim2.new(0, 34, 1, 0)
	iconeLabel.Position = UDim2.new(0, 8, 0, 0)
	iconeLabel.BackgroundTransparency = 1
	iconeLabel.Text = icone
	iconeLabel.Font = Enum.Font.GothamBold
	iconeLabel.TextSize = 18
	iconeLabel.TextColor3 = COR_TEXTO
	iconeLabel.ZIndex = pai.ZIndex
	iconeLabel.Parent = barra

	local textoLabel = Instance.new("TextLabel")
	textoLabel.Size = UDim2.new(1, -46, 1, 0)
	textoLabel.Position = UDim2.new(0, 42, 0, 0)
	textoLabel.BackgroundTransparency = 1
	textoLabel.Text = texto
	textoLabel.TextXAlignment = Enum.TextXAlignment.Left
	textoLabel.Font = Enum.Font.GothamBold
	textoLabel.TextSize = 17
	textoLabel.TextColor3 = COR_TEXTO
	textoLabel.ZIndex = pai.ZIndex
	textoLabel.Parent = barra

	return barra
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PainelGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true

-- Ajusta hubs grandes para telas de celular/tablet.
local function adicionarEscalaMobile(gui, larguraBase, alturaBase)
	local escala = Instance.new("UIScale")
	local camera = workspace.CurrentCamera
	local function atualizar()
		camera = workspace.CurrentCamera
		if not camera then return end
		local viewport = camera.ViewportSize
		local sx = (viewport.X * 0.92) / larguraBase
		local sy = (viewport.Y * 0.82) / alturaBase
		escala.Scale = math.min(1, sx, sy)
	end
	escala.Parent = gui
	atualizar()
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(atualizar)
	end
	return escala
end

local function tornarFrameArrastavel(handle, alvo)
	local dragging = false
	local dragInput, dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = alvo.Position

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
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			alvo.Position = UDim2.new(alvo.Position.X.Scale, startPos.X.Offset + delta.X, alvo.Position.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function conectarArrasteArea(area, callback)
	local arrastando = false

	local function atualizar(posX, posY)
		local relX = math.clamp((posX - area.AbsolutePosition.X) / area.AbsoluteSize.X, 0, 1)
		local relY = math.clamp((posY - area.AbsolutePosition.Y) / area.AbsoluteSize.Y, 0, 1)
		callback(relX, relY)
	end

	area.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			arrastando = true
			atualizar(input.Position.X, input.Position.Y)
		end
	end)

	area.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			arrastando = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if arrastando and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			atualizar(input.Position.X, input.Position.Y)
		end
	end)
end

-- ============================================================
-- BOTÃO CONFIGURAÇÕES
-- ============================================================
local configBtn = Instance.new("TextButton")
configBtn.Size = UDim2.new(0, 64, 0, 64)
configBtn.Position = UDim2.new(0, 16, 0, 16)
configBtn.Text = "⚙"
configBtn.Font = Enum.Font.GothamBold
configBtn.TextSize = 26
configBtn.BackgroundColor3 = COR_ACCENT_2
configBtn.TextColor3 = COR_TEXTO
configBtn.AutoButtonColor = false
configBtn.ZIndex = 5
configBtn.Parent = screenGui

local configCorner = Instance.new("UICorner")
configCorner.CornerRadius = UDim.new(1, 0)
configCorner.Parent = configBtn

estilizar(configBtn, Color3.fromRGB(180, 200, 255))

local configLabel = Instance.new("TextLabel")
configLabel.Size = UDim2.new(0, 64, 0, 16)
configLabel.Position = UDim2.new(0, 16, 0, 82)
configLabel.BackgroundTransparency = 1
configLabel.Text = "MENU"
configLabel.Font = Enum.Font.GothamBold
configLabel.TextSize = 10
configLabel.TextColor3 = COR_TEXTO
configLabel.ZIndex = 5
configLabel.Parent = screenGui

-- ============================================================
-- PÁGINA 1
-- ============================================================
local painel = Instance.new("Frame")
painel.Size = UDim2.new(0, 350, 0, 518)
painel.Position = UDim2.new(0, 92, 0, 20)
painel.BackgroundColor3 = COR_FUNDO
painel.BackgroundTransparency = 0
painel.BorderSizePixel = 0
local painelScale = Instance.new("UIScale")
painelScale.Scale = 1.25
painelScale.Parent = painel
painel.Visible = false
painel.ZIndex = 5
painel.Parent = screenGui
adicionarEscalaMobile(painel, 350, 518)

local painelCorner = Instance.new("UICorner")
painelCorner.CornerRadius = UDim.new(0, 16)
painelCorner.Parent = painel

local painelStroke = Instance.new("UIStroke")
painelStroke.Color = Color3.fromRGB(90, 90, 100)
painelStroke.Transparency = 0
painelStroke.Thickness = 1
painelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
painelStroke.Parent = painel

local titulo = criarBarraTitulo(painel, "⚙", "Configurações")
titulo.Active = true
tornarFrameArrastavel(titulo, painel)

local adicionarBtn = Instance.new("TextButton")
adicionarBtn.Size = UDim2.new(1, -40, 0, 40)
adicionarBtn.Position = UDim2.new(0, 20, 0, 52)
adicionarBtn.Text = "+  Adicionar Botão"
adicionarBtn.Font = Enum.Font.GothamBold
adicionarBtn.TextSize = 16
adicionarBtn.BackgroundColor3 = COR_SUCESSO
adicionarBtn.TextColor3 = COR_TEXTO
adicionarBtn.AutoButtonColor = false
adicionarBtn.ZIndex = 5
adicionarBtn.Parent = painel

local adicionarCorner = Instance.new("UICorner")
adicionarCorner.CornerRadius = UDim.new(0, 10)
adicionarCorner.Parent = adicionarBtn

estilizar(adicionarBtn, Color3.fromRGB(180, 255, 200))

local visaoLinha = Instance.new("Frame")
visaoLinha.Size = UDim2.new(1, -40, 0, 40)
visaoLinha.Position = UDim2.new(0, 20, 0, 100)
visaoLinha.BackgroundColor3 = COR_FUNDO_CLARO
visaoLinha.BorderSizePixel = 0
visaoLinha.ZIndex = 5
visaoLinha.Parent = painel

local visaoLinhaCorner = Instance.new("UICorner")
visaoLinhaCorner.CornerRadius = UDim.new(0, 10)
visaoLinhaCorner.Parent = visaoLinha

local visaoLabel = Instance.new("TextLabel")
visaoLabel.Size = UDim2.new(1, -74, 1, 0)
visaoLabel.Position = UDim2.new(0, 14, 0, 0)
visaoLabel.BackgroundTransparency = 1
visaoLabel.Text = "👀  Ver através de paredes"
visaoLabel.TextXAlignment = Enum.TextXAlignment.Left
visaoLabel.Font = Enum.Font.GothamMedium
visaoLabel.TextSize = 14
visaoLabel.TextColor3 = COR_TEXTO_SEC
visaoLabel.ZIndex = 5
visaoLabel.Parent = visaoLinha

local visaoSwitch = Instance.new("TextButton")
visaoSwitch.Size = UDim2.new(0, 58, 0, 28)
visaoSwitch.Position = UDim2.new(1, -64, 0.5, -14)
visaoSwitch.Text = "OFF"
visaoSwitch.Font = Enum.Font.GothamBold
visaoSwitch.TextSize = 12
visaoSwitch.BackgroundColor3 = COR_NEUTRO
visaoSwitch.TextColor3 = COR_TEXTO
visaoSwitch.AutoButtonColor = false
visaoSwitch.ZIndex = 5
visaoSwitch.Parent = visaoLinha

local visaoSwitchCorner = Instance.new("UICorner")
visaoSwitchCorner.CornerRadius = UDim.new(1, 0)
visaoSwitchCorner.Parent = visaoSwitch

local tamanhoLinha = Instance.new("Frame")
tamanhoLinha.Size = UDim2.new(1, -40, 0, 40)
tamanhoLinha.Position = UDim2.new(0, 20, 0, 148)
tamanhoLinha.BackgroundColor3 = COR_FUNDO_CLARO
tamanhoLinha.BorderSizePixel = 0
tamanhoLinha.ZIndex = 5
tamanhoLinha.Parent = painel

local tamanhoLinhaCorner = Instance.new("UICorner")
tamanhoLinhaCorner.CornerRadius = UDim.new(0, 10)
tamanhoLinhaCorner.Parent = tamanhoLinha

local tamanhoLabel = Instance.new("TextLabel")
tamanhoLabel.Size = UDim2.new(1, -50, 1, 0)
tamanhoLabel.Position = UDim2.new(0, 14, 0, 0)
tamanhoLabel.BackgroundTransparency = 1
tamanhoLabel.Text = "📐  Tamanho e forma"
tamanhoLabel.TextXAlignment = Enum.TextXAlignment.Left
tamanhoLabel.Font = Enum.Font.GothamMedium
tamanhoLabel.TextSize = 14
tamanhoLabel.TextColor3 = COR_TEXTO_SEC
tamanhoLabel.ZIndex = 5
tamanhoLabel.Parent = tamanhoLinha

local tamanhoEditarBtn = Instance.new("TextButton")
tamanhoEditarBtn.Size = UDim2.new(0, 28, 0, 28)
tamanhoEditarBtn.Position = UDim2.new(1, -34, 0.5, -14)
tamanhoEditarBtn.Text = ""
tamanhoEditarBtn.BackgroundColor3 = COR_ACCENT_2
tamanhoEditarBtn.AutoButtonColor = false
tamanhoEditarBtn.ZIndex = 5
tamanhoEditarBtn.Parent = tamanhoLinha

local tamanhoEditarCorner = Instance.new("UICorner")
tamanhoEditarCorner.CornerRadius = UDim.new(0, 8)
tamanhoEditarCorner.Parent = tamanhoEditarBtn

estilizar(tamanhoEditarBtn, Color3.fromRGB(180, 200, 255))

local paginaLinha = Instance.new("Frame")
paginaLinha.Size = UDim2.new(1, -40, 0, 40)
paginaLinha.Position = UDim2.new(0, 20, 0, 196)
paginaLinha.BackgroundColor3 = COR_FUNDO_CLARO
paginaLinha.BorderSizePixel = 0
paginaLinha.ZIndex = 5
paginaLinha.Parent = painel

local paginaLinhaCorner = Instance.new("UICorner")
paginaLinhaCorner.CornerRadius = UDim.new(0, 10)
paginaLinhaCorner.Parent = paginaLinha

local paginaLabel = Instance.new("TextLabel")
paginaLabel.Size = UDim2.new(1, -80, 1, 0)
paginaLabel.Position = UDim2.new(0, 14, 0, 0)
paginaLabel.BackgroundTransparency = 1
paginaLabel.Text = "🗂  Página 2"
paginaLabel.TextXAlignment = Enum.TextXAlignment.Left
paginaLabel.Font = Enum.Font.GothamMedium
paginaLabel.TextSize = 14
paginaLabel.TextColor3 = COR_TEXTO_SEC
paginaLabel.ZIndex = 5
paginaLabel.Parent = paginaLinha

local paginaAbrirBtn = Instance.new("TextButton")
paginaAbrirBtn.Size = UDim2.new(0, 64, 0, 28)
paginaAbrirBtn.Position = UDim2.new(1, -70, 0.5, -14)
paginaAbrirBtn.Text = "Abrir"
paginaAbrirBtn.Font = Enum.Font.GothamBold
paginaAbrirBtn.TextSize = 12
paginaAbrirBtn.BackgroundColor3 = COR_ACCENT_1
paginaAbrirBtn.TextColor3 = COR_TEXTO
paginaAbrirBtn.AutoButtonColor = false
paginaAbrirBtn.ZIndex = 5
paginaAbrirBtn.Parent = paginaLinha

local paginaAbrirCorner = Instance.new("UICorner")
paginaAbrirCorner.CornerRadius = UDim.new(0, 8)
paginaAbrirCorner.Parent = paginaAbrirBtn

estilizar(paginaAbrirBtn, Color3.fromRGB(210, 200, 255))

local lista = Instance.new("ScrollingFrame")
lista.Size = UDim2.new(1, -40, 0, 210)
lista.Position = UDim2.new(0, 20, 0, 244)
lista.BackgroundTransparency = 1
lista.ScrollBarThickness = 5
lista.ScrollBarImageColor3 = COR_ACCENT_2
lista.CanvasSize = UDim2.new(0, 0, 0, 0)
lista.ZIndex = 5
lista.Parent = painel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = lista

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	lista.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end)

local fecharBtn = Instance.new("TextButton")
fecharBtn.Size = UDim2.new(1, -40, 0, 40)
fecharBtn.Position = UDim2.new(0, 20, 0, 466)
fecharBtn.Text = "✖  Fechar Painel"
fecharBtn.Font = Enum.Font.GothamBold
fecharBtn.TextSize = 15
fecharBtn.BackgroundColor3 = COR_PERIGO
fecharBtn.TextColor3 = COR_TEXTO
fecharBtn.AutoButtonColor = false
fecharBtn.ZIndex = 5
fecharBtn.Parent = painel

local fecharCorner = Instance.new("UICorner")
fecharCorner.CornerRadius = UDim.new(0, 10)
fecharCorner.Parent = fecharBtn

estilizar(fecharBtn, Color3.fromRGB(255, 190, 190))

fecharBtn.MouseButton1Click:Connect(function()
	painel.Visible = false
end)

-- ============================================================
-- PÁGINA 2
-- ============================================================
local painel2 = Instance.new("Frame")
painel2.Size = UDim2.new(0, 350, 0, 502)
painel2.Position = UDim2.new(0, 92, 0, 20)
painel2.BackgroundColor3 = COR_FUNDO
painel2.BackgroundTransparency = 0
painel2.BorderSizePixel = 0
painel2.Visible = false
painel2.ZIndex = 5
painel2.Parent = screenGui
adicionarEscalaMobile(painel2, 350, 502)

local painel2Corner = Instance.new("UICorner")
painel2Corner.CornerRadius = UDim.new(0, 16)
painel2Corner.Parent = painel2

local painel2Stroke = Instance.new("UIStroke")
painel2Stroke.Color = Color3.fromRGB(90, 90, 100)
painel2Stroke.Transparency = 0
painel2Stroke.Thickness = 1
painel2Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
painel2Stroke.Parent = painel2

local titulo2 = criarBarraTitulo(painel2, "🗂", "Página 2")
titulo2.Active = true
tornarFrameArrastavel(titulo2, painel2)

-- ====== 🚁 Drone (Local digitado por você) ======
local droneBtn = Instance.new("TextButton")
droneBtn.Size = UDim2.new(1, -40, 0, 50)
droneBtn.Position = UDim2.new(0, 20, 0, 60)
droneBtn.Text = "🚁  Drone"
droneBtn.Font = Enum.Font.GothamBold
droneBtn.TextSize = 16
droneBtn.BackgroundColor3 = COR_ACCENT_2
droneBtn.TextColor3 = COR_TEXTO
droneBtn.AutoButtonColor = false
droneBtn.ZIndex = 5
droneBtn.Parent = painel2

local droneCorner = Instance.new("UICorner")
droneCorner.CornerRadius = UDim.new(0, 10)
droneCorner.Parent = droneBtn

estilizar(droneBtn, Color3.fromRGB(180, 200, 255))

local droneOpcoes = Instance.new("Frame")
droneOpcoes.Size = UDim2.new(1, -40, 0, 114)
droneOpcoes.Position = UDim2.new(0, 20, 0, 118)
droneOpcoes.BackgroundTransparency = 1
droneOpcoes.Visible = false
droneOpcoes.ZIndex = 5
droneOpcoes.Parent = painel2

local droneOpcoesLayout = Instance.new("UIListLayout")
droneOpcoesLayout.Padding = UDim.new(0, 8)
droneOpcoesLayout.Parent = droneOpcoes

local dronePreview = Instance.new("TextLabel")
dronePreview.Size = UDim2.new(1, 0, 0, 36)
dronePreview.BackgroundColor3 = COR_FUNDO_CLARO
dronePreview.Text = "  .Explosao de drone fpv - local  raio da explosão 7m"
dronePreview.TextXAlignment = Enum.TextXAlignment.Left
dronePreview.TextWrapped = true
dronePreview.Font = Enum.Font.Gotham
dronePreview.TextSize = 12
dronePreview.TextColor3 = COR_TEXTO_SEC
dronePreview.ZIndex = 5
dronePreview.Parent = droneOpcoes

local dronePreviewCorner = Instance.new("UICorner")
dronePreviewCorner.CornerRadius = UDim.new(0, 8)
dronePreviewCorner.Parent = dronePreview

local campoLocalDrone = Instance.new("TextBox")
campoLocalDrone.Size = UDim2.new(1, 0, 0, 36)
campoLocalDrone.PlaceholderText = "Local (ex: frente da praça)"
campoLocalDrone.Text = ""
campoLocalDrone.Font = Enum.Font.GothamBold
campoLocalDrone.TextSize = 14
campoLocalDrone.BackgroundColor3 = COR_FUNDO
campoLocalDrone.TextColor3 = COR_TEXTO
campoLocalDrone.ClearTextOnFocus = false
campoLocalDrone.ZIndex = 5
campoLocalDrone.Parent = droneOpcoes

local campoLocalDroneCorner = Instance.new("UICorner")
campoLocalDroneCorner.CornerRadius = UDim.new(0, 8)
campoLocalDroneCorner.Parent = campoLocalDrone

campoLocalDrone:GetPropertyChangedSignal("Text"):Connect(function()
	dronePreview.Text = "  .Explosao de drone fpv - local " .. campoLocalDrone.Text .. " - raio da explosão 7m"
end)

local atacarDroneBtn = Instance.new("TextButton")
atacarDroneBtn.Size = UDim2.new(1, 0, 0, 36)
atacarDroneBtn.Text = "🎯  Atacar"
atacarDroneBtn.Font = Enum.Font.GothamBold
atacarDroneBtn.TextSize = 15
atacarDroneBtn.BackgroundColor3 = COR_ACCENT_2
atacarDroneBtn.TextColor3 = COR_TEXTO
atacarDroneBtn.AutoButtonColor = false
atacarDroneBtn.ZIndex = 5
atacarDroneBtn.Parent = droneOpcoes

local atacarDroneCorner = Instance.new("UICorner")
atacarDroneCorner.CornerRadius = UDim.new(0, 8)
atacarDroneCorner.Parent = atacarDroneBtn

estilizar(atacarDroneBtn, Color3.fromRGB(180, 200, 255))

atacarDroneBtn.MouseButton1Click:Connect(function()
	if campoLocalDrone.Text == "" then return end
	local comando = ".Explosao de drone fpv - local " .. campoLocalDrone.Text .. " - raio da explosão 7m"
	canalGeral:SendAsync(comando)
end)

droneBtn.MouseButton1Click:Connect(function()
	droneOpcoes.Visible = not droneOpcoes.Visible
end)

-- ====== 🚀 Míssil (Loc e Alvo digitados por você) ======
local misselBtn = Instance.new("TextButton")
misselBtn.Size = UDim2.new(1, -40, 0, 50)
misselBtn.Position = UDim2.new(0, 20, 0, 244)
misselBtn.Text = "🚀  Míssil"
misselBtn.Font = Enum.Font.GothamBold
misselBtn.TextSize = 16
misselBtn.BackgroundColor3 = COR_PERIGO
misselBtn.TextColor3 = COR_TEXTO
misselBtn.AutoButtonColor = false
misselBtn.ZIndex = 5
misselBtn.Parent = painel2

local misselCorner = Instance.new("UICorner")
misselCorner.CornerRadius = UDim.new(0, 10)
misselCorner.Parent = misselBtn

estilizar(misselBtn, Color3.fromRGB(255, 190, 190))

local misselOpcoes = Instance.new("Frame")
misselOpcoes.Size = UDim2.new(1, -40, 0, 150)
misselOpcoes.Position = UDim2.new(0, 20, 0, 302)
misselOpcoes.BackgroundTransparency = 1
misselOpcoes.Visible = false
misselOpcoes.ZIndex = 5
misselOpcoes.Parent = painel2

local misselOpcoesLayout = Instance.new("UIListLayout")
misselOpcoesLayout.Padding = UDim.new(0, 8)
misselOpcoesLayout.Parent = misselOpcoes

local misselPreview = Instance.new("TextLabel")
misselPreview.Size = UDim2.new(1, 0, 0, 36)
misselPreview.BackgroundColor3 = COR_FUNDO_CLARO
misselPreview.Text = "  .Lançamento de míssil de cruzeiro — [BGM-109 Tomahawk] — [Loc: ]"
misselPreview.TextXAlignment = Enum.TextXAlignment.Left
misselPreview.TextWrapped = true
misselPreview.Font = Enum.Font.Gotham
misselPreview.TextSize = 12
misselPreview.TextColor3 = COR_TEXTO_SEC
misselPreview.ZIndex = 5
misselPreview.Parent = misselOpcoes

local misselPreviewCorner = Instance.new("UICorner")
misselPreviewCorner.CornerRadius = UDim.new(0, 8)
misselPreviewCorner.Parent = misselPreview

local campoLoc = Instance.new("TextBox")
campoLoc.Size = UDim2.new(1, 0, 0, 36)
campoLoc.PlaceholderText = "Loc (ex: Frente da praça)"
campoLoc.Text = ""
campoLoc.Font = Enum.Font.GothamBold
campoLoc.TextSize = 14
campoLoc.BackgroundColor3 = COR_FUNDO
campoLoc.TextColor3 = COR_TEXTO
campoLoc.ClearTextOnFocus = false
campoLoc.ZIndex = 5
campoLoc.Parent = misselOpcoes

local campoLocCorner = Instance.new("UICorner")
campoLocCorner.CornerRadius = UDim.new(0, 8)
campoLocCorner.Parent = campoLoc

local campoAlvo = Instance.new("TextBox")
campoAlvo.Size = UDim2.new(1, 0, 0, 36)
campoAlvo.PlaceholderText = "Alvo (opcional)"
campoAlvo.Text = ""
campoAlvo.Font = Enum.Font.Gotham
campoAlvo.TextSize = 14
campoAlvo.BackgroundColor3 = COR_FUNDO
campoAlvo.TextColor3 = COR_TEXTO
campoAlvo.ClearTextOnFocus = false
campoAlvo.ZIndex = 5
campoAlvo.Parent = misselOpcoes

local campoAlvoCorner = Instance.new("UICorner")
campoAlvoCorner.CornerRadius = UDim.new(0, 8)
campoAlvoCorner.Parent = campoAlvo

local function atualizarPreviewMissil()
	local loc = campoLoc.Text ~= "" and campoLoc.Text or ""
	local texto = "  .Lançamento de míssil de cruzeiro — [BGM-109 Tomahawk] — [Loc: " .. loc .. "]"
	if campoAlvo.Text ~= "" then
		texto = texto .. " [Alvo: " .. campoAlvo.Text .. "]"
	end
	misselPreview.Text = texto
end

campoLoc:GetPropertyChangedSignal("Text"):Connect(atualizarPreviewMissil)
campoAlvo:GetPropertyChangedSignal("Text"):Connect(atualizarPreviewMissil)

local lancarBtn = Instance.new("TextButton")
lancarBtn.Size = UDim2.new(1, 0, 0, 36)
lancarBtn.Text = "🚀  Lançar"
lancarBtn.Font = Enum.Font.GothamBold
lancarBtn.TextSize = 15
lancarBtn.BackgroundColor3 = COR_PERIGO
lancarBtn.TextColor3 = COR_TEXTO
lancarBtn.AutoButtonColor = false
lancarBtn.ZIndex = 5
lancarBtn.Parent = misselOpcoes

local lancarCorner = Instance.new("UICorner")
lancarCorner.CornerRadius = UDim.new(0, 8)
lancarCorner.Parent = lancarBtn

estilizar(lancarBtn, Color3.fromRGB(255, 190, 190))

lancarBtn.MouseButton1Click:Connect(function()
	if campoLoc.Text == "" then return end
	local comando = ".Lançamento de míssil de cruzeiro — [BGM-109 Tomahawk] — [Loc: " .. campoLoc.Text .. "]"
	if campoAlvo.Text ~= "" then
		comando = comando .. " [Alvo: " .. campoAlvo.Text .. "]"
	end
	canalGeral:SendAsync(comando)
end)

misselBtn.MouseButton1Click:Connect(function()
	misselOpcoes.Visible = not misselOpcoes.Visible
end)

local voltarBtn = Instance.new("TextButton")
voltarBtn.Size = UDim2.new(1, -40, 0, 40)
voltarBtn.Position = UDim2.new(0, 20, 0, 448)
voltarBtn.Text = "←  Voltar"
voltarBtn.Font = Enum.Font.GothamBold
voltarBtn.TextSize = 15
voltarBtn.BackgroundColor3 = COR_ACCENT_2
voltarBtn.TextColor3 = COR_TEXTO
voltarBtn.AutoButtonColor = false
voltarBtn.ZIndex = 5
voltarBtn.Parent = painel2

local voltarCorner = Instance.new("UICorner")
voltarCorner.CornerRadius = UDim.new(0, 10)
voltarCorner.Parent = voltarBtn

estilizar(voltarBtn, Color3.fromRGB(180, 200, 255))

voltarBtn.MouseButton1Click:Connect(function()
	painel2.Visible = false
	painel.Visible = true
end)

configBtn.MouseButton1Click:Connect(function()
	painel.Visible = not painel.Visible
	painel2.Visible = false
end)

paginaAbrirBtn.MouseButton1Click:Connect(function()
	painel.Visible = false
	painel2.Visible = true
end)

-- ============================================================
-- SELETOR DE COR
-- ============================================================
local pickerFrame = Instance.new("Frame")
pickerFrame.Size = UDim2.new(0, 230, 0, 300)
pickerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
pickerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
pickerFrame.BackgroundColor3 = COR_FUNDO
pickerFrame.BorderSizePixel = 0
pickerFrame.Visible = false
pickerFrame.ZIndex = 10
pickerFrame.Parent = screenGui
adicionarEscalaMobile(pickerFrame, 230, 300)

local pickerCorner = Instance.new("UICorner")
pickerCorner.CornerRadius = UDim.new(0, 16)
pickerCorner.Parent = pickerFrame

local pickerStroke = Instance.new("UIStroke")
pickerStroke.Color = Color3.fromRGB(90, 90, 100)
pickerStroke.Transparency = 0
pickerStroke.Thickness = 1
pickerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
pickerStroke.Parent = pickerFrame

local pickerTitulo = criarBarraTitulo(pickerFrame, "🎨", "Escolher cor")
pickerTitulo.ZIndex = 10
for _, filho in ipairs(pickerTitulo:GetChildren()) do
	if filho:IsA("GuiObject") then filho.ZIndex = 10 end
end
pickerTitulo.Active = true
tornarFrameArrastavel(pickerTitulo, pickerFrame)

local pickerFecharBtn = Instance.new("TextButton")
pickerFecharBtn.Size = UDim2.new(0, 34, 0, 34)
pickerFecharBtn.Position = UDim2.new(1, -34, 0, 0)
pickerFecharBtn.Text = "✕"
pickerFecharBtn.Font = Enum.Font.GothamBold
pickerFecharBtn.TextSize = 15
pickerFecharBtn.BackgroundColor3 = COR_PERIGO
pickerFecharBtn.TextColor3 = COR_TEXTO
pickerFecharBtn.AutoButtonColor = false
pickerFecharBtn.ZIndex = 11
pickerFecharBtn.Parent = pickerFrame

local pickerFecharCorner = Instance.new("UICorner")
pickerFecharCorner.CornerRadius = UDim.new(0, 16)
pickerFecharCorner.Parent = pickerFecharBtn

pickerFecharBtn.MouseButton1Click:Connect(function()
	pickerFrame.Visible = false
end)

local svSquare = Instance.new("Frame")
svSquare.Size = UDim2.new(1, -24, 0, 140)
svSquare.Position = UDim2.new(0, 12, 0, 46)
svSquare.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
svSquare.BorderSizePixel = 0
svSquare.ZIndex = 10
svSquare.Parent = pickerFrame

local svCorner = Instance.new("UICorner")
svCorner.CornerRadius = UDim.new(0, 10)
svCorner.Parent = svSquare

local svStroke = Instance.new("UIStroke")
svStroke.Color = Color3.fromRGB(90, 90, 100)
svStroke.Transparency = 0
svStroke.Thickness = 1
svStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
svStroke.Parent = svSquare

local overlaySat = Instance.new("Frame")
overlaySat.Size = UDim2.new(1, 0, 1, 0)
overlaySat.BackgroundColor3 = Color3.new(1, 1, 1)
overlaySat.BorderSizePixel = 0
overlaySat.ZIndex = 10
overlaySat.Parent = svSquare

local satGradient = Instance.new("UIGradient")
satGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(1, 1),
})
satGradient.Parent = overlaySat

local overlayVal = Instance.new("Frame")
overlayVal.Size = UDim2.new(1, 0, 1, 0)
overlayVal.BackgroundColor3 = Color3.new(0, 0, 0)
overlayVal.BorderSizePixel = 0
overlayVal.ZIndex = 10
overlayVal.Parent = svSquare

local valGradient = Instance.new("UIGradient")
valGradient.Rotation = 90
valGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0),
})
valGradient.Parent = overlayVal

local svCursor = Instance.new("Frame")
svCursor.Size = UDim2.new(0, 12, 0, 12)
svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
svCursor.Position = UDim2.new(1, 0, 0, 0)
svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
svCursor.BorderSizePixel = 2
svCursor.ZIndex = 11
svCursor.Parent = svSquare

local svCursorCorner = Instance.new("UICorner")
svCursorCorner.CornerRadius = UDim.new(1, 0)
svCursorCorner.Parent = svCursor

local hueBar = Instance.new("Frame")
hueBar.Size = UDim2.new(1, -24, 0, 22)
hueBar.Position = UDim2.new(0, 12, 0, 196)
hueBar.BorderSizePixel = 0
hueBar.ZIndex = 10
hueBar.Parent = pickerFrame

local hueBarCorner = Instance.new("UICorner")
hueBarCorner.CornerRadius = UDim.new(1, 0)
hueBarCorner.Parent = hueBar

local hueBarStroke = Instance.new("UIStroke")
hueBarStroke.Color = Color3.fromRGB(90, 90, 100)
hueBarStroke.Transparency = 0
hueBarStroke.Thickness = 1
hueBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
hueBarStroke.Parent = hueBar

local hueGradient = Instance.new("UIGradient")
hueGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.34, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
	ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
	ColorSequenceKeypoint.new(0.84, Color3.fromRGB(255, 0, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
})
hueGradient.Parent = hueBar

local hueCursor = Instance.new("Frame")
hueCursor.Size = UDim2.new(0, 5, 1, 6)
hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
hueCursor.Position = UDim2.new(0, 0, 0.5, 0)
hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
hueCursor.ZIndex = 11
hueCursor.Parent = hueBar

local hueCursorCorner = Instance.new("UICorner")
hueCursorCorner.CornerRadius = UDim.new(1, 0)
hueCursorCorner.Parent = hueCursor

local preview = Instance.new("Frame")
preview.Size = UDim2.new(0, 44, 0, 34)
preview.Position = UDim2.new(0, 12, 0, 232)
preview.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
preview.BorderSizePixel = 0
preview.ZIndex = 10
preview.Parent = pickerFrame

local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0, 8)
previewCorner.Parent = preview

local previewStroke = Instance.new("UIStroke")
previewStroke.Color = Color3.fromRGB(90, 90, 100)
previewStroke.Transparency = 0
previewStroke.Thickness = 1
previewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
previewStroke.Parent = preview

local aplicarBtn = Instance.new("TextButton")
aplicarBtn.Size = UDim2.new(1, -76, 0, 34)
aplicarBtn.Position = UDim2.new(0, 64, 0, 232)
aplicarBtn.Text = "✔  Aplicar"
aplicarBtn.Font = Enum.Font.GothamBold
aplicarBtn.TextSize = 15
aplicarBtn.BackgroundColor3 = COR_SUCESSO
aplicarBtn.TextColor3 = COR_TEXTO
aplicarBtn.AutoButtonColor = false
aplicarBtn.ZIndex = 10
aplicarBtn.Parent = pickerFrame

local aplicarCorner = Instance.new("UICorner")
aplicarCorner.CornerRadius = UDim.new(0, 8)
aplicarCorner.Parent = aplicarBtn

estilizar(aplicarBtn, Color3.fromRGB(180, 255, 200))

local function atualizarPreview()
	preview.BackgroundColor3 = Color3.fromHSV(pickerHue, pickerSat, pickerVal)
end

conectarArrasteArea(svSquare, function(relX, relY)
	pickerSat = relX
	pickerVal = 1 - relY
	svCursor.Position = UDim2.new(relX, 0, relY, 0)
	atualizarPreview()
end)

conectarArrasteArea(hueBar, function(relX, relY)
	pickerHue = relX
	hueCursor.Position = UDim2.new(relX, 0, 0.5, 0)
	svSquare.BackgroundColor3 = Color3.fromHSV(pickerHue, 1, 1)
	atualizarPreview()
end)

local function abrirPicker(floatBtn, swatchBtn)
	pickerAlvo = { floatBtn = floatBtn, swatchBtn = swatchBtn }
	pickerHue, pickerSat, pickerVal = floatBtn.BackgroundColor3:ToHSV()
	svSquare.BackgroundColor3 = Color3.fromHSV(pickerHue, 1, 1)
	svCursor.Position = UDim2.new(pickerSat, 0, 1 - pickerVal, 0)
	hueCursor.Position = UDim2.new(pickerHue, 0, 0.5, 0)
	atualizarPreview()
	pickerFrame.Visible = true
end

aplicarBtn.MouseButton1Click:Connect(function()
	if pickerAlvo then
		local cor = Color3.fromHSV(pickerHue, pickerSat, pickerVal)
		pickerAlvo.floatBtn.BackgroundColor3 = cor
		pickerAlvo.swatchBtn.BackgroundColor3 = cor
	end
	pickerFrame.Visible = false
end)

-- ============================================================
-- TAMANHO E FORMA
-- ============================================================
local tamanhoFrame = Instance.new("Frame")
tamanhoFrame.Size = UDim2.new(0, 230, 0, 230)
tamanhoFrame.AnchorPoint = Vector2.new(0.5, 0.5)
tamanhoFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
tamanhoFrame.BackgroundColor3 = COR_FUNDO
tamanhoFrame.BorderSizePixel = 0
tamanhoFrame.Visible = false
tamanhoFrame.ZIndex = 10
tamanhoFrame.Parent = screenGui
adicionarEscalaMobile(tamanhoFrame, 230, 230)

local tamanhoFrameCorner = Instance.new("UICorner")
tamanhoFrameCorner.CornerRadius = UDim.new(0, 16)
tamanhoFrameCorner.Parent = tamanhoFrame

local tamanhoFrameStroke = Instance.new("UIStroke")
tamanhoFrameStroke.Color = Color3.fromRGB(90, 90, 100)
tamanhoFrameStroke.Transparency = 0
tamanhoFrameStroke.Thickness = 1
tamanhoFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
tamanhoFrameStroke.Parent = tamanhoFrame

local tamanhoTitulo = criarBarraTitulo(tamanhoFrame, "📐", "Tamanho e forma")
tamanhoTitulo.ZIndex = 10
for _, filho in ipairs(tamanhoTitulo:GetChildren()) do
	if filho:IsA("GuiObject") then filho.ZIndex = 10 end
end
tamanhoTitulo.Active = true
tornarFrameArrastavel(tamanhoTitulo, tamanhoFrame)

local tamanhoFecharBtn = Instance.new("TextButton")
tamanhoFecharBtn.Size = UDim2.new(0, 34, 0, 34)
tamanhoFecharBtn.Position = UDim2.new(1, -34, 0, 0)
tamanhoFecharBtn.Text = "✕"
tamanhoFecharBtn.Font = Enum.Font.GothamBold
tamanhoFecharBtn.TextSize = 15
tamanhoFecharBtn.BackgroundColor3 = COR_PERIGO
tamanhoFecharBtn.TextColor3 = COR_TEXTO
tamanhoFecharBtn.AutoButtonColor = false
tamanhoFecharBtn.ZIndex = 11
tamanhoFecharBtn.Parent = tamanhoFrame

local tamanhoFecharCorner = Instance.new("UICorner")
tamanhoFecharCorner.CornerRadius = UDim.new(0, 16)
tamanhoFecharCorner.Parent = tamanhoFecharBtn

tamanhoFecharBtn.MouseButton1Click:Connect(function()
	tamanhoFrame.Visible = false
end)

local tamanhoPreview = Instance.new("Frame")
tamanhoPreview.Size = UDim2.new(0, 56, 0, 56)
tamanhoPreview.Position = UDim2.new(0.5, 0, 0, 46)
tamanhoPreview.AnchorPoint = Vector2.new(0.5, 0)
tamanhoPreview.BackgroundColor3 = COR_SUCESSO
tamanhoPreview.BorderSizePixel = 0
tamanhoPreview.ZIndex = 10
tamanhoPreview.Parent = tamanhoFrame

local tamanhoPreviewCorner = Instance.new("UICorner")
tamanhoPreviewCorner.CornerRadius = FORMAS[formaAtual]
tamanhoPreviewCorner.Parent = tamanhoPreview

estilizar(tamanhoPreview, Color3.fromRGB(180, 255, 200))

local tamanhoBarLabel = Instance.new("TextLabel")
tamanhoBarLabel.Size = UDim2.new(1, -24, 0, 16)
tamanhoBarLabel.Position = UDim2.new(0, 12, 0, 114)
tamanhoBarLabel.BackgroundTransparency = 1
tamanhoBarLabel.Text = "Tamanho"
tamanhoBarLabel.TextXAlignment = Enum.TextXAlignment.Left
tamanhoBarLabel.Font = Enum.Font.GothamMedium
tamanhoBarLabel.TextSize = 12
tamanhoBarLabel.TextColor3 = COR_TEXTO_SEC
tamanhoBarLabel.ZIndex = 10
tamanhoBarLabel.Parent = tamanhoFrame

local tamanhoBar = Instance.new("Frame")
tamanhoBar.Size = UDim2.new(1, -24, 0, 16)
tamanhoBar.Position = UDim2.new(0, 12, 0, 132)
tamanhoBar.BackgroundColor3 = COR_FUNDO_CLARO
tamanhoBar.BorderSizePixel = 0
tamanhoBar.ZIndex = 10
tamanhoBar.Parent = tamanhoFrame

local tamanhoBarCorner = Instance.new("UICorner")
tamanhoBarCorner.CornerRadius = UDim.new(1, 0)
tamanhoBarCorner.Parent = tamanhoBar

local tamanhoBarCursor = Instance.new("Frame")
tamanhoBarCursor.Size = UDim2.new(0, 18, 0, 18)
tamanhoBarCursor.AnchorPoint = Vector2.new(0.5, 0)
tamanhoBarCursor.BackgroundColor3 = COR_ACCENT_2
tamanhoBarCursor.ZIndex = 11
tamanhoBarCursor.Parent = tamanhoBar

local tamanhoBarCursorCorner = Instance.new("UICorner")
tamanhoBarCursorCorner.CornerRadius = UDim.new(1, 0)
tamanhoBarCursorCorner.Parent = tamanhoBarCursor

local TAMANHO_MIN, TAMANHO_MAX = 36, 90

local function posicaoParaTamanho(rel)
	return math.floor(TAMANHO_MIN + rel * (TAMANHO_MAX - TAMANHO_MIN))
end

local function tamanhoParaPosicao(tam)
	return (tam - TAMANHO_MIN) / (TAMANHO_MAX - TAMANHO_MIN)
end

conectarArrasteArea(tamanhoBar, function(relX, relY)
	tamanhoStaged = posicaoParaTamanho(relX)
	tamanhoBarCursor.Position = UDim2.new(relX, 0, 0, 0)
	tamanhoPreview.Size = UDim2.new(0, tamanhoStaged, 0, tamanhoStaged)
end)

local formasFrame = Instance.new("Frame")
formasFrame.Size = UDim2.new(1, -24, 0, 32)
formasFrame.Position = UDim2.new(0, 12, 0, 164)
formasFrame.BackgroundTransparency = 1
formasFrame.ZIndex = 10
formasFrame.Parent = tamanhoFrame

local formasLayout = Instance.new("UIListLayout")
formasLayout.FillDirection = Enum.FillDirection.Horizontal
formasLayout.Padding = UDim.new(0, 6)
formasLayout.Parent = formasFrame

local formaBotoesRefs = {}

local function criarBotaoForma(nomeForma, texto)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 64, 0, 32)
	b.Text = texto
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.BackgroundColor3 = COR_FUNDO_CLARO
	b.TextColor3 = COR_TEXTO
	b.AutoButtonColor = false
	b.ZIndex = 10
	b.Parent = formasFrame

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = b

	b.MouseButton1Click:Connect(function()
		formaStaged = nomeForma
		tamanhoPreviewCorner.CornerRadius = FORMAS[nomeForma]
		for _, ref in pairs(formaBotoesRefs) do
			ref.BackgroundColor3 = COR_FUNDO_CLARO
		end
		b.BackgroundColor3 = COR_ACCENT_2
	end)

	formaBotoesRefs[nomeForma] = b
	return b
end

criarBotaoForma("redondo", "Redondo")
criarBotaoForma("quadrado", "Quadrado")
criarBotaoForma("arredondado", "Cantos")

local tamanhoAplicarBtn = Instance.new("TextButton")
tamanhoAplicarBtn.Size = UDim2.new(1, -24, 0, 32)
tamanhoAplicarBtn.Position = UDim2.new(0, 12, 0, 192)
tamanhoAplicarBtn.Text = "✔  Aplicar a todos"
tamanhoAplicarBtn.Font = Enum.Font.GothamBold
tamanhoAplicarBtn.TextSize = 14
tamanhoAplicarBtn.BackgroundColor3 = COR_SUCESSO
tamanhoAplicarBtn.TextColor3 = COR_TEXTO
tamanhoAplicarBtn.AutoButtonColor = false
tamanhoAplicarBtn.ZIndex = 10
tamanhoAplicarBtn.Parent = tamanhoFrame

local tamanhoAplicarCorner = Instance.new("UICorner")
tamanhoAplicarCorner.CornerRadius = UDim.new(0, 8)
tamanhoAplicarCorner.Parent = tamanhoAplicarBtn

estilizar(tamanhoAplicarBtn, Color3.fromRGB(180, 255, 200))

tamanhoAplicarBtn.MouseButton1Click:Connect(function()
	tamanhoAtual = tamanhoStaged
	formaAtual = formaStaged
	for _, ref in ipairs(todosBotoesFloat) do
		ref.btn.Size = UDim2.new(0, tamanhoAtual, 0, tamanhoAtual)
		ref.corner.CornerRadius = FORMAS[formaAtual]
	end
	tamanhoFrame.Visible = false
end)

tamanhoEditarBtn.MouseButton1Click:Connect(function()
	tamanhoStaged = tamanhoAtual
	formaStaged = formaAtual
	tamanhoBarCursor.Position = UDim2.new(tamanhoParaPosicao(tamanhoAtual), 0, 0, 0)
	tamanhoPreview.Size = UDim2.new(0, tamanhoAtual, 0, tamanhoAtual)
	tamanhoPreviewCorner.CornerRadius = FORMAS[formaAtual]
	for nome, ref in pairs(formaBotoesRefs) do
		ref.BackgroundColor3 = (nome == formaAtual) and COR_ACCENT_2 or COR_FUNDO_CLARO
	end
	tamanhoFrame.Visible = true
end)

-- ============================================================
-- BOTÕES FLUTUANTES
-- ============================================================
local function tornarArrastavel(btn, aoClicar)
	local dragging = false
	local dragInput, dragStart, startPos

	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = btn.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					local deltaX = math.abs(btn.Position.X.Offset - startPos.X.Offset)
					local deltaY = math.abs(btn.Position.Y.Offset - startPos.Y.Offset)
					if deltaX < 5 and deltaY < 5 then
						aoClicar()
					end
				end
			end)
		end
	end)

	btn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ============================================================
-- ENVIO PELO CHAT (PC)
-- ============================================================

local ultimoEnvio = 0
local INTERVALO_ENVIO = 0 
local enviandoAgora = false

local function enviarNoChat(mensagem)
	if not mensagem or mensagem == "" then return false end

	local agora = os.clock()
	local restante = INTERVALO_ENVIO - (agora - ultimoEnvio)
	if restante > 0 then
		task.wait(restante)
	end

	local enviado = false

	-- Chat moderno / TextChatService
	local ok = pcall(function()
		local canais = TextChatService:FindFirstChild("TextChannels")
		if not canais then return end

		local canal = canais:FindFirstChild("RBXGeneral")
		if not canal then
			for _, obj in ipairs(canais:GetChildren()) do
				if obj:IsA("TextChannel") then
					canal = obj
					break
				end
			end
		end

		if canal then
			canal:SendAsync(mensagem)
			enviado = true
		end
	end)

	-- Chat legado, caso exista no jogo.
	if not enviado then
		pcall(function()
			local eventos = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
			local request = eventos and eventos:FindFirstChild("SayMessageRequest")
			if request then
				request:FireServer(mensagem, "All")
				enviado = true
			end
		end)
	end

	if enviado then
		ultimoEnvio = os.clock()
	end

	return enviado
end

-- ============================================================
-- BOTÕES / ATALHOS DO PC
-- ============================================================

local function nomeDaTecla(keyCode)
	return keyCode and keyCode.Name or "Nenhuma"
end

local function criarBotao(nomeInicial, fraseInicial, teclaInicial)
	contador += 1
	local id = contador

	local dados = {
		id = id,
		frase = fraseInicial or "",
		nome = nomeInicial or "",
		quantidade = 1,
		tecla = nil,
		enviando = false,
	}

	local capturandoTecla = false
	local conexaoTecla = nil

	local linha = Instance.new("Frame")
	linha.Name = "Configuracao" .. id
	linha.Size = UDim2.new(1, 0, 0, 140)
	linha.BackgroundColor3 = COR_FUNDO_CLARO
	linha.BorderSizePixel = 0
	linha.LayoutOrder = id
	linha.ZIndex = 5
	linha.Parent = lista

	local linhaCorner = Instance.new("UICorner")
	linhaCorner.CornerRadius = UDim.new(0, 10)
	linhaCorner.Parent = linha

	-- Remover
	local removerBtn = Instance.new("TextButton")
	removerBtn.Size = UDim2.new(0, 28, 0, 28)
	removerBtn.Position = UDim2.new(0, 6, 0, 8)
	removerBtn.Text = "🗑"
	removerBtn.Font = Enum.Font.GothamBold
	removerBtn.TextSize = 13
	removerBtn.BackgroundColor3 = COR_PERIGO
	removerBtn.TextColor3 = COR_TEXTO
	removerBtn.AutoButtonColor = false
	removerBtn.ZIndex = 6
	removerBtn.Parent = linha

	local removerCorner = Instance.new("UICorner")
	removerCorner.CornerRadius = UDim.new(0, 8)
	removerCorner.Parent = removerBtn

	-- Nome
	local campoNome = Instance.new("TextBox")
	campoNome.Size = UDim2.new(1, -48, 0, 28)
	campoNome.Position = UDim2.new(0, 40, 0, 8)
	campoNome.PlaceholderText = "Nome (ex: MAT)"
	campoNome.Text = dados.nome
	campoNome.Font = Enum.Font.GothamBold
	campoNome.TextSize = 13
	campoNome.BackgroundColor3 = COR_FUNDO
	campoNome.TextColor3 = COR_TEXTO
	campoNome.ClearTextOnFocus = false
	campoNome.ZIndex = 6
	campoNome.Parent = linha

	local campoNomeCorner = Instance.new("UICorner")
	campoNomeCorner.CornerRadius = UDim.new(0, 8)
	campoNomeCorner.Parent = campoNome

	-- Mensagem
	local campoFrase = Instance.new("TextBox")
	campoFrase.Size = UDim2.new(1, -70, 0, 28)
	campoFrase.Position = UDim2.new(0, 8, 0, 44)
	campoFrase.PlaceholderText = "Mensagem enviada no chat"
	campoFrase.Text = dados.frase
	campoFrase.Font = Enum.Font.Gotham
	campoFrase.TextSize = 13
	campoFrase.BackgroundColor3 = COR_FUNDO
	campoFrase.TextColor3 = COR_TEXTO
	campoFrase.ClearTextOnFocus = false
	campoFrase.ZIndex = 6
	campoFrase.Parent = linha

	local campoFraseCorner = Instance.new("UICorner")
	campoFraseCorner.CornerRadius = UDim.new(0, 8)
	campoFraseCorner.Parent = campoFrase

	-- Quantidade
	local campoQtd = Instance.new("TextBox")
	campoQtd.Size = UDim2.new(0, 56, 0, 28)
	campoQtd.Position = UDim2.new(1, -62, 0, 44)
	campoQtd.PlaceholderText = "1x"
	campoQtd.Text = "1"
	campoQtd.Font = Enum.Font.GothamBold
	campoQtd.TextSize = 13
	campoQtd.TextXAlignment = Enum.TextXAlignment.Center
	campoQtd.BackgroundColor3 = COR_FUNDO
	campoQtd.TextColor3 = COR_TEXTO
	campoQtd.ClearTextOnFocus = false
	campoQtd.ZIndex = 6
	campoQtd.Parent = linha

	local campoQtdCorner = Instance.new("UICorner")
	campoQtdCorner.CornerRadius = UDim.new(0, 8)
	campoQtdCorner.Parent = campoQtd

	-- Botão de toque para executar a ação no MOBILE
	local executarBtn = Instance.new("TextButton")
	executarBtn.Size = UDim2.new(1, -16, 0, 32)
	executarBtn.Position = UDim2.new(0, 8, 0, 80)
	executarBtn.Text = "▶  TOCAR PARA EXECUTAR"
	executarBtn.Font = Enum.Font.GothamBold
	executarBtn.TextSize = 13
	executarBtn.BackgroundColor3 = COR_ACCENT_2
	executarBtn.TextColor3 = COR_TEXTO
	executarBtn.AutoButtonColor = false
	executarBtn.ZIndex = 6
	executarBtn.Parent = linha

	local executarCorner = Instance.new("UICorner")
	executarCorner.CornerRadius = UDim.new(0, 8)
	executarCorner.Parent = executarBtn

	-- ============================================================
	-- BOTÃO FLUTUANTE DO ATALHO
	-- Pode ser arrastado livremente pela tela no MOBILE.
	-- Um toque curto executa a mesma ação.
	-- ============================================================
	local botaoFlutuante = Instance.new("TextButton")
	botaoFlutuante.Name = "BotaoFlutuante" .. id
	botaoFlutuante.Size = UDim2.new(0, tamanhoAtual, 0, tamanhoAtual)

	local coluna = (id - 1) % 4
	local linhaFloat = math.floor((id - 1) / 4)
	botaoFlutuante.Position = UDim2.new(0, 16 + coluna * (tamanhoAtual + 10), 0, 120 + linhaFloat * (tamanhoAtual + 10))

	botaoFlutuante.Text = dados.nome ~= "" and dados.nome or ("Botão " .. id)
	botaoFlutuante.Font = Enum.Font.GothamBold
	botaoFlutuante.TextSize = 12
	botaoFlutuante.TextWrapped = true
	botaoFlutuante.BackgroundColor3 = COR_ACCENT_2
	botaoFlutuante.TextColor3 = COR_TEXTO
	botaoFlutuante.AutoButtonColor = false
	botaoFlutuante.Active = true
	botaoFlutuante.ZIndex = 20
	botaoFlutuante.Parent = screenGui

	local botaoFlutuanteCorner = Instance.new("UICorner")
	botaoFlutuanteCorner.CornerRadius = FORMAS[formaAtual]
	botaoFlutuanteCorner.Parent = botaoFlutuante

	estilizar(botaoFlutuante, Color3.fromRGB(180, 200, 255))

	todosBotoesFloat[#todosBotoesFloat + 1] = {
		btn = botaoFlutuante,
		corner = botaoFlutuanteCorner
	}

	local function executarAcao()
		if dados.frase == "" or dados.enviando then return end

		dados.enviando = true
		task.spawn(function()
			for i = 1, dados.quantidade do
				enviarNoChat(dados.frase)
				if i < dados.quantidade then
					task.wait(INTERVALO_ENVIO)
				end
			end
			dados.enviando = false
		end)
	end

	-- Arrastar com o dedo; toque sem arrastar executa.
	tornarArrastavel(botaoFlutuante, executarAcao)

	-- Atualiza o texto do botão quando o nome for alterado.
	campoNome:GetPropertyChangedSignal("Text"):Connect(function()
		dados.nome = campoNome.Text
		botaoFlutuante.Text = campoNome.Text ~= "" and campoNome.Text or ("Botão " .. id)
	end)

	executarBtn.MouseButton1Click:Connect(executarAcao)

	removerBtn.MouseButton1Click:Connect(function()
		if conexaoTecla then conexaoTecla:Disconnect() end
		if botaoFlutuante then
			botaoFlutuante:Destroy()
		end
		linha:Destroy()
		botoes[id] = nil
	end)

	botoes[id] = dados
end

adicionarBtn.MouseButton1Click:Connect(function()
	criarBotao()
end)

-- Ações padrão para MOBILE.
criarBotao("Execute", "! ( [ + ] ) -- Execute.'")
criarBotao("Render", "! ( [ + ] ) -- Render.'")
criarBotao("Furar Pneu", "! ( [ + ] ) -- Furar Pneu.'")
criarBotao("Soco", "! ( [ + ] ) -- Soco -- JAB + cruzado.'")
criarBotao("Ordem de parada", "! ( [ + ] ) -- Ordem de parada -- Desça com as mãos na cabeça")
criarBotao("esquivar", "! ( { + } ) -- Esquivar.'")
criarBotao("Joelhada", "! ( { + } ) -- Joelhada (Krav Maga)")
criarBotao("algemar", "! ( { + } ) -- Algemar")
criarBotao("coronhada", "! ( { + } ) -- Coronhada(desmaiar e esquece tudo)")

-- ============================================================
-- VISÃO
-- ============================================================
local function aplicarVisao(alvo)
	if alvo == player.Character then return end
	if highlights[alvo] then return end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 60, 60)
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = alvo

	local cabeca = alvo:WaitForChild("Head", 2)
	local billboard

	if cabeca then
		billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 150, 0, 30)
		billboard.StudsOffset = Vector3.new(0, 2.2, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = 100000
		billboard.Parent = cabeca

		local nomeLabel = Instance.new("TextLabel")
		nomeLabel.Size = UDim2.new(1, 0, 1, 0)
		nomeLabel.BackgroundTransparency = 1
		nomeLabel.Text = alvo.Name
		nomeLabel.Font = Enum.Font.GothamBold
		nomeLabel.TextSize = 16
		nomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nomeLabel.TextStrokeTransparency = 0
		nomeLabel.Parent = billboard
	end

	highlights[alvo] = { highlight = highlight, billboard = billboard }
end

local function removerVisao()
	for _, dados in pairs(highlights) do
		if dados.highlight then dados.highlight:Destroy() end
		if dados.billboard then dados.billboard:Destroy() end
	end
	highlights = {}
end

local function conectarJogador(jogador)
	jogador.CharacterAdded:Connect(function(char)
		if visaoAtiva and jogador ~= player then
			aplicarVisao(char)
		end
	end)
end

for _, jogador in ipairs(Players:GetPlayers()) do
	conectarJogador(jogador)
end

Players.PlayerAdded:Connect(conectarJogador)

visaoSwitch.MouseButton1Click:Connect(function()
	visaoAtiva = not visaoAtiva

	if visaoAtiva then
		visaoSwitch.Text = "ON"
		visaoSwitch.BackgroundColor3 = COR_SUCESSO
		for _, jogador in ipairs(Players:GetPlayers()) do
			if jogador ~= player and jogador.Character then
				aplicarVisao(jogador.Character)
			end
		end
	else
		visaoSwitch.Text = "OFF"
		visaoSwitch.BackgroundColor3 = COR_NEUTRO
		removerVisao()
	end
end)

-- ============================================================
-- HUB DE FLY - PC
-- ============================================================

local flyAtivo = false
local flyNoClip = false
local flyVelocidade = 1000
local noclipOriginal = {}
local flyLoop = nil
local flyGui = nil
local flySubindo = false
local flyDescendo = false

local function getRootHumanoid()
	local character = player.Character
	if not character then return nil, nil end
	return character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
end

local function atualizarNoClip()
	local character = player.Character
	if not character then return end
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CanCollide = not flyNoClip
		end
	end
end

local function setFlyEstado(on, toggleBtn)
	flyAtivo = on
	if toggleBtn then
		toggleBtn.Text = on and "FLY: ON" or "FLY: OFF"
		toggleBtn.BackgroundColor3 = on and COR_SUCESSO or COR_NEUTRO
	end

	if flyLoop then
		flyLoop:Disconnect()
		flyLoop = nil
	end

	local root, humanoid = getRootHumanoid()
	if humanoid then humanoid.AutoRotate = not on end
	if not on and root then root.AssemblyLinearVelocity = Vector3.zero end
	if not on then
		flyNoClip = false
		flySubindo = false
		flyDescendo = false
		atualizarNoClip()
	end

	if not on then return end

	flyLoop = RunService.RenderStepped:Connect(function()
		if not flyAtivo then return end
		local currentRoot, currentHumanoid = getRootHumanoid()
		local camera = workspace.CurrentCamera
		if not currentRoot or not currentHumanoid or not camera then
			return
		end

		local direction = currentHumanoid.MoveDirection

		if flySubindo then
			direction += Vector3.yAxis
		end
		if flyDescendo then
			direction -= Vector3.yAxis
		end

		if direction.Magnitude > 0 then
			currentRoot.AssemblyLinearVelocity = direction.Unit * flyVelocidade
		else
			currentRoot.AssemblyLinearVelocity = Vector3.zero
		end

		currentHumanoid.AutoRotate = false
		if flyNoClip then
			atualizarNoClip()
		end
	end)
end

local function criarHubFly()
	if flyGui then
		flyGui.Enabled = not flyGui.Enabled
		return
	end

	flyGui = Instance.new("ScreenGui")
	flyGui.Name = "HubFly"
	flyGui.ResetOnSpawn = false
	flyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	flyGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 420, 0, 330)
	frame.Position = UDim2.new(0, 20, 0.5, -165)
	frame.BackgroundColor3 = COR_FUNDO
	frame.BorderSizePixel = 0
	frame.Parent = flyGui
	adicionarEscalaMobile(frame, 420, 330)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = COR_ACCENT_2
	stroke.Thickness = 2
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "✈ HUB DE FLY"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextColor3 = COR_TEXTO
	title.Parent = frame

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(1, -30, 0, 48)
	toggle.Position = UDim2.new(0, 15, 0, 55)
	toggle.Text = "FLY: OFF"
	toggle.Font = Enum.Font.GothamBold
	toggle.TextSize = 18
	toggle.BackgroundColor3 = COR_NEUTRO
	toggle.TextColor3 = COR_TEXTO
	toggle.AutoButtonColor = false
	toggle.Parent = frame

	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, 8)
	tc.Parent = toggle

	local noclip = Instance.new("TextButton")
	noclip.Size = UDim2.new(1, -30, 0, 48)
	noclip.Position = UDim2.new(0, 15, 0, 170)
	noclip.Text = "ATRAVESSAR PAREDES: OFF"
	noclip.Font = Enum.Font.GothamBold
	noclip.TextSize = 17
	noclip.BackgroundColor3 = COR_NEUTRO
	noclip.TextColor3 = COR_TEXTO
	noclip.AutoButtonColor = false
	noclip.Parent = frame

	local nc = Instance.new("UICorner")
	nc.CornerRadius = UDim.new(0, 8)
	nc.Parent = noclip

	noclip.MouseButton1Click:Connect(function()
		flyNoClip = not flyNoClip
		atualizarNoClip()
		noclip.Text = flyNoClip and "ATRAVESSAR PAREDES: ON" or "ATRAVESSAR PAREDES: OFF"
		noclip.BackgroundColor3 = flyNoClip and COR_SUCESSO or COR_NEUTRO
	end)

	local speed = Instance.new("TextBox")
	speed.Size = UDim2.new(1, -30, 0, 48)
	speed.Position = UDim2.new(0, 15, 0, 115)
	speed.Text = tostring(flyVelocidade)
	speed.PlaceholderText = "Velocidade (10-1000)"
	speed.Font = Enum.Font.GothamBold
	speed.TextSize = 18
	speed.BackgroundColor3 = COR_FUNDO_CLARO
	speed.TextColor3 = COR_TEXTO
	speed.ClearTextOnFocus = false
	speed.Parent = frame

	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 8)
	sc.Parent = speed

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, -20, 0, 22)
	hint.Position = UDim2.new(0, 15, 0, 285)
	hint.BackgroundTransparency = 1
	hint.Text = "Joystick = mover  •  ↑ = subir  •  ↓ = descer"
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 14
	hint.TextColor3 = COR_TEXTO
	hint.TextTransparency = 0.2
	hint.Parent = frame

	local subirBtn = Instance.new("TextButton")
	subirBtn.Size = UDim2.new(0, 70, 0, 48)
	subirBtn.Position = UDim2.new(1, -170, 0, 220)
	subirBtn.Text = "▲"
	subirBtn.Font = Enum.Font.GothamBold
	subirBtn.TextSize = 24
	subirBtn.BackgroundColor3 = COR_ACCENT_2
	subirBtn.TextColor3 = COR_TEXTO
	subirBtn.AutoButtonColor = false
	subirBtn.Parent = frame
	Instance.new("UICorner", subirBtn).CornerRadius = UDim.new(0, 10)

	local descerBtn = Instance.new("TextButton")
	descerBtn.Size = UDim2.new(0, 70, 0, 48)
	descerBtn.Position = UDim2.new(1, -90, 0, 220)
	descerBtn.Text = "▼"
	descerBtn.Font = Enum.Font.GothamBold
	descerBtn.TextSize = 24
	descerBtn.BackgroundColor3 = COR_ACCENT_2
	descerBtn.TextColor3 = COR_TEXTO
	descerBtn.AutoButtonColor = false
	descerBtn.Parent = frame
	Instance.new("UICorner", descerBtn).CornerRadius = UDim.new(0, 10)

	local function configurarBotaoVertical(botao, nome)
		botao.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				if nome == "subir" then flySubindo = true else flyDescendo = true end
			end
		end)
		botao.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				if nome == "subir" then flySubindo = false else flyDescendo = false end
			end
		end)
	end

	configurarBotaoVertical(subirBtn, "subir")
	configurarBotaoVertical(descerBtn, "descer")

	speed.FocusLost:Connect(function()
		local n = tonumber(speed.Text)
		if n then flyVelocidade = math.clamp(math.floor(n), 10, 1000) end
		speed.Text = tostring(flyVelocidade)
	end)

	toggle.MouseButton1Click:Connect(function()
		setFlyEstado(not flyAtivo, toggle)
	end)

	-- Arrastar o hub com o mouse
	local dragging = false
	local dragStart, startPos
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- O Hub de Fly é aberto pelo botão "✈ FLY" no painel mobile.

-- Botão do Hub de Fly dentro do painel principal.
local flyBtn = Instance.new("TextButton")
flyBtn.Name = "AbrirFly"
flyBtn.Size = UDim2.new(0, 78, 0, 30)
flyBtn.Position = UDim2.new(1, -90, 0, 12)
flyBtn.Text = "✈ FLY"
flyBtn.Font = Enum.Font.GothamBold
flyBtn.TextSize = 13
flyBtn.BackgroundColor3 = COR_ACCENT_2
flyBtn.TextColor3 = COR_TEXTO
flyBtn.AutoButtonColor = false
flyBtn.ZIndex = 20
flyBtn.Parent = painel

local flyBtnCorner = Instance.new("UICorner")
flyBtnCorner.CornerRadius = UDim.new(0, 8)
flyBtnCorner.Parent = flyBtn

flyBtn.MouseButton1Click:Connect(criarHubFly)

player.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	if flyNoClip then atualizarNoClip() end
	if flyAtivo then
		flyAtivo = false
		if flyLoop then flyLoop:Disconnect(); flyLoop = nil end
	end
end)

-- ============================================================
-- ============================================================
-- HUB DE ITENS DA EXPERIÊNCIA
-- Mostra Tools acessíveis pelo cliente em ReplicatedStorage/StarterPack
-- e permite colocar uma cópia na mochila.
-- ============================================================
local itensGui = nil
local itensLista = nil
local itensStatus = nil
local itensCache = {}

local function coletarItens()
    local encontrados = {}
    local vistos = {}

    local function adicionar(obj)
        if obj and obj:IsA("Tool") and not vistos[obj.Name] then
            vistos[obj.Name] = true
            table.insert(encontrados, obj)
        end
    end

    local rs = ReplicatedStorage
    for _, obj in ipairs(rs:GetDescendants()) do
        adicionar(obj)
    end

    local starterPack = game:GetService("StarterPack")
    for _, obj in ipairs(starterPack:GetDescendants()) do
        adicionar(obj)
    end

    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, obj in ipairs(backpack:GetChildren()) do
            adicionar(obj)
        end
    end

    local character = player.Character
    if character then
        for _, obj in ipairs(character:GetChildren()) do
            adicionar(obj)
        end
    end

    table.sort(encontrados, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    return encontrados
end

local function atualizarListaItens()
    if not itensLista then return end

    for _, child in ipairs(itensLista:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    itensCache = coletarItens()
    local y = 0

    if #itensCache == 0 then
        local vazio = Instance.new("TextLabel")
        vazio.Size = UDim2.new(1, -20, 0, 50)
        vazio.Position = UDim2.new(0, 10, 0, 10)
        vazio.BackgroundTransparency = 1
        vazio.Text = "Nenhuma Tool acessível encontrada."
        vazio.TextColor3 = Color3.fromRGB(190, 190, 200)
        vazio.Font = Enum.Font.Gotham
        vazio.TextSize = 14
        vazio.Parent = itensLista
        itensLista.CanvasSize = UDim2.new(0, 0, 0, 70)
        return
    end

    for _, item in ipairs(itensCache) do
        local linha = Instance.new("Frame")
        linha.Size = UDim2.new(1, -20, 0, 50)
        linha.Position = UDim2.new(0, 10, 0, y)
        linha.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        linha.BorderSizePixel = 0
        linha.ZIndex = 201
        linha.Parent = itensLista
        Instance.new("UICorner", linha).CornerRadius = UDim.new(0, 8)

        local nome = Instance.new("TextLabel")
        nome.Size = UDim2.new(1, -125, 1, 0)
        nome.Position = UDim2.new(0, 12, 0, 0)
        nome.BackgroundTransparency = 1
        nome.Text = "🧰  " .. item.Name
        nome.TextColor3 = Color3.new(1, 1, 1)
        nome.Font = Enum.Font.GothamBold
        nome.TextSize = 14
        nome.TextXAlignment = Enum.TextXAlignment.Left
        nome.TextTruncate = Enum.TextTruncate.AtEnd
        nome.ZIndex = 202
        nome.Parent = linha

        local pegar = Instance.new("TextButton")
        pegar.Size = UDim2.new(0, 105, 0, 34)
        pegar.Position = UDim2.new(1, -113, 0.5, -17)
        pegar.BackgroundColor3 = Color3.fromRGB(65, 105, 80)
        pegar.TextColor3 = Color3.new(1, 1, 1)
        pegar.Text = "PEGAR"
        pegar.Font = Enum.Font.GothamBold
        pegar.TextSize = 12
        pegar.ZIndex = 203
        pegar.Parent = linha
        Instance.new("UICorner", pegar).CornerRadius = UDim.new(0, 6)

        pegar.MouseButton1Click:Connect(function()
            local backpack = player:FindFirstChildOfClass("Backpack")
            if not backpack then
                if itensStatus then itensStatus.Text = "Mochila não encontrada." end
                return
            end

            local jaTem = backpack:FindFirstChild(item.Name) or (player.Character and player.Character:FindFirstChild(item.Name))
            if jaTem then
                if itensStatus then itensStatus.Text = "Você já possui: " .. item.Name end
                return
            end

            local clone = item:Clone()
            clone.Parent = backpack
            if itensStatus then
                itensStatus.Text = "Item adicionado: " .. item.Name
            end
        end)

        y += 58
    end

    itensLista.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 1))
end

local function criarHubItens()
    if itensGui then
        itensGui.Visible = not itensGui.Visible
        if itensGui.Visible then atualizarListaItens() end
        return
    end

    itensGui = Instance.new("Frame")
    itensGui.Name = "ItensHub"
    itensGui.Size = UDim2.new(0, 520, 0, 620)
    itensGui.Position = UDim2.new(0.5, -260, 0.5, -310)
    itensGui.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    itensGui.BorderSizePixel = 0
    itensGui.Visible = true
    itensGui.ZIndex = 200
    itensGui.Parent = screenGui
    adicionarEscalaMobile(itensGui, 520, 620)
    Instance.new("UICorner", itensGui).CornerRadius = UDim.new(0, 12)

    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, -60, 0, 45)
    titulo.Position = UDim2.new(0, 15, 0, 5)
    titulo.BackgroundTransparency = 1
    titulo.Text = "🧰 ITENS DA EXPERIÊNCIA"
    titulo.TextColor3 = Color3.new(1, 1, 1)
    titulo.Font = Enum.Font.GothamBold
    titulo.TextSize = 21
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.ZIndex = 201
    titulo.Parent = itensGui

    local fechar = Instance.new("TextButton")
    fechar.Size = UDim2.new(0, 45, 0, 45)
    fechar.Position = UDim2.new(1, -55, 0, 10)
    fechar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    fechar.TextColor3 = Color3.new(1, 1, 1)
    fechar.Text = "X"
    fechar.Font = Enum.Font.GothamBold
    fechar.TextSize = 14
    fechar.ZIndex = 202
    fechar.Parent = itensGui
    Instance.new("UICorner", fechar).CornerRadius = UDim.new(0, 8)
    fechar.MouseButton1Click:Connect(function()
        itensGui.Visible = false
    end)

    local atualizar = Instance.new("TextButton")
    atualizar.Size = UDim2.new(1, -30, 0, 42)
    atualizar.Position = UDim2.new(0, 15, 0, 55)
    atualizar.BackgroundColor3 = Color3.fromRGB(55, 75, 95)
    atualizar.TextColor3 = Color3.new(1, 1, 1)
    atualizar.Text = "↻ ATUALIZAR ITENS"
    atualizar.Font = Enum.Font.GothamBold
    atualizar.TextSize = 15
    atualizar.ZIndex = 202
    atualizar.Parent = itensGui
    Instance.new("UICorner", atualizar).CornerRadius = UDim.new(0, 8)
    atualizar.MouseButton1Click:Connect(atualizarListaItens)

    itensLista = Instance.new("ScrollingFrame")
    itensLista.Size = UDim2.new(1, -30, 0, 440)
    itensLista.Position = UDim2.new(0, 15, 0, 107)
    itensLista.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    itensLista.BorderSizePixel = 0
    itensLista.ScrollBarThickness = 5
    itensLista.CanvasSize = UDim2.new(0, 0, 0, 0)
    itensLista.ZIndex = 200
    itensLista.Parent = itensGui
    Instance.new("UICorner", itensLista).CornerRadius = UDim.new(0, 8)

    itensStatus = Instance.new("TextLabel")
    itensStatus.Size = UDim2.new(1, -30, 0, 35)
    itensStatus.Position = UDim2.new(0, 15, 1, -58)
    itensStatus.BackgroundTransparency = 1
    itensStatus.Text = "Selecione um item para pegar."
    itensStatus.TextColor3 = Color3.fromRGB(210, 210, 210)
    itensStatus.Font = Enum.Font.Gotham
    itensStatus.TextSize = 13
    itensStatus.TextXAlignment = Enum.TextXAlignment.Center
    itensStatus.ZIndex = 201
    itensStatus.Parent = itensGui

    tornarArrastavel(itensGui, titulo)
    atualizarListaItens()
end

local itensMainBtn = Instance.new("TextButton")
itensMainBtn.Name = "AbrirItens"
itensMainBtn.Size = UDim2.new(0, 150, 0, 44)
itensMainBtn.Position = UDim2.new(1, -160, 1, -58)
itensMainBtn.BackgroundColor3 = Color3.fromRGB(75, 100, 80)
itensMainBtn.TextColor3 = Color3.new(1, 1, 1)
itensMainBtn.Text = "🧰 ITENS"
itensMainBtn.Font = Enum.Font.GothamBold
itensMainBtn.TextSize = 12
itensMainBtn.ZIndex = 50
itensMainBtn.Parent = screenGui
Instance.new("UICorner", itensMainBtn).CornerRadius = UDim.new(0, 8)
itensMainBtn.MouseButton1Click:Connect(criarHubItens)

Players.PlayerAdded:Connect(function()
    if itensGui and itensGui.Visible then
        task.defer(atualizarListaItens)
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    if itensGui and itensGui.Visible then
        atualizarListaItens()
    end
end)

-- ============================================================
-- HUB DE TELEPORTE / COPIAR SKIN / TP TOOL
-- F4 abre/fecha o hub.
-- ============================================================

local tpGui
local tpLista
local tpSelecionado
local tpStatus

-- Declaração antecipada para os callbacks da lista.
local teleportarParaPlayer
local copiarSkin
local darTPTool

local function atualizarListaTP()
    if not tpLista or not tpLista.Parent then return end

    for _, child in ipairs(tpLista:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local y = 0
    for _, alvo in ipairs(Players:GetPlayers()) do
        if alvo ~= player then
            local linha = Instance.new("Frame")
            linha.Name = "PlayerRow_" .. alvo.UserId
            linha.Size = UDim2.new(1, -20, 0, 48)
            linha.Position = UDim2.new(0, 10, 0, y)
            linha.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
            linha.BorderSizePixel = 0
            linha.ZIndex = 101
            linha.Parent = tpLista
            Instance.new("UICorner", linha).CornerRadius = UDim.new(0, 7)

            local nome = Instance.new("TextLabel")
            nome.Size = UDim2.new(1, -130, 1, 0)
            nome.Position = UDim2.new(0, 12, 0, 0)
            nome.BackgroundTransparency = 1
            nome.Text = alvo.DisplayName .. "  (@" .. alvo.Name .. ")"
            nome.TextColor3 = Color3.new(1, 1, 1)
            nome.Font = Enum.Font.Gotham
            nome.TextSize = 15
            nome.TextXAlignment = Enum.TextXAlignment.Left
            nome.TextTruncate = Enum.TextTruncate.AtEnd
            nome.ZIndex = 102
            nome.Parent = linha

            -- Botão individual ao lado do jogador.
            local teleportarBtn = Instance.new("TextButton")
            teleportarBtn.Name = "TeleportButton"
            teleportarBtn.Size = UDim2.new(0, 110, 0, 34)
            teleportarBtn.Position = UDim2.new(1, -118, 0.5, -17)
            teleportarBtn.BackgroundColor3 = Color3.fromRGB(65, 105, 80)
            teleportarBtn.TextColor3 = Color3.new(1, 1, 1)
            teleportarBtn.Text = "TELEPORTAR"
            teleportarBtn.Font = Enum.Font.GothamBold
            teleportarBtn.TextSize = 12
            teleportarBtn.AutoButtonColor = true
            teleportarBtn.ZIndex = 103
            teleportarBtn.Parent = linha
            Instance.new("UICorner", teleportarBtn).CornerRadius = UDim.new(0, 6)

            teleportarBtn.MouseButton1Click:Connect(function()
                tpSelecionado = alvo
                teleportarParaPlayer(alvo)
            end)

            -- Clicar no nome seleciona o jogador para Copiar Skin.
            nome.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    tpSelecionado = alvo
                    for _, item in ipairs(tpLista:GetChildren()) do
                        if item:IsA("Frame") then
                            item.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
                        end
                    end
                    linha.BackgroundColor3 = Color3.fromRGB(75, 100, 150)
                    if tpStatus then
                        tpStatus.Text = "Selecionado: " .. alvo.DisplayName
                    end
                end
            end)

            y += 54
        end
    end

    tpLista.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 1))
end

teleportarParaPlayer = function(alvo)
    if not alvo or alvo == player then
        if tpStatus then tpStatus.Text = "Selecione um jogador válido." end
        return
    end

    local meuChar = player.Character or player.CharacterAdded:Wait()
    local alvoChar = alvo.Character
    if not meuChar or not alvoChar then
        if tpStatus then tpStatus.Text = "O personagem não está carregado." end
        return
    end

    local alvoRoot = alvoChar:FindFirstChild("HumanoidRootPart")
    if not alvoRoot then
        if tpStatus then tpStatus.Text = "O jogador ainda não carregou o personagem." end
        return
    end

    -- Fica alguns studs atrás do jogador para não ficar dentro dele.
    local destino = alvoRoot.CFrame * CFrame.new(0, 0, 4)
    meuChar:PivotTo(destino)

    if tpStatus then
        tpStatus.Text = "Teleportado para " .. alvo.DisplayName .. "!"
    end
end

copiarSkin = function(alvo)
    if not alvo or alvo == player or not alvo.Character then
        if tpStatus then tpStatus.Text = "Selecione um jogador válido." end
        return
    end

    local meuChar = player.Character
    local alvoChar = alvo.Character
    local meuHum = meuChar and meuChar:FindFirstChildOfClass("Humanoid")
    local alvoHum = alvoChar and alvoChar:FindFirstChildOfClass("Humanoid")
    if not meuChar or not meuHum or not alvoHum then
        if tpStatus then tpStatus.Text = "Personagem/Humanoid não encontrado." end
        return
    end

    -- Primeiro tenta copiar a aparência completa pelo HumanoidDescription.
    local okDesc, desc = pcall(function()
        return alvoHum:GetAppliedDescription()
    end)

    if okDesc and desc then
        local okApply = pcall(function()
            meuHum:ApplyDescription(desc)
        end)
        if okApply then
            if tpStatus then tpStatus.Text = "Skin de " .. alvo.DisplayName .. " copiada!" end
            return
        end
    end

    -- Fallback para experiências que usam roupas/acessórios diretamente no Character.
    for _, obj in ipairs(meuChar:GetChildren()) do
        if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") then
            obj:Destroy()
        end
    end

    for _, obj in ipairs(alvoChar:GetChildren()) do
        if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") then
            local clone = obj:Clone()
            clone.Parent = meuChar
        end
    end

    -- Copia também escalas/configuração do corpo quando disponíveis.
    local alvoBody = alvoChar:FindFirstChildOfClass("BodyColors")
    local meuBody = meuChar:FindFirstChildOfClass("BodyColors")
    if alvoBody and meuBody then
        meuBody.HeadColor3 = alvoBody.HeadColor3
        meuBody.LeftArmColor3 = alvoBody.LeftArmColor3
        meuBody.RightArmColor3 = alvoBody.RightArmColor3
        meuBody.LeftLegColor3 = alvoBody.LeftLegColor3
        meuBody.RightLegColor3 = alvoBody.RightLegColor3
        meuBody.TorsoColor3 = alvoBody.TorsoColor3
    end

    if tpStatus then tpStatus.Text = "Skin de " .. alvo.DisplayName .. " copiada!" end
end

darTPTool = function()
    local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 3)
    if not backpack then
        if tpStatus then tpStatus.Text = "Mochila não encontrada." end
        return
    end

    local character = player.Character
    local existente = backpack:FindFirstChild("TP Tool") or (character and character:FindFirstChild("TP Tool"))
    if existente then
        if tpStatus then tpStatus.Text = "Você já possui a TP Tool." end
        return
    end

    local tool = Instance.new("Tool")
    tool.Name = "TP Tool"
    tool.ToolTip = "Clique para teleportar"
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool.GripForward = Vector3.new(0, 0, -1)

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.7, 0.7, 0.7)
    handle.Shape = Enum.PartType.Ball
    handle.Material = Enum.Material.Neon
    handle.Color = Color3.fromRGB(70, 140, 255)
    handle.CanCollide = false
    handle.CanQuery = false
    handle.CanTouch = false
    handle.Massless = true
    handle.Parent = tool

    local mouse = player:GetMouse()

    tool.Activated:Connect(function()
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not mouse then return end

        local hit = mouse.Hit
        if not hit then return end

        local destino = hit.Position
        -- Teleporta 5 studs para cima e SEM cooldown.
        local destinoSeguro = destino + Vector3.new(0, 5, 0)
        char:PivotTo(CFrame.new(destinoSeguro, destinoSeguro + root.CFrame.LookVector))
    end)

    tool.Parent = backpack
    if tpStatus then tpStatus.Text = "TP Tool adicionada à mochila!" end
end

local function criarTPHub()
    if tpGui then return end

    tpGui = Instance.new("Frame")
    tpGui.Name = "TPHub"
    tpGui.Size = UDim2.new(0, 520, 0, 620)
    tpGui.Position = UDim2.new(0.5, -260, 0.5, -310)
    tpGui.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    tpGui.BorderSizePixel = 0
    tpGui.Visible = false
    tpGui.ZIndex = 100
    tpGui.Parent = screenGui
    adicionarEscalaMobile(tpGui, 520, 620)
    Instance.new("UICorner", tpGui).CornerRadius = UDim.new(0, 12)

    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, -65, 0, 45)
    titulo.Position = UDim2.new(0, 15, 0, 5)
    titulo.BackgroundTransparency = 1
    titulo.Text = "📍 TP • 👕 COPIAR SKIN"
    titulo.TextColor3 = Color3.new(1, 1, 1)
    titulo.Font = Enum.Font.GothamBold
    titulo.TextSize = 22
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.Parent = tpGui

    local fechar = Instance.new("TextButton")
    fechar.Size = UDim2.new(0, 45, 0, 45)
    fechar.Position = UDim2.new(1, -55, 0, 10)
    fechar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    fechar.TextColor3 = Color3.new(1, 1, 1)
    fechar.Text = "X"
    fechar.Font = Enum.Font.GothamBold
    fechar.TextSize = 14
    fechar.ZIndex = 110
    fechar.Parent = tpGui
    Instance.new("UICorner", fechar).CornerRadius = UDim.new(0, 8)
    fechar.MouseButton1Click:Connect(function() tpGui.Visible = false end)

    local atualizar = Instance.new("TextButton")
    atualizar.Size = UDim2.new(0.48, -10, 0, 42)
    atualizar.Position = UDim2.new(0, 15, 0, 55)
    atualizar.BackgroundColor3 = Color3.fromRGB(55, 75, 95)
    atualizar.TextColor3 = Color3.new(1, 1, 1)
    atualizar.Text = "↻ ATUALIZAR"
    atualizar.Font = Enum.Font.GothamBold
    atualizar.TextSize = 15
    atualizar.ZIndex = 110
    atualizar.Parent = tpGui
    Instance.new("UICorner", atualizar).CornerRadius = UDim.new(0, 8)
    atualizar.MouseButton1Click:Connect(atualizarListaTP)

    local tpToolBtn = Instance.new("TextButton")
    tpToolBtn.Size = UDim2.new(0.48, -10, 0, 42)
    tpToolBtn.Position = UDim2.new(0.52, -5, 0, 55)
    tpToolBtn.BackgroundColor3 = Color3.fromRGB(75, 95, 140)
    tpToolBtn.TextColor3 = Color3.new(1, 1, 1)
    tpToolBtn.Text = "🖱 DAR TP TOOL"
    tpToolBtn.Font = Enum.Font.GothamBold
    tpToolBtn.TextSize = 15
    tpToolBtn.ZIndex = 110
    tpToolBtn.Parent = tpGui
    Instance.new("UICorner", tpToolBtn).CornerRadius = UDim.new(0, 8)
    tpToolBtn.MouseButton1Click:Connect(darTPTool)

    tpLista = Instance.new("ScrollingFrame")
    tpLista.Name = "PlayerList"
    tpLista.Size = UDim2.new(1, -30, 0, 330)
    tpLista.Position = UDim2.new(0, 15, 0, 107)
    tpLista.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    tpLista.BorderSizePixel = 0
    tpLista.ScrollBarThickness = 5
    tpLista.CanvasSize = UDim2.new(0, 0, 0, 0)
    tpLista.ZIndex = 101
    tpLista.Parent = tpGui
    Instance.new("UICorner", tpLista).CornerRadius = UDim.new(0, 8)

    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0.48, -10, 0, 52)
    tpBtn.Position = UDim2.new(0, 15, 1, -70)
    tpBtn.BackgroundColor3 = Color3.fromRGB(65, 100, 75)
    tpBtn.TextColor3 = Color3.new(1, 1, 1)
    tpBtn.Text = "📍 TELEPORTAR"
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 17
    tpBtn.ZIndex = 110
    tpBtn.Parent = tpGui
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 8)
    tpBtn.MouseButton1Click:Connect(function()
        teleportarParaPlayer(tpSelecionado)
    end)

    local skinBtn = Instance.new("TextButton")
    skinBtn.Size = UDim2.new(0.48, -10, 0, 52)
    skinBtn.Position = UDim2.new(0.52, -5, 1, -70)
    skinBtn.BackgroundColor3 = Color3.fromRGB(100, 75, 125)
    skinBtn.TextColor3 = Color3.new(1, 1, 1)
    skinBtn.Text = "👕 COPIAR SKIN"
    skinBtn.Font = Enum.Font.GothamBold
    skinBtn.TextSize = 17
    skinBtn.ZIndex = 110
    skinBtn.Parent = tpGui
    Instance.new("UICorner", skinBtn).CornerRadius = UDim.new(0, 8)
    skinBtn.MouseButton1Click:Connect(function()
        copiarSkin(tpSelecionado)
    end)

    tpStatus = Instance.new("TextLabel")
    tpStatus.Size = UDim2.new(1, -30, 0, 25)
    tpStatus.Position = UDim2.new(0, 15, 1, -105)
    tpStatus.BackgroundTransparency = 1
    tpStatus.Text = "Selecione um jogador."
    tpStatus.TextColor3 = Color3.fromRGB(210, 210, 210)
    tpStatus.Font = Enum.Font.Gotham
    tpStatus.TextSize = 13
    tpStatus.TextXAlignment = Enum.TextXAlignment.Center
    tpStatus.ZIndex = 110
    tpStatus.Parent = tpGui

    tornarArrastavel(tpGui, titulo)
    atualizarListaTP()
end

criarTPHub()

local tpMainBtn = Instance.new("TextButton")
tpMainBtn.Size = UDim2.new(0, 150, 0, 44)
tpMainBtn.Position = UDim2.new(0, 10, 1, -58)
tpMainBtn.BackgroundColor3 = Color3.fromRGB(65, 85, 120)
tpMainBtn.TextColor3 = Color3.new(1, 1, 1)
tpMainBtn.Text = "📍 TP PLAYER"
tpMainBtn.Font = Enum.Font.GothamBold
tpMainBtn.TextSize = 12
tpMainBtn.ZIndex = 50
tpMainBtn.Parent = screenGui
Instance.new("UICorner", tpMainBtn).CornerRadius = UDim.new(0, 8)

tpMainBtn.MouseButton1Click:Connect(function()
    tpGui.Visible = not tpGui.Visible
    if tpGui.Visible then
        atualizarListaTP()
    end
end)

Players.PlayerAdded:Connect(function()
    task.defer(atualizarListaTP)
end)

Players.PlayerRemoving:Connect(function(alvo)
    if tpSelecionado == alvo then
        tpSelecionado = nil
    end
    task.defer(atualizarListaTP)
end)

