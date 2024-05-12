// 枠線の定義(1行ごと)
`define LINE_hr0 64'b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000	// 高解像度版の空白(何も表示しない)
`define LINE_hr1 64'b00000000_00000000_00000000_00000000_00000011_11111111_11000000_00000000	// 高解像度版の下枠
`define LINE_hr2 64'b00000000_00000000_00000000_00000000_00000010_00000000_01000000_00000000	// 高解像度版の左右の枠


// 27行目まではチャタリングのコード
module chattering(clk,reset,in,out);
// 必要があればパラメタNを変えられる
  parameter N=5;	// Nはボタンの数

  input clk,reset;
  input [N-1:0]in;
  output [N-1:0]out;
  reg [N-1:0]out,buffer;
  reg [27:0] count;

  always @(posedge clk or negedge reset)
    if(!reset) count <= 0;
    else count <= count + 1;

  always @(posedge clk)
    if(count==0)begin
        buffer <= in;
        out <= buffer;
    end

endmodule

module clock2_25MHz(output reg clk_25MHz);
  initial clk_25MHz = 0;
  always  #20 clk_25MHz = ~clk_25MHz; // 1/(25x10^6)=40psec
endmodule

// in video.v
// L.5 Button (BTN4=BTNC,BTN3=BTND,BTN2=BTNR,BTN1=BTNL,BTN0=BTNU)
// L.32 color color(CLK25M,SW[14],VtcHCnt[9:0],VtcVCnt[8:0],Red,Green,Blue,BTN[0],BTN[1],BTN[2],BTN[3],BTN[4]);

module color(
	input Clk, 
	input Reset, 
	input [9:0] Hcount,		// [9:0]はレンジ、[MSB:LSB]
	input [8:0] Vcount, 
	output [7:0] Red, 
	output [7:0] Green, 
	output [7:0] Blue,
	input Btnu_in,	// 上ボタン
	input Btnl_in,	// 左ボタン
	input Btnr_in,	// 右ボタン
	input Btnd_in,	// 下ボタン
	input Btnc_in	// 中央ボタン
);

	integer i, j, k;	// ループカウンタ
	

	parameter WIDTH = 10;
	parameter DEPTH = 20;
	parameter H_BLOCKS = 64;
	parameter V_BLOCKS = 32;
	parameter UPPER_LIMIT = 9;	// ゲームで使える領域の上側限界の座標
	parameter LEFT_LIMIT = 14 + 1;	// ゲームで使える領域の左側限界の座標
	parameter DOWN_LIMIT = 28;	// ゲームで使える領域の下側限界の座標
	parameter X_INIT = 20;
	parameter Y_INIT = 8;
	
    // 1ブロックを16×16ピクセルにする
	wire [2047:0] map, block;   // 128ビットの16倍
	reg [2047:0] back = {/* 下の表示範囲外 */ `LINE_hr0, `LINE_hr0, /*下の枠*/ `LINE_hr1, /* 左右の枠 */ `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, /* 上の空白 */ `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0};		// 背景のセット
	reg [5:0] x	= X_INIT;	// 横の初期位置は20, 0 <= x < 64, 実際に使うのは 0 <= x < 40
	reg [4:0] y = Y_INIT;	// 縦の初期位置は3, 0 <= y < 32, 実際に使うのは 0 <= x < 30
	reg [5:0] x2 = X_INIT;
	reg [4:0] y2 = Y_INIT-1;


	wire [10:0]  pos;	// 上5ビットがy座標、下6ビットがx座標

	reg [0:0]	Btnu_before = 0;	// 1クロック前のボタンの状態?
	reg	[0:0]	Btnl_before = 0;
	reg [0:0]	Btnr_before = 0;
	reg [0:0]	Btnd_before = 0;
	reg [0:0]	Btnc_before = 0;
	reg [0:0]	Btnu_flag = 0;

	reg  [4:0]	counter_shift = 25;
	reg [31:0]	counter = 0;	// 0と1を繰り返すclkで、1が何回でたか数える
	// assign文は常に実行される?
	assign block = ( (1<<x)<<y*H_BLOCKS | (1<<x2)<<y2*H_BLOCKS ); 
//	assign map = back | block;	// backとblockの論理和?
	assign map = {back[2047:0] | block[2047:0]};	// backとblockの論理和
	// scoreを1番上の行の10マスで表示したい
	assign pos = {Vcount[8:4], Hcount[9:4]};
	assign {Red,Green,Blue} = map[pos]==1 ? {8'd255,8'd255,8'd255}:{0,0,0};

	chattering chat1(Clk, Reset,{Btnu_in,Btnl_in,Btnr_in,Btnd_in,Btnc_in},{Btnu,Btnl,Btnr,Btnd,Btnc});

	reg [9:0] score = 0;	// 消した行数が得点になる


	// initial begin
		
	// end
	always @(posedge Clk) begin
		// x2 <= x;
		// y2 <= y-1;
		if(Reset == 1) begin
			x <= X_INIT;
			y <= Y_INIT;
			x2 <= X_INIT;
			y2 <= Y_INIT-1; // y2はyの1マス上
			score <= 0;
			back <= {/* 下の表示範囲外 */ `LINE_hr0, `LINE_hr0, /*下の枠*/ `LINE_hr1, /* 左右の枠 */ `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, `LINE_hr2, /* 上の空白 */ `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0, `LINE_hr0};		// 背景のセット
		end else begin 
			// Btnl_beforeは、1クロック前のボタンの状態
			// Btnlは、現在のボタンの状態
			if (Btnu_flag == 0 && Btnu == 1) begin	// 上ボタン
				counter_shift <= 15;	// ブロックが落ちる速度を爆速にすることで、疑似的にすぐ下の積みあがるようにする
				back[0] <= 1;	// デバッグ用、落ちる速度が速くなっているときは左上にマークを出す
			end else if (Btnu_flag == 1 && Btnu == 0)begin	// 押されていないとき、かつブロックを下まで落とした後
				Btnu_flag <= 0;
			end else if(Btnl_before == 0 && Btnl == 1) begin	// 左ボタン
				if ((back & (1 << x-1 + y*H_BLOCKS)) == 0) begin	// 壁にのめりこまない為の飽和処理、演算子&の順位は==より下だからかっこ付き
					x <= x-1;
					x2 <= x-1;
				end
				Btnl_before <= 1;
			end	else if (Btnl_before == 1 && Btnl == 0) begin	// 押されていない時
				Btnl_before <= 0;		
			end else if (Btnr_before == 0 && Btnr == 1) begin	// 右ボタン
				if ((back & (1 << x+1 + y*H_BLOCKS)) == 0) begin
					x <= x+1;
					x2 <= x+1;	
				end
				Btnr_before <= 1;
			end else if (Btnr_before == 1 && Btnr == 0) begin
				Btnr_before <= 0; 
			end else if(Btnd_before == 0 && Btnd == 1) begin	// 下ボタン
				if ((back & (1 << x + (y+1)*H_BLOCKS)) == 0) begin	// 現在のブロックの位置より下に、ブロックがなかった場合
					y <= y+1;
					y2 <= y2+1;
				end
				Btnd_before <= 1;
			end	else if (Btnd_before == 1 && Btnd == 0) begin	// 押されていない時
				Btnd_before <= 0;
			end else if (Btnc_before == 0 && Btnc == 1) begin	// 中央ボタン
				// 回転の処理を記述する
			end else if (Btnc_before == 1 && Btnc == 0) begin
				Btnc_before <= 0;
			end else begin
				// null
			end		


			if(Clk == 1) begin// 時間経過でブロックが落ちる
				counter <= counter + 1;
				if(((counter >> counter_shift) & 1) == 1) begin	// 
					counter <= 0;
					if ((back & (1 << x + (y+1)*H_BLOCKS)) == 0) begin	// 現在のブロックの位置より下に、ブロックがなかった場合
						y <= y+1;	// ブロックを下に落とす
						y2 <= y2+1;
					// end else if ((back & (1 << 20 + 3*H_BLOCKS)) == 1) begin	// ブロックが出てくる(20, 3)にすでにブロックがある場合:ゲームオーバー
					// 	score <= 0;
					end else begin
						back <= back | (1 << (x + y*H_BLOCKS)) | (1 << (x2 + y2*H_BLOCKS));	// 背景にブロックを埋め込む(ブロックを積みあげる)
						// back <= back | (1 << (x2 + y2*H_BLOCKS));	// 背景にブロックを埋め込む(ブロックを積みあげる)
						counter_shift <= 24;	// ブロックが落ちるスピードを初期値に戻す
						Btnu_flag <= 1;	// 落下済みのflag
						back[0] <= 0;	// デバッグ用、落ちる速度が速くなっているときは左上にマークを出す
						if(score < 9) begin
							// 新しいブロックがスポーンする
							x <= X_INIT;
							y <= Y_INIT;
							x2 <= X_INIT;
							y2 <= Y_INIT-1;
						end
					end
				end else if (counter[0] == 1) begin	// ブロックを積み上げる処理を行った1カウント後に、1行判定してそろってればブロック消す

					for(i = UPPER_LIMIT; i < (UPPER_LIMIT + DEPTH); i = i+1) begin

						if(((back >> (LEFT_LIMIT + i*H_BLOCKS)) & 10'b1111111111) == 10'b1111111111) begin // 一行全部そろったら...
						// if(score < 10) begin
						// 	score = score+1;	// 10点まで、1行消すごとに1点を加算する
						// end
							for(k = i-1; k > 0; k = k-1) begin	// 下の行から順に上書きしていく
								for(j = LEFT_LIMIT; j < LEFT_LIMIT+WIDTH; j = j+1) begin
									back[j+(k+1)*H_BLOCKS] = back[j+k*H_BLOCKS];	// 上の行を下の行にコピー
								end
							end
							for(j = LEFT_LIMIT; j < LEFT_LIMIT+WIDTH; j = j+1) begin
									back[j+UPPER_LIMIT*H_BLOCKS] = 0;	// 一番上の行は空白にする
							end
						end

					end

				end
			end

		end		
	end

endmodule
