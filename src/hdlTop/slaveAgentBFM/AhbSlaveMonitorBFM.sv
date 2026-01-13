`ifndef AHBSLAVEMONITORBFM_INCLUDED_
`define AHBSLAVEMONITORBFM_INCLUDED_

import AhbGlobalPackage::*;

interface AhbSlaveMonitorBFM (input  bit   hclk,
                              input  bit  hresetn,
                              input logic [2:0] hburst,
                              input logic hmastlock,
                              input logic [ADDR_WIDTH-1:0] haddr,
                              input logic [HPROT_WIDTH-1:0] hprot,
                              input logic [2:0] hsize,
                              input logic hnonsec,
                              input logic hexcl,
                              input logic [HMASTER_WIDTH-1:0] hmaster,
                              input logic [1:0] htrans,
                              input logic [DATA_WIDTH-1:0] hwdata,
                              input logic [(DATA_WIDTH/8)-1:0]hwstrb,
                              input logic hwrite,
                              input logic [DATA_WIDTH-1:0] hrdata,
                              input logic hreadyout,
                              input logic hresp,
                              input logic hexokay,
                              input logic hready,
                              /* input logic [NO_OF_SLAVES-1:0]hselx */
															input logic hselx
                             );


  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import AhbSlavePackage::*;

  string name = "AHB_SLAVE_MONITOR_BFM";

  AhbSlaveMonitorProxy ahbSlaveMonitorProxy;

  initial begin
    `uvm_info(name,$sformatf(name),UVM_LOW);
  end

  task waitForResetn();
   @(negedge hresetn);
    `uvm_info(name, $sformatf("SYSTEM_RESET_DETECTED"), UVM_HIGH)

    @(posedge hresetn);
    `uvm_info(name, $sformatf("SYSTEM_RESET_DEACTIVATED"), UVM_HIGH)
  endtask : waitForResetn

 task slaveSampleData (output ahbTransferCharStruct ahbDataPacket, input ahbTransferConfigStruct ahbConfigPacket);

        @(posedge hclk);
        
        while(hreadyout !=1 && hresp==1 && htrans == IDLE) begin
            `uvm_info(name, $sformatf("Inside while loop HREADY"), UVM_HIGH)
      @(posedge hclk);
    end

    ahbDataPacket.hselx  = hselx;
    ahbDataPacket.haddr  = haddr;
    ahbDataPacket.hburst = ahbBurstEnum'(hburst);
    ahbDataPacket.hwrite = ahbOperationEnum'(hwrite);
    ahbDataPacket.hsize  = ahbHsizeEnum'(hsize);
    ahbDataPacket.htrans = ahbTransferEnum'(htrans);
    ahbDataPacket.hnonsec = hnonsec;
    ahbDataPacket.hprot  = ahbProtectionEnum'(hprot);
    ahbDataPacket.hresp  = ahbRespEnum'(hresp);
    ahbDataPacket.hreadyout = hreadyout;

        if(hwrite) begin
      ahbDataPacket.hwdata = hwdata;
      ahbDataPacket.hwstrb  = hwstrb;
    end
    else
      ahbDataPacket.hrdata = hrdata;
		
  endtask : slaveSampleData

endinterface : AhbSlaveMonitorBFM

`endif


/* `ifndef AHBSLAVEMONITORBFM_INCLUDED_ */
/* `define AHBSLAVEMONITORBFM_INCLUDED_ */

/* import AhbGlobalPackage::*; */

/* interface AhbSlaveMonitorBFM (input  bit   hclk, */
/*                               input  bit   hresetn, */
/*                               input logic [2:0] hburst, */
/*                               input logic hmastlock, */
/*                               input logic [ADDR_WIDTH-1:0] haddr, */
/*                               input logic [HPROT_WIDTH-1:0] hprot, */
/*                               input logic [2:0] hsize, */
/*                               input logic hnonsec, */
/*                               input logic hexcl, */
/*                               input logic [HMASTER_WIDTH-1:0] hmaster, */
/*                               input logic [1:0] htrans, */
/*                               input logic [DATA_WIDTH-1:0] hwdata, */
/*                               input logic [(DATA_WIDTH/8)-1:0]hwstrb, */
/*                               input logic hwrite, */
/*                               input logic [DATA_WIDTH-1:0] hrdata, */
/*                               input logic hreadyout, */
/*                               input logic hresp, */
/*                               input logic hexokay, */
/*                               input logic hready, */
/*                               input logic hselx */
/*                              ); */


/*   import uvm_pkg::*; */
/*   `include "uvm_macros.svh" */

/*   import AhbSlavePackage::*; */

/*   string name = "AHB_SLAVE_MONITOR_BFM"; */

/*   AhbSlaveMonitorProxy ahbSlaveMonitorProxy; */

/*   // --------------------------------------------------------- */
/*   // INTERNAL PIPELINE REGISTERS */
/*   // These variables store the Control Signals from the Address Phase */
/*   // so they can be used in the Data Phase (Next Cycle). */
/*   // --------------------------------------------------------- */
/*   ahbOperationEnum piped_hwrite; */
/*   logic            piped_hselx; */

/*   initial begin */
/*     `uvm_info(name,$sformatf(name),UVM_LOW); */
/*   end */

/*   always @(posedge hclk) begin */
/*      if (hresetn == 0) begin */
/*          piped_hwrite <= READ; */
/*          piped_hselx  <= 1'b0; */
/*      end */
/*      // CHANGED: Removed "else if (hready)" check. */
/*      // We capture on every clock. If HREADY=0 (Wait), the bus is stable, */ 
/*      // so we just capture the same valid value again. This is safe. */
/*      else begin */
/*          piped_hwrite <= ahbOperationEnum'(hwrite); */
/*          piped_hselx  <= hselx; */
/*      end */
/*   end */

/*   task waitForResetn(); */
/*     @(negedge hresetn); */
/*     `uvm_info(name, $sformatf("SYSTEM_RESET_DETECTED"), UVM_HIGH) */

/*     @(posedge hresetn); */
/*     `uvm_info(name, $sformatf("SYSTEM_RESET_DEACTIVATED"), UVM_HIGH) */
/*   endtask : waitForResetn */

/*   task slaveSampleData (output ahbTransferCharStruct ahbDataPacket, input ahbTransferConfigStruct ahbConfigPacket); */

/*     @(posedge hclk); */

/*     // Wait for Data Phase to complete (Ready=1, Resp=OKAY) */
/*     // Note: We check hreadyout (Slave Ready) */
/*     while(hreadyout !=1 && hresp==1 && htrans == IDLE) begin */
/*         `uvm_info(name, $sformatf("Inside while loop HREADY"), UVM_HIGH) */
/*         @(posedge hclk); */
/*     end */

/*     // ----------------------------------------------------------- */
/*     // CAPTURE SIGNALS */
/*     // Use LIVE values for data, but PIPED values for control decision */
/*     // ----------------------------------------------------------- */

/*     // We capture live address/control for the packet fields */
/*     // (Note: Ideally these should also be piped, but for your current */
/*     // Scoreboard logic, getting the data correct is the priority) */
/*     ahbDataPacket.hselx   = hselx; */
/*     ahbDataPacket.haddr   = haddr; */
/*     ahbDataPacket.hburst  = ahbBurstEnum'(hburst); */
/*     ahbDataPacket.hwrite  = ahbOperationEnum'(hwrite); */
/*     ahbDataPacket.hsize   = ahbHsizeEnum'(hsize); */
/*     ahbDataPacket.htrans  = ahbTransferEnum'(htrans); */
/*     ahbDataPacket.hnonsec = hnonsec; */
/*     ahbDataPacket.hprot   = ahbProtectionEnum'(hprot); */

/*     ahbDataPacket.hresp     = ahbRespEnum'(hresp); */
/*     ahbDataPacket.hreadyout = hreadyout; */

/*     // ----------------------------------------------------------- */
/*     // FIX: Check the PIPED direction (stored from previous cycle) */
/*     // This remembers "I am in a Write Data Phase" even if hwrite is now 0 */
/*     // ----------------------------------------------------------- */
/*     if(piped_hwrite == WRITE && piped_hselx == 1) begin */
/*        ahbDataPacket.hwdata = hwdata; */
/*        ahbDataPacket.hwstrb = hwstrb; */
/*     end */
/*     else begin */
/*        ahbDataPacket.hrdata = hrdata; */
/*     end */

/*   endtask : slaveSampleData */

/* endinterface : AhbSlaveMonitorBFM */

/* `endif */
