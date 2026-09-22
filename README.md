# Space BMC Core RTL

This repository starts the Space BMC Core implementation with a standalone,
self-checking heartbeat monitor written in Verilog-2001.

## Current scope

- `rtl/heartbeat_monitor.v`: parameterized heartbeat timeout detector.
- `tb/tb_heartbeat_monitor.v`: automated boundary and recovery checks.
- `scripts/run_heartbeat_sim.ps1`: Questa compile-and-run entry point.

Recovery sequencing and the Recovery FSM are intentionally not part of this
milestone.

## Timeout definition

`TIMEOUT_CYCLES` is the number of consecutive rising clock edges without a
sampled heartbeat before `timeout` asserts. The default is 25,000,000 cycles,
equivalent to 500 ms when driven by the DE10-Standard 50 MHz clock.

`timeout` is latched after assertion. It is cleared and its interval restarted
by any of the following:

- active-low asynchronous reset (`rst_n = 0`);
- a heartbeat sampled high on a rising clock edge;
- `clear_timeout` sampled high on a rising clock edge.

The testbench overrides `TIMEOUT_CYCLES` with a small value to keep simulation
fast while checking the same cycle-accurate behavior.

## Run the simulation

Requirements:

- PowerShell 7 or Windows PowerShell 5.1;
- Questa Altera FPGA Starter Edition (installed with Quartus Prime Lite 25.1).

From the repository root:

```powershell
pwsh -File .\scripts\run_heartbeat_sim.ps1
```

A successful run ends with `TEST PASSED` and returns exit code 0.

## Inspect the waveform

After the automated regression passes, open the same test in the Questa GUI:

```powershell
pwsh -File .\scripts\open_heartbeat_wave.ps1
```

The waveform layout includes the testbench inputs, the DUT's internal elapsed
cycle counter, the timeout output, and the testbench check/error counters.
Waveform inspection supplements the self-checking testbench; it does not
replace automated PASS/FAIL checking.
