`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2019 05:55:55 PM
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench(

    );

    reg clk_50M, clk_125M, clk_125M_90deg, clk_200M, clk_100M;
    reg reset_n;

    initial begin
        reset_n = 0;
        clk_50M = 0;
        clk_125M = 0;
        clk_125M_90deg = 0;
        clk_200M = 0;
        clk_100M = 0;
    end

    initial begin
        #2;
        forever clk_125M_90deg = #(8/2) ~clk_125M_90deg;
    end

    initial begin
        #50;
        reset_n = 1;
    end

    always #(20/2) clk_50M = ~clk_50M;
    always #(8/2) clk_125M = ~clk_125M;
    always #(5/2) clk_200M = ~clk_200M;
    always #(10/2) clk_100M = ~clk_100M;

    logic [3:0] rgmii_rd;
    logic rgmii_rx_ctl;
    logic rgmii_rxc;
    logic [3:0] rgmii_td;
    logic rgmii_tx_ctl;
    logic rgmii_txc;

    localparam BUFFER_SIZE = 2000;
    localparam FRAME_COUNT = 10;

    logic packet_clk;
    logic trans;
    logic [7:0] frame_index = 0;
    logic [3:0] data1;
    logic [3:0] data2;
    logic [7:0] frame_data [FRAME_COUNT-1:0][BUFFER_SIZE-1:0];
    logic [8*BUFFER_SIZE-1:0] buffer;
    logic [15:0] count;
    logic [15:0] frame_size [FRAME_COUNT-1:0];
    integer fd, index, res, frame_count;

    initial begin
        packet_clk = 0;
        fd = $fopen("example_frame.mem", "r");

        index = 0;
        frame_count = 0;
        for (integer i = 0;i < FRAME_COUNT;i++) begin
            frame_size[i] = 0;
            for (integer j = 0;j < BUFFER_SIZE;j++) begin
                frame_data[i][j] = 0;
            end
        end

        while (!$feof(fd)) begin
            res = $fscanf(fd, "%x", frame_data[frame_count][index]);
            if (res != 1) begin
                // end of a frame
                // read a line
                $fgets(buffer, fd);
                if (index > 0) begin
                    frame_size[frame_count] = index + 1;
                    frame_count = frame_count + 1;
                end
                index = 0;
            end else begin
                index = index + 1;
            end
        end

        if (index > 0) begin
            frame_size[frame_count] = index + 1;
            frame_count = frame_count + 1;
        end
    end

    always packet_clk = #1000 ~packet_clk;

    always_ff @ (posedge clk_125M) begin
        count <= packet_clk ? count + 1 : 0;
        if (packet_clk && count < frame_size[frame_index] - 1) begin
            trans <= 1'b1;
            data1 <= frame_data[frame_index][count][3:0];
            data2 <= frame_data[frame_index][count][7:4];
        end else begin
            trans <= 1'b0;
            data1 <= 4'b0;
            data2 <= 4'b0;
        end
    end

    always_ff @ (negedge packet_clk) begin
        frame_index = (frame_index + 1) % frame_count;
    end

    genvar i;
    for (i = 0;i < 4;i++) begin
        ODDR #(
            .DDR_CLK_EDGE("SAME_EDGE")
        ) oddr_inst (
            .D1(data1[i]),
            .D2(data2[i]),
            .C(clk_125M),
            .CE(1'b1),
            .Q(rgmii_rd[i]),
            .R(1'b0)
        );
    end

    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE")
    ) oddr_inst_ctl (
        .D1(trans),
        .D2(trans),
        .C(clk_125M),
        .CE(1'b1),
        .Q(rgmii_rx_ctl),
        .R(1'b0)
    );

    assign rgmii_rxc = clk_125M_90deg;

    logic axis_rxd_tready;
    logic axis_rxd_tlast = 0;
    logic axis_rxd_tvalid = 0;
    logic [7:0] axis_rxd_tdata = 0;
    logic axis_txd_tready = 1;
    logic axis_txd_tlast = 0;
    logic axis_txd_tvalid = 0;
    logic [7:0] axis_txd_tdata = 0;
    logic [31:0] count2 = 0;

    always @ (posedge clk_100M) begin
        axis_txd_tready <= ~axis_txd_tready;
        if (reset_n && axis_rxd_tready) begin
            if (count2 < 64) begin
                axis_rxd_tdata <= count2;
                axis_rxd_tvalid <= ~axis_rxd_tvalid;
                axis_rxd_tlast <= count2 == 63;
                if (axis_rxd_tvalid) begin
                    count2 <= count2 + 1;
                end
            end else if (count2 == 100) begin
                count2 <= 0;
            end else if (count2 >= 64) begin
                axis_rxd_tvalid <= 0;
                axis_rxd_tlast <= 0;
                count2 <= count2 + 1;
            end
        end
    end

    router_top dut(
        .clk(clk_50M),
        .clk_125M(clk_125M),
        .clk_200M(clk_200M),
        .reset_n(reset_n),

        .axis_clk(clk_100M),
        .axis_txd_tdata(axis_txd_tdata),
        .axis_txd_tlast(axis_txd_tlast),
        .axis_txd_tvalid(axis_txd_tvalid),
        .axis_txd_tready(axis_txd_tready),
        .axis_rxd_tdata(axis_rxd_tdata),
        .axis_rxd_tlast(axis_rxd_tlast),
        .axis_rxd_tvalid(axis_rxd_tvalid),
        .axis_rxd_tready(axis_rxd_tready),

        .rgmii_rd(rgmii_rd),
        .rgmii_rx_ctl(rgmii_rx_ctl),
        .rgmii_rxc(rgmii_rxc),
        .rgmii_td(rgmii_td),
        .rgmii_tx_ctl(rgmii_tx_ctl),
        .rgmii_txc(rgmii_txc),

        .os_clk(clk_50M),
        .os_addr(0),
        .os_din(0),
        .os_we(0),
        .os_rst(0),
        .os_en(0)
    );

    logic [3:0] data = 0;
    logic active = 0;

    always @ (posedge rgmii_txc) begin
        if (rgmii_tx_ctl) begin
            data <= rgmii_td;
            active <= 1;
        end else begin
            if (active) begin
                $display("");
                active <= 0;
            end
        end
    end

    always @ (negedge rgmii_txc) begin
        if (active) begin
            $write("%x ", {rgmii_td, data});
        end
    end
endmodule
