# Milenium UI — V3 Pro

> **Single-file Roblox UI Library** — эстетика CS2 / neverlose, переписанная и отполированная под 2026. Один файл `MileniumV2.lua`, drop-in замена V2, Studio-safe.

- **Файл:** `MileniumV2.lua` — **~5280 строк / 231кб**
- **Демо:** `Example.lua` (короткий), `FullExample.lua` (100% API, 700+ строк)
- **Версия:** `library:get_version()` → `3.0.1-pro` · ветка `arena/019fe824-ui`
- **Совместимость:** Synapse X / KRNL / Fluxus / Electron / Delta / Solara + Roblox Studio (file/io no-op)
- **Лицензия:** MIT (кредиты `finobe` / `milenium`)

---

## Содержание

- [Установка](#установка)
- [Quick Start (30 сек)](#quick-start-30-сек)
- [Архитектура](#архитектура-window--tab--column--section)
- [Flags и Configs](#flags-и-configs)
- [Темизация](#темизация)
- [Уведомления](#уведомления)
- [API Reference](#api-reference)
  - [window](#window--librarywindow)
  - [tab / seperator](#tab--librarytab--seperator)
  - [column / sub_tab](#column--sub_tab)
  - [section](#section)
  - [toggle](#toggle)
  - [slider](#slider)
  - [dropdown](#dropdown)
  - [label / divider / badge](#label--divider--badge)
  - [colorpicker](#colorpicker)
  - [textbox / input](#textbox--input)
  - [keybind](#keybind)
  - [button](#button)
  - [settings / list](#settings--list)
  - [player_list / search](#player_list--search)
  - [player_card / watermark / keybind_list / hotbar](#player_card--watermark--keybind_list--hotbar)
  - [progress_bar / tab_list / multi_select](#progress_bar--tab_list--multi_select)
  - [banner / radio / prompt / tooltip / context_menu](#banner--radio--prompt--tooltip--context_menu-новые-v3)
- [Полный список V3 новинок](#что-нового-в-v3)
- [Исправленные баги](#исправленные-баги-v2--v3)
- [Best practices](#best-practices)
- [Миграция с V2](#миграция-с-v2)
- [Структура файла](#структура-файла)
- [Changelog](#changelog)
- [FAQ](#faq)

---

## Установка

**Executor (рекомендуется):**
```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Birmap2314/ui/main/MileniumV2.lua"))()
```
**Studio / require:**
```lua
local library = require(path.to.MileniumV2)
-- или
local library = loadstring(readfile("MileniumV2.lua"))()
```
**Локально:**
```lua
local lib = loadstring(game:HttpGet("file://MileniumV2.lua"))()
-- Studio: file/io no-op’ится автоматически, шрифты фолбэкнутся на Gotham
```

Никаких зависимостей. Один `require`/`loadstring` — и готово.

---

## Quick Start (30 сек)

```lua
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Birmap2314/ui/main/MileniumV2.lua"))()
local win = lib:window({ name="milenium", suffix="pro", gameInfo="My Game — Demo", size=UDim2.new(0,780,0,620) })

-- Табы слева + верхние sub-tabs
local combat = win:tab({ name="Combat", icon="rbxassetid://6031094670", tabs={"Aimbot","Checks"} })
local visuals = win:tab({ name="Visuals", tabs={"ESP","World"} })

-- Колонки + секция
local sec = combat[1]:column({}):section({ name="Aimbot", icon="rbxassetid://6031094670" })

sec:toggle({ name="Enabled", flag="aim_enabled", default=false, callback=print })
   :keybind({ name="Key", flag="aim_key", key=Enum.KeyCode.E, mode="Toggle" })
   :colorpicker({ name="Color", flag="aim_color", color=Color3.fromRGB(155,150,219) })

sec:slider({ name="FOV", flag="fov", min=0, max=500, default=120, suffix="°" })
sec:dropdown({ name="Part", flag="part", items={"Head","Torso","Random"}, default="Head" })
sec:button({ name="Notify", callback=function() lib:notify("Hello!","success") end })

-- Новое V3:
sec:banner({ text="Right-click me!", type="info" })
sec:radio({ name="Mode", flag="mode", options={"A","B","C"}, default="A" })

lib:init_config(win) -- Save/Load/Delete + accent + menu bind
```

> Весь `FullExample.lua` — копипаста с 700+ строк, покрывает **каждый** элемент.

---

## Архитектура: window → tab → column → section

```
window = library:window({ name, suffix, gameInfo, size })
tabPages = window:tab({ name, icon, tabs = {"SubA","SubB",...} })
-- tabPages[1] == страница SubA, [2]==SubB
col = tabPages[1]:column({ size=1 })           -- или page:sub_tab({}):column({})
sec = col:section({ name, icon, size=0.6, fading_toggle=true, default=true })
-- sec → все элементы: sec:toggle / slider / dropdown / ... (чейнинг)
```

- **window:seperator({name})** — заголовок-разделитель в левом списке табов.
- **page:sub_tab({})** — flex-контейнер для `column` в строку (горизонтально).
- **section** — скроллируемый блок (`ScrollingFrame`), `fading_toggle` добавляет свитч в шапку (затемняет содержимое).

Чейнинг: почти все элементы возвращают `self`, можно `toggle(...):keybind(...):colorpicker(...)` в одну строку.

---

## Flags и Configs

**Flags** — глобальная таблица `library.flags[flag] = value`. Каждый элемент с `flag` туда пишет.

```lua
sec:toggle({ name="GodMode", flag="god", default=false })
print(library:get_flag("god")) -- false
library:set_flag("god", true)  -- триггерит callback + config_flags

-- напрямую:
library.flags.god = true
```

**Configs** — JSON в `milenium/configs/<name>.cfg`:
```lua
library:get_config()         --> '{"god":true,"fov":120,"aim_key":{"key":"Enum.KeyCode.E","mode":"Toggle","active":true}}'
library:load_config(jsonStr) --> применит через library.config_flags

library:init_config(window)  -- создаёт UI: List + Textbox + Save/Load/Delete + Menu Bind + Accent
-- Кнопки:
-- Save: берёт имя из Textbox или List, пишет writefile(..., get_config())
-- Load: readfile + load_config
-- Delete: delfile
-- Поддерживает оба сепаратора "\" и "/", авто-сортировка, "<no configs>" если пусто
```

**Советы:**
- Давай осмысленные `flag` (`aim_fov`), не `flagnumber3`.
- `library:next_flag()` — авто-генератор если `flag` не указан.
- Не используй один `flag` на два элемента — последний перетрёт.

---

## Темизация

Одна тема — `accent` (Color3). Всё остальное — тёмные тона.

```lua
library:update_theme("accent", Color3.fromRGB(255,120,140)) -- твинит все элементы
window:set_accent(Color3.fromRGB(255,120,140))               -- алиас
library:apply_theme(instance, "accent", "BackgroundColor3")  -- внутри, если делаешь кастом
lib:get_version() -- "3.0.1-pro"
window:fade_background(true) -- вкл BlurEffect (6px) за окном, false — выкл
```

Цвета по умолчанию: `BackgroundColor3=14,14,16`, `Stroke=23,23,29`, `Accent=155,150,219`.

---

## Уведомления

```lua
library.notifications:create_notification({ name="Title", info="Text", lifetime=3, type="info" })
-- типы: "info" | "success" | "warn" | "error"  (цвет полоски + анимация slide)
-- шорткат:
library:notify("Saved!", "success", "Configs") -- (text, type, title)

-- очередь капится на 6, старые удаляются, refresh_notifs виртуализирован
-- lifetime по умолчанию 3 сек, bar анимируется линейно
```

---

## API Reference

Все опции — таблица `options`. Алиасы: `name/Name`, `flag/Flag`, `items/Items`, `default/Default` и т.д. — регистронезависимо где разумно.

### window — `library:window`

```lua
window = library:window({
  name = "milenium", suffix = "pro",
  gameInfo = "Milenium V3 for Counter-Strike", -- подпись внизу
  size = UDim2.new(0, 780, 0, 620),
})
window.toggle_menu(bool)      -- показать/скрыть GUI (используется keybind из init_config)
window.fade_background(bool)  -- блюр
window.set_accent(Color3)
window.items.main             -- Frame окна (можно library:draggify / resizify уже применены)
```

Родитель: `gethui()` → `get_hidden_gui()` → `syn.protect_gui` → `CoreGui`. `DisplayOrder 10/11`, `IgnoreGuiInset`, `ZIndexBehavior`.

### tab — `library:tab` / `seperator`

```lua
pages = window:tab({
  name = "Combat",
  icon = "rbxassetid://6031094670", -- любая картинка
  tabs = {"Aimbot","Checks","Trigger"} -- верхние sub-tabs, pages[1]==Aimbot
})
pages[1]:column({}) -- и т.д.

window:seperator({ name="Utilities" }) -- некликабельный заголовок в левом списке
```

Иконка твинится в `accent` при активации.

### column / sub_tab

```lua
col = page:column({ size=1 }) -- size 0..1 доля flex
sub = page:sub_tab({})        -- контейнер для колонок в строку
colL = sub:column({})
colR = sub:column({})
```

`page` — это `pages[i]` после `window:tab`. `column` создаёт `Frame + UIListLayout`.

### section

```lua
sec = col:section({
  name = "Aimbot",
  icon = "rbxassetid://6031094670",
  size = 0.65,            -- доля высоты (0..1)
  fading_toggle = true,   -- свитч в шапке, затемняет секцию
  default = true,         -- начальное состояние fading
})
-- внутри: sec:toggle/slider/... + sec.items.outline/inline/scrolling/elements
sec.toggle_section(bool) -- если fading_toggle
```

Скролл: `ScrollingFrame` с `AutomaticCanvasSize`.

### toggle

```lua
sec:toggle({
  name = "Enabled",
  flag = "aim_enabled",
  default = false,
  type = "toggle", -- "toggle" (pill) | "checkbox" (square) | авто-random если не указан
  info = "Подпись серым под именем",
  callback = function(bool) print(bool) end,
  seperator = false, -- линия снизу
})

-- чейнинг:
sec:toggle({...}):keybind({...}):colorpicker({...})
sec:toggle({...}):settings({...}) -- шестерёнка справа
```

`flags[flag] = bool`, `config_flags[flag] = set(bool)`.

### slider

```lua
sec:slider({
  name = "FOV",
  flag = "aim_fov",
  min = 0, max = 500, default = 120,
  interval = 1, -- алиасы decimal, step
  suffix = "°", -- постфикс в правом лейбле
  info = "Подсказка",
  callback = function(val) end,
  seperator = true,
})
-- value clamp + round(interval)
-- fill анимируется: Size = UDim2((val-min)/(max-min), -4, 0, 2)
```

Поддерживает `input` рядом (отдельный элемент `input`).

### dropdown

```lua
sec:dropdown({
  name = "Target Part",
  flag = "aim_part",
  items = {"Head","Torso","Random"},
  default = "Head", -- или {"Head","Torso"} если multi=true
  multi = false,
  scrolling = false, -- скролл если >6
  width = 130,       -- ширина кнопки
  callback = function(val) -- val = string | table если multi
  end,
  seperator = true,
})
-- методы:
dd.refresh_options({"New","List"})
dd.set("Head") -- или {"Head","Torso"}
-- фильтруется через :search (см. ниже)
```

### label / divider / badge

```lua
sec:label({ name="Status: Ready", info="Серый подтекст", seperator=false })
sec:divider({ height=12 }) -- линия, height = высота контейнера
sec:badge({ text="BETA", color=Color3.fromRGB(90,200,120) }) -- пилюля
sec:badge().set_text("NEW")
```

### colorpicker

```lua
sec:colorpicker({
  name = "ESP Color",
  flag = "esp_color",
  color = Color3.fromRGB(155,150,219),
  alpha = 0, -- 0..1 (в flags: Transparency)
  callback = function(col, alpha) end,
  seperator = false,
})
-- если вызван как :toggle(...):colorpicker(...) — встроится в строку toggle справа
-- hue/sat/alpha drag с clamp, ввод "R, G, B, A" или HEX
-- flags[flag] = { Color=Color3, Transparency=number }
```

### textbox / input

```lua
sec:textbox({
  name = "Webhook",
  placeholder = "https://...",
  flag = "webhook",
  default = "",
  callback = function(text) end,
})

sec:input({ -- числовой (можно и строку)
  name = "Distance",
  flag = "dist",
  placeholder = "100",
  default = 100,
  min = 0, max = 5000,
  integer = true, -- floor
  callback = function(val) end, -- val = number | string если не число
})
```

### keybind

```lua
sec:keybind({
  name = "Aim Key",
  flag = "aim_key",
  key = Enum.KeyCode.E, -- или Enum.UserInputType.MouseButton1/2/3/4/5
  mode = "Toggle", -- "Hold" | "Toggle" | "Always"
  default = false, -- active
  callback = function(activeBool) end,
})
-- ЛКМ на блок — бинд (покажет "..."), ESC → NONE
-- ПКМ — меню Hold/Toggle/Always
-- Поддержка MB4/MB5 (XButton1/2), MouseButton4/5
-- flags[flag] = { key=Enum, mode=string, active=bool }
-- keybind_viewer (см. ниже) трекает все такие флаги
```

### button

```lua
sec:button({ name="Apply", callback=function() end })
-- эффект: текст мигает accent на клик
```

### settings / list

```lua
local popup = sec:toggle({ name="Feature", flag="feat" }):settings({})
-- popup — Frame с кнопкой-шестерёнкой справа от toggle
-- popup.items.outline/inline/elements — можно добавлять внутрь:

sec:list({
  options = {"Server #1","Server #2"},
  flag = "server_pick",
  callback = function(opt) print(opt) end,
})
-- list.refresh_options({"New","Options"})
-- flags[flag] = string (выбранный)
```

### player_list / search

```lua
local plist = sec:player_list({
  name = "Online Players",
  flag = "selected_player", -- flags[flag] = Player Instance
  max_height = 200,
  include_self = true,
  callback = function(player) print(player) end,
})
-- живой: PlayerAdded/Removing → refresh, аватарки headshot, клик → accent

-- SEARCH — фильтрует любой list/dropdown/player_list
local fruits = sec:list({ options={"Apple","Banana"}, flag="fruits" })
sec:search({
  name = "Search",
  placeholder = "filter...",
  flag = "search_fruits",
  target = fruits, -- или dropdown cfg, или player_list
})
```

### player_card / watermark / keybind_list / hotbar

```lua
local card = sec:player_card({
  player = game.Players.LocalPlayer,
  name = "DisplayName",
  role = "LocalPlayer",
  accent = Color3.fromRGB(155,150,219),
})
card.update(player, name, role)
card.set_status_color(Color3)

local wm = library:watermark({ text="milenium.pro", sub="v3.0.1" })
wm.set_text("new title","new sub")
wm.set_visible(false) -- draggable, показывает fps/ping (обновление 0.5с)

local kblist = library:keybind_list() -- плавающая панель
-- kblist.track("Name", get_activeFn, get_keyFn) -- ручной трекинг, если нужно
-- авто-обновление раз в 0.25с

local hotbar = library:hotbar({ position=UDim2.new(0.5,0,0,10) })
local btn = hotbar.add_button({ name="ESP", active=true, width=44, callback=function(active) end })
hotbar.set_visible(false) -- draggable
```

### progress_bar / tab_list / multi_select

```lua
local bar = sec:progress_bar({ name="Loading", min=0, max=100, value=30, smoothing=0.2 })
bar.set(76) -- анимируется Quint, показывает "76 / 100"
bar.set_color(Color3)

sec:tab_list({
  name = "Quick Action",
  options = {"Spectate","Teleport","Copy"},
  default = 1,
  callback = function(opt, idx) end,
})
-- tab_list.select(2)

sec:multi_select({
  name = "Whitelist",
  flag = "wl",
  options = {"A","B","C","D"},
  default = {"A"},
  max = 3, -- лимит
  callback = function(tbl) end,
})
-- multi_select.refresh({"New","List"})
-- flags[flag] = table
```

### banner / radio / prompt / tooltip / context_menu (новые V3)

```lua
local banner = sec:banner({ text="Info message", type="info" }) -- info/success/warn/error
banner.set_text("New text")
banner.set_type("error")

sec:radio({
  name = "Aim Mode",
  flag = "aim_mode",
  options = {"Camera","Mouse","Silent"},
  default = "Camera",
  callback = function(v) end,
})
-- flags[flag]=string, config_flags поддерживает сохранение

library:prompt({
  title="Reset?",
  text="Удалить конфиг?",
  yes=function() print("yes") end,
  no=function() print("no") end,
}) -- оверлей + blur, клик вне — no

-- TOOLTIP — на любой GuiObject или элемент-секции:
sec:tooltip({ text="Подсказка при ховере", delay=0.25 }) -- если вызван от секции — аттачится к последнему элементу
local t = sec:toggle({ name="X", flag="x" })
t:tooltip({ text="Тултип на тоггле" })
library:tooltip({ text="Глобальный", target=t }) -- альтернативно

-- CONTEXT MENU — ПКМ меню
local menu = library:context_menu({ items={
  { name="Copy", callback=function() end },
  { name="Paste", callback=function() end },
  "sep",
  { name="Reset", callback=function() end },
}})
menu.attach(sec)        -- ПКМ по секции
menu.attach(t)          -- или по элементу
menu.set_items({ ... }) -- обновить
menu.open_at(UDim2.fromOffset(x,y))
menu.close()
```

### Прочие хелперы

```lua
library:tween(obj, {BackgroundColor3=Color3}, Enum.EasingStyle.Quad, 0.22) -- возвращает Tween
library:spring(obj, props, speed, damping) -- если animation_style=="spring" иначе tween

library:mouse_in_frame(guiObject) --> bool (использует GetMouseLocation)
library:draggify(frame, handle?) -- перетаскивание с clamp
library:resizify(frame)           -- ресайз с хэндлом

library:get_flag("aim_fov")       -- алиас flags[flag]
library:set_flag("aim_fov", 250)  -- триггерит config_flags если есть
library:notify("Text","success","Title")
library:get_version()             --> "3.0.1-pro"
library:count_flags()             --> число флагов
library:next_flag()               --> "flagnumberN"

library:connection(signal, fn)    -- safe pcall + хранит в library.connections
library:disconnect_all()
library:unload_menu()             -- Destroy GUI + disconnect + clear flags

library:create("Frame", { ... })  -- safe Instance.new + pcall props
library:convert("255, 128, 0, 0.5") --> r,g,b,a
library:convert_enum("Enum.KeyCode.E") --> Enum.KeyCode.E

library:set_animation("tween"|"spring")
library:animation_changer() -- создаёт кнопку-переключатель (вызывать от секции: sec:animation_changer())

-- Утилиты:
library:round(1.234, 0.01) --> 1.23
library:update_theme("accent", Color3)
library:apply_theme(instance, "accent", "BackgroundColor3")
```

---

## Что нового в V3

| Фича | Пример |
|---|---|
| `tooltip` | Ховер с `RenderStepped` позиционированием, `delay` |
| `context_menu` | ПКМ, `attach`, clamp к экрану, global close |
| `banner` | Цветная левая полоска, `set_text/type` |
| `radio` | Кружки + `config_flags`, `set(v)` |
| `prompt` | Оверлей `BackgroundTransparency 0.45`, `BlurEffect` |
| `notify` | Шорткат с `type` |
| `get_flag/set_flag` | Безопасный доступ к `flags` |
| `fade_background` | `BlurEffect.Size 6` вкл/выкл |
| `spring` | Двухступенчатый tween для `spring` стиля |
| `keybind` MB4/MB5 | `XButton1/2`, `MouseButton4/5` + `ESC → NONE` |

Все новые вызовы — опциональны, старые не ломаются.

---

## Исправленные баги V2 → V3

- **tween** возвращал `nil` → теперь `Tween`
- **create/update_theme** — отсутствовали `pairs/next`, тень `_` → fixed
- **get_config/load_config** — `_` как ключ → `k`
- **update_config_list** — только `\` → `/` + `\\`, сортировка
- **resizify/draggify** — вылет за экран → clamp + `MIN_W/H`
- **notifications:fade** — `BackgroundTransparency` 0.6×1→1 → per-instance `bg <0.9`
- **slider** — `fill` при `min==max` → clamp, `round(interval)`
- **dropdown** — `+80` → clamp, `ScrollingFrame` если много
- **colorpicker** — hue/sat `clamp`, HEX
- **keybind** — `MB4/MB5` не работали → added
- **window** — `CoreGui` only → `gethui` фолбэк, `DisplayOrder`, `ResetOnSpawn`
- **fonts** — падал если `HttpGet` нет сети → `pcall` + `Gotham` fallback
- **file/io** — падал в Studio → no-op wrappers
- **connections** — утечки → `disconnect_all`, `unload_menu` чистит `notifs`

---

## Best practices

1. **Флаги:** давай уникальные `flag` (`aim_fov`), не `flagnumber`. Используй `library:next_flag()` только если лень.
2. **Callbacks:** не делай тяжёлую логику внутри `callback` слайдера (он дергается каждый `InputChanged`). Дебаунс: `task.delay(0.1, fn)`.
3. **Dropdown/Lists:** если много опций (>12) — `scrolling=true` или `multi_select`.
4. **Keybinds:** `mode="Always"` сразу `active=true`. Проверяй `flags[flag].active` в рендере.
5. **Configs:** вызывай `library:init_config(window)` **один раз** в конце, после всех элементов. Сохраняй accent отдельно если хочешь персист.
6. **Tooltips:** `delay 0.2-0.3` оптимально, не спамь.
7. **Context menu:** `menu.attach` можно на несколько целей, но не создавай 10 меню — одно переиспользуй через `set_items`.
8. **Hotbar/Watermark:** храни ссылку (`local wm = library:watermark(...)`), иначе не скроешь.

---

## Миграция с V2

Ничего менять не нужно.

```lua
-- V2:
local win = library:window({name="test"})
local tab = win:tab({name="Main", tabs={"A","B"}})
tab[1]:column({}):section({name="S"}):toggle({name="T", flag="f"})
-- V3: тот же код работает, плюс новые поля опциональны:
tab[1]:column({}):section({...}):toggle({...}):tooltip({text="new"})
```

Если использовал хак `fag()` — алиас остался, но лучше `library:count_flags()`.

---

## Структура файла

```
MileniumV2.lua (~5280 строк, 231кб)
├─ Variables + Safe executor layer (gethui_safe, makefolder wrappers, TWEEN_DEFAULT)
├─ Library init (flags, themes, keys MB4/MB5, fonts try_register fallback)
├─ Misc (tween/spring, resizify/draggify clamp, convert, update_config_list robust, get/load_config, round, apply/update_theme fixed, connection safe, create safe, unload_menu)
├─ window / tab / seperator / column / sub_tab / section (ScrollingFrame, fading_toggle)
├─ Elements
│  ├─ toggle (toggle/checkbox, info, keybind/colorpicker/settings chaining)
│  ├─ slider (min/max/interval/suffix, fill tween)
│  ├─ dropdown (single/multi, width, scrolling)
│  ├─ label / colorpicker (hue/sat/alpha + hex) / textbox / keybind (Hold/Toggle/Always, MB4/5) / button / settings / list
├─ Config (init_config)
├─ V2 extras: player_list (headshot caching), search, watermark (fps/ping), keybind_list, hotbar, badge, progress_bar, divider, player_card, multi_select, tab_list, input, set_animation
├─ Notifications (typed, capped 6, slide, left_bar)
└─ V3 extras: tooltip (RenderStepped), context_menu (attach, sep), banner, radio, prompt, animation_changer, get_version, get_flag/set_flag, notify, fade_background, count_flags
```

---

## Changelog

### v3.0.1-pro (2026-08-09) — текущий
- Фикс `tween/create/update_theme/get_config/load_config/update_config_list/resizify/draggify/notifications/slider/dropdown/colorpicker/keybind/window/fonts/file wrappers`
- Добавлено: `tooltip`, `context_menu`, `banner`, `radio`, `prompt`, `notify`, `get_flag/set_flag`, `fade_background`, `spring`, `count_flags`, `get_version`, MB4/MB5, HEX, `BlurEffect`
- Визуал: `7-8px` радиус, тени, `0.22s Quad`, фокус свечение
- Демо: `Example.lua` + `FullExample.lua` (100% покрытие), `README` → docs
- 5280 строк, backward compatible, exploit-agnostic

### v2 (base, finobe + Arena V2)
- Оригинал + `player_list`, `search`, `watermark`, `keybind_list`, `hotbar`, `badge`, `progress_bar`, `tab_list`, `player_card`, `input`, `divider`, `multi_select`, `context_menu` stub, `animation_changer` stub

---

## FAQ

**Q: Где хранить конфиги?**  
A: `milenium/configs/<name>.cfg`. `library:get_config()` → JSON, `library:load_config(json)`. `init_config` делает UI.

**Q: Как скрыть меню на F4?**  
A: `init_config` добавляет `Menu Bind` (дефолт `Insert`). Или `window.toggle_menu(false)` / `uis.InputBegan` → `window.toggle_menu`.

**Q: Фон размыт?**  
A: `window:fade_background(true)` включает `BlurEffect` в `Lighting`. `false` — выкл. Можно `getgenv()._MILENIUM_BLUR = false` до создания window чтобы не создавать.

**Q: Не грузятся шрифты?**  
A: В Studio / без интернета — автоматически фолбэк на `Gotham`/`GothamBold`/`Code`. Ничего не падает.

**Q: Как сделать поиск по dropdown?**  
A: `sec:search({ target = dropdownCfg })` или `target = listCfg`. `search` фильтрует `refresh_options`.

**Q: Поддержка Studio?**  
A: Да, все `makefolder/isfile/...` no-op, `gethui_safe` → `CoreGui` fallback.

---

## Лицензия

MIT — делай что хочешь, сохрани кредиты `finobe` / `milenium`. PR и ишьюсы — welcome.

> **Готово к продакшену.** Копируй `FullExample.lua` целиком, меняй флаги/колбэки под свою игру — получишь полноценный чит-меню за 5 минут.

