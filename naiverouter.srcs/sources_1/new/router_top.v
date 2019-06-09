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
    output [`BYTE_WIDTH-1:0] axis_rxd_tdata,
    output axis_rxd_tlast,
    input axis_rxd_tready,
    output axis_rxd_tvalid,

    // from os to router
    input [`BYTE_WIDTH-1:0] axis_txd_tdata,
    input axis_txd_tlast,
    output axis_txd_tready,
    input axis_txd_tvalid,
    
    input [3:0] rgmii1_rd,
    input rgmii1_rx_ctl,
    input rgmii1_rxc,
    output [3:0] rgmii1_td,
    output rgmii1_tx_ctl,
    output rgmii1_txc,

    input [3:0] rgmii2_rd,
    input rgmii2_rx_ctl,
    input rgmii2_rxc,
    output [3:0] rgmii2_td,
    output rgmii2_tx_ctl,
    output rgmii2_txc,

    input [3:0] rgmii3_rd,
    input rgmii3_rx_ctl,
    input rgmii3_rxc,
    output [3:0] rgmii3_td,
    output rgmii3_tx_ctl,
    output rgmii3_txc,

    input [3:0] rgmii4_rd,
    input rgmii4_rx_ctl,
    input rgmii4_rxc,
    output [3:0] rgmii4_td,
    output rgmii4_tx_ctl,
    output rgmii4_txc,

    output [`PORT_OS_COUNT-1:0][`STATS_WIDTH-1:0] stats_rx_packets,
    output [`PORT_OS_COUNT-1:0][`STATS_WIDTH-1:0] stats_rx_bytes,
    output [`PORT_OS_COUNT-1:0][`STATS_WIDTH-1:0] stats_tx_packets,
    output [`PORT_OS_COUNT-1:0][`STATS_WIDTH-1:0] stats_tx_bytes,

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
	    .axis_rxd_tdata(axis_rxd_tdata),
	    .axis_rxd_tlast(axis_rxd_tlast),
	    .axis_rxd_tready(axis_rxd_tready),
	    .axis_rxd_tvalid(axis_rxd_tvalid),
	    .axis_txd_tdata(axis_txd_tdata),
	    .axis_txd_tlast(axis_txd_tlast),
	    .axis_txd_tready(axis_txd_tready),
	    .axis_txd_tvalid(axis_txd_tvalid),

	    .rgmii1_rd(rgmii1_rd),
	    .rgmii1_rx_ctl(rgmii1_rx_ctl),
	    .rgmii1_rxc(rgmii1_rxc),
	    .rgmii1_td(rgmii1_td),
	    .rgmii1_tx_ctl(rgmii1_tx_ctl),
	    .rgmii1_txc(rgmii1_txc),

	    .rgmii2_rd(rgmii2_rd),
	    .rgmii2_rx_ctl(rgmii2_rx_ctl),
	    .rgmii2_rxc(rgmii2_rxc),
	    .rgmii2_td(rgmii2_td),
	    .rgmii2_tx_ctl(rgmii2_tx_ctl),
	    .rgmii2_txc(rgmii2_txc),

	    .rgmii3_rd(rgmii3_rd),
	    .rgmii3_rx_ctl(rgmii3_rx_ctl),
	    .rgmii3_rxc(rgmii3_rxc),
	    .rgmii3_td(rgmii3_td),
	    .rgmii3_tx_ctl(rgmii3_tx_ctl),
	    .rgmii3_txc(rgmii3_txc),

	    .rgmii4_rd(rgmii4_rd),
	    .rgmii4_rx_ctl(rgmii4_rx_ctl),
	    .rgmii4_rxc(rgmii4_rxc),
	    .rgmii4_td(rgmii4_td),
	    .rgmii4_tx_ctl(rgmii4_tx_ctl),
	    .rgmii4_txc(rgmii4_txc),

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

