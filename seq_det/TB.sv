// Code your testbench here
// or browse Examples
class transaction;
  randc bit d_in;
  bit out;
  bit reset;
  
  function void display();
    $display("data in: %0d, out: %0d",d_in, out);
  endfunction
  
endclass

class generator;
  transaction tr;
  mailbox #(transaction) mbx;
  int count;
  event next;
  event done;
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction
  
  task run();
    repeat(count)
      begin
        tr = new();
        assert(tr.randomize);
        else
        $display("randomization failed");
        tr.display();
        mbx.put(tr);
        @(next);
      end
    ->done;
  endtask
endclass

class driver;
  transaction tr;
  virtual intf inf;
  mailbox #(transaction) mbx;
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction
  
  task reset();
   inf.reset <= 1'b0;
   repeat(5) @(posedge inf.clk);
   inf.reset <= 1'b1;
    $display("reset done");
  endtask
   
  task run();
    begin
      forever begin
       mbx.get(tr);
      end
    end
    
  endtask
      
endclass
      
class monitor;
  transaction tr;
  mailbox #(transaction) mbx;
  generator gen;
  driver drv;
   virtual intf inf;
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction
  
  task run();
    tr = new();
    repeat(2);
    tr.reset <= inf.reset;
    tr.d_in <= inf.d_in;
    tr.out <= inf.out;
    mbx.put();
    tr.display();
  endtask
endclass

class scoreboard;
  transaction tr;
  mailbox #(transaction) mbx;
  virtual intf inf;
  event next;
  bit mem[$];
  
  function new(mailbox #(transaction)mbx);
    this.mbx = mbx;
  endfunction
  
  task run();
    forever begin
     mbx.get();
      mem.push_front(tr.d_in);
      if(vif.out == 1'b1)
        $display("sequence matched");
      else
        $display("match not found");
      ->next;
    end
  endtask
endclass

class env;
  generator gen;
  driver drv;
  scoreboard sco;
  monitor mon;
  transaction tr;
  virtual intf inf;
  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxms;
  
  function new(intf inf);
    mbxgd = new();
    mbxms = new();
    gen = new(mbxgd);
    drv = new(mbxgd);
    mon = new(mbxmd);
    sco = new(mbxms);
    gen.next = next;
    sco.next = next;    
  endfunction 
  
  task pre_test();
    drv.reset();
  endtask
  
  task test();
    fork
      drv.run();
      gen.run();
      mon.run();
      sco.run();
    join_any
  endtask
  
  task post_test();
    wait(gen.done.triggered);
    $finish();
  endtask
  
  task run();
    pre_test();
    test();
    post_test();
  endtask
  
endclass

module tb;
  env e;
  intf inf();
  
  seq_det dut(inf.d_in, inf.d_in, inf.clk, inf.reset, inf.out);
  
  always #5 inf.clk = ~inf.clk;
  
  initial begin
    e = new();
    inf.clk = 1'b0;
    e.gen.count = 10;
    e.run();
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
    
endmodule
    
