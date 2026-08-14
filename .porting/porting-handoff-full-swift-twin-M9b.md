# Handoff: SM64 Modern Full Swift Twin — M9b Behavior Coverage Inventory

## What Was Done

M9b turns the behavior migration boundary into an executable coverage
contract. A Swift 6 smoke asserts that the retained behavior opcode enum is
contiguous from 0x00 through 0x38 and that every slot's decoded word length
matches the C command ABI. The source audit then checks the C dispatch table
itself and inventories all native callback call sites and behavior-script
declarations from the US source tree.

The current audit baseline is:

- 57/57 behavior dispatch slots and word lengths pinned.
- 547 unique CALL_NATIVE declarations/call sites in behavior data.
- 534 unique behavior declarations across data, game, and actor sources.
- Swift opcode coverage fingerprint:
  behaviorOpcodeCoverageFingerprint=0xde06ed55e494a7bd.

## Validation

- script/test_behavior_coverage.sh passed the strict Swift opcode smoke,
  C dispatch-table count, native callback inventory, and behavior declaration
  thresholds.
- script/test_behavior_script.sh and
  script/test_behavior_script_content.sh remained green.
- The full existing script/test_*.sh matrix remained green before this
  inventory slice.
- git diff --check passed.

## Scope Boundary

The inventory counts declarations and callback sites; it does not prove that
any native callback has been replaced by Swift or that every production
behavior has route-level Swift/C parity. Native callback ownership, actor
field unions, object scheduling, collision, gameplay actions, production
resource extraction, whole-behavior differential traces, GUI capture, device
and GPU acceptance, distribution, and human acceptance remain open.
