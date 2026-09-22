# Heartbeat Monitor Module Specification

Status: Prototype 0 module-level baseline

RTL language: Verilog-2001

Module: `heartbeat_monitor`

## 1. Purpose

The heartbeat monitor detects when a supervised host has stopped producing a
periodic heartbeat. It only detects and reports the timeout condition. It does
not decide which recovery action to perform; that responsibility belongs to a
later watchdog or recovery module.

## 2. Interface

| Name | Direction | Width | Clock domain | Meaning |
|---|---:|---:|---|---|
| `clk` | input | 1 | source | Monitoring clock. State changes occur on its rising edge. |
| `rst_n` | input | 1 | asynchronous | Active-low reset. A low level immediately clears the counter and `timeout`. |
| `heartbeat` | input | 1 | synchronous to `clk` | A high level sampled on a rising edge is a valid heartbeat event. |
| `clear_timeout` | input | 1 | synchronous to `clk` | A high level sampled on a rising edge explicitly clears the timeout and restarts the interval. |
| `timeout` | output | 1 | registered to `clk` | Indicates that the allowed number of consecutive missing-heartbeat samples has been reached. |

The Prototype 0 module assumes `heartbeat` and `clear_timeout` are already
synchronous to `clk`. Synchronizers and clock-domain crossing logic are outside
this module. A future integration specification must identify the source clock
domain before connecting an asynchronous external signal.

## 3. Parameter

`TIMEOUT_CYCLES` is the number of consecutive rising edges of `clk` without a
sampled heartbeat before `timeout` asserts. It must be at least one.

The default is 25,000,000 cycles. With a 50 MHz clock:

```text
clock period     = 1 / 50,000,000 = 20 ns
timeout duration = 25,000,000 x 20 ns = 500 ms
```

The module parameter is expressed in cycles so that the RTL does not silently
assume a final product clock frequency. The top-level integration is
responsible for selecting a value consistent with its actual clock.

## 4. Cycle-Accurate Behavior

Priority from highest to lowest:

1. When `rst_n` is low, clear the elapsed-cycle counter and drive `timeout` low.
2. When `heartbeat` or `clear_timeout` is sampled high, clear the counter and
   drive `timeout` low.
3. While `timeout` is low and neither recovery input is active, increment the
   elapsed-cycle count.
4. On the `TIMEOUT_CYCLES`th consecutive rising edge without a heartbeat,
   assert `timeout`.
5. Once asserted, keep `timeout` high until reset, a new heartbeat, or
   `clear_timeout` occurs.

For `TIMEOUT_CYCLES = 5`, the missing-heartbeat boundary is:

| Rising edge without heartbeat | Elapsed interval after edge | `timeout` |
|---:|---:|---:|
| 1 | 1 cycle | 0 |
| 2 | 2 cycles | 0 |
| 3 | 3 cycles | 0 |
| 4 | 4 cycles | 0 |
| 5 | 5 cycles | 1 |

A heartbeat sampled on edge 5 has priority over the timeout comparison. It
restarts the interval and leaves `timeout` low.

## 5. Reset and Startup Assumption

Counting begins on the first rising clock edge after `rst_n` is released. The
Prototype 0 design does not wait for a first heartbeat and does not have an
`enable` or `armed` input. Therefore, a host that never starts producing
heartbeats will still cause a timeout after one complete interval.

This is an explicit prototype assumption. System integration must later decide
whether reset release means that the host is expected to become alive
immediately, or whether an enable/arming phase is required.

## 6. Output Semantics

`timeout` is a latched level, not a one-clock pulse. A level is used because a
downstream fault manager may not sample the exact assertion cycle. The
downstream logic receives a persistent fault indication until an explicit
recovery event occurs.

This module does not generate the architectural fault code `8'h01`; mapping the
timeout indication to the Heartbeat Timeout fault code belongs to the fault
manager or integration layer.

## 7. Items Not Yet Proven

The current module-level simulation does not prove:

- operation with an asynchronous heartbeat source;
- metastability protection or clock-domain crossing correctness;
- the final system clock frequency;
- Quartus synthesis resource use or maximum clock frequency;
- behavior after FPGA placement and routing;
- behavior on the DE10-Standard board;
- Recovery FSM behavior.

These items belong to later engineering gates and must not be inferred from a
passing RTL simulation.
