`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2019 12:28:31 AM
// Design Name: 
// Module Name: testbench_arbiter
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


module testbench_arbiter(

    );
    logic clk;
    logic rst;
    logic [3:0] req;
    logic [3:0] grant;
    
    initial begin
        clk = 0;
        rst = 1;
        req = 0;
        #10
        rst = 0;
        repeat (2) @ (posedge clk);
        req[0] <= 1;
        repeat (2) @ (posedge clk);
        req[0] <= 0;
        repeat (2) @ (posedge clk);
        req[0] <= 1;
        req[1] <= 1;
        repeat (2) @ (posedge clk);
        req[2] <= 1;
        req[1] <= 0;
        repeat (2) @ (posedge clk);
        req[3] <= 1;
        req[2] <= 0;
        repeat (2) @ (posedge clk);
        req[3] <= 0;
        repeat (2) @ (posedge clk);
        req[0] <= 0;
        repeat (2) @ (posedge clk);
        req[3] <= 1;
        req[2] <= 0;
        repeat (2) @ (posedge clk);
        req[0] <= 1;
        req[1] <= 1;
        repeat (2) @ (posedge clk);
        req[0] <= 0;
        repeat (2) @ (posedge clk);
        req[3] <= 0;
        repeat (2) @ (posedge clk);
        req[0] <= 1;
        repeat (2) @ (posedge clk);
        req[1] <= 1;
        repeat (2) @ (posedge clk);
        req[1] <= 0;
        #10  $finish;
    end
    
    always clk = #10 ~clk; // 50MHz

    arbiter arbiter_inst(
        .clk(clk),
        .rst(rst),

        .req(req),
        .grant(grant)
    );
endmodule
