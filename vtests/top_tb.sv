`timescale 1ns/1ps

module top_tb();

logic clk;
logic rst;

logic [63:0]    s_axis_tdata;
logic           s_axis_tvalid;
logic           s_axis_tready;

logic [63:0]    m_axis_tdata;
logic           m_axis_tvalid;
logic           m_axis_tready;

logic RsRx;
wire RsTx;


wide_uart wuart0(
    .clk,
    .rst,

    .s_axis_tdata,
    .s_axis_tvalid,
    .s_axis_tready,

    .m_axis_tdata,
    .m_axis_tvalid,
    .m_axis_tready,

    .RsRx(RsTx), //other wide of uart
    .RsTx(RsRx) // so connections are swapped

);

top DUT(

    .CLK100MHZ(clk),
    .btnC(rst),

    .sw(2'h0),
    .LED(),

    .RsRx,
    .RsTx

);

//toggle the clock
// @ 100MHz
always #5 clk <= ~clk;

task initialize();
    clk = 'h0;
    rst = 'h1;
    
    #1;     
endtask

initial begin
    
    initialize();

    repeat(10) @(posedge clk);

    rst = 'h0;
    
    s_axis_tdata = 64'hfeedfacedeadbeef;
    s_axis_tvalid = 'h1;
    @(posedge clk);
    while (s_axis_tready != 'h1)
        @(posedge clk);
    s_axis_tvalid = 'h0;

    m_axis_tready = 'h1;
    @(posedge clk);
    while (m_axis_tvalid != 'h1)
        @(posedge clk);

    $display("recv: %h", m_axis_tdata);
    assert(m_axis_tdata == 64'h167c4586e73882e6) else $fatal(1, "bad Rx");
    
    @(posedge clk);
    
    //do the same thing again...
    s_axis_tdata = 64'hfeedfacedeadbeef;
    s_axis_tvalid = 'h1;
    @(posedge clk);
    while (s_axis_tready != 'h1)
        @(posedge clk);
    s_axis_tvalid = 'h0;

    m_axis_tready = 'h1;
    @(posedge clk);
    while (m_axis_tvalid != 'h1)
        @(posedge clk);

    $display("recv: %h", m_axis_tdata);
    assert(m_axis_tdata == 64'h167c4586e73882e6) else $fatal(1, "bad Rx");
 
    $display("@@@Passed");

    $finish;
end

endmodule
