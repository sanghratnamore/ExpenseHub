# ExpenseHub — User Personas & User Stories

## 1. User Personas

### Persona 1 — College Student

**Name:** Aarav
**Age:** 21
**Occupation:** College Student

Aarav lives with three friends and regularly shares expenses such as rent, electricity, Wi-Fi, groceries, food, and transportation. He also frequently travels with friends.

**Problems:**

* Uses WhatsApp, notes, calculators, and payment history to track expenses.
* Finds it difficult to remember who paid for what.
* Manually calculates who owes whom.
* Sometimes forgets whether a payment has already been settled.

**Goal:**

To easily track personal and shared expenses without performing manual calculations.

---

### Persona 2 — Young Professional

**Name:** Priya
**Age:** 25
**Occupation:** Software Developer

Priya shares an apartment with two friends and wants to understand her personal spending while keeping shared household expenses organized.

**Problems:**

* Personal and shared expenses can become mixed together.
* Difficult to analyze monthly spending.
* Household expenses are paid by different people.

**Goal:**

To track personal spending while separately managing shared household expenses.

---

### Persona 3 — Trip Organizer

**Name:** Rohan
**Age:** 23
**Occupation:** Student

Rohan frequently organizes trips with friends and often pays for hotels, transportation, and activities on behalf of the group.

**Problems:**

* Multiple people contribute different amounts.
* Calculating final balances manually is difficult.
* Collecting money from multiple people can become confusing.

**Goal:**

To quickly determine how much each person owes or should receive after a group activity or trip.

---

### Persona 4 — Administrator

**Name:** ExpenseHub Administrator
**Role:** Platform Administrator

The administrator manages platform-level operations.

**Responsibilities:**

* Manage users.
* Manage expense categories.
* Review reported content.
* Manage inappropriate accounts.
* Monitor system activity.

---

# 2. User Stories

## Account Management

### US-01 — Registration

As a new user, I want to create an ExpenseHub account so that I can use the platform.

### US-02 — Login

As a registered user, I want to log in securely so that I can access my account.

### US-03 — Profile

As a user, I want to manage my profile so that my account information stays up to date.

---

## Personal Expense Management

### US-04 — Add Expense

As a user, I want to record a personal expense so that I can track my spending.

### US-05 — Categorize Expense

As a user, I want to categorize my expenses so that I can understand where my money goes.

### US-06 — Edit Expense

As a user, I want to edit an expense so that I can correct mistakes.

### US-07 — Delete Expense

As a user, I want to delete an incorrect expense so that my records remain accurate.

### US-08 — View Expense History

As a user, I want to view my expense history so that I can review my previous spending.

---

## Group Management

### US-09 — Create Group

As a user, I want to create a group so that I can manage shared expenses with other people.

### US-10 — Invite Members

As a group member with appropriate permission, I want to invite people to my group so that we can manage expenses together.

### US-11 — View Members

As a group member, I want to see the members of my group so that I know who participates in shared expenses.

### US-12 — Leave Group

As a group member, I want to leave a group when I no longer participate in its expenses.

---

## Group Expense Management

### US-13 — Add Group Expense

As a group member, I want to record a shared expense so that the group can track who paid and who participated.

### US-14 — Equal Split

As a group member, I want to split an expense equally among selected members so that everyone's share is calculated automatically.

### US-15 — Custom Split

As a group member, I want to assign different amounts to different members so that expenses can be split according to actual contributions.

### US-16 — View Group Expenses

As a group member, I want to view group expense history so that I can understand how money was spent.

---

## Balance Management

### US-17 — View Balance

As a group member, I want to see how much I owe or should receive so that I know my current financial position within the group.

### US-18 — View Member Balances

As a group member, I want to see relevant balances between members so that we can settle shared expenses.

---

## Settlement Management

### US-19 — Record Settlement

As a user, I want to record a payment I made to another member so that the group's outstanding balances are updated.

### US-20 — Settlement History

As a user, I want to view settlement history so that I can verify previous payments.

---

## Dashboard and Reports

### US-21 — Personal Dashboard

As a user, I want to see a summary of my income and expenses so that I can understand my financial activity.

### US-22 — Group Dashboard

As a group member, I want to see a summary of group expenses and balances so that I can understand the group's financial status.

---

## Administration

### US-23 — Manage Users

As an administrator, I want to manage user accounts so that I can maintain the platform.

### US-24 — Manage Categories

As an administrator, I want to manage expense categories so that the platform maintains appropriate categories.

### US-25 — Handle Reports

As an administrator, I want to review reported content or users so that inappropriate activity can be handled.

---

# 3. Acceptance Criteria Examples

## US-15 — Custom Split

The system should:

1. Allow the user to select group members.
2. Allow an amount to be assigned to each participant.
3. Calculate the total assigned amount.
4. Compare the assigned amount with the expense amount.
5. Reject the expense if the amounts do not match.
6. Save the expense if the amounts match.
7. Update group balances.

### Valid Example

Expense: ₹1,000

| Member    |      Share |
| --------- | ---------: |
| Aarav     |       ₹400 |
| Rohan     |       ₹300 |
| Priya     |       ₹200 |
| Neha      |       ₹100 |
| **Total** | **₹1,000** |

Result: Valid.

### Invalid Example

Expense: ₹1,000

| Member    |    Share |
| --------- | -------: |
| Aarav     |     ₹400 |
| Rohan     |     ₹300 |
| Priya     |     ₹200 |
| Neha      |      ₹50 |
| **Total** | **₹950** |

Result: Invalid because the assigned shares do not equal the expense amount.

---

# 4. Primary User Flow

A typical ExpenseHub user journey:

1. User registers.
2. User logs in.
3. User reaches the dashboard.
4. User records personal expenses or creates/joins a group.
5. User adds shared expenses.
6. User selects participants.
7. System calculates individual shares.
8. System calculates balances.
9. Members record settlements.
10. User views the final expense summary.
