`ifndef AHBVIRTUALSINGLEWRITESEQUENCE_INCLUDED_
`define AHBVIRTUALSINGLEWRITESEQUENCE_INCLUDED_
 
class AhbVirtualSingleWriteSequence extends AhbVirtualBaseSequence;
  `uvm_object_utils(AhbVirtualSingleWriteSequence)
 
  AhbMasterSequence ahbMasterSequence[NO_OF_MASTERS];
 
  AhbSlaveSequence ahbSlaveSequence[NO_OF_SLAVES];
 
  extern function new(string name ="AhbVirtualSingleWriteSequence");
  extern task body();
 
endclass : AhbVirtualSingleWriteSequence
 
function AhbVirtualSingleWriteSequence::new(string name ="AhbVirtualSingleWriteSequence");
  super.new(name);
endfunction : new
 
task AhbVirtualSingleWriteSequence::body();
  super.body();
  foreach(ahbMasterSequence[i])
    ahbMasterSequence[i]= AhbMasterSequence::type_id::create("ahbMasterSequence");
  
  foreach(ahbSlaveSequence[i]) begin
    ahbSlaveSequence[i]  = AhbSlaveSequence::type_id::create("ahbSlaveSequence");
    ahbSlaveSequence[i].randomize();
  end 
  
  foreach(ahbMasterSequence[i])begin 
    if(!ahbMasterSequence[i].randomize() with {
                                                              hsizeSeq == WORD;
							      haddrSeq inside {[0:3000]};
							      hwriteSeq ==1;
    							      //hmastlockSeq == 0;
                                                              htransSeq == NONSEQ;
                                                              hburstSeq == SINGLE;
						              foreach(busyControlSeq[i]) busyControlSeq[i] dist {0:=100, 1:=0};}
 
                                                        ) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualSingleWriteSequence")
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
          ahbSlaveSequence[j].start(p_sequencer.ahbSlaveSequencer[j]);
         join_none
        end
        wait fork; 
       end 
     join
endtask : body
 
`endif  
