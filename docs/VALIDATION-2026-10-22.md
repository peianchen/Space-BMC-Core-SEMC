# Heartbeat regression: 22 October 2026

[README](../README.md) · [Engineering notes](ENGINEERING.md)

The unchanged `rtl/heartbeat_monitor.v` and `tb/tb_heartbeat_monitor.v` were run with Questa Altera Starter FPGA Edition 2025.2 on Windows, using the repository's `scripts/run_heartbeat_sim.ps1` from an ASCII-only working path.

```text
Verilog compilation: Errors: 0, Warnings: 0
TEST PASSED: 15 checks completed with no errors.
Simulation: Errors: 0, Warnings: 0
Process exit code: 0
```

Checks cover reset state, the pre-timeout boundary, periodic heartbeats, assertion on the Nth missing cycle, latching, heartbeat recovery, explicit clearing, interval restart and asynchronous reset of an active timeout.

The original Unicode checkout path failed in Questa's library/database handling before the successful ASCII-path run. When reproducing on Windows, use a short ASCII path or a toolchain known to support the checkout path.

This result is functional simulation of the checked-in testbench. No RTL changes, FPGA programming, hardware measurement, timing-closure claim or Recovery FSM verification are included.
