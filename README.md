# Inline Scene Mask_S AviUtl スクリプト

[Inline Scene S](https://github.com/sigma-axis/aviutl_script_InlineScene_S) で保存したキャッシュ画像で現在オブジェクトをマスクするスクリプト．

フィルタ効果のマスクで，マスク用画像としてシーンを選択した場合の「inline scene 版」です（一部機能は異なります）．

また，「上のオブジェクトでクリッピング」機能の柔軟な代替にもなります．

[ダウンロードはこちら．](https://github.com/sigma-axis/aviutl_script_ILS_Mask_S/releases) \[紹介動画準備中...\]

![マスクのデモ](https://github.com/user-attachments/assets/1c577f10-79b1-4253-87c4-dfb7d2766f1c)

## 動作要件

- AviUtl 1.10 (1.00 など他バージョンでは動作不可)

  http://spring-fragrance.mints.ne.jp/aviutl

- 拡張編集 0.92

  - 0.93rc1 など他バージョンでは動作不可．

- patch.aul (謎さうなフォーク版)

  https://github.com/nazonoSAUNA/patch.aul

- [LuaJIT](https://luajit.org/)

  バイナリのダウンロードは[こちら](https://github.com/Per-Terra/LuaJIT-Auto-Builds/releases)からできます．

  - 拡張編集 0.93rc1 同梱の `lua51jit.dll` は***バージョンが古く既知のバグもあるため非推奨***です．
  - AviUtl のフォルダにある `lua51.dll` と置き換えてください．

- Inline Scene S の導入

  https://github.com/sigma-axis/aviutl_script_InlineScene_S

## 導入方法

以下のフォルダに `@ILS_Mask_S.anm` と `ILS_Mask_S.lua` の 2 つのファイルをコピーしてください．

- `InlineScene_S.lua` のあるフォルダ

  [Inline Scene S](https://github.com/sigma-axis/aviutl_script_InlineScene_S) の導入先のフォルダです．

> [!TIP]
> 正確には「`require "InlineScene_S` の構文で `InlineScene_S.lua` が見つかること」が条件なので，例えば `InlineScene_S.lua` が `script` フォルダに配置されているなどの場合は，`script` フォルダ内の任意の名前のフォルダでも可能です．
>
> `patch.aul.json` で `"switch"` 以下の `"lua.path"` を `true` にすることで，`module` フォルダに `InlineScene_S.lua` を配置する方法も可能です（ただし一部 rikky_module.dll を使うスクリプトなどが動かなくなる報告もあります）．
>
> 詳しくは [Lua 5.1 の `require` の仕様](https://www.lua.org/manual/5.1/manual.html#5.3)と拡張編集のスクリプトの仕様を参照してください．

## 使い方

[`Inline Sceneここまで`](https://github.com/sigma-axis/aviutl_script_InlineScene_S?tab=readme-ov-file#inline-scene%E3%81%93%E3%81%93%E3%81%BE%E3%81%A7) や [`Inline Scene単品保存`](https://github.com/sigma-axis/aviutl_script_InlineScene_S?tab=readme-ov-file#inline-scene%E5%8D%98%E5%93%81%E4%BF%9D%E5%AD%98) などでキャッシュが保存されている状態で，オブジェクトに [`Mask`](#mask) のアニメーション効果を適用すると，現在オブジェクトがキャッシュ画像でマスクされます．

マスクの位置や回転角，サイズを変更・調整する場合は，[`Mask設定(拡大率指定)`](#mask設定拡大率指定) や [`Mask設定(サイズ指定)`](#mask設定サイズ指定) を `Mask` の直前に適用してください．これらがない場合は，マスク元画像が現在オブジェクトのサイズに合わせて拡縮します (拡張編集標準の「マスク」フィルタ効果で「元のサイズに合わせる」に相当する動作).

![設定は連続して配置](https://github.com/user-attachments/assets/8e266640-f0b4-412b-906e-d2ee3bb25cd4)

各アニメーション効果の「設定」にある `PI` は parameter injection です．初期値は `nil`. テーブル型を指定すると `obj.check0` や `obj.track0` などの代替値として使用されます．また，任意のスクリプトコードを実行する記述領域にもなります．

```lua
_0 = {
  [0] = check0, -- boolean または number (~= 0 で true 扱い). obj.check0 の代替値．それ以外の型だと無視．
  [1] = track0, -- number 型．obj.track0 の代替値．tonumber() して nil な場合は無視．
  [2] = track1, -- obj.track1 の代替値．その他は [1] と同様．
  [3] = track2, -- obj.track2 の代替値．その他は [1] と同様．
  [4] = track3, -- obj.track3 の代替値．その他は [1] と同様．
}
```

### `Mask`

マスクを適用するアニメーション効果です．

この直前に [`Mask設定(拡大率指定)`](#mask設定拡大率指定) や [`Mask設定(サイズ指定)`](#mask設定サイズ指定) がかけられていた場合，そこで指定されたサイズやぼかし等の設定も適用されます．これらがない場合は，マスク元画像が現在オブジェクトのサイズに合わせて拡縮します (拡張編集標準の「マスク」フィルタ効果で「元のサイズに合わせる」に相当する動作).

#### 設定値
1.  `強さ`

    マスクの強さを % 単位で指定します．マスクをかけた場合とかけなかった場合のα値を線形補間します．最小値は `0`, 最大値は `200`, 初期値は `100`.

1.  `ぼかし`

    マスクのぼかし量をピクセル単位で指定します．最小値は `0`, 最大値は `500`, 初期値は `0`.

1.  `マスクを反転`

    マスクのα値を反転するかどうか指定します．初期値は OFF.

1.  `ILシーン名`

    マスク元のキャッシュ画像を表す，`Inline Scene単品保存` などで指定した `ILシーン名` を指定します．初期値は `scn1`.

1.  `現在フレーム`

    ON の場合，inline scene がそのフレーム描画中に保存されたものでないときにはマスク処理を行いません．初期値は OFF.

1.  `最小α値`

    マスク処理でのα値の計算方法を，通常の `乗算` に代わって，小さいほうのα値を適用する方法に切り替えます．初期値は OFF.

    |元画像|`乗算` (通常)|`最小α値`|
    |:---:|:---:|:---:|
    |![元画像とマスク画像](https://github.com/user-attachments/assets/199e48e2-c274-4a08-a398-8bc5bfedbf07)|![乗算マスク](https://github.com/user-attachments/assets/8227741a-016b-4331-96f5-3db1de93efb0)|![最小値マスク](https://github.com/user-attachments/assets/bb02e47a-2a17-4463-82ae-c3d60f85fc85)|
    ||計算式: $(\alpha_1,\alpha_2)\mapsto\alpha_1\alpha_2$|計算式: $(\alpha_1,\alpha_2)\mapsto\min\{\alpha_1,\alpha_2\}$|

### `Mask設定(拡大率指定)`

[`Mask`](#mask) の処理に対して拡大率やぼかしを指定します．`Mask` の直前に配置してください．

#### 設定値
1.  `X` / `Y`

    マスクの位置を指定します．アンカーをマウス移動でも調整可能です．最小値は `-2000`, 最大値は `2000`, 初期値は原点 $(0, 0)$.

1.  `回転`

    マスク画像の回転角度を指定します．度数法で時計回りに正．回転中心は，キャッシュ画像保存時の回転中心です．最小値は `-720`, 最大値は `720`, 初期値は `0`.

1.  `拡大率`

    マスク画像の拡大率を % 単位で指定します．拡大縮小の中心は，キャッシュ画像保存時の回転中心です．最小値は `0`, 最大値は `1600`, 初期値は `100`.

### `Mask設定(サイズ指定)`

[`Mask`](#mask) の処理に対してサイズをピクセル単位で指定したり，ぼかしを指定します．`Mask` の直前に配置してください．

#### 設定値
1.  `X` / `Y`

    マスクの位置を指定します．アンカーをマウス移動でも調整可能です．最小値は `-2000`, 最大値は `2000`, 初期値は原点 $(0, 0)$.

1.  `回転`

    マスク画像の回転角度を指定します．度数法で時計回りに正．回転中心は，キャッシュ画像保存時の回転中心です．最小値は `-720`, 最大値は `720`, 初期値は `0`.

1.  `サイズ`

    マスク画像のサイズをピクセル単位で指定します．拡大縮小の中心は，キャッシュ画像保存時の回転中心です．最小値は `0`, 最大値は `4000`, 初期値は `200`.

## TIPS

1.  [`Mask設定(拡大率指定)`](#mask設定拡大率指定) と [`Mask設定(サイズ指定)`](#mask設定サイズ指定) を同時に指定した場合は，最後に指定したものの効果が優先されます．また，[`Mask`](#mask) と別々のオブジェクトに配置されていた場合 (例: オブジェクトに `Mask設定(拡大率指定)`, グループ制御に `Mask`) は `Mask設定(拡大率指定)` と `Mask設定(サイズ指定)` は機能しません．

1.  [`Mask`](#mask) の `強さ` は `100` を超えて指定できます．その場合は，半透明のピクセルのα値がさらに下がります．

1.  テキストエディタで `@ILS_Mask_S.anm`, `ILS_Mask_S.lua` を開くと冒頭付近にファイルバージョンが付記されています．

    ```lua
    --
    -- VERSION: v1.00
    --
    ```

    ファイル間でバージョンが異なる場合，更新漏れの可能性があるためご確認ください．


## 改版履歴

- **v1.00** (2024-12-26)

  - 初版．


## ライセンス

このプログラムの利用・改変・再頒布等に関しては MIT ライセンスに従うものとします．

---

The MIT License (MIT)

Copyright (C) 2024 sigma-axis

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

https://mit-license.org/


#  連絡・バグ報告

- GitHub: https://github.com/sigma-axis
- Twitter: https://x.com/sigma_axis
- nicovideo: https://www.nicovideo.jp/user/51492481
- Misskey.io: https://misskey.io/@sigma_axis
- Bluesky: https://bsky.app/profile/sigma-axis.bsky.social
