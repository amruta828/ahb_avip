`ifndef AHBWRAP16WRITEFOLLOWEDBYREADTEST_INCLUDED_
`define AHBWRAP16WRITEFOLLOWEDBYREADTEST_INCLUDED_

class AhbWrap16WriteFollowedByReadTest extends AhbBaseTest;
  `uvm_component_utils(AhbWrap16WriteFollowedByReadTest)

  AhbVirtualWrap16WriteFollowedByReadSequence ahbVirtualWrap16WriteFollowedByReadSequence;

  extern function new(string name = "AhbWrap16WriteFollowedByReadTest", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : AhbWrap16WriteFollowedByReadTest

function AhbWrap16WriteFollowedByReadTest::new(string name = "AhbWrap16WriteFollowedByReadTest",uvm_component parent = null);
  super.new(name, parent);
endfunction : new


task AhbWrap16WriteFollowedByReadTest::run_phase(uvm_phase phase);

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

  ahbVirtualWrap16WriteFollowedByReadSequence = AhbVirtualWrap16WriteFollowedByReadSequence::type_id::create("ahbVirtualWriteFollowedByReadSequence");
  `uvm_info(get_type_name(),$sformatf("AhbWrap16WriteFollowedByReadTest"),UVM_LOW);

  phase.raise_objection(this);
  ahbVirtualWrap16WriteFollowedByReadSequence.start(ahbEnvironment.ahbVirtualSequencer);
        #10;
  phase.drop_objection(this);

endtask : run_phase

`endif

