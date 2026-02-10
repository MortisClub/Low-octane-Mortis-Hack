
local BASE_URL = "https://raw.githubusercontent.com/MortisClub/Low-octane-Mortis-/main/"


local MODULES = {
    "runtime",
}

-- =========================================================
-- ОБЩИЙ ГЛОБАЛ ДЛЯ ВСЕГО ЧИТА
-- =========================================================

getgenv().Mortis = getgenv().Mortis or {}
local Mortis = getgenv().Mortis

Mortis.Modules = Mortis.Modules or {}

-- =========================================================
-- УТИЛИТА ДЛЯ ПОДГРУЗКИ ОДНОГО МОДУЛЯ
-- =========================================================

local function importModule(name)
    local url = BASE_URL .. name .. ".lua"

    local okGet, src = pcall(function()
        return game:HttpGet(url)
    end)

    if not okGet then
        warn(("[Mortis] Не удалось скачать '%s' по URL: %s\nПричина: %s")
            :format(name, url, tostring(src)))
        return
    end

    local chunk, errCompile = loadstring(src, name .. ".lua")
    if not chunk then
        warn(("[Mortis] Ошибка компиляции '%s': %s")
            :format(name, tostring(errCompile)))
        return
    end

    local okRun, result = pcall(chunk)
    if not okRun then
        warn(("[Mortis] Ошибка выполнения '%s': %s")
            :format(name, tostring(result)))
        return
    end

    -- Если модуль что‑то возвращает (таблицу функций) — сохраним.
    Mortis.Modules[name] = result
end

-- =========================================================
-- ЗАГРУЗКА ВСЕХ МОДУЛЕЙ
-- =========================================================

for _, name in ipairs(MODULES) do
    importModule(name)
end


print("[Mortis] main.lua: загрузка завершена")

