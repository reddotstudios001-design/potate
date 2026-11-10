# potato ui

Biblioteca de interface para Roblox (Luau) com a **mesma cara do script potato**: janela escura com cantos arredondados, animacoes suaves, sistema de temas completo, watermark, Tab Edit e persistencia de config.

Voce carrega a biblioteca com `loadstring`, cria sua janela em poucas linhas e tem, de graca, tudo o que o potato original trazia de interface pronta — sem levar junto as funcoes de jogo (ESP, chams etc.). Essas ficam no seu script.

- 100% do visual do potato original (nada foi redesenhado)
- Tabs, cards, sliders, toggles, swatches, keybinds, action buttons e info cards ja embutidos
- Temas prontos + estudio de temas customizados (gradiente de 3 cores)
- Config salvo automaticamente (tema, cores, ordem de tabs/cards, keybind, watermark, lado do preview)
- Licenca MIT — mantenha o credito: **potato**

## Estrutura do repositorio

| Arquivo | O que e |
| --- | --- |
| `PotatoUI.lua` | A biblioteca. Senao usa nada além do que esta nela. |
| `Example.lua` | Script de exemplo completo: recria o potato original (ESP, preview 3D, etc.) usando so a API publica da biblioteca. |
| `README.md` | Este arquivo. |
| `LICENSE` | MIT, copyright potato. |

## Requisitos

- Um executor Roblox que rode Luau e tenha `readfile`/`writefile`/`makefolder`/`isfolder` (qualquer executor moderno). Sem acesso a arquivos, tudo funciona, mas a config nao persiste (a biblioteca detecta e avisa na tab Configs).
- A biblioteca carrega icones [Lucide](https://lucide.dev) de um repositorio remoto (mesmo esquema do potato original) e tem um fallback local para os icones mais usados.

## Instalacao

1. Suba estes 4 arquivos para o seu repositorio no GitHub (branch `main`).
2. Troque `seu-usuario` pelo seu usuario nas URLs abaixo.

```lua
local Potato = loadstring(game:HttpGet("https://raw.githubusercontent.com/reddotstudios001-design/potate/main/PotatoUI.lua"))()
```

Ou, se preferir nao depender de HTTP, cole o conteudo do `PotatoUI.lua` direto no topo do seu script (ele termina com `return Potato`, entao fica identico).

## Uso rapido

```lua
local Potato = loadstring(game:HttpGet("https://raw.githubusercontent.com/seu-usuario/potato-ui/main/PotatoUI.lua"))()

local Window = Potato:CreateWindow({
	Name = "meu script",
	Version = "1.0",
})

local Tab = Window:CreateTab("principal", "zap")

Tab:AddToggle({
	Id = "ExemploToggle",
	Title = "Minha Opcao",
	Subtitle = "liga e desliga alguma coisa",
	Icon = "sparkles",
	Default = true,
	Callback = function(valor)
		print("toggle:", valor)
	end
})

Tab:AddSlider({
	Id = "ExemploSlider",
	Title = "Intensidade",
	Min = 0,
	Max = 100,
	Suffix = "%",
	Default = 50,
	Icon = "activity",
	Callback = function(valor)
		print("slider:", valor)
	end
})
```

## `Potato:CreateWindow(opcoes)`

Tudo e opcional. Sem argumentos, a janela sai com o nome `potato`.

| Opcao | Tipo | Padrao | Descricao |
| --- | --- | --- | --- |
| `Name` | string | `"potato"` | Nome exibido na title bar e na watermark. |
| `Version` | string\|number | `LIB_VERSION` (2.6) | Versao exibida no botao de changelog do rodape. |
| `ToggleKey` | EnumKeyCode | `Enum.KeyCode.P` | Tecla que esconde/mostra a UI. Tambem ajustavel depois na tab Settings. |
| `Logo` | string | logo do potato | URL da imagem da title bar (aceita `rbxthumb`). |
| `Width` | number | `760` | Largura base da janela (expandida). |
| `Height` | number | `470` | Altura da janela. |
| `ConfigFile` | string\|false | `"<nome>/config.json"` | Caminho do arquivo de config. `false` desativa a persistencia. |
| `Theme` | string | `"Pitch Black"` | Tema inicial (ignorado se houver config salvo). |
| `ShowSettingsTab` | boolean | `true` | Cria a tab embutida Settings. |
| `ShowConfigsTab` | boolean | `true` | Cria a tab embutida Configs. |
| `Changelog` | array | changelog do potato | Array de `{ "vX.Y  •  titulo", "texto" }`. Sobrescreve as notas exibidas quando a versao salva e diferente da atual. |
| `OnUnload` | function | `nil` | Chamada quando a UI e descarregada (botao X / `Window:Unload()` / `__PotatoUnload()`). |

Retorna o objeto `Window`.

## Objeto `Window`

| Metodo | Descricao |
| --- | --- |
| `Window:CreateTab(nome, icone)` | Cria uma tab do seu script (o icone e um nome de icone Lucide, ex.: `"eye"`, `"zap"`). Retorna a `tab`. |
| `Window:CreateSidePanel(tabName, titulo)` | Cria um painel lateral (ex.: preview 3D) vinculado a tab `tabName`. So aparece naquela tab. Retorna o painel (`{ Frame, Divider, Header, DragSub, SwapIndicator, Body }`). Coloque seu conteudo dentro de `panel.Body`. |
| `Window:ApplyTheme(nome, aplicarAccent)` | Aplica um dos 6 temas embutidos ou um tema customizado salvo. |
| `Window:SetAccent(Color3)` | Troca a cor de destaque global (tabs, checkboxes, sliders). |
| `Window:Save()` | Salva a config agora. Retorna `true/false`. |
| `Window:Load()` | Recarrega a config do disco. Retorna `true/false`. |
| `Window:ResetSettings()` | Restaura todas as opcoes para o padrao (inclusive as suas, com `Id`). |
| `Window:ResetLayout()` | Restaura ordem de tabs, ordem de cards, cores e lado do preview para o padrao. |
| `Window:Minimize(boolean)` | Minimiza/restaura a janela. |
| `Window:Toggle()` | Esconde/mostra a janela. |
| `Window:Unload()` | Descarrega a UI (salva a config antes e dispara `OnUnload`). |

Propriedade: `Window.OnUnload` (function) — alternativa ao `opts.OnUnload`.

Global auxiliar (para desinstalar de fora): `__PotatoUnload()` no ambiente do executor (se exposto).

## Objeto `tab`

| Metodo | Descricao |
| --- | --- |
| `tab:AddToggle(opts)` | Toggle on/off com titulo, subtitulo e icone. |
| `tab:AddSlider(opts)` | Slider numerico (min/max/passo, sufixo, callback ao mover). |
| `tab:AddColorSwatches(opts)` | Seletor de cor por amostras (array de `Color3`). |
| `tab:AddKeybind(opts)` | Botao de atalho: clique para armar, pressione a tecla (Escape cancela). |
| `tab:AddButton(opts)` | Botao de acao (ex.: "Reset"). Callback recebe o objeto do botao. |
| `tab:AddInfoCard(opts)` | Card de informacao (titulo + texto), ideal para status. |

Todos aceitam `Id` (string). **O que tem `Id` e salvo automaticamente** na config. Controles sem `Id` nao persistem.

### Retorno dos controles com `Id`

`tab:AddToggle`, `AddSlider`, `AddColorSwatches` e `AddKeybind` retornam um handle:

```lua
local toggle = Tab:AddToggle({ Id = "MeuToggle", Title = "Exemplo", Default = true, Callback = function(v) end })
toggle:Get()        -- valor atual
toggle:Set(true)    -- define e dispara Callback
toggle:SetQuiet(true) -- define sem disparar Callback
toggle:Apply()      -- re-dispara Callback com o valor salvo (util apos CreateWindow)
```

`AddButton` retorna `{ Id, Button }`; `AddInfoCard` retorna `{ Id }`.

### Opcoes comuns

| Chave | Tipo | Usado em |
| --- | --- | --- |
| `Id` | string | todos (define a chave de persistencia) |
| `Title` | string | todos |
| `Subtitle` | string | Toggle |
| `Icon` | string (Lucide) | todos |
| `Default` | boolean / number / Color3 / EnumKeyCode | Toggle, Slider, Swatches, Keybind |
| `Min` / `Max` / `Step` | number | Slider |
| `Suffix` | string | Slider (ex.: `"%"`, `"h"`) |
| `Options` | array de Color3 | ColorSwatches (obrigatorio) |
| `ButtonText` | string | Button (texto do botao, padrao `"Run"`) |
| `Text` | string | InfoCard (corpo do texto) |
| `Callback` | function | Toggle `(boolean)`, Slider `(number)`, Swatches `(Color3)`, Keybind `(EnumKeyCode)`, Button `(Button)` |

## O que ja vem embutido (nao precisa recriar)

**Tabs embutidas**
- Settings — seletor de tema (+ estudio de temas customizados), Theme Gradient on/off, Gradient Angle, UI Scale, UI Transparency, toggles da watermark (logo, nome, FPS, ping, usuario, relogio) + presets, e o keybind de esconder a UI.
- Configs — status do salvamento (caminho do arquivo), cartao de licenca (credito potato), botoes Save / Load / Reset Settings / Reset Layout.

**Temas**
- 6 temas embutidos: Pitch Black, Midnight, Emerald, Crimson, Amethyst, Oceanic (gradiente de 3 stops, com suporte a tema em gradiente ou solido).
- Estudio "New Theme" (ate 3 temas customizados): 3 cores + accent, picker HSV, preview vivo, nome customizado, editar e deletar.
- `UseGradient` + `GradientAngle` para controlar o gradiente global das superficies.

**Sistema**
- Auto-save com debounce de 0.8s (qualquer controle com `Id`, ordem de tabs/cards, cores de tab/conteudo, posicao da watermark, lado do preview, tema + temas customizados, keybind da UI).
- Auto-load na abertura (defer, depois que o seu script termina de criar as tabs).
- Changelog inteligente: abre apenas quando a versao salva e diferente da `Version` atual (primeira execucao nao abre nada).
- Changelog inclui as notas do potato; substitua com `opts.Changelog` para as notas do seu script.
- Tab Edit: botao de lapis na barra de abas — arraste os cards pelo grip para reordenar, troque cor de cada tab e a cor de conteudo (accent) de cada tab, arraste o header do painel lateral para trocar o lado. Tudo salvo.
- Watermark arrastável com FPS/ping reais, logo, relogio, usuario e presets de 1 clique. Posicao salva.
- Reset Layout / Reset Settings / Save / Load direto na tab Configs.
- Keybind global de esconder/mostrar a UI (padrao `P`, salvo).
- Versao sempre visivel no rodape; clique abre o changelog.

## Tab Edit

Clique no botao de lapis ao lado da busca na barra de abas. Com o modo ativo:

- Os icones dos cards viram um grip (pontinhos) — arraste para cima/baixo para reordenar.
- Cada tab ganha amostras de cor para a cor da propria tab e para a cor de conteudo (accent aplicado em toggles/sliders/badges daquela tab).
- O painel lateral (`CreateSidePanel`) pode ser trocado de lado arrastando o header dele (ou com um clique simples).

## Persistencia

- Arquivo padrao: `<nome-do-script>/config.json` na pasta do executor (ex.: `potato/config.json`).
- Conteudo: `Version`, `Settings` (todas as opcoes com `Id` + configs reservadas da biblioteca), `CustomThemes`, `TabOrder`, `TabColors`, `ContentColors`, `ItemOrder`, `WatermarkPos`.
- `Version` e sempre reescrita com a versao atual ao abrir, sem sobrescrever as suas preferencias (merge so da versao).
- `ConfigFile = false` desativa tudo (a biblioteca mostra "File access unavailable" na tab Configs).

## Exemplo completo

Veja `Example.lua`: recria o potato original (ESP de caixa/cantos/nome/distancia/vida/tracer, chams, preview 3D do personagem com overlay de ESP, walk speed, jump power, FOV, infinite jump, noclip, fullbright, gravidade, relogio, tabs visuals/player/world/misc) usando **somente a API publica** — e a referencia de como integrar a biblioteca no seu script.

## Creditos e licenca

- Visual e conceito: **potato**. Se for redistribuir ou publicar o seu script usando esta biblioteca, mantenha o credito (a cartao de licenca na tab Configs faz isso por voce).
- Codigo: MIT (veja `LICENSE`). O visual continua pertencendo ao potato.
- Icones: [Lucide](https://lucide.dev) (ISC).
