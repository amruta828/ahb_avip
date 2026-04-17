`ifndef AHBWRITEWITHWAITSTATETEST_INCLUDED_
`define AHBWRITEWITHWAITSTATETEST_INCLUDED_

class AhbWriteWithWaitStateTest extends AhbBaseTest;
  `uvm_component_utils(AhbWriteWithWaitStateTest)
  
  AhbVirtualWriteWithWaitStateSequence ahbVirtualWriteWithWaitStateSequence; 
 
  extern function new(string name = "AhbWriteWithWaitStateTest", uvm_component parent = null);
  extern virtual function void setupAhbEnvironmentConfig();
  extern virtual task run_phase(uvm_phase phase);

endclass : AhbWriteWithWaitStateTest

function AhbWriteWithWaitStateTest::new(string name = "AhbWriteWithWaitStateTest",uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void AhbWriteWithWaitStateTest::setupAhbEnvironmentConfig();
 super.setupAhbEnvironmentConfig();
 ahbEnvironmentConfig.operationMode = WRITE;
endfunction : setupAhbEnvironmentConfig

task AhbWriteWithWaitStateTest::run_phase(uvm_phase phase);
  
/*  foreach(ahbEnvironment.ahbSlaveAgentConfig[i]) begin
    if(!ahbEnvironment.ahbSlaveAgentConfig[i].randomize() with {noOfWaitStates==2;}) begin
      `uvm_fatal(get_type_name(),"Unable to randomise noOfWaitStates")
    end
    ahbEnvironment.ahbMasterAgentConfig[i].noOfWaitStates = ahbEnvironment.ahbSlaveAgentConfig[i].noOfWaitStates ;
  end*/

//added by me
    ahbEnvironment.ahbMasterAgentConfig[0].noOfWaitStates = ahbEnvironment.ahbSlaveAgentConfig[0].noOfWaitStates ;
    ahbEnvironment.ahbMasterAgentConfig[0].noOfWaitStates = ahbEnvironment.ahbSlaveAgentConfig[1].noOfWaitStates ;


  ahbVirtualWriteWithWaitStateSequence = AhbVirtualWriteWithWaitStateSequence::type_id::create("ahbVirtualWriteWithWaitStateSequence");
  `uvm_info(get_type_name(),$sformatf("AhbWriteWithWaitStateTest"),UVM_LOW);
  phase.raise_objection(this);
  ahbVirtualWriteWithWaitStateSequence.start(ahbEnvironment.ahbVirtualSequencer);
  #10;
  phase.drop_objection(this);

endtask : run_phase

`endif

