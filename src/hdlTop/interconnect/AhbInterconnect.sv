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
  logic master_hready[NO_OF_MASTERS];//added
  logic [$clog2(NO_OF_MASTERS)-1:0] current_owner [NO_OF_SLAVES];
  logic [$clog2(NO_OF_MASTERS)-1:0] new_c_owner [NO_OF_SLAVES];
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
        master_hready[m] = ahbMasterInterface[m].hready; //added
      end
    end
  endgenerate

  logic slave_hreadyout[NO_OF_SLAVES];
  logic [31:0] slave_hrdata[NO_OF_SLAVES];
  logic [1:0] slave_hresp[NO_OF_SLAVES];

    logic[$clog2(NO_OF_MASTERS)-1:0]owner[NO_OF_SLAVES];


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


  function automatic logic [$clog2(NO_OF_SLAVES):0] decode_address(logic [ADDR_WIDTH-1:0] addr);
    logic [ADDR_WIDTH-1:0] slave_size;
    logic [ADDR_WIDTH-1:0] start_addr;
    logic [ADDR_WIDTH-1:0] end_addr;

    // Calculate the size of one slave (e.g., 1KB = 1024 bytes)
    slave_size = (1 << SLAVE_MEMORY_SIZE);

    for (int i = 0; i < NO_OF_SLAVES; i++) begin
      start_addr = i * slave_size;
      end_addr   = start_addr + slave_size;

      if (addr >= start_addr && addr < end_addr) begin
   $display("slave number %0d address %0d",i,addr);

   return i;

      end
    end
 $display("invalid  address %0d",addr);

    return NO_OF_SLAVES;
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
 logic [NO_OF_MASTERS-1:0] master_last_request[NO_OF_SLAVES];
 bit [$clog2(NO_OF_MASTERS)-1:0] last_request [NO_OF_SLAVES];
 bit flag[NO_OF_SLAVES];

  generate
    for (genvar s = 0; s < NO_OF_SLAVES; s++) begin : request_gen
      for (genvar m = 0; m < NO_OF_MASTERS; m++) begin
        always_comb begin
          master_request[s][m] = (decode_address(master_haddr[m]) == s)? 1: 'bx;//added
          //master_request[s][m] = ((master_htrans[m] != 2'b00) && (decode_address(master_haddr[m]) == s)) ? 1: 'bx;
        end
      end
    end
  endgenerate


generate
  for(genvar slaveLoop = 0; slaveLoop < NO_OF_SLAVES; slaveLoop++) begin
    //for(genvar masterLoop = 0; masterLoop < NO_OF_MASTERS; masterLoop++) begin
      always_ff@(posedge hclk or negedge hresetn) begin
          // $info("FF BLOCK");
        if(!hresetn) begin
          current_owner[slaveLoop] <= 'bx;
          previous_owner[slaveLoop] <= '0;
          slave_has_owner[slaveLoop] <= 1'b0;
        end
        else begin
        for(int masterLoop=0;masterLoop < NO_OF_MASTERS; masterLoop++) begin
          // Update previous owner when current owner changes
          if(master_grant[slaveLoop][masterLoop] == 1'b1) begin
            $display($time," first master_grant[slaveloop=%0d][masterloop=%0d]=%0d",slaveLoop,masterLoop,master_grant[slaveLoop][masterLoop]);
            previous_owner[slaveLoop] <= current_owner[slaveLoop];  // Store current as previous
            current_owner[slaveLoop] <= masterLoop;                // Update current
            new_c_owner[slaveLoop]   <= masterLoop;
	    $display("[%0t] current_owner[%0d] = %0d",$time,slaveLoop,current_owner[slaveLoop]);
	    $display("[%0t] new_c_owner[%0d] = %0d",$time,slaveLoop,new_c_owner[slaveLoop]);
            slave_has_owner[slaveLoop] <= 1'b1;
          end
          else begin
                slave_has_owner[slaveLoop]='0;//uncommented
                current_owner[slaveLoop]='x;
          end
          if(slave_has_owner[slaveLoop]) begin
            owner[slaveLoop] = current_owner[slaveLoop];
            if(master_request[slaveLoop][masterLoop] &&
               (master_htrans[masterLoop] == 2'b00) &&  // IDLE
               !master_hmastlock[masterLoop] &&current_owner[slaveLoop] == masterLoop) begin        // No lock
              previous_owner[slaveLoop] <= current_owner[slaveLoop]; // Store current as previous before releasing
              slave_has_owner[slaveLoop] <= 1'b0;
            end
            break;
          end
          else begin
                slave_has_owner[slaveLoop] = 'x;
          end
        end
        end
      end
    //end
  end
endgenerate



generate
  for(genvar gs=0;gs<NO_OF_SLAVES;gs++) begin
    for(genvar gm=0;gm<NO_OF_MASTERS;gm++) begin
     always_comb begin
       $info("THE REQ IS %0b for the slave %0d",master_request[gs],gs);
       $info("THE GRANT IS %0d for the slave %0d addr is %0d for master %0d",master_grant[gs][gm],gs,ahbMasterInterface[gm].haddr,gm);
       //$display("THE ADDRESS IS %0d for the master =%0d",ahbMasterInterface[gm].haddr,gm);


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
      /* always @ (master_request[s], slave_hreadyout[s] ) begin */
        logic can_accept;
        logic locked_present;
        master_grant[s] = 'x;
        //  $info("ALWAST");
        for(int i=0;i<NO_OF_MASTERS;i++)
         if(master_request[s][i])
           if(master_hmastlock[i]==1) begin
              locked_present=1;
              break;
           end
        can_accept = !slave_data_phase[s].valid ||  slave_hreadyout[s];




       if(locked_present==1 &&  can_accept==1)
          for (int i = 0; i < NO_OF_MASTERS; i++) begin
            int master_idx;
            master_idx = (rr_pointer[s] + i) % NO_OF_MASTERS;
            if (master_request[s][master_idx] && master_hmastlock[master_idx]==1) begin
              $display($time," 1st if block master_request[%0d][%0d] masterlock=%0d",s,master_idx,master_idx);
                master_grant[s][master_idx] = 1'b1;
                $display($time," 1st block grant %0d",master_grant[s][master_idx]);
                break;
            end
          end
            else if(can_accept == 1 && master_htrans[current_owner[s]] == 2'b 11)begin//added
                //else if(can_accept == 1 && master_htrans[current_owner[s]] == 2'b 11 && slave_has_owner[s]==1)begin

                $display($time ," 2nd else if block can_accept=%0d htrans=%0d slave_has_owner=%d",can_accept,master_htrans[current_owner[s]],slave_has_owner[s]);
               master_grant[s]='0;
              master_grant[s][current_owner[s]] =1;
                slave_data_phase[s].haddr        <= master_haddr[current_owner[s]];
		$strobe("[%0t] 2nd  slave_data_phase.[%0d].haddr = %0d",$time,s,slave_data_phase[s].haddr);
                slave_data_phase[s].hsize        <= master_hsize[current_owner[s]];
                slave_data_phase[s].htrans       <= master_htrans[current_owner[s]];
                slave_data_phase[s].hwrite       <= master_hwrite[current_owner[s]];
                slave_data_phase[s].hburst       <= master_hburst[current_owner[s]];
                slave_data_phase[s].hprot        <= master_hprot[current_owner[s]];
                slave_data_phase[s].hmastlock    <= master_hmastlock[current_owner[s]];
                slave_data_phase[s].target_slave <= s;
                slave_data_phase[s].master_id    <= current_owner[s];
                slave_data_phase[s].valid        <= 1'b1;

              $display($time ," 2nd blk grant %0d alsve=%0d",master_grant[s][current_owner[s]],s);
            end

             else if (can_accept) begin
                $display($time ," 3rd block can accept=%0d slave=%0d",can_accept,s);
                $display("slave_has_owner = %0d slave = %0d ",slave_has_owner[s],s);
                for (int i = 0; i < NO_OF_MASTERS; i++) begin
                int m;
                m = (rr_pointer[s] + i) % NO_OF_MASTERS;

                if (master_request[s][m] ) begin
                  $display("dead case s:%d | m:%d",s,m);
                  $display($time," inside 3rd block master_request[s=%0d][m= %0d] htrans=%0d",s,m,master_htrans[m]);
                  master_grant[s][m] = 1'b1;
                  $display($time," 3rd block grant %0d",master_grant[s][m]);
                  last_request[s] = m;

                slave_data_phase[s].haddr        <= master_haddr[m];
		$strobe("[%0t] 3rd  slave_data_phase.[%0d].haddr = %0d",$time,s,slave_data_phase[s].haddr);
                slave_data_phase[s].hsize        <= master_hsize[m];
                slave_data_phase[s].htrans       <= master_htrans[m];
                slave_data_phase[s].hwrite       <= master_hwrite[m];
                slave_data_phase[s].hburst       <= master_hburst[m];
                slave_data_phase[s].hprot        <= master_hprot[m];
                slave_data_phase[s].hmastlock    <= master_hmastlock[m];
                slave_data_phase[s].target_slave <= s;
                slave_data_phase[s].master_id    <= m;
                slave_data_phase[s].valid        <= 1'b1;
                //slave_hwdata_stable[s] = master_hwdata[current_owner[s]];

              break;

            end
      else
       slave_data_phase[s].haddr <= 'bx;
          end
        end
      end
    end
  endgenerate

  generate
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
	    $display("[%0t] master_pipeline[%0d][master_wr_ptr[%0d]].haddr = %0d", $time,m,m,master_pipeline[m][master_wr_ptr[m]].haddr);
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
  endgenerate

//added block
 generate
   for(genvar s =0;s <NO_OF_SLAVES ;s++) begin
     always_comb begin
       for(int i=0;i<NO_OF_MASTERS;i++) begin
         if(master_grant[s][i]==1) begin
           ahbSlaveInterface[s].hready = master_hready[i]; //added
           //ahbSlaveInterface[s].hready =1'b1;
           break;
         end
         else begin
            ahbSlaveInterface[s].hready =0;
         end
       end
     end
   end
 endgenerate

 generate
  for(genvar m=0;m<NO_OF_MASTERS;m++) begin
   always_comb begin

    for(int s = 0;s < NO_OF_SLAVES;s++)
        if( m == current_owner[s])begin
            ahbMasterInterface[m].hrdata = slave_hrdata[s];
            //add
                                                                                                                                                                            
            //break;
        end
        //else begin
        //      ahbSlaveInterface[m].hready =0;
        //end
   end

  end
endgenerate

/* //try
 generate
  for(genvar m=0;m<NO_OF_MASTERS;m++) begin
   always_comb begin

    for(int s = 0;s < NO_OF_SLAVES;s++)begin
        if(m == owner[s])begin
            ahbMasterInterface[m].hrdata = slave_hrdata[s];
        end
    end
   end

  end
endgenerate

*/

  generate
    for (genvar s = 0; s < NO_OF_SLAVES; s++) begin : slave_data_mgmt
      logic new_data_phase_starting;

      always_comb begin
        //$info("ALWASY");
        if (!hresetn) begin
          //slave_data_phase[s] <= '0;
          //slave_hwdata_stable[s] <= '0;
          new_data_phase_starting <= 1'b0;
        end else begin
          new_data_phase_starting <= |master_grant[s];
          $display("ENTERED THIS BLOCK @%0t",$time());
          if (|master_grant[s]) begin
                 for (int m = 0; m < NO_OF_MASTERS; m++) begin
              if (master_grant[s][m] == 1) begin
                 //slave_hwdata_stable[s] = master_hwdata[current_owner[s]];
                 slave_hwdata_stable[s] = master_hwdata[new_c_owner[s]];
                 $display("[%0t] slave_hwdata_stable[%0d] = %0h",$time,s,slave_hwdata_stable[s]);
               /* slave_data_phase[s].haddr        <= master_haddr[m];
                slave_data_phase[s].hsize        <= master_hsize[m];
                slave_data_phase[s].htrans       <= master_htrans[m];
                slave_data_phase[s].hwrite       <= master_hwrite[m];
                slave_data_phase[s].hburst       <= master_hburst[m];
                slave_data_phase[s].hprot        <= master_hprot[m];
                slave_data_phase[s].hmastlock    <= master_hmastlock[m];
                slave_data_phase[s].target_slave <= s;
                slave_data_phase[s].master_id    <= m;
                slave_data_phase[s].valid        <= 1'b1;
            //    slave_hwdata_stable[s] = master_hwdata[current_owner[s]];*/
                break;
              end
            end
          end
          else if (slave_data_phase[s].valid && slave_hreadyout[s]) begin
           // slave_data_phase[s].valid <= 1'b0;
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
             $display(" 1st hwdata = %0h",ahbSlaveInterface[s].hwdata);
        //if (slave_data_phase[s].valid && slave_hreadyout[s]) begin
          ahbSlaveInterface[s].haddr      = slave_data_phase[s].haddr;
	  $display("[%0t] ahbSlaveInterface[%0d].haddr = %0d",$time,s,ahbSlaveInterface[s].haddr);
          ahbSlaveInterface[s].hsize      = slave_data_phase[s].hsize;
          ahbSlaveInterface[s].htrans     = slave_data_phase[s].htrans;
          ahbSlaveInterface[s].hwrite     = slave_data_phase[s].hwrite;
          ahbSlaveInterface[s].hburst     = slave_data_phase[s].hburst;
          ahbSlaveInterface[s].hprot      = slave_data_phase[s].hprot;
          ahbSlaveInterface[s].hmastlock  = slave_data_phase[s].hmastlock;
          ahbSlaveInterface[s].hselx      = 1'b1;

          ahbSlaveInterface[s].hwdata     = slave_hwdata_stable[s];//c
	  $display(" 2nd hwdata = %0h",ahbSlaveInterface[s].hwdata);
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
      logic pipeline_has_space;
      logic can_accept_new_transfer;
      logic oldest_is_ready;

      always_comb begin
        //$info("ALWAYS");
        //ahbMasterInterface[m].hrdata = '0;
        ahbMasterInterface[m].hresp  = 2'b00;

 //       oldest_is_valid = (master_count[m] > 0) && master_pipeline[m][master_rd_ptr[m]].valid;
      oldest_is_ready = 1'b1; // Default to ready if no active transaction

        for(int s=0;s <NO_OF_SLAVES;s++)
        if(m == current_owner[s])
           begin
            oldest_is_ready = slave_hreadyout[s];
            $display("%0t check slave_hreadyout[%0d] = %0d",$time, s,slave_hreadyout[s]);
            break;
           end
        pipeline_has_space = (master_count[m] < 2);

        can_accept_new_transfer = 1'b0;
        //if(master_htrans[m] != 2'b00)begin //removed
          for (int s = 0; s < NO_OF_SLAVES; s++) begin
            if (master_grant[s][m]) begin
            $display("last grant s=%0d m=%0d g==%0d",s,m,master_grant[s][m]);
                  can_accept_new_transfer = 1'b1;
              break;
            end
          end
         //end//removed


        //removed
        /* if (master_htrans[m] == 2'b00) begin
          ahbMasterInterface[m].hready = 1'b1;
          $display($time, "hreadyy %0d master [%0d]",ahbMasterInterface[m].hready,m);

        end else begin
          ahbMasterInterface[m].hready = can_accept_new_transfer && oldest_is_ready;
$display($time, "else hready %0d master [%0d] can_accept=%0d oldest_is_ready=%0d",ahbMasterInterface[m].hready,m,can_accept_new_transfer,oldest_is_ready);
        end
        */

          ahbMasterInterface[m].hready = can_accept_new_transfer && oldest_is_ready;//added
$display($time, "else hready %0d master [%0d] can_accept=%0d oldest_is_ready=%0d",ahbMasterInterface[m].hready,m,can_accept_new_transfer,oldest_is_ready);
      end
    end
  endgenerate

endinterface                                                                                                                  
