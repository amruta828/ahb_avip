`ifndef AHBVIRTUALWRITEFOLLOWEDBYREADSEQUENCE_INCLUDED_
`define AHBVIRTUALWRITEFOLLOWEDBYREADSEQUENCE_INCLUDED_
 
class AhbVirtualWriteFollowedByReadSequence extends AhbVirtualBaseSequence;
  `uvm_object_utils(AhbVirtualWriteFollowedByReadSequence)
 
  AhbMasterSequence ahbMasterWriteSequence[NO_OF_MASTERS];
  AhbMasterSequence ahbMasterReadSequence[NO_OF_MASTERS];
 
  AhbSlaveSequence ahbSlaveWriteSequence[NO_OF_SLAVES];
  AhbSlaveSequence ahbSlaveReadSequence[NO_OF_SLAVES];


  AhbVirtualSingleWriteSequence ahbVirtualSingleWriteSequence;
  AhbVirtualSingleReadSequence ahbVirtualSingleReadSequence;
  AhbVirtualIdleSequence ahbVirtualIdleSequence;

  extern function new(string name ="AhbVirtualWriteFollowedByReadSequence");
  extern task body();
 
endclass : AhbVirtualWriteFollowedByReadSequence
 
function AhbVirtualWriteFollowedByReadSequence::new(string name ="AhbVirtualWriteFollowedByReadSequence");
  super.new(name);
endfunction : new
 
task AhbVirtualWriteFollowedByReadSequence::body();
  super.body();


  foreach(ahbMasterWriteSequence[i]) begin
    ahbMasterWriteSequence[i] = AhbMasterSequence::type_id::create($sformatf("ahbMasterWriteSequence[%0d]", i));
    ahbMasterReadSequence[i]  = AhbMasterSequence::type_id::create($sformatf("ahbMasterReadSequence[%0d]", i));
  end

  foreach(ahbSlaveWriteSequence[i]) begin
    ahbSlaveWriteSequence[i] = AhbSlaveSequence::type_id::create($sformatf("ahbSlaveWriteSequence[%0d]", i));
    ahbSlaveReadSequence[i]  = AhbSlaveSequence::type_id::create($sformatf("ahbSlaveReadSequence[%0d]", i));
  end


  foreach(ahbMasterWriteSequence[i]) begin 
    if(!ahbMasterWriteSequence[i].randomize() with {
         hsizeSeq == WORD;
         hwriteSeq == 1; // WRITE
         hmastlockSeq == 0;
         htransSeq == NONSEQ;
         hburstSeq == SINGLE;
         foreach(busyControlSeq[k]) busyControlSeq[k] dist {0:=100, 1:=0};
    }) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside Write Sequence")
    end
  end


/*
if(!ahbSlaveWriteSequence[0].randomize() with {
                                                noOfWaitStateSeq == 3;
}

                                                        ) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualWriteFollowedByReadSequence")
    end


if(!ahbSlaveWriteSequence[1].randomize() with {
                                                
						noOfWaitStateSeq == 3;
}

                                                        ) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualWriteFollowedByReadSequence")
    end


if(!ahbSlaveReadSequence[0].randomize() with {
                                                noOfWaitStateSeq == 3;
}

                                                        ) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualWriteFollowedByReadSequence")
    end
if(!ahbSlaveReadSequence[1].randomize() with {
                                                noOfWaitStateSeq == 0;
					//	hreadySeq == 1;
}

                                                        ) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualWriteFollowedByReadSequence")
    end
*/

//  foreach(ahbSlaveWriteSequence[i]) ahbSlaveWriteSequence[i].randomize();
//   foreach(ahbSlaveReadSequence[i])  ahbSlaveReadSequence[i].randomize();


  fork
    // Start Slave Sequences (Reactive)
    begin
       foreach(ahbSlaveWriteSequence[i]) begin
         fork
           automatic int k = i;
           ahbSlaveWriteSequence[k].start(p_sequencer.ahbSlaveSequencer[k]);
         join_none
       end
    end

    // Start Master Write Sequences
    begin
       foreach(ahbMasterWriteSequence[i]) begin
         fork
            automatic int k = i;
            ahbMasterWriteSequence[k].start(p_sequencer.ahbMasterSequencer[k]);
         join_none
       end
       wait fork; // Wait for ALL writes to finish
    end
  join


  foreach(ahbMasterReadSequence[i]) begin 

    if(!ahbMasterReadSequence[i].randomize() with {
         hsizeSeq == WORD;
         hwriteSeq == 0; // READ
         hmastlockSeq == 0;
         htransSeq == NONSEQ;
         hburstSeq == SINGLE;
         foreach(busyControlSeq[k]) busyControlSeq[k] dist {0:=100, 1:=0};
    }) begin
      `uvm_error(get_type_name(), "Randomization failed : Inside Read Sequence")
    end
    



    ahbMasterReadSequence[i].haddr_list = ahbMasterWriteSequence[i].haddr_list;
  end

  fork
    // Start Slave Sequences (Reactive)
    begin
       foreach(ahbSlaveReadSequence[i]) begin
         fork
           automatic int k = i;
           ahbSlaveReadSequence[k].start(p_sequencer.ahbSlaveSequencer[k]);
         join_none
       end
    end

    // Start Master Read Sequences
    begin
     
  foreach(ahbMasterReadSequence[i]) begin
         fork
            automatic int k = i;
            ahbMasterReadSequence[k].start(p_sequencer.ahbMasterSequencer[k]);
         join_none
       end
       wait fork; // Wait for ALL reads to finish
    end
  join

endtask : body
 
`endif 

 
