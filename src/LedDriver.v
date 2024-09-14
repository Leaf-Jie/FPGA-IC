module spi_master (
    input wire clk,
    input wire miso,
    input wire [63:0] init_in,       // 初始化数据输入
    input wire [399:0] data_in,      // 400 位数据输入
    input wire start,
    input wire data,                 // 控制 400 位数据发送的信号
    input wire index,                // 用于控制是否是 index 数据
    output reg sclk,
    output reg mosi,
    output reg [63:0] data_out,
    output reg done                  // 传输完成标志
);

reg [6:0] bit_cnt = 7'b0000000;      // 用于计数 64 位数据
reg [8:0] data_bit_cnt = 9'b000000000; // 用于计数 400 位数据
reg [4:0] high_cnt = 5'b00000;       // 用于计数 18 位高电平
reg transmitting = 1'b0;
reg send_high_bits = 1'b0;           // 控制是否发送高电平
reg send_check_bit = 1'b0;           // 控制是否发送校验位
reg first_bit = 1'b1;                // 标记是否为第一次发送数据
reg prev_start = 1'b0;               // 记录上一个时钟周期的 start 信号
reg check_bit;                       // 保存校验位

initial begin
    sclk = 1'b0;                     // 初始化时钟信号为低电平
    mosi = 1'b1;                     // 初始化 MOSI 信号为高电平
    done = 1'b1;                     // 初始化 done 信号为高电平
end

always @(posedge clk) begin
    // 持续生成 SCLK 信号，无论是否在传输数据
    sclk <= ~sclk;

    // 检测 start 信号的上升沿
    if (start && !prev_start) begin
        transmitting <= 1'b1;
        bit_cnt <= 7'b0000000;
        data_bit_cnt <= 10'b0000000000;
        high_cnt <= 5'b00000;
        done <= 1'b0;                 // 开始传输时清除 done 信号
        first_bit <= 1'b1;            // 重置 first_bit 确保下次发送前先拉低 MOSI
        send_check_bit <= 1'b0;       // 初始化不发送校验位
        send_high_bits <= 1'b0;       // 初始化不发送高电平
    end

    prev_start <= start;  // 更新 prev_start

    if (transmitting) begin
        if (sclk == 1'b1)  // 在 SCLK 的下降沿更新 MOSI 信号
        begin 
            if (first_bit) begin
                mosi <= 1'b0;         // 第一次发送前拉低 MOSI
                first_bit <= 1'b0;    // 完成首次拉低
            end else begin
                if (!send_check_bit && !send_high_bits) begin
                    if (index) begin
                        // index为高时，发送前16位
                        if (bit_cnt < 7'd16) begin
                            mosi <= init_in[63 - bit_cnt];  // 发送当前 bit
                            bit_cnt <= bit_cnt + 1;

                            // 发送 16 位后计算并准备发送校验位
                            if ((bit_cnt % 16 == 15)) begin
                                check_bit <= ~init_in[63 - bit_cnt]; // 计算校验位
                                send_check_bit <= 1'b1; // 设置标志准备发送校验位
                            end
                        end else if (bit_cnt == 7'd16) begin
                            // 发送完前16位，开始发送18位高电平
                            send_high_bits <= 1'b1;
                        end
                    end
                    else if (data) 
                    begin
                        // data为高时，发送 400 位数据
                        if (data_bit_cnt < 10'd400) begin
                            mosi <= data_in[399 - data_bit_cnt];  // 发送当前 bit
                            data_bit_cnt <= data_bit_cnt + 1;

                            // 每发送 16 位后计算并准备发送校验位
                            if ((data_bit_cnt % 16 == 15)) begin
                                check_bit <= ~data_in[399 - data_bit_cnt]; // 计算校验位
                                send_check_bit <= 1'b1; // 设置标志准备发送校验位
                            end
                        end else if (data_bit_cnt == 10'd400) begin
                            // 发送完 400 位数据，开始发送18位高电平
                            send_high_bits <= 1'b1;
                        end
                    end 
                    else 
                    begin
                        // 正常发送64位数据
                        if (bit_cnt < 7'd64) begin
                            mosi <= init_in[63 - bit_cnt];  // 发送当前 bit
                            bit_cnt <= bit_cnt + 1;

                            // 每发送 16 位后计算并准备发送校验位
                            if ((bit_cnt % 16 == 15)) begin
                                check_bit <= ~init_in[63 - bit_cnt]; // 计算校验位
                                send_check_bit <= 1'b1; // 设置标志准备发送校验位
                            end
                        end
                    end
                end else if (send_check_bit) begin
                    // 立即发送校验位
                    mosi <= check_bit;
                    send_check_bit <= 1'b0; // 校验位发送后清除标志
                    if (bit_cnt == 7'd64 || data_bit_cnt == 9'd400) begin
                        send_high_bits <= 1'b1;        // 完成数据传输，开始发送高电平
                    end
                end else if (send_high_bits) begin
                    // 发送18位高电平
                    if (high_cnt < 5'd18) begin
                        mosi <= 1'b1;                  // 发送高电平
                        high_cnt <= high_cnt + 1;
                    end else if (high_cnt == 5'd18) begin
                        done <= 1'b1;                  // 传输完成时将 done 信号置为高电平
                        transmitting <= 1'b0;
                        mosi <= 1'b1;                  // 传输完成后 MOSI 恢复为高电平
                    end
                end
            end
        end

        // 在 SCLK 的上升沿采样 MISO 信号并存储到输出缓冲区
        if (sclk == 1'b0 && bit_cnt < 7'd64) begin
            data_out[63 - bit_cnt] <= miso;
        end
    end
end

endmodule
// module spi_master (
//     input wire clk,
//     input wire miso,
//     input wire [63:0] init_in,       // 初始化数据输入
//     input wire [399:0] data_in,      // 400 位数据输入
//     input wire start,
//     input wire data,                 // 控制 400 位数据发送的信号
//     input wire index,                // 用于控制是否是 index 数据
//     output reg sclk,
//     output reg mosi,
//     output reg [63:0] data_out,
//     output reg done                  // 传输完成标志
// );

// reg [6:0] bit_cnt = 7'b0000000;      // 用于计数 64 位数据
// reg [8:0] data_bit_cnt = 9'b000000000; // 用于计数 400 位数据
// reg [6:0] high_cnt = 7'b0000000;     // 用于计数 64 位高电平
// reg transmitting = 1'b0;
// reg send_high_bits = 1'b0;           // 控制是否发送高电平
// reg send_check_bit = 1'b0;           // 控制是否发送校验位
// reg first_bit = 1'b1;                // 标记是否为第一次发送数据
// reg prev_start = 1'b0;               // 记录上一个时钟周期的 start 信号
// reg check_bit;                       // 保存校验位

// initial begin
//     sclk = 1'b0;                     // 初始化时钟信号为低电平
//     mosi = 1'b1;                     // 初始化 MOSI 信号为高电平
//     done = 1'b1;                     // 初始化 done 信号为高电平
// end

// always @(posedge clk) begin
//     // 持续生成 SCLK 信号，无论是否在传输数据
//     sclk <= ~sclk;

//     // 检测 start 信号的上升沿
//     if (start && !prev_start) begin
//         transmitting <= 1'b1;
//         bit_cnt <= 7'b0000000;
//         data_bit_cnt <= 10'b0000000000;
//         high_cnt <= 7'b0000000;
//         done <= 1'b0;                 // 开始传输时清除 done 信号
//         first_bit <= 1'b1;            // 重置 first_bit 确保下次发送前先拉低 MOSI
//         send_check_bit <= 1'b0;       // 初始化不发送校验位
//         send_high_bits <= 1'b0;       // 初始化不发送高电平
//     end

//     prev_start <= start;  // 更新 prev_start

//     if (transmitting) begin
//         if (sclk == 1'b1)  // 在 SCLK 的下降沿更新 MOSI 信号
//         begin 
//             if (first_bit) begin
//                 mosi <= 1'b0;         // 第一次发送前拉低 MOSI
//                 first_bit <= 1'b0;    // 完成首次拉低
//             end else begin
//                 if (!send_check_bit && !send_high_bits) begin
//                     if (index) begin
//                         // index为高时，发送前16位
//                         if (bit_cnt < 7'd16) begin
//                             mosi <= init_in[63 - bit_cnt];  // 发送当前 bit
//                             bit_cnt <= bit_cnt + 1;

//                             // 发送 16 位后计算并准备发送校验位
//                             if ((bit_cnt % 16 == 15)) begin
//                                 check_bit <= ~init_in[63 - bit_cnt]; // 计算校验位
//                                 send_check_bit <= 1'b1; // 设置标志准备发送校验位
//                             end
//                         end else if (bit_cnt == 7'd16) begin
//                             // 发送完前16位，开始发送64位高电平
//                             send_high_bits <= 1'b1;
//                         end
//                     end
//                     else if (data) 
//                     begin
//                         // data为高时，发送 400 位数据
//                         if (data_bit_cnt < 10'd400) begin
//                             mosi <= data_in[399 - data_bit_cnt];  // 发送当前 bit
//                             data_bit_cnt <= data_bit_cnt + 1;

//                             // 每发送 16 位后计算并准备发送校验位
//                             if ((data_bit_cnt % 16 == 15)) begin
//                                 check_bit <= ~data_in[399 - data_bit_cnt]; // 计算校验位
//                                 send_check_bit <= 1'b1; // 设置标志准备发送校验位
//                             end
//                         end else if (data_bit_cnt == 10'd400) begin
//                             // 发送完 400 位数据，开始发送64位高电平
//                             send_high_bits <= 1'b1;
//                         end
//                     end 
//                     else 
//                     begin
//                         // 正常发送64位数据
//                         if (bit_cnt < 7'd64) begin
//                             mosi <= init_in[63 - bit_cnt];  // 发送当前 bit
//                             bit_cnt <= bit_cnt + 1;

//                             // 每发送 16 位后计算并准备发送校验位
//                             if ((bit_cnt % 16 == 15)) begin
//                                 check_bit <= ~init_in[63 - bit_cnt]; // 计算校验位
//                                 send_check_bit <= 1'b1; // 设置标志准备发送校验位
//                             end
//                         end
//                     end
//                 end else if (send_check_bit) begin
//                     // 立即发送校验位
//                     mosi <= check_bit;
//                     send_check_bit <= 1'b0; // 校验位发送后清除标志
//                     if (bit_cnt == 7'd64 || data_bit_cnt == 9'd400) begin
//                         send_high_bits <= 1'b1;        // 完成数据传输，开始发送高电平
//                     end
//                 end else if (send_high_bits) begin
//                     // 发送64位高电平
//                     if (high_cnt < 7'd64) begin
//                         mosi <= 1'b1;                  // 发送高电平
//                         high_cnt <= high_cnt + 1;
//                     end else if (high_cnt == 7'd64) begin
//                         done <= 1'b1;                  // 传输完成时将 done 信号置为高电平
//                         transmitting <= 1'b0;
//                         mosi <= 1'b1;                  // 传输完成后 MOSI 恢复为高电平
//                     end
//                 end
//             end
//         end

//         // 在 SCLK 的上升沿采样 MISO 信号并存储到输出缓冲区
//         if (sclk == 1'b0 && bit_cnt < 7'd64) begin
//             data_out[63 - bit_cnt] <= miso;
//         end
//     end
// end

// endmodule
