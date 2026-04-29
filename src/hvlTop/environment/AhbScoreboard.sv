`ifndef AHBSCOREBOARD_INCLUDED_
`define AHBSCOREBOARD_INCLUDED_

class AhbScoreboard extends uvm_scoreboard;
  `uvm_component_utils(AhbScoreboard)

  AhbMasterTransaction ahbMasterTransaction;

  AhbSlaveTransaction ahbSlaveTransaction;

  AhbEnvironmentConfig ahbEnvironmentConfig;

  uvm_tlm_analysis_fifo#(AhbMasterTransaction) ahbMasterAnalysisFifo[];

  uvm_tlm_analysis_fifo#(AhbSlaveTransaction) ahbSlaveAnalysisFifo[];

  int ahbMasterTransactionCount = 0;

  int ahbSlaveTransactionCount = 0;

  int VerifiedMasterHwdataCount = 0;

  int FailedMasterHwdataCount = 0;

  int VerifiedMasterHaddrCount = 0;

  int FailedMasterHaddrCount = 0;

  int VerifiedMasterHwriteCount = 0;

  int FailedMasterHwriteCount = 0;

  int VerifiedSlaveHrdataCount = 0;

  int FailedSlaveHrdataCount = 0;

  int VerifiedMasterHprotCount;

  int FailedMasterHprotCount;

  int indexMaster;
  
  typedef struct {
   int haddr;
   int master;
  }grant_info_t;

  grant_info_t g;
  grant_info_t g_m;
  grant_info_t expected_grant_q[int][$];


  int master_request_q[int][$];   
  int rr_pointer[NO_OF_SLAVES];   // round robin pointer

  int indexSlave;
  bit [7:0] mem[int][int];

  AhbMasterTransaction slave_expected_q[int][$];
  int slave_expected_id_q[int][$];

  bit [ADDR_WIDTH-1:0] SLAVE_START_ADDR[];
  bit [ADDR_WIDTH-1:0] SLAVE_END_ADDR[];

  extern function new(string name = "AhbScoreboard", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void check_phase (uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase);

  extern function int get_slave_index(logic [ADDR_WIDTH-1:0] addr);
  extern function void ref_model(AhbMasterTransaction m_tx, int slave_idx);
  extern function void compare_trans(AhbMasterTransaction exp_tx, AhbSlaveTransaction s_tx, int s_idx);

  extern function int predict_grant(int slave_idx);
endclass : AhbScoreboard


function AhbScoreboard::new(string name = "AhbScoreboard",uvm_component parent = null);
  super.new(name, parent);
  ahbMasterAnalysisFifo = new[NO_OF_MASTERS];
  ahbSlaveAnalysisFifo = new[NO_OF_SLAVES];

  foreach(ahbMasterAnalysisFifo[i]) begin
    ahbMasterAnalysisFifo[i] = new($sformatf("ahbMasterAnalysisFifo[%0d]",i),this);
  end

  foreach(ahbSlaveAnalysisFifo[i]) begin
    ahbSlaveAnalysisFifo[i] = new($sformatf("ahbSlaveAnalysisFifo[%0d]",i),this);
  end
endfunction : new


function void AhbScoreboard::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db #(AhbEnvironmentConfig)::get(this,"","AhbEnvironmentConfig",ahbEnvironmentConfig)) begin
    `uvm_fatal("FATAL_ENV_CONFIG", $sformatf("AhbScoreboard :: Couldn't get the env_config from config_db"))
  end

  SLAVE_START_ADDR = new[NO_OF_SLAVES];
  SLAVE_END_ADDR   = new[NO_OF_SLAVES];

  foreach(ahbEnvironmentConfig.ahbSlaveAgentConfig[i]) begin
    SLAVE_START_ADDR[i] = ahbEnvironmentConfig.ahbSlaveAgentConfig[i].minimumAddress;
    SLAVE_END_ADDR[i]   = ahbEnvironmentConfig.ahbSlaveAgentConfig[i].maximumAddress;
  end
endfunction : build_phase

function int AhbScoreboard::get_slave_index(logic [ADDR_WIDTH-1:0] addr);
  logic [ADDR_WIDTH-1:0] slave_size;
  logic [ADDR_WIDTH-1:0] start_addr;
  logic [ADDR_WIDTH-1:0] end_addr;

  slave_size = (1 << SLAVE_MEMORY_SIZE);

  for (int i = 0; i < NO_OF_SLAVES; i++) begin
    start_addr = i * slave_size;
    end_addr   = start_addr + slave_size;

    if (addr >= start_addr && addr < end_addr) begin
      return i;
    end
  end

  return -1;
endfunction


function void AhbScoreboard::ref_model( AhbMasterTransaction m_tx, int slave_idx );

  int bytes_per_beat;
  int beat_addr;

  bytes_per_beat = 1 << m_tx.hsize;

  // ---------------- WRITE OPERATION ----------------
  if (m_tx.hwrite == WRITE) begin

    foreach (m_tx.hwdata[i]) begin
      beat_addr = m_tx.haddr + (i * bytes_per_beat);

      for (int j = 0; j < bytes_per_beat; j++) begin
        if (m_tx.hwstrb[i][j]) begin
          mem[slave_idx][beat_addr + j] = m_tx.hwdata[i][8*j +: 8];
          `uvm_info("REF_MODEL_WRITE", $sformatf("SLAVE=%0d ADDR=0x%0h DATA=0x%02h (beat=%0d byte=%0d)",slave_idx,(beat_addr + j), m_tx.hwdata[i][8*j +: 8], i,j),UVM_LOW);
        end
      end
    end

  end

  // ---------------- READ OPERATION ----------------
  else begin
    logic [31:0] assembled_data; 

    // Clear the queue 
    m_tx.hrdata.delete();

    //Populate the queue by reading from Memory for the CURRENT BEAT ONLY
    beat_addr = m_tx.haddr;
    assembled_data = '0; 

    // Assemble 8-bit memory locations into a 32-bit word
    for (int k = 0; k < bytes_per_beat; k++) begin
      if (mem[slave_idx].exists(beat_addr + k)) begin
        assembled_data[8*k +: 8] = mem[slave_idx][beat_addr + k];
      end 
      else begin
        assembled_data[8*k +: 8] = 8'h00;
      end
    end
  
    // Push only the single beat data to match the monitor's behavior
    m_tx.hrdata.push_back(assembled_data);

    `uvm_info("REF_MODEL_READ",$sformatf("SLAVE=%0d ADDR=0x%0h DATA=0x%0h", slave_idx, beat_addr, assembled_data), UVM_LOW)
  end
endfunction


task AhbScoreboard::run_phase(uvm_phase phase);
  super.run_phase(phase);

  foreach(ahbMasterAnalysisFifo[i]) begin
    automatic int m_idx = i;
    fork
      forever begin
        AhbMasterTransaction m_tx, exp_tx;
        int s_idx;
	int temp;
        ahbMasterAnalysisFifo[m_idx].get(m_tx);
 	$display("[%0t] run phase got m_tx haddr=%0d, mtx=%0d, htrans= %0d ",$time,m_tx.haddr,i,m_tx.htrans);//debug
        m_tx.print();
  
	// Ignore IDLE and BUSY transactions from the Masters
        if (m_tx.htrans == IDLE || m_tx.htrans == BUSY) continue;
         
        ahbMasterTransactionCount++;
        s_idx = get_slave_index(m_tx.haddr);

        // if(m_tx.htrans != IDLE && m_tx.htrans != BUSY) begin
	if(m_tx.htrans != IDLE || m_tx.htrans != BUSY) begin
   	  if(!master_request_q.exists(s_idx))
      	    master_request_q[s_idx] = {};
   	  master_request_q[s_idx].push_back(m_idx);
  	  $display("[%0t] Master %0d requested Slave %0d addr=%0d, master_requested_q = %p",$time,m_idx, s_idx, m_tx.haddr,master_request_q);//debug
	end

        if(m_tx.htrans == 2'b10)
    	  temp = predict_grant(s_idx);

	g_m.haddr  = m_tx.haddr;
	g_m.master = temp;
	  
        expected_grant_q[s_idx].push_back(g_m);

	$display("[%0t] MASTER: predicted grant=%0d for slave %0d haddr = %0d", $time, temp, s_idx,m_tx.haddr);//debug
	if(s_idx != -1) begin
          $cast(exp_tx, m_tx.clone());
          ref_model(exp_tx, s_idx);
	  if(m_tx.hwrite==0)begin
	    if(m_tx.hrdata === exp_tx.hrdata)
	      `uvm_info("SCB",$sformatf("hrdata match found"),UVM_LOW)
	    else
	      `uvm_error("SCB",$sformatd("hrdata mismatch found - m_tx = %0d, exp_tx = %0d",m_tx.hrdata,exp_tx.hrdata))
	  end
          slave_expected_q[s_idx].push_back(exp_tx);
          slave_expected_id_q[s_idx].push_back(m_idx);
        end
      end
    join_none
  end

  foreach(ahbSlaveAnalysisFifo[i]) begin
    automatic int s_idx = i;
    fork
      forever begin
        AhbSlaveTransaction s_tx;
        AhbMasterTransaction exp_tx;
        int master_id;
        int found_idx;
	int exp_master;
	int found = 0;	

        ahbSlaveAnalysisFifo[s_idx].get(s_tx);
 	$display("run phase got s_tx");//debug
	s_tx.print();

        // Ignore IDLE and BUSY transactions broadcasted by the Slave monitor
        if (s_tx.htrans == IDLE || s_tx.htrans == BUSY) continue;

        // Ignore empty Address-Phase packets (must wait for the data phase packet)
        if (s_tx.hwrite == READ && s_tx.hrdata.size() == 0) continue;
        if (s_tx.hwrite == WRITE && s_tx.hwdata.size() == 0) continue;

        ahbSlaveTransactionCount++;
        wait(slave_expected_q[s_idx].size() > 0);

   	wait(expected_grant_q.exists(s_idx) && expected_grant_q[s_idx].size() > 0);

	foreach(expected_grant_q[s_idx][i]) begin
   	  if(expected_grant_q[s_idx][i].haddr == s_tx.haddr) begin
            g = expected_grant_q[s_idx][i];
     	    expected_grant_q[s_idx].delete(i);
	    $display("expected_grant_q = %p",expected_grant_q);//debug
            found = 1;
      	    break;
   	  end
	end

	if(!found) begin
   	  `uvm_error("SYNC", "No matching expected grant found")
	end

 	$display("[%0t] SLAVE: addr=%0d exp_master=%0d ",$time, s_tx.haddr, g.master);//debug

        // Search for the matching expected transaction
        found_idx = -1;
        for (int j = 0; j < slave_expected_q[s_idx].size(); j++) begin
          if (slave_expected_q[s_idx][j].haddr == s_tx.haddr && slave_expected_q[s_idx][j].hwrite == s_tx.hwrite) begin
            found_idx = j;
            break;
          end
        end

        // Extract the matching transaction
        if (found_idx != -1) begin
          exp_tx = slave_expected_q[s_idx][found_idx];
          slave_expected_q[s_idx].delete(found_idx);
          master_id = slave_expected_id_q[s_idx][found_idx];
          slave_expected_id_q[s_idx].delete(found_idx);
        end 
        else begin
          // Fallback to prevent stall
          exp_tx = slave_expected_q[s_idx].pop_front();
          master_id = slave_expected_id_q[s_idx].pop_front();
        end

        // Compare the aligned transactions
        compare_trans(exp_tx, s_tx,s_idx);
  	$display("sending to compare");//debug
        $display("exp_tx");
	exp_tx.print();
  	$display("s_tx");
	s_tx.print(); 

      end
    join_none
  end

  wait fork;
endtask : run_phase


function int AhbScoreboard::predict_grant(int slave_idx);
  int m;
  int idx_q[$];

  if (!master_request_q.exists(slave_idx) || master_request_q[slave_idx].size() == 0) begin
    $display("[%0t] No requests for slave %0d", $time, slave_idx);//debug
    return -1;
  end

  $display("[%0t] QUEUE[%0d]=%p , rr_pointer=%0d", $time, slave_idx, master_request_q[slave_idx], rr_pointer[slave_idx]);//debug

  for (int i = 0; i < NO_OF_MASTERS; i++) begin

    m= (rr_pointer[slave_idx] + i) % NO_OF_MASTERS;

    $display("[%0t] Checking master %0d", $time, m);//debug
    idx_q = master_request_q[slave_idx].find_index(x) with (x == m);

    if (idx_q.size() > 0) begin
      rr_pointer[slave_idx] = (m + 1) % NO_OF_MASTERS;
      master_request_q[slave_idx].delete(idx_q[0]);
      $display("[%0t] GRANT=%0d , NEW rr_pointer=%0d , UPDATED QUEUE=%p", $time, m, rr_pointer[slave_idx], master_request_q[slave_idx]);//debug
      return m;
    end
  end

  // No valid master found
  $display("[%0t] No matching master found", $time);//debug
  return -1;

endfunction


function void AhbScoreboard::compare_trans( AhbMasterTransaction exp_tx, AhbSlaveTransaction  s_tx, int s_idx);

  exp_tx.print;
  $display("NIHAL EXP");//debug

  s_tx.print;
  $display("NIHAL S_tx");//debug

  if (exp_tx.hwrite === s_tx.hwrite) begin
    VerifiedMasterHwriteCount++;
  end
  else begin
    FailedMasterHwriteCount++;
  end

  // ---------------- READ ----------------
  if (s_tx.hwrite == READ) begin
    `uvm_info(get_type_name(),"---------------- AHB SCOREBOARD [READ] ----------------",UVM_LOW)

    // Address
    if (exp_tx.haddr === s_tx.haddr) begin
      `uvm_info("SB_HADDR_MATCH",$sformatf("HADDR Match: %h actual=%h  s_idx = %0d", exp_tx.haddr,s_tx.haddr,s_idx),UVM_HIGH)
      VerifiedMasterHaddrCount++;
    end
    else begin
      `uvm_error("SB_HADDR_MISMATCH",$sformatf("HADDR Mismatch: Exp=%h Act=%h, s_idx = %0d",exp_tx.haddr, s_tx.haddr,s_idx))
      FailedMasterHaddrCount++;
    end

    // Read Data (BURST SAFE)
    $display("EXP s_tx HRDATA:%p",s_tx.hrdata);//debug
    $display("EXP exp_tx HRDATA:%p",exp_tx.hrdata);//debug
    foreach (exp_tx.hrdata[i]) begin
      $display("2addr");

      if (exp_tx.hrdata[i] !== s_tx.hrdata[i]) begin
        `uvm_error("SB_HRDATA_MISMATCH",$sformatf("HRDATA mismatch at beat %0d: Exp=%h Act=%h", i, exp_tx.hrdata[i], s_tx.hrdata[i]))
          FailedSlaveHrdataCount++;
      end
      else begin
        `uvm_info("SB_HRDATA_MATCH", $sformatf("HRDATA match at beat %0d: %h", i, exp_tx.hrdata[i]), UVM_LOW)
          VerifiedSlaveHrdataCount++;
      end
    end
    // HPROT
    if (exp_tx.hprot === s_tx.hprot)
      `uvm_info("SB_HPROT_MATCH", "HPROT Match", UVM_LOW)
    else
      `uvm_error("SB_HPROT_MISMATCH", "HPROT Mismatch")

    // HSIZE
    if (exp_tx.hsize === s_tx.hsize)
      `uvm_info("SB_HSIZE_MATCH", "HSIZE Match", UVM_LOW)
    else
      `uvm_error("SB_HSIZE_MISMATCH", "HSIZE Mismatch")

    `uvm_info(get_type_name(),
      "-------------- END READ COMPARISON ----------------",
      UVM_LOW)
  end

  // ---------------- WRITE ----------------
  else if (exp_tx.hwrite == WRITE) begin
    `uvm_info(get_type_name(),"---------------- AHB SCOREBOARD [WRITE] ----------------", UVM_LOW)
    // Address
    if (exp_tx.haddr === s_tx.haddr) begin
      `uvm_info("SB_HADDR_MATCH",$sformatf("HADDR Match: %h, s_idx = %0d", exp_tx.haddr,s_idx), UVM_HIGH)
      VerifiedMasterHaddrCount++;
    end
    else begin
      `uvm_error("SB_HADDR_MISMATCH",$sformatf("HADDR Mismatch: Exp=%h Act=%h , s_idx = %0d",exp_tx.haddr, s_tx.haddr,s_idx))
      FailedMasterHaddrCount++;
    end

    // Write Data (BURST SAFE)
    if (exp_tx.hwdata.size() != s_tx.hwdata.size()) begin
      `uvm_error("SB_HWDATA_SIZE_MISMATCH",$sformatf("HWDATA size mismatch: Exp=%0d Act=%0d", exp_tx.hwdata.size(), s_tx.hwdata.size()))
    end
    else begin
      foreach (exp_tx.hwdata[i]) begin
        if (exp_tx.hwdata[i] !== s_tx.hwdata[i]) begin
          `uvm_error("SB_HWDATA_MISMATCH",$sformatf("HWDATA mismatch at beat %0d: Exp=%h Act=%h , s_idx= %0d", i, exp_tx.hwdata[i], s_tx.hwdata[i],s_idx))
          FailedMasterHwdataCount++;
        end
        else begin
          `uvm_info("SB_HWDATA_MATCH",$sformatf("HWDATA match at beat %0d: %h, s_idx = %0d", i, exp_tx.hwdata[i],s_idx),UVM_LOW)
          VerifiedMasterHwdataCount++;
        end
      end
    end

    // HPROT
    if (exp_tx.hprot === s_tx.hprot)
      `uvm_info("SB_HPROT_MATCH", "HPROT Match", UVM_LOW)
    else
      `uvm_error("SB_HPROT_MISMATCH", "HPROT Mismatch")

    // HSIZE
    if (exp_tx.hsize === s_tx.hsize)
      `uvm_info("SB_HSIZE_MATCH", "HSIZE Match", UVM_LOW)
    else
      `uvm_error("SB_HSIZE_MISMATCH", "HSIZE Mismatch")

    `uvm_info(get_type_name(),
      "-------------- END WRITE COMPARISON ----------------",
      UVM_LOW)
  end

endfunction

function void AhbScoreboard::check_phase(uvm_phase phase);
  super.check_phase(phase);

  `uvm_info(get_type_name(),$sformatf("--\n----------------------------------------------SCOREBOARD CHECK PHASE---------------------------------------"),UVM_HIGH)
  `uvm_info (get_type_name(),$sformatf(" Scoreboard Check Phase is starting"),UVM_HIGH);

  if (ahbMasterTransactionCount == ahbSlaveTransactionCount) begin
    `uvm_info (get_type_name(), $sformatf ("master and slave have equal no. of transactions = %0d",ahbMasterTransactionCount),UVM_HIGH);
    `uvm_info (get_type_name(), $sformatf ("ahbMasterTransactionCount : %0d",ahbMasterTransactionCount ),UVM_HIGH);
    `uvm_info (get_type_name(), $sformatf ("ahbSlaveTransactionCount : %0d",ahbSlaveTransactionCount),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("ahbMasterTransactionCount : %0d",ahbMasterTransactionCount ),UVM_HIGH);
    `uvm_info (get_type_name(), $sformatf ("ahbSlaveTransactionCount  : %0d",ahbSlaveTransactionCount  ),UVM_HIGH);
    `uvm_error ("SC_CheckPhase", $sformatf ("master and slave doesnot have same no.of transactions"));
  end

  if(ahbEnvironmentConfig.operationMode == WRITE_READ) begin
    if (( VerifiedMasterHwdataCount != 0) && (FailedMasterHwdataCount == 0)) begin
      `uvm_info (get_type_name(), $sformatf ("master and slave writeData comparisions are equal = %0d",VerifiedMasterHwdataCount),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("VerifiedMasterHwdataCount :%0d",VerifiedMasterHwdataCount),UVM_HIGH);
      `uvm_info (get_type_name(), $sformatf ("FailedMasterHwdataCount : %0d", FailedMasterHwdataCount),UVM_HIGH);
      `uvm_error ("SC_CheckPhase", $sformatf ("master and slave writeData comparisions Not equal"));
    end

    if ((VerifiedSlaveHrdataCount != 0) && (FailedSlaveHrdataCount == 0) ) begin
      `uvm_info (get_type_name(), $sformatf ("master and slave readData comparisions are equal = %0d",VerifiedSlaveHrdataCount),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("VerifiedSlaveHrdataCount :%0d", VerifiedSlaveHrdataCount),UVM_HIGH);
      `uvm_info (get_type_name(), $sformatf ("FailedSlaveHrdataCount : %0d", FailedSlaveHrdataCount),UVM_HIGH);
      `uvm_error ("SC_CheckPhase", $sformatf ("master and slave readData comparisions Not equal"));
    end
  end
  else if(ahbEnvironmentConfig.operationMode == WRITE) begin

    if (( VerifiedMasterHwdataCount != 0) && (FailedMasterHwdataCount == 0)) begin
      `uvm_info (get_type_name(), $sformatf ("master and slave writeData comparisions are equal = %0d",VerifiedMasterHwdataCount),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("VerifiedMasterHwdataCount :%0d", VerifiedMasterHwdataCount),UVM_HIGH);
      `uvm_info (get_type_name(), $sformatf ("FailedMasterHwdataCount : %0d",FailedMasterHwdataCount),UVM_HIGH);
      `uvm_error ("SC_CheckPhase", $sformatf ("master and slave writeData comparisions Not equal"));
    end
  end
  else if(ahbEnvironmentConfig.operationMode == READ) begin
    if ((VerifiedSlaveHrdataCount != 0) && (FailedSlaveHrdataCount == 0) ) begin
      `uvm_info (get_type_name(), $sformatf ("master and slave readData comparisions are equal = %0d",VerifiedSlaveHrdataCount),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("VerifiedSlaveHrdataCount :%0d",VerifiedSlaveHrdataCount),UVM_HIGH);
      `uvm_info (get_type_name(), $sformatf ("FailedSlaveHrdataCount : %0d", FailedSlaveHrdataCount),UVM_HIGH);
      `uvm_error ("SC_CheckPhase", $sformatf ("master and slave readData comparisions Not equal"));
    end
  end

  if ((VerifiedMasterHaddrCount != 0) && (FailedMasterHaddrCount == 0)) begin
    `uvm_info (get_type_name(), $sformatf ("master and slave address comparisions are equal = %0d",VerifiedMasterHaddrCount),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("VerifiedMasterHaddrCount :%0d", VerifiedMasterHaddrCount),UVM_HIGH);
    `uvm_info (get_type_name(), $sformatf ("FailedMasterHaddrCount : %0d", FailedMasterHaddrCount),UVM_HIGH);
    `uvm_error ("SC_CheckPhase", $sformatf ("master and slave address comparisions Not equal"));
  end

  if ((VerifiedMasterHwriteCount != 0) && (FailedMasterHwriteCount == 0)) begin
    `uvm_info (get_type_name(), $sformatf ("master and slave hwrite comparisions are equal = %0d",VerifiedMasterHwriteCount),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("VerifiedMasterHwriteCount :%0d", VerifiedMasterHwriteCount),UVM_HIGH);
    `uvm_info (get_type_name(), $sformatf ("FailedMasterHwriteCount : %0d", FailedMasterHwriteCount),UVM_HIGH);
    `uvm_error ("SC_CheckPhase", $sformatf ("master and slave hwrite comparisions Not equal"));
  end

  if( ahbMasterAnalysisFifo[indexMaster].size() == 0) begin
    `uvm_info ("SC_CheckPhase", $sformatf ("AHB Master analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf (" ahbMasterAnalysisFifo:%0d", ahbMasterAnalysisFifo[indexMaster].size() ),UVM_HIGH);
    `uvm_error ("SC_CheckPhase", $sformatf ("AHB Master analysis FIFO is not empty"));
  end

  if( ahbSlaveAnalysisFifo[indexSlave].size()== 0) begin
    `uvm_info ("SC_CheckPhase", $sformatf ("AHB Slave analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf (" ahbSlaveAnalysisFifo:%0d", ahbSlaveAnalysisFifo[indexSlave].size()),UVM_HIGH);
    `uvm_error ("SC_CheckPhase",$sformatf ("AHB Slave analysis FIFO is not empty"));
  end

  `uvm_info(get_type_name(),$sformatf("--\n----------------------------------------------END OF SCOREBOARD CHECK PHASE---------------------------------------"),UVM_HIGH)

endfunction : check_phase

function void AhbScoreboard::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info("scoreboard",$sformatf("--\n--------------------------------------------------Scoreboard Report-----------------------------------------------"),UVM_HIGH);

  `uvm_info (get_type_name(),$sformatf(" Scoreboard Report Phase is starting"),UVM_HIGH);

  `uvm_info (get_type_name(),$sformatf("No. of transactions from master:%0d", ahbMasterTransactionCount),UVM_HIGH);

  `uvm_info (get_type_name(),$sformatf("No. of transactions from slave:%0d", ahbSlaveTransactionCount ),UVM_HIGH);

  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise master_hwdata comparisions passed:%0d", VerifiedMasterHwdataCount),UVM_HIGH);

  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise master_paddr comparisions passed:%0d", VerifiedMasterHaddrCount),UVM_HIGH);

  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise master_hwrite comparisions passed:%0d", VerifiedMasterHwriteCount),UVM_HIGH);

  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise slave_prdata comparisions passed:%0d",VerifiedSlaveHrdataCount),UVM_HIGH);

  `uvm_info (get_type_name(),$sformatf("No. of byte wise master_hwdata comparision failed:%0d", FailedMasterHwdataCount),UVM_HIGH);

  `uvm_info (get_type_name(),$sformatf("No. of byte wise master_paddr comparision failed:%0d", FailedMasterHaddrCount),UVM_HIGH);

  `uvm_info (get_type_name(),$sformatf("No. of byte wise master_hwrite comparision failed:%0d",FailedMasterHwriteCount),UVM_HIGH);

  `uvm_info (get_type_name(),$sformatf("No. of byte wise slave_prdata comparision failed:%0d", FailedSlaveHrdataCount),UVM_HIGH);

  `uvm_info("scoreboard",$sformatf("--\n--------------------------------------------------End of Scoreboard Report-----------------------------------------------"),UVM_HIGH);

endfunction : report_phase

`endif
