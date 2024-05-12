# FPGAを用いたゲームの作成
## プロジェクトの概要
FPGAボードからVGAの信号を出力して、ディスプレイにテトリス風のゲームの画面を映す

FPGAボードのボタンでブロックを動かし、テトリス風のゲームを遊ぶ

## 必要となるソースコードについて

## GitHub上のソースコードについて
- `video/VGAtiming-do-well.v`: VGA信号を出力するためのファイル
- `color-hi-res.v: 画面の解像度を設定するためのファイル(VGAは640x480ピクセルだが、今回は縦40ピクセルx横30ピクセルを出力するようにしている。)
- `video.v`:FPGAボードで用いるスイッチ、ボタンを指定するファイル

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
