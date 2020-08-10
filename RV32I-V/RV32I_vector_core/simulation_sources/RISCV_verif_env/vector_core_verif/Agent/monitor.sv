class vector_core_monitor extends uvm_monitor;
    
    // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;
   bit is_ok_to_end = 0;
    
    uvm_analysis_port #(vector_core_seq_item) instr_item_collected_port;
    uvm_analysis_port #(store_data_seq_item) store_data_collected_port;
    uvm_analysis_port #(load_data_seq_item) load_data_collected_port;
    
   typedef enum {wait_for_ready, send_seq_item, wait_store_to_finish} collect_instr_stages;
    collect_instr_stages v_lane_mon_stages = wait_for_ready;

   typedef enum {wait_for_we, send_store_seq_item} collect_store_data_stages;
    collect_store_data_stages v_core_store_stages = wait_for_we;

    typedef enum {wait_for_re, send_load_seq_item} collect_load_data_stages;
    collect_load_data_stages v_core_load_stages = wait_for_re;
    
    
    `uvm_component_utils_begin(vector_core_monitor)
	`uvm_field_int(checks_enable, UVM_DEFAULT)
	`uvm_field_int(coverage_enable, UVM_DEFAULT)
    `uvm_component_utils_end

    // The virtual interface used to drive and view HDL signals.
   virtual 	interface v_core_if vif;

   // current transaction
   vector_core_seq_item curr_instr_item;
   store_data_seq_item curr_store_item;
   load_data_seq_item curr_load_item; 
   
   
   // coverage can go here
   // ...

   function new(string name = "vector_core_monitor", uvm_component parent = null);
       super.new(name,parent);      
       instr_item_collected_port = new("instr_item_collected_port", this);
       store_data_collected_port = new("store_data_collected_port", this);
       load_data_collected_port = new("load_data_collected_port", this);
   endfunction

   function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       if (!uvm_config_db#(virtual v_core_if)::get(this, "", "v_core_if", vif))
         `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
   endfunction : connect_phase



   task main_phase(uvm_phase phase);
       forever begin
	   @(posedge(vif.clk));
	   #2ns;		       			   
           curr_instr_item = vector_core_seq_item::type_id::create("curr_instr_item", this);
	   curr_store_item = store_data_seq_item::type_id::create("curr_store_item", this);
	   curr_load_item = load_data_seq_item::type_id::create("curr_load_item", this);
	   
	   if (vif.reset)begin	       
	       fork
		   //Instruction fork
		   begin
		       if (!vif.vector_stall_s) begin			   
			   curr_instr_item.vector_instruction_i = vif.vector_instruction_i;
			   curr_instr_item.rs1_i = vif.rs1_i;
			   curr_instr_item.rs2_i = vif.rs2_i;		       
			   instr_item_collected_port.write(curr_instr_item);			   
		       end
		   end
		   //Store fork
		   begin
		       if(vif.mem_we_s) begin			 							   
			   curr_store_item.data_to_mem_s = vif.data_to_mem_s;
			   store_data_collected_port.write(curr_store_item);			   			   
		       end
		   end
		   // Load fork
		   begin
			 case (v_core_load_stages)
			     wait_for_re: begin				 
				 if (vif.mem_re_s)
				   v_core_load_stages = send_load_seq_item;		    				 
			     end
			     send_load_seq_item: begin
				 curr_load_item.data_from_mem_s = vif.data_from_mem_s;
				 load_data_collected_port.write(curr_load_item);
				 if (!vif.mem_re_s) begin
				   v_core_load_stages = wait_for_re;
				 end
			     end
			 endcase
		   end		   
	       join_none
	   end // if (vif.reset)	   
       end // forever begin       
   endtask : main_phase

endclass : vector_core_monitor
