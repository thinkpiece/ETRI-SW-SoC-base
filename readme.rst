ETRI SW-SoC base template
=========================

Project Directory Tree
----------------------

.. code-block:: console

  readme.rst               % readme
  LICENSE
  cmod/                    % your c reference model
  vmod/                    % verilog model
  ├── cnnip_v1_0.v         % top module
  ├── cnnip_v1_0_S00_AXI.v % AXI4-lite slave interface
  ├── addr_gen.sv
  ├── blk_mem_wrapper.sv
  ├── cnnip_ctrlr.sv
  ├── cnnip_mem_if.sv
  └── register_set.sv
  sdk_srcs/                % SDK source file

Assumptions
-----------

Note that this is the base template for the project so there are many
assumptions. Please carefully modify the code for your own project.

1. ``blk_mem_wrapper`` refers to ``blk_mem_gen_0`` that is a true dual-port
   memory with 8-bit write enable.
2. The top module ``cnnip_v1_0`` recevies 16-bit address from the top system.
   The occupied address space is set by the ``Package IP`` wizard.
