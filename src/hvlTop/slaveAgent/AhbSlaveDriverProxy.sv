`ifndef AHBSLAVEDRIVERPROXY_INCLUDED_
`define AHBSLAVEDRIVERPROXY_INCLUDED_

class AhbSlaveDriverProxy extends uvm_driver#(AhbSlaveTransaction);
  `uvm_component_utils(AhbSlaveDriverProxy)

  AhbSlaveTransaction ahbSlaveTransaction;

  virtual AhbSlaveDriverBFM ahbSlaveDriverBFM;

  AhbSlaveAgentConfig ahbSlaveAgentConfig;

  string ahbSlaveIdAsci;

  
  extern function new(string name = "AhbSlaveDriverProxy", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task taskWrite(inout ahbTransferCharStruct structPacket);
  extern virtual task taskRead(inout ahbTransferCharStruct structPacket);
  extern virtual function void connect_phase(uvm_phase phase);
  extern function void setConfig( AhbSlaveAgentConfig ahbSlaveAgentConfig);


endclass : AhbSlaveDriverProxy

function AhbSlaveDriverProxy::new(string name = "AhbSlaveDriverProxy", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void AhbSlaveDriverProxy::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `uvm_info(get_type_name(), "SLAVE DRIVER PROXY CREATED", UVM_LOW)
/*  
  if(!uvm_config_db #(virtual AhbSlaveDriverBFM)::get(this,"",ahbSlaveConfig.ahbBfmField, ahbSlaveDriverBFM)) 
    begin
    `uvm_fatal("FATAL SDP CANNOT GET SLAVE DRIVER BFM","cannot get() ahbSlaveDriverBFM");
  end
 */
endfunction : build_phase


function void AhbSlaveDriverProxy::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  //ahbSlaveDriverBFM.ahbSlaveDriverProxy = this;
endfunction : end_of_elaboration_phase

task AhbSlaveDriverProxy::run_phase(uvm_phase phase);
`uvm_info(get_type_name(), $sformatf(" BEFORE RESET \n "), UVM_LOW);
/*
  ahbSlaveIdAsci.itoa(ahbSlaveAgentConfig.ahbSlaveDriverId);
  ahbBfmField = {"AhbSlaveDriverBFM" ,ahbSlaveIdAsci};

  //$display("\n\nTHE SLAVE BFM FIELD IS %s \n \n",ahbBfmField );
  if(!uvm_config_db #(virtual AhbSlaveDriverBFM)::get(this,"",ahbBfmField, ahbSlaveDriverBFM))
    begin
    `uvm_fatal("FATAL SDP CANNOT GET SLAVE DRIVER BFM","cannot get() ahbSlaveDriverBFM");
  end
*/
  ahbSlaveDriverBFM.waitForResetn();
  
   forever begin
    ahbTransferCharStruct structPacket;
    ahbTransferConfigStruct structConfig;
   
    seq_item_port.get_next_item(req);
    if(req.choosePacketData) begin  

    AhbSlaveSequenceItemConverter::fromClass(req, structPacket);
    `uvm_info(get_type_name(), $sformatf("RUN PHASE: NO OF WAIT STATES: %0d",ahbSlaveAgentConfig.noOfWaitStates), UVM_LOW)
    //$display("THE RUN PHASE IS %0d",ahbSlaveAgentConfig.noOfWaitStates); 
    AhbSlaveConfigConverter::fromClass(ahbSlaveAgentConfig, structConfig);
    fork
    ahbSlaveDriverBFM.slaveDriveToBFM(structPacket, structConfig);
   join_none
    AhbSlaveSequenceItemConverter::toClass(structPacket, req);  

    `uvm_info(get_type_name(), $sformatf("STRUCT PACKET = %p",req), UVM_LOW)
      
      if(structPacket.hwrite == WRITE)begin   
        `uvm_info(get_type_name(), "ENTERED WRITE LOOP", UVM_LOW)
        taskWrite(structPacket);
      end
      else begin
        taskRead(structPacket);
      end
    end
    else
      begin
        AhbSlaveSequenceItemConverter::fromClass(req, structPacket);
	`uvm_info(get_type_name(), $sformatf("RUN PHASE: NO OF WAIT STATES: %0d",ahbSlaveAgentConfig.noOfWaitStates), UVM_LOW)
        //$display("THE RUN PHASE IS %0d",ahbSlaveAgentConfig.noOfWaitStates); 
        AhbSlaveConfigConverter::fromClass(ahbSlaveAgentConfig, structConfig);
       fork 
       ahbSlaveDriverBFM.slaveDriveToBFM(structPacket, structConfig);
       join_none  
       AhbSlaveSequenceItemConverter::toClass(structPacket, req); 
      end
     `uvm_info(get_type_name(), "ACK SENT", UVM_LOW)
    seq_item_port.item_done();
  end

endtask : run_phase

task AhbSlaveDriverProxy::taskWrite(inout ahbTransferCharStruct structPacket);
  `uvm_info(get_type_name(), $sformatf("DEBUG: taskWrite"), UVM_LOW); 
  
  for(int i=0; i<(DATA_WIDTH/8); i++) begin
    `uvm_info(get_type_name(), $sformatf("DEBUG: task_write inside for loop :: %0d", i), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("DEBUG: task_write inside for loop hwstrb = %0b", structPacket.hwstrb[i]), UVM_LOW);
    
    if(structPacket.hwstrb[i] == 1) begin
      ahbSlaveAgentConfig.slaveMemoryTask(structPacket.haddr+i,structPacket.hwdata[8*i+7 -: 8]);
      `uvm_info(get_type_name(), $sformatf("DEBUG: task_write inside for loop data = %0h",ahbSlaveAgentConfig.slaveMemory[structPacket.haddr+i]), UVM_LOW);
    end
  end
endtask : taskWrite

task AhbSlaveDriverProxy::taskRead(inout ahbTransferCharStruct structPacket);
  bit memoryExist;

  `uvm_info(get_type_name(), $sformatf("DEBUG: task_read"), UVM_LOW);
  
  for(int i=0; i<(DATA_WIDTH/8); i++) begin
    if(ahbSlaveAgentConfig.slaveMemory.exists(structPacket.haddr)) begin
      structPacket.hrdata[8*i+7 -: 8] = ahbSlaveAgentConfig.slaveMemory[structPacket.haddr + i];
      memoryExist = 1;
    end
  end
  if(memoryExist == 0) begin
    `uvm_error(get_type_name(), $sformatf("Selected address has no data"));
      structPacket.hresp  = ERROR;
      structPacket.hrdata  = 'h0;
  end
endtask : taskRead


function void AhbSlaveDriverProxy :: connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  ahbSlaveDriverBFM = ahbSlaveAgentConfig.ahbSlaveDriverBfm;
endfunction  : connect_phase

function void AhbSlaveDriverProxy :: setConfig( AhbSlaveAgentConfig ahbSlaveAgentConfig);
   this.ahbSlaveAgentConfig = ahbSlaveAgentConfig;
  `uvm_info(get_type_name(), $sformatf("NO OF WAIT STATES: %0d",ahbSlaveAgentConfig.noOfWaitStates), UVM_LOW)
   //$display("IN THE SLAVE PROXY THE  %0d",this.ahbSlaveAgentConfig.noOfWaitStates);
endfunction : setConfig    

`endif
