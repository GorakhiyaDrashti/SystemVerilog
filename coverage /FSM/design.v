// Code your design here
module fsm(
input din, clock, reset,
  output reg dout);
  
  reg state, nstate;
  parameter s0 = 0,
            s1 = 1;
  
  always @(posedge clock or negedge reset) begin
    if(reset)
      state <= s0;
  else 
    state <= nstate;
  end
  
  always @(state or din) begin
    dout <= 0;
    case(state)
      s0: 
        if(din)  begin
          nstate <= s1;
          dout <= 0;
        end
      else begin
        nstate <= s0;
        dout <= 0;
      end
      s1: 
        if(din) begin
          nstate <= s0;
          dout <= 1;
        end
        else
          begin
            nstate <= s1;
            dout <= 0;
        end
      default:
        nstate <= s0;
    endcase
  end
  
endmodule
