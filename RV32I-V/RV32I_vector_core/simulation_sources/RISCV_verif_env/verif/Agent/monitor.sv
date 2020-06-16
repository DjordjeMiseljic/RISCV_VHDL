class control_if_monitor extends uvm_monitor;
    
    // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;

    uvm_analysis_port #(control_if_seq_item) instr_item_collected_port;
    uvm_analysis_port #(store_data_seq_item) store_data_collected_port;
    
   typedef enum {wait_for_ready, send_seq_item} collect_instr_stages;
    collect_instr_stages v_lane_mon_stages = wait_for_ready;

   typedef enum {wait_for_re, send_store_seq_item} collect_store_data_stages;
    collect_store_data_stages v_lane_store_stages = wait_for_re;

    
    `uvm_component_utils_begin(control_if_monitor)
	`uvm_field_int(checks_enable, UVM_DEFAULT)
	`uvm_field_int(coverage_enable, UVM_DEFAULT)
    `uvm_component_utils_end

    // The virtual interface used to drive and view HDL signals.
   virtual 	interface v_lane_if vif;

   // current transaction
   control_if_seq_item curr_instr_item;
   store_data_seq_item curr_store_item;      

   
   // coverage can go here
   // ...

   function new(string name = "control_if_monitor", uvm_component parent = null);
       super.new(name,parent);      
       instr_item_collected_port = new("instr_item_collected_port", this);
       store_data_collected_port = new("store_data_collected_port", this);
   endfunction

   function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       if (!uvm_config_db#(virtual v_lane_if)::get(this, "", "v_lane_if", vif))
         `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
   endfunction : connect_phase

   task main_phase(uvm_phase phase);
       forever begin
	   @(posedge(vif.clk));
	   #2ns;		       			   
           curr_instr_item = control_if_seq_item::type_id::create("curr_instr_item", this);
	   curr_store_item = store_data_seq_item::type_id::create("curr_store_item", this);
	   if (vif.reset)begin
	       /*wait for ready, and after one clock cycle collect instruction, vmul, vector length and 
		send it to scoreboard*/
	       case (v_lane_mon_stages)
		   wait_for_ready:begin
		       if(vif.ready_o)
			 v_lane_mon_stages = send_seq_item;			
		   end
		   send_seq_item: begin
		       curr_instr_item.vector_instruction_i = vif.vector_instruction_i;
		       curr_instr_item.vmul_i = vif.vmul_i;
		       curr_instr_item.vector_length_i = vif.vector_length_i;
		       curr_instr_item.alu_op_i = vif.alu_op_i;
		       instr_item_collected_port.write(curr_instr_item);
		       v_lane_mon_stages = wait_for_ready;			
		   end
	       endcase // case (v_lane_mon_stages)

	       /*If read enable is set, wait for one clock cycle and then collect 
		item on data_to_mem poert and send it to scoreboard*/
	       case (v_lane_store_stages)
		   wait_for_re:begin
		       if(vif.store_fifo_re_i) 
			 v_lane_store_stages = send_store_seq_item;		       
		   end
		   send_store_seq_item: begin
		       if(vif.store_fifo_re_i) begin
			   curr_store_item.data_to_mem_o = vif.data_to_mem_o;			  
			   store_data_collected_port.write(curr_store_item);
		       end
		       else begin
			   v_lane_store_stages = wait_for_re;
		       end
		   end   
	       endcase // case v_lane_store_stages		
	   end
	   
       end
   endtask : main_phase

endclass : control_if_monitor
