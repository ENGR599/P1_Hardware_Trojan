`timescale 1ns/1ps

module wide_uart(
    input clk,
    input rst,

    input [63:0]        s_axis_tdata,
    input               s_axis_tvalid,
    output logic        s_axis_tready,

    output logic [63:0] m_axis_tdata,
    output logic        m_axis_tvalid,
    input               m_axis_tready,

    input               RsRx,
    output              RsTx
);


//Small Slave (sm_s) FSM / Interface
enum { SM_S_ST_RECV, SM_S_ST_BUFF} sm_s_state, sm_s_nextstate;

integer sm_s_count, sm_s_nextcount;

logic  [63:0]  sm_s_axis_buff, sm_s_axis_nextbuff;

logic  [7:0]  sm_s_axis_tdata;
logic         sm_s_axis_tvalid;
logic         sm_s_axis_tready;

// Small Master (sm_m) FSM / Interface

enum {SM_M_ST_BUFF, SM_M_ST_TX} sm_m_state, sm_m_nextstate;

integer     sm_m_count, sm_m_nextcount; 

logic  [63:0]    sm_m_axis_buff, sm_m_axis_nextbuff;

logic  [7:0]    sm_m_axis_tdata;
logic             sm_m_axis_tvalid;
logic             sm_m_axis_tready;

// UART signals
logic rx_busy;
logic tx_busy;

// Small Slave FSM 
always_ff @(posedge clk) begin
    if (rst) begin
        sm_s_state <= SM_S_ST_RECV;
        sm_s_count <= 'h0;
        sm_s_axis_buff <= 'h0;
    end else begin
        sm_s_state <= sm_s_nextstate;
        sm_s_count <= sm_s_nextcount;
        sm_s_axis_buff <=  sm_s_axis_nextbuff;
    end
end

always_comb begin
    sm_s_nextcount = sm_s_count;
    sm_s_axis_nextbuff = sm_s_axis_buff;

    s_axis_tready = (sm_s_count == 'h0);

    sm_s_axis_tdata = sm_s_axis_buff[sm_s_count +:8 ];
    sm_s_axis_tvalid = 'h0;

    case (sm_s_state)
        SM_S_ST_RECV: begin
            if ( s_axis_tvalid && s_axis_tready) begin
                sm_s_axis_nextbuff = s_axis_tdata;
                sm_s_nextstate = SM_S_ST_BUFF;
                sm_s_nextcount = 'h0;
            end
        end
        
        SM_S_ST_BUFF: begin
            sm_s_axis_tvalid = 'h1;
            if (sm_s_axis_tready) begin
                if (sm_s_count == 'd56) begin
                    sm_s_nextstate = SM_S_ST_RECV;
                    sm_s_nextcount = 'h0;
                end else begin
                    sm_s_nextcount = sm_s_count + 'd8;
                end
            end
        end
    endcase
end

// Small Master FSM

always_ff @(posedge clk) begin
    if (rst) begin
        sm_m_state <= SM_M_ST_BUFF;
        sm_m_count <= 'h0;
        sm_m_axis_buff <= 'h0;
    end else begin
        sm_m_state <= sm_m_nextstate;
        sm_m_count <= sm_m_nextcount;
        sm_m_axis_buff <=  sm_m_axis_nextbuff;
    end
end

always_comb begin
    
    sm_m_nextstate = sm_m_state; //fixme other states 
    sm_m_nextcount = sm_m_count; 
    sm_m_axis_nextbuff = sm_m_axis_buff; //fixme 

    m_axis_tvalid = 'h0;
    m_axis_tdata = sm_m_axis_buff;
    sm_m_axis_tready = (sm_m_state != SM_M_ST_TX); 

    case (sm_m_state) 
        SM_M_ST_BUFF: begin
            if (sm_m_axis_tvalid && sm_m_axis_tready) begin
                sm_m_axis_nextbuff[sm_m_count +:8 ] = sm_m_axis_tdata;
                if (sm_m_count == 'd56) begin
                    sm_m_nextstate = SM_M_ST_TX;
                    sm_m_nextcount = 'h0;
                end else begin
                    sm_m_nextcount = sm_m_count + 'd8;
                end
            end
        end

        SM_M_ST_TX: begin
            m_axis_tvalid = 'h1;
            if (m_axis_tready) begin
                sm_m_nextstate = SM_M_ST_BUFF;
            end
        end
    endcase

end

uart uart0 (
    .clk(clk),
    .rst(rst),

    .s_axis_tdata(sm_s_axis_tdata),
    .s_axis_tvalid(sm_s_axis_tvalid),
    .s_axis_tready(sm_s_axis_tready),

    .m_axis_tdata(sm_m_axis_tdata),
    .m_axis_tvalid(sm_m_axis_tvalid),
    .m_axis_tready(sm_m_axis_tready),

    .rxd(RsRx),
    .txd(RsTx),

    .tx_busy(tx_busy),
    .rx_busy(rx_busy),
    .rx_overrun_error(),
    .rx_frame_error(),

    .prescale(16'd1302)

);

endmodule
