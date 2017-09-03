local cpturl = ""
local pkgurl = ""
local path = "/cpt"

local h = http.get(cpturl)
if h ~= nil then
  local cpt = loadstring(h.readAll())
  cpt("add", pkgurl)
  cpt("install", "cpt")
end
