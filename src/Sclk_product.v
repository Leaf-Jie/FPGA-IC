module clkproduce(
	input gclk,
	input rst,

	output clk_1khz,
	output clk_10hz
);
   
	reg [40:0] cn10 = 0;
	reg [40:0] cn1k = 0;
	reg clk1k =0;
	reg clk10 =0;
	
	assign clk_1khz = clk1k;
	assign clk_10hz = clk10;
	
	always @(posedge gclk)
	   begin
		   if (cn1k>25000) begin
			   cn1k <= 0;
				clk1k <= !clk1k;
				end
			else begin
			   cn1k <= cn1k+1;
				end
			if (cn10 > 2500000) begin 
				cn10 <= 0;
				clk10 <= !clk10;
				end
			else begin
			   cn10 <= cn10+1;
				end
		end
	
endmodule
	