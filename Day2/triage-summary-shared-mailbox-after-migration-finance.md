# Structured Triage Summary

## Summary (one line)
Finance user cannot open a shared mailbox after migration.

## Impact (who/how many/business urgency)
- Who: One Finance user attempting to access a shared mailbox (to-verify).
- How many: Single reported user so far (to-verify).
- Business urgency: Medium to high, depending on whether the mailbox is used for shared finance operations or time-sensitive communications (to-verify).

## Known facts
- Ticket reference is T-1002.
- A Finance user cannot open a shared mailbox.
- The issue started after a migration.

## Missing information to gather
- Whether the shared mailbox is missing entirely or opens with an error (to-verify).
- Whether the user can access the mailbox in Outlook, Outlook on the web, or both.
- Whether other users with the same mailbox permissions are affected.
- Whether the mailbox opens if added manually versus auto-mapped.
- Exact migration type and when it completed.
- Exact error wording shown to the user.
- Whether the user's primary mailbox is otherwise working normally.

## Likely category
Exchange/Outlook shared mailbox access issue after migration.

## First diagnostic step
Confirm scope by checking whether the user can open the shared mailbox in Outlook on the web; if web access works, focus first on Outlook client profile, cache, or mailbox mapping behavior after migration.
