`ifndef AHBVIRTUALWRITESEQUENCE_INCLUDED_
`define AHBVIRTUALWRITESEQUENCE_INCLUDED_
 
class AhbVirtualWriteSequence extends AhbVirtualBaseSequence;
  `uvm_object_utils(AhbVirtualWriteSequence)
 
  AhbMasterSequence ahbMasterSequence[NO_OF_MASTERS];
 
  AhbSlaveSequence ahbSlaveSequence[NO_OF_SLAVES];
 
  extern function new(string name ="AhbVirtualWriteSequence");
  extern task body();
 
endclass : AhbVirtualWriteSequence
 
function AhbVirtualWriteSequence::new(string name ="AhbVirtualWriteSequence");
  super.new(name);
endfunction : new
 
task AhbVirtualWriteSequence::body();
  super.body();
  foreach(ahbMasterSequence[i]) 
    ahbMasterSequence[i]= AhbMasterSequence::type_id::create("ahbMasterSequence");
  foreach(ahbSlaveSequence[i])
    ahbSlaveSequence[i]  = AhbSlaveSequence::type_id::create("ahbSlaveSequence");
  foreach(ahbMasterSequence[i])begin : repeat_block 
    if(!ahbMasterSequence[i].randomize() with { hsizeSeq dist {BYTE:=1, HALFWORD:=1, WORD:=1};
					     hwriteSeq ==1;
                                             //hmastlockSeq == 1;
                                             htransSeq == NONSEQ;
                                             hburstSeq dist { 2:=1, 3:=1, 4:=1, 5:=2, 6:=2, 7:=2};
 					     foreach(busyControlSeq[i]) 
                                               busyControlSeq[i] dist {0:=100, 1:=0};}
                                             ) begin : if_block
      `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualWriteSequence")
    end : if_block
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
          ahbSlaveSequence[j].start(p_sequencer.ahbSlaveSequencer[j]);
         join_none
        end
        wait fork;
       end
     join
    wait fork;
   $display("\n\n\n HEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE ***************************** \n\n\n");
 
endtask : body
 
`endif  
