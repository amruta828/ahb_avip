`ifndef AHBMASTERSEQUENCE_INCLUDED_
`define AHBMASTERSEQUENCE_INCLUDED_

class AhbMasterSequence extends AhbMasterBaseSequence;
  `uvm_object_utils(AhbMasterSequence)
 
  AhbMasterTransaction req;
  
  rand bit [ADDR_WIDTH-1:0] haddr_list[$]; 

  // Keep existing variables for other properties
  rand bit [NO_OF_SLAVES-1:0] hselxSeq;
  rand ahbBurstEnum hburstSeq;
  rand bit hmastlockSeq;
  rand ahbProtectionEnum hprotSeq;
  rand ahbHsizeEnum hsizeSeq;
  rand bit hnonsecSeq;
  rand bit hexclSeq;
  rand bit [HMASTER_WIDTH-1:0] hmasterSeq;
  rand ahbTransferEnum htransSeq;
  rand bit [DATA_WIDTH-1:0] hwdataSeq[$:2**LENGTH];
  rand bit [(DATA_WIDTH/8)-1:0] hwstrbSeq[$:2**LENGTH];
  rand ahbOperationEnum hwriteSeq;
  rand bit hexokaySeq;
  rand bit busyControlSeq[];
   
  // Constraint to ensure we generate exactly 4 addresses (for the 4 writes/reads)
  constraint c_list_size { haddr_list.size() == 4; }

  // Apply address range constraints to every element in the list
  constraint addr_range_list { 
    foreach (haddr_list[i]) { soft haddr_list[i] inside {[0:2000]};
    }
  }

  // Apply alignment constraints to every element in the list
  constraint haddr_alignment_list {
    foreach (haddr_list[i]) {
      if (hsizeSeq == HALFWORD) {
        haddr_list[i][0] == 1'b0;      // Aligned to 2-byte boundary
      } else if (hsizeSeq == WORD) {
        haddr_list[i][1:0] == 2'b00;   // Aligned to 4-byte boundary
      } else if (hsizeSeq == DOUBLEWORD) {
        haddr_list[i][2:0] == 3'b000;  // Aligned to 8-byte boundary
      } else if (hsizeSeq == LINE4) {
        haddr_list[i][3:0] == 4'b0000; // Aligned to 16-byte boundary
      } else if (hsizeSeq == LINE8) {
        haddr_list[i][4:0] == 5'b00000;// Aligned to 32-byte boundary
      } else if (hsizeSeq == LINE16) {
        haddr_list[i][5:0] == 6'b000000;// Aligned to 64-byte boundary
      } else if (hsizeSeq == LINE32) {
        haddr_list[i][6:0] == 7'b0000000;// Aligned to 128-byte boundary
      }
    }
  }

  constraint first_trans_typ1 {
    if (hburstSeq == SINGLE) {
      soft htransSeq inside {IDLE, NONSEQ};
    } else {
      soft htransSeq == NONSEQ;
    }
  }

  constraint incr_trans_typ1 {
    if (hburstSeq != SINGLE) {
      if (htransSeq == IDLE)
        soft htransSeq == NONSEQ;
      else
        soft htransSeq == SEQ;
    }
  }

  constraint hselx_logic1 {
    if (htransSeq == IDLE)
      soft hselxSeq == '0;
    else 
      $onehot(hselxSeq);
  }

  constraint strobleValue1{
    foreach(hwstrbSeq[i]) { 
      if(hsizeSeq == BYTE) $countones(hwstrbSeq[i]) == 1;
      else if(hsizeSeq == HALFWORD) $countones(hwstrbSeq[i]) == 2;
      else if(hsizeSeq == WORD) $countones(hwstrbSeq[i]) == 4;
      else if(hsizeSeq == DOUBLEWORD) $countones(hwstrbSeq[i]) == 8;
    }
  }

  constraint burstsize1{
    if(hburstSeq == WRAP4 || hburstSeq == INCR4) hwdataSeq.size() == 4;
    else if(hburstSeq == WRAP8 || hburstSeq == INCR8) hwdataSeq.size() == 8;
    else if(hburstSeq == WRAP16 || hburstSeq == INCR16) hwdataSeq.size() == 16;
    else hwdataSeq.size() == 1;
  }

  constraint strobesize1{
    if(hburstSeq == WRAP4 || hburstSeq == INCR4) hwstrbSeq.size() == 4;
    else if(hburstSeq == WRAP8 || hburstSeq == INCR8) hwstrbSeq.size() == 8;
    else if(hburstSeq == WRAP16 || hburstSeq == INCR16) hwstrbSeq.size() == 16;
    else hwstrbSeq.size() == 1;
  }

  constraint busyState1{
    if(hburstSeq == WRAP4 || hburstSeq == INCR4) busyControlSeq.size() == 4;
    else if(hburstSeq == WRAP8 || hburstSeq == INCR8) busyControlSeq.size() == 8;
    else if(hburstSeq == WRAP16 || hburstSeq == INCR16) busyControlSeq.size() == 16;
    else busyControlSeq.size()==1;
  }

  constraint busyControlValue1{foreach(busyControlSeq[i]) if(i == 0 || i == busyControlSeq.size - 1) busyControlSeq[i] == 0;}
  constraint busyControlNextCycle1{foreach(busyControlSeq[i]) if(i < busyControlSeq.size()) if(busyControlSeq[i]) busyControlSeq[i + 1] != 1;}

  extern function new(string name ="AhbMasterSequence");
  extern task body();
  
endclass :AhbMasterSequence
    
function AhbMasterSequence::new(string name="AhbMasterSequence");
  super.new(name);
endfunction : new

task AhbMasterSequence::body();
  super.body();
  req = AhbMasterTransaction::type_id::create("req");
  
  foreach(haddr_list[k]) begin 
    start_item(req);
    `uvm_info("AHB", $sformatf("req is of type: %s", req.get_type_name()), UVM_LOW)

    if (!req.randomize() with {  
                  hselx      == hselxSeq;
                  hburst     == hburstSeq;             
                  haddr      == haddr_list[k]; 
                  hmastlock  == hmastlockSeq;
                  hprot      == hprotSeq;
                  hsize      == hsizeSeq;
                  hnonsec    == hnonsecSeq;
                  hexcl      == hexclSeq;
                  htrans     == htransSeq;
                  hwrite     == hwriteSeq;
                  hexokay    == hexokaySeq;
                  
                  foreach(hwdataSeq[i])
                  //hwdata[i]  == hwdataSeq[i];
                  foreach(hwstrbSeq[i])
                  hwstrb[i]     == hwstrbSeq[i];
                  foreach(busyControlSeq[i])
                  busyControl[i] == busyControlSeq[i];
                }) begin
      `uvm_fatal("AHB", "Randomization failed inside Master Sequence body")
    end
    
    $display("*****************************************master sequence***********************************");
    req.print();
    $display("********************************************************************************************");
    finish_item(req);
  end
  $display("MASTER SEQUENCE DONE "); 
endtask: body
`endif
