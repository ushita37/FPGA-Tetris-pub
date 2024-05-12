// 枠線の定義(1行ごと)
`define LINE0 16'b00000010_00000000
`define LINE1 16'b00000011_11111111


module color(
	input Clk, 
	input Reset, 
	input [9:0] Hcount,		// [9:0]はレンジ、[MSB:LSB]
	input [8:0] Vcount, 
	output [7:0] Red, 
	output [7:0] Green, 
	output [7:0] Blue,
	input Btnl,
	input Btnr
);

	reg [127:0] map;
	wire [6:0] pos;
	assign pos = {Vcount[8:6], Hcount[9:6]};
	assign Red   = map[pos]==1 ? 255:0;
	assign Green = map[pos]==1 ? 255:0;
	assign Blue  = map[pos]==1 ? 255:0;


	always @(posedge Clk) begin
		if(Btnl == 1) begin
			map <= {`LINE1,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE1} | (1<<18);
		end	else if (Btnr==1) begin
			map <= {`LINE1,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE1} | (1<<34);
		end else begin
			map <= {`LINE1,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE0,`LINE1} | (1<<50); // 中かっこで16bitの列を8個くくって、128bitの列をつくる
		end
	end
endmodule