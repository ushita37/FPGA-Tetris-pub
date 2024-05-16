# FPGAを用いたゲームの作成
## プロジェクトの概要
FPGAボードからVGAの信号を出力して、ディスプレイにテトリス風のゲームの画面を映す

FPGAボードのボタンでブロックを動かし、テトリス風のゲームを遊ぶ

## GitHub上のソースコードについて
- `video/VGAtiming-do-well.v`: VGA信号を出力するためのファイル
- `video/color-hi-res.v`: 画面の解像度を設定するためのファイル(VGAは640x480ピクセルだが、今回は縦16ピクセルx横16ピクセルを1マスにまとめて、縦40マスx横30マスを出力している。)
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

## コーデの解説(出力される画面をどのようにセットしているか)
`color-hi-res.v`では、実物のディスプレイにブロックを表示する方法を示している。