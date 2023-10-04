# nereid-usb-zuiki-joycard

ZUIKI X68000 Z JOYCARD を X680x0 実機 + Nereid USB で使う覚書

<img src='images/zpad3.jpeg'/>

---

## はじめに

この覚書は ZUIKI社より単独販売および X68000 Z PRODUCT EDITION に標準装備されている X68000 Z JOYCARD (BLACK) を Nereid USB を使って X680x0 実機に繋ぐための覚書です。

---

## ゲームソフトでの利用

元々 IOCS _JOYGET コールを使ってジョイスティックの読み取りを行なっているソフトであれば、そのまま利用できます。(例：Super Moon Figher X)

<img src='images/zpad2.jpeg'/>


IOCSを使わず直接8255のレジスタ($e9a001,$e9a003)を読んでいるソフトの場合は敢えてIOCS _JOYGETを使うようにパッチを当てる必要があります。IOCSコールが返す値は8255ポートA,Bの内容そのものですので、それほど難しいパッチではありません。(例：女帝戦記)

<img src='images/zpad1.jpeg'/>

---

## 更新履歴

2023.10.04 ... 初版