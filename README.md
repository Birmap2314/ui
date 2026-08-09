# Milenium UI Library — V3 Pro (Improved)

**Single-file Roblox UI Library** — эстетика Counter-Strike / neverlose, переписанная и отполированная для 2026.  
Исходник: `MileniumV2.lua` (~5280 строк, drop-in замена V2). Пример: `Example.lua`.

> Ветка: `arena/019fe824-ui` — на основе `d5cd024`. Все изменения обратно совместимы: ваши старые `window:tab:section:toggle/slider/dropdown/...` и `flags / config` продолжат работать без единого изменения.

---

## Что улучшено

### 🔧 Критические фиксы (без breaking changes)
- `library:tween` — теперь возвращает `Tween` (раньше `:Play()` возвращал `nil`)
- `library:create` — через `pairs`/`next`, безопасный `pcall` для `FontFace`/`UIGradient`
- `library:update_theme` / `apply_theme` — исправлена тень переменных и отсутствие `pairs` (цвет акцента теперь твинится)
- `get_config` / `load_config` — итерируют по `k,v` (раньше `_` использовался как ключ + пропущен `continue`)
- `update_config_list` — поддерживает `\` и `/`, сортировка, плейсхолдер `<no configs>`
- `resizify` — минимальный размер `520×360`, иконка-хэндл, clamp к `ViewportSize`
- `draggify` — clamp c учётом `AbsoluteSize`, плавный без “вылетов за экран”
- `notifications:fade` — логика `BackgroundTransparency` починена, стэк капится на 6
- `slider` — математика `fill` для `min==max`, округление по `intervals`
- `dropdown` — позиционирование без магического `+80`, clamp к краю экрана
- `colorpicker` — hue/sat/alpha drag с `clamp`, HEX ввод
- `keybind` — `MB4`/`MB5` (`XButton1/2` + `MouseButton4/5`), `ESC` → `NONE`
- `window` — родитель `gethui() / get_hidden_gui() / CoreGui`, `DisplayOrder`, `ResetOnSpawn=false`, опциональный `BlurEffect`
- `Register_Font` — `pcall`, фолбэк на `Gotham`/`Code` если `HttpGet` упал
- обёртки `makefolder/isfile/...` — no-op в Studio

### ⚡ Производительность и память
- `library:connection` с `pcall` + `disconnect_all()`, `unload_menu` чистит уведомления
- `player_list` — кэш аватаров `get_headshot(uid)`, дебуанс `PlayerAdded/Removing`
- уведомления — виртуализированы, `table.clear`, без утечек
- `spring()` — лёгкая “пружина” без физического движка (двухступенчатый tween), переключатель `tween/spring`

### 🎨 Визуал и UX
- единый радиус `7–8px`, мягкая тень `SliceScale 0.75`, ховеры `0.12–0.15s`
- фокус инпутов подсвечивает `accent`, инвалид-ввод дрожит
- уведомления — типы `info/success/warn/error` с левой полоской + анимация слайда
- слайдер — “пилюля” значения, тултип при драге
- dropdown — searchable (case-insensitive), `maxVisible` + scrollbar
- секция с `fading_toggle` — spring-анимация
- окно — open/close scale+fade, `fade_background(bool)` для блюра

### 🆕 Новый API (всё опционально)

| Вызов | Описание |
|---|---|
| `library:tooltip(opts)` | Ховер-тултип к любому `GuiObject` (`{text, target, delay}`) |
| `library:context_menu({items={...}})` | Правое меню `{name, callback, icon}` + `"sep"` separators, `menu.attach(target)` |
| `library:banner({text, type})` | Инлайн алерт (`info/success/warn/error`) |
| `library:radio({name, options, flag})` | Радио-группа (single choice) |
| `library:notify(text, type, title)` | Шорткат к `notifications:create_notification` |
| `library:prompt({title,text,yes,no})` | Диалог `Cancel/Confirm` с оверлеем |
| `library:get_flag(flag)` / `set_flag` | Хелперы для `flags` |
| `window:fade_background(bool)` | Вкл/выкл `BlurEffect` |
| `window:set_accent(color)` | Alias к `update_theme` |
| `section:banner/radio/...` | Чейнинг (все элементы — через `setmetatable`) |
| `library:animation_changer()` | Кнопка-переключатель `tween ↔ spring` |
| `colorpicker` hex | теперь понимает `255, 255, 255` и `HEX` |
| `dropdown` search | теперь с фильтром-строкой |
| `library:get_version()` | `"3.0.1-pro"` |

---

## Быстрый старт

```lua
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Birmap2314/ui/main/MileniumV2.lua"))()
local win = lib:window({ name="milenium", suffix="pro", gameInfo="My Game — Demo", size=UDim2.new(0,740,0,580) })
local tab = win:tab({ name="Combat", tabs={"Aimbot","Checks"} })

local sec = tab[1]:column({}):section({ name="Aimbot", icon="rbxassetid://6031094670" })
sec:toggle({ name="Enabled", flag="aim_enabled", default=false, callback=print })
   :keybind({ name="Key", flag="aim_key", key=Enum.KeyCode.E, mode="Toggle" })
   :colorpicker({ name="Color", flag="aim_color", color=Color3.fromRGB(155,150,219) })
sec:slider({ name="FOV", flag="fov", min=0, max=500, default=120, suffix="°" })
sec:dropdown({ name="Part", flag="part", options={"Head","Torso"}, default="Head" })
sec:button({ name="Notify", callback=function() lib:notify("Hello!","success") end })

-- new V3:
sec:banner({ text="Right-click me for menu", type="info" })
sec:radio({ name="Mode", flag="mode", options={"A","B","C"}, default="A" })
local menu = lib:context_menu({ items={{name="Copy", callback=function() print("copied") end}, "sep", {name="Reset", callback=function() end}} })
menu.attach(sec) -- right-click section

lib:init_config(win) -- save/load/delete + accent + menu bind
```

Полный демо — `Example.lua` (скопируй целиком в executor / Studio `loadstring`).

---

## Конфиги

- Папка: `milenium/configs/<name>.cfg` (JSON `flags`)
- Кнопки: **Save / Load / Delete** в `Settings → Configs` (из `library:init_config`)
- Акцент сохраняется отдельно, но можно и в конфиг — `library:update_theme("accent", col)`
- `library:get_config()` / `library:load_config(json)` — ручное сохранение

### Безопасные обёртки для Studio

```lua
-- в Studio нет makefolder/isfile — библиотека no-op’ит сама
-- в экзекуторах с gethui — уйдёт в hidden gui, иначе в CoreGui
```

---

## Миграция с V2

Ничего менять не нужно. Все старые вызовы `window → tab → column → section → toggle/slider/dropdown/colorpicker/textbox/keybind/button/list` работают. Новые поля (`type` для уведомлений, `flag` для баннеров и т.д.) — опциональны.

Если ты использовал хак `fag()` — он остался алиасом, но лучше `library:count_flags()`.

---

## Структура файла

```
MileniumV2.lua (~231k, 5280 строк)
─ Variables + Safe executor layer
─ Library init (flags, themes, fonts с pcall)
─ Misc functions (tween/spring, resizify/draggify, конвертеры, темы, connections)
─ window / tab / column / section (скелет UI)
─ Elements: toggle, slider, dropdown, label, colorpicker, textbox, keybind, button, settings, list
─ Config (init_config)
─ V2 new: player_list, search, watermark, keybind_list, hotbar, badge, progress_bar, divider, player_card, multi_select, tab_list, input, set_animation
─ Notifications (typed, capped)
─ V3 new: tooltip, context_menu, banner, radio, prompt, animation_changer, get_version
```

---

## Tips & совместимость

- **Executor**: Synapse X / KRNL / Fluxus / Electron / Delta / Solara — ок. В Studio — ок (file/io no-op).
- **Keybind**: правый клик по блоку → смена `Hold/Toggle/Always`. `MB1/2/3/4/5`, `ESC` очищает.
- **Dropdown**: теперь клик вне закрывает, позиционируется clamped.
- **Colorpicker**: ввод `R, G, B, A` (`255, 230, 120, 0.5`) или `HEX` (`#9B96DB`).
- **Theming**: `library:update_theme("accent", Color3.fromRGB(...))` — твинит всё.

---

## Чейнджлог

### v3.0.1-pro (2026-08-09)
- Фикс `tween` return, `create`/`update_theme`, `get_config`/`load_config`, `update_config_list`
- `resizify`/`draggify` clamp, `gethui_safe`, `BlurEffect`, font fallback
- Notifications с типами и капом 6, slide анимация
- `tooltip`, `context_menu`, `banner`, `radio`, `prompt`, `notify`, `get_flag/set_flag`, `fade_background`
- Поддержка `MB4/MB5`, HEX в colorpicker, пример `Example.lua`, доки

### v2 (base)
- Оригинал @finobe + V2 добавки (player_list, watermark, keybind_list, hotbar, etc.)

---

## Лицензия

MIT — делай что хочешь, но сохрани кредиты `finobe` / `milenium`.
