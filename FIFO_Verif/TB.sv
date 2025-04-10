class transaction;
  bit wr_rd;
  bit [7:0]data_in;
  bit reset;
  bit [7:0] data_out;
  bit full,empty;
  rand bit oper;
  
  constraint c1{
    oper dist {1 :/ 50 , 0 :/ 50};
  }
  
  function void display();
    $display("data_in : %0d, data_out: %0d, wr_rd: %0b",data_in, data_out, wr_rd);
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
    repeat(count) begin
      tr = new();
      assert(tr.randomize)
      $display("randomization successful");
      else $display("randomization failed");
      tr.display();
      @(next);
    end
   ->done;
  endtask
endclass


class driver;
  transaction tr;
  virtual intf inf;
  mailbox #(transaction) mbx;
  
  function new(virtual intf inf, mailbox #(transaction) mbx);
  this.inf = inf;
  this.mbx = mbx;
endfunction
  
  task reset();
    inf.reset <= 1'b0;
    inf.data_in <= 8'b0;
    inf.wr_rd <= 1'b0;
    repeat(5)
    @(posedge inf.clk);
    inf.reset <= 1'b1;
    $display("reset done");
  endtask
      
  task write();
    @(posedge inf.clk);
    inf.wr_rd <= 1'b1;
    inf.reset <= 1'b1;
    inf.data_in <= $urandom_range(1,50);
    $display("DRV: received data: wr_rd = %0d, data_in = %0d", inf.wr_rd,inf.data_in);
    @(posedge inf.clk);
  endtask
  
  task read();
    @(posedge inf.clk);
    inf.wr_rd <= 1'b0;
    inf.reset <= 1'b1;
    $display("DRV: read operation");
    @(posedge inf.clk);
  endtask
  
  task run();
    forever begin
      mbx.get(tr);
      if(tr.oper == 1'b1)
        write();
      else
        read();
    end
  endtask
endclass

class monitor;
  
  transaction tr;
  virtual intf inf;
  generator gen;
  driver drv;
  mailbox #(transaction) mbx;
  
  function new(virtual intf inf, mailbox #(transaction) mbx);
  this.inf = inf;
  this.mbx = mbx;
endfunction
  
  task run();
    tr = new();
    repeat(2)
    tr.wr_rd = inf.wr_rd;
    tr.data_in = inf.data_in;
    tr.reset = inf.reset;
    tr.full = inf.full;
    tr.empty = inf.empty;
    @(posedge inf.clk);
    tr.data_out = inf.data_out;
    mbx.put(tr);
    $display("wr_rd: %0d, data_in: %0d, data_out: %0d, full: %0d, empty: %0d", tr.wr_rd, tr.data_in, tr.data_out, tr.full, tr.empty);
    
  endtask
  
endclass


class scoreboard;
  transaction tr;
  mailbox #(transaction) mbx;
  event next;
  bit [7:0]que[$];
  bit [7:0]temp;
  int err;
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction
  
  task run();
    forever begin
     mbx.get(tr);
    if(tr.wr_rd == 1'b1)
     begin
       if(tr.full == 1'b0)
         begin
           que.push_front(tr.data_in);
           $display("pushed data :%0d",tr.data_in);
         end
       else
         $display("FIFO is full");
     end
      else if(tr.wr_rd == 1'b0) begin
        if(tr.empty == 1'b0) begin
          temp = que.pop_back();
          if(tr.data_out == temp)
            $display("DATA MATCH");
          else
            $error("DATA MISMATCH");
            err++;
        end
        else
          $display("FIFO is empty");
     end
      -> next;
      end
    
  endtask
endclass


class env;
  
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  transaction tr;
  event nextgs;
  
        
  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxms;
  virtual intf inf;
  
  function new(virtual intf inf);
    mbxgd = new();
    mbxms = new();
    gen = new(mbxgd);
    drv = new(inf,mbxgd);
    mon = new(inf,mbxms);
    sco = new(mbxms);
    gen.next = nextgs;
    sco.next = nextgs;
  endfunction
  
  task pre_test();
     drv.reset();
  endtask
  
  task test();
   fork 
     gen.run();
     drv.run();
     mon.run();
     sco.run();
   join_any
  endtask
  
  task post_test();
    
    wait(gen.done.triggered);
    $display("error count: %0d",sco.err);
    $finish();
  endtask
  
    
  task run();
    pre_test();
    test();
    post_test();
  endtask
  
endclass




module tb;
  intf inf();
  env e;
  
  Sync_FF dut(inf.wr_rd, inf.data_in, inf.reset, inf.clk, inf.data_out, inf.full, inf.empty);
  initial begin
    inf.clk <= 1'b0;
  end
  
  always #5 inf.clk <= ~inf.clk;
  
  initial begin
    e = new(inf);
    e.gen.count = 10;
    
    e.run();
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
    
endmodule
