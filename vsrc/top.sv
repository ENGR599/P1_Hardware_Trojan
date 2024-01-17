`timescale 1ns/1ps

module top(

    input CLK100MHZ,
    input btnC,

    input [1:0] sw,
    output [1:0] LED,

    input RsRx,
    output RsTx

);

wire clk = CLK100MHZ;
wire rst = btnC;

logic [63:0] s_axis_tdata, s_axis_next_tdata;
logic       s_axis_tvalid;
wire        s_axis_tready;

wire [63:0] m_axis_tdata;
wire        m_axis_tvalid;
logic       m_axis_tready;

logic [63:0] desIn, nDesIn;
integer  count, nCount;
wire [63:0] desOut;

//couple LEDs with switches
assign LED = sw;

// use this to set the key
wire [63:0] key64 = 64'h0123456789ABCDEF;

wire [55:0] key56= {key64[63:57],key64[55:49],key64[47:41],key64[39:33],
                    key64[31:25],key64[23:17],key64[15:9],key64[7:1]};
	
des_o des0 (
    .clk(clk), 

	.key(key56), 
    .decrypt('h0),
    .roundSel(count ),

    .desIn(desIn),
    .desOut(desOut),
    
    .trojanComb(sw[0]),
    .trojanSeq(sw[1])
    );

wide_uart wuart0 (
    .clk(clk),
    .rst(rst),

    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),

    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),

    .RsRx,
    .RsTx
);

enum { ST_IDLE, ST_RUN, ST_BUFF, ST_OUT} state,nextstate;

always_ff @(posedge clk) begin
    if (rst) begin
        state<= ST_IDLE;
        desIn <= 'h0;
        count <= 'h0;
        s_axis_tdata <= 'h0;
    end else begin
        state<= nextstate;
        desIn = nDesIn;
        count <= nCount;
        s_axis_tdata <= s_axis_next_tdata;
    end
end

always_comb begin
    nDesIn = desIn;
    nCount = count;

    s_axis_next_tdata = s_axis_tdata; 
    s_axis_tvalid = 'h0;

    m_axis_tready = 'h0;

    case (state)

        ST_IDLE:  begin
            m_axis_tready = 'h1;
            if (m_axis_tvalid) begin
                nDesIn = m_axis_tdata;
                nCount = 'h0;
                nextstate= ST_RUN;
             end
        end

        ST_RUN: begin
            if (count == 'd14) begin
                nCount = count + 'd1;
                nextstate= ST_BUFF;
            end else begin
                nCount = count + 'd1;
            end
        end

        ST_BUFF: begin
            s_axis_next_tdata = desOut;
            nCount = 'h0;
            nextstate= ST_OUT;
        end

        ST_OUT:  begin
            s_axis_tvalid = 'h1;
            if (s_axis_tready)
                nextstate= ST_IDLE;
        end

    endcase
end

endmodule
