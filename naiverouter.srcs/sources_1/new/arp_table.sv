`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2019 09:25:43 PM
// Design Name: 
// Module Name: arp_table
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

module arp_table(
    input clk,
    input rst,

    input [`IPV4_WIDTH-1:0] lookup_ip,
    output logic [`MAC_WIDTH-1:0] lookup_mac,
    output logic [`PORT_WIDTH-1:0] lookup_port,
    input lookup_ip_valid,
    output logic lookup_mac_valid,
    output logic lookup_mac_not_found,

    input [`IPV4_WIDTH-1:0] insert_ip,
    input [`MAC_WIDTH-1:0] insert_mac,
    input [`PORT_WIDTH-1:0] insert_port,
    input insert_valid,
    output logic insert_ready
    );

    logic [`BUCKET_INDEX_WIDTH-1:0] lookup_bucket_index;
    assign lookup_bucket_index = {lookup_ip[31], lookup_ip[30], lookup_ip[29]};

    logic [`BUCKET_DEPTH_WIDTH-1:0] lookup_current_bucket_depth;

    // a for lookup, b for insert
    logic [`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH-1:0] data_dina;
    logic [`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH-1:0] data_douta;
    logic [`BUCKET_INDEX_WIDTH+`BUCKET_DEPTH_WIDTH-1:0] data_addra;
    logic [`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH-1:0] data_dinb;
    logic [`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH-1:0] data_doutb;
    logic [`BUCKET_INDEX_WIDTH+`BUCKET_DEPTH_WIDTH-1:0] data_addrb;
    logic data_web;

    assign data_addra = {lookup_bucket_index, lookup_current_bucket_depth};

    // A hash table with BUCKET_INDEX_COUNT buckets, each bucket can have at most BUCKET_DEPTH_COUNT items
    // Each item consists of (IP, MAC, PORT) tuple.
    // Addr: {bucket_index, bucket_depth} Data: (IP, MAC, PORT)
    xpm_memory_tdpram #(
        .ADDR_WIDTH_A(`BUCKET_INDEX_WIDTH+`BUCKET_DEPTH_WIDTH),
        .WRITE_DATA_WIDTH_A(`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH),
        .BYTE_WRITE_WIDTH_A(`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH),

        .ADDR_WIDTH_B(`BUCKET_INDEX_WIDTH+`BUCKET_DEPTH_WIDTH),
        .WRITE_DATA_WIDTH_B(`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH),
        .BYTE_WRITE_WIDTH_B(`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH),
        .MEMORY_SIZE(`BUCKET_INDEX_COUNT*`BUCKET_DEPTH_COUNT*(`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH)),
        .READ_LATENCY_A(1),
        .READ_LATENCY_B(0)
    ) xpm_memory_tdpram_inst (
        .dina(data_dina),
        .douta(data_douta),
        .addra(data_addra),
        .wea(1'b0),
        .clka(clk),
        .rsta(rst),
        .ena(1'b1),

        .dinb(data_dinb),
        .doutb(data_doutb),
        .addrb(data_addrb),
        .web(data_web),
        .clkb(clk),
        .rstb(rst),
        .enb(1'b1)
    );

    logic searching = 0;

    logic [`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH-1:0] last_data_douta;
    logic data_avail;
    logic ip_matches;

    always_ff @ (posedge clk) begin
        if (rst) begin
            searching <= 0;
            lookup_mac_valid <= 0;
            lookup_current_bucket_depth <= 0;
            lookup_mac_not_found <= 0;
        end else begin
            last_data_douta <= data_douta;
            ip_matches <= data_douta[`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH-1:`MAC_WIDTH+`PORT_WIDTH] == lookup_ip;
            if (!searching && lookup_ip_valid) begin
                searching <= 1;
                lookup_current_bucket_depth <= 0;
                lookup_mac_valid <= 0;
                lookup_mac_not_found <= 0;
                lookup_mac <= 0;
                lookup_port <= 0;
            end else if (searching) begin
                if (!lookup_ip_valid) begin
                    searching <= 0;
                    lookup_mac_valid <= 0;
                    lookup_mac_not_found <= 0;
                    lookup_current_bucket_depth <= 0;
                    data_avail <= 1;
                end else if (!lookup_mac_valid && !lookup_mac_not_found) begin
                    if (data_avail) begin
                        data_avail <= 0;
                        if (ip_matches) begin
                            lookup_mac_valid <= 1;
                            lookup_mac <= data_douta[`MAC_WIDTH+`PORT_WIDTH-1:`PORT_WIDTH];
                            lookup_port <= data_douta[`PORT_WIDTH-1:0];
                        end
                    end else begin
                        if (lookup_current_bucket_depth != `BUCKET_DEPTH_COUNT - 1) begin
                            lookup_current_bucket_depth <= lookup_current_bucket_depth + 1;
                        end else begin
                            lookup_mac_not_found <= 1;
                        end
                        data_avail <= 1;
                    end
                end
            end

        end
    end

    logic [`BUCKET_INDEX_WIDTH-1:0] insert_bucket_index;
    logic [`BUCKET_DEPTH_WIDTH-1:0] insert_current_bucket_depth;
    assign insert_bucket_index = {insert_ip[31], insert_ip[30], insert_ip[29], insert_ip[28]};

    logic [`IPV4_WIDTH-1:0] saved_insert_ip;
    logic [`MAC_WIDTH-1:0] saved_insert_mac;
    logic [`PORT_WIDTH-1:0] saved_insert_port;
    logic first_pass;
    logic second_pass;
    logic [`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH-1:0] temp_data;

    assign data_addrb = {insert_bucket_index, insert_current_bucket_depth};

    logic [`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH-1:0] last_data_doutb;

    always_ff @ (posedge clk) begin
        last_data_doutb <= data_doutb;
        if (rst) begin
            saved_insert_ip <= 0;
            saved_insert_mac <= 0;
            insert_ready <= 1;
            saved_insert_ip <= 0;
            saved_insert_mac <= 0;
            saved_insert_port <= 0;
            insert_current_bucket_depth <= 0;
            first_pass <= 0;
            second_pass <= 0;
            data_dinb <= 0;
            data_web <= 0;
        end else if (insert_valid && insert_ready) begin
            insert_ready <= 0;
            saved_insert_ip <= insert_ip;
            saved_insert_mac <= insert_mac;
            saved_insert_port <= insert_port;
            insert_current_bucket_depth <= 0;
            first_pass <= 1;
            second_pass <= 0;
            data_dinb <= 0;
            data_web <= 0;
        end else if (!insert_ready) begin
            if (first_pass) begin
                data_dinb <= {saved_insert_ip, saved_insert_mac, saved_insert_port};
                if (last_data_doutb[`IPV4_WIDTH+`MAC_WIDTH+`PORT_WIDTH-1:`MAC_WIDTH+`PORT_WIDTH] == saved_insert_ip) begin
                    first_pass <= 0;
                    second_pass <= 0;
                    data_web <= 1;
                    insert_ready <= 1;
                    insert_current_bucket_depth <= insert_current_bucket_depth - 1;
                end else if (insert_current_bucket_depth != `BUCKET_DEPTH_COUNT - 1) begin
                    insert_current_bucket_depth <= insert_current_bucket_depth + 1;
                    data_web <= 0;
                end else begin
                    first_pass <= 0;
                    second_pass <= 1;
                    insert_current_bucket_depth <= 0;
                    data_web <= 1;
                end
            end else if (second_pass) begin
                if (insert_current_bucket_depth != `BUCKET_DEPTH_COUNT - 1) begin
                    data_dinb <= data_doutb;
                    data_web <= 1;
                    insert_current_bucket_depth <= insert_current_bucket_depth + 1;
                end else begin
                    data_dinb <= data_doutb;
                    data_web <= 1;
                    second_pass <= 0;
                    insert_ready <= 1;
                end
            end
        end else begin
            data_dinb <= 0;
            data_web <= 0;
        end
    end
endmodule
