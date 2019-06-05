`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/04/2019 04:43:59 PM
// Design Name: 
// Module Name: router
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

module router(
    input logic clk, // internal clk
    input logic clk125M, // 125MHz
    input logic clk200M, // 200MHz
    input logic reset_n,

    input axis_clk,
    // from router to os
    output logic [`BYTE_WIDTH-1:0] axis_rxd_tdata,
    output logic axis_rxd_tlast,
    input axis_rxd_tready,
    output logic axis_rxd_tvalid,

    // from os to router
    input [`BYTE_WIDTH-1:0] axis_txd_tdata,
    input axis_txd_tlast,
    output logic axis_txd_tready,
    input axis_txd_tvalid,
    
    input logic [3:0] rgmii1_rd,
    input logic rgmii1_rx_ctl,
    input logic rgmii1_rxc,
    output logic [3:0] rgmii1_td,
    output logic rgmii1_tx_ctl,
    output logic rgmii1_txc,

    input logic [3:0] rgmii2_rd,
    input logic rgmii2_rx_ctl,
    input logic rgmii2_rxc,
    output logic [3:0] rgmii2_td,
    output logic rgmii2_tx_ctl,
    output logic rgmii2_txc,

    output logic [`PORT_OS_COUNT-1:0][`STATS_WIDTH-1:0] stats_rx_packets,
    output logic [`PORT_OS_COUNT-1:0][`STATS_WIDTH-1:0] stats_rx_bytes,
    output logic [`PORT_OS_COUNT-1:0][`STATS_WIDTH-1:0] stats_tx_packets,
    output logic [`PORT_OS_COUNT-1:0][`STATS_WIDTH-1:0] stats_tx_bytes,

    input os_clk,
    input [15:0] os_addr,
    input [`ROUTING_TABLE_ENTRY_WIDTH-1:0] os_din,
    output [`ROUTING_TABLE_ENTRY_WIDTH-1:0] os_dout,
    input [(`ROUTING_TABLE_ENTRY_WIDTH)/`BYTE_WIDTH-1:0] os_wea,
    input os_rst,
    input os_en
    );
    
    logic reset;
    assign reset = ~reset_n;
    
    logic gtx_clk; // 125MHz
    logic gtx_clk90; // 125MHz, 90 deg shift

    // arp table with arbiter
    logic [`PORT_COUNT-1:0] arp_arbiter_req;
    logic [`PORT_COUNT-1:0] arp_arbiter_grant;

    logic [`PORT_COUNT-1:0][`IPV4_WIDTH-1:0] port_arp_lookup_ip;
    logic [`PORT_COUNT-1:0][`MAC_WIDTH-1:0] port_arp_lookup_mac;
    logic [`PORT_COUNT-1:0][`PORT_WIDTH-1:0] port_arp_lookup_port;
    logic [`PORT_COUNT-1:0] port_arp_lookup_ip_valid;
    logic [`PORT_COUNT-1:0] port_arp_lookup_mac_valid;
    logic [`PORT_COUNT-1:0] port_arp_lookup_mac_not_found;

    logic [`PORT_COUNT-1:0][`IPV4_WIDTH-1:0] port_arp_insert_ip;
    logic [`PORT_COUNT-1:0][`MAC_WIDTH-1:0] port_arp_insert_mac;
    logic [`PORT_COUNT-1:0][`PORT_WIDTH-1:0] port_arp_insert_port;
    logic [`PORT_COUNT-1:0] port_arp_insert_valid;
    logic [`PORT_COUNT-1:0] port_arp_insert_ready;


    arp_table_bus arp_table_bus_inst(
        .clk(clk),
        .reset(reset),
        .arp_arbiter_req(arp_arbiter_req),
        .arp_arbiter_grant(arp_arbiter_grant),

        .port_arp_lookup_ip(port_arp_lookup_ip),
        .port_arp_lookup_mac(port_arp_lookup_mac),
        .port_arp_lookup_port(port_arp_lookup_port),
        .port_arp_lookup_ip_valid(port_arp_lookup_ip_valid),
        .port_arp_lookup_mac_valid(port_arp_lookup_mac_valid),
        .port_arp_lookup_mac_not_found(port_arp_lookup_mac_not_found),

        .port_arp_insert_ip(port_arp_insert_ip),
        .port_arp_insert_mac(port_arp_insert_mac),
        .port_arp_insert_port(port_arp_insert_port),
        .port_arp_insert_valid(port_arp_insert_valid),
        .port_arp_insert_ready(port_arp_insert_ready)
    );

    // routing table with arbiter
    logic [`PORT_COUNT-1:0] routing_arbiter_req;
    logic [`PORT_COUNT-1:0] routing_arbiter_grant;

    logic [`PORT_COUNT-1:0][`IPV4_WIDTH-1:0] port_lookup_dest_ip;
    logic [`PORT_COUNT-1:0][`IPV4_WIDTH-1:0] port_lookup_via_ip;
    logic [`PORT_COUNT-1:0][`PORT_WIDTH-1:0] port_lookup_via_port;
    logic [`PORT_COUNT-1:0]port_lookup_valid;
    logic [`PORT_COUNT-1:0]port_lookup_ready;
    logic [`PORT_COUNT-1:0]port_lookup_output_valid;
    logic [`PORT_COUNT-1:0]port_lookup_not_found;

    routing_table_bus routing_table_bus_inst(
        .clk(clk),
        .reset(reset),
        .routing_arbiter_req(routing_arbiter_req),
        .routing_arbiter_grant(routing_arbiter_grant),

        .port_lookup_dest_ip(port_lookup_dest_ip),
        .port_lookup_via_ip(port_lookup_via_ip),
        .port_lookup_via_port(port_lookup_via_port),
        .port_lookup_valid(port_lookup_valid),
        .port_lookup_ready(port_lookup_ready),
        .port_lookup_output_valid(port_lookup_output_valid),
        .port_lookup_not_found(port_lookup_not_found),

        .os_clk(os_clk),
        .os_addr(os_addr[15:4]),
        .os_din(os_din),
        .os_dout(os_dout),
        .os_wea(os_wea),
        .os_rst(os_rst),
        .os_en(os_en)
    );

    // ports
    logic [`PORT_OS_COUNT-1:0][`PORT_OS_COUNT-1:0][`BYTE_WIDTH-1:0] fifo_matrix_wdata;
    logic [`PORT_OS_COUNT-1:0][`PORT_OS_COUNT-1:0] fifo_matrix_wlast;
    logic [`PORT_OS_COUNT-1:0][`PORT_OS_COUNT-1:0] fifo_matrix_wvalid;
    logic [`PORT_OS_COUNT-1:0][`PORT_OS_COUNT-1:0] fifo_matrix_wready;

    logic [`PORT_COUNT-1:0][`IPV4_WIDTH-1:0] port_ip = {
        `IPV4_WIDTH'h0a000101,// port 1 10.0.1.1
        `IPV4_WIDTH'h0a000001 // port 0 10.0.0.1
    };

    // port 0
    port #(
        .shared(0)
    ) port_inst_0 (
        .clk(clk),
        .reset_n(reset_n),
        .port_id(2'b00),
        .port_ip(port_ip), // 10.0.0.1
        .port_mac(48'h020203030000), // 02:02:03:03:00:00

        // arp
        .arp_arbiter_req(arp_arbiter_req[0]),
        .arp_arbiter_granted(arp_arbiter_grant[0]),
        .arp_lookup_ip(port_arp_lookup_ip[0]),
        .arp_lookup_mac(port_arp_lookup_mac[0]),
        .arp_lookup_port(port_arp_lookup_port[0]),
        .arp_lookup_ip_valid(port_arp_lookup_ip_valid[0]),
        .arp_lookup_mac_valid(port_arp_lookup_mac_valid[0]),
        .arp_lookup_mac_not_found(port_arp_lookup_mac_not_found[0]),
        .arp_insert_ip(port_arp_insert_ip[0]),
        .arp_insert_mac(port_arp_insert_mac[0]),
        .arp_insert_port(port_arp_insert_port[0]),
        .arp_insert_valid(port_arp_insert_valid[0]),
        .arp_insert_ready(port_arp_insert_ready[0]),

        // routing
        .routing_arbiter_req(routing_arbiter_req[0]),
        .routing_arbiter_granted(routing_arbiter_grant[0]),
        .routing_lookup_dest_ip(port_lookup_dest_ip[0]),
        .routing_lookup_via_ip(port_lookup_via_ip[0]),
        .routing_lookup_via_port(port_lookup_via_port[0]),
        .routing_lookup_valid(port_lookup_valid[0]),
        .routing_lookup_ready(port_lookup_ready[0]),
        .routing_lookup_output_valid(port_lookup_output_valid[0]),
        .routing_lookup_not_found(port_lookup_not_found[0]),

        // from X to current
        .fifo_matrix_tx_wdata({fifo_matrix_wdata[4][0], fifo_matrix_wdata[3][0], fifo_matrix_wdata[2][0], fifo_matrix_wdata[1][0], fifo_matrix_wdata[0][0]}),
        .fifo_matrix_tx_wlast({fifo_matrix_wlast[4][0], fifo_matrix_wlast[3][0], fifo_matrix_wlast[2][0], fifo_matrix_wlast[1][0], fifo_matrix_wlast[0][0]}),
        .fifo_matrix_tx_wvalid({fifo_matrix_wvalid[4][0], fifo_matrix_wvalid[3][0], fifo_matrix_wvalid[2][0], fifo_matrix_wvalid[1][0], fifo_matrix_wvalid[0][0]}),
        .fifo_matrix_tx_wready({fifo_matrix_wready[4][0], fifo_matrix_wready[3][0], fifo_matrix_wready[2][0], fifo_matrix_wready[1][0], fifo_matrix_wready[0][0]}),

        // from current to X
        .fifo_matrix_rx_wdata({fifo_matrix_wdata[0][4], fifo_matrix_wdata[0][3], fifo_matrix_wdata[0][2], fifo_matrix_wdata[0][1], fifo_matrix_wdata[0][0]}),
        .fifo_matrix_rx_wlast({fifo_matrix_wlast[0][4], fifo_matrix_wlast[0][3], fifo_matrix_wlast[0][2], fifo_matrix_wlast[0][1], fifo_matrix_wlast[0][0]}),
        .fifo_matrix_rx_wvalid({fifo_matrix_wvalid[0][4], fifo_matrix_wvalid[0][3], fifo_matrix_wvalid[0][2], fifo_matrix_wvalid[0][1], fifo_matrix_wvalid[0][0]}),
        .fifo_matrix_rx_wready({fifo_matrix_wready[0][4], fifo_matrix_wready[0][3], fifo_matrix_wready[0][2], fifo_matrix_wready[0][1], fifo_matrix_wready[0][0]}),

        .gtx_clk(clk125M),
        .gtx_clk_out(gtx_clk),
        .gtx_clk90_out(gtx_clk90),
        .refclk(clk200M),

        .rgmii_td(rgmii1_td),
        .rgmii_tx_ctl(rgmii1_tx_ctl),
        .rgmii_txc(rgmii1_txc),
        .rgmii_rd(rgmii1_rd),
        .rgmii_rx_ctl(rgmii1_rx_ctl),
        .rgmii_rxc(rgmii1_rxc),
        
        .stats_rx_bytes(stats_rx_bytes[0]),
        .stats_rx_packets(stats_rx_packets[0]),
        .stats_tx_bytes(stats_tx_bytes[0]),
        .stats_tx_packets(stats_tx_packets[0])
    );

    // port 1
    port #(
        .shared(1)
    ) port_inst_1 (
        .clk(clk),
        .reset_n(reset_n),
        .port_id(2'b01),
        .port_ip(port_ip), // 10.0.1.1
        .port_mac(48'h020203030000), // 02:02:03:03:00:00

        // arp
        .arp_arbiter_req(arp_arbiter_req[1]),
        .arp_arbiter_granted(arp_arbiter_grant[1]),
        .arp_lookup_ip(port_arp_lookup_ip[1]),
        .arp_lookup_mac(port_arp_lookup_mac[1]),
        .arp_lookup_port(port_arp_lookup_port[1]),
        .arp_lookup_ip_valid(port_arp_lookup_ip_valid[1]),
        .arp_lookup_mac_valid(port_arp_lookup_mac_valid[1]),
        .arp_lookup_mac_not_found(port_arp_lookup_mac_not_found[1]),
        .arp_insert_ip(port_arp_insert_ip[1]),
        .arp_insert_mac(port_arp_insert_mac[1]),
        .arp_insert_port(port_arp_insert_port[1]),
        .arp_insert_valid(port_arp_insert_valid[1]),
        .arp_insert_ready(port_arp_insert_ready[1]),

        // routing
        .routing_arbiter_req(routing_arbiter_req[1]),
        .routing_arbiter_granted(routing_arbiter_grant[1]),
        .routing_lookup_dest_ip(port_lookup_dest_ip[1]),
        .routing_lookup_via_ip(port_lookup_via_ip[1]),
        .routing_lookup_via_port(port_lookup_via_port[1]),
        .routing_lookup_valid(port_lookup_valid[1]),
        .routing_lookup_ready(port_lookup_ready[1]),
        .routing_lookup_output_valid(port_lookup_output_valid[1]),
        .routing_lookup_not_found(port_lookup_not_found[1]),

        // from X to current
        .fifo_matrix_tx_wdata({fifo_matrix_wdata[4][1], fifo_matrix_wdata[3][1], fifo_matrix_wdata[2][1], fifo_matrix_wdata[1][1], fifo_matrix_wdata[0][1]}),
        .fifo_matrix_tx_wlast({fifo_matrix_wlast[4][1], fifo_matrix_wlast[3][1], fifo_matrix_wlast[2][1], fifo_matrix_wlast[1][1], fifo_matrix_wlast[0][1]}),
        .fifo_matrix_tx_wvalid({fifo_matrix_wvalid[4][1], fifo_matrix_wvalid[3][1], fifo_matrix_wvalid[2][1], fifo_matrix_wvalid[1][1], fifo_matrix_wvalid[0][1]}),
        .fifo_matrix_tx_wready({fifo_matrix_wready[4][1], fifo_matrix_wready[3][1], fifo_matrix_wready[2][1], fifo_matrix_wready[1][1], fifo_matrix_wready[0][1]}),

        // from current to X
        .fifo_matrix_rx_wdata({fifo_matrix_wdata[1][4], fifo_matrix_wdata[1][3], fifo_matrix_wdata[1][2], fifo_matrix_wdata[1][1], fifo_matrix_wdata[1][0]}),
        .fifo_matrix_rx_wlast({fifo_matrix_wlast[1][4], fifo_matrix_wlast[1][3], fifo_matrix_wlast[1][2], fifo_matrix_wlast[1][1], fifo_matrix_wlast[1][0]}),
        .fifo_matrix_rx_wvalid({fifo_matrix_wvalid[1][4], fifo_matrix_wvalid[1][3], fifo_matrix_wvalid[1][2], fifo_matrix_wvalid[1][1], fifo_matrix_wvalid[1][0]}),
        .fifo_matrix_rx_wready({fifo_matrix_wready[1][4], fifo_matrix_wready[1][3], fifo_matrix_wready[1][2], fifo_matrix_wready[1][1], fifo_matrix_wready[1][0]}),

        .gtx_clk(gtx_clk),
        .gtx_clk90(gtx_clk90),

        .rgmii_td(rgmii2_td),
        .rgmii_tx_ctl(rgmii2_tx_ctl),
        .rgmii_txc(rgmii2_txc),
        .rgmii_rd(rgmii2_rd),
        .rgmii_rx_ctl(rgmii2_rx_ctl),
        .rgmii_rxc(rgmii2_rxc),

        .stats_rx_bytes(stats_rx_bytes[1]),
        .stats_rx_packets(stats_rx_packets[1]),
        .stats_tx_bytes(stats_tx_bytes[1]),
        .stats_tx_packets(stats_tx_packets[1])
    );

    // port 4 is os

    // from fifo matrix to os rx fifo
    // Round robin
    logic [`PORT_WIDTH-1:0] fifo_matrix_rx_index;
    logic fifo_matrix_rx_progress;

    logic [7:0] os_rxd_tdata;
    logic os_rxd_tvalid;
    logic os_rxd_tready;
    logic os_rxd_tlast;

    assign os_rxd_tdata = fifo_matrix_rx_progress ? fifo_matrix_wdata[fifo_matrix_rx_index][`OS_PORT_ID] : fifo_matrix_rx_index;
    assign os_rxd_tlast = fifo_matrix_rx_progress ? fifo_matrix_wlast[fifo_matrix_rx_index][`OS_PORT_ID] : 0;

    axis_data_fifo_0 axis_data_fifo_0_rx (
        .s_axis_aresetn(reset_n),
        .m_axis_aresetn(reset_n),
        .s_axis_aclk(clk),
        .s_axis_tvalid(os_rxd_tvalid),
        .s_axis_tready(os_rxd_tready),
        .s_axis_tdata(os_rxd_tdata),
        .s_axis_tlast(os_rxd_tlast),
        .m_axis_aclk(axis_clk),
        .m_axis_tvalid(axis_rxd_tvalid),
        .m_axis_tready(axis_rxd_tready),
        .m_axis_tdata(axis_rxd_tdata),
        .m_axis_tlast(axis_rxd_tlast)
    );

    always_ff @ (posedge clk) begin
        if (reset) begin
            os_rxd_tvalid <= 0;

            fifo_matrix_rx_index <= 0;
            fifo_matrix_rx_progress <= 0;

            fifo_matrix_wready[0][`OS_PORT_ID] <= 0;
            fifo_matrix_wready[1][`OS_PORT_ID] <= 0;
            fifo_matrix_wready[2][`OS_PORT_ID] <= 0;
            fifo_matrix_wready[3][`OS_PORT_ID] <= 0;
        end else begin
            if (!fifo_matrix_rx_progress && os_rxd_tready) begin
                // can send to os now
                if (fifo_matrix_wvalid[fifo_matrix_rx_index][`OS_PORT_ID]) begin
                    // begin to recv data
                    if (os_rxd_tvalid) begin
                        fifo_matrix_rx_progress <= 1;
                    end
                    fifo_matrix_wready[fifo_matrix_rx_index][`OS_PORT_ID] <= 1;
                    os_rxd_tvalid <= 1;
                end else begin
                    // round robin
                    fifo_matrix_rx_index <= fifo_matrix_rx_index + 1;
                    os_rxd_tvalid <= 0;
                    fifo_matrix_wready[fifo_matrix_rx_index][`OS_PORT_ID] <= 0;
                end
            end else if (fifo_matrix_rx_progress) begin
                if (fifo_matrix_wlast[fifo_matrix_rx_index][`OS_PORT_ID]) begin
                    fifo_matrix_rx_progress <= 0;
                    os_rxd_tvalid <= 0;
                end else begin
                    os_rxd_tvalid <= 1;
                end
            end
        end
    end

    // from os tx fifo to fifo matrix
    logic [`PORT_WIDTH-1:0] fifo_matrix_tx_index;
    logic [`LENGTH_WIDTH-1:0] fifo_matrix_tx_length;
    logic [`LENGTH_WIDTH-1:0] fifo_matrix_tx_counter;
    logic fifo_matrix_tx_progress;

    logic [7:0] os_txd_tdata;
    logic os_txd_tvalid;
    logic os_txd_tready;
    logic os_txd_tlast;

    axis_data_fifo_0 axis_data_fifo_0_tx (
        .s_axis_aresetn(reset_n),
        .m_axis_aresetn(reset_n),
        .m_axis_aclk(clk),
        .m_axis_tvalid(os_txd_tvalid),
        .m_axis_tready(os_txd_tready),
        .m_axis_tdata(os_txd_tdata),
        .m_axis_tlast(os_txd_tlast),
        .s_axis_aclk(axis_clk),
        .s_axis_tvalid(axis_txd_tvalid),
        .s_axis_tready(axis_txd_tready),
        .s_axis_tdata(axis_txd_tdata),
        .s_axis_tlast(axis_txd_tlast)
    );

    logic [`BYTE_WIDTH-1:0] fifo_matrix_tx_douta;
    logic [`LENGTH_WIDTH-1:0] fifo_matrix_tx_addra;
    logic [`BYTE_WIDTH-1:0] fifo_matrix_tx_dina;
    logic fifo_matrix_tx_wea;

    // stores the current ethernet frame temporarily
    // index start from 1
    xpm_memory_spram #(
        .ADDR_WIDTH_A(`LENGTH_WIDTH),
        .BYTE_WRITE_WIDTH_A(`BYTE_WIDTH),
        .MEMORY_SIZE(`MAX_ETHERNET_FRAME_BYTES * `BYTE_WIDTH),
        .READ_DATA_WIDTH_A(`BYTE_WIDTH),
        .READ_LATENCY_A(0),
        .WRITE_DATA_WIDTH_A(`BYTE_WIDTH)
    ) xpm_memory_spram_inst_tx (
        .douta(fifo_matrix_tx_douta),
        .addra(fifo_matrix_tx_addra),
        .clka(clk),
        .dina(fifo_matrix_tx_dina),
        .ena(1'b1),
        .rsta(reset),
        .wea(fifo_matrix_tx_wea)
    );

    always @ (posedge clk) begin
        if (reset) begin
            fifo_matrix_tx_index <= 0;
            fifo_matrix_tx_progress <= 0;

            fifo_matrix_tx_addra <= 0;
            fifo_matrix_tx_dina <= 0;
            fifo_matrix_tx_wea <= 0;

            os_txd_tready <= 1;

            fifo_matrix_wdata[`OS_PORT_ID][0] <= 0;
            fifo_matrix_wdata[`OS_PORT_ID][1] <= 0;
            fifo_matrix_wdata[`OS_PORT_ID][2] <= 0;
            fifo_matrix_wdata[`OS_PORT_ID][3] <= 0;
            fifo_matrix_wlast[`OS_PORT_ID][0] <= 0;
            fifo_matrix_wlast[`OS_PORT_ID][1] <= 0;
            fifo_matrix_wlast[`OS_PORT_ID][2] <= 0;
            fifo_matrix_wlast[`OS_PORT_ID][3] <= 0;
            fifo_matrix_wvalid[`OS_PORT_ID][0] <= 0;
            fifo_matrix_wvalid[`OS_PORT_ID][1] <= 0;
            fifo_matrix_wvalid[`OS_PORT_ID][2] <= 0;
            fifo_matrix_wvalid[`OS_PORT_ID][3] <= 0;
        end else begin
            // save data whenever tvalid is 1
            // and begin to send when tlast is 1
            if (os_txd_tvalid && !fifo_matrix_tx_progress) begin
                fifo_matrix_tx_dina <= os_txd_tdata;
                fifo_matrix_tx_wea <= 1;
                fifo_matrix_tx_addra <= fifo_matrix_tx_addra + 1;
                if (fifo_matrix_tx_addra == 0) begin
                    fifo_matrix_tx_index <= os_txd_tdata;
                end
                if (os_txd_tlast) begin
                    os_txd_tready <= 0;
                    fifo_matrix_tx_progress <= 1;
                    fifo_matrix_tx_length <= fifo_matrix_tx_addra;
                    fifo_matrix_tx_counter <= 0;
                    fifo_matrix_wvalid[`OS_PORT_ID][fifo_matrix_tx_index] <= 1;
                end 
            end else if (!fifo_matrix_tx_progress) begin
                fifo_matrix_tx_dina <= 0;
                fifo_matrix_tx_wea <= 0;
                fifo_matrix_tx_addra <= 0;
            end else begin
                if (fifo_matrix_tx_addra == fifo_matrix_tx_length + 1) begin
                    fifo_matrix_tx_addra <= 2;
                end
                fifo_matrix_tx_wea <= 0;
                if (fifo_matrix_wready[`OS_PORT_ID][fifo_matrix_tx_index]) begin
                    if (fifo_matrix_tx_counter < fifo_matrix_tx_length) begin
                        fifo_matrix_tx_counter <= fifo_matrix_tx_counter + 1;
                        fifo_matrix_tx_addra <= fifo_matrix_tx_counter + 3;
                        fifo_matrix_wdata[`OS_PORT_ID][fifo_matrix_tx_index] <= fifo_matrix_tx_douta;
                        if (fifo_matrix_tx_counter == fifo_matrix_tx_length - 1) begin
                            fifo_matrix_wlast[`OS_PORT_ID][fifo_matrix_tx_index] <= 1;
                        end
                    end else begin
                        fifo_matrix_wvalid[`OS_PORT_ID][fifo_matrix_tx_index] <= 0;
                        fifo_matrix_wdata[`OS_PORT_ID][fifo_matrix_tx_index] <= 0;
                        fifo_matrix_wlast[`OS_PORT_ID][fifo_matrix_tx_index] <= 0;
                        fifo_matrix_tx_progress <= 0;
                        fifo_matrix_tx_index <= 0;
                        fifo_matrix_tx_addra <= 0;
                        os_txd_tready <= 1;
                    end
                end
            end
        end
    end
endmodule

