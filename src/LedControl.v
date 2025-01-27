// module spi_controller (
//     input wire clk,                // 系统时钟信号
//     input wire rst,                // 复位信号
//     input wire miso,               // 输入的MISO信号
//     input wire start,              // 输入的启动信号
//     input wire [399:0] data_in,    // 可修改的400位输入数据
//     output wire sclk,              // 输出的时钟信号
//     output wire mosi,              // 输出的MOSI信号
//     output wire [63:0] data_out,   // 解析出来的64位数据
//     input wire done                // SPI模块的传输完成标志
// );

// reg [1:0] state = 2'b00;           // 状态机状态
// reg start_spi = 1'b0;              // SPI模块的启动信号
// reg [63:0] init_data[4:0];         // 上电阶段发送的五组64位数据
// reg [2:0] init_data_counter = 3'b000; // 初始化数据块计数器
// reg [63:0] data_buffer;            // 缓存当前要发送的64位数据
// reg [399:0] data_buffer_400;       // 缓存400位数据
// reg init_phase = 1'b1;             // 标志上电阶段
// reg prev_done = 1'b0;              // 保存上一个周期的 done 信号
// reg prev_rst = 1'b0;               // 保存上一个周期的 rst 信号
// reg rst_executed = 1'b0;           // 用于确保复位只执行一次
// reg sent_index = 1'b0;             // 标记是否已经发送过index数据
// reg [15:0] index_data = 16'hAA10;  // 示例的index数据
// reg index = 1'b0;                  // 用于传递给 spi_master 的 index 信号
// reg data = 1'b0;                   // 控制400位数据的传输信号

// // 延迟计数器
// reg [6:0] delay_counter = 7'b0000000;  // 100 个时钟周期计数器
// reg delay_phase = 1'b0;                // 延迟阶段标志

// // 实例化 spi_master 模块
// spi_master spi (
//     .clk(clk),
//     .miso(miso),
//     .data_in(data_buffer_400),      // 传递400位数据缓冲区
//     .init_in(data_buffer),          // 传递初始化数据缓冲区
//     .start(start_spi),
//     .sclk(sclk),
//     .mosi(mosi),
//     .data_out(data_out),
//     .done(done),
//     .index(index),
//     .data(data)                     // 传递控制400位数据的信号
// );

// // 初始化五组64位数据
// initial begin
//     init_data[0] = 64'hAA002000F0CF0107;  // 示例数据1
//     init_data[1] = 64'hAA0101000094A7FF;  // 示例数据2
//     init_data[2] = 64'hAA02038000000666;  // 示例数据3
//     init_data[3] = 64'hAA03003C7D7D7D00;  // 示例数据4
//     init_data[4] = 64'hAA04080005404000;  // 示例数据5
//     data_buffer = 64'hAAAAAAAAAAAAAAAA;   // 初始化数据缓冲区
//     data_buffer_400 = 400'b0;             // 初始化400位数据缓冲区
// end

// always @(posedge clk) begin
//     prev_rst <= rst;  // 保存上一个周期的 rst 信号
//     prev_done <= done;  // 记录前一个周期的 done 信号

//     // 检测 rst 信号的上升沿，并确保只执行一次初始化过程
//     if (rst && !prev_rst && !rst_executed) begin
//         // 当 rst 信号从低变高并且未执行初始化时，重新进入初始化阶段
//         init_phase <= 1'b1;
//         sent_index <= 1'b0;           // 重置index发送标志
//         init_data_counter <= 3'b000;
//         rst_executed <= 1'b1;         // 标记复位已执行
//         state <= 2'b00;               // 回到初始状态
//         delay_phase <= 1'b0;          // 清除延迟阶段标志
//         delay_counter <= 7'b0000000;  // 清零延迟计数器
//     end else if (!rst && prev_rst) begin
//         // 当 rst 信号从高变低时，清除标志以允许下次复位
//         rst_executed <= 1'b0;         // 允许下次复位信号时执行初始化
//     end

//     case (state)
//         2'b00: begin
//             if (init_phase && !sent_index) begin
//                 // 发送 index 数据前16位
//                 data_buffer <= {index_data, 48'b0};  // 将index数据放在data_buffer的前16位
//                 start_spi <= 1'b1;                   // 启动SPI传输
//                 index <= 1'b1;                       // 设置 index 信号为高
//                 data <= 1'b0;                        // 初始化时 data 信号为低
//                 state <= 2'b01;                      // 切换到等待传输完成状态
//             end else if (init_phase && sent_index) begin
//                 // 发送初始化数据
//                 data_buffer <= init_data[init_data_counter];
//                 start_spi <= 1'b1;                   // 启动SPI传输
//                 index <= 1'b0;                       // 清除 index 信号
//                 data <= 1'b0;                        // 初始化时 data 信号为低
//                 state <= 2'b01;                      // 切换到等待传输完成状态
//             end else if (start && !delay_phase) begin
//                 // 常规阶段发送400位数据，确保不在延迟阶段
//                 data_buffer_400 <= data_in;
//                 start_spi <= 1'b1;                   // 启动SPI传输
//                 data <= 1'b1;                        // 设置 data 信号为高，发送400位数据
//                 state <= 2'b01;                      // 切换到等待传输完成状态
//             end
//         end
        
//         2'b01: begin
//             if (done && !prev_done) begin  // 检测 done 信号的上升沿
//                 start_spi <= 1'b0;         // 停止SPI传输
//                 if (!sent_index) begin
//                     sent_index <= 1'b1;    // 标记 index 数据已发送
//                     state <= 2'b00;        // 返回以发送初始化数据
//                 end else if (init_phase) begin
//                     state <= 2'b10;        // 切换到发送下一个初始化数据
//                 end else begin
//                     // 400 位数据传输完成后进入延迟阶段
//                     delay_phase <= 1'b1;
//                     delay_counter <= 7'b0000000;  // 清零延迟计数器
//                     state <= 2'b10;               // 切换到延迟阶段
//                 end
//             end
//         end
        
//         2'b10: begin
//             if (delay_phase) begin
//                 // 延迟阶段处理
//                 if (delay_counter < 7'd100) begin
//                     delay_counter <= delay_counter + 1;
//                 end else begin
//                     delay_phase <= 1'b0;   // 结束延迟阶段
//                     state <= 2'b00;        // 返回空闲状态，允许新数据传输
//                 end
//             end else if (init_phase) begin
//                 // 初始化阶段处理
//                 if (init_data_counter < 3'b100) begin
//                     init_data_counter <= init_data_counter + 1;
//                 end else begin
//                     init_phase <= 1'b0;    // 结束初始化阶段
//                 end
//                 state <= 2'b00;            // 返回到发送下一组数据
//             end
//         end
//     endcase
// end

// endmodule
module spi_controller (
    input wire clk,                // 系统时钟信号
    input wire rst,                // 复位信号
    input wire miso,               // 输入的MISO信号
    input wire start,              // 输入的启动信号
    input wire [399:0] data_in,    // 可修改的400位输入数据
    output wire sclk,              // 输出的时钟信号
    output wire mosi,              // 输出的MOSI信号
    output wire [63:0] data_out,   // 解析出来的64位数据
    input wire done                // SPI模块的传输完成标志
);

reg [1:0] state = 2'b00;           // 状态机状态
reg start_spi = 1'b0;              // SPI模块的启动信号
reg [63:0] init_data[4:0];         // 上电阶段发送的五组64位数据
reg [2:0] init_data_counter = 3'b000; // 初始化数据块计数器
reg [63:0] data_buffer;            // 缓存当前要发送的64位数据
reg [399:0] data_buffer_400;       // 缓存400位数据
reg init_phase = 1'b1;             // 标志上电阶段
reg prev_done = 1'b0;              // 保存上一个周期的 done 信号
reg prev_rst = 1'b0;               // 保存上一个周期的 rst 信号
reg prev_start = 1'b0;               // 保存上一个周期的 start 信号
reg rst_executed = 1'b0;           // 用于确保复位只执行一次
reg sent_index = 1'b0;             // 标记是否已经发送过index数据
reg [15:0] index_data = 16'hAA10;  // 示例的index数据
reg [15:0] vsync_data = 16'hAAF0;  // 示例的index数据
reg index = 1'b0;                  // 用于传递给 spi_master 的 index 信号
reg data = 1'b0;                   // 控制400位数据的传输信号

// 延迟计数器
reg [15:0] delay_counter = 16'b0;   // 35000 个时钟周期计数器
reg [15:0] block_counter = 16'b0;     // 记录256个400位数据块的发送次数
reg delay_phase = 1'b0;             // 延迟阶段标志

// 实例化 spi_master 模块
spi_master spi (
    .clk(clk),
    .miso(miso),
    .data_in(data_buffer_400),      // 传递400位数据缓冲区
    .init_in(data_buffer),          // 传递初始化数据缓冲区
    .start(start_spi),
    .sclk(sclk),
    .mosi(mosi),
    .data_out(data_out),
    .done(done),
    .index(index),
    .data(data)                     // 传递控制400位数据的信号
);

// 初始化五组64位数据
initial begin
    init_data[0] = 64'hAA002000F0CF0107;  // 示例数据1
    init_data[1] = 64'hAA0101000094A7FF;  // 示例数据2
    init_data[2] = 64'hAA02038000000666;  // 示例数据3
    init_data[3] = 64'hAA03003C7D7D7D00;  // 示例数据4
    init_data[4] = 64'hAA04080005404000;  // 示例数据5
    data_buffer = 64'hAAAAAAAAAAAAAAAA;   // 初始化数据缓冲区
    data_buffer_400 = 400'b0;             // 初始化400位数据缓冲区
end

always @(posedge clk) begin
    prev_rst <= rst;  // 保存上一个周期的 rst 信号
    prev_done <= done;  // 记录前一个周期的 done 信号
    prev_start <= start;  // 记录前一个周期的 start 信号

    // 检测 rst 信号的上升沿，并确保只执行一次初始化过程
    if (rst && !prev_rst && !rst_executed) begin
        // 当 rst 信号从低变高并且未执行初始化时，重新进入初始化阶段
        init_phase <= 1'b1;
        sent_index <= 1'b0;           // 重置index发送标志
        init_data_counter <= 3'b000;
        rst_executed <= 1'b1;         // 标记复位已执行
        state <= 2'b00;               // 回到初始状态
        delay_phase <= 1'b0;          // 清除延迟阶段标志
        delay_counter <= 16'b0;       // 清零延迟计数器
        block_counter <= 16'b0;        // 清除400位数据块发送计数器
    end else if (!rst && prev_rst) begin
        // 当 rst 信号从高变低时，清除标志以允许下次复位
        rst_executed <= 1'b0;         // 允许下次复位信号时执行初始化
    end

    // 检测 start 信号的上升沿，并确保重新按下start键的时候会发送index信号
    if (start && !prev_start) begin
        // 当 rst 信号从高变低时
        state <= 2'b00;               // 回到初始状态
        delay_phase <= 1'b0;          // 清除延迟阶段标志
        delay_counter <= 16'b0;       // 清零延迟计数器
        block_counter <= 16'b0;        // 清除400位数据块发送计数器
    end

    case (state)
        2'b00: begin
            if (init_phase && !sent_index) begin
                // 发送 index 数据前16位
                data_buffer <= {index_data, 48'b0};  // 将index数据放在data_buffer的前16位
                start_spi <= 1'b1;                   // 启动SPI传输
                index <= 1'b1;                       // 设置 index 信号为高
                data <= 1'b0;                        // 初始化时 data 信号为低
                state <= 2'b01;                      // 切换到等待传输完成状态
            end else if (init_phase && sent_index) begin
                // 发送初始化数据
                data_buffer <= init_data[init_data_counter];
                start_spi <= 1'b1;                   // 启动SPI传输
                index <= 1'b0;                       // 清除 index 信号
                data <= 1'b0;                        // 初始化时 data 信号为低
                state <= 2'b01;                      // 切换到等待传输完成状态
            end else if (start && !delay_phase) begin
                // 常规阶段发送400位数据，确保不在延迟阶段
                if (block_counter == 16'd0) begin
                    // 如果已经发送了256个400位数据块，先发送一次index数据
                    data_buffer <= {vsync_data, 48'b0};
                    start_spi <= 1'b1;               // 启动SPI传输
                    index <= 1'b1;                   // 发送index信号
                    data <= 1'b0;                    // 初始化时 data 信号为低
                    block_counter <= 16'b0;           // 重置数据块计数器
                    state <= 2'b01;                  // 切换到等待传输完成状态
                end else begin
                    // 发送400位数据
                    index <= 1'b0;                       // 清除 index 信号
                    data_buffer_400 <= data_in;
                    start_spi <= 1'b1;               // 启动SPI传输
                    data <= 1'b1;                    // 设置 data 信号为高，发送400位数据
                    state <= 2'b01;                  // 切换到等待传输完成状态
                end
            end
        end
        
        2'b01: begin
            if (done && !prev_done) begin  // 检测 done 信号的上升沿
                start_spi <= 1'b0;         // 停止SPI传输
                if (!sent_index) begin
                    sent_index <= 1'b1;    // 标记 index 数据已发送
                    state <= 2'b00;        // 返回以发送初始化数据
                end else if (init_phase) begin
                    state <= 2'b10;        // 切换到发送下一个初始化数据
                end else begin
                    block_counter <= block_counter + 1;  // 增加数据块计数
                    if (block_counter < 16'd256) begin
                        state <= 2'b10;   // 继续发送400位数据
                    end else begin
                        // 发送完256个400位数据块后进入延迟阶段
                        block_counter <= 16'b0;           // 重置数据块计数器
                        delay_phase <= 1'b1;
                        delay_counter <= 16'b0;        // 清零延迟计数器
                        state <= 2'b10;               // 切换到延迟阶段
                    end
                end
            end
        end
        
        2'b10: begin
            if (delay_phase) begin
                // 延迟阶段处理
                if (delay_counter < 16'd35000) begin
                    delay_counter <= delay_counter + 1;
                end else begin
                    delay_phase <= 1'b0;   // 结束延迟阶段
                    state <= 2'b00;        // 返回空闲状态，允许新数据传输
                end
            end else if (init_phase) begin
                // 初始化阶段处理
                if (init_data_counter < 3'b100) begin
                    init_data_counter <= init_data_counter + 1;
                end else begin
                    init_phase <= 1'b0;    // 结束初始化阶段
                end
                state <= 2'b00;            // 返回到发送下一组数据
            end
            else begin
                state <= 2'b00;            // 返回到发送下一组数据
            end
        end
    endcase
end

endmodule
