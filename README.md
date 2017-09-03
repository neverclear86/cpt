# cpt
Computers Package Tool  

## About
Minecraftの *ComputerCraft* 用のプログラムパッケージ管理
### 主な機能
- プログラムのダウンロード・アップデートをDebianのaptめいて簡易化
- パッケージファイルを用意することでプログラムをcpt-getで管理できる

## Install
`pastebin run 06KWKAyr`

## Use

### パッケージの追加
パッケージファイルを追加する
#### `cpt add [url]`
- urlはファイル内容が生で取得できるもの
- Pastebinのコードでも可
- Alias : `add` -> `a`

### プログラム名一覧表示
#### `cpt list`
- Alias : `list` -> `ls`

### プログラムをインストール  
パッケージ内のプログラムをインストールする
#### `cpt install [programname]`
- listで取得できたプログラム名を入力
- Alias : `install` -> `i`

### パッケージのアップデート  
パッケージを最新の状態へアップデート
#### `cpt update`
- Alias : `update` -> `ud`

### プログラムのアップグレード
パッケージとバージョンの差異があるプログラムを更新
#### `cpt upgrade`
- 先にupdateを実行しないと意味が無いぞ！
- Alias : `upgrade` -> `ug`


## Package
cptで管理するためのパッケージファイル
```Lua
{
  author = "author",
  programs = {
    {
      name = "programname1",
      url = "programurl",
      version = "1.0.0",
      path = "/installpath/",
    },
    {
      name = "programname2",
      url = "programurl",
      version = "1.0.0",
    },
  }
}
```
- author : 作者名
- programs : プログラムのリスト
  - name : プログラム名
  - url : プログラムファイルのURL(Pastebinのコード可)
  - version : プログラムのバージョン
  - path : プログラムのインストール先パス(省略時ルート直下)

※jsonっぽいからlonファイルって呼んでる
