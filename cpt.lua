---
-- Computers Package Tool
-- version: beta 1.0
-- プログラムを管理するプログラム
-- @author neverclear

--- パッケージ管理ファイル
local PKG_FILE = "/etc/cpt/pkg.lon"
--- インストール済みパッケージ管理ファイル
local INSTALLED_FILE = "/etc/cpt/installed.lon"

local function _error(tbl)
  error(textutils.serialise(tbl), 0)
end

--- Lonファイル操作
local lon = {}

--- Lonファイルにテーブルを保存
-- @param string filename 保存するファイル名
-- @param table  tbl      保存するデータ
function lon.save(filename, tbl)
  local file = fs.open(filename, "w")
  file.write(textutils.serialise(tbl))
  file.close()
end


--- Lonファイルを読み込み
-- @param   string filename 保存するファイル名
-- @return  string          読み込んだデータ
function lon.load(filename)
  local file = fs.open(filename, "r")
  if file == nil then
    return {}
  end
  local tbl = textutils.unserialise(file.readAll())
  file.close()
  return tbl
end



--------------------------------------------------------------------------------
local function loading()
  local arr = {
    "|", "/", "-", "*",
  }

  local i = 0
  while true do
    local x, y = term.getCursorPos()
    term.setCursorPos(1, y)
    term.write(arr[i + 1])
    sleep(0.1)
    i = (i + 1) % 4
  end
end

local function finishLoading()
  local x, y = term.getCursorPos()
  term.setCursorPos(1, y)
  term.write(" ")
end

--- インターネットにつながっているかの確認
-- @return boolean 接続があればtrue
local function ping()
  return http.get("http://google.com") ~= nil
end


--- URL文字列でない場合pastebinURLを生成
-- @param string url URL文字列 or PastebinCode
-- @return string  URL文字列
local function makeURL(url)
  if not http.checkURL(url) then
    url = "https://pastebin.com/raw/" .. url
  end
  return url
end


--- URLへGETでアクセス、レスポンスを返却
-- @param string url 接続先URL
-- @return string    レスポンス文字列
local function getResponse(url)
  local res = http.get(url)
  if res == nil then
    _error({code = 1002, detail = url})
  end
  local str = res.readAll()
  return str
end

--- ファイルのダウンロード
-- @param string url ファイルURL
-- @param string filename 保存先ファイル名
-- @param strint path ファイル保存先ディレクトリ
local function download(url, filename, path)
  url = makeURL(url)
  local source = getResponse(url)
  if source == nil then
    error({code = 1002, detail = url})
  end
  if not string.find(path, "\/$") then
    path = path .. "/"
  end
  local file = fs.open(path .. filename, "w")
  file.write(source)
  file.close()
end


local function pad(str, plen)
  local ret = ""
  local len = math.abs(plen) - string.len(str)
  if plen >= 0 then
    ret = string.rep(" ", plen) .. str
  else
    ret = str .. string.rep(" ", len)
  end
  return ret
end

---------------------------------------------------------------------------

--- パッケージ操作クラス
local Package = {pkg = {}}

function Package:isPackage(arg)
  return type(arg) == "table"
  and arg.author ~= nil
  and arg.packageUrl ~= nil
  and type(arg.programs) == "table"
end


function Package:new(pkg)
  local obj = {}
  setmetatable(obj, self)
  self.__index = self

  if type(pkg) == "string" then
    pkg = textutils.unserialise(pkg)
  end
  obj.pkg = pkg or {}

  return obj
end


function Package:addPackage(package)
  if not Package:isPackage(package) then
    _error({code = 2001})
  end

  for i,v in ipairs(self.pkg) do
    if v.packageUrl == package.packageUrl then
      _error({code = 2002})
      break
    end
  end

  table.insert(self.pkg, package)
end


function Package:addProgram(programtbl)
  local isInserted = false
  for i,v in ipairs(self.pkg) do
    if v.packageUrl == programtbl.packageUrl then
      table.insert(v.programs, programtbl.programs[1])
      isInserted = true
    end
  end
  if not isInserted then
    table.insert(self.pkg, programtbl)
  end
end


function Package:findPackage()

end

--- パッケージに指定したプログラム名が存在するかどうか
--  存在すればそのテーブル、しなければnilを返す
-- @param string programname プログラム名
-- @return table? 指定したプログラム名を含むパッケージテーブル
function Package:findProgram(programname)
  local target = {}

  local isExist = false
  for i, v in ipairs(self.pkg) do
    for j, w in ipairs(v.programs) do
      if w.name == programname then
        target.author = v.author
        target.packageUrl = v.packageUrl
        target.programs = {w}
        isExist = true
      end
    end
  end

  if not isExist then
    target = nil
  end

  return target
end


function Package:findAllProgram(names)
  local ret = Package:new()
  for i, v in ipairs(names) do
    ret:addProgram(self:findProgram(v))
  end
  return ret
end


function Package:getProgramList()
  local list = {}
  for i, v in ipairs(self.pkg) do
    for j, w in ipairs(v.programs) do
      table.insert(list, w)
    end
  end
  return list
end

function Package:getProgramNameList()
  local programnames = {}
  for i, v in ipairs(self:getProgramList()) do
    table.insert(programnames, v.name)
  end
  return programnames
end

--------------------------------------------------------------------------------

--- パッケージファイルにパッケージを追加する
--  cpt-get add {URL}
-- @param string url パッケージファイルのURL
local function add(url)
  url = makeURL(url)
  master = Package:new(lon.load(PKG_FILE))

  for i, v in ipairs(master.pkg) do
    if v.packageUrl == url then
      print("Already exist.")
      return
    end
  end

  local run = function()
    local package = getResponse(url)
    package = textutils.unserialise(package)
    package.packageUrl = url
    master:addPackage(package)
  end

  term.write("  " .. "Add package: " .. url)
  parallel.waitForAny(run, loading)
  finishLoading()
  print("Add completed.")

  lon.save(PKG_FILE, master.pkg)
end


--- パッケージファイル内のプログラムをインストールする
--  cpt-get install {プログラム名}
-- @param string programname プログラム名
local function install(programname)
  local installed = Package:new(lon.load(INSTALLED_FILE))
  if installed:findProgram(programname) then
    print(programname .. " is already installed.")
    return
  end
  local master = Package:new(lon.load(PKG_FILE))
  local target = master:findProgram(programname)
  if target == nil then
    _error({code = 3001})
  end

  -- プログラムをファイルに保存
  local run = function()
    local path = target.programs[1].path or "/"
    download(target.programs[1].url, programname, path)
  end

  -- 実行
  parallel.waitForAny(run, loading)
  finishLoading()
  print(programname .. " : Install completed.")

  -- インストール済みレポジトリリストに追加
  installed:addProgram(target)

  -- インストール済みレポジトリ保存
  lon.save(INSTALLED_FILE, installed.pkg)

end


--- パッケージファイルを最新状態へアップデート
--  cpt-get update
local function update()
  local old = Package:new(lon.load(PKG_FILE))
  local master = Package:new()

  -- アップデート処理
  local run = function()
    for i, v in ipairs(old.pkg) do
      term.write("  GET[" .. tostring(i) .. "] " .. v.packageUrl)
      local package = textutils.unserialise(getResponse(v.packageUrl))
      package.packageUrl = v.packageUrl
      local success, err = pcall(master.addPackage, master, package)
      if not success then
        print("GetPackageError: " .. v.packageUrl)
        table.insert(master.pkg, v)
      end
      finishLoading()
      print()
    end
  end

  -- 実行
  parallel.waitForAny(run, loading)

  lon.save(PKG_FILE, master.pkg)
end


--- インストールされているプログラムを最新へアップグレード
--  cpt-get upgrade
local function upgrade()
  local run = function()
    local master = Package:new(lon.load(PKG_FILE))
    local installed = Package:new(lon.load(INSTALLED_FILE))
    local newIns = master:findAllProgram(installed:getProgramNameList())

    for i, v in ipairs(newIns:getProgramList()) do
      -- バージョンが変更されているもののみ
      if v.version ~= installed:findProgram(v.name).programs[1].version then
        term.write("  GET[".. tostring(i) .."] " .. makeURL(v.url))
        local path = v.path or "/"
        download(v.url, v.name, path)
        finishLoading()
        print()
      end
    end

    lon.save(INSTALLED_FILE, newIns.pkg)
  end

  -- 実行
  parallel.waitForAny(run, loading)
  print("Done.")

end


local function list()
  local master = Package:new(lon.load(PKG_FILE))
  local installed = Package:new(lon.load(INSTALLED_FILE))
  local list = master:getProgramList()
  -- ソートついでに文字数取得
  local len = 0
  table.sort(list, function(a, b)
    local al = string.len(a.name)
    local bl = string.len(b.name)
    len = al > bl and al or bl
    return a.name < b.name
  end)
  for i, v in ipairs(list) do
    print(pad(v.name, -len) .. " : ver " .. v.version)
  end
end

--main---------------------------------------------------------------------

--- エラーコードからエラーメッセージを取得して表示
--  @param table err エラーオブジェクト
local function showError(err)
  local errtbl = textutils.unserialise(err)
  if errtbl ~= nil and errtbl.code == 1001 then
    print("No Internet connection.")
  elseif errtbl ~= nil then
    local message = textutils.unserialise(getResponse("https://raw.githubusercontent.com/neverclear86/cpt/master/error.lon"))
    print(message[errtbl.code])
  else
    print(err)
  end
end


local function showHelp()
  print("add")
  print("install")
  print("update")
  print("upgrade")
end



local function main(args)
  if args[1] == "-h" then
    showHelp()
    return
  end
  local success, err = pcall(function()
    if not ping() then
      error({code = 1001})
    end
    local switch = {
      add = add,
      a = add,
      install = install,
      i = install,
      update = update,
      ud = update,
      upgrade = upgrade,
      ug = upgrade,
      list = list,
      ls = list,
    }
    if switch[args[1]] == nil then
      print("Please type \"cpt-get -h\" to read help.")
      return
    end
    switch[args[1]](args[2])
  end, args)
  if not success then
    showError(err)
  end
end

main({...})
