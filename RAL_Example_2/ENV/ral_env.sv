
class env extends uvm_env;
  `uvm_component_utils(env)
  agent agt;
  reg_axi_adapter adapter;
  RegModel_SFR reg_model;
  
  function new(string name = "env", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
   super.build_phase(phase);
   agt = agent::type_id::create("agt", this);
   adapter = reg_axi_adapter::type_id::create("adapter");
   reg_model = RegModel_SFR::type_id::create("reg_model");

   `uvm_info("ral_env","-------------------------------------------- build method for reg model --------------------------------------",UVM_LOW);
   reg_model.build(); // to build uvm_reg_block (reg_model)
   `uvm_info("ral_env","-------------------------------------------- Reset method for reg model --------------------------------------",UVM_LOW);
   reg_model.reset(); // uvm_reg_block = Reset the mirror for this block.
   `uvm_info("ral_env","-------------------------------------------- Lock method for reg model --------------------------------------",UVM_LOW);
   reg_model.lock_model(); // Lock a model and build the address map.
   `uvm_info("ral_env","-------------------------------------------- Print method for reg model --------------------------------------",UVM_LOW);
   reg_model.print(); //
   
   uvm_config_db#(RegModel_SFR)::set(uvm_root::get(), "*", "reg_model", reg_model);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    reg_model.default_map.set_sequencer(.sequencer(agt.seqr), .adapter(adapter));
    reg_model.default_map.set_base_addr('h0);        
  endfunction
   
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("env_test","using print method for topology",UVM_LOW);
    print();
    `uvm_info("env_test","using print_topology method for topology",UVM_LOW);
    uvm_top.print_topology();
  endfunction
   
endclass
