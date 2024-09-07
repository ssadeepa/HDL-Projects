module uart_tb;

    reg clk_in = 0;
    reg tx_start = 0;
    reg [7:0] tx_data_in;
    wire [7:0] rx_data_out;
    wire rx_done_flag, tx_done_flag;
   
    wire tx_rx_wire;
   
    // Instantiate the uart_comm module
    uart_comm uut (
        .clk_in(clk_in), 
        .tx_start(tx_start), 
        .tx_data_in(tx_data_in), 
        .tx_out(tx_rx_wire), 
        .rx_in(tx_rx_wire), 
        .rx_data_out(rx_data_out), 
        .rx_done_flag(rx_done_flag), 
        .tx_done_flag(tx_done_flag)
    );
    
    integer idx = 0;
 
    initial 
    begin
        tx_start = 1;
        for(idx = 0; idx < 10; idx = idx + 1) 
        begin
            tx_data_in = $urandom_range(10 , 200); // Send random values within range
            @(posedge rx_done_flag);  // Wait for receive to complete
            @(posedge tx_done_flag);  // Wait for transmit to complete
        end
        $stop;  // End simulation
    end
 
    // Clock generation
    always #5 clk_in = ~clk_in;
 
endmodule
