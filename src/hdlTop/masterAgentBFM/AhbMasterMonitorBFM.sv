`ifndef AHBMASTERMONITORBFM_INCLUDED_
`define AHBMASTERMONITORBFM_INCLUDED_

import AhbGlobalPackage::*;

interface AhbMasterMonitorBFM(input  bit   hclk,
                              input  bit  hresetn,
                              input logic [ADDR_WIDTH-1:0] haddr,
                              input logic [NO_OF_SLAVES-1:0] hselx,
                              input logic [2:0] hburst,
                              input logic hmastlock,
                              input logic [HPROT_WIDTH-1:0] hprot,
                              input logic [2:0] hsize,
                              input logic hnonsec,
                              input logic hexcl,
                              input logic [HMASTER_WIDTH-1:0] hmaster,
                              input logic [1:0] htrans,
                              input logic [DATA_WIDTH-1:0] hwdata,
                              input logic [(DATA_WIDTH/8)-1:0] hwstrb,
                              input logic hwrite,
                              input logic [DATA_WIDTH-1:0] hrdata,
                              input logic hreadyout,
                              input logic hresp,
                              input logic hexokay,
                              input logic hready
                             );

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import AhbMasterPackage::*;

  AhbMasterMonitorProxy ahbMasterMonitorProxy;

  string name = "AHB_MASTER_MONITOR_BFM"; 

  clocking SlaveMonitorCb @(posedge hclk);
   default input #1step output #1step;
   input hselx,haddr,hburst,hmastlock,hprot,hsize,hnonsec,hexcl,hmaster,htrans,hwdata,hwstrb,hwrite,hrdata,hreadyout,hresp,hexokay,hready;
  endclocking
 
  initial begin
    `uvm_info(name, $sformatf("AHB MASTER MONITOR BFM"), UVM_LOW);
  end

  task waitForResetn();
    @(negedge hresetn);
    `uvm_info(name, $sformatf("system reset detected"), UVM_HIGH)
    @(posedge hresetn);
    `uvm_info(name, $sformatf("system reset deactivated"), UVM_HIGH)
  endtask : waitForResetn
/*
  task sampleData (output ahbTransferCharStruct ahbDataPacket, input ahbTransferConfigStruct ahbConfigPacket);
    
    @(posedge hclk);

  while(hready !== 1 && hresp == 1 && htrans == IDLE) begin
      //`uvm_info(name, $sformatf("Inside while loop: hresp =%0d, hready=%0d, hselx=%0d", hresp, hready, hselx), UVM_LOW)
      @(posedge hclk);
      ahbDataPacket.noOfWaitStates++;
    end

    ahbDataPacket.haddr = haddr;
    ahbDataPacket.hwrite  = ahbOperationEnum'(hwrite);
    ahbDataPacket.hsize   = ahbHsizeEnum'(hsize);
    ahbDataPacket.hburst  = ahbBurstEnum'(hburst);
    ahbDataPacket.htrans  = ahbTransferEnum'(htrans);
    ahbDataPacket.hmastlock = hmastlock;
    ahbDataPacket.hready = hready;
    ahbDataPacket.hresp = ahbRespEnum'(hresp);
    //ahbDataPacket.hselx = hselx;
    ahbDataPacket.hprot = ahbProtectionEnum'(hprot);
    ahbDataPacket.hwstrb = hwstrb;

    if (hwrite == 1) begin
      ahbDataPacket.hwdata = hwdata;
    end
    else begin
      ahbDataPacket.hrdata = hrdata;
    end
  endtask : sampleData
*/
  task sampleData (output ahbTransferCharStruct ahbDataPacket, input ahbTransferConfigStruct ahbConfigPacket);

    // static variables remember the previous cycle's address phase signals
   static logic [NO_OF_SLAVES-1:0] prev_hselx = 0;
    static logic [ADDR_WIDTH-1:0]   prev_haddr = 0;
    static logic [2:0]              prev_hburst = 0;
    static logic                    prev_hwrite = 0;
    static logic [2:0]              prev_hsize = 0;
    static logic [1:0]              prev_htrans = 0;
    static logic                    prev_hnonsec = 0;
    static logic [HPROT_WIDTH-1:0]  prev_hprot = 0;

    @(SlaveMonitorCb);
    //while(hreadyout !== 1'b1)begin
    while(SlaveMonitorCb.hready !== 1'b1 && SlaveMonitorCb.htrans !== 2'b00) begin//added
      @(SlaveMonitorCb);
    end

    ahbDataPacket.hselx   = prev_hselx;
    ahbDataPacket.haddr   = prev_haddr;
        $display("ishika %0t haddr = %0h",$time,ahbDataPacket.haddr);
    ahbDataPacket.hburst  = ahbBurstEnum'(prev_hburst);
    ahbDataPacket.hwrite  = ahbOperationEnum'(prev_hwrite);
    ahbDataPacket.hsize   = ahbHsizeEnum'(prev_hsize);
    ahbDataPacket.hnonsec = prev_hnonsec;
    ahbDataPacket.hprot   = ahbProtectionEnum'(prev_hprot);

    //if (prev_hselx === 1'b0) begin
    if (prev_hselx === 1'b0 || $isunknown(prev_haddr)) begin
      ahbDataPacket.htrans = ahbTransferEnum'(0);
    end else begin
      ahbDataPacket.htrans = ahbTransferEnum'(prev_htrans);
    end

    ahbDataPacket.hresp     = ahbRespEnum'(SlaveMonitorCb.hresp);
    ahbDataPacket.hreadyout = SlaveMonitorCb.hreadyout;

    if(prev_hwrite) begin
      ahbDataPacket.hwdata = SlaveMonitorCb.hwdata;
      ahbDataPacket.hwstrb = SlaveMonitorCb.hwstrb;
    end
    else begin
      ahbDataPacket.hrdata = SlaveMonitorCb.hrdata;

    end

    // Save the current address phase signals for the next cycle's data phase
    prev_hselx   = SlaveMonitorCb.hselx;
    prev_haddr   = SlaveMonitorCb.haddr;
    prev_hburst  = SlaveMonitorCb.hburst;
    prev_hwrite  = SlaveMonitorCb.hwrite;
    prev_hsize   = SlaveMonitorCb.hsize;
    prev_htrans  = SlaveMonitorCb.htrans;
    prev_hnonsec = SlaveMonitorCb.hnonsec;
    prev_hprot   = SlaveMonitorCb.hprot;

$display("[%0t] from master monitor = haddr=%0d",$time,prev_haddr);

  endtask : sampleData

endinterface : AhbMasterMonitorBFM

`endif
