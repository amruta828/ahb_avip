`ifndef AHBVIRTUALIDLESEQUENCE_INCLUDED_
`define AHBVIRTUALIDLESEQUENCE_INCLUDED_
 
class AhbVirtualIdleSequence extends AhbVirtualBaseSequence;
  `uvm_object_utils(AhbVirtualIdleSequence)
 
  AhbMasterSequence ahbMasterSequence[NO_OF_MASTERS];
 
  AhbSlaveSequence ahbSlaveSequence[NO_OF_SLAVES];
 
  extern function new(string name ="AhbVirtualIdleSequence");
  extern task body();
 
endclass : AhbVirtualIdleSequence
 
function AhbVirtualIdleSequence::new(string name ="AhbVirtualIdleSequence");
  super.new(name);
endfunction : new
 
task AhbVirtualIdleSequence::body();
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
							      hwriteSeq ==1;
    							      hmastlockSeq == 0;
                                                              htransSeq == IDLE;
                                                              hburstSeq == SINGLE;
						              foreach(busyControlSeq[i]) busyControlSeq[i] dist {0:=100, 1:=0};}
 
                                                        ) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualIdleSequence")
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
     /*
       begin 
       foreach(ahbSlaveSequence[i]) begin
         fork
          automatic int j =i;
          ahbSlaveSequence[j].start(p_sequencer.ahbSlaveSequencer[j]);
         join_none
        end
        wait fork; 
       end*/ 
     join
    //wait fork;
   $display("\n\n\n HEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE ***************************** \n\n\n");	
endtask : body
 
`endif  
