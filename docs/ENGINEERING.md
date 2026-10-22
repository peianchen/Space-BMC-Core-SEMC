# Space BMC Core: Engineering notes

[README](../README.md) · [中文](ENGINEERING.zh-TW.md) · [English](ENGINEERING.md)

A parameterized Verilog heartbeat monitor with a self-checking testbench for timeout boundaries, latching, clearing and interval restart.

## Purpose

A monitor needs an explicit contract: how many missing heartbeats constitute a timeout, whether that output stays asserted and when counting restarts. This project isolates that module so cycle boundaries can be checked repeatedly in simulation.

## Architecture and workflow

```text
CLOCK + HEARTBEAT -> ELAPSED COUNTER -> TIMEOUT LATCH -> CLEAR + RESTART
```

### Sample the inputs

heartbeat and clear_timeout are sampled on rising clk edges; rst_n is asynchronous and active low. Cross-clock synchronization belongs in the integration layer.

### Count elapsed edges

TIMEOUT_CYCLES counts consecutive rising edges without a sampled heartbeat. The default 25,000,000 corresponds to 500 ms under a 50 MHz clock assumption.

### Latch timeout

The output asserts at the threshold and remains high. Waiting alone does not clear it.

### Clear and restart

Reset, a heartbeat or clear_timeout clears the output and resets the counter. The testbench uses a smaller threshold for fast boundary and restart checks.


## Design decisions

### Specify behavior before integration

Document the sampling edge and threshold to avoid disagreement about whether assertion belongs at edge N or N+1.

### Shorten simulation through parameters

The hardware and test share the same RTL with different thresholds. Small values make boundaries observable; parameter ranges still need coverage.

### Separate monitoring from recovery

This milestone produces a latched timeout. Recovery FSM, power sequencing and a complete BMC are outside its scope.


## Results and evidence

The [22 October 2026 regression](VALIDATION-2026-10-22.md) passed all 15 checks in Questa 2025.2 with 0 errors and 0 warnings. The run used an ASCII-only path and unchanged RTL/testbench; no hardware was programmed.

### Public implementation

RTL, testbench and a Questa PowerShell entry point are available. The runner requires TEST PASSED and normal process termination.

### Timing interpretation

500 ms is derived from 25,000,000 / 50,000,000, not measured board latency.

### Verification boundary

Functional simulation does not establish timing closure, board reliability or space qualification; those require separate evidence.

## Reproduction

1. Install a compatible Questa toolchain and run scripts/run_heartbeat_sim.ps1 from the repository root.
2. Check TEST PASSED and the exit code, then use open_heartbeat_wave.ps1 to inspect the counter, timeout and checker state.
3. Before FPGA integration, review clock, reset, input synchronization and constraints; perform synthesis, timing and board verification separately.

## Limits

The interactive diagram is an explanation, not simulator output. The module assumes a synchronous sampled interface; asynchronous heartbeats require additional CDC design.
