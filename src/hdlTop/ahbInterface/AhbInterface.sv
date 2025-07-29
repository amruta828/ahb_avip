`ifndef AHBINTERFACE_INCLUDED_
`define AHBINTERFACE_INCLUDED_

import AhbGlobalPackage::*;

interface AhbInterface(input hclk, input hresetn);
  
  logic  [ADDR_WIDTH-1:0] haddr;
  logic hselx;
  
  wire [2:0] hburst;

  wire hmastlock;

  wire [HPROT_WIDTH-1:0] hprot;
 
  wire [2:0] hsize;

  wire hnonsec;

  wire hexcl;

  wire [HMASTER_WIDTH-1:0] hmaster;

  wire [1:0] htrans;


  logic [DATA_WIDTH-1:0] hwdata;

  wire [(DATA_WIDTH/8)-1:0] hwstrb;

  logic hwrite;

  logic [DATA_WIDTH-1:0] hrdata;

  logic hreadyout;

  wire hresp;

  wire hexokay;

  logic hready;

 modport ahbSlaveinterconnectModport(input hrdata,hreadyout, output hready,hselx, output  haddr,hburst,hprot,hmastlock,hsize,hnonsec,hexcl,hmaster,htrans,hwdata,hwstrb,hwrite,hresp);
 modport ahbMasterinterconnectModport(input hreadyout, output hready,hselx, input  haddr,hburst,hprot,hmastlock,hsize,hnonsec,hexcl,hmaster,htrans,hwdata,hwstrb,hwrite,hresp,hrdata);  

endinterface : AhbInterface

`endif

