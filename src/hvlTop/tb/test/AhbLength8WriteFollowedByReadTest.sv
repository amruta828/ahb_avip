`ifndef AHBLENGTH8WRITEFOLLOWEDBYREADTEST_INCLUDED_
`define AHBLENGTH8WRITEFOLLOWEDBYREADTEST_INCLUDED_

class AhbLength8WriteFollowedByReadTest extends AhbBaseTest;
  `uvm_component_utils(AhbLength8WriteFollowedByReadTest)
  
  AhbVirtualLength8WriteFollowedByReadSequence ahbVirtualLength8WriteFollowedByReadSequence; 
 
  extern function new(string name = "AhbLength8WriteFollowedByReadTest", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : AhbLength8WriteFollowedByReadTest

function AhbLength8WriteFollowedByReadTest::new(string name = "AhbLength8WriteFollowedByReadTest",uvm_component parent = null);
  super.new(name, parent);
endfunction : new


task AhbLength8WriteFollowedByReadTest::run_phase(uvm_phase phase);
  
 //foreach(ahbEnvironment.ahbSlaveAgentConfig[i]) begin
  /*  if(!ahbEnvironment.ahbSlaveAgentConfig[0].randomize() with {noOfWaitStates==3;}) begin
      `uvm_fatal(get_type_name(),"Unable to randomise noOfWaitStates")
    end
   if(!ahbEnvironment.ahbSlaveAgentConfig[1].randomize() with {noOfWaitStates==0;}) begin
      `uvm_fatal(get_type_name(),"Unable to randomise noOfWaitStates")
    end
*/

  //added 4 line
    ahbEnvironment.ahbMasterAgentConfig[0].noOfWaitStates = ahbEnvironment.ahbSlaveAgentConfig[1].noOfWaitStates ;
    ahbEnvironment.ahbMasterAgentConfig[0].noOfWaitStates = ahbEnvironment.ahbSlaveAgentConfig[0].noOfWaitStates ;
 //end

  ahbVirtualLength8WriteFollowedByReadSequence = AhbVirtualLength8WriteFollowedByReadSequence::type_id::create("ahbVirtualLength8WriteFollowedByReadSequence");
  `uvm_info(get_type_name(),$sformatf("AhbLength8WriteFollowedByReadTest"),UVM_LOW);

  phase.raise_objection(this);
  ahbVirtualLength8WriteFollowedByReadSequence.start(ahbEnvironment.ahbVirtualSequencer);
 #10;
  phase.drop_objection(this);

endtask : run_phase

`endif

 
