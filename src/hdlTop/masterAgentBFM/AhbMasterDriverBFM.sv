`ifndef AHBMASTERDRIVERBFM_INCLUDED_
`define AHBMASTERDRIVERBFM_INCLUDED_

import AhbGlobalPackage::*;
interface AhbMasterDriverBFM (input  bit   hclk,
                              input  bit   hresetn,
                              output logic [ADDR_WIDTH-1:0] haddr,
                              output logic [2:0] hburst,
                              output logic hmastlock,
                              output logic [HPROT_WIDTH-1:0] hprot,
                              output logic [2:0] hsize,
                              output logic hnonsec,
                              output logic hexcl,
                              output logic [HMASTER_WIDTH-1:0] hmaster,
                              output logic [1:0] htrans,     
                              output logic hwrite,
                              output logic [DATA_WIDTH-1:0] hwdata,
                              output logic [(DATA_WIDTH/8)-1:0] hwstrb,
                              input  logic [DATA_WIDTH-1:0] hrdata,
                              input  logic hready,
                              input  logic hreadyout,
                              input  logic hresp,
                              input  logic hexokay
                              //output logic [NO_OF_SLAVES-1:0] hselx
                             );

  import AhbMasterPackage::*;
  `include "uvm_macros.svh"
  import uvm_pkg::*; 
  string name = "AHB_MASTER_DRIVER_BFM";

  AhbMasterDriverProxy ahbMasterDriverProxy;

  initial begin : MASTER_DRIVER
   // `uvm_info(name, $sformatf(name), UVM_LOW)
    $display("THE MASTER AGENT ARE  CREATED AS EXPECTED %m");
  end

  clocking MasterDriverCb @(posedge hclk);
    default input #1step output #1step;
    output haddr,hburst,hmastlock,hprot,hsize,hnonsec,hexcl,hmaster,htrans,hwrite,hwdata,hwstrb;
    input hready;
  endclocking

  task waitForResetn();
   $display("RESET CALLED");
    @(negedge hresetn);
    `uvm_info(name ,$sformatf("SYSTEM RESET DETECTED"),UVM_HIGH)
    htrans <= IDLE;  
    @(posedge hresetn);
   @(MasterDriverCb);
    `uvm_info(name ,$sformatf(" @%0t SYSTEM RESET DEACTIVATED",$time),UVM_HIGH)
  endtask: waitForResetn

  task driveToBFM(inout ahbTransferCharStruct dataPacket, input ahbTransferConfigStruct configPacket);
  
    if(dataPacket.hburst == SINGLE) begin
      driveSingleTransfer(dataPacket,configPacket);
    end
    else if(dataPacket.hburst != SINGLE) begin
     driveBurstTransfer(dataPacket,configPacket);
    end
endtask: driveToBFM

  task driveSingleTransfer(inout ahbTransferCharStruct dataPacket,input ahbTransferConfigStruct configPacket);
    `uvm_info("INSIDESINGLETRANSFER","BFM",UVM_LOW);

    `uvm_info(name,$sformatf("DRIVING THE Single Transfer"),UVM_LOW)
    
   MasterDriverCb.haddr     <= dataPacket.haddr;
    MasterDriverCb.hburst    <= dataPacket.hburst;
    MasterDriverCb.hmastlock <= dataPacket.hmastlock;
    MasterDriverCb.hprot     <= dataPacket.hprot;
    MasterDriverCb.hsize     <= dataPacket.hsize;
    MasterDriverCb.hnonsec   <= dataPacket.hnonsec;
    MasterDriverCb.hexcl     <= dataPacket.hexcl;
    MasterDriverCb.hmaster   <= dataPacket.hmaster;
    MasterDriverCb.htrans    <= dataPacket.htrans;
    MasterDriverCb.hwstrb    <= dataPacket.hwstrb[0];
    MasterDriverCb.hwrite    <= dataPacket.hwrite;

    @(MasterDriverCb);
    
    while(MasterDriverCb.hready==0 || $isunknown(MasterDriverCb.hready)) @(MasterDriverCb);  
   
    
    MasterDriverCb.hwdata <= dataPacket.hwrite ? maskingStrobe(dataPacket.hwdata[0], dataPacket.hwstrb[0]) : '0;

     if(dataPacket.hmastlock == 1)begin 
        driveIdle(dataPacket);
     end 

 
 endtask

  task driveBurstTransfer(inout ahbTransferCharStruct dataPacket,input ahbTransferConfigStruct configPacket);
   automatic int burst_length;
    automatic int i;
    automatic logic [ADDR_WIDTH-1:0] current_address = dataPacket.haddr;
    case (dataPacket.hburst)
      3'b010, 3'b011 : burst_length = 4;  // INCR4, WRAP4
      3'b100, 3'b101 : burst_length = 8;  // INCR8, WRAP8
      3'b110, 3'b111 : burst_length = 16; // INCR16, WRAP16
      3'b 001 : burst_length = configPacket.undefinedBurstLength;
      default: burst_length = 1;
    endcase
  $display("INSIDE BURST");
    MasterDriverCb.haddr     <= current_address;
     MasterDriverCb.hburst    <= dataPacket.hburst;
     MasterDriverCb.hmastlock <= dataPacket.hmastlock;
     MasterDriverCb.hprot     <= dataPacket.hprot;
     MasterDriverCb.hsize     <= dataPacket.hsize;
     MasterDriverCb.hnonsec   <= dataPacket.hnonsec;
    MasterDriverCb.hexcl     <= dataPacket.hexcl;
    MasterDriverCb.hmaster   <= dataPacket.hmaster;
    MasterDriverCb.htrans    <= dataPacket.htrans;
    MasterDriverCb.hwstrb    <= dataPacket.hwstrb[0];
    MasterDriverCb.hwrite    <= dataPacket.hwrite;
  
   @(MasterDriverCb);
  while(MasterDriverCb.hready==0 || $isunknown(MasterDriverCb.hready)) begin  $display("DRIVER");@(MasterDriverCb);end 

    hwdata <= dataPacket.hwrite ? maskingStrobe(dataPacket.hwdata[0], dataPacket.hwstrb[0]) : '0;

    for(i = 1;i < burst_length; i++) begin
    
  if (dataPacket.hburst == 3'b010 || dataPacket.hburst == 3'b100 || dataPacket.hburst == 3'b110) begin
        current_address = (current_address & ~(burst_length * (1 << dataPacket.hsize) - 1)) | ((current_address + (1 << dataPacket.hsize)) & (burst_length * (1 << dataPacket.hsize) - 1));
      end
      else begin
        current_address += (1 << dataPacket.hsize);
      end


       $display("HEY I AM INSIDE BURST");
      MasterDriverCb.haddr     <= current_address;
     MasterDriverCb.hburst    <= dataPacket.hburst;
     MasterDriverCb.hmastlock <= dataPacket.hmastlock;
     MasterDriverCb.hprot     <= dataPacket.hprot;
     MasterDriverCb.hsize     <= dataPacket.hsize;
     MasterDriverCb.hnonsec   <= dataPacket.hnonsec;
    MasterDriverCb.hexcl     <= dataPacket.hexcl;
    MasterDriverCb.hmaster   <= dataPacket.hmaster;
    MasterDriverCb.htrans    <= 2'b 11;
    MasterDriverCb.hwstrb    <= dataPacket.hwstrb[0];
    MasterDriverCb.hwrite    <= dataPacket.hwrite;
    
   @(MasterDriverCb); 
  while(MasterDriverCb.hready==0 || $isunknown(MasterDriverCb.hready))@(MasterDriverCb);

/*      if (hresp == 1) begin
        `uvm_info(name, $sformatf("ERROR detected during Burst Transfer at Address: %0h", haddr),UVM_LOW);
      end*/

/*      if (dataPacket.hburst == 3'b010 || dataPacket.hburst == 3'b100 || dataPacket.hburst == 3'b110) begin
        current_address = (current_address & ~(burst_length * (1 << dataPacket.hsize) - 1)) | ((current_address + (1 << dataPacket.hsize)) & (burst_length * (1 << dataPacket.hsize) - 1));
      end 
      else begin
        current_address += (1 << dataPacket.hsize); 
      end*/
   /*
      if(i > 0)begin
        if(dataPacket.busyControl[i]>0) begin
          driveBusyTransfer(dataPacket, current_address) ;
        end
        else begin
          htrans <= 2'b11; // Sequential transfer
        end
      end
      if(i==0) 
        WaitStates(configPacket);*/

      hwdata <= dataPacket.hwrite ? maskingStrobe(dataPacket.hwdata[i], dataPacket.hwstrb[i]) : '0;
    end

    driveIdle(dataPacket);    
    `uvm_info(name, "Burst Transfer Completed, Bus in IDLE State", UVM_LOW);
  endtask

  function logic [DATA_WIDTH-1:0] maskingStrobe(logic [DATA_WIDTH-1:0] data, logic [(DATA_WIDTH/8)-1:0] strobe);
    logic [DATA_WIDTH-1:0] masked_data;
    for (int j = 0; j < (DATA_WIDTH/8); j++) begin
      masked_data[j*8 +: 8] = strobe[j] ? data[j*8 +: 8] : 8'h00;
    end
    return masked_data;
  endfunction

  task driveBusyTransfer(inout ahbTransferCharStruct dataPacket, inout logic [ADDR_WIDTH-1:0] current_address);
    htrans <= 2'b01;   // Busy transfer
    `uvm_info(name, $sformatf("Driving BUSY Transfer at Address: %0h", haddr), UVM_LOW);
    @(posedge hclk);
    htrans <= 2'b11 ;  
  endtask

  task driveIdle(input ahbTransferCharStruct dataPacket );
 
    MasterDriverCb.haddr     <= dataPacket.haddr;
    MasterDriverCb.hburst    <= 2'b 00;
    MasterDriverCb.hmastlock <= 0 ;
    MasterDriverCb.hprot     <= dataPacket.hprot;
    MasterDriverCb.hsize     <= dataPacket.hsize;
    MasterDriverCb.hnonsec   <= dataPacket.hnonsec;
    MasterDriverCb.hexcl     <= dataPacket.hexcl;
    MasterDriverCb.hmaster   <= dataPacket.hmaster;
    MasterDriverCb.htrans    <= 2'b 00;
    MasterDriverCb.hwstrb    <= dataPacket.hwstrb[0];
    MasterDriverCb.hwrite    <= 1;

    @(MasterDriverCb);
    while(MasterDriverCb.hready==0 || $isunknown(MasterDriverCb.hready)) begin $display("DRIVER STUCK");  @(MasterDriverCb);  end
    
    MasterDriverCb.hwdata <= dataPacket.hwrite ? maskingStrobe(dataPacket.hwdata[0], dataPacket.hwstrb[0]) : '0;

  endtask

  task WaitStates(input ahbTransferConfigStruct configPacket);
    repeat(configPacket.noOfWaitStates) begin
      @(posedge hclk);
    end
  endtask

endinterface
`endif
