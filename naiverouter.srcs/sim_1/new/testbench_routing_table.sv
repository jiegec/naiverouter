`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2019 02:26:06 PM
// Design Name: 
// Module Name: testbench_routing_table
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

`include "constants.vh"

module testbench_routing_table(

    );

    logic clk;
    logic rst;
    logic [`IPV4_WIDTH-1:0] lookup_dest_ip;
    logic [`IPV4_WIDTH-1:0] lookup_via_ip;
    logic lookup_valid;
    logic lookup_ready;
    logic lookup_output_valid;
    logic lookup_not_found;

    initial begin
        clk = 0;
        rst = 1;
        lookup_dest_ip = 0;
        lookup_valid = 0;
        #100
        rst = 0;

        // lookup 10.0.0.1
        repeat (2) @ (posedge clk);
        lookup_dest_ip <= 32'h0a000001; // 10.0.0.1
        lookup_valid <= 1;
        repeat (1) @ (posedge clk);
        lookup_valid <= 0;
        repeat (2) @ (posedge clk);

        // lookup 10.0.0.2
        repeat (2) @ (posedge clk);
        lookup_dest_ip <= 32'h0a000002; // 10.0.0.2
        lookup_valid <= 1;
        repeat (1) @ (posedge clk);
        lookup_valid <= 0;
        repeat (2) @ (posedge clk);

        // lookup 10.0.1.2
        repeat (2) @ (posedge clk);
        lookup_dest_ip <= 32'h0a000102; // 10.0.1.2
        lookup_valid <= 1;
        repeat (1) @ (posedge clk);
        lookup_valid <= 0;
        repeat (2) @ (posedge clk);

        // lookup 10.1.1.2
        repeat (2) @ (posedge clk);
        lookup_dest_ip <= 32'h0a010102; // 10.1.1.2
        lookup_valid <= 1;
        repeat (1) @ (posedge clk);
        lookup_valid <= 0;
        repeat (2) @ (posedge clk);
    end
    
    always clk = #10 ~clk; // 50MHz

    routing_table routing_table_inst(
        .clk(clk),
        .rst(rst),

        .lookup_dest_ip(lookup_dest_ip),
        .lookup_via_ip(lookup_via_ip),
        .lookup_valid(lookup_valid),
        .lookup_ready(lookup_ready),
        .lookup_output_valid(lookup_output_valid),
        .lookup_not_found(lookup_not_found)
    );
endmodule
