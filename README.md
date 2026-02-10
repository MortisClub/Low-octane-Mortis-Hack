<div align="center">

  <!-- БАННЕР / ЛОГО -->
  <!-- ЗАМЕНИ ССЫЛКУ НИЖЕ НА СВОЙ БАННЕР / ЛОГО -->
  <img src="https://i.ibb.co/bRb9CXZC/sqg5xpd7.jpg" alt="Mortis Hack Banner" width="720">

  <br><br>

  <!-- БЕЙДЖИ -->
  <img src="https://img.shields.io/badge/Roblox-Script-blueviolet?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Mortis-v10.2-red?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Xeno-Fix-black?style=for-the-badge" />
  <img src="https://img.shields.io/badge/UI-Rayfield-00bcd4?style=for-the-badge" />

  <br><br>

  <b>Mortis v10.2 — Xeno Fix</b>
  <p>Обновлённая версия без хуков: оружие/прицел не ломается в новом Xeno.</p>

  <!-- ПРЕВЬЮ ИНТЕРФЕЙСА / ГЕЙМПЛЕЯ -->
  <!-- Можешь заменить на свой скрин / гифку меню -->
  <img src="https://i.ibb.co/JjvKcCY3/fmycru3m.jpg" alt="Mortis Hack Preview" width="480">

</div>

---

### Основные функции

- **Aimbot**: плавное/агрессивное наведение, FOV‑круг, пресеты  
- **ESP / WH**: подсветка игроков по командам (headcloth / band / neutral)  
- **Visuals**: Fullbright  

**Удалено в v10.2** (по совместимости с новым Xeno):
- **Magic Bullet / hookmetamethod** (ломает оружие в новой версии Xeno)

Все функции разнесены по модулям, а единая точка входа — `main.lua`  
([посмотреть на GitHub](https://github.com/MortisClub/Low-octane-Mortis-/blob/main/main.lua)).

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
- **`runtime.lua`** — основной скрипт v10.2 (ESP + Aimbot + Fullbright) и Rayfield‑GUI.
- **Без хуков**: в v10.2 нет `hookmetamethod`, чтобы не ломать оружие в новом Xeno.

---

## Структура проекта

- **`main.lua`**  
  Точка входа. Подгружает `runtime.lua` по HTTP (`game:HttpGet`) и выполняет.

- **`runtime.lua`**  
  Основной скрипт v10.2: ESP + Aimbot + Fullbright + Rayfield‑GUI (без хуков).

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

