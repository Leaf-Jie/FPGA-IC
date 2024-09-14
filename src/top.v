module top (
    input clk50m,
    input wire sendCmd,
    input miso,
    input rst,

    output dclk,
    output mosi,
    output testIo
);

wire clk_pll;
wire clkd_pll;

// reg [63:0] fc_test = 64'hA5A5A5A5A5A5A5A5;
reg [399:0] fc_data = 400'hAA30FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
reg [399:0] fc_test = 400'hAA30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
reg [12:0] count_256 = 12'h000;
wire startSend;
reg transmitDone;          // 标志当前块传输是否完成

assign startSend = ~sendCmd;
// assign testIo = ~sendCmd;

//initial begin
//    fc0[0] = 17'h15401;
//    fc_test = 17'h15401;
//end

 always @(posedge clkd_pll) begin
     if (startSend) begin
         if (256 <= count_256) begin
             fc_test <= fc_data;
         end
         count_256 <= count_256 + 1;
     end
 end

Gowin_rPLL u_rPLL(
    .clkin(clk50m),
    .clkout(clk_pll),
    .clkoutd(clkd_pll)
);

spi_controller u_ledDriver(
    .clk(clkd_pll),
    .rst(rst),
    .miso(miso),
    .data_in(fc_test),
    .start(startSend),
    .sclk(dclk),
    .mosi(mosi),
    .data_out(),
    .done(testIo)
);

endmodule