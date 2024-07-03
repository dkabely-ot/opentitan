// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class i2c_item extends uvm_sequence_item;

  // transaction data part
  bit [7:0]                data_q[$];
  bit [9:0]                addr;      // enough to support both 7 & 10-bit target address
  int                      tran_id;
  int                      num_data;  // valid data
  bus_op_e                 bus_op;
  bit                      addr_ack;
  bit                      data_ack_q[$];
  // transaction control part
  bit                      nack;
  bit                      ack;
  bit                      rstart;

  // queue dropped data due to fmt_overflow
  bit [7:0]                fmt_ovf_data_q[$];

  // random flags
  rand bit [7:0]           fbyte;
  rand bit                 nakok, rcont, read, stop, start;
  //
  // DUT-Target
  i2c_acq_byte_id_e        signal; // ACQDATA.SIGNAL

  // The following fields are used when using the seq_item to create transactions byte-by-byte in
  // the i2c_agent. Used when interacting with the i2c_driver and 'drv_type' to create stimulus.
  // TODO: Remove / Refactor to use bus_op + data_q instead
  logic [7:0]              wdata;
  logic [7:0]              rdata;
  // This field is used by the i2c_driver to control the driving behaviour for a single sequence
  // item. This is not a great abstraction, hopefully one day it can be removed as part of a larger
  // refactor.
  // Also see #14825
  drv_type_e               drv_type;

  // Use for debug print
  string                   pname = "";

  // Use to indicate the number of cycles Agent consumes for Write data or while in idle state
  int                      wait_cycles = 8;

  constraint fbyte_c     { fbyte      inside {[0 : 127] }; }
  constraint rcont_c     {
     solve read, stop before rcont;
     // for read request, rcont and stop must be complementary set
     if (read) {
       rcont == ~stop;
     } else {
       rcont dist { 1 :/ 1, 0 :/ 2 };
     }
  }

  constraint wait_cycles_c {
    wait_cycles == 8;
  }

  // In the I2C block-level DV environment, we only use the .compare() method for DUT-Controller
  // transactions. DUT-Target transactions use checking routines which explicitly only compare a
  // different subset of the fields. Hence, the NOCOMPARE attributes only apply to DUT-Controller
  // transaction comparison.
  //
  `uvm_object_utils_begin(i2c_item)
    `uvm_field_int(tran_id,                    UVM_DEFAULT)
    `uvm_field_enum(bus_op_e, bus_op,          UVM_DEFAULT)
    `uvm_field_int(addr,                       UVM_DEFAULT)
    `uvm_field_int(num_data,                   UVM_DEFAULT)
    `uvm_field_int(start,                      UVM_DEFAULT)
    `uvm_field_int(stop,                       UVM_DEFAULT)
    `uvm_field_int(wdata,                      UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_queue_int(data_q,               UVM_DEFAULT)
    `uvm_field_queue_int(fmt_ovf_data_q,       UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int(rdata,                      UVM_DEFAULT | UVM_NOPRINT | UVM_NOCOMPARE)
    `uvm_field_enum(i2c_acq_byte_id_e, signal, UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int(rstart,                     UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int(fbyte,                      UVM_DEFAULT | UVM_NOPRINT | UVM_NOCOMPARE)
    `uvm_field_int(ack,                        UVM_DEFAULT | UVM_NOPRINT | UVM_NOCOMPARE)
    `uvm_field_int(nack,                       UVM_DEFAULT | UVM_NOPRINT | UVM_NOCOMPARE)
    `uvm_field_int(read,                       UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int(rcont,                      UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int(nakok,                      UVM_DEFAULT | UVM_NOPRINT | UVM_NOCOMPARE)
    `uvm_field_enum(drv_type_e,  drv_type,     UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int(wait_cycles,                UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int(addr_ack,                   UVM_DEFAULT | UVM_NOCOMPARE | UVM_NOPRINT)
    `uvm_field_queue_int(data_ack_q,           UVM_DEFAULT | UVM_NOCOMPARE | UVM_NOPRINT)
  `uvm_object_utils_end

  `uvm_object_new

  function void clear_data();
    num_data = 0;
    addr     = 0;
    drv_type = None;
    data_q.delete();
    fmt_ovf_data_q.delete();
    wdata = 0;
    rdata = 0;
    addr_ack = 0;
    data_ack_q.delete();
  endfunction : clear_data

  function void clear_flag();
    start   = 1'b0;
    stop    = 1'b0;
    read    = 1'b0;
    rcont   = 1'b0;
    nakok   = 1'b0;
    rstart  = 1'b0;
  endfunction : clear_flag

  function void clear_all();
    clear_data();
    clear_flag();
  endfunction : clear_all

  virtual function string convert2string();
    string str = "";
    str = {str, $sformatf("%s:tran_id  = %0d\n", pname, tran_id)};
    str = {str, $sformatf("%s:bus_op   = %s\n",    pname, bus_op.name)};
    str = {str, $sformatf("%s:addr     = 0x%2x\n", pname, addr)};
    str = {str, $sformatf("%s:num_data = %0d\n", pname, num_data)};
    str = {str, $sformatf("%s:start    = %1b\n", pname, start)};
    str = {str, $sformatf("%s:stop     = %1b\n", pname, stop)};
    str = {str, $sformatf("%s:read     = %1b\n", pname, read)};
    str = {str, $sformatf("%s:rstart   = %1b\n", pname, rstart)};
    foreach (data_q[i]) begin
      str = {str, $sformatf("%s:data_q[%0d]=0x%2x\n", pname, i, data_q[i])};
    end
    return str;
  endfunction
endclass : i2c_item
