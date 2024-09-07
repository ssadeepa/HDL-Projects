`timescale 1ns / 1ps 
 
module uart_comm(
    input clk_in,
    input tx_start,
    input [7:0] tx_data_in,
    output reg tx_out, 
    input rx_in,
    output [7:0] rx_data_out,
    output rx_done_flag, 
    output tx_done_flag
    );
    
 parameter sys_clk_freq = 100_000;
 parameter baud_rate = 9600;
 
 parameter bit_period = sys_clk_freq / baud_rate;
 
 reg bit_ready = 0;
 integer clk_counter = 0;
 parameter IDLE = 0, TX = 1, TX_CHECK = 2;
 reg [1:0] tx_state = IDLE;
 
/////////////////// Clock Divider for Baud Rate Generation
 always@(posedge clk_in)
 begin
  if(tx_state == IDLE)
    begin 
    clk_counter <= 0;
    end
  else begin
    if(clk_counter == bit_period)
       begin
        bit_ready <= 1'b1;
        clk_counter <= 0;  
       end
    else
       begin
       clk_counter <= clk_counter + 1;
       bit_ready <= 1'b0;  
      end    
  end
 
 end
 
 /////////////////////// Transmit (TX) Logic
 reg [9:0] tx_shift_data; // 1 start bit, 8 data bits, 1 stop bit
 integer tx_bit_idx = 0; 
 reg [9:0] tx_shift_reg = 0;
 
 
 always@(posedge clk_in)
 begin
 case(tx_state)
 IDLE : 
     begin
           tx_out    <= 1'b1;  // Idle line high
           tx_shift_data <= 0;
           tx_bit_idx <= 0;
           tx_shift_reg  <= 0;
           
           if(tx_start == 1'b1)
              begin
                tx_shift_data <= {1'b1, tx_data_in, 1'b0}; // Load data with start and stop bits
                tx_state  <= TX;
              end
           else
              begin           
               tx_state <= IDLE;
              end
     end
 
  TX: begin
           tx_out   <= tx_shift_data[tx_bit_idx]; // Shift out bits
           tx_state <= TX_CHECK;
           tx_shift_reg  <= {tx_shift_data[tx_bit_idx], tx_shift_reg[9:1]};
  end 
  
  TX_CHECK: 
  begin    
      if(tx_bit_idx <= 9)  // Check if all bits are transmitted
        begin
          if(bit_ready == 1'b1)
            begin
            tx_state <= TX;
            tx_bit_idx <= tx_bit_idx + 1;
            end
        end
      else
        begin
        tx_state <= IDLE;
        tx_bit_idx <= 0;
        end
  end
 
 default: tx_state <= IDLE;
 
 endcase
 
 end
 
assign tx_done_flag = (tx_bit_idx == 9 && bit_ready == 1'b1) ? 1'b1 : 1'b0;
 
 //////////////////////////////// Receive (RX) Logic
 integer rx_clk_counter = 0;
 integer rx_bit_idx = 0;
 parameter RX_IDLE = 0, RX_WAIT = 1, RX = 2, RX_CHECK = 3;
 reg [1:0] rx_state;
 reg [9:0] rx_shift_data;
 always@(posedge clk_in)
 begin
 case(rx_state)
 RX_IDLE : 
     begin
      rx_shift_data <= 0;
      rx_bit_idx <= 0;
      rx_clk_counter <= 0;
        
      if(rx_in == 1'b0) // Start bit detected
        begin
         rx_state <= RX_WAIT;
        end
      else
        begin
        rx_state <= RX_IDLE;
        end
     end
     
RX_WAIT : 
begin
      if(rx_clk_counter < bit_period / 2) // Wait for half of the bit period to sample in the middle
        begin
          rx_clk_counter <= rx_clk_counter + 1;
          rx_state <= RX_WAIT;
        end
      else
        begin
          rx_clk_counter <= 0;
          rx_state <= RX;
          rx_shift_data <= {rx_in, rx_shift_data[9:1]}; 
        end
end
 
 
RX : 
begin
     if(rx_bit_idx <= 9) // Receive all bits including start and stop bits
      begin
      if(bit_ready == 1'b1) 
        begin
        rx_bit_idx <= rx_bit_idx + 1;
        rx_state <= RX_WAIT;
        end
      end
      else
        begin
        rx_state <= RX_IDLE;
        rx_bit_idx <= 0;
        end
end

 
default : rx_state <= RX_IDLE;
 
 
 endcase
 end
 
 
assign rx_data_out = rx_shift_data[8:1]; // Extract 8-bit data
assign rx_done_flag = (rx_bit_idx == 9 && bit_ready == 1'b1) ? 1'b1 : 1'b0;
 
 
 endmodule
