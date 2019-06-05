`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/18/2019 03:50:50 PM
// Design Name: 
// Module Name: arbiter
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


module arbiter(
        input clk,
        input rst,

        input [3:0] req,
        output logic [3:0] grant = 0
    );

    logic [1:0] rotate = 0;
    logic [3:0] shift_req = 0;
    logic [3:0] shift_grant = 0;
    logic [3:0] grant_comb = 0;

    always_comb begin
        unique casez (rotate)
            2'b00 : shift_req = req;
            2'b01 : shift_req = {req[0], req[3:1]};
            2'b10 : shift_req = {req[1:0], req[3:2]};
            2'b11 : shift_req = {req[2:0], req[3]};
        endcase

        priority casez (shift_req)
            4'b???1 : shift_grant = 4'b0001;
            4'b??1? : shift_grant = 4'b0010;
            4'b?1?? : shift_grant = 4'b0100;
            4'b1??? : shift_grant = 4'b1000;
            4'b???? : shift_grant = 4'b0000;
        endcase

        unique casez (rotate)
            2'b00 : grant_comb = shift_grant;
            2'b01 : grant_comb = {shift_grant[2:0], shift_grant[3]};
            2'b10 : grant_comb = {shift_grant[1:0], shift_grant[3:2]};
            2'b11 : grant_comb = {shift_grant[0], shift_grant[3:1]};
        endcase
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            grant <= 0;
        end else if (!(grant & req)) begin
            grant <= grant_comb;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            rotate <= 0;
        end else begin
            unique casez (grant)
                4'b???1 : rotate = 2'b01;
                4'b??1? : rotate = 2'b10;
                4'b?1?? : rotate = 2'b11;
                4'b1??? : rotate = 2'b00;
                4'b0000 : ;
            endcase
        end
    end
endmodule
