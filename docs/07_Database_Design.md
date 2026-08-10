# 31. Database & Data Model

## 31.1 Purpose

The ExpenseHub database will store and manage users, groups, expenses, payments, splits, settlements, recurring expenses, and related information.

The database will use a relational design with clearly defined relationships between entities.

The main principle of the database design is:

> **Store source facts and derive calculated results where possible.**

For example, group balances should be calculated from expenses, payments, splits, and settlements rather than being treated as independently stored financial values.

---

## 31.2 Core Entities

The initial database will contain the following core entities:

1. User
2. Group
3. GroupMember
4. Category
5. PersonalExpense
6. Expense
7. ExpensePayment
8. ExpenseSplit
9. Settlement
10. RecurringExpense

Additional entities may be introduced later if required by authentication, invitations, notifications, audit history, or other features.

---

## 31.3 User

The User entity represents a registered ExpenseHub user.

### User Information

* User ID
* Name
* Email
* Password Hash
* Profile Image
* Created At
* Updated At

### Rules

* Each user must have a unique ID.
* Email addresses must be unique.
* Passwords must never be stored as plain text.
* Passwords must be securely hashed before being stored.

---

## 31.4 Group

The Group entity represents a collection of users who share expenses.

A group may represent:

* General shared expenses
* A trip
* A shared apartment
* A household
* Other future group activities

### Group Information

* Group ID
* Group Name
* Description
* Group Type
* Created By
* Created At
* Updated At

---

## 31.5 Group Type

ExpenseHub will support the following group types in the MVP:

* GENERAL
* TRIP
* SHARED_LIVING

The group type may be used to customize the user interface and provide relevant features.

The underlying expense management system will remain shared between all group types.

---

## 31.6 GroupMember

A GroupMember represents the relationship between a user and a group.

A user may belong to multiple groups, and a group may contain multiple users.

Therefore, GroupMember acts as the relationship entity between User and Group.

### GroupMember Information

* Group Member ID
* Group ID
* User ID
* Role
* Joined At

### MVP Roles

* OWNER
* MEMBER

### Rules

* A user cannot be added to the same group more than once.
* The combination of Group ID and User ID must be unique.
* The group owner must be a member of the group.

---

## 31.7 Category

The Category entity represents the category of an expense.

### Initial Categories

* Food
* Transport
* Shopping
* Bills
* Entertainment
* Education
* Healthcare
* Travel
* Accommodation
* Rent
* Electricity
* Water
* Internet
* Groceries
* Maintenance
* Other

Categories may be expanded in future versions.

---

## 31.8 PersonalExpense

PersonalExpense represents an expense belonging directly to one user.

Personal expenses are independent of group expenses.

### PersonalExpense Information

* Personal Expense ID
* User ID
* Category ID
* Description
* Amount
* Expense Date
* Note
* Created At
* Updated At

### Example

```text
User: Aarav

Description: Dinner
Amount: ₹300
Category: Food
```

This expense affects Aarav's personal spending statistics but does not affect any group balance.

---

## 31.9 Expense

Expense represents a shared expense belonging to a group.

### Expense Information

* Expense ID
* Group ID
* Category ID
* Description
* Total Amount
* Expense Date
* Split Type
* Created By
* Created At
* Updated At

### Supported MVP Split Types

* EQUAL
* CUSTOM

### Future Split Types

* PERCENTAGE
* SHARE_BASED

---

## 31.10 ExpensePayment

ExpensePayment represents money actually paid toward a group expense.

A single expense may have multiple payers.

### ExpensePayment Information

* Payment ID
* Expense ID
* User ID
* Amount
* Created At

### Example

For an ₹8,000 hotel expense:

```text
Aarav → ₹5,000
Rohan → ₹3,000
```

Both payments belong to the same expense.

### Validation

The following condition must always be satisfied:

```text
Sum of all payments = Expense Total Amount
```

---

## 31.11 ExpenseSplit

ExpenseSplit represents how much of an expense each participant is responsible for.

A single expense may have multiple participants.

### ExpenseSplit Information

* Split ID
* Expense ID
* User ID
* Share Amount
* Created At

### Example

For an ₹8,000 expense:

```text
Aarav → ₹2,000
Rohan → ₹2,000
Priya → ₹2,000
Neha → ₹2,000
```

### Validation

The following condition must always be satisfied:

```text
Sum of all split amounts = Expense Total Amount
```

---

## 31.12 Payment vs Split

Payment and Split represent two different concepts.

### Payment

Answers:

> Who actually paid the money?

### Split

Answers:

> Who is responsible for the expense?

For example:

```text
Expense = ₹8,000

Payments:
Aarav → ₹5,000
Rohan → ₹3,000

Splits:
Aarav → ₹2,000
Rohan → ₹2,000
Priya → ₹2,000
Neha → ₹2,000
```

This distinction is fundamental to the ExpenseHub balance system.

---

## 31.13 Balance Calculation

The balance of each group member is derived from payment and split records.

For each member:

```text
Expense Balance =
Total Amount Paid - Total Share
```

### Positive Balance

The member should receive money.

### Negative Balance

The member owes money.

### Zero Balance

The member has no outstanding amount.

---

## 31.14 Balance Invariant

The sum of all member balances for a group expense must equal zero.

Example:

```text
Aarav   +₹3,000
Rohan   +₹1,000
Priya   -₹2,000
Neha    -₹2,000
----------------
Total    ₹0
```

This invariant should be maintained by the system.

---

## 31.15 Settlement

Settlement represents money transferred between group members to reduce outstanding balances.

### Settlement Information

* Settlement ID
* Group ID
* Payer ID
* Receiver ID
* Amount
* Settlement Date
* Note
* Created By
* Created At

### Example

```text
Priya → Aarav
₹2,000
```

The settlement reduces Priya's outstanding amount and reduces Aarav's amount to be received.

---

## 31.16 Settlement Rules

* Payer must be a member of the group.
* Receiver must be a member of the group.
* Settlement amount must be positive.
* Payer and receiver should not be the same user.
* The authenticated user must be authorized to create the settlement.
* Historical settlements should remain available for reporting and auditing.

---

## 31.17 RecurringExpense

RecurringExpense represents a template for expenses that occur repeatedly.

Examples:

* Monthly rent
* Monthly internet
* Fixed maintenance charges

A recurring expense is a template and is not itself included directly in balance calculations.

### RecurringExpense Information

* Recurring Expense ID
* Group ID
* Name
* Amount
* Category ID
* Frequency
* Start Date
* End Date
* Split Type
* Status
* Created By
* Created At
* Updated At

---

## 31.18 Recurring Expense Generation

A recurring expense template generates an actual group Expense.

Conceptually:

```text
Recurring Expense Template
            ↓
      Actual Expense
            ↓
    ┌───────┴───────┐
    ↓               ↓
 Payments          Splits
```

The generated Expense participates in normal balance calculations.

---

## 31.19 Recurring Expense Frequency

MVP:

* MONTHLY

Future:

* WEEKLY
* YEARLY
* CUSTOM

Monthly recurrence is prioritized because it covers common shared-living expenses such as rent and internet.

---

## 31.20 Recurring Expense Status

MVP statuses:

* ACTIVE
* PAUSED

Future:

* ENDED

Pausing a recurring expense prevents future occurrences from being generated while preserving historical expenses.

---

## 31.21 Recurring Expense Duplicate Prevention

The system must prevent the same recurring expense occurrence from being generated more than once for the same billing period.

For example:

```text
August Rent
```

must not accidentally be created multiple times.

The backend must maintain sufficient information to identify whether an occurrence for a particular billing period has already been generated.

---

## 31.22 Historical Expense Preservation

Deleting, pausing, or ending a recurring expense template must not delete previously generated expenses.

Historical expenses must remain available for:

* Balance calculations
* Reports
* Spending history
* Financial records

---

## 31.23 Money Representation

All financial amounts must be stored using the smallest currency unit rather than floating-point values.

For Indian Rupees:

```text
₹100.50 = 10050 paise
```

Therefore, financial amounts should be stored as integer values representing paise.

This prevents common floating-point precision problems during financial calculations.

---

## 31.24 Date and Time

The database must use appropriate date and time data types.

Common date/time fields include:

* Created At
* Updated At
* Expense Date
* Settlement Date
* Start Date
* End Date
* Joined At

The application should use a consistent timezone strategy.

---

## 31.25 Foreign Keys

Foreign keys will be used to maintain relationships between entities.

Examples:

```text
PersonalExpense.user_id
        → User.id

PersonalExpense.category_id
        → Category.id

GroupMember.user_id
        → User.id

GroupMember.group_id
        → Group.id

Expense.group_id
        → Group.id

Expense.category_id
        → Category.id

ExpensePayment.expense_id
        → Expense.id

ExpensePayment.user_id
        → User.id

ExpenseSplit.expense_id
        → Expense.id

ExpenseSplit.user_id
        → User.id

Settlement.group_id
        → Group.id

Settlement.payer_id
        → User.id

Settlement.receiver_id
        → User.id

RecurringExpense.group_id
        → Group.id

RecurringExpense.category_id
        → Category.id
```

---

## 31.26 Database Constraints

The database and backend must enforce appropriate data integrity rules.

Important constraints include:

* Unique user email
* Unique group membership
* Valid foreign-key relationships
* Positive financial amounts
* Valid group membership
* Payment total equals expense total
* Split total equals expense total
* Valid settlement participants
* Valid recurring expense configuration

---

## 31.27 Source of Truth

The following records are considered the primary source of financial information:

* Personal expenses
* Group expenses
* Expense payments
* Expense splits
* Settlements
* Recurring expense templates

Calculated values should not unnecessarily become independent sources of truth.

---

## 31.28 Calculated Data

The following values should primarily be calculated from source records:

* Group balances
* Personal spending summaries
* Category totals
* Monthly spending totals
* Settlement-adjusted balances
* Dashboard statistics
* Reports

For example:

```text
Current Balance
=
Payments
-
Expense Shares
-
Relevant Settlement Effects
```

The exact balance calculation will be finalized during backend implementation.

---

## 31.29 Database Relationships

The major relationships are:

```text
User
 │
 ├── PersonalExpense
 │
 ├── GroupMember
 │       │
 │       └── Group
 │              │
 │              └── Expense
 │                    ├── ExpensePayment
 │                    └── ExpenseSplit
 │
 └── Settlement
```

---

## 31.30 Initial Database Tables

The initial database will contain:

```text
users
groups
group_members
categories
personal_expenses
expenses
expense_payments
expense_splits
settlements
recurring_expenses
```

Additional supporting tables may be introduced when required.

---

## 31.31 Database Design Principles

ExpenseHub database design should follow these principles:

1. Maintain clear relationships between entities.
2. Avoid duplicate financial information.
3. Store financial amounts using integer smallest currency units.
4. Use foreign keys to maintain referential integrity.
5. Validate financial totals at the backend.
6. Derive balances from source financial records.
7. Preserve historical financial information.
8. Prevent duplicate recurring expense occurrences.
9. Keep personal and group expenses logically separated.
10. Design the database so future features can be added without major restructuring.

---

## 31.32 Preliminary Entity Relationship Overview

The preliminary relationship structure is:

```text
                    ┌──────────┐
                    │   USER   │
                    └────┬─────┘
                         │
              ┌──────────┼───────────┐
              │          │           │
              ▼          ▼           ▼
       PersonalExpense GroupMember Settlement
                         │             │
                         ▼             ▼
                       Group         User
                         │
                         ▼
                       Expense
                      /       \
                     ▼         ▼
              ExpensePayment  ExpenseSplit
                     │         │
                     └────┬────┘
                          │
                       Category
```

This is a preliminary representation. The final ER diagram and exact cardinalities will be documented in the next database-design section.

---

## 31.33 Future Database Extensions

Possible future entities include:

* Group Invitations
* Notifications
* Expense Attachments
* Comments
* Expense Edit History
* Recurring Expense Occurrences
* User Preferences
* Audit Logs
* Currency Management

These will not be added to the MVP database unless required.
