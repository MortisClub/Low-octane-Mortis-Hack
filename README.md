<div align="center">

  <!-- БАННЕР / ЛОГО -->
  <!-- ЗАМЕНИ ССЫЛКУ НИЖЕ НА СВОЙ БАННЕР / ЛОГО -->
  <img src="https://i.ibb.co/bRb9CXZC/sqg5xpd7.jpg" alt="Mortis Hack Banner" width="720">

  <br><br>

  <!-- БЕЙДЖИ -->
  <img src="https://img.shields.io/badge/Roblox-Script-blueviolet?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Mortis-v11.2-red?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Xeno-Fix-black?style=for-the-badge" />
  <img src="https://img.shields.io/badge/UI-Rayfield-00bcd4?style=for-the-badge" />

  <br><br>

  <b>Mortis v11.2 — Config/Monolith</b>
  <p>Версия без хуков с системой конфигов и осознанным монолитным `runtime.lua` под Xeno.</p>

  <!-- ПРЕВЬЮ ИНТЕРФЕЙСА / ГЕЙМПЛЕЯ -->
  <!-- Можешь заменить на свой скрин / гифку меню -->
  <img src="https://i.ibb.co/JjvKcCY3/fmycru3m.jpg" alt="Mortis Hack Preview" width="480">

</div>

---

### Основные функции

- **Aimbot**: плавное/агрессивное наведение, FOV‑круг, пресеты  
- **ESP / WH**: подсветка игроков по командам (headcloth / band / neutral)  
- **Visuals**: Fullbright  

**Удалено в v10.x** (по совместимости с новым Xeno):
- **Magic Bullet / hookmetamethod** (ломает оружие в новой версии Xeno)

Единая точка входа — `main.lua`, который загружает монолитный `runtime.lua`  
([посмотреть на GitHub](https://github.com/MortisClub/Low-octane-Mortis-/blob/main/main.lua)).  
Монолитный формат выбран специально: так Xeno гарантированно загружает весь код без `require` и дополнительных модулей.

---

## Быстрый старт

 **Запуск в Xeno / другом Lua‑экзекьюторе**:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MortisClub/Low-octane-Mortis-/main/main.lua"))()
```

После запуска откроется Rayfield‑GUI с вкладками:
- **ESP**
- **Aimbot**
- **Visuals**

---

## Как это работает

- **`main.lua`** — загрузчик.
- **`runtime.lua`** — основной скрипт v11.2 (ESP + Aimbot + Fullbright + Configs) и Rayfield‑GUI.
- **Без хуков**: в v10.2 нет `hookmetamethod`, чтобы не ломать оружие в новом Xeno.

---

## Структура проекта

- **`main.lua`**  
  Точка входа. Подгружает `runtime.lua` по HTTP (`game:HttpGet`) и выполняет.

- **`runtime.lua`**  
  Основной скрипт v11.2: ESP + Aimbot + Fullbright + Rayfield‑GUI + система конфигов (папка `MortisHack/`).

---

## Использование (Xeno / любой Lua‑экзекьютор)

1. Вставь строку запуска с **своей** raw‑ссылкой:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<USER>/<REPO>/main/main.lua"))()
```

2. Дождись загрузки модулей и появления Fluent‑меню.
3. Настрой нужные функции во вкладках:
   - **ESP** — подсветка игроков  
   - **Aimbot** — ключ активации, FOV, режимы наведения  
   - **Visuals** — Fullbright

---

## FAQ

-- **Почему нет Magic Bullet?**  
  В v10.2 он убран, потому что `hookmetamethod` ломает оружие/прицеливание в новом Xeno.

-- **Где менять настройки по умолчанию (FOV, плавность, цвет ESP)?**  
  В начале `runtime.lua` в таблице `Settings`.

-- **Как поменять клавишу активации аима?**  
  В игре — во вкладке **Aimbot** (Aim Key).

-- **Почему GUI не появляется?**  
  Убедись, что запускаешь именно raw‑ссылку (а не `github.com/.../blob/...`):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MortisClub/Low-octane-Mortis-/main/main.lua"))()
```

---

## Changelog

- **v11.2 — Config / Monolith**
  - **Решение по архитектуре**: `runtime.lua` оставлен монолитным файлом, а не разбит на несколько модулей (`core.lua`, `aim.lua`, `esp.lua` и т.д.).  
    - **Причина**: Xeno стабильнее и предсказуемее выполняет один большой скрипт, загруженный через `loadstring(game:HttpGet(...main.lua))()`, чем связку из нескольких `require`/доп. файлов.  
    - **Эффект**: меньше шансов, что у пользователя что‑то не догрузится (битые пути, кеш, ограничения на `require`) — всё, что нужно, всегда приезжает одним запросом.  

- **v11.1 — Config System**
  - **Добавлено**: вкладка **Configs** в Rayfield‑GUI.  
  - **Добавлено**: сохранение/загрузка конфигов в папку `MortisHack/` в формате `*.json` (например, `default.json`, `legit.json`, `rage.json`, `tournament.json`).  
  - **Добавлено**: авто‑обновление всех слайдеров/тогглов при загрузке конфига и опция авто‑загрузки `default` при старте.  
  - **Сохраняется**: все ключевые параметры из `Settings` (ESP‑цвет/прозрачность, все Aimbot‑настройки, Fullbright и т.п.).  
   - **Дизайн‑решение**: `runtime.lua` оставлен монолитным файлом вместо разбиения на несколько модулей (`core.lua`, `aim.lua`, `esp.lua` и т.д.), чтобы Xeno загружал весь код одной `loadstring(game:HttpGet(...main.lua))()` без `require` и проблем с путями.

- **v10.2 — Xeno Fix**
  - **Удалено**: Magic Bullet и любые хуки через `hookmetamethod`  
    - **Причина**: в новом Xeno хук `__namecall` ломал систему оружия/прицеливания (аргументы ремоутов портились, оружие задирало вверх, аим не работал корректно).  
  - **Удалено**: старый Fluent‑интерфейс (`ui.lua`) и модульная структура (`core.lua`, `lighting.lua`, `movement.lua`, `esp.lua`, `aim.lua`) из пути загрузки.  
    - **Причина**: упростить запуск до одной точки входа и убрать лишние зависимости; весь актуальный функционал перенесён в монолитный `runtime.lua`.  
  - **Добавлено**: новый Rayfield‑GUI с вкладками **ESP / Aimbot / Visuals**.  
  - **Упрощено**: логика — только ESP, Aimbot и Fullbright, без Movement/GodMode/прочих фич, чтобы ничего не конфликтовало с античитом и Xeno.  
  - **Поведение**: чит не трогает сетевые вызовы игры (нет `hookmetamethod`), поэтому оружие и прицел работают как в оригинале, а Aimbot управляет только твоей мышью.

