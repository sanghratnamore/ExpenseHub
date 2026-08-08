# ExpenseHub — UI/UX Blueprint

## 1. Application Type

ExpenseHub will be developed as a responsive web application.

The MVP should support:

* Desktop
* Laptop
* Tablet
* Mobile browser

A separate mobile application is outside the MVP scope.

---

# 2. Main Application Layout

The authenticated application will use a:

**Sidebar + Topbar layout**

### Topbar

* ExpenseHub logo/name
* Notifications
* User profile

### Sidebar

#### Main

* Dashboard

#### Money

* Personal Expenses

#### Groups

* My Groups

#### Insights

* Reports

#### Account

* Profile
* Settings

#### Bottom

* Logout

---

# 3. Main Screens

## Public Screens

1. Landing Page
2. Login
3. Registration

## User Screens

4. Dashboard
5. Personal Expenses
6. Add/Edit Personal Expense
7. Groups
8. Create Group
9. Group Overview
10. Group Expenses
11. Add Group Expense
12. Group Balances
13. Group Settlements
14. Group Members
15. Reports
16. Profile
17. Settings

## Admin Screens

18. Admin Dashboard
19. User Management
20. Category Management
21. Reports/Moderation

---

# 4. Group Navigation

Each group will have its own navigation:

* Overview
* Expenses
* Balances
* Settlements
* Members

A group may have a type:

* General
* Trip
* Shared Home

Trips and shared homes will not have completely separate expense systems. They will use the common group expense engine.

---

# 5. Dashboard

The dashboard should contain:

* Welcome message
* Income summary
* Personal spending summary
* Group balance summary
* Monthly spending chart
* Recent expenses
* Recent group activity

---

# 6. Personal Expenses

The page should contain:

* Total monthly spending
* Add Expense button
* Search
* Category filter
* Date filter
* Expense list/table
* Edit action
* Delete action

---

# 7. Add Personal Expense

Fields:

* Amount
* Category
* Date
* Description

Actions:

* Cancel
* Save Expense

---

# 8. Create Group

Fields:

* Group name
* Description
* Group type

Group types:

* General
* Trip
* Shared Home

---

# 9. Add Group Expense

Fields:

* Description
* Amount
* Category
* Payer
* Participants
* Split type

Split types:

* Equal
* Custom

The system must validate that custom participant shares equal the total expense amount.

---

# 10. Group Balances

The balance screen should show:

* Amount the current user should receive
* Amount the current user owes
* Relevant member balances
* Settlement action

---

# 11. Settlement

The settlement form should contain:

* Member
* Amount
* Date
* Optional note

After recording a settlement, the system should recalculate the relevant outstanding balance.

---

# 12. Reports

The MVP reports page should contain:

* Selected date range
* Total spending
* Category summary
* Monthly summary
* Group expense summary
* Basic charts

PDF and Excel export are planned for a future version.

---

# 13. Responsive Design

### Desktop

Use a persistent sidebar and topbar.

### Mobile

Use:

* Hamburger menu
* Responsive cards
* Mobile-friendly forms
* Optional bottom navigation for primary actions

Tables should transform into cards or horizontally scroll when necessary.

---

# 14. Reusable UI Components

The frontend should use reusable components such as:

* Buttons
* Inputs
* Dropdowns
* Cards
* Tables
* Modals
* Toast notifications
* Navigation
* Sidebar
* Topbar
* Loading indicators
* Error messages
* Empty states

---

# 15. Required UI States

Every major screen should support:

### Normal State

Displays the available data.

### Empty State

Displays a useful message and relevant action.

### Loading State

Displays a loading indicator while data is being retrieved.

### Error State

Displays an understandable error message and retry action where appropriate.

---

# 16. UI Design Principles

ExpenseHub should prioritize:

* Simplicity
* Clean visual hierarchy
* Consistency
* Accessibility
* Responsive design
* Clear feedback
* Minimal unnecessary complexity
* Reusable components

Because ExpenseHub deals with financial information, the interface should communicate reliability and transparency.

---

# 17. Navigation Structure

```text
ExpenseHub
│
├── Dashboard
│
├── Personal Expenses
│   ├── Expense List
│   └── Add/Edit Expense
│
├── Groups
│   ├── My Groups
│   ├── Create Group
│   └── Group
│       ├── Overview
│       ├── Expenses
│       ├── Balances
│       ├── Settlements
│       └── Members
│
├── Reports
│
├── Profile
│
├── Settings
│
└── Logout
```

## 18. Public Pages

### 18.1 Landing Page

### 18.2 Login

### 18.3 Registration

## 19. Authentication Flow

## 20. Public vs Protected Routes

## 21. URL Structure

## 22. Authentication Security Requirements

## 23. Accessibility Requirements

## 24. Dashboard Design

### 24.1 Purpose

The dashboard serves as the user's primary overview screen after authentication.

### 24.2 Dashboard Header

- Personalized greeting
- Financial overview description

### 24.3 Summary Cards

- Personal Spending
- Group Expenses
- Net Group Balance

### 24.4 Monthly Spending Chart

- Monthly spending visualization
- Month selector

### 24.5 Quick Actions

- Add Expense
- Create Group
- View Groups

### 24.6 Recent Expenses

- Display latest personal expenses
- Show description, category, date and amount
- Link to complete expense history

### 24.7 Group Balances

- Display relevant group balances
- Clearly distinguish money owed from money receivable
- Link to group balance details

### 24.8 Dashboard Empty State

Provide useful onboarding actions when the user has no expenses or groups.

### 24.9 Dashboard Loading State

Display loading indicators while dashboard information is being retrieved.

### 24.10 Dashboard Error State

Display a user-friendly error message and retry option when dashboard data cannot be loaded.

### 24.11 Dashboard Responsive Design

On smaller screens, dashboard cards and sections should stack vertically.

### 24.12 Dashboard Data Requirements

The dashboard requires information from:

- User
- Personal Expenses
- Groups
- Group Expenses
- Settlements

## 25. Personal Expense Management

### 25.1 Purpose

The Personal Expense module allows users to record, view, edit, delete, search and filter their own expenses.

### 25.2 Expense Fields

- Amount
- Description
- Category
- Date
- Notes

### 25.3 Expense Categories

- Food
- Transport
- Shopping
- Bills
- Entertainment
- Education
- Healthcare
- Travel
- Other

### 25.4 Expense List

The expense list should display:

- Date
- Description
- Category
- Amount
- Actions

### 25.5 Expense Actions

Users can:

- Add
- View
- Edit
- Delete

### 25.6 Search and Filters

The MVP should support:

- Description search
- Category filtering
- Date/month filtering

### 25.7 Validation

The system should validate:

- Amount is required
- Amount must be positive
- Description is required
- Category is required
- Date is valid

Both frontend and backend validation are required.

### 25.8 Delete Confirmation

The system must request confirmation before permanently deleting an expense.

### 25.9 Empty State

New users with no expenses should receive a helpful message and an action to add their first expense.

### 25.10 Loading State

The application should display a loading state while expenses are being retrieved.

### 25.11 Error State

The application should provide a user-friendly error message if expenses cannot be loaded.

### 25.12 Data Ownership

Users may only access and modify their own personal expenses.

### 25.13 Initial Expense Data Model

```text
Expense
├── ID
├── User
├── Amount
├── Description
├── Category
├── Date
├── Notes
├── Created At
└── Updated At

## 26. Group Management

### 26.1 Purpose

The Group Management module allows users to create and participate in shared expense groups.

### 26.2 Group Types

- General
- Trip
- Shared Home

### 26.3 Group Creation

Required:
- Group name
- Group type

Optional:
- Description

### 26.4 Group Roles

- Owner
- Member

### 26.5 Owner Permissions

- View group
- Add expenses
- Edit own expenses
- Delete own expenses
- Invite members
- Remove members
- Manage group settings
- Archive group

### 26.6 Member Permissions

- View group
- Add expenses
- Edit own expenses
- Delete own expenses
- View balances
- Record settlements
- Leave group

### 26.7 Group Invitations

Only registered ExpenseHub users can be invited during the MVP.

Users can:
- Accept invitation
- Decline invitation

### 26.8 Group Expenses

Each group expense contains:
- Amount
- Description
- Category
- Date
- Created By
- Paid By
- Split Type
- Participants

### 26.9 Expense Ownership

The user who creates a group expense can edit or delete it.

### 26.10 Member Removal

Members with outstanding balances cannot be removed.

### 26.11 Leaving a Group

Members cannot leave while they have an outstanding balance.

### 26.12 Group Deletion

Groups will not be permanently deleted in the MVP.

Groups may be archived instead.

### 26.13 Group Empty State

Groups without expenses should provide an option to add the first shared expense.

### 26.14 Group Data Structure

```text
Group
├── ID
├── Name
├── Description
├── Type
├── Owner
├── Status
├── Created At
└── Updated At

## 27. Group Expense & Split System

### 27.1 Purpose

The Group Expense system allows group members to record shared expenses and automatically determine each participant's share.

### 27.2 Expense Information

A group expense contains:

- Description
- Amount
- Category
- Date
- Created By
- Paid By
- Participants
- Split Type

### 27.3 Supported Split Types

MVP:

- Equal Split
- Custom Amount Split

Future:

- Percentage Split
- Share-Based Split

### 27.4 Equal Split

The system divides the expense amount equally among selected participants.

### 27.5 Custom Split

Users may specify an individual amount for each participant.

The total of all participant shares must exactly equal the expense amount.

### 27.6 Participants

At least one group member must participate in an expense.

The person who paid the expense does not have to be a participant.

### 27.7 Paid By

The payer must be a member of the group.

### 27.8 Balance Calculation

For each member:

Balance = Total Amount Paid - Total Share of Expenses

Positive balance:
The member should receive money.

Negative balance:
The member owes money.

### 27.9 Balance Invariant

The sum of all member balances within a group must equal zero.

### 27.10 Money Representation

Financial amounts should be stored using the smallest currency unit (paise) rather than floating-point values.

### 27.11 Expense Validation

The system must verify:

- Amount is positive
- Description is provided
- Category is provided
- Date is valid
- Payer belongs to the group
- At least one participant is selected
- Custom split totals equal the expense amount

### 27.12 Expense Permissions

Users may edit or delete only expenses they created.

### 27.13 Backend Authorization

The backend must verify that the authenticated user belongs to the group before allowing group expense operations.

### 27.14 Balance Source of Truth

Current balances should be derived from expense and settlement records rather than relying solely on manually stored balance values.

### 27.15 Future Enhancements

- Percentage splitting
- Share-based splitting
- Receipt attachment
- Expense comments
- Expense editing history

## 28. Settlement System

### 28.1 Purpose

The Settlement System allows group members to record payments made between members to settle outstanding group balances.

A settlement represents a payment that has already occurred outside the ExpenseHub platform.

ExpenseHub records the settlement but does not process or verify the actual financial transaction.

---

### 28.2 Expense vs Settlement

An expense records a shared financial obligation.

A settlement records the payment used to reduce or clear that obligation.

Settlements must not be recorded as normal expenses because doing so would incorrectly increase the group's total expenses.

---

### 28.3 Settlement Information

A settlement contains:

* Settlement ID
* Group
* Payer
* Receiver
* Amount
* Date
* Note
* Created By
* Created At
* Status

---

### 28.4 Settlement Participants

The payer and receiver must both be members of the group.

The payer must be the authenticated user creating the settlement in the MVP.

A user cannot create a settlement where the payer and receiver are the same person.

---

### 28.5 Settlement Amount

The settlement amount must:

* Be greater than zero.
* Be represented using the smallest currency unit.
* Not exceed the applicable outstanding amount for the payer in the MVP.

Partial settlements are supported.

---

### 28.6 Partial Settlement

Members may settle an outstanding balance in multiple payments.

Example:

```text
Priya owes Aarav ₹2,000.

First settlement:
Priya → Aarav ₹1,000

Remaining:
₹1,000
```

A second settlement may clear the remaining amount.

---

### 28.7 Settlement Status

MVP settlement status:

* RECORDED

ExpenseHub does not verify whether the external payment was actually completed.

The settlement represents the user's recorded transaction.

---

### 28.8 Settlement Calculation

Current outstanding balances should consider both expenses and settlements.

Conceptually:

```text
Current Balance
=
Expense-Based Balance
+
Settlement Effects
```

A payment from a member to another member reduces the payer's negative balance and the receiver's positive balance.

---

### 28.9 Settlement History

Each group should provide a settlement history containing:

* Payer
* Receiver
* Amount
* Date
* Note
* Status

Users should be able to view previous settlements.

---

### 28.10 Settlement Permissions

MVP permissions:

* Group members can view settlements.
* A member can create a settlement where they are the payer.
* A member can delete their own settlement.
* Members cannot modify or delete another member's settlement.

---

### 28.11 Settlement Editing

Direct editing of settlements is not supported in the MVP.

If a settlement was recorded incorrectly, the user may delete the settlement and create a corrected settlement.

Future versions may implement settlement reversal and audit history.

---

### 28.12 Settlement Validation

The backend must verify:

* Payer belongs to the group.
* Receiver belongs to the group.
* Payer and receiver are different users.
* Payer is the authenticated user.
* Amount is positive.
* Amount does not exceed the applicable outstanding amount.
* Group exists and is active.
* User has permission to create the settlement.

---

### 28.13 Balance Recalculation

Balances should not depend on a manually stored balance value.

Balances should be derived from:

```text
Expenses
   +
Settlements
   ↓
Current Outstanding Balances
```

If an expense is edited or deleted, current balances must be recalculated accordingly.

If a settlement is deleted, the affected balances must also be recalculated.

---

### 28.14 Settlement Example

Before settlement:

```text
Aarav   +₹2,000
Priya   -₹2,000
```

Priya records:

```text
Priya → Aarav
₹1,000
```

After settlement:

```text
Aarav   +₹1,000
Priya   -₹1,000
```

After another ₹1,000 settlement:

```text
Aarav   ₹0
Priya   ₹0
```

---

### 28.15 Future Settlement Features

* Settlement optimization
* Minimum-transfer calculation
* Settlement reminders
* UPI integration
* Payment verification
* Settlement requests
* Settlement confirmation by receiver
* Settlement reversal
* Settlement audit history

## 29. Dashboard & Reports System

### 29.1 Purpose

The Dashboard and Reports system provides users with a summarized view of their personal finances and group expenses.

The dashboard should prioritize useful financial information rather than unnecessary visual elements.

---

### 29.2 Dashboard Types

ExpenseHub will contain two primary dashboard types:

1. Personal Dashboard
2. Group Dashboard

---

### 29.3 Personal Dashboard

The Personal Dashboard provides an overview of the authenticated user's personal financial activity.

It includes:

* Total income
* Total expenses
* Remaining amount
* Net group balance
* Recent expenses
* Spending by category
* Monthly spending summary
* Group summary
* Quick actions

---

### 29.4 Personal Financial Summary

The dashboard should display:

* Total income for the selected period
* Total personal expenses for the selected period
* Remaining amount
* Current net group balance

The remaining amount is calculated as:

```text id="5icr6f"
Remaining = Total Income - Total Personal Expenses
```

Group balances should be displayed separately from personal income and expenses.

---

### 29.5 Recent Personal Expenses

The dashboard should display the user's most recent expenses.

Each expense should show:

* Description
* Category
* Amount
* Date

The dashboard may display the latest 5–10 expenses with an option to view all expenses.

---

### 29.6 Personal Spending Categories

The system should summarize personal expenses by category.

Supported categories include:

* Food
* Transport
* Shopping
* Bills
* Entertainment
* Education
* Healthcare
* Travel
* Accommodation
* Other

---

### 29.7 Group Dashboard

Each group should have a dedicated dashboard.

The Group Dashboard should display:

* Group name
* Number of members
* Total group expenses
* Current user's group balance
* Recent group expenses
* Spending by category
* Member balances
* Recent settlements
* Group activity summary

---

### 29.8 Group Expense Summary

The system should display the total amount recorded through group expenses.

Example:

```text id="95n7o1"
Total Group Expenses
₹18,500
```

This represents the total of recorded group expenses and not the amount currently owed between members.

---

### 29.9 Group Spending by Category

The system should summarize group expenses by category.

Example:

```text id="i2qcku"
Accommodation     ₹8,000
Food              ₹4,000
Transport         ₹2,500
Entertainment     ₹2,000
Other             ₹2,000
```

---

### 29.10 Group Balance Summary

The Group Dashboard should display each member's current outstanding balance.

Positive balance:

> Member should receive money.

Negative balance:

> Member owes money.

The logged-in user's balance should be highlighted.

---

### 29.11 Recent Group Expenses

The system should display recent group expenses including:

* Description
* Total amount
* Payers
* Date
* Category

When multiple members paid for an expense, the dashboard should indicate the multiple payers.

---

### 29.12 Settlement Summary

The Group Dashboard may display recent settlement activity.

Example:

```text id="m6f4h2"
Priya paid Aarav ₹1,000
Rohan paid Aarav ₹500
```

A link should allow users to view the complete settlement history.

---

### 29.13 Personal Reports

MVP personal reports:

1. Monthly spending summary
2. Spending by category
3. Income vs expenses

---

### 29.14 Group Reports

MVP group reports:

1. Total group spending
2. Spending by category
3. Member balances
4. Settlement history

---

### 29.15 Report Periods

The reporting system should support:

* Current Month
* Previous Month
* Custom Date Range

Additional periods may be added in future versions.

---

### 29.16 Report Filtering

Reports should allow filtering by:

* Date range
* Category

Additional filters may be introduced in future versions.

---

### 29.17 Dashboard Quick Actions

The Personal Dashboard should provide shortcuts for:

* Add Personal Expense
* Add Income
* Create Group
* View Groups

The Group Dashboard should provide shortcuts for:

* Add Group Expense
* View Balances
* Record Settlement
* View Members

---

### 29.18 Dashboard Security

Personal dashboard information must only be accessible to the authenticated user who owns the data.

Group dashboard information must only be accessible to members of the respective group.

Backend authorization must be used to enforce these restrictions.

---

### 29.19 Data Accuracy

Dashboard values should be derived from the underlying expense, income, payment, split, and settlement records.

Dashboard calculations must not rely solely on manually stored summary values.

---

### 29.20 MVP Scope

The MVP dashboard will include:

* Personal financial summary
* Personal recent expenses
* Personal category summary
* Group summary
* Group total expenses
* Group balances
* Group recent expenses
* Group category summary
* Settlement summary

---

### 29.21 Future Enhancements

* PDF report export
* CSV export
* Advanced charts
* Spending comparisons
* Budget tracking
* Spending alerts
* Advanced analytics
* Spending trend analysis
* Automated expense categorization
* AI-assisted financial insights

## 30. Shared Living & Recurring Expenses

### 30.1 Purpose

ExpenseHub will support shared-living groups such as roommates, shared apartments, and houses.

Shared-living groups can use the existing group expense, payment, split, balance, and settlement systems to manage common household expenses.

---

### 30.2 Shared Living Group Type

Groups may have a type:

* General
* Trip
* Shared Living

The group type may customize the user interface and available features without creating a separate expense management system.

---

### 30.3 Shared Living Expenses

Common shared-living expenses include:

* Rent
* Electricity
* Water
* Internet
* Groceries
* Gas
* Maintenance
* Cleaning
* Other

These expenses use the same Group Expense system as other groups.

---

### 30.4 Shared Living Dashboard

A Shared Living group dashboard should display:

* Total expenses for the current month
* User's total share
* User's total payments
* Current outstanding balance
* Monthly expense breakdown
* Recurring expenses
* Recent expenses
* Upcoming recurring expenses

---

### 30.5 Recurring Expense

A recurring expense represents an expense that occurs repeatedly according to a defined schedule.

A recurring expense should be treated as a template rather than as an actual expense.

Conceptually:

```text
Recurring Expense Template
          ↓
Generates
          ↓
Actual Group Expense
```

---

### 30.6 Recurring Expense Information

A recurring expense may contain:

* Name
* Amount
* Category
* Group
* Frequency
* Start Date
* End Date
* Payers
* Participants
* Split Type
* Status

---

### 30.7 Recurring Expense Frequency

MVP:

* Monthly

Future:

* Weekly
* Yearly
* Custom frequency

Monthly recurring expenses are prioritized because they cover common shared-living expenses such as rent and internet.

---

### 30.8 Fixed and Variable Expenses

Fixed recurring expenses have a predictable amount.

Examples:

* Rent
* Internet
* Fixed maintenance charges

Variable recurring expenses may have different amounts each period.

Examples:

* Electricity
* Water
* Groceries

MVP recurring expense functionality should prioritize fixed monthly expenses.

Variable recurring expenses may initially be handled through reminders or manual expense creation.

---

### 30.9 Recurring Expense Generation

The system should generate an actual group expense for each recurring period.

The generated expense must use the existing:

* Payment system
* Participant system
* Split system
* Balance system
* Settlement system

---

### 30.10 Duplicate Prevention

The system must prevent the same recurring expense occurrence from being generated more than once for the same billing period.

For example:

```text
August Rent
```

must not accidentally be generated multiple times.

---

### 30.11 Historical Expenses

Deleting, pausing, or ending a recurring expense template must not delete previously generated expenses.

Historical expenses must remain available for reporting and balance calculations.

---

### 30.12 Recurring Expense Status

MVP statuses:

* ACTIVE
* PAUSED

Future versions may support:

* ENDED

---

### 30.13 Pause

Pausing a recurring expense prevents future occurrences from being generated.

Previously generated expenses remain unchanged.

---

### 30.14 Delete

Deleting a recurring expense removes the recurring template from future generation.

Previously generated expenses must not be deleted automatically.

---

### 30.15 Shared Living Balance

The existing group balance calculation will be used.

For each member:

```text
Balance = Total Amount Paid - Total Share of Expenses
```

Settlements will reduce outstanding balances in the same way as other group types.

---

### 30.16 Multiple Payers

Shared-living expenses must support multiple payers.

Example:

```text
Rent: ₹20,000

Aarav → ₹12,000
Rohan → ₹8,000
```

The expense may still be split among all apartment members.

---

### 30.17 Recurring Expense Permissions

Only authorized group members should be able to:

* Create recurring expenses
* Pause recurring expenses
* Resume recurring expenses
* Delete recurring expenses

Backend authorization must be used for all operations.

---

### 30.18 MVP Scope

The MVP will support:

* Shared Living group type
* Shared-living dashboard
* Monthly recurring expenses
* Fixed recurring expense amounts
* Multiple payers
* Existing equal and custom splits
* Recurring expense pause/resume
* Duplicate occurrence prevention

---

### 30.19 Future Enhancements

* Variable recurring expenses
* Automatic bill reminders
* Weekly recurring expenses
* Yearly recurring expenses
* Custom recurrence schedules
* Utility bill tracking
* Bill due-date notifications
* Shared household tasks
* Expense approval
* Advanced recurring expense management

