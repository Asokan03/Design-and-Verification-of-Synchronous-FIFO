
module sync_fifo #(
    parameter FIFO_WIDTH = 8,
    parameter FIFO_DEPTH = 16,
    parameter PTR_SIZE   = $clog2(FIFO_DEPTH)
)(
    input  logic                   clk,
    input  logic                   rst_n,     // active LOW reset
    input  logic                   wr_n,      // active LOW write enable
    input  logic                   rd_n,      // active LOW read enable
    input  logic [FIFO_WIDTH-1:0]  data_in,

    output logic [FIFO_WIDTH-1:0]  data_out,
    output logic                   full,
    output logic                   empty,
    output logic                   over_flow,
    output logic                   under_flow
);

    // INTERNAL SIGNALS
  
    logic [FIFO_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0];
    logic [PTR_SIZE-1:0]   write_ptr, read_ptr;
    logic [PTR_SIZE:0]     fifo_status; // can count up to DEPTH

    logic write, read;

    assign write = (!wr_n && !full);
    assign read  = (!rd_n && !empty);

    // WRITE LOGIC
  
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= '0;
        end
        else if (write) begin
            fifo_mem[write_ptr] <= data_in;

            if (write_ptr == FIFO_DEPTH-1)
                write_ptr <= '0;
            else
                write_ptr <= write_ptr + 1'b1;
        end
    end

    // READ LOGIC
   
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_ptr <= '0;
            data_out <= '0;
        end
        else if (read) begin
            data_out <= fifo_mem[read_ptr];

            if (read_ptr == FIFO_DEPTH-1)
                read_ptr <= '0;
            else
                read_ptr <= read_ptr + 1'b1;
        end
    end

    // STATUS COUNTER (CORE LOGIC)
  
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_status <= '0;
        end
        else begin
            case ({write, read})
                2'b10: fifo_status <= fifo_status + 1'b1; // write only
                2'b01: fifo_status <= fifo_status - 1'b1; // read only
                2'b11: fifo_status <= fifo_status;        // both
                default: fifo_status <= fifo_status;      // idle
            endcase
        end
    end

    // FLAG LOGIC
  
    assign full  = (fifo_status == FIFO_DEPTH);
    assign empty = (fifo_status == 0);

    // OVERFLOW / UNDERFLOW DETECTION
   
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            over_flow  <= 1'b0;
            under_flow <= 1'b0;
        end
        else begin
            // detect illegal attempts
            over_flow  <= (!wr_n && full);
            under_flow <= (!rd_n && empty);
        end
    end

endmodule
