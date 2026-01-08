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

  bit [ADDR_WIDTH-1:0] temp_addr[NO_OF_SLAVES];
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


 ahbVirtualIdleSequence = AhbVirtualIdleSequence :: type_id :: create("ahbVirtualIdleSequence");

 ahbVirtualSingleWriteSequence = AhbVirtualSingleWriteSequence:: type_id :: create("ahbvirtualSingleWriteSequence");

 ahbVirtualSingleReadSequence = AhbVirtualSingleReadSequence :: type_id :: create("ahbVirtualSingleReadSequence");

foreach(ahbMasterWriteSequence[i])begin 
    if(!ahbMasterWriteSequence[i].randomize() with {
							      haddrSeq inside {[0:3000]};
                                                              hsizeSeq == WORD;
							      hwriteSeq ==1;
                                                              hmastlockSeq==0;
                                                              htransSeq == NONSEQ;
                                                              hburstSeq == SINGLE;
						              foreach(busyControlSeq[i]) busyControlSeq[i] dist {0:=100, 1:=0};}
 
                                                        ) begin
       `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualSingleWriteSequence")
    end
    temp_addr[i] = ahbMasterWriteSequence[i].haddrSeq;
    `uvm_info(get_type_name(), $sformatf("temp_addr[%0d] = %0h",i,temp_addr[i]), UVM_NONE)
   end


  foreach(ahbMasterReadSequence[i]) begin 
  if(!ahbMasterReadSequence[i].randomize() with {hsizeSeq == WORD;
							      haddrSeq == temp_addr[i];
                                                              hwriteSeq ==0;
                                                              hmastlockSeq==0;
                                                              htransSeq == NONSEQ;
                                                              hburstSeq == SINGLE;
                                                              foreach(busyControlSeq[i]) busyControlSeq[i] dist {0:=100, 1:=0};}

                                            ) begin
    `uvm_error(get_type_name(), "Randomization failed : Inside AhbVirtualReadFollowedByReadSequence")
  end
  `uvm_info(get_type_name(), $sformatf("temp_addr[%0d] = %0h",i,temp_addr[i]), UVM_NONE)
 end 
 
 foreach(ahbSlaveWriteSequence[i]) begin 
  ahbSlaveWriteSequence[i].randomize();
  ahbSlaveReadSequence[i].randomize();
 end




fork
       begin
       foreach(ahbMasterWriteSequence[i]) begin
         fork
            automatic int j = i;
            ahbMasterWriteSequence[j].start(p_sequencer.ahbMasterSequencer[j]);
         join_none
       end
       wait fork;

       begin
       foreach(ahbMasterReadSequence[i]) begin
         fork
            automatic int j = i;
            ahbMasterReadSequence[j].start(p_sequencer.ahbMasterSequencer[j]);
         join_any
       end
     //  wait fork;
       end

       end

       begin
       foreach(ahbSlaveWriteSequence[i]) begin
         fork
          automatic int j =i;
          ahbSlaveWriteSequence[j].start(p_sequencer.ahbSlaveSequencer[j]);
         join_none
        end
        wait fork;
       end
join



fork
       begin
       foreach(ahbMasterReadSequence[i]) begin
         fork
            automatic int j = i;
            ahbMasterReadSequence[j].start(p_sequencer.ahbMasterSequencer[j]);
         join_none
       end
       wait fork;
       end

 join

//ahbVirtualSingleWriteSequence.start(m_sequencer);
//ahbVirtualIdleSequence.start(m_sequencer);
//ahbVirtualSingleReadSequence.start(m_sequencer);

endtask : body
 
`endif  
