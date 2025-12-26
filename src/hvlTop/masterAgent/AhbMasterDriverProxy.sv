`ifndef AHBMASTERDRIVERPROXY_INCLUDED_
`define AHBMASTERDRIVERPROXY_INCLUDED_
 
class AhbMasterDriverProxy extends uvm_driver #(AhbMasterTransaction);
  `uvm_component_utils(AhbMasterDriverProxy)

  AhbMasterTransaction   ahbMasterTransaction;

  virtual AhbMasterDriverBFM ahbMasterDriverBFM;

  AhbMasterAgentConfig ahbMasterAgentConfig;

  string ahbBfmField;

  string ahbMasterIdAsci;

  extern function new(string name = "AhbMasterDriverProxy", uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern function void setConfig(AhbMasterAgentConfig ahbMasterAgentConfig); 
endclass : AhbMasterDriverProxy

 
function AhbMasterDriverProxy::new(string name = "AhbMasterDriverProxy",uvm_component parent);
  super.new(name, parent);
endfunction : new

function void AhbMasterDriverProxy::build_phase(uvm_phase phase);
  super.build_phase(phase);
 /* 
  if(!uvm_config_db #(virtual AhbMasterDriverBFM)::get(this,"",ahbMasterConfig.ahbBfmField, ahbMasterDriverBFM)) begin
    `uvm_fatal("FATAL_MDP_CANNOT_GET_APB_MASTER_DRIVER_BFM","cannot get() ahbMasterDriverBFM");
  end
*/
endfunction : build_phase


function void AhbMasterDriverProxy::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);

  //ahbMasterDriverBFM.ahbMasterDriverProxy = this;

endfunction : end_of_elaboration_phase

/*
task AhbMasterDriverProxy::run_phase(uvm_phase phase);
// *
  ahbMasterIdAsci.itoa( ahbMasterAgentConfig.ahbMasterDriverId);

  ahbBfmField = {"AhbMasterDriverBFM" , ahbMasterIdAsci};

  if(!uvm_config_db #(virtual AhbMasterDriverBFM)::get(this,"" ,ahbBfmField  ,  ahbMasterDriverBFM)) begin
    `uvm_fatal("FATAL_MDP_CANNOT_GET_APB_MASTER_DRIVER_BFM","cannot get() ahbMasterDriverBFM");
  end
 // *
 
   ahbMasterDriverBFM.waitForResetn();

  forever begin

    ahbTransferCharStruct dataPacket;
    ahbTransferConfigStruct configPacket;
    $display("\n \n getting next one \n \n");
    $display("....I AM HERE..... %0t ",$time);
    seq_item_port.get_next_item(req);

    `uvm_info(get_type_name(), $sformatf("REQ-MASTERTX \n %s",req.sprint),UVM_LOW);

  
    $display("***************************IN DRIVER************************************************************************");
    req.print();
    $display("***************************************************************************************************"); 
    AhbMasterSequenceItemConverter::fromClass(req, dataPacket);
    AhbMasterConfigConverter::fromClass(ahbMasterAgentConfig, configPacket);
    ahbMasterDriverBFM.driveToBFM(dataPacket,configPacket);
    $display("EXITED THE DRIVER BFM  AT @%t",$time);
    AhbMasterSequenceItemConverter::toClass(dataPacket, req);
    $display("\n \n NEXTONE %0t \N \N\N",$time);
    seq_item_port.item_done();
  end

endtask : run_phase
*/

/////////////
/// new code//
//////////////

task AhbMasterDriverProxy::run_phase(uvm_phase phase);
   ahbMasterDriverBFM.waitForResetn();

  forever begin
    ahbTransferCharStruct dataPacket;
    ahbTransferConfigStruct configPacket;

    seq_item_port.get_next_item(req);

    `uvm_info(get_type_name(), $sformatf("Received Transaction: \n%s", req.sprint()), UVM_LOW)

    AhbMasterSequenceItemConverter::fromClass(req, dataPacket);
    AhbMasterConfigConverter::fromClass(ahbMasterAgentConfig, configPacket);
    ahbMasterDriverBFM.driveToBFM(dataPacket, configPacket);
    
    `uvm_info(get_type_name(), $sformatf("Completed Driving Transaction at Time: %0t", $time), UVM_LOW)

    AhbMasterSequenceItemConverter::toClass(dataPacket, req);
    seq_item_port.item_done();
  end

endtask : run_phase
///////////////////////////
   
function void AhbMasterDriverProxy :: connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  ahbMasterDriverBFM = ahbMasterAgentConfig.ahbMasterDriverBfm;
endfunction  : connect_phase

function void AhbMasterDriverProxy :: setConfig( AhbMasterAgentConfig ahbMasterAgentConfig );
   this.ahbMasterAgentConfig = ahbMasterAgentConfig;
endfunction : setConfig

 
`endif


