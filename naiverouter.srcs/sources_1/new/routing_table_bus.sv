`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/24/2019 06:19:16 PM
// Design Name: 
// Module Name: routing_table_bus
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

module routing_table_bus(
    input clk,
    input reset,
    input [`PORT_COUNT-1:0] routing_arbiter_req,
    output logic [`PORT_COUNT-1:0] routing_arbiter_grant,

    input [`PORT_COUNT-1:0][`IPV4_WIDTH-1:0] port_lookup_dest_ip,
    output logic [`PORT_COUNT-1:0][`IPV4_WIDTH-1:0] port_lookup_via_ip,
    output logic [`PORT_COUNT-1:0][`PORT_WIDTH-1:0] port_lookup_via_port,
    input [`PORT_COUNT-1:0]port_lookup_valid,
    output logic [`PORT_COUNT-1:0]port_lookup_ready,
    output logic [`PORT_COUNT-1:0]port_lookup_output_valid,
    output logic [`PORT_COUNT-1:0]port_lookup_not_found,

    input os_clk,
    input [`BUCKET_INDEX_WIDTH-1:0] os_addr,
    input [`ROUTING_TABLE_ENTRY_WIDTH-1:0] os_din,
    output [`ROUTING_TABLE_ENTRY_WIDTH-1:0] os_dout,
    input [(`ROUTING_TABLE_ENTRY_WIDTH)/`BYTE_WIDTH-1:0] os_wea,
    input os_rst,
    input os_en
    );

    logic [`IPV4_WIDTH-1:0] lookup_dest_ip;
    logic [`IPV4_WIDTH-1:0] lookup_via_ip;
    logic [`PORT_WIDTH-1:0] lookup_via_port;
    logic lookup_valid;
    logic lookup_ready;
    logic lookup_output_valid;
    logic lookup_not_found;

    routing_table routing_table_inst(
        .clk(clk),
        .rst(reset),

        .lookup_dest_ip(lookup_dest_ip),
        .lookup_via_ip(lookup_via_ip),
        .lookup_via_port(lookup_via_port),
        .lookup_valid(lookup_valid),
        .lookup_ready(lookup_ready),
        .lookup_output_valid(lookup_output_valid),
        .lookup_not_found(lookup_not_found),

        .os_clk(os_clk),
        .os_addr(os_addr),
        .os_din(os_din),
        .os_dout(os_dout),
        .os_wea(os_wea),
        .os_rst(os_rst),
        .os_en(os_en)
    );


    always_comb begin
        unique casez (routing_arbiter_grant)
            4'b???1: begin
                port_lookup_via_ip[0] = lookup_via_ip;
                port_lookup_via_port[0] = lookup_via_port;
                port_lookup_ready[0] = lookup_ready;
                port_lookup_output_valid[0] = lookup_output_valid;
                port_lookup_not_found[0] = lookup_not_found;
                port_lookup_via_ip[1] = 0;
                port_lookup_via_port[1] = 0;
                port_lookup_ready[1] = 0;
                port_lookup_output_valid[1] = 0;
                port_lookup_not_found[1] = 0;
                port_lookup_via_ip[2] = 0;
                port_lookup_via_port[2] = 0;
                port_lookup_ready[2] = 0;
                port_lookup_output_valid[2] = 0;
                port_lookup_not_found[2] = 0;
                port_lookup_via_ip[3] = 0;
                port_lookup_via_port[3] = 0;
                port_lookup_ready[3] = 0;
                port_lookup_output_valid[3] = 0;
                port_lookup_not_found[3] = 0;
                lookup_dest_ip = port_lookup_dest_ip[0];
                lookup_valid = port_lookup_valid[0];
            end
            4'b??1?: begin
                port_lookup_via_ip[0] = 0;
                port_lookup_via_port[0] = 0;
                port_lookup_ready[0] = 0;
                port_lookup_output_valid[0] = 0;
                port_lookup_not_found[0] = 0;
                port_lookup_via_ip[1] = lookup_via_ip;
                port_lookup_via_port[1] = lookup_via_port;
                port_lookup_ready[1] = lookup_ready;
                port_lookup_output_valid[1] = lookup_output_valid;
                port_lookup_not_found[1] = lookup_not_found;
                port_lookup_via_ip[2] = 0;
                port_lookup_via_port[2] = 0;
                port_lookup_ready[2] = 0;
                port_lookup_output_valid[2] = 0;
                port_lookup_not_found[2] = 0;
                port_lookup_via_ip[3] = 0;
                port_lookup_via_port[3] = 0;
                port_lookup_ready[3] = 0;
                port_lookup_output_valid[3] = 0;
                port_lookup_not_found[3] = 0;
                lookup_dest_ip = port_lookup_dest_ip[1];
                lookup_valid = port_lookup_valid[1];
            end
            4'b?1??: begin
                port_lookup_via_ip[0] = 0;
                port_lookup_via_port[0] = 0;
                port_lookup_ready[0] = 0;
                port_lookup_output_valid[0] = 0;
                port_lookup_not_found[0] = 0;
                port_lookup_via_ip[1] = 0;
                port_lookup_via_port[1] = 0;
                port_lookup_ready[1] = 0;
                port_lookup_output_valid[1] = 0;
                port_lookup_not_found[1] = 0;
                port_lookup_via_ip[2] = lookup_via_ip;
                port_lookup_via_port[2] = lookup_via_port;
                port_lookup_ready[2] = lookup_ready;
                port_lookup_output_valid[2] = lookup_output_valid;
                port_lookup_not_found[2] = lookup_not_found;
                port_lookup_via_ip[3] = 0;
                port_lookup_via_port[3] = 0;
                port_lookup_ready[3] = 0;
                port_lookup_output_valid[3] = 0;
                port_lookup_not_found[3] = 0;
                lookup_dest_ip = port_lookup_dest_ip[2];
                lookup_valid = port_lookup_valid[2];
            end
            4'b1???: begin
                port_lookup_via_ip[0] = 0;
                port_lookup_via_port[0] = 0;
                port_lookup_ready[0] = 0;
                port_lookup_output_valid[0] = 0;
                port_lookup_not_found[0] = 0;
                port_lookup_via_ip[1] = 0;
                port_lookup_via_port[1] = 0;
                port_lookup_ready[1] = 0;
                port_lookup_output_valid[1] = 0;
                port_lookup_not_found[1] = 0;
                port_lookup_via_ip[2] = 0;
                port_lookup_via_port[2] = 0;
                port_lookup_ready[2] = 0;
                port_lookup_output_valid[2] = 0;
                port_lookup_not_found[2] = 0;
                port_lookup_via_ip[3] = lookup_via_ip;
                port_lookup_via_port[3] = lookup_via_port;
                port_lookup_ready[3] = lookup_ready;
                port_lookup_output_valid[3] = lookup_output_valid;
                port_lookup_not_found[3] = lookup_not_found;
                lookup_dest_ip = port_lookup_dest_ip[3];
                lookup_valid = port_lookup_valid[3];
            end
            4'b0000: begin
                port_lookup_via_ip[0] = 0;
                port_lookup_via_port[0] = 0;
                port_lookup_ready[0] = 0;
                port_lookup_output_valid[0] = 0;
                port_lookup_not_found[0] = 0;
                port_lookup_via_ip[1] = 0;
                port_lookup_via_port[1] = 0;
                port_lookup_ready[1] = 0;
                port_lookup_output_valid[1] = 0;
                port_lookup_not_found[1] = 0;
                port_lookup_via_ip[2] = 0;
                port_lookup_via_port[2] = 0;
                port_lookup_ready[2] = 0;
                port_lookup_output_valid[2] = 0;
                port_lookup_not_found[2] = 0;
                port_lookup_via_ip[3] = 0;
                port_lookup_via_port[3] = 0;
                port_lookup_ready[3] = 0;
                port_lookup_output_valid[3] = 0;
                port_lookup_not_found[3] = 0;
                lookup_dest_ip = 0;
                lookup_valid = 0;
            end
        endcase
    end

    arbiter arbiter_inst_routing(
        .clk(clk),
        .rst(reset),

        .req(routing_arbiter_req),
        .grant(routing_arbiter_grant)
    );
endmodule
