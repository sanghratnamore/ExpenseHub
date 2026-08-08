# ExpenseHub — Use Cases & User Flows

## 1. System Actors

### User

The primary ExpenseHub user who can manage personal expenses, groups, shared expenses, balances, and settlements.

### Administrator

The platform administrator who manages users, categories, reports, and other administrative operations.

---

# 2. System Boundary

## Inside ExpenseHub

* Account management
* Personal expense management
* Group management
* Group expense management
* Expense splitting
* Balance calculation
* Settlement management
* Dashboard
* Reports
* Administrative management

## Outside the Initial System

* Actual bank transfers
* UPI payment processing
* Bank account management
* Investment services
* Tax services
* External financial services

---

# 3. Main Use Cases

## Account Management

* Register
* Login
* Logout
* Manage Profile

## Personal Expense Management

* Add Personal Expense
* Edit Personal Expense
* Delete Personal Expense
* View Personal Expenses
* Categorize Expenses

## Group Management

* Create Group
* Invite Member
* Accept Invitation
* View Members
* Leave Group

## Group Expense Management

* Add Group Expense
* Equal Split
* Custom Split
* Edit Group Expense
* Delete Group Expense
* View Group Expense History

## Balance Management

* Calculate Balance
* View Balance
* View Member Balances

## Settlement Management

* Record Settlement
* View Settlement History

## Dashboard and Reports

* View Personal Dashboard
* View Group Dashboard
* View Reports

## Administration

* Manage Users
* Manage Categories
* Handle Reports

---

# 4. Important Use Case Flows

## UC-01 — User Registration

### Actor

User

### Goal

Create an ExpenseHub account.

### Main Flow

1. User opens the registration page.
2. User enters required information.
3. User submits the registration form.
4. System validates the information.
5. System creates the account.
6. System displays a successful registration message.
7. User can log in.

### Possible Errors

* Email already exists.
* Invalid email.
* Weak password.
* Required information is missing.

---

## UC-02 — Add Personal Expense

### Actor

User

### Goal

Record a personal expense.

### Main Flow

1. User opens Personal Expenses.
2. User selects Add Expense.
3. User enters the amount.
4. User selects a category.
5. User selects the date.
6. User optionally enters a description.
7. User saves the expense.
8. System validates the data.
9. System stores the expense.
10. System updates relevant summaries.

---

## UC-03 — Create Group

### Actor

User

### Goal

Create a group for shared expenses.

### Main Flow

1. User selects Create Group.
2. User enters a group name.
3. User optionally enters a description.
4. User creates the group.
5. System creates the group.
6. User becomes the group owner/administrator.
7. The group dashboard is displayed.

---

## UC-04 — Add Group Expense

### Actor

Group Member

### Goal

Record a shared group expense.

### Main Flow

1. User opens a group.
2. User selects Add Expense.
3. User enters the expense amount.
4. User enters a description.
5. User selects a category.
6. User selects the person who paid.
7. User selects participating members.
8. User selects the split type.
9. System validates the split.
10. System stores the expense.
11. System calculates the resulting balances.
12. System updates the group dashboard.

### Split Types

* Equal split
* Custom split

### Validation Rule

The total of participant shares must equal the expense amount.

---

## UC-05 — View Balance

### Actor

Group Member

### Goal

Understand how much the member owes or should receive.

### Main Flow

1. User opens a group.
2. User opens the Balance section.
3. System retrieves relevant expenses and settlements.
4. System calculates member balances.
5. System displays the balances.

---

## UC-06 — Record Settlement

### Actor

User

### Goal

Record a payment between group members.

### Main Flow

1. User opens the group's settlement section.
2. User selects the member involved.
3. User enters the settlement amount.
4. User confirms the settlement.
5. System validates the settlement.
6. System records the settlement.
7. System recalculates the outstanding balance.

---

## UC-07 — View Personal Dashboard

### Actor

User

### Goal

Understand personal financial activity.

### Main Flow

1. User opens the dashboard.
2. System retrieves personal income and expense records.
3. System calculates totals.
4. System calculates category summaries.
5. System displays the results.

---

## UC-08 — Administrator Management

### Actor

Administrator

### Goal

Manage the ExpenseHub platform.

### Main Flow

1. Administrator logs into the admin area.
2. Administrator views system information.
3. Administrator manages users, categories, or reports.
4. System validates administrative permissions.
5. System performs the requested operation.
6. System records relevant administrative activity.

---

# 5. Main User Flow

A typical ExpenseHub journey:

1. User registers.
2. User logs in.
3. User reaches the dashboard.
4. User manages personal expenses or creates/joins a group.
5. User adds shared expenses.
6. User selects participants.
7. User chooses a split method.
8. System validates the expense.
9. System calculates balances.
10. Members record settlements.
11. User views the final expense summary.

---

# 6. Core Group Expense Scenario

Example:

Four friends create:

**Goa Trip — August 2026**

Members:

* Aarav
* Rohan
* Priya
* Neha

### Expense 1

Hotel — ₹8,000
Paid by Aarav
Equal split

### Expense 2

Petrol — ₹2,000
Paid by Rohan
Equal split

### Expense 3

Dinner — ₹1,600
Paid by Priya
Custom split

ExpenseHub calculates the resulting balances and allows members to record settlements.

This scenario will later be used as an end-to-end test case for the application.
