`ifndef AHBVIRTUALSINGLEREADSEQUENCE_INCLUDED_
`define AHBVIRTUALSINGLEREADSEQUENCE_INCLUDED_
 
class AhbVirtualSingleReadSequence extends AhbVirtualBaseSequence;
  `uvm_object_utils(AhbVirtualSingleReadSequence)
 
  AhbMasterSequence ahbMasterSequence[NO_OF_MASTERS];
 
  AhbSlaveSequence ahbSlaveSequence[NO_OF_SLAVES];
 
  extern function new(string name ="AhbVirtualSingleReadSequence");
  extern task body();
 
endclass : AhbVirtualSingleReadSequence
 
function AhbVirtualSingleReadSequence::new(string name ="AhbVirtualSingleReadSequence");
  super.new(name);
endfunction : new
 
task AhbVirtualSingleReadSequence::body();
  super.body();
  foreach(ahbMasterSequence[i])
    ahbMasterSequence[i] = AhbMasterSequence::type_id::create("ahbMasterSequence");
  
  foreach(ahbSlaveSequence[i])
    ahbSlaveSequence[i]  = AhbSlaveSequence::type_id::create("ahbSlaveSequence");
  
  foreach(ahbMasterSequence[i])begin 
    if(!ahbMasterSequence[i].randomize() with {
                                                              hsizeSeq dist {BYTE:=1, HALFWORD:=1, WORD:=1};
							      hwriteSeq ==0;
                                                              htransSeq == NONSEQ;
                                                              hmastlockSeq == 0; 
                                                              hburstSeq == SINGLE;
							      foreach(busyControlSeq[i]) busyControlSeq[i] dist {0:=100, 1:=0};}
 
                                                        ) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualSingleReadSequence")
    end
   end 
      fork
       begin
       foreach(ahbMasterSequence[i]) begin
         fork
            automatic int j = i;
            ahbMasterSequence[j].start(p_sequencer.ahbMasterSequencer[j]);
         join_none
       end
       wait fork;
       end

       begin
       foreach(ahbSlaveSequence[i]) begin
         fork
          automatic int j =i;
          //ahbSlaveSequence[j].start(p_sequencer.ahbSlaveSequencer[j]);
         join_none
        end
        wait fork;
       end
     join
    //wait fork; 
endtask : body
 
`endif  
