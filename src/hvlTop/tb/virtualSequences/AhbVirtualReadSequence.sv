`ifndef AHBVIRTUALREADSEQUENCE_INCLUDED_
`define AHBVIRTUALREADSEQUENCE_INCLUDED_
 
class AhbVirtualReadSequence extends AhbVirtualBaseSequence;
  `uvm_object_utils(AhbVirtualReadSequence)
 
  AhbMasterSequence ahbMasterSequence[NO_OF_MASTERS];
 
  AhbSlaveSequence ahbSlaveSequence[NO_OF_SLAVES];
 
  extern function new(string name ="AhbVirtualReadSequence");
  extern task body();
 
endclass : AhbVirtualReadSequence
 
function AhbVirtualReadSequence::new(string name ="AhbVirtualReadSequence");
  super.new(name);
endfunction : new
 
task AhbVirtualReadSequence::body();
  super.body();
  foreach(ahbMasterSequence[i])
    ahbMasterSequence[i] = AhbMasterSequence::type_id::create("ahbMasterSequence");
  foreach(ahbSlaveSequence[i])
    ahbSlaveSequence[i]= AhbSlaveSequence::type_id::create("ahbSlaveSequence");
  
  foreach(ahbMasterSequence[i])begin 
    if(!ahbMasterSequence[i].randomize() with {
                                                              hsizeSeq dist {BYTE:=1, HALFWORD:=1, WORD:=1};
							      hwriteSeq ==0;
                                                              htransSeq == SINGLE;
                                                              hburstSeq dist { 2:=1, 3:=1, 4:=1, 5:=2, 6:=2, 7:=2};
							      foreach(busyControlSeq[i]) busyControlSeq[i] dist {0:=100, 1:=0};}
 
                                                        ) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualReadSequence")
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
