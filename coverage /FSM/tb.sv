// Code your testbench here
// or browse Examples
module tb;
  
 reg clock = 0;
  reg reset = 0;
  reg din = 0;
  wire dout;
  
  covergroup c1;
    option.per_instance = 1;
    coverpoint dut.state;
       
  endgroup
  
  fsm dut (din,clock,reset,dout);
  
  always #5 clock = ~clock;
  
  initial begin
    reset = 1;
    #30;
    reset = 0;
    #40;
    din = 1;
  end
  c1 cia;
  
  initial begin
    cia = new();
    for(int i =0;i<10;i++) begin
      cia.sample();
      #20;
    end
  end
  
  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars;
    #200;
    $finish();
  end
  
endmodule
