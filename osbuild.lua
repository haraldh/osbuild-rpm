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

    local users = rpm.expand("%{?osbuild_useradd_" .. name .. "_users}")
    local _,n_users = users:gsub("%S+", "")
    rpm.define("osbuild_useradd_" .. name .. "_users " .. users .. " " .. user)

    if group ~= "" then
        rpm.define("osbuild_useradd_" .. name .. "_user" .. n_users .. "_group " .. group)
    end

    if gecko ~= "" then
        rpm.define("osbuild_useradd_" .. name .. "_user" .. n_users .. "_gecko " .. gecko)
    end

    if home ~= "" then
        rpm.define("osbuild_useradd_" .. name .. "_user" .. n_users .. "_home " .. home)
    end

    if shell ~= "" then
        rpm.define("osbuild_useradd_" .. name .. "_user" .. n_users .. "_shell " .. shell)
    end

    if uid ~= "" then
        rpm.define("osbuild_useradd_" .. name .. "_user" .. n_users .. "_uid " .. uid)
    end

    if groups ~= "" then
        rpm.define("osbuild_useradd_" .. name .. "_user" .. n_users .. "_groups " .. groups)
    end

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

    local groups = rpm.expand("%{?osbuild_groupadd_" .. name .. "_groups}")
    local _,n_groups = groups:gsub("%S+", "")
    rpm.define("osbuild_groupadd_" .. name .. "_groups " .. groups .. " " .. group)

    if gid ~= "" then
        rpm.define("osbuild_groupadd_group" .. n_groups .. "_gid " .. gid)
    end

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

    local users = rpm.expand("%{?osbuild_useradd_" .. name .. "_users}")
    for user in users:gmatch("%S+") do
        print(rpm.expand("%{_sbindir}/useradd ") .. user .. "\n")
    end

    local groups = rpm.expand("%{?osbuild_groupadd_" .. name .. "_groups}")
    for group in groups:gmatch("%S+") do
        print(rpm.expand("%{_sbindir}/groupadd ") .. group .. "\n")
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

    local users = rpm.expand("%{?osbuild_useradd_" .. name .. "_users}")
    if users ~= "" then
        print(",\n")
        print("  \"users\": [")
        local first = true
        local index = 0
        for user in users:gmatch("%S+") do
            if not first then
              print(",")
            end
            first = false
            print("\n")
            print("    {\n")
            print("      \"name\": \"" .. user .. "\"")
            local uid = rpm.expand("%{?osbuild_useradd_" .. name .. "_user" .. index .. "_uid}")
            if uid ~= "" then
                print(",\n")
                print("      \"uid\": " .. uid)
            end
            print("\n")
            print("    }")
            index = index + 1
        end
        print("\n")
        print("  ]")
    end

    local groups = rpm.expand("%{?osbuild_groupadd_" .. name .. "_groups}")
    if groups ~= "" then
        print(",\n")
        print("  \"groups\": [")
        local first = true
        local index = 0
        for group in groups:gmatch("%S+") do
            if not first then
              print(",")
            end
            first = false
            print("\n")
            print("    {\n")
            print("      \"name\": \"" .. group .. "\"")
            local gid = rpm.expand("%{?osbuild_groupadd_" .. name .. "_group" .. index .. "_gid}")
            if gid ~= "" then
                print(",\n")
                print("      \"gid\": " .. gid)
            end
            print("\n")
            print("    }")
        end
        print("\n")
        print("  ]")
        index = index + 1
    end

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
	install = install
}

_G.json = osbuild

return osbuild


