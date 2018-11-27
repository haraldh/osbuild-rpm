--[[
    osbuild - Export structured data to streamline the creation of operating system images
]]

local _G = _G

package.path = package.path .. ";/usr/share/lua/" .. _VERSION:gsub("[^0-9.]+", "") .. "/?.lua"
local json = require("json")

local function dwarn(m)
    rpm.expand("%{warn:" .. m .. "}")
end

local function derror(m)
    rpm.expand("%{error:" .. m .. "}")
end

local function load_state()
    return json.decode(rpm.expand("%{?osbuild}"))
end

local function save_state(s)
    rpm.define("osbuild {" .. json.encode(s) .. "}")
end

local function useradd(name, user, group, gecko, home, shell, uid, groups)
    local osbuild = load_state()

    if not osbuild then osbuild = {} end
    if not osbuild[name] then osbuild[name] = {} end
    if not osbuild[name]["users"] then osbuild[name]["users"] = {} end
    if not osbuild[name]["users"][user] then osbuild[name]["users"][user] = {} end

    osbuild[name]["users"][user]["group"] = group
    osbuild[name]["users"][user]["gecko"] = gecko
    osbuild[name]["users"][user]["home"] = home
    osbuild[name]["users"][user]["shell"] = shell
    osbuild[name]["users"][user]["uid"] = tonumber(uid)
    osbuild[name]["users"][user]["groups"] = groups

    save_state(osbuild)

    print("Requires(pre): " .. rpm.expand("%{_sbindir}/useradd") .. "\n")
    print("Provides: user(" .. user .. ")\n")
end

local function groupadd(name, group, gid)
    local osbuild = load_state()

    if not osbuild then osbuild = {} end
    if not osbuild[name] then osbuild[name] = {} end
    if not osbuild[name]["groups"] then osbuild[name]["groups"] = {} end
    if not osbuild[name]["groups"][group] then osbuild[name]["groups"][group] = {} end

    osbuild[name]["groups"][group]["gid"] = tonumber(gid)

    save_state(osbuild)

    print("Requires(pre): " .. rpm.expand("%{_sbindir}/groupadd") .. "\n")
    print("Provides: group(" .. group .. ")\n")
end

local function pre(name)
    local osbuild = load_state()
    if not osbuild[name] then return end

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

local function install(name)
    local osbuild = load_state()
    if not osbuild[name] then return end

    print("mkdir -p " .. rpm.expand("%{buildroot}%{_datarootdir}/osbuild") .. "\n")
    print("cat >" .. rpm.expand("%{buildroot}%{_datarootdir}/osbuild/") .. name .. ".json <<EOF\n")
    print(json.encode(osbuild[name]))
    print("\n")
    print("EOF\n")
end

local function files(name)
    local osbuild = load_state()
    if not osbuild[name] then return end

    print(rpm.expand("%{_datarootdir}/osbuild/") .. name .. ".json\n")
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
