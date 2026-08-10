# Triage Summary

## Summary (one line)
Ticket T-1001: New Windows 11 laptop is prompting for a BitLocker recovery key on every boot.

## Impact (who/how many/ business urgency)
- Who: Single user/device reported in this ticket (to-verify).
- How many: 1 known affected ticket so far (to-verify if broader pattern).
- Business urgency: Potentially high because repeated boot recovery prompts can block normal device access; user role/time-critical need is to-verify.

## known facts
- Ticket ID: T-1001.
- Device context: New Windows 11 laptop.
- Symptom: BitLocker recovery key prompt appears every boot.

## Missing information to gather
- User identity, department, and contact details.
- Device hostname/asset ID/serial number.
- Whether the user can successfully enter the recovery key and reach Windows each time.
- When the issue started and whether it began after any change (firmware/BIOS update, hardware change, policy change).
- Whether the same behavior occurs on every restart and cold boot.
- Whether other newly issued Windows 11 laptops are affected.
- Whether device is domain/Azure AD joined and recovery key escrow location.

## likely catagory
Endpoint security and encryption startup issue (BitLocker repeated recovery prompt) (to-verify).

## First diagnostic step
Validate and document scope by confirming the exact boot sequence and reproducing one reboot cycle while checking if the recovery prompt appears consistently, then confirm recovery key escrow/retrieval path for that device (to-verify).
