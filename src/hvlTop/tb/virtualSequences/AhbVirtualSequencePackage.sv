`ifndef AHBVIRTUALSEQUENCEPACKAGE_INCLUDED_
`define AHBVIRTUALSEQUENCEPACKAGE_INCLUDED_

package AhbVirtualSequencePackage;

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import AhbGlobalPackage::*;
  import AhbMasterPackage::*;
  import AhbSlavePackage::*;
  import AhbMasterSequencePackage::*;
  import AhbSlaveSequencePackage::*;
  import AhbEnvironmentPackage::*;

  `include "AhbVirtualBaseSequence.sv"
  `include "AhbVirtualWriteSequence.sv"
 `include "AhbVirtualIdleSequence.sv"
  `include "AhbVirtualReadSequence.sv"
  `include "AhbVirtualSingleWriteSequence.sv"
  `include "AhbVirtualSingleReadSequence.sv"
  `include "AhbVirtualWriteWithBusySequence.sv"
  `include "AhbVirtualReadWithBusySequence.sv"
  `include "AhbVirtualSingleWriteWithWaitStateSequence.sv"
  `include "AhbVirtualSingleReadWithWaitStateSequence.sv"
  `include "AhbVirtualWriteWithWaitStateSequence.sv"
  `include "AhbVirtualReadWithWaitStateSequence.sv"
  `include "AhbVirtualWriteFollowedByReadSequence.sv"
 //`include "AhbVirtualIdleSequence.sv"
  `include "AhbVirtualSingleWriteFollowedByReadSequence.sv"
  `include "AhbVirtualLength4WriteFollowedByReadSequence.sv"
  `include "AhbVirtualLength8WriteFollowedByReadSequence.sv"
  `include "AhbVirtualLength16WriteFollowedByReadSequence.sv"
 
  `include "AhbVirtualWrap4WriteFollowedByReadSequence.sv"
  `include "AhbVirtualWrap8WriteFollowedByReadSequence.sv"  
  `include "AhbVirtualWrap16WriteFollowedByReadSequence.sv"
endpackage : AhbVirtualSequencePackage

`endif
