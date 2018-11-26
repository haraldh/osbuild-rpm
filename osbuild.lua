--[[
    osbuild - Export structured data to streamline the creation of operating system images
]]

local _G = _G

package.path = package.path .. ";/usr/share/lua/" .. _VERSION:gsub("[^0-9.]+", "") .. "/?.lua"
local json = require("json")

local function useradd(package, name, user, group, gecko, home, shell, uid, groups)
    if package ~= "" then
        name = name .. "_" .. package
    end

    local osbuild = json.decode(rpm.expand("%{?osbuild}"))
    osbuild = (osbuild or {})
    osbuild[name] = (osbuild[name] or {})
    osbuild[name]["users"] = (osbuild[name]["users"] or {})
    osbuild[name]["users"][user] = (osbuild[name]["users"][user] or {})
    osbuild[name]["users"][user]["group"] = group
    osbuild[name]["users"][user]["gecko"] = gecko
    osbuild[name]["users"][user]["home"] = home
    osbuild[name]["users"][user]["shell"] = shell
    osbuild[name]["users"][user]["uid"] = uid
    osbuild[name]["users"][user]["groups"] = groups

    rpm.define("osbuild {" .. json.encode(osbuild) .. "}")

    print("Requires(pre): " .. rpm.expand("%{_sbindir}/useradd") .. "\n")
    print("Provides: user(" .. user .. ")\n")
end

local function groupadd(package, name, group, gid)
    -- -n package name
    -- -S subpackage name
    -- -* groupadd options

    if package ~= "" then
        name = name .. "_" .. package
    end

    local osbuild = json.decode(rpm.expand("%{?osbuild}"))
    osbuild = (osbuild or {})
    osbuild[name] = (osbuild[name] or {})
    osbuild[name]["groups"] = (osbuild[name]["groups"] or {})
    osbuild[name]["groups"][group] = (osbuild[name]["groups"][group] or {})
    osbuild[name]["groups"][group]["gid"] = gid

    rpm.define("osbuild {" .. json.encode(osbuild) .. "}")

    print("Requires(pre): " .. rpm.expand("%{_sbindir}/groupadd") .. "\n")
    print("Provides: group(" .. group .. ")\n")
end

local function pre(package, name)
    -- -n package name
    -- -S subpackage name

    local filename = name
    if package ~= "" then
        filename = name .. "-" .. package
        name = name .. "_" .. package
    end

    local osbuild = json.decode(rpm.expand("%{?osbuild}"))

    if osbuild[name]["users"] then
       for user,_ in pairs(osbuild[name]["users"]) do
          print(rpm.expand("%{_sbindir}/useradd ") .. user .. "\n")
       end
    end

    if osbuild[name]["groups"] then
       for group,_ in pairs(osbuild[name]["groups"]) do
          print(rpm.expand("%{_sbindir}/groupadd ") .. group .. "\n")
       end
    end
end

local function install(package, name)
    -- -n package name
    -- -S subpackage name

    local filename = name
    if package ~= "" then
        filename = name .. "-" .. package
        name = name .. "_" .. package
    end

    print("mkdir -p " .. rpm.expand("%{buildroot}%{_datarootdir}/osbuild") .. "\n")
    print("cat >" .. rpm.expand("%{buildroot}%{_datarootdir}/osbuild/") .. filename .. ".json <<EOF\n")
    print("{\n")
    print("  \"name\": \"" .. filename .. "\"")
    print(rpm.expand("%{?osbuild}"))
    print("\n")
    print("}\n")
    print("EOF\n")
end

local function files(package, name)
    -- -n package name
    -- -S subpackage name

    local filename = name
    if package ~= "" then
       filename = name .. "-" .. package
       name = name .. "_" .. package
    end

    print(rpm.expand("%{_datarootdir}/osbuild/") .. filename .. ".json\n")
end

local osbuild = {
        _VERSION = "1.0",
        _DESCRIPTION = "blah blub",
        _COPYRIGHT = "Copyright (c)...",
        useradd = useradd,
        groupadd = groupadd,
        pre = pre,
        install = install,
        files = files
}

_G.json = osbuild

return osbuild
