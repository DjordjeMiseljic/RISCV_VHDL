class control_if_agent extends uvm_agent;

    // components
    control_if_driver drv;
    control_if_sequencer seqr;
    control_if_monitor mon;
   virtual interface v_lane_if vif;
   // configuration
   vector_lane_config cfg;
   int 	   value;   
   `uvm_component_utils_begin (control_if_agent)
       `uvm_field_object(cfg, UVM_DEFAULT)
   `uvm_component_utils_end

   function new(string name = "control_if_agent", uvm_component parent = null);
       super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       /************Geting from configuration database*******************/
       if (!uvm_config_db#(virtual v_lane_if)::get(this, "", "v_lane_if", vif))
         `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
       
       if(!uvm_config_db#(vector_lane_config)::get(this, "", "vector_lane_config", cfg))
         `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
       /*****************************************************************/
       
       /************Setting to configuration database********************/
       uvm_config_db#(virtual v_lane_if)::set(this, "*", "v_lane_if", vif);
       /*****************************************************************/
       
       mon = control_if_monitor::type_id::create("mon", this);
       if(cfg.is_active == UVM_ACTIVE) begin
           drv = control_if_driver::type_id::create("drv", this);
           seqr = control_if_sequencer::type_id::create("seqr", this);
       end
   endfunction : build_phase

   function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       if(cfg.is_active == UVM_ACTIVE) begin
           drv.seq_item_port.connect(seqr.seq_item_export);
       end
   endfunction : connect_phase

endclass : control_if_agent