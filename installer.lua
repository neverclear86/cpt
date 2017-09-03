local cpturl = "https://raw.githubusercontent.com/neverclear86/cpt/master/cpt.lua"
local pkgurl = "https://raw.githubusercontent.com/neverclear86/cpt/master/package.lon"
local path = "/cpt"

local h = http.get(cpturl)
if h ~= nil then
  local cpt = loadstring(h.readAll())
  cpt("add", pkgurl)
  cpt("install", "cpt")
end
