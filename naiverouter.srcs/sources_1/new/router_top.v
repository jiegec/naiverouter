`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2019 07:27:08 PM
// Design Name: 
// Module Name: router_top
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

module router_top(
    input clk, // internal clk
    input clk_125M, // 125MHz
    input clk_200M, // 200MHz
    input reset_n,

    input axis_clk,
    // from router to os
    output [`BYTE_WIDTH-1:0] axis_txd_tdata,
    output axis_txd_tlast,
    input axis_txd_tready,
    output axis_txd_tvalid,

    // from os to router
    input [`BYTE_WIDTH-1:0] axis_rxd_tdata,
    input axis_rxd_tlast,
    output axis_rxd_tready,
    input axis_rxd_tvalid,
    
    input [3:0] rgmii_rd,
    input rgmii_rx_ctl,
    input rgmii_rxc,
    output [3:0] rgmii_td,
    output rgmii_tx_ctl,
    output rgmii_txc,

    output [`PORT_COUNT-1:0][`STATS_WIDTH-1:0] stats_rx_packets,
    output [`PORT_COUNT-1:0][`STATS_WIDTH-1:0] stats_rx_bytes,
    output [`PORT_COUNT-1:0][`STATS_WIDTH-1:0] stats_tx_packets,
    output [`PORT_COUNT-1:0][`STATS_WIDTH-1:0] stats_tx_bytes,

    input os_clk,
    input [15:0] os_addr,
    input [`ROUTING_TABLE_ENTRY_WIDTH-1:0] os_din,
    output [`ROUTING_TABLE_ENTRY_WIDTH-1:0] os_dout,
    input [(`ROUTING_TABLE_ENTRY_WIDTH)/`BYTE_WIDTH-1:0] os_we,
    input os_rst,
    input os_en
    );

    router router_inst(
	    .clk(clk),
	    .clk125M(clk_125M),
	    .clk200M(clk_200M),
	    .reset_n(reset_n),

	    .axis_clk(axis_clk),
	    .axis_rxd_tdata(axis_txd_tdata),
	    .axis_rxd_tlast(axis_txd_tlast),
	    .axis_rxd_tready(axis_txd_tready),
	    .axis_rxd_tvalid(axis_txd_tvalid),
	    .axis_txd_tdata(axis_rxd_tdata),
	    .axis_txd_tlast(axis_rxd_tlast),
	    .axis_txd_tready(axis_rxd_tready),
	    .axis_txd_tvalid(axis_rxd_tvalid),

	    .rgmii_rd(rgmii_rd),
	    .rgmii_rx_ctl(rgmii_rx_ctl),
	    .rgmii_rxc(rgmii_rxc),
	    .rgmii_td(rgmii_td),
	    .rgmii_tx_ctl(rgmii_tx_ctl),
	    .rgmii_txc(rgmii_txc),

	    .stats_rx_packets(stats_rx_packets),
	    .stats_rx_bytes(stats_rx_bytes),
	    .stats_tx_packets(stats_tx_packets),
	    .stats_tx_bytes(stats_tx_bytes),

	    .os_clk(os_clk),
	    .os_addr(os_addr),
	    .os_din(os_din),
	    .os_dout(os_dout),
	    .os_wea(os_we),
	    .os_rst(os_rst),
	    .os_en(os_en)
    );
    
endmodule

