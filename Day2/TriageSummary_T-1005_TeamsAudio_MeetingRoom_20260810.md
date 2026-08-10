# Triage Summary

## Summary (one line)
Ticket T-1005: Teams audio is not working on three machines in the same meeting room.

## Impact (who/how many/ business urgency)
- Who: Users of one meeting room.
- How many: 3 machines reported affected.
- Business urgency: Potentially high due to meeting disruption (to-verify schedule/business impact).

## known facts
- Ticket ID: T-1005.
- Symptom: Teams audio is dead/not functioning.
- Scope: Three machines affected.
- Location pattern: All affected machines are in the same meeting room.

## Missing information to gather
- Whether issue is input, output, or both.
- Whether non-Teams audio works on those machines.
- Shared hardware details (dock, speakerphone, USB hub, room AV).
- Whether issue occurs for all users on those machines.
- Recent room hardware/software changes.

## likely catagory
Meeting room audio device or Teams audio path issue affecting multiple endpoints (to-verify).

## First diagnostic step
Isolate shared dependency by testing Teams audio on one affected machine with and without the room audio hardware path to confirm whether the fault is room equipment-related or endpoint-specific (to-verify).
