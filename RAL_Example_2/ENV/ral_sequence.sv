
class base_seq extends uvm_sequence#(seq_item);
  seq_item req;
  `uvm_object_utils(base_seq)
  
  function new (string name = "base_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(), "Base seq: Inside Body", UVM_LOW);
    `uvm_do(req);
  endtask
endclass
  
class reg_seq extends uvm_sequence#(seq_item);
  seq_item req;
  RegModel_SFR reg_model;
  uvm_status_e   status;
  uvm_reg_data_t read_data;
  bit [31:0] dv_data,mv_data,read_out;

  `uvm_object_utils(reg_seq)
  
  function new (string name = "reg_seq");
    super.new(name);
  endfunction
  
  task body();
   `uvm_info(get_type_name(), "Reg seq: Inside Body", UVM_LOW);
    if(!uvm_config_db#(RegModel_SFR) :: get(uvm_root::get(), "", "reg_model", reg_model))
      `uvm_fatal(get_type_name(), "reg_model is not set at top level");
   
    reg_model.mod_reg.control_reg.write(status, 32'h1234_1234,UVM_FRONTDOOR);
    reg_model.mod_reg.control_reg.read(status, read_data,UVM_FRONTDOOR);
    `uvm_info("ral_seq",$sformatf("using front_door : read_data = %0h \t status = %s",read_data,status),UVM_LOW);

    reg_model.mod_reg.intr_sts_reg.write(status, 32'h1234_1234,UVM_FRONTDOOR);
    reg_model.mod_reg.intr_sts_reg.read(status, read_data,UVM_FRONTDOOR);
    `uvm_info("ral_seq",$sformatf("using front_door : read_data = %0h \t status = %s",read_data,status),UVM_LOW); 

    /*reg_model.mod_reg.intr_msk_reg.write(status, 32'h5555_5555,UVM_BACKDOOR);
    reg_model.mod_reg.intr_msk_reg.read(status, read_data,UVM_BACKDOOR);
    `uvm_info("ral_seq",$sformatf("using back_door : read_data = %0h \t status = %s",read_data,status),UVM_LOW);*/
    
    reg_model.mod_reg.debug_reg.write(status, 32'hAAAA_AAAA,UVM_FRONTDOOR);
    reg_model.mod_reg.debug_reg.read(status, read_data,UVM_BACKDOOR);   
    `uvm_info("ral_seq",$sformatf("using back_door read_data = %0h \t status = %s",read_data,status),UVM_LOW);


//----------------------------------------------------------------------------------------------------------------------------------------------------------------------//
    $display(" ******************** backdoor write i.e poke ******************** ");
    reg_model.mod_reg.intr_msk_reg.poke(status, 32'd10);	        // writing 10 to the h/w reg
    dv_data = reg_model.mod_reg.intr_msk_reg.get();			// get the desired variable, backdoor
    mv_data = reg_model.mod_reg.intr_msk_reg.get_mirrored_value();	// get the mirrored variable, backdoor
    `uvm_info(get_type_name(), $sformatf(" After backdoor poke(poke - backdoor write) method, Desired value is %0d, Mirrored value is %0d\t status = %s",dv_data, mv_data, status), UVM_NONE)
    
    // ------ backdoor read ------
    $display(" ******************** backdoor read i.e peek ******************** ");
    reg_model.mod_reg.intr_msk_reg.peek(status, read_out);		// peek method -> read the value from the dut reg
    // read method is a task hence does't return anything
    dv_data = reg_model.mod_reg.intr_msk_reg.get();			// get the desired variable, backdoor
    mv_data = reg_model.mod_reg.intr_msk_reg.get_mirrored_value();	// get the mirrored variable, backdoor
    `uvm_info(get_type_name(), $sformatf(" After backdoor peek (peek - backdoor read) method, Desired value is %0d, Mirrored value is %0d, read_out is %0d\t status = %s",dv_data, mv_data, read_out, status), UVM_NONE)	

  endtask
  
  
endclass
