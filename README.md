# FPGAを用いたゲームの作成
## プロジェクトの概要
FPGAボードからVGAの信号を出力して、ディスプレイにゲーム画面を映す

FPGAボードのボタンでブロックを動かし、テトリス風のゲームを遊ぶ

## GitHub上のソースコードについて
- `video/VGAtiming-do-well.v`: VGA信号を出力するためのファイル
- `video/color-hi-res.v`: 画面の解像度を設定するためのファイル(VGAは640x480ピクセルだが、今回は縦16ピクセルx横16ピクセルを1マスにまとめて、40マスx30マスを出力している。)
- `video/video.v`: FPGAボードで用いるスイッチ、ボタンを指定するファイル
- `video/basys3.xdc` : FPGA(DIGILENT BASYS3 ARTIX-7)の制約ファイル
- `tetris-hi-res/tetris-hi-res.xpr` : Vivadoプロジェクトのファイル

## Vivadoでプロジェクトを作成するときのSourcesについて
- Design Sources
	- video `video.v`
		- VGAtiming : VGAtiming `VGAtiming-do-well.v`
		- color `color-hi-res.v`
			- chat1 : chattering `color-hi-res.v`
	- VGAtimingSim `VGAtiming-do-well.v`
		- clock2_25MHz : clock2_25MHz `color-hi-res.v`
		- VGAtiming : VGAtiming `VGAtiming-do-well.v`
	- clock2_25MHz `VGAtiming-do-well.v`
- Constraints
	- constrs_1
		`basys3.xdc`
- Simulation Sources
	- sim_1
		- VGAtimingSim `VGAtiming-do-well.v` 
			- clock2_25MHz : clock2_25MHz `color-hi-res.v`
			- VGAtiming : VGAtiming `VGAtiming-do-well.v`
	- video `video.v`
    	- VGAtiming : VGAtiming `VGAtiming-do-well.v`
    	- color: color `color-hi-res.v`
        	- chat1 : chattering `color-hi-res.v`
  	- clock2_25MHz `VGAtiming-do-well.v`
- Utility Sources
    - utils_1
        - Design Checkpoint
			`VGAtimingSim.dcp`


## 使用した機材など

![DIGILENT BASYS3 ARTIX-7](https://raw.githubusercontent.com/ushita37/FPGA-Tetris-pub/main/fpga.jpg)


## ゲームの遊び方
ゲームを実際に動かした時の様子は[こちら](https://drive.google.com/file/d/1AaBwkMbuqvsR4GAyNL1H4vhcQYWOdarv/view?usp=sharing)

`SW14`(16個並んでいるスイッチのうち左から2つ目)を上に倒すと、画面が初期状態になる。その後、スイッチを下に倒してゲームを開始する。

ゲームを開始すると、時間経過でブロックが落ちてくる。落下中のブロックはFPGAの左(`BTNL`)、右(`BTNR`)、下(`BTND`)のボタンを押して移動できる。上(`BTNU`)を押すと、落下中のブロックが現在いる列の一番下まで落ちる。

ブロックは1つのマス(ピクセル)を2つ縦に繋げた長方形になっている。このブロックが一番下まで落下すると、次のブロックが現れる。ブロックをボタン操作で動かして落とすことを繰り返し、1行全てがブロックで埋まると、その行が消去される。消去された行より上にあるブロックは、自動的に一つずつ下に移動する。

##  コードの解説(出力される画面をどのようにセットしているか)
`color-hi-res.v`では、実物のディスプレイにブロックを表示する方法を示している。

まず、解像度とブロックのサイズ、配置について説明する。
VGAの解像度は横640ピクセルx縦480ピクセルであるが、この1ピクセルをゲームの1ブロックとして使うと、ブロックが小さすぎて見づらくなる。そのため、16x16ピクセル(256ピクセル)をまとめて１マスとして扱う。すると、画面に表示されるのは40マスx30マスの画面となる。

さらに、この画面を全てゲームで使う必要はないので、中央の一部分のみをゲームで使うようにしている。具体的な配置は以下の図に示した。
![FPGA resolution](https://raw.githubusercontent.com/ushita37/FPGA-Tetris-pub/main/fpga-resolution.png)


次に、ブロックの位置(アドレス)管理について説明する。`color-hi-res.v`では、2047ビットの`reg back`、`wire block`、`wire map`を使用している。`back`は動かずに画面に表示される部分、すなわち上の図の斜線部(ブロックを積み上げることができるスペースの端を示す「枠」)を表している。ブロックが一番下まで落ちて、これ以上動かなくなった時はそのブロックのアドレスについて、`back`のビットを1にする。(実際のゲーム画面では、ビットが0だと黒で、ビットが1だと白で表示される)

`block`は現在落下中のブロックを表している。FPGAボードの左ボタンを押すと現在のアドレスより1小さい位置のビットが1になり、右ボタンを押すと現在のアドレスより1大きい位置のビットが1になる、といった動作をする。

`map`は、`back`と`block`の論理和である。ゲーム画面が`back`の層と`block`の層の2層からなるとすれば、`map`はその2つを重ねたものである。

なお、`back`、`block`、`map`いずれもアドレスは2047~0の範囲であるが、実際のディスプレイで出力できるのは40マスx30マス分しかない。実際に使われるのは2048あるアドレスのうち1200個分だけである。以下の図にアドレスと表示領域の対応を示す。
![FPGA address](https://raw.githubusercontent.com/ushita37/FPGA-Tetris-pub/main/fpga-address.png)