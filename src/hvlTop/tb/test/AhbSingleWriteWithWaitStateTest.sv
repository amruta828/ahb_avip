
`ifndef AHBSINGLEWRITEWITHWAITSTATETEST_INCLUDED_
`define AHBSINGLEWRITEWITHWAITSTATETEST_INCLUDED_

class AhbSingleWriteWithWaitStateTest extends AhbBaseTest;
  `uvm_component_utils(AhbSingleWriteWithWaitStateTest)
  
  AhbVirtualSingleWriteWithWaitStateSequence ahbVirtualSingleWriteWithWaitStateSequence; 
 
  extern function new(string name = "AhbSingleWriteWithWaitStateTest", uvm_component parent = null);
  extern virtual function void setupAhbEnvironmentConfig();
  extern virtual task run_phase(uvm_phase phase);

endclass : AhbSingleWriteWithWaitStateTest

function AhbSingleWriteWithWaitStateTest::new(string name = "AhbSingleWriteWithWaitStateTest",uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void AhbSingleWriteWithWaitStateTest::setupAhbEnvironmentConfig();
 super.setupAhbEnvironmentConfig();
 ahbEnvironmentConfig.operationMode = WRITE;
endfunction : setupAhbEnvironmentConfig

task AhbSingleWriteWithWaitStateTest::run_phase(uvm_phase phase);

/*  foreach(ahbEnvironment.ahbSlaveAgentConfig[i]) begin
    if(!ahbEnvironment.ahbSlaveAgentConfig[i].randomize() with {noOfWaitStates==0;}) begin
      `uvm_fatal(get_type_name(),"Unable to randomise noOfWaitStates")
    end
*/


ahbEnvironment.ahbMasterAgentConfig[0].noOfWaitStates = ahbEnvironment.ahbSlaveAgentConfig[0].noOfWaitStates;    
ahbEnvironment.ahbMasterAgentConfig[0].noOfWaitStates = ahbEnvironment.ahbSlaveAgentConfig[1].noOfWaitStates ;
 
 //  ahbEnvironment.ahbMasterAgentConfig[i].noOfWaitStates = ahbEnvironment.ahbSlaveAgentConfig[i].noOfWaitStates ;
//  end
  ahbVirtualSingleWriteWithWaitStateSequence = AhbVirtualSingleWriteWithWaitStateSequence::type_id::create("ahbVirtualSingleWriteWithWaitStateSequence");
 `uvm_info(get_type_name(),$sformatf("AhbSingleWriteWithWaitStateTest"),UVM_LOW);
  phase.raise_objection(this);
  ahbVirtualSingleWriteWithWaitStateSequence.start(ahbEnvironment.ahbVirtualSequencer);
  #10;
  phase.drop_objection(this);

endtask : run_phase

`endif

