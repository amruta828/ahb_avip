`ifndef AHBLENGTH16WRITEFOLLOWEDBYREADTEST_INCLUDED_
`define AHBLENGTH16WRITEFOLLOWEDBYREADTEST_INCLUDED_

class AhbLength16WriteFollowedByReadTest extends AhbBaseTest;
  `uvm_component_utils(AhbLength16WriteFollowedByReadTest)

  AhbVirtualLength16WriteFollowedByReadSequence ahbVirtualLength16WriteFollowedByReadSequence;

  extern function new(string name = "AhbLength16WriteFollowedByReadTest", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : AhbLength16WriteFollowedByReadTest

function AhbLength16WriteFollowedByReadTest::new(string name = "AhbLength16WriteFollowedByReadTest",uvm_component parent = null);
  super.new(name, parent);
endfunction : new


task AhbLength16WriteFollowedByReadTest::run_phase(uvm_phase phase);

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

  ahbVirtualLength16WriteFollowedByReadSequence = AhbVirtualLength16WriteFollowedByReadSequence::type_id::create("ahbVirtualLength16WriteFollowedByReadSequence");
  `uvm_info(get_type_name(),$sformatf("AhbLength16WriteFollowedByReadTest"),UVM_LOW);

  phase.raise_objection(this);
  ahbVirtualLength16WriteFollowedByReadSequence.start(ahbEnvironment.ahbVirtualSequencer);
        #10;
  phase.drop_objection(this);

endtask : run_phase

`endif
 
