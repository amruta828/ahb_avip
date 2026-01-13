`ifndef AHBSLAVEDRIVERBFM_INCLUDED_
`define AHBSLAVEDRIVERBFM_INCLUDED_
 
import AhbGlobalPackage::*;
 
interface AhbSlaveDriverBFM (input  bit   hclk,
                             input  bit   hresetn,
                             input  logic [2:0] hburst,
                             input  logic hmastlock,
                             input  logic [ADDR_WIDTH-1:0] haddr,
                             input  logic [HPROT_WIDTH-1:0] hprot,
                             input  logic [2:0] hsize,
                             input  logic hnonsec,
                             input  logic hexcl,
                             input  logic [HMASTER_WIDTH-1:0] hmaster,
                             input  logic [1:0] htrans,
                             input  logic [DATA_WIDTH-1:0] hwdata,
                             input  logic [(DATA_WIDTH/8)-1:0]hwstrb,
                             input  logic hwrite,
                             output logic [DATA_WIDTH-1:0] hrdata,
                             output bit hreadyout,
                             output logic hresp,
                             output logic hexokay,
                             input  logic hready,
                             input  logic hselx
                            );
 
  import AhbSlavePackage::*;
 
  `include "uvm_macros.svh"
  import uvm_pkg::*;
 
reg[7:0]normalReg[longint];
 
 
/*
  `ifdef slaveStatusRegister
      reg[7:0]slaveStatusRegister[STATUSREGISTERWIDTH-1:0];
 
  `ifdef slaveControlRegister
       reg[7:0]slaveControlRegister[CONTROLREGISTERWIDTH-1:0];
 
  `ifdef slaveDataRegister
       reg[7:0]slaveControlRegister[DATAREGISTERWIDTH-1:0];
 
`ifdef slaveInstructionRegister
       reg[7:0]slaveControlRegister[INSTRUCTIONREGISTERWIDTH-1:0];
*/
 
  string name = "AHB_SLAVE_DRIVER_BFM";
 
  AhbSlaveDriverProxy ahbSlaveDriverProxy ;
  initial begin
    `uvm_info(name,$sformatf(name),UVM_LOW);
  end
 
 
  clocking SlaveDriverCb @(posedge hclk);
    default input #1step output #1step;
    input  haddr,hburst,hmastlock,hprot,hsize,hnonsec,hexcl,hmaster,htrans,hwrite,hwdata,hwstrb,hselx;
    output hreadyout;
  endclocking
 
  task waitForResetn();
    @(negedge hresetn);
      `uvm_info(name,$sformatf("SYSTEM RESET DETECTED"),UVM_LOW)
       hreadyout =1;
    @(posedge hresetn);
    @(SlaveDriverCb);
    `uvm_info(name,$sformatf("SYSTEM RESET DEACTIVATED"),UVM_LOW)
  endtask: waitForResetn
 
  task slaveDriveToBFM(inout ahbTransferCharStruct dataPacket, input ahbTransferConfigStruct configPacket);
    forever begin
      slaveDriveSingleTransfer(dataPacket,configPacket);
    end
endtask: slaveDriveToBFM
 
 
  task slaveDriveSingleTransfer(inout ahbTransferCharStruct dataPacket,input ahbTransferConfigStruct configPacket);
    bit[31:0]temp;
 
    bit[31:0]addressTemp;
    bit[31:0]dataTemp;
    @(SlaveDriverCb);
 
    while(SlaveDriverCb.hselx==0 || $isunknown(SlaveDriverCb.hselx) )  begin  $display("MONITOR %t",$time);@(SlaveDriverCb);end
      if(configPacket.needWaitStates) begin
        SlaveDriverCb.hreadyout <= 0;
        repeat(configPacket.noOfWaitStates)@(SlaveDriverCb);
        SlaveDriverCb.hreadyout <=1;
      end
      addressTemp = dataPacket.haddr;
 
      SlaveDriverCb.hreadyout <= 1;
      dataTemp = SlaveDriverCb.hwdata;
      dataPacket.haddr     <= haddr;
      dataPacket.htrans    <= ahbTransferEnum'(htrans);
      dataPacket.hsize     <= ahbHsizeEnum'(hsize);
      dataPacket.hburst    <= ahbBurstEnum'(hburst);
      dataPacket.hwrite    <= ahbOperationEnum'(hwrite);
      dataPacket.hmastlock <= hmastlock;
      dataPacket.hselx     <= hselx;
 
      if(SlaveDriverCb.hwrite) begin
        `uvm_info("SLAVE DRIVER BFM",$sformatf("the data to be written is :%0h",SlaveDriverCb.hwdata),UVM_LOW);
 
   $display("NIHAL strb :%b", hwstrb);
//        $display("THE DATA TO BE WRITTEN IS %0h",SlaveDriverCb.hwdata);
        for(int i=0;i<4;i++) begin
          //(if(hwstrb[i] == 1) begin
         normalReg[addressTemp+i] = dataTemp[((7*i)+i) +: 8];
          //end
        end
        `uvm_info("SLAVE DRIVER BFM",$sformatf("THE DATA WRITTEN IS %p @%0t\n",normalReg, $time), UVM_LOW)
 
      end
      else if(!hwrite) begin
 $display("SLAVE GOING INTO READ MODE");
        for (int i=0;i<4;i++) begin
          temp[((7*i)+i)+:8] =  normalReg[haddr+i];
        end
        hrdata = temp;
        `uvm_info("SLAVE DRIVER BFM",$sformatf("THE DATA READ IS %0h %0t ", hrdata, $time), UVM_LOW)
 
      end
 
  endtask: slaveDriveSingleTransfer
 
  task slavedriveBurstTransfer(inout ahbTransferCharStruct dataPacket,input ahbTransferConfigStruct configPacket);
 
    int burst_length;
`uvm_info(name,$sformatf("STARTED BURST TRANSFER TASK"),UVM_LOW)
    case (hburst)
      3'b010, 3'b011: burst_length = 4;
      3'b100, 3'b101: burst_length = 8;
      3'b110, 3'b111: burst_length = 16;
      default: burst_length = 1;
    endcase
 
          for(int i = 0;i < burst_length;i++) begin
      //hreadyout <= 1;
      dataPacket.haddr       <= haddr;
      dataPacket.hburst      <= ahbBurstEnum'(hburst);
      dataPacket.hsize       <= ahbHsizeEnum'(hsize);
      dataPacket.hwrite      <= ahbOperationEnum'(hwrite);
      dataPacket.htrans      <= ahbTransferEnum'(htrans);
      dataPacket.hmastlock   <= hmastlock;
      dataPacket.hselx       <= hselx;
 
    `uvm_info(name,$sformatf("Busy = %0b",dataPacket.busyControl), UVM_LOW);
 
      if(i==0)
        waitCycles(configPacket);
      if(hwrite) begin
        //if(i!=0) begin
                @(posedge hclk);
        //end
        dataPacket.hwdata[i]  <= hwdata;
        dataPacket.hwstrb[i]  <= hwstrb;
        hresp  <= 0;
      end
      else if(!hwrite) begin
        if(i!=0) begin
                @(posedge hclk);
        end
              `uvm_info(name, $sformatf("DEBUG Address=%0h, Burst=%0b, Size=%0b, Write=%0b,hrdata[%0d] = %0d",
                                dataPacket.haddr, dataPacket.hburst, dataPacket.hsize, dataPacket.hwrite,i,dataPacket.hrdata[i]), UVM_LOW);
        hrdata <=dataPacket.hrdata[i];
 
        hresp  <= 0;
      end
    end
    //hreadyout <= 0;
  endtask: slavedriveBurstTransfer
 
 
  task waitCycles(inout ahbTransferConfigStruct configPacket);
    @(posedge hclk);
    hresp <= 0;
    repeat(configPacket.noOfWaitStates) begin
            `uvm_info(name,$sformatf(" DRIVING WAIT STATE"),UVM_LOW);
    //  hreadyout <= 0;
      //hresp <=  ~hreadyout;
      @(posedge hclk);
    end
   // hreadyout<=1;
 
    `uvm_info(name, "Bus is now out of wait cycles", UVM_LOW);
  endtask: waitCycles
 
endinterface
`endif
