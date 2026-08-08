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
