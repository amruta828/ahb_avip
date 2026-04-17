`ifndef AHBVIRTUALSINGLEWRITEWITHWAITSTATESEQUENCE_INCLUDED_
`define AHBVIRTUALSINGLEWRITEWITHWAITSTATESEQUENCE_INCLUDED_
 
class AhbVirtualSingleWriteWithWaitStateSequence extends AhbVirtualBaseSequence;
  `uvm_object_utils(AhbVirtualSingleWriteWithWaitStateSequence)
 
  AhbMasterSequence ahbMasterSequence[NO_OF_MASTERS];
 
  AhbSlaveSequence ahbSlaveSequence[NO_OF_SLAVES];
 
  extern function new(string name ="AhbVirtualSingleWriteWithWaitStateSequence");
  extern task body();
 
endclass : AhbVirtualSingleWriteWithWaitStateSequence
 
function AhbVirtualSingleWriteWithWaitStateSequence::new(string name ="AhbVirtualSingleWriteWithWaitStateSequence");
  super.new(name);
endfunction : new
 
task AhbVirtualSingleWriteWithWaitStateSequence::body();
  super.body();
  foreach(ahbMasterSequence[i])
    ahbMasterSequence[i] = AhbMasterSequence::type_id::create("ahbMasterSequence");

  foreach(ahbSlaveSequence[i])
    ahbSlaveSequence[i]= AhbSlaveSequence::type_id::create("ahbSlaveSequence");
  


  foreach(ahbMasterSequence[i])begin 
    if(!ahbMasterSequence[i].randomize() with {
                                                              hsizeSeq dist {BYTE:=1, HALFWORD:=1, WORD:=1};
							      hwriteSeq ==1;
                                                              htransSeq == NONSEQ;
                                                              hburstSeq == SINGLE;
						              foreach(busyControlSeq[i]) busyControlSeq[i] dist {0:=100, 1:=0};
}
 
                                                        ) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualSingleWriteWithWaitStateSequence")
    end
   end 


if(!ahbSlaveSequence[1].randomize() with {
                                               // noOfWaitStatesSeq == 0;
						hreadyoutSeq == 1;
}

                                                        ) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualSingleWriteWithWaitStateSequence")
    end

    foreach(ahbMasterSequence[i])begin
      ahbMasterSequence[i].randomize();
    end
	
  //    ahbSlaveSequence[1].randomize();

  fork
	
      foreach(p_sequencer.ahbSlaveSequencer[i])
        ahbSlaveSequence[i].start(p_sequencer.ahbSlaveSequencer[i]);
      foreach(p_sequencer.ahbMasterSequencer[i])
         ahbMasterSequence[i].start(p_sequencer.ahbMasterSequencer[0]); 
    join	
  
endtask : body
 
`endif  
