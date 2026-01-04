import AhbGlobalPackage::*;

interface AhbInterconnect(
  input logic hclk,
  input logic hresetn,
  AhbInterface.ahbMasterinterconnectModport ahbMasterInterface[NO_OF_MASTERS],
  AhbInterface.ahbSlaveinterconnectModport ahbSlaveInterface[NO_OF_SLAVES]
);

  logic [ADDR_WIDTH-1:0] master_haddr[NO_OF_MASTERS];
  logic [2:0] master_hsize[NO_OF_MASTERS];
  logic [1:0] master_htrans[NO_OF_MASTERS];
  logic master_hwrite[NO_OF_MASTERS];
  logic [2:0] master_hburst[NO_OF_MASTERS];
  logic [3:0] master_hprot[NO_OF_MASTERS];
  logic master_hmastlock[NO_OF_MASTERS];
  logic [31:0] master_hwdata[NO_OF_MASTERS];

    logic [$clog2(NO_OF_MASTERS)-1:0] current_owner [NO_OF_SLAVES];
  logic slave_has_owner [NO_OF_SLAVES];
 logic [$clog2(NO_OF_MASTERS)-1:0] previous_owner [NO_OF_SLAVES];

  generate
    for (genvar m = 0; m < NO_OF_MASTERS; m++) begin : master_signal_collect
      always_comb begin
        master_haddr[m]     = ahbMasterInterface[m].haddr;
        master_hsize[m]     = ahbMasterInterface[m].hsize;
        master_htrans[m]    = ahbMasterInterface[m].htrans;
        master_hwrite[m]    = ahbMasterInterface[m].hwrite;
        master_hburst[m]    = ahbMasterInterface[m].hburst;
        master_hprot[m]     = ahbMasterInterface[m].hprot;
        master_hmastlock[m] = ahbMasterInterface[m].hmastlock;
        master_hwdata[m]    = ahbMasterInterface[m].hwdata;
      end
    end
  endgenerate

  logic slave_hreadyout[NO_OF_SLAVES];
  logic [31:0] slave_hrdata[NO_OF_SLAVES];
  logic [1:0] slave_hresp[NO_OF_SLAVES];

    logic[$clog2(NO_OF_MASTERS)-1:0]owner;


  generate
    for (genvar s = 0; s < NO_OF_SLAVES; s++) begin : slave_signal_collect
      always_comb begin
        slave_hreadyout[s] = ahbSlaveInterface[s].hreadyout;
        slave_hrdata[s]    = ahbSlaveInterface[s].hrdata;
        slave_hresp[s]     = ahbSlaveInterface[s].hresp;
      end
    end
  endgenerate


  typedef struct packed {
    logic [ADDR_WIDTH-1:0] haddr;
    logic [2:0]            hsize;
    logic [1:0]            htrans;
    logic                  hwrite;
    logic [2:0]            hburst;
    logic [3:0]            hprot;
    logic                  hmastlock;
    logic [$clog2(NO_OF_SLAVES)-1:0] target_slave;
    logic [$clog2(NO_OF_MASTERS)-1:0] master_id;
    logic                  valid;
  } addr_phase_t;

/*
  function automatic logic [$clog2(NO_OF_SLAVES)-1:0] decode_address(
    logic [ADDR_WIDTH-1:0] addr
  );
    return addr[ADDR_WIDTH-1:ADDR_WIDTH-$clog2(NO_OF_SLAVES)];
  endfunction
*/
  function automatic int decode_address(logic [ADDR_WIDTH-1:0] addr);
    return int'(addr >> SLAVE_MEMORY_SIZE); 
  endfunction

  addr_phase_t master_pipeline[NO_OF_MASTERS][2];
  logic [1:0] master_wr_ptr[NO_OF_MASTERS];
  logic [1:0] master_rd_ptr[NO_OF_MASTERS];
  logic [1:0] master_count[NO_OF_MASTERS];

  addr_phase_t slave_data_phase[NO_OF_SLAVES];
  logic [31:0] slave_hwdata_stable[NO_OF_SLAVES];

  // Round robin arbitration
  logic [$clog2(NO_OF_MASTERS)-1:0] rr_pointer[NO_OF_SLAVES];
  logic [NO_OF_MASTERS-1:0] master_request[NO_OF_SLAVES];
  logic [NO_OF_MASTERS-1:0] master_grant[NO_OF_SLAVES];

  generate
    for (genvar s = 0; s < NO_OF_SLAVES; s++) begin : request_gen
      for (genvar m = 0; m < NO_OF_MASTERS; m++) begin
        always_comb begin
          master_request[s][m] = (master_htrans[m] != 2'b00) && (decode_address(master_haddr[m]) == s);
        end
      end
    end
  endgenerate


generate
  for(genvar slaveLoop = 0; slaveLoop < NO_OF_SLAVES; slaveLoop++) begin
    for(genvar masterLoop = 0; masterLoop < NO_OF_MASTERS; masterLoop++) begin
      always_ff@(posedge hclk or negedge hresetn) begin
          // $info("FF BLOCK");
        if(!hresetn) begin
          current_owner[slaveLoop] <= '0;
          previous_owner[slaveLoop] <= '0;
          slave_has_owner[slaveLoop] <= 1'b0;
        end
        else begin
          // Update previous owner when current owner changes
          if(master_grant[slaveLoop][masterLoop] == 1'b1) begin
            previous_owner[slaveLoop] <= current_owner[slaveLoop];  // Store current as previous
            current_owner[slaveLoop] <= masterLoop;                // Update current
            slave_has_owner[slaveLoop] <= 1'b1;
          end
          
          if(slave_has_owner[slaveLoop]) begin
            owner = current_owner[slaveLoop];
            if(master_request[slaveLoop][masterLoop] &&
               (ahbMasterInterface[masterLoop].htrans == 2'b00) &&  // IDLE
               !ahbMasterInterface[masterLoop].hmastlock && 
               current_owner[slaveLoop] == masterLoop) begin        // No lock
              previous_owner[slaveLoop] <= current_owner[slaveLoop]; // Store current as previous before releasing
              slave_has_owner[slaveLoop] <= 1'b0;
            end
          end
        end
      end
    end
  end
endgenerate



generate 
  for(genvar gs=0;gs<NO_OF_SLAVES;gs++) begin 
    for(genvar gm=0;gm<NO_OF_MASTERS;gm++) begin 
     always_comb begin
       $info("THE REQ IS %0b for the slave %0d",master_request[gs],gs); 
       $info("THE GRANT IS %0d for the slave %0d",master_grant[gs][gm],gs);
       $display("THE ADDRESS IS %0b for the master =%0d",ahbMasterInterface[gm].haddr,gm);


      end 

    end 
  end 
endgenerate
  // Arbitration logic
  generate
    for (genvar s = 0; s < NO_OF_SLAVES; s++) begin : arbitration
      always_ff @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
          rr_pointer[s] <= 0;
        end else if (|master_grant[s]) begin
          for (int m = 0; m < NO_OF_MASTERS; m++) begin
        //    $info("ITERATION");
            if (master_grant[s][m]) begin
              rr_pointer[s] <= (m + 1) % NO_OF_MASTERS;
              break;
            end
          end
        end
      end

      always_comb begin
        logic can_accept;
        logic locked_present;
        master_grant[s] = '0;
        //  $info("ALWAST");
        for(int i=0;i<NO_OF_MASTERS;i++) 
         if(master_request[s][i]) 
           if(master_hmastlock[i]==1) begin 
              locked_present=1;
              break;
           end 

        can_accept = !slave_data_phase[s].valid || slave_hreadyout[s];




       if(locked_present==1 && can_accept==1) 
          for (int i = 0; i < NO_OF_MASTERS; i++) begin
            int master_idx;
            master_idx = (rr_pointer[s] + i) % NO_OF_MASTERS;
            if (master_request[s][master_idx] && master_hmastlock[master_idx]==1) begin
              master_grant[s][master_idx] = 1'b1;
              break;
            end
          end
        else if(can_accept == 1 && master_htrans[current_owner[s]] == 2'b 11 && slave_has_owner[s]==1) 
          master_grant[s][current_owner[s]] =1;
        else if (can_accept) begin
          for (int i = 0; i < NO_OF_MASTERS; i++) begin
            int master_idx;
            master_idx = (rr_pointer[s] + i) % NO_OF_MASTERS;
            if (master_request[s][master_idx] && master_htrans[master_idx] != 2'b 00) begin
               $info("dead case");
              master_grant[s][master_idx] = 1'b1;
              break;
            end
          end
        end
      end
    end
  endgenerate

 /* generate
    for (genvar m = 0; m < NO_OF_MASTERS; m++) begin : master_pipeline_mgmt
      logic push_req, pop_req;

      always_comb begin
        //$info("ALWASY");
        if (!hresetn) begin
          for (int i = 0; i < 2; i++) master_pipeline[m][i] <= '0;
          master_wr_ptr[m] <= '0;
          master_rd_ptr[m] <= '0;
          master_count[m] <= '0;
        end else begin
          // Check for push (grant received)
          push_req = 1'b0;
          for (int s = 0; s < NO_OF_SLAVES; s++) begin
            if (master_grant[s][m]) push_req = 1'b1;
          end

          pop_req = 1'b0;
          if (master_count[m] > 0) begin
            logic [$clog2(NO_OF_SLAVES)-1:0] target_slave;
            target_slave = master_pipeline[m][master_rd_ptr[m]].target_slave;
            pop_req = slave_hreadyout[target_slave] && master_pipeline[m][master_rd_ptr[m]].valid;
          end

          if (push_req && master_count[m] < 2) begin
            master_pipeline[m][master_wr_ptr[m]].haddr        <= master_haddr[m];
            master_pipeline[m][master_wr_ptr[m]].hsize        <= master_hsize[m];
            master_pipeline[m][master_wr_ptr[m]].htrans       <= master_htrans[m];
            master_pipeline[m][master_wr_ptr[m]].hwrite       <= master_hwrite[m];
            master_pipeline[m][master_wr_ptr[m]].hburst       <= master_hburst[m];
            master_pipeline[m][master_wr_ptr[m]].hprot        <= master_hprot[m];
            master_pipeline[m][master_wr_ptr[m]].hmastlock    <= master_hmastlock[m];
            master_pipeline[m][master_wr_ptr[m]].target_slave <= decode_address(master_haddr[m]);
            master_pipeline[m][master_wr_ptr[m]].master_id    <= m;
            master_pipeline[m][master_wr_ptr[m]].valid        <= 1'b1;
            master_wr_ptr[m] <= (master_wr_ptr[m] + 1) % 2;
          end

          if (pop_req) begin
            master_pipeline[m][master_rd_ptr[m]].valid <= 1'b0;
            master_rd_ptr[m] <= (master_rd_ptr[m] + 1) % 2;
          end

          case ({push_req, pop_req})
            2'b10: master_count[m] <= master_count[m] + 1;
            2'b01: master_count[m] <= master_count[m] - 1;
            default: master_count[m] <= master_count[m];
          endcase
        end
      end
    end
  endgenerate*/

 generate 
  for(genvar m=0;m<NO_OF_MASTERS;m++) begin  
   always_comb begin

    for(int s = 0;s < NO_OF_SLAVES;s++) 
        if( m == current_owner[s])
            ahbMasterInterface[m].hrdata = slave_hrdata[s]; 

   end

  end
endgenerate 



  generate
    for (genvar s = 0; s < NO_OF_SLAVES; s++) begin : slave_data_mgmt
      logic new_data_phase_starting;

      always_comb begin
	//$info("ALWASY");
        if (!hresetn) begin
          slave_data_phase[s] <= '0;
          slave_hwdata_stable[s] <= '0;
          new_data_phase_starting <= 1'b0;
        end else begin
          new_data_phase_starting <= |master_grant[s];
           slave_hwdata_stable[s] = master_hwdata[current_owner[s]];
           
          if (|master_grant[s]) begin
            for (int m = 0; m < NO_OF_MASTERS; m++) begin
              if (master_grant[s][m]) begin
                slave_data_phase[s].haddr        <= master_haddr[m];
                slave_data_phase[s].hsize        <= master_hsize[m];
                slave_data_phase[s].htrans       <= master_htrans[m];
                slave_data_phase[s].hwrite       <= master_hwrite[m];
                slave_data_phase[s].hburst       <= master_hburst[m];
                slave_data_phase[s].hprot        <= master_hprot[m];
                slave_data_phase[s].hmastlock    <= master_hmastlock[m];
                slave_data_phase[s].target_slave <= s;
                slave_data_phase[s].master_id    <= m;
                slave_data_phase[s].valid        <= 1'b1;
                break;
              end
            end
          end else if (slave_data_phase[s].valid && slave_hreadyout[s]) begin
            slave_data_phase[s].valid <= 1'b0;
          end

        end
      end
    end
  endgenerate

  generate
    for (genvar s = 0; s < NO_OF_SLAVES; s++) begin : slave_interface
      always_comb begin
        //$info("ALWAYS");
             ahbSlaveInterface[s].hwdata     = slave_hwdata_stable[s];
        //if (slave_data_phase[s].valid && slave_hreadyout[s]) begin
          ahbSlaveInterface[s].haddr      = slave_data_phase[s].haddr;
          ahbSlaveInterface[s].hsize      = slave_data_phase[s].hsize;
          ahbSlaveInterface[s].htrans     = slave_data_phase[s].htrans;
          ahbSlaveInterface[s].hwrite     = slave_data_phase[s].hwrite;
          ahbSlaveInterface[s].hburst     = slave_data_phase[s].hburst;
          ahbSlaveInterface[s].hprot      = slave_data_phase[s].hprot;
          ahbSlaveInterface[s].hmastlock  = slave_data_phase[s].hmastlock;
          ahbSlaveInterface[s].hselx      = 1'b1;

          ahbSlaveInterface[s].hwdata     = slave_hwdata_stable[s];
        //end
  /* else begin
          ahbSlaveInterface[s].haddr      = '0;
          ahbSlaveInterface[s].hsize      = '0;
          ahbSlaveInterface[s].htrans     = 2'b00; // IDLE
          ahbSlaveInterface[s].hwrite     = 1'b0;
          ahbSlaveInterface[s].hburst     = '0;
          ahbSlaveInterface[s].hprot      = '0;
          ahbSlaveInterface[s].hmastlock  = 1'b0;
          ahbSlaveInterface[s].hselx      = 1'b0;
          ahbSlaveInterface[s].hwdata     = '0;
        end*/
      end
    end
  endgenerate

  generate
    for (genvar m = 0; m < NO_OF_MASTERS; m++) begin : master_interface
      logic oldest_is_valid;
      logic oldest_is_ready;
      //logic pipeline_has_space;
      logic can_accept_new_transfer;

      always_comb begin
	//$info("ALWAYS");
        //ahbMasterInterface[m].hrdata = '0;
        ahbMasterInterface[m].hresp  = 2'b00;

 //       oldest_is_valid = (master_count[m] > 0) && master_pipeline[m][master_rd_ptr[m]].valid;
      oldest_is_ready = 1'b1; // Default to ready if no active transaction

        for(int s=0;s <NO_OF_SLAVES;s++)
         if(m == owner[s])
           begin 
            oldest_is_ready = slave_hreadyout[s];        
           end 
        //pipeline_has_space = (master_count[m] < 2);

        can_accept_new_transfer = 1'b0;
        if (master_htrans[m] != 2'b00) begin
          for (int s = 0; s < NO_OF_SLAVES; s++) begin
            if (master_grant[s][m]) begin
              can_accept_new_transfer = 1'b1;
              break;
            end
          end
        end

        if (master_htrans[m] == 2'b00) begin
          ahbMasterInterface[m].hready = 1'b1;
        end else begin
          ahbMasterInterface[m].hready = can_accept_new_transfer && oldest_is_ready;
        end
      end
    end
  endgenerate

endinterface
