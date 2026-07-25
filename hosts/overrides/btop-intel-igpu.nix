{ pkgs, ... }:

# Security wrapper so btop can read Intel iGPU performance counters. Grants the
# perfmon + dac_read_search capabilities that reading the iGPU perf interface
# requires. Import only on hosts with an Intel iGPU exposing perf counters
# (native desktops); WSL hosts have no iGPU perf access and skip this.
{
  security.wrappers.btop = {
    owner = "root";
    group = "root";
    capabilities = "cap_perfmon+ep cap_dac_read_search+ep";
    source = "${pkgs.btop}/bin/btop";
  };
}
