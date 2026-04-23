`ifndef AHBSINGLEWRITEFOLLOWEDBYREADTEST_INCLUDED_
`define AHBSINGLEWRITEFOLLOWEDBYREADTEST_INCLUDED_

class AhbSingleWriteFollowedByReadTest extends AhbBaseTest;
  `uvm_component_utils(AhbSingleWriteFollowedByReadTest)
  
  AhbVirtualSingleWriteFollowedByReadSequence ahbVirtualSingleWriteFollowedByReadSequence; 
 
  extern function new(string name = "AhbSingleWriteFollowedByReadTest", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : AhbSingleWriteFollowedByReadTest

function AhbSingleWriteFollowedByReadTest::new(string name = "AhbSingleWriteFollowedByReadTest",uvm_component parent = null);
  super.new(name, parent);
endfunction : new


task AhbSingleWriteFollowedByReadTest::run_phase(uvm_phase phase);
  
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

  ahbVirtualSingleWriteFollowedByReadSequence = AhbVirtualSingleWriteFollowedByReadSequence::type_id::create("ahbVirtualWriteFollowedByReadSequence");
  `uvm_info(get_type_name(),$sformatf("AhbSingleWriteFollowedByReadTest"),UVM_LOW);

  phase.raise_objection(this);
  ahbVirtualSingleWriteFollowedByReadSequence.start(ahbEnvironment.ahbVirtualSequencer);
	#10;
  phase.drop_objection(this);

endtask : run_phase

`endif
