import AhbGlobalPackage::*;

interface AhbInterconnect(
  input logic hclk,
  input logic hresetn,
  AhbInterface.ahbMasterinterconnectModport ahbMasterInterface[NO_OF_MASTERS],
   AhbInterface.ahbSlaveinterconnectModport ahbSlaveInterface[NO_OF_SLAVES]
);
  

  logic [$clog2(NO_OF_MASTERS)-1:0] rr_pointer [NO_OF_SLAVES];
  // State variables
  int lastGrantPos[NO_OF_SLAVES];
  int unsigned slaveThreshold[NO_OF_SLAVES];
  int unsigned startingPoint;
  int check_master;  
  // Loop variables
  int i, j, m, n;
  int swasthik;
  logic[3:0] d;
  logic grantThisMaster;
  logic [$clog2(NO_OF_MASTERS)-1:0]tempOwner;
  logic[$clog2(NO_OF_MASTERS)-1:0]owner;
  logic arrayFound[NO_OF_MASTERS];
  // Round-robin arbitration signals
  logic [NO_OF_MASTERS-1:0] master_request[NO_OF_SLAVES];
  logic [NO_OF_MASTERS-1:0] master_grant [NO_OF_SLAVES];
  logic current_owner_locked;
  int ownerTemp;
   //int master_to_check; 
  // Current owner tracking
  logic [$clog2(NO_OF_MASTERS)-1:0] current_owner [NO_OF_SLAVES];
  logic slave_has_owner [NO_OF_SLAVES];
      
  // Address decode signals
  logic [NO_OF_SLAVES-1:0] slave_match [NO_OF_MASTERS];
  


 initial begin
 startingPoint =0; 
  for(int k=0;k<NO_OF_SLAVES;k++) begin
    slaveThreshold[k] = startingPoint + (((2**31)/NO_OF_SLAVES)*2)-1;
    $display("THE STARTING POINT IS %0h",slaveThreshold[k]);
          startingPoint = slaveThreshold[k]+1;
  end
 $display("***************\N\N THE THRESHOLD LIST IS %p\n\n*********************",slaveThreshold);
end 


generate 
  for(genvar slaveLoop =0 ; slaveLoop < NO_OF_SLAVES ; slaveLoop++) begin 
    for(genvar masterLoop =0 ; masterLoop < NO_OF_MASTERS ; masterLoop++) begin 
      always_comb begin
          master_request[slaveLoop][masterLoop] = slaveLoop ==0 ? (ahbMasterInterface[masterLoop].haddr < slaveThreshold[slaveLoop]&& ahbMasterInterface[masterLoop].haddr>=0) : ((ahbMasterInterface[masterLoop].haddr >= slaveThreshold[slaveLoop-1]) && (ahbMasterInterface[masterLoop].haddr < slaveThreshold[slaveLoop] ) );
          $info("ENTERED THE  COMBI FOR REQUEST"); 
     end
   end 
  end
endgenerate 

//current owner of the bus
generate 
  for(genvar slaveLoop =0; slaveLoop < NO_OF_SLAVES ;slaveLoop++) begin
    for(genvar masterLoop = 0; masterLoop < NO_OF_MASTERS ; masterLoop++) begin 
      always_ff@(posedge hclk or hresetn) begin 
        if(!hresetn) begin 
          current_owner[slaveLoop] = '0; 
          slave_has_owner[slaveLoop] = 0;
        end 
      
        else begin 
           if(master_grant[slaveLoop][masterLoop] == 1) begin
             current_owner[slaveLoop] = masterLoop;
             slave_has_owner[slaveLoop] = 1;
           end 
          if(slave_has_owner[slaveLoop]) begin
            owner = current_owner[slaveLoop];
            if(master_request[slaveLoop][masterLoop]&& 
               (ahbMasterInterface[masterLoop].htrans == 2'b00) &&  // IDLE
               !ahbMasterInterface[masterLoop].hmastlock && current_owner[slaveLoop]==masterLoop) begin      // No lock
              slave_has_owner[slaveLoop] <= 1'b0;
            end
          end 
        
      end 
    end 
  end
 end  
endgenerate

/*
generate 

 for (genvar i =0 ; i<NO_OF_MASTERS ;i++) begin 
   always_comb begin 
    if(!hresetn)
     ahbMasterInterface[i].hready=0;
  end 

 end
endgenerate 
*/


generate 

  for(genvar slaveLoop = 0 ; slaveLoop < NO_OF_SLAVES ;slaveLoop++) begin 
//     logic [$clog2(NO_OF_MASTERS)-1:0] rr_pointer [NO_OF_SLAVES];
   logic [$clog2(NO_OF_MASTERS)-1:0] granted_master_id;
    logic grant_found;
    int next_rr_pointer;
    logic current_owner_locked;
    int master_to_check;    
    always_ff @(posedge hclk or negedge hresetn) begin
        if(!hresetn) begin
           
          rr_pointer[slaveLoop] <= NO_OF_MASTERS - 1; // Start with last master, so we begin from master 0
        end else begin
          rr_pointer[slaveLoop] <= next_rr_pointer;
        end
    end
  
    always_comb begin //if my previous master goes idle  transfer ownership to other requested slave
         master_grant[slaveLoop] = '0;
        next_rr_pointer = rr_pointer[slaveLoop];
        granted_master_id = 0;
        grant_found = 1'b0;


           if(|master_request[slaveLoop]) begin // Only arbitrate if someone is requesting
            
            for(int search_offset = 1; search_offset <= NO_OF_MASTERS; search_offset++) begin //round robin logic 
              master_to_check = (rr_pointer[slaveLoop] + search_offset) % NO_OF_MASTERS;
              
              if(!grant_found && master_request[slaveLoop][master_to_check]) begin
                master_grant[slaveLoop][master_to_check] = 1'b1;
                granted_master_id = master_to_check;
                grant_found = 1'b1;
                $info("ENTERED THE RR BLOCK ");     
                break;
              end
            end
            
            if(grant_found) begin
              next_rr_pointer = granted_master_id;
               $display("THE NEXT POINTER FOR THE SLAVE %0d is %0d @%t",slaveLoop,next_rr_pointer,$time);
            end
          end 
       end
      end  
endgenerate 


generate 
 
  for(genvar gs = 0 ; gs < NO_OF_SLAVES;gs++) begin 
    logic[ADDR_WIDTH:0]tempAddr[NO_OF_MASTERS];
    logic[NO_OF_MASTERS-1:0]master_active;
    logic [DATA_WIDTH-1:0] masterData[NO_OF_MASTERS];
    logic masterWrite[NO_OF_MASTERS];
   

    for(genvar i=0;i<NO_OF_MASTERS; i++) begin 
      always_comb begin 
      tempAddr[i] = ahbMasterInterface[i].haddr;
      master_active[i] = master_request[gs][i] && master_grant[gs][i];
      masterData[i] = ahbMasterInterface[i].hwdata;
      masterWrite[i] = ahbMasterInterface[i].hwrite;
      $info("LAST BLOCK 1");
    end

    end   

    always_comb begin 
      for(int i=0;i<NO_OF_MASTERS;i++) 
        if(master_active[i] ==1 && master_grant[gs][i] == 1) 
         begin 
           ahbSlaveInterface[gs].haddr = tempAddr[i];
           ahbSlaveInterface[gs].hselx = 1;
           ahbSlaveInterface[gs].hwdata =  masterData[i];
           ahbSlaveInterface[gs].hwrite =  masterWrite[i];
           $info("LAST BLOCK 2"); 
           break;
         end  
    end 

  end

endgenerate 

generate 

  for(genvar gm =0 ; gm <NO_OF_MASTERS;gm++) begin 
    logic readyOut[NO_OF_SLAVES];
    logic slaveTransfer[NO_OF_SLAVES];
    for(genvar gs =0 ; gs<NO_OF_SLAVES;gs++) begin
     always_comb begin  
     slaveTransfer[gs] = master_request[gs][gm] && master_grant[gs][gm];
     readyOut[gs] = ahbSlaveInterface[gs].hreadyout;
     end 
    end 

    always_comb begin 
      for(int i=0;i<NO_OF_SLAVES;i++) begin 
        if(slaveTransfer[i] ==1 && master_grant[i][gm] ==1 &&hresetn != 0) begin 
         ahbMasterInterface[gm].hready= readyOut[i];
         break;
        end
        else if(hresetn ==0)
         ahbMasterInterface[gm].hready= 1;
       else 
         ahbMasterInterface[gm].hready ='b x;


      end 
 
    end

   end 
endgenerate 



endinterface 
