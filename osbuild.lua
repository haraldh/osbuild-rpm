--[[
    osbuild - Export structured data to streamline the creation of operating system images
]]

local _G = _G

local json = require("osbuild/JSON")
json.strictTypes = true

local function dwarn(m)
    rpm.expand("%{warn:" .. m .. "}")
end

local function derror(m)
    rpm.expand("%{error:" .. m .. "}")
end

local function load_state()
    return json:decode(rpm.expand("%{?___osbuild}"))
end

local function save_state(s)
    rpm.define("___osbuild {" .. json:encode(s) .. "}")
end

local function useradd(pkgname, user, group, gecko, home, shell, uid, groups)
    local osbuild = load_state()

    osbuild = json:newObject(osbuild)
    osbuild[pkgname] = json:newObject(osbuild[pkgname])
    osbuild[pkgname]["users"] = json:newObject(osbuild[pkgname]["users"])
    osbuild[pkgname]["users"][user] = json:newObject(osbuild[pkgname]["users"][user])

    osbuild[pkgname]["users"][user]["group"] = group
    osbuild[pkgname]["users"][user]["gecko"] = gecko
    osbuild[pkgname]["users"][user]["home"] = home
    osbuild[pkgname]["users"][user]["shell"] = shell
    osbuild[pkgname]["users"][user]["uid"] = tonumber(uid)

    if groups then
        osbuild[pkgname]["users"][user]["groups"] = json:newArray(osbuild[pkgname]["users"][user]["groups"])
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

    osbuild = json:newObject(osbuild)
    osbuild[pkgname] = json:newObject(osbuild[pkgname])
    osbuild[pkgname]["groups"] = json:newObject(osbuild[pkgname]["groups"])
    osbuild[pkgname]["groups"][group] = json:newObject(osbuild[pkgname]["groups"][group])

    if gid then
        osbuild[pkgname]["groups"][group]["gid"] = tonumber(gid)
    end

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

local function install(pkgname)
    local osbuild = load_state()
    if not osbuild[pkgname] then return end

    print("mkdir -p " .. rpm.expand("%{buildroot}%{_datarootdir}/osbuild") .. "\n")
    print("cat >" .. rpm.expand("%{buildroot}%{_datarootdir}/osbuild/") .. pkgname .. ".json <<'EOF'\n")
    local pkg = osbuild[pkgname]
    pkg["name"] = pkgname
    print(json:encode_pretty(pkg))
    print("\nEOF\n")
end

local function files(pkgname)
    local osbuild = load_state()
    if not osbuild[pkgname] then return end

    print(rpm.expand("%{_datarootdir}/osbuild/") .. pkgname .. ".json\n")
end

local osbuild = {
    _VERSION = "1",
    _DESCRIPTION = "https://github.com/fabrix/osbuild",
    useradd = useradd,
    groupadd = groupadd,
    pre = pre,
    install = install,
    files = files
}

_G.osbuild = osbuild

return osbuild
