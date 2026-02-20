`ifndef AHBSINGLEWRITETEST_INCLUDED_
`define AHBSINGLEWRITETEST_INCLUDED_

class AhbSingleWriteTest extends AhbBaseTest;
  `uvm_component_utils(AhbSingleWriteTest)
  
  AhbVirtualSingleWriteSequence ahbVirtualSingleWriteSequence; 
 
  extern function new(string name = "AhbSingleWriteTest", uvm_component parent = null);
  extern virtual function void setupAhbEnvironmentConfig();
  extern virtual task run_phase(uvm_phase phase);

endclass : AhbSingleWriteTest

function AhbSingleWriteTest::new(string name = "AhbSingleWriteTest",uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void AhbSingleWriteTest::setupAhbEnvironmentConfig();
 super.setupAhbEnvironmentConfig();
 ahbEnvironmentConfig.operationMode = WRITE;
 $display("in env no of wait is %0d",ahbEnvironmentConfig.ahbSlaveAgentConfig[0].noOfWaitStates);
endfunction : setupAhbEnvironmentConfig

task AhbSingleWriteTest::run_phase(uvm_phase phase);
  $display("in env no of wait is %0d",ahbEnvironmentConfig.ahbSlaveAgentConfig[0].noOfWaitStates);
/*
  foreach(ahbEnvironment.ahbSlaveAgentConfig[i]) begin
    if(!ahbEnvironment.ahbSlaveAgentConfig[i].randomize() with {noOfWaitStates==0;}) begin
      `uvm_fatal(get_type_name(),"Unable to randomise noOfWaitStates")
    end
   // ahbEnvironment.ahbMasterAgentConfig[i].noOfWaitStates = ahbEnvironment.ahbSlaveAgentConfig[i].noOfWaitStates ;
  end*/
  ahbVirtualSingleWriteSequence = AhbVirtualSingleWriteSequence::type_id::create("ahbVirtualSingleWriteSequence");
 `uvm_info(get_type_name(),$sformatf("AhbSingleWriteTest"),UVM_LOW);
  phase.raise_objection(this);
  ahbVirtualSingleWriteSequence.start(ahbEnvironment.ahbVirtualSequencer);
  #10;
  phase.drop_objection(this);

endtask : run_phase

`endif
