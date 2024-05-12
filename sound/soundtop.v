module soundtop(
		input CLK100M,     // 100MHz clock input
		input [4:0] BTN,   // Button (BTN4=BTNC,BTN3=BTND,BTN2=BTNR,BTN1=BTNL,BTN0=BTNU)
		input [3:0] SW,    // Switch (SW3,SW2,SW1,SW0)
		output [3:0] LED,  // LED    (LD3,LD2,LD1,LD0)
		output SPEAKER0, output SPEAKER1 // Speaker
		);	    
   // make 25MHz clock from 100MHz clock
   reg [1:0] 	       count=0;
   wire 	       CLK25M;
   always @(posedge CLK100M) begin
      count <= count + 1;
   end
   assign CLK25M = count[1];
	
   // LED
   assign LED = SW;

   // generate sound
   sound sound(CLK25M, SW[0], BTN, SPEAKER0, SPEAKER1);
endmodule
