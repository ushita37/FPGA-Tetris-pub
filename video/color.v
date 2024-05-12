module color(
	     input Clk, 
	     input Reset, 
	     input [9:0] Hcount, 
	     input [8:0] Vcount, 
	     output [7:0] Red, 
	     output [7:0] Green, 
	     output [7:0] Blue,
	     input Btnl,
	     input Btnr
	     );
   assign Red   = Hcount[7:0];
   assign Green = 8'b11111111;
   assign Blue  = Vcount[7:0];
endmodule
