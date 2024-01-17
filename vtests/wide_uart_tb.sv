`timescale 1ns/1ps

module wide_uart_tb();

logic clk;
logic rst;

logic [63:0]    s_axis_tdata;
logic           s_axis_tvalid;
logic           s_axis_tready;

logic [63:0]    m_axis_tdata;
logic           m_axis_tvalid;
logic           m_axis_tready;

logic RsRx;
logic RsTx;


wide_uart DUT (
    .clk,
    .rst,

    .s_axis_tdata,
    .s_axis_tvalid,
    .s_axis_tready,

    .m_axis_tdata,
    .m_axis_tvalid,
    .m_axis_tready,

    .RsRx,
    .RsTx

);

//loop UART onto itself
assign RsRx = RsTx;

//toggle the clock
always #5 clk <= ~clk;

task initialize();
    clk = 'h0;
    rst = 'h1;

    s_axis_tdata = 'h0;
    s_axis_tvalid = 'h0;
    m_axis_tready = 'h0;
    
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

    assert(m_axis_tdata == 64'hfeedfacedeadbeef) else $fatal(1, "bad Rx");
    
    @(posedge clk);

    $display("@@@Passed");

    $finish;
end

endmodule
