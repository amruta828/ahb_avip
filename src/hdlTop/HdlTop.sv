`ifndef HDLTOP_INCLUDED
`define HDLTOP_INCLUDED

module HdlTop;


  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import AhbGlobalPackage::*;

  initial begin
    `uvm_info("HDL_TOP","HDL_TOP",UVM_LOW);
  end


  bit hclk;
  bit hresetn;
  //bit SLAVE_ID[NO_OF_SLAVES];
  //bit MASTER_ID[NO_OF_MASTERS];
/*
  initial begin 
    foreach(SLAVE_ID[i])
      SLAVE_ID[i] = i;
   
    foreach(MASTER_ID[i])
      MASTER_ID[i] = i;
  end 
*/
  initial begin
   hclk = 1'b0;
    forever #5 hclk =~hclk;
  end

  initial begin
  hresetn = 1'b1;
   @(posedge hclk) hresetn= 1'b0;

    //repeat(1) begin
      @(posedge hclk);
      $display("@%T H EY MAN",$time);
   // end
   hresetn = 1'b1;
  end


  AhbInterface ahbMasterInterface[0 : NO_OF_MASTERS-1](hclk,hresetn);
  AhbInterface ahbSlaveInterface[0:NO_OF_SLAVES-1](hclk,hresetn);
  AhbInterconnect ahbinterconnect(hclk,hresetn,ahbMasterInterface.ahbMasterinterconnectModport,ahbSlaveInterface.ahbSlaveinterconnectModport);
  
   
  
  genvar i;

  generate 
    for(i= 0 ; i < NO_OF_MASTERS ;i++) begin 
       AhbMasterAgentBFM#(.MASTER_ID(i)) ahbMasterAgentBFM(ahbMasterInterface[i]);
    end 
  endgenerate 
  genvar j;

  generate
    for(j=0; j< NO_OF_SLAVES;j++) begin
       AhbSlaveAgentBFM#(.SLAVE_ID(j)) ahbSlaveAgentBFM(ahbSlaveInterface[j]);
    end
  endgenerate

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, HdlTop); 
  end

endmodule : HdlTop

`endif
