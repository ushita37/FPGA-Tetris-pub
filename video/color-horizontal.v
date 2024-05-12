// 枠線の定義(1行ごと)
`define LINE0 16'b00000010_00000001		// 左右の線のみ
`define LINE1 16'b00000011_11111111		// 下枠
`define LINE2 16'b00000000_00000000     // 上枠はなし?

// 27行目まではチャタリングのコード
module chattering(clk,reset,in,out);
// 必要があればパラメタNを変えられる
  parameter N=3;	// Nはボタンの数

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


module color(
	input Clk, 
	input Reset, 
	input [9:0] Hcount,		// [9:0]はレンジ、[MSB:LSB]
	input [8:0] Vcount, 
	output [7:0] Red, 
	output [7:0] Green, 
	output [7:0] Blue,
	input Btnl_in,	// 左ボタン
	input Btnr_in,	// 右ボタン
	input Btnd_in	// 下ボタン
);

	wire [127:0] map, block;
	reg [127:0] back = {`LINE1,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE2};	// 背景のセット;
	reg [3:0] x	= 5;	// 横の初期位置は5
	reg [2:0] y = 1;	// 縦の初期位置は1
	wire [6:0]  pos;	// 上3ビットがy座標、下4ビットがx座標
	reg	[0:0]	Btnlb4 = 0;	// 1クロック前のボタンの状態?
	reg [0:0]	Btnrb4 = 0;
	reg [0:0]	Btndb4 = 0;
	reg [26:0]	counter = 0;	// 0と1を繰り返すclkで、1が何回でたか数える
	// assign文は常に実行される?
	assign block = (1<<x)<<y*16; 
//	assign map = back | block;	// backとblockの論理和?
	assign map = {back[127:0] | block[127:0]};	// backとblockの論理和
	// assign map = {16'b1111111111111111 >> (16- score%10), back[127:16] | block[127:16]};
	// scoreを1番上の行の10マスで表示したい
	assign pos = {Vcount[8:6], Hcount[9:6]};
//	assign {Red,Green,Blue} = map[pos]==1 ? {255,255,255}:{0,0,0};
	// assign Red   = map[pos]==0 ? 0:( ((16'b1111111111111111 >> (16- (score>9)?0:score))>>pos[3:0])!=0 && pos[6:4] == 7 )? 0:255;
	assign Red   = map[pos]==0 ? 0:( ((16'b1111111111111111 >> (16-  score))>>pos[3:0])!=0 && pos[6:4] == 7 )? 0:255;
	// (score>9)?0:score は10で割った剰余を求めてるのと同じ
	// assign Green = map[pos]==0 ? 0:( ((16'b1111111111111111 >> (16- (score>19 && score<10)?0:score))>>pos[3:0])!=0 && pos[6:4] == 7 )? 0:255;
	assign Green = map[pos]==1 ? 255:0;
	assign Blue  = map[pos]==1 ? 255:0;
	// assign Blue = map[pos]==0 ? 0:( ((16'b1111111111111111 >> (16- (score>10)?score-10:0 ))>>pos[3:0])!=0 && pos[6:4] == 7 )? 0:255;

	chattering chat1(Clk, Reset,{Btnl_in,Btnr_in,Btnd_in},{Btnl,Btnr,Btnd});


	integer i, j, k;	// ループカウンタ
	parameter WIDTH = 8;
	parameter DEPTH = 6;
	reg [9:0] score = 0;	// 消した行数が得点になる


	// initial begin
		
	// end
	always @(posedge Clk) begin
		if(Reset == 1) begin
			x <= 5;
			y <= 1;
			score <= 0;
			back <= {`LINE1,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE2};	// 背景のセット
		end else begin 
			
			// Btnlb4は、1クロック前のボタンの状態
			// Btnlは、現在のボタンの状態
			if(Btnlb4 == 0 && Btnl == 1) begin	// 左ボタン
				if ((back & (1 << x-1 + y*16)) == 0) begin	// 壁にのめりこまない為の飽和処理、演算子&の順位は==より下だからかっこ付き
					x <= x-1;
				end
				Btnlb4 <= 1;
			end	else if (Btnlb4 == 1 && Btnl == 0) begin	// 押されていない時
				Btnlb4 <= 0;		
			end else if (Btnrb4 == 0 && Btnr == 1) begin	// 右ボタン
				if ((back & (1 << x+1 + y*16)) == 0) begin
					x <= x+1;
				end
				Btnrb4 <= 1;
			end else if (Btnrb4 == 1 && Btnr == 0) begin
				Btnrb4 <= 0; 
			end else if(Btndb4 == 0 && Btnd == 1) begin	// 下ボタン
				if ((back & (1 << x + (y+1)*16)) == 0) begin	// 現在のブロックの位置より下に、ブロックがなかった場合
					y <= y+1;
				end
				Btndb4 <= 1;
			end	else if (Btndb4 == 1 && Btnd == 0) begin	// 押されていない時
				Btndb4 <= 0;
			end else begin
				// null
			end		


			if(Clk == 1) begin// 時間経過でブロックが落ちる
				counter <= counter + 1;
				if(counter == 27'b010_00000000_00000000_00000000) begin
					counter <= 27'b000_00000000_00000000_00000000;
					if ((back & (1 << x + (y+1)*16)) == 0) begin	// 現在のブロックの位置より下に、ブロックがなかった場合
						y <= y+1;
					// end else if ((back & (1 << 5 + 1*16)) == 1) begin	// ブロックが出てくる(5, 1)にすでにブロックがある場合：ゲームオーバー
					// 	x <= 5;
					// 	y <= 1;
					// 	score <= 0;
					// 	back <= {`LINE1,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE2};	// 背景のセット
					end else begin
						back <= back | (1 << (x + y*16));	// 背景にブロックを埋め込む(ブロックを積みあげる)
						if(score < 9) begin
							// 新しいブロックがスポーンする
							x <= 5;
							y <= 1;
						end
					end
				end else if (counter == 27'b000_00000000_00000000_00000001) begin	// ブロックを積み上げる処理を行った1カウント後に、1行判定してそろってればブロック消す

					for(i = 1; i < (DEPTH+1); i = i+1) begin
						if(back[1+i*16] == 1 && back[2+i*16] == 1 && back[3+i*16] == 1 && back[4+i*16] == 1 && back[5+i*16] == 1 && back[6+i*16] == 1 && back[7+i*16] == 1 && back[8+i*16] == 1) begin	// 一行全部そろったら...
						if(score < 10) begin
							score = score+1;	// 10点まで、1行消すごとに1点を加算する
						end
							for(k = i-1; k > 0; k = k-1) begin	// 下の行から順に上書きしていく
								for(j = 1; j < WIDTH+1; j = j+1) begin
									back[j+(k+1)*16] = back[j+k*16];	// 上の行を下の行にコピー
								end
							end
							for(j = 1; j < (WIDTH+1); j = j+1) begin
									back[j+1*16] = 0;	// 一番上の行は空白にする
							end
						end

					end

				end
			end

		end		
	end

endmodule
