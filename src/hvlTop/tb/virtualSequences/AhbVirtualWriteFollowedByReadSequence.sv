`ifndef AHBVIRTUALWRITEFOLLOWEDBYREADSEQUENCE_INCLUDED_
`define AHBVIRTUALWRITEFOLLOWEDBYREADSEQUENCE_INCLUDED_
 
class AhbVirtualWriteFollowedByReadSequence extends AhbVirtualBaseSequence;
  `uvm_object_utils(AhbVirtualWriteFollowedByReadSequence)
 
  AhbMasterSequence ahbMasterWriteSequence[NO_OF_MASTERS];
  AhbMasterSequence ahbMasterReadSequence[NO_OF_MASTERS];
 
  AhbSlaveSequence ahbSlaveWriteSequence[NO_OF_SLAVES];
  AhbSlaveSequence ahbSlaveReadSequence[NO_OF_SLAVES];
 
  extern function new(string name ="AhbVirtualWriteFollowedByReadSequence");
  extern task body();
 
endclass : AhbVirtualWriteFollowedByReadSequence
 
function AhbVirtualWriteFollowedByReadSequence::new(string name ="AhbVirtualWriteFollowedByReadSequence");
  super.new(name);
endfunction : new
 
task AhbVirtualWriteFollowedByReadSequence::body();
  super.body();
  foreach(ahbMasterWriteSequence[i]) begin
    ahbMasterWriteSequence[i]= AhbMasterSequence::type_id::create("ahbMasterWriteSequence");
    ahbMasterReadSequence[i]= AhbMasterSequence::type_id::create("ahbMasterReadSequence");
  end 

  foreach(ahbSlaveWriteSequence[i]) begin
    ahbSlaveWriteSequence[i]= AhbSlaveSequence::type_id::create("ahbSlaveWriteSequence");
    ahbSlaveReadSequence[i]  = AhbSlaveSequence::type_id::create("ahbSlaveReadSequence");
  end
  
  foreach(ahbMasterWriteSequence[i])begin
    if(!ahbMasterWriteSequence[i].randomize() with {hsizeSeq == WORD;
	    					    hwriteSeq == 1;
                                                    htransSeq == NONSEQ;
                                                    hburstSeq == SINGLE;
 						    foreach(busyControlSeq[i]) 
                                                      busyControlSeq[i] == 0;}
                                                    ) begin
      `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualWriteFollowedByReadSequence")
    end
  end 

  foreach(ahbMasterReadSequence[i]) begin 
  if(!ahbMasterReadSequence[i].randomize() with {hsizeSeq == WORD;
	    			              hwriteSeq == 0;
                                              htransSeq == NONSEQ;
                                              hburstSeq == 0;
 					      foreach(busyControlSeq[i]) 
                                                busyControlSeq[i] == 0;}
                                            ) begin
    `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualReadFollowedByReadSequence")
  end
 end 
  
 foreach(ahbSlaveWriteSequence[i]) begin 
  ahbSlaveWriteSequence[i].randomize();
  ahbSlaveReadSequence[i].randomize();
 end


  fork
      
        foreach( ahbMasterWriteSequence[i]) begin
          fork  
            automatic int j = i;
            ahbMasterWriteSequence[j].start(p_sequencer.ahbMasterSequencer[j]); 
          join_none
         end 

        foreach( ahbSlaveWriteSequence[i]) begin
          fork
            automatic int j = i;
            ahbSlaveWriteSequence[j].start(p_sequencer.ahbSlaveSequencer[j]); 
          join_none
         end

  join	
  wait fork;


  fork

        foreach( ahbMasterReadSequence[i]) begin
          fork
            automatic int j = i;
            ahbMasterReadSequence[j].start(p_sequencer.ahbMasterSequencer[j]);
          join_none
         end

        foreach( ahbSlaveReadSequence[i]) begin
          fork
            automatic int j = i;
            ahbSlaveReadSequence[j].start(p_sequencer.ahbSlaveSequencer[j]);  
          join_none
         end

  join
  wait fork;


endtask : body
 
`endif  
