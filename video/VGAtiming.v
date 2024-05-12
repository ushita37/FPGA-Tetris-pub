// horizontal constants
`define H_PW      96 // sync
`define H_FP      16 // front porch
`define H_DISPW   640 // active video
`define H_BP      48 // back porch
`define H_POL     0 // negative polarity
// vertical constants
`define V_PW      2 // sync
`define V_FP      10 // front porch, fixed from 33
`define V_DISPW   480 // active video
`define V_BP      33 // back porch, fixed from 10
`define V_POL     0 // negative polarity

module VGAtiming(
  input PCLK_I,
  input RST_I,
  output BLANK_O,
  output HSYNC_O,
  output VSYNC_O,
  output [10:0] HCNT_O,
  output [10:0] VCNT_O
);
  reg [10:0] HCnt;  // horizontal counter
  reg [10:0] VCnt;  // vertical counter
  reg hsync, vsync; // horizontal/vertical sync
  reg blank; // data enable

  always @(posedge PCLK_I) begin
    // start editing here
    if (RST_I == 1) begin
      HCnt <= `H_DISPW + `H_FP + `H_PW + `H_BP - 1;
      VCnt <= `V_DISPW + `V_FP + `V_PW + `V_BP - 1;
      blank <= 0;
      hsync <= 1;
      vsync <= 1;
    end else begin
      // pixel/line counters and video data enable
      if (HCnt == `H_DISPW + `H_FP + `H_PW + `H_BP - 1) begin
        HCnt <= 0;          // reset hcnt when reach max
        if (VCnt == `V_DISPW + `V_BP + `V_PW + `V_FP - 1) begin 
          VCnt <= 0;        // reset vcnt when reach max
        end else begin
          VCnt <= VCnt + 1; // increment vcnt
        end
      end else begin
        HCnt <= HCnt + 1;   // increment hcnt
      end

      // setting blank 
      if (VCnt < `V_DISPW -1) begin // VCnt 0~4
        if (HCnt == `H_DISPW + `H_FP + `H_PW + `H_BP - 1) begin   // hcnt is max just before 0
          blank <= 1;
        end else if (HCnt == `H_DISPW -1) begin   // 1 clk before
          blank <= 0;
        end
      end else if (VCnt == `V_DISPW -1) begin
        if (HCnt == `H_DISPW - 1) begin   // hcnt is max just before 0
          blank <= 0;
        end
      end else if (VCnt == `V_DISPW + `V_BP + `V_PW + `V_FP - 1) begin// vcnt is max just before 0
        if (HCnt == `H_DISPW + `H_FP + `H_PW + `H_BP - 1) begin   // hcnt is max just before 0
          blank <= 1;
        end
      end

      // setting hsync & vsync
      if (HCnt == 0) begin
        hsync <= 1;
      end else if (HCnt == `H_DISPW + `H_FP -1) begin   // 1 clk before
        hsync <= 0;
        if (VCnt == `V_DISPW + `V_FP) begin  // synchronize timing of vsync with edge of hsync
          vsync <= 0;
        end else if (VCnt == `V_DISPW + `V_FP + `V_PW) begin
          vsync <= 1;
        end
      end else if (HCnt == `H_DISPW + `H_FP + `H_PW -1) begin   // 1clk before
        hsync <= 1;
      end

    end
    // end editing here
  end

  assign HCNT_O = HCnt;
  assign VCNT_O = VCnt;
  assign HSYNC_O = `H_POL ? ~hsync : hsync;
  assign VSYNC_O = `V_POL ? ~vsync : vsync;
  assign BLANK_O = blank;
endmodule // VGAtiming

module clock2_25MHz(output reg clk_25MHz);
  initial clk_25MHz = 0;
  always  #20 clk_25MHz = ~clk_25MHz; // 1/(25x10^6)=40psec
endmodule

module VGAtimingSim;
  wire clk_25MHz, blank, hsync, vsync;
  wire [10:0] hcnt, vcnt;
  reg reset;
  clock2_25MHz clock2_25MHz(clk_25MHz);
  VGAtiming VGAtiming(clk_25MHz, reset, blank, hsync, vsync, hcnt, vcnt);
  initial begin
    $display("clk reset hsync vsync blank hcnt vcnt   time(ns)");
    // diff 2 lines
     $display(" null line\n null line");
    // end 2lines
    $monitor(" %b    %b     %b     %b     %b   %3d  %3d", clk_25MHz, reset, hsync, vsync, blank, hcnt, vcnt, $stime);
    reset = 0;
    #40
    @(posedge clk_25MHz) reset = 1;
    @(posedge clk_25MHz) reset = 0;
    #30000;
    $finish;
  end
endmodule // VGAtimingSim
