class reg_axi_adapter extends uvm_reg_adapter;
  `uvm_object_utils(reg_axi_adapter)
  
  function new(string name = "reg_axi_adapter");
    super.new(name);
  endfunction
 
  // REG to BUS method
  virtual function uvm_sequence_item reg2bus (const ref uvm_reg_bus_op rw);
    seq_item bus_item = seq_item::type_id::create("bus_item");
    bus_item.addr = rw.addr;
    bus_item.data = rw.data;
    bus_item.rd_or_wr = (rw.kind == UVM_READ) ? 1: 0;
    
    `uvm_info(get_type_name, $sformatf("reg2bus: addr = %0h, data = %0h, rd_or_wr = %0h", bus_item.addr, bus_item.data, bus_item.rd_or_wr), UVM_LOW);
    return bus_item;
  endfunction
  
  // BUS to REG method
  virtual function void bus2reg (uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    seq_item bus_pkt;
    if(!$cast(bus_pkt, bus_item))
      `uvm_fatal(get_type_name(), "Failed to cast bus_item transaction")

    rw.addr = bus_pkt.addr;
    rw.data = bus_pkt.data;
    rw.kind = (bus_pkt.rd_or_wr) ? UVM_READ: UVM_WRITE;
    //rw.status = UVM_IS_OK;
  endfunction
endclass

//====================================================================================================================================================================//
class uvm_reg_tlm_adapter extends uvm_reg_adapter;

  `uvm_object_utils(uvm_reg_tlm_adapter)

  function new(string name = "uvm_reg_tlm_adapter");
    super.new(name);
  endfunction

  // Function: reg2bus
  //
  // Converts a <uvm_reg_bus_op> struct to a <uvm_tlm_gp> item.

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);

     uvm_tlm_gp gp = uvm_tlm_gp::type_id::create("tlm_gp",, this.get_full_name());
     int nbytes = (rw.n_bits-1)/8+1;
     uvm_reg_addr_t addr=rw.addr;

     if (rw.kind == UVM_WRITE)
        gp.set_command(UVM_TLM_WRITE_COMMAND);
     else
        gp.set_command(UVM_TLM_READ_COMMAND);

     gp.set_address(addr);

     gp.m_byte_enable = new [nbytes];

     gp.set_streaming_width (nbytes);

     gp.m_data = new [gp.get_streaming_width()];

     for (int i = 0; i < nbytes; i++) begin
        gp.m_data[i] = rw.data[i*8+:8];
        gp.m_byte_enable[i] = (i > nbytes) ? 1'b0 : rw.byte_en[i];
     end

     return gp;

  endfunction


  // Function: bus2reg
  //
  // Converts a <uvm_tlm_gp> item to a <uvm_reg_bus_op>.
  // into the provided ~rw~ transaction.
  //
  virtual function void bus2reg(uvm_sequence_item bus_item,
                                ref uvm_reg_bus_op rw);

    uvm_tlm_gp gp;
    int nbytes;

    if (bus_item == null)
     `uvm_fatal("REG/NULL_ITEM","bus2reg: bus_item argument is null") 

    if (!$cast(gp,bus_item)) begin
      `uvm_error("WRONG_TYPE","Provided bus_item is not of type uvm_tlm_gp")
      return;
    end

    if (gp.get_command() == UVM_TLM_WRITE_COMMAND)
      rw.kind = UVM_WRITE;
    else
      rw.kind = UVM_READ;

    rw.addr = gp.get_address();

    rw.byte_en = 0;
    foreach (gp.m_byte_enable[i])
      rw.byte_en[i] = gp.m_byte_enable[i];

    rw.data = 0;
    foreach (gp.m_data[i])
      rw.data[i*8+:8] = gp.m_data[i];

    rw.status = (gp.is_response_ok()) ? UVM_IS_OK : UVM_NOT_OK;


  endfunction

endclass
