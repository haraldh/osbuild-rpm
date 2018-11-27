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
    return json.decode(rpm.expand("%{?___osbuild}"))
end

local function save_state(s)
    rpm.define("___osbuild {" .. json.encode(s) .. "}")
end

local function useradd(pkgname, user, group, gecko, home, shell, uid, groups)
    local osbuild = load_state()

    if not osbuild then osbuild = {} end
    if not osbuild[pkgname] then
	osbuild[pkgname] = {}
	osbuild[pkgname]["name"] = pkgname
    end
    if not osbuild[pkgname]["users"] then osbuild[pkgname]["users"] = {} end
    if not osbuild[pkgname]["users"][user] then osbuild[pkgname]["users"][user] = {} end

    osbuild[pkgname]["users"][user]["group"] = group
    osbuild[pkgname]["users"][user]["gecko"] = gecko
    osbuild[pkgname]["users"][user]["home"] = home
    osbuild[pkgname]["users"][user]["shell"] = shell
    osbuild[pkgname]["users"][user]["uid"] = tonumber(uid)

    if groups then
	osbuild[pkgname]["users"][user]["groups"] = {}
	for g in groups:gmatch("[^,]*") do
	    table.insert(osbuild[pkgname]["users"][user]["groups"], g)
	end
    end

    save_state(osbuild)

    print("Requires(pre): " .. rpm.expand("%{_sbindir}/useradd") .. "\n")
    print("Provides: user(" .. user .. ")\n")
end

local function groupadd(pkgname, group, gid)
    local osbuild = load_state()

    if not osbuild then osbuild = {} end
    if not osbuild[pkgname] then
	osbuild[pkgname] = {}
	osbuild[pkgname]["name"] = pkgname
    end
    if not osbuild[pkgname]["groups"] then osbuild[pkgname]["groups"] = {} end
    if not osbuild[pkgname]["groups"][group] then osbuild[pkgname]["groups"][group] = {} end

    osbuild[pkgname]["groups"][group]["gid"] = tonumber(gid)

    save_state(osbuild)

    print("Requires(pre): " .. rpm.expand("%{_sbindir}/groupadd") .. "\n")
    print("Provides: group(" .. group .. ")\n")
end

local function pre(pkgname)
    local osbuild = load_state()
    if not osbuild[pkgname] then return end

    if osbuild[pkgname]["users"] then
        for user,_ in pairs(osbuild[pkgname]["users"]) do
            print(rpm.expand("%{_sbindir}/useradd ") .. user .. "\n")
        end
    end

    if osbuild[pkgname]["groups"] then
        for group,_ in pairs(osbuild[pkgname]["groups"]) do
            print(rpm.expand("%{_sbindir}/groupadd ") .. group .. "\n")
        end
    end
end

function shell_quote(s)
    if string.find(s, '[^%w%+%-%=%@%_%/]') or s == '' then
	return "'" .. string.gsub(s, "'", "'\"'\"'") .. "'"
    else
	return s
    end
end

local function pretty_json(s)
    local io = require("io")
    local j = json.encode(s)
    fp = io.popen("printf -- '%s' " .. shell_quote(j) .. " | jq -SM '.'", "r")
    x = fp:read("*a")
    fp:close()
    if not x or x == '' then return j end

    return x
end

local function not_pretty_json(s)
    return json.encode(s) .. "\n"
end

local function install(pkgname)
    local osbuild = load_state()
    if not osbuild[pkgname] then return end

    print("mkdir -p " .. rpm.expand("%{buildroot}%{_datarootdir}/osbuild") .. "\n")
    print("cat >" .. rpm.expand("%{buildroot}%{_datarootdir}/osbuild/") .. pkgname .. ".json <<'EOF'\n")
    print(pretty_json(osbuild[pkgname]))
    print("EOF\n")
end

local function files(pkgname)
    local osbuild = load_state()
    if not osbuild[pkgname] then return end

    print(rpm.expand("%{_datarootdir}/osbuild/") .. pkgname .. ".json\n")
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
