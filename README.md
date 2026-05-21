# Smart Credit Manager (SCM)

> **A dual-role Flutter application for small business owners to manage customer credit/debt accounts, and for customers to monitor their own balances — powered by Supabase.**

---

## Table of Contents

- [1. Project Title](#1-project-title)
- [2. Executive Summary](#2-executive-summary)
- [3. Product Objective](#3-product-objective)
- [4. Target Users / Personas](#4-target-users--personas)
- [5. Feature Overview](#5-feature-overview)
- [6. Screen and Page Documentation](#6-screen-and-page-documentation)
  - [6.1 App Entry / Root Screens](#61-app-entry--root-screens)
  - [6.2 Authentication Screens](#62-authentication-screens)
  - [6.3 Owner Screens](#63-owner-screens)
  - [6.4 Customer Screens](#64-customer-screens)
- [7. User Flow Documentation](#7-user-flow-documentation)
- [8. App Architecture](#8-app-architecture)
- [9. Folder Structure](#9-folder-structure)
- [10. State Management](#10-state-management)
- [11. Navigation and Routing](#11-navigation-and-routing)
- [12. Data Models](#12-data-models)
- [13. API / Backend Integration](#13-api--backend-integration)
  - [13.1 Supabase Database](#131-supabase-database)
  - [13.2 Row Level Security (RLS)](#132-row-level-security-rls)
  - [13.3 Supabase RPCs](#133-supabase-rpcs)
  - [13.4 Supabase Edge Functions](#134-supabase-edge-functions)
- [14. Local Storage / Persistence](#14-local-storage--persistence)
- [15. Authentication and Authorization](#15-authentication-and-authorization)
- [16. Forms and Validation](#16-forms-and-validation)
- [17. UI/UX and Theme System](#17-uiux-and-theme-system)
- [18. Assets and Media](#18-assets-and-media)
- [19. Platform Support](#19-platform-support)
- [20. Setup Instructions](#20-setup-instructions)
- [21. Environment Configuration](#21-environment-configuration)
- [22. Testing and Quality](#22-testing-and-quality)
- [23. Build and Deployment](#23-build-and-deployment)
- [24. Known Issues / Current Limitations](#24-known-issues--current-limitations)
- [25. Future Roadmap](#25-future-roadmap)
- [26. Developer Guidelines](#26-developer-guidelines)
- [27. Screenshot Placeholder Index](#27-screenshot-placeholder-index)
- [28. Glossary](#28-glossary)
- [29. Maintainer Notes](#29-maintainer-notes)
- [30. Summary of This Document](#30-summary-of-this-document)

---

## 1. Project Title

| Property | Value |
|---|---|
| **Package Name** | `credit_app` |
| **Display Name** | Smart Credit Manager |
| **Abbreviation** | SCM |
| **Tagline (from login UI)** | "SCM – Simple & Secure" |
| **Version** | `1.0.0+1` |
| **Source** | `pubspec.yaml` `name` field and `MaterialApp.router` `title` parameter |

---

## 2. Executive Summary

**Smart Credit Manager (SCM)** is a Flutter mobile application designed for **small business owners** (shop keepers, vendors, micro-retailers) who extend informal credit to their customers and need a reliable way to track debts, repayments, refunds, and outstanding balances.

The app operates on a **dual-role model**:

| Role | Description |
|---|---|
| **Owner** | The business operator who creates customers, issues credit, records payments/refunds, views reports, and manages complaints. |
| **Customer** | A buyer linked to an owner who can view their own outstanding balance, transaction history, receive notifications/reminders, and submit complaints. |

**Backend:** Supabase (PostgreSQL + Auth + Row Level Security + Edge Functions).  
**State Management:** Riverpod (`flutter_riverpod` v3).  
**Routing:** GoRouter (`go_router` v17).  
**Currency:** Ethiopian Birr (ETB) — hardcoded in `FinancialCalculator.formatCurrency()`.  
**Current Maturity:** Early production / advanced MVP. Core CRUD workflows are functional; analytics, reports, and notifications are implemented. No automated tests beyond the Flutter default stub. No CI/CD. No dark mode. Single locale (English).

---

## 3. Product Objective

### Business Objective

Replace paper-based credit ledgers used by small businesses in Ethiopia (and similar markets) with a digital, cloud-synced system that:

1. **Eliminates manual bookkeeping errors** — all credits, payments, and refunds are recorded with timestamps, amounts, and optional notes.
2. **Provides real-time balance visibility** — both the owner and the customer can see the current outstanding balance at any time.
3. **Enforces credit discipline** — configurable per-customer credit limits with overrun warnings.
4. **Automates payment reminders** — the app generates in-app notifications when payments are due tomorrow, due today, or overdue.
5. **Supports dispute resolution** — customers can submit complaints/requests that owners can track through a pending → in-progress → completed workflow.
6. **Gives business intelligence** — the owner gets a dashboard with total outstanding, total debt issued, total repayments, overdue summaries, aging analysis, and collection-rate metrics.

### User Value

| User | Value |
|---|---|
| **Owner** | Single source of truth for all credit accounts. Reduces disputes. Identifies risky debtors. Measures collection performance. |
| **Customer** | Transparency into their own balance. Proof of payments made. Ability to flag issues to the shop owner. |

### What Success Looks Like

- An owner can onboard a customer, issue credit with due dates, record payments, and get an accurate dashboard — all within the app.
- A customer can log in with owner-provided credentials, see exactly how much they owe, review all past transactions, and submit a complaint if something looks wrong.

---

## 4. Target Users / Personas

### 4.1 Owner (Shop Keeper / Vendor)

| Property | Detail |
|---|---|
| **Goal** | Track credit given to customers; collect payments; monitor overdue accounts; generate reports |
| **Available Actions** | Sign up / Sign in, Create customers, Set credit limits, Issue credits with due dates, Record payments/refunds, View dashboard stats, View all transactions, View reports & aging analysis, View & manage complaints, Create login credentials for customers, Delete customers, Delete own account |
| **Limitations** | Cannot access customer-side routes. Cannot see other owners' data (RLS enforced). No export/PDF. No push notifications. |
| **Related Screens** | Role Selection, Login, Owner Dashboard, Customer List, Customer Ledger, All Transactions, Reports & Analytics, Complaints |
| **Status** | **Implemented** |

### 4.2 Customer (Buyer / Debtor)

| Property | Detail |
|---|---|
| **Goal** | View their outstanding balance, review transactions, receive reminders, raise complaints |
| **Available Actions** | Sign in (with owner-provided credentials), View balance & payment status, View transaction history, View notifications/reminders, Submit complaints/requests, Log out |
| **Limitations** | Cannot sign up independently — account created by owner. Cannot modify transactions. Cannot see other customers' data. |
| **Related Screens** | Role Selection, Login, Customer Dashboard, Transaction History |
| **Status** | **Implemented** |

### 4.3 Admin / Super Admin

| Property | Detail |
|---|---|
| **Status** | **Not implemented** — no admin panel or super-admin role exists in the codebase |

---

## 5. Feature Overview

| # | Feature | Description | Status | Related Screens | Related Files / Modules | Notes |
|---|---|---|---|---|---|---|
| 1 | **Role Selection** | User picks "Owner" or "Customer" before logging in | **Implemented** | Role Selection Screen | `role_selection_screen.dart`, `auth_controller.dart` | Sets `selectedRoleProvider` |
| 2 | **Owner Sign Up** | Owner creates a new account with email + password | **Implemented** | Login Screen | `login_screen.dart`, `auth_controller.dart`, `supabase_service.dart` | Signup toggle only shown for Owner role |
| 3 | **Owner Sign In** | Owner logs in with email + password | **Implemented** | Login Screen | `login_screen.dart`, `auth_controller.dart` | Role enforcement: rejects customer accounts |
| 4 | **Customer Sign In** | Customer logs in with credentials provided by owner | **Implemented** | Login Screen | `login_screen.dart`, `auth_controller.dart` | Signup is not available for customers |
| 5 | **Role Enforcement** | Prevents an owner from accessing customer routes and vice versa | **Implemented** | Router redirect | `routes.dart` | GoRouter redirect logic checks `userMetadata['role']` |
| 6 | **Owner Dashboard** | Financial summary: Total Outstanding, Debt Given, Repayments, Overdue Summary, Quick Actions, Recent Activity | **Implemented** | Owner Dashboard | `owner_dashboard_screen.dart` | Uses `dashboardStatsProvider` |
| 7 | **Customer Management** | Add, view, delete customers with name, phone, credit limit | **Implemented** | Customer List | `customer_list_screen.dart`, `supabase_service.dart` | FAB to add; popup menu for delete/set limit |
| 8 | **Customer Credential Creation** | Owner creates email/password login for a customer | **Implemented** | Customer List (dialog) | `customer_list_screen.dart`, `supabase_service.dart` | Uses temporary `SupabaseClient` with `EmptyLocalStorage` to avoid overwriting owner session |
| 9 | **Credit Issuance** | Owner issues a credit (debt) to a customer with title, amount, due date, note | **Implemented** | Customer Ledger | `customer_ledger_screen.dart` | Credit limit warning dialog if exceeded |
| 10 | **Payment Recording** | Owner records a repayment from customer | **Implemented** | Customer Ledger, All Transactions | `customer_ledger_screen.dart`, `transaction_screen.dart` | Validates payment does not exceed outstanding balance |
| 11 | **Refund / Discount** | Owner issues a refund or discount that reduces balance | **Implemented** | Customer Ledger, All Transactions | `customer_ledger_screen.dart`, `transaction_screen.dart` | Type `refund` in transaction model |
| 12 | **Transaction Edit** | Owner edits existing transaction (amount, title, note, due date) | **Implemented** | Customer Ledger (tap on transaction) | `customer_ledger_screen.dart` | Reuses the add-transaction dialog |
| 13 | **Transaction Delete** | Owner deletes a transaction with confirmation | **Implemented** | Customer Ledger (popup menu) | `customer_ledger_screen.dart` | Confirmation dialog required |
| 14 | **Customer Ledger** | Per-customer detail view with balance summary, payment status badge, credit limit info, debt history | **Implemented** | Customer Ledger | `customer_ledger_screen.dart` | SliverAppBar with customer avatar, quick action buttons |
| 15 | **Credit Limit Enforcement** | Warning when a new credit would exceed the customer's limit; owner can override | **Implemented** | Customer Ledger (dialog) | `customer_ledger_screen.dart` | Soft enforcement (warning, not block) |
| 16 | **All Transactions View** | Flat list of all transactions across all customers | **Implemented** | Transaction Screen | `transaction_screen.dart` | Owner can add new transactions from here too |
| 17 | **Reports & Analytics** | Business Overview (4 stat cards), Overdue Status, Aging Analysis (Current / 1-7d / 8-30d / 30+d), Collection Rate with progress bar | **Implemented** | Reports Screen | `reports_screen.dart`, `financial_calculator.dart` | Reads from `dashboardStatsProvider` |
| 18 | **Aging Analysis** | Categorizes outstanding debt by overdue period per customer | **Implemented** | Reports Screen | `financial_calculator.dart` | Four buckets: Current, 1-7 Days, 8-30 Days, 30+ Days |
| 19 | **Collection Rate** | Visual progress bar showing % of debt collected | **Implemented** | Reports Screen | `reports_screen.dart` | Color changes: orange < 70%, green ≥ 70% |
| 20 | **Complaint Management (Owner)** | Owner views customer complaints with status badges; can progress them through pending → in_progress → completed | **Implemented** | Complaints Screen | `complaints_screen.dart`, `supabase_service.dart` | Three-state workflow |
| 21 | **Complaint Submission (Customer)** | Customer submits a complaint/request to the owner | **Implemented** | Customer Dashboard (dialog) | `customer_dashboard_screen.dart`, `supabase_service.dart` | Free-text message field |
| 22 | **Customer Balance View** | Customer sees outstanding balance, payment status, credit limit, available credit | **Implemented** | Customer Dashboard | `customer_dashboard_screen.dart` | Uses `customerDashboardProvider` |
| 23 | **Customer Transaction History** | Customer views their chronological transaction list | **Implemented** | Customer History Screen | `customer_history_screen.dart` | Read-only; pull-to-refresh |
| 24 | **In-App Notifications** | Reminders for due-tomorrow, due-today, and overdue payments; displayed in bottom sheet with unread badge | **Implemented** | Customer Dashboard (bottom sheet) | `reminder_service.dart`, `customer_dashboard_screen.dart` | Generated server-side via `ReminderService`; de-duplicated within 24 hours |
| 25 | **Payment Status Calculation** | Per-customer and per-transaction status: Pending / Partial / Paid / Overdue | **Implemented** | Customer Ledger, Customer Dashboard | `financial_calculator.dart` | FIFO payment application logic |
| 26 | **Account Deletion (Owner)** | Owner can permanently delete their account and cascade-delete all customers, transactions, and auth accounts | **Implemented** | Owner Dashboard (popup menu) | `owner_dashboard_screen.dart`, `supabase_service.dart`, `supabase_schema.sql` | Calls `delete_user_account()` RPC |
| 27 | **Account Deletion (Customer)** | Owner can delete individual customer and their auth account | **Implemented** | Customer List (popup menu) | `customer_list_screen.dart`, `supabase_service.dart` | Calls `delete_customer_auth_account()` RPC |
| 28 | **Logout** | Both roles can log out | **Implemented** | Owner Dashboard, Customer Dashboard | `auth_controller.dart` | Clears Supabase session |
| 29 | **Dark Mode** | Dark color theme | **Not implemented** | — | — | Only `lightTheme` defined in `AppTheme` |
| 30 | **Localization / i18n** | Multi-language support | **Not implemented** | — | — | All strings are hardcoded in English |
| 31 | **Push Notifications** | Device push notifications via FCM / APNs | **Not implemented** | — | — | Only in-app DB notifications exist |
| 32 | **Offline Support** | Work offline with local cache | **Not implemented** | — | — | All data fetched on demand from Supabase |
| 33 | **Search / Filter** | Search customers or transactions | **Not implemented** | — | — | Lists show all records |
| 34 | **Data Export** | PDF / CSV export of ledgers or reports | **Not implemented** | — | — | — |
| 35 | **Password Reset** | Forgot password / reset flow | **Not implemented** | — | — | No UI or service method exists |

---

## 6. Screen and Page Documentation

### 6.1 App Entry / Root Screens

#### Splash / Loading Screen (`/`)

| Property | Detail |
|---|---|
| **Route / Entry Point** | `/` (initial route) |
| **Status** | **Implemented** (minimal) |
| **Purpose** | Display a `CircularProgressIndicator` while the auth state is resolved |
| **Who uses it** | Both roles — shown briefly on app launch |
| **Main UI elements** | Centered `CircularProgressIndicator` inside a `Scaffold` |
| **User actions** | None — passive loading screen |
| **Navigation behavior** | GoRouter redirect immediately navigates to `/role` (unauthenticated) or `/owner` / `/customer` (authenticated) |
| **Related files** | `routes.dart` (inline `GoRoute` builder) |
| **Known limitations** | No branding, no logo, no app name displayed. Purely functional. |

![Splash Screen Screenshot](docs/images/splash-screen.png)
> Screenshot placeholder: Add screenshot for this screen here.

---

### 6.2 Authentication Screens

#### Role Selection Screen (`/role`)

| Property | Detail |
|---|---|
| **Route / Entry Point** | `/role` |
| **Status** | **Implemented** |
| **Purpose** | Let the user choose whether they are an Owner or a Customer before proceeding to login |
| **Who uses it** | Both roles |
| **Main UI elements** | `Icons.storefront` icon (80px), "Welcome to Smart Credit Manager" heading, "Choose your role to continue" subtitle, "Continue as Owner" primary button, "Continue as Customer" secondary button |
| **User actions** | Tap one of the two buttons |
| **Navigation behavior** | Sets `selectedRoleProvider` to `'owner'` or `'customer'`, then pushes `/login` |
| **Related files** | `lib/features/auth/screens/role_selection_screen.dart` |
| **Related providers** | `selectedRoleProvider` (`SelectedRoleNotifier`) |
| **Validation/error/loading states** | None — no validation needed |
| **Known limitations** | No "remember my role" persistence. User must re-select on every app launch if not logged in. |

![Role Selection Screenshot](docs/images/role-selection.png)
> Screenshot placeholder: Add screenshot for this screen here.

---

#### Login Screen (`/login`)

| Property | Detail |
|---|---|
| **Route / Entry Point** | `/login` |
| **Status** | **Implemented** |
| **Purpose** | Authenticate the user (email + password). Owners can toggle to Sign Up mode. Customers can only log in. |
| **Who uses it** | Both roles |
| **Main UI elements** | AppBar with role-specific title ("Owner Login" / "Customer Login"), "Smart Credit Manager" heading, "SCM – Simple & Secure" subtitle, Email `CustomTextField`, Password `CustomTextField`, Login / Sign Up `CustomButton`, Toggle text (owners only), Info text for customers ("Your login credentials are provided by your shop owner.") |
| **User actions** | Enter email + password → Submit. Owners can toggle between Login / Sign Up. |
| **Navigation behavior** | On success, GoRouter redirect navigates to `/owner` or `/customer` based on role. Back button pops to `/role`. |
| **Related files** | `lib/features/auth/screens/login_screen.dart` |
| **Related providers/controllers** | `authControllerProvider`, `selectedRoleProvider` |
| **Validation rules** | Email: required (not empty). Password: required, minimum 6 characters. |
| **Error handling** | Auth errors shown via `SnackBar`. Role mismatch errors (e.g., customer trying to log in as owner) produce a descriptive error message and sign the user out. |
| **Known limitations** | No email format validation (only checks non-empty). No "Forgot Password" link. No loading state on the toggle button. |

![Login Screen Screenshot](docs/images/login-screen.png)
> Screenshot placeholder: Add screenshot for this screen here.

---

### 6.3 Owner Screens

#### Owner Dashboard (`/owner`)

| Property | Detail |
|---|---|
| **Route / Entry Point** | `/owner` |
| **Status** | **Implemented** |
| **Purpose** | Central hub for the owner. Displays financial KPIs, overdue alerts, quick-action navigation, and recent transactions. |
| **Who uses it** | Owner only |
| **Main UI elements** | AppBar with "SCM Dashboard" title and popup menu (Logout, Delete Account). **Total Outstanding** card (full width, dark green). **Debt Given** + **Repayments** row (two mini cards). **Overdue Summary** card (red, conditional — hidden if no overdue accounts) with Customers / Balance / Invoices stats. **Quick Actions** grid: Customers, Transactions, Reports, Complaints. **Recent Activity** section: last 5 transactions with "View All" link. |
| **User actions** | Navigate to Customers, Transactions, Reports, Complaints. Logout. Delete account. |
| **Navigation behavior** | Quick action cards push to `/owner/customers`, `/owner/transactions`, `/owner/reports`, `/owner/complaints`. "View All" pushes to `/owner/transactions`. |
| **Related files** | `lib/features/owner/dashboard/owner_dashboard_screen.dart` |
| **Related providers** | `dashboardStatsProvider` (computes all stats from Supabase data), `authControllerProvider` |
| **Validation/error/loading states** | Loading spinner while stats load. Error card on failure. Delete account has a confirmation dialog. |
| **Known limitations** | Dashboard refetches all data on every visit (no caching). No date filtering on the dashboard. No sparklines or charts (text/numbers only). |

![Owner Dashboard Screenshot](docs/images/owner-dashboard.png)
> Screenshot placeholder: Add screenshot for this screen here.

---

#### Customer List Screen (`/owner/customers`)

| Property | Detail |
|---|---|
| **Route / Entry Point** | `/owner/customers` |
| **Status** | **Implemented** |
| **Purpose** | View all customers belonging to the owner. Add new customers. Manage individual customers. |
| **Who uses it** | Owner only |
| **Main UI elements** | AppBar "Customers". `ListView` of customer cards with avatar (first letter), name, phone. Popup menu per customer: Create Login (if no auth_user_id), Set Credit Limit, Delete. FAB to add a new customer. |
| **User actions** | Tap a customer → navigate to ledger. Use popup menu for actions. Tap FAB → add customer dialog (Name, Phone, Credit Limit in ETB). After adding, prompted to create login credentials. |
| **Navigation behavior** | Tapping a customer pushes `/owner/customers/:id` with the `CustomerModel` passed as `extra`. |
| **Related files** | `lib/features/owner/customers/customer_list_screen.dart` |
| **Related providers** | `customersProvider` |
| **Validation/error/loading states** | Empty state: "No customers found." Loading spinner. Error text. Add/delete operations show SnackBar feedback. |
| **Known limitations** | No search/filter. No pagination. Customer list fetches all active customers. No sort options. Phone number has no format validation. |

![Customer List Screenshot](docs/images/customer-list.png)
> Screenshot placeholder: Add screenshot for this screen here.

---

#### Customer Ledger Screen (`/owner/customers/:id`)

| Property | Detail |
|---|---|
| **Route / Entry Point** | `/owner/customers/:id` |
| **Status** | **Implemented** |
| **Purpose** | Detailed per-customer view: balance summary, credit limit info, quick action buttons, full transaction history. The most complex screen in the app. |
| **Who uses it** | Owner only |
| **Main UI elements** | `SliverAppBar` (expandedHeight: 200) with gradient, customer avatar, name, phone badge. **Status badge** (Pending / Partial / Paid / Overdue). **Summary card** with Debt / Repayments / Outstanding. **Credit Limit card** (conditional — shown only if limit > 0) with Credit Limit / Available Credit. **Quick action buttons**: "Add Debt" (red), "Repayment" (green), "Add Refund / Discount" (blue). **Debt History** section header. **Transaction list** (`SliverList`): each transaction shows type icon, title, status badge, amount, note (if any), date, due date. Each transaction has edit/delete popup menu. |
| **User actions** | Add credit/payment/refund via dialog. Edit transaction (tap card). Delete transaction (popup menu). Pull-to-refresh. |
| **Navigation behavior** | Back button returns to Customer List. No further navigation from this screen. |
| **Related files** | `lib/features/owner/customers/customer_ledger_screen.dart` |
| **Related providers** | `customerLedgerProvider` (family, keyed by customerId) |
| **Validation rules** | Amount must be > 0. Payment/refund cannot exceed outstanding balance. Credit exceeding credit limit triggers a warning dialog (soft override). |
| **Error handling** | SnackBar on success/failure. Loading spinners in dialog buttons. |
| **Known limitations** | Customer model passed via `extra` — if deep-linked directly, `state.extra` would be null and crash. No pagination on transaction list. |

![Customer Ledger Screenshot](docs/images/customer-ledger.png)
> Screenshot placeholder: Add screenshot for this screen here.

---

#### All Transactions Screen (`/owner/transactions`)

| Property | Detail |
|---|---|
| **Route / Entry Point** | `/owner/transactions` |
| **Status** | **Implemented** |
| **Purpose** | Flat list of every transaction across all customers, sorted by date descending. Quick-add a transaction from here. |
| **Who uses it** | Owner only |
| **Main UI elements** | AppBar "All Transactions". `ListView` with transaction tiles: type icon (colored), title, date, amount. FAB to add a transaction (with customer dropdown, type dropdown, title, amount, note). |
| **User actions** | View all transactions. Add new transaction via FAB dialog. |
| **Navigation behavior** | No drill-down from individual transactions. Back button returns to dashboard. |
| **Related files** | `lib/features/owner/transactions/transaction_screen.dart` |
| **Related providers** | `allTransactionsProvider` |
| **Validation rules** | Amount must be > 0. Payment/refund cannot exceed the selected customer's outstanding balance. |
| **Known limitations** | No edit/delete from this screen (only from Customer Ledger). No search, filter, or date range. No customer name shown on each transaction (only title). |

![All Transactions Screenshot](docs/images/all-transactions.png)
> Screenshot placeholder: Add screenshot for this screen here.

---

#### Reports & Analytics Screen (`/owner/reports`)

| Property | Detail |
|---|---|
| **Route / Entry Point** | `/owner/reports` |
| **Status** | **Implemented** |
| **Purpose** | Business intelligence dashboard with KPIs, overdue metrics, aging analysis, and collection progress. |
| **Who uses it** | Owner only |
| **Main UI elements** | **Business Overview** grid (2×2): Total Customers, Debt Issued, Repayments, Outstanding. **Overdue Status** card: Overdue Customers count, Overdue Amount. **Aging Analysis** cards: Current, 1-7 Days, 8-30 Days, 30+ Days — each showing customer count and total balance. **Collection Rate**: progress bar with percentage and summary text. |
| **User actions** | View-only. No interactions beyond scrolling. |
| **Related files** | `lib/features/owner/reports/reports_screen.dart`, `lib/shared/utils/financial_calculator.dart` |
| **Related providers** | `dashboardStatsProvider` (shared with Owner Dashboard) |
| **Known limitations** | No date range filtering. No drill-down from aging categories to specific customers. No chart visualizations (all text/number-based). No export. |

![Reports Screenshot](docs/images/reports-analytics.png)
> Screenshot placeholder: Add screenshot for this screen here.

---

#### Complaints Screen (`/owner/complaints`)

| Property | Detail |
|---|---|
| **Route / Entry Point** | `/owner/complaints` |
| **Status** | **Implemented** |
| **Purpose** | View complaints submitted by customers. Progress them through a three-state workflow. |
| **Who uses it** | Owner only |
| **Main UI elements** | AppBar "Customer Complaints". `ListView` of complaint cards: message text, status chip (Pending / In Progress / Completed), submission date, action button ("Start Working" for pending, "Mark Completed" for in_progress, "Issue resolved" text for completed). |
| **User actions** | Transition complaint status: pending → in_progress → completed. |
| **Related files** | `lib/features/owner/complaints/complaints_screen.dart` |
| **Related providers** | `complaintsProvider` |
| **Known limitations** | No reply/messaging to the customer. No complaint deletion. No customer name shown (only customer_id in data). No sorting/filtering by status. |

![Complaints Screenshot](docs/images/complaints.png)
> Screenshot placeholder: Add screenshot for this screen here.

---

### 6.4 Customer Screens

#### Customer Dashboard (`/customer`)

| Property | Detail |
|---|---|
| **Route / Entry Point** | `/customer` |
| **Status** | **Implemented** |
| **Purpose** | Customer's home screen showing their outstanding balance, payment status, credit limit info, and menu to access transaction history, complaint submission, and notifications. |
| **Who uses it** | Customer only |
| **Main UI elements** | AppBar "SCM Customer" with notification bell (unread badge) and logout icon. **Balance card** (dark green): "My Outstanding Balance" with formatted amount, status badge (Pending/Partial/Paid/Overdue), credit limit and available credit (if limit > 0). **Menu section**: "Transaction History" list tile, "Submit Complaint / Request" list tile. **Notifications bottom sheet** (via bell icon): DraggableScrollableSheet with notification list — each showing icon, title, message, date; tap to mark as read. |
| **User actions** | View balance. Open notification bottom sheet. Mark notifications as read. Navigate to transaction history. Submit a complaint. Logout. |
| **Related files** | `lib/features/customer/dashboard/customer_dashboard_screen.dart` |
| **Related providers** | `customerDashboardProvider`, `notificationsProvider`, `authControllerProvider` |
| **Known limitations** | No pull-to-refresh on the main dashboard (only on history screen). No profile editing. Customer cannot delete their own account. |

![Customer Dashboard Screenshot](docs/images/customer-dashboard.png)
> Screenshot placeholder: Add screenshot for this screen here.

---

#### Customer Transaction History (`/customer/history`)

| Property | Detail |
|---|---|
| **Route / Entry Point** | `/customer/history` |
| **Status** | **Implemented** |
| **Purpose** | Read-only chronological list of all transactions related to the customer. |
| **Who uses it** | Customer only |
| **Main UI elements** | AppBar "Transaction History". `ListView` of transaction cards: type icon, title, note (if any), date, "OVERDUE" label (if credit with past due date), amount (colored by type). Pull-to-refresh. |
| **User actions** | Scroll and review. Pull to refresh. |
| **Related files** | `lib/features/customer/history/customer_history_screen.dart` |
| **Related providers** | `customerDashboardProvider` (reuses data already fetched) |
| **Known limitations** | No pagination. No search/filter. No export. |

![Customer History Screenshot](docs/images/customer-history.png)
> Screenshot placeholder: Add screenshot for this screen here.

---

## 7. User Flow Documentation

### Flow 1: Owner Registration and First-Time Setup

| Property | Detail |
|---|---|
| **Starting Point** | App launch (splash → `/role`) |
| **Status** | **Implemented** |

1. User opens the app → splash screen briefly shown.
2. GoRouter redirects unauthenticated user to `/role` (Role Selection).
3. User taps **"Continue as Owner"** → `selectedRoleProvider` set to `'owner'`.
4. User is navigated to `/login` → Login Screen shows "Owner Login".
5. User taps **"Don't have an account? Sign Up"** toggle → form switches to Sign Up mode.
6. User enters email + password → taps **"Sign Up"**.
7. `AuthController.signUp()` calls `SupabaseService.signUp()` with `{role: 'owner'}` metadata.
8. On success, `authControllerProvider` emits the new user.
9. GoRouter redirect detects authenticated user with role `owner` → navigates to `/owner` (Owner Dashboard).
10. On failure, `SnackBar` shows error message.

**Files involved:** `role_selection_screen.dart`, `login_screen.dart`, `auth_controller.dart`, `supabase_service.dart`, `routes.dart`

---

### Flow 2: Owner Adds a Customer and Issues Credit

| Property | Detail |
|---|---|
| **Starting Point** | Owner Dashboard → Customers |
| **Status** | **Implemented** |

1. Owner taps **"Customers"** quick action → navigates to `/owner/customers`.
2. Owner taps **FAB (+)** → Add Customer dialog appears.
3. Owner enters Name, Phone, Credit Limit (ETB) → taps **"Add"**.
4. `SupabaseService.addCustomer()` inserts row into `customers` table.
5. On success, dialog closes. **Create Login Credentials** dialog appears automatically.
6. Owner enters email + password for the customer → taps **"Create"**.
7. `SupabaseService.createCustomerCredentials()` creates a temporary `SupabaseClient`, signs up the customer via GoTrue Auth API with `{role: 'customer'}` metadata, then links the `auth_user_id` to the customer record.
8. Owner taps on the new customer → navigates to Customer Ledger.
9. Owner taps **"Add Debt"** → transaction dialog appears with type "Credit (Debt)".
10. Owner enters Title (e.g., "Rice and Oil"), Amount, optional Due Date, optional Note → taps **"Add"**.
11. If amount + existing balance > credit limit (and limit > 0), a warning dialog appears: "Credit Limit Exceeded — Do you want to proceed anyway?"
12. `SupabaseService.addTransaction()` inserts row into `transactions` table.
13. Ledger, dashboard stats, and transaction providers are invalidated → UI refreshes.

**Files involved:** `customer_list_screen.dart`, `customer_ledger_screen.dart`, `supabase_service.dart`

---

### Flow 3: Owner Records a Payment

| Property | Detail |
|---|---|
| **Starting Point** | Customer Ledger |
| **Status** | **Implemented** |

1. Owner opens Customer Ledger for a specific customer.
2. Owner taps **"Repayment"** button (green).
3. Transaction dialog appears with type pre-set to "Repayment".
4. Owner enters amount and optional note → taps **"Add"**.
5. Validation: if payment amount > outstanding balance, a SnackBar error is shown: "Payment exceeds remaining outstanding balance."
6. On success, transaction is saved, providers are invalidated, UI refreshes with updated balance and payment status.

**Files involved:** `customer_ledger_screen.dart`, `supabase_service.dart`, `financial_calculator.dart`

---

### Flow 4: Customer Logs In and Views Balance

| Property | Detail |
|---|---|
| **Starting Point** | App launch |
| **Status** | **Implemented** |

1. Customer opens app → redirected to `/role`.
2. Customer taps **"Continue as Customer"** → `selectedRoleProvider` set to `'customer'`.
3. Customer enters email + password (provided by owner) → taps **"Login"**.
4. `AuthController.signIn()` verifies that `userMetadata['role']` matches `'customer'`. If mismatch (e.g., owner account), signs out and shows error.
5. On success, GoRouter redirect navigates to `/customer` (Customer Dashboard).
6. `customerDashboardProvider` fetches customer profile (via `auth_user_id`) and transactions.
7. Dashboard shows outstanding balance, payment status, credit limit info.

**Files involved:** `role_selection_screen.dart`, `login_screen.dart`, `auth_controller.dart`, `customer_dashboard_screen.dart`, `supabase_service.dart`

---

### Flow 5: Customer Submits a Complaint

| Property | Detail |
|---|---|
| **Starting Point** | Customer Dashboard |
| **Status** | **Implemented** |

1. Customer taps **"Submit Complaint / Request"** menu item.
2. Dialog appears with a multi-line text field for the message.
3. Customer enters message → taps **"Submit"**.
4. `SupabaseService.submitComplaint()` inserts row into `complaints` table with `customer_id`, `owner_id`, `message`, and status `'pending'`.
5. Success SnackBar: "Message submitted successfully."
6. Owner later sees it on their Complaints screen and can progress through pending → in_progress → completed.

**Files involved:** `customer_dashboard_screen.dart`, `complaints_screen.dart`, `supabase_service.dart`

---

### Flow 6: Automated Payment Reminders

| Property | Detail |
|---|---|
| **Starting Point** | Owner login triggers `ReminderService` |
| **Status** | **Implemented** |

1. When `authControllerProvider` emits a non-null user, the router notifier calls `ReminderService.checkAndGenerateReminders()`.
2. The service iterates over all the owner's customers and their credit transactions.
3. For each unpaid credit with a `dueDate`:
   - **1 day before due:** creates "Payment Due Tomorrow" notification (type `reminder`).
   - **Day of due:** creates "Payment Due Today" notification (type `reminder`).
   - **Past due (overdue status):** creates "Payment Overdue" notification (type `alert`).
4. De-duplication: if a notification with the same `transactionId` and `title` was already sent within the last 24 hours, it is skipped.
5. Notifications are visible to the customer in their Notifications bottom sheet.

**Files involved:** `lib/core/services/reminder_service.dart`, `routes.dart` (trigger point), `customer_dashboard_screen.dart` (display)

---

### Flow 7: Owner Deletes Their Account

| Property | Detail |
|---|---|
| **Starting Point** | Owner Dashboard → popup menu → "Delete Account" |
| **Status** | **Implemented** |

1. Owner taps the three-dot menu → selects **"Delete Account"**.
2. Confirmation dialog: "Are you absolutely sure you want to permanently delete your account? This will delete all your customers, transactions, reports, and all related data. This action CANNOT be undone."
3. If confirmed, `SupabaseService.deleteOwnerAccount()` calls the `delete_user_account()` RPC.
4. The RPC (SECURITY DEFINER) performs:
   - Deletes every customer's `auth.users` row (removes their login credentials/sessions).
   - Deletes the owner's `auth.users` row (cascades to all `customers`, `transactions`, `complaints`, `notifications` via FK `ON DELETE CASCADE`).
5. Client calls `signOut()` → auth state changes → GoRouter redirects to `/role`.

**Files involved:** `owner_dashboard_screen.dart`, `supabase_service.dart`, `supabase_schema.sql`, `supabase_cascade_auth_fix.sql`

---

## 8. App Architecture

### Overview

The application follows a **feature-first architecture** with shared layers for models, services, utilities, and theme. It does not strictly follow Clean Architecture or any named pattern, but the separation is practical and consistent.

```
┌─────────────────────────────────────────────────────────┐
│                      main.dart                          │
│        (WidgetsBinding, dotenv, Supabase init,          │
│         ProviderScope → MyApp)                          │
└──────────────────────┬──────────────────────────────────┘
                       │
              ┌────────▼────────┐
              │ MyApp (Consumer)│
              │ MaterialApp     │
              │ .router         │
              └────────┬────────┘
                       │
          ┌────────────▼────────────┐
          │     GoRouter            │
          │ (routerProvider)        │
          │ + RouterNotifier        │
          │   (auth-aware redirect) │
          └────────────┬────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
   ┌────▼────┐   ┌─────▼─────┐  ┌────▼──────┐
   │  Auth   │   │  Owner    │  │ Customer  │
   │ Feature │   │  Feature  │  │  Feature  │
   │         │   │           │  │           │
   │ screens │   │ dashboard │  │ dashboard │
   │ control │   │ customers │  │ history   │
   │         │   │ ledger    │  │           │
   │         │   │ transact. │  │           │
   │         │   │ reports   │  │           │
   │         │   │ complaints│  │           │
   └────┬────┘   └─────┬─────┘  └────┬──────┘
        │              │              │
        └──────────────┼──────────────┘
                       │
          ┌────────────▼────────────┐
          │   Shared Layers         │
          │                         │
          │ • data/models/          │
          │ • data/services/        │
          │   (SupabaseService)     │
          │ • shared/utils/         │
          │   (FinancialCalculator) │
          │ • shared/widgets/       │
          │ • core/theme/           │
          │ • core/constants/       │
          │ • core/services/        │
          │   (ReminderService)     │
          └─────────────────────────┘
```

### Key Architectural Decisions

| Decision | Detail |
|---|---|
| **Entry point** | `main.dart`: loads `.env`, initializes Supabase, wraps app in `ProviderScope` |
| **App root** | `MyApp` is a `ConsumerWidget` using `MaterialApp.router` with `routerConfig` from `routerProvider` |
| **Routing** | GoRouter with `RouterNotifier` that listens to `authControllerProvider` and redirects based on auth state and role |
| **State management** | Riverpod (v3): `AsyncNotifier` for auth, `FutureProvider.autoDispose` for data fetching, `Provider` for services |
| **Service layer** | Single `SupabaseService` class wrapping all Supabase client operations (auth, CRUD for customers/transactions/complaints/notifications) |
| **Utility layer** | `FinancialCalculator` — pure static methods for balance calculation, status determination, currency formatting, aging analysis |
| **Theme** | `AppTheme.lightTheme` using `AppColors` and Google Fonts (Inter) |

---

## 9. Folder Structure

```
smart_credit_manager_app/
├── lib/
│   ├── main.dart                           # App entry point
│   ├── core/
│   │   ├── constants/
│   │   │   └── env_constants.dart          # Supabase URL & Anon Key from .env
│   │   ├── routes.dart                     # GoRouter setup, RouterNotifier, redirect logic
│   │   ├── services/
│   │   │   └── reminder_service.dart       # Automated payment reminder generation
│   │   └── theme/
│   │       ├── app_colors.dart             # Color palette constants
│   │       └── app_theme.dart              # ThemeData configuration
│   ├── data/
│   │   ├── models/
│   │   │   ├── customer_model.dart         # CustomerModel (fromJson/toJson)
│   │   │   ├── transaction_model.dart      # TransactionModel (fromJson/toJson)
│   │   │   ├── complaint_model.dart        # ComplaintModel (fromJson/toJson)
│   │   │   ├── notification_model.dart     # NotificationModel (fromJson/toJson)
│   │   │   └── user_model.dart             # UserModel (id, email, role)
│   │   └── services/
│   │       └── supabase_service.dart       # All Supabase API calls (auth + CRUD)
│   ├── features/
│   │   ├── auth/
│   │   │   ├── controller/
│   │   │   │   └── auth_controller.dart    # AuthController (AsyncNotifier), SelectedRoleNotifier
│   │   │   └── screens/
│   │   │       ├── role_selection_screen.dart
│   │   │       └── login_screen.dart
│   │   ├── owner/
│   │   │   ├── dashboard/
│   │   │   │   └── owner_dashboard_screen.dart  # Dashboard + dashboardStatsProvider
│   │   │   ├── customers/
│   │   │   │   ├── customer_list_screen.dart     # Customer CRUD + customersProvider
│   │   │   │   └── customer_ledger_screen.dart   # Per-customer ledger (1087 lines)
│   │   │   ├── transactions/
│   │   │   │   └── transaction_screen.dart       # All transactions + allTransactionsProvider
│   │   │   ├── reports/
│   │   │   │   └── reports_screen.dart           # Reports & Analytics
│   │   │   └── complaints/
│   │   │       └── complaints_screen.dart        # Complaint management
│   │   └── customer/
│   │       ├── dashboard/
│   │       │   └── customer_dashboard_screen.dart  # Customer home + notifications
│   │       └── history/
│   │           └── customer_history_screen.dart     # Read-only transaction history
│   ├── shared/
│   │   ├── utils/
│   │   │   └── financial_calculator.dart   # Balance, status, aging, formatting (277 lines)
│   │   └── widgets/
│   │       ├── custom_button.dart          # Reusable button (primary/secondary, loading)
│   │       └── custom_text_field.dart      # Reusable labeled text field
│   └── Images/                             # 6 JPEG photos (likely app screenshots or design refs)
├── test/
│   └── widget_test.dart                    # Default Flutter counter test (not applicable)
├── supabase/
│   └── functions/
│       └── create-customer-user/
│           └── index.ts                    # Deno Edge Function for admin user creation
├── docs/
│   └── images/                             # Screenshot placeholders
├── android/                                # Android platform config
├── ios/                                    # iOS platform config (default)
├── web/                                    # Web platform config (default)
├── macos/                                  # macOS platform config (default)
├── windows/                                # Windows platform config (default)
├── linux/                                  # Linux platform config (default)
├── pubspec.yaml                            # Flutter dependencies & assets
├── analysis_options.yaml                   # Linter config (flutter_lints)
├── .env                                    # Supabase credentials (gitignored)
├── .env.example                            # Template for .env
├── .gitignore                              # Ignore rules
├── supabase_schema.sql                     # Full database schema + RLS + RPCs
├── supabase_migration_update.sql           # Migration: add columns, complaints, RPCs, refund type
├── supabase_cascade_auth_fix.sql           # Fix: cascade auth deletion for customers
└── package.json                            # Node deps (supabase-js for edge functions)
```

### Folder Descriptions

| Folder | Purpose |
|---|---|
| `lib/core/` | Application-wide infrastructure: routing, theme, constants, core services |
| `lib/data/models/` | Plain Dart model classes with JSON serialization |
| `lib/data/services/` | Backend communication layer (single `SupabaseService`) |
| `lib/features/auth/` | Authentication feature: controller + screens |
| `lib/features/owner/` | All owner-facing screens organized by sub-feature |
| `lib/features/customer/` | All customer-facing screens |
| `lib/shared/utils/` | Pure utility functions (no Flutter dependency beyond model imports) |
| `lib/shared/widgets/` | Reusable UI widgets used across features |
| `lib/Images/` | Image files stored in the lib directory (6 JPEGs — appear to be app screenshots or design mockups) |
| `supabase/functions/` | Supabase Edge Functions (Deno-based) |

---

## 10. State Management

### Approach: **Riverpod v3** (`flutter_riverpod: ^3.3.1`)

The project uses Riverpod exclusively. There is no use of `setState` for data management (only for local dialog state via `StatefulBuilder`), no Bloc, no GetX, no Redux.

### Provider Inventory

| Provider | Type | File | Purpose |
|---|---|---|---|
| `supabaseProvider` | `Provider<SupabaseClient>` | `supabase_service.dart` | Supabase client singleton |
| `supabaseServiceProvider` | `Provider<SupabaseService>` | `supabase_service.dart` | Service layer singleton |
| `authControllerProvider` | `AsyncNotifierProvider<AuthController, User?>` | `auth_controller.dart` | Auth state (login/signup/logout) |
| `selectedRoleProvider` | `NotifierProvider<SelectedRoleNotifier, String?>` | `auth_controller.dart` | Selected role for login flow |
| `routerNotifierProvider` | `Provider<RouterNotifier>` | `routes.dart` | GoRouter refresh notifier |
| `routerProvider` | `Provider<GoRouter>` | `routes.dart` | GoRouter instance |
| `reminderServiceProvider` | `Provider<ReminderService>` | `reminder_service.dart` | Reminder generation service |
| `dashboardStatsProvider` | `FutureProvider.autoDispose` | `owner_dashboard_screen.dart` | Owner dashboard statistics |
| `customersProvider` | `FutureProvider.autoDispose<List<CustomerModel>>` | `customer_list_screen.dart` | Customer list |
| `customerLedgerProvider` | `FutureProvider.autoDispose.family<List<TransactionModel>, String>` | `customer_ledger_screen.dart` | Per-customer transaction list |
| `allTransactionsProvider` | `FutureProvider.autoDispose<List<TransactionModel>>` | `transaction_screen.dart` | All owner transactions |
| `complaintsProvider` | `FutureProvider.autoDispose<List<ComplaintModel>>` | `complaints_screen.dart` | Complaint list |
| `customerDashboardProvider` | `FutureProvider.autoDispose` | `customer_dashboard_screen.dart` | Customer balance + transactions |
| `notificationsProvider` | `FutureProvider.autoDispose<List<NotificationModel>>` | `customer_dashboard_screen.dart` | Customer notifications |

### Patterns

- **`autoDispose`**: All data-fetching providers use `autoDispose` to free resources when screens are left.
- **`ref.invalidate()`**: After mutations (add/edit/delete), related providers are explicitly invalidated to trigger refetch. Multiple providers are often invalidated together (e.g., `customerLedgerProvider`, `allTransactionsProvider`, `dashboardStatsProvider` after a transaction change).
- **`family`**: `customerLedgerProvider` is a family provider keyed by `customerId`.
- **No local caching**: All data is fetched fresh from Supabase on every provider build.

### Limitations

- No optimistic updates — UI waits for server response before reflecting changes.
- Heavy invalidation pattern — modifying one transaction can trigger refetch of dashboard stats, all transactions, and the specific customer ledger.
- No error recovery beyond showing a SnackBar.

---

## 11. Navigation and Routing

### Approach: **GoRouter** (`go_router: ^17.2.3`)

### Route Table

| Route | Screen | File | Purpose | Entry Point | Status |
|---|---|---|---|---|---|
| `/` | Splash (inline) | `routes.dart` | Loading spinner while auth resolves | App launch | **Implemented** |
| `/role` | `RoleSelectionScreen` | `role_selection_screen.dart` | Role selection (Owner / Customer) | Redirect when unauthenticated | **Implemented** |
| `/login` | `LoginScreen` | `login_screen.dart` | Email/password login (+ signup for owners) | After role selection | **Implemented** |
| `/owner` | `OwnerDashboardScreen` | `owner_dashboard_screen.dart` | Owner main dashboard | After owner login | **Implemented** |
| `/owner/customers` | `CustomerListScreen` | `customer_list_screen.dart` | Customer management | Dashboard quick action | **Implemented** |
| `/owner/customers/:id` | `CustomerLedgerScreen` | `customer_ledger_screen.dart` | Per-customer ledger | Customer list tap | **Implemented** |
| `/owner/transactions` | `TransactionScreen` | `transaction_screen.dart` | All transactions list | Dashboard quick action | **Implemented** |
| `/owner/reports` | `ReportsScreen` | `reports_screen.dart` | Reports & analytics | Dashboard quick action | **Implemented** |
| `/owner/complaints` | `ComplaintsScreen` | `complaints_screen.dart` | Complaint management | Dashboard quick action | **Implemented** |
| `/customer` | `CustomerDashboardScreen` | `customer_dashboard_screen.dart` | Customer main dashboard | After customer login | **Implemented** |
| `/customer/history` | `CustomerHistoryScreen` | `customer_history_screen.dart` | Transaction history | Dashboard menu | **Implemented** |

### Route Guards / Redirect Logic

The `RouterNotifier` class implements the redirect logic:

1. **Unauthenticated users** → redirected to `/role` (unless already on `/role` or `/login`).
2. **Authenticated users on entry screens** (`/`, `/role`, `/login`) → redirected to their role-appropriate dashboard (`/owner` or `/customer`).
3. **Role enforcement** → an `owner` trying to access `/customer/*` is redirected to `/owner`, and vice versa.
4. `RouterNotifier` listens to `authControllerProvider` and calls `notifyListeners()` on auth state changes, which triggers GoRouter to re-evaluate the redirect.

### Navigation Patterns

- **`context.push()`**: Used for forward navigation (preserves back stack).
- **`context.pop()`**: Used on login screen back button.
- **`Navigator.pop(ctx)`**: Used in dialogs.
- **`state.extra`**: The `CustomerModel` is passed to the Customer Ledger screen via GoRouter's `extra` parameter.

### Known Navigation Limitations

- Deep linking to `/owner/customers/:id` would fail because `state.extra` would be null (no fetch-by-id fallback in the route builder).
- No bottom navigation bar — all navigation is via push/pop from the dashboard.
- No drawer or side menu.
- No tab navigation.

---

## 12. Data Models

### 12.1 `CustomerModel`

**File:** `lib/data/models/customer_model.dart`  
**Purpose:** Represents a customer belonging to an owner.  
**Serialization:** `fromJson()` / `toJson()`

| Field | Type | Description | Required/Optional |
|---|---|---|---|
| `id` | `String` (UUID) | Primary key | Required |
| `name` | `String` | Customer display name | Required |
| `phone` | `String` | Customer phone number | Required |
| `ownerId` | `String` (UUID) | FK to owner's `auth.users.id` | Required |
| `authUserId` | `String?` (UUID) | FK to customer's `auth.users.id` (if credentials created) | Optional |
| `creditLimit` | `double` | Maximum credit allowed (default 0) | Optional (default 0.0) |
| `isActive` | `bool` | Soft-delete flag | Optional (default true) |
| `createdAt` | `DateTime` | Creation timestamp | Required |

---

### 12.2 `TransactionModel`

**File:** `lib/data/models/transaction_model.dart`  
**Purpose:** Represents a credit, payment, or refund entry.  
**Serialization:** `fromJson()` / `toJson()`

| Field | Type | Description | Required/Optional |
|---|---|---|---|
| `id` | `String` (UUID) | Primary key | Required |
| `customerId` | `String` (UUID) | FK to `customers.id` | Required |
| `ownerId` | `String` (UUID) | FK to owner's `auth.users.id` | Required |
| `amount` | `double` | Transaction amount (always positive) | Required |
| `type` | `String` | One of: `'credit'`, `'payment'`, `'refund'` | Required |
| `title` | `String?` | Item description (e.g., "Rice and Oil") | Optional |
| `date` | `DateTime` | Transaction date | Required |
| `dueDate` | `DateTime?` | Payment due date (only for credits) | Optional |
| `note` | `String?` | Free-text note | Optional |
| `createdAt` | `DateTime` | Record creation timestamp | Required |

---

### 12.3 `ComplaintModel`

**File:** `lib/data/models/complaint_model.dart`  
**Purpose:** Represents a complaint/request from a customer to their owner.  
**Serialization:** `fromJson()` / `toJson()`

| Field | Type | Description | Required/Optional |
|---|---|---|---|
| `id` | `String` (UUID) | Primary key | Required |
| `customerId` | `String` (UUID) | FK to `customers.id` | Required |
| `ownerId` | `String` (UUID) | FK to owner's `auth.users.id` | Required |
| `message` | `String` | Complaint text | Required |
| `status` | `String` | One of: `'pending'`, `'in_progress'`, `'completed'` | Required |
| `createdAt` | `DateTime` | Submission timestamp | Required |

---

### 12.4 `NotificationModel`

**File:** `lib/data/models/notification_model.dart`  
**Purpose:** Represents an in-app notification (reminder, alert, or info).  
**Serialization:** `fromJson()` / `toJson()`

| Field | Type | Description | Required/Optional |
|---|---|---|---|
| `id` | `String` (UUID) | Primary key | Required |
| `customerId` | `String` (UUID) | FK to `customers.id` | Required |
| `ownerId` | `String` (UUID) | FK to owner's `auth.users.id` | Required |
| `title` | `String` | Notification title | Required |
| `message` | `String` | Notification body | Required |
| `type` | `String` | One of: `'reminder'`, `'alert'`, `'info'` | Required |
| `isRead` | `bool` | Read status | Optional (default false) |
| `transactionId` | `String?` (UUID) | FK to related transaction | Optional |
| `createdAt` | `DateTime` | Creation timestamp | Required |

---

### 12.5 `UserModel`

**File:** `lib/data/models/user_model.dart`  
**Purpose:** Simple user representation (id, email, role). Note: this model is defined but is not actively used in the codebase — `Supabase.User` from the auth SDK is used directly instead.  
**Status:** **Defined but unused** (no imports reference it outside the model file).

| Field | Type | Description | Required/Optional |
|---|---|---|---|
| `id` | `String` | User ID | Required |
| `email` | `String` | Email address | Required |
| `role` | `String` | `'owner'` or `'customer'` | Required (default `'owner'`) |

---

## 13. API / Backend Integration

### 13.1 Supabase Database

**Client Library:** `supabase_flutter: ^2.12.4`  
**Configuration:** URL and Anon Key loaded from `.env` via `flutter_dotenv`.  
**Initialization:** In `main.dart` via `Supabase.initialize()`.

#### Database Tables

| Table | Purpose | Columns | RLS |
|---|---|---|---|
| `customers` | Stores customer records per owner | id, name, phone, owner_id, auth_user_id, credit_limit, is_active, created_at | Enabled |
| `transactions` | Credit/payment/refund entries | id, customer_id, owner_id, amount, type, title, date, due_date, note, created_at | Enabled |
| `complaints` | Customer complaints/requests | id, customer_id, owner_id, message, status, created_at | Enabled |
| `notifications` | In-app reminders and alerts | id, customer_id, owner_id, title, message, type, is_read, transaction_id, created_at | Enabled |

#### Constraints

- `customers`: `credit_limit >= 0`, `UNIQUE(owner_id, phone)`.
- `transactions`: `amount > 0`, `type IN ('credit', 'payment', 'refund')`.
- `complaints`: `status IN ('pending', 'in_progress', 'completed')`.
- `notifications`: `type IN ('reminder', 'alert', 'info')`.

### 13.2 Row Level Security (RLS)

All four tables have RLS enabled. Policies enforce:

| Table | Policy | Who |
|---|---|---|
| `customers` | SELECT, INSERT, UPDATE, DELETE own customers | Owner (via `owner_id = auth.uid()`) |
| `customers` | SELECT own profile | Customer (via `auth_user_id = auth.uid()`) |
| `transactions` | SELECT, INSERT, UPDATE, DELETE via customer ownership join | Owner |
| `transactions` | SELECT own transactions via customer ownership join | Customer |
| `complaints` | SELECT, UPDATE own complaints | Owner |
| `complaints` | SELECT, INSERT own complaints | Customer |
| `notifications` | SELECT, INSERT own notifications | Owner |
| `notifications` | SELECT, UPDATE (mark as read) own notifications | Customer |

### 13.3 Supabase RPCs

| RPC | Purpose | Security | File |
|---|---|---|---|
| `delete_user_account()` | Cascade-delete owner + all customer auth accounts + all data | `SECURITY DEFINER`, authenticated only | `supabase_schema.sql`, `supabase_cascade_auth_fix.sql` |
| `delete_customer_auth_account(target_customer_id)` | Delete a single customer's auth account + customer record | `SECURITY DEFINER`, authenticated only | `supabase_cascade_auth_fix.sql`, `supabase_migration_update.sql` |

### 13.4 Supabase Edge Functions

| Function | Purpose | Runtime | File |
|---|---|---|---|
| `create-customer-user` | Creates a customer auth account using the Admin API (`SUPABASE_SERVICE_ROLE_KEY`) to avoid the session-overwrite problem | Deno | `supabase/functions/create-customer-user/index.ts` |

**Note:** The Flutter app currently uses an in-app workaround (`createCustomerCredentials()` in `SupabaseService`) that creates a temporary `SupabaseClient` with `EmptyLocalStorage` instead of calling this Edge Function. The Edge Function exists as an alternative/future approach.

### API Methods in `SupabaseService`

| Method | Description | HTTP Equivalent |
|---|---|---|
| `signIn()` | Email/password login | POST `/auth/v1/token` |
| `signUp()` | Email/password registration with metadata | POST `/auth/v1/signup` |
| `signOut()` | End session | POST `/auth/v1/logout` |
| `deleteOwnerAccount()` | Calls `delete_user_account()` RPC then signs out | POST `/rest/v1/rpc/delete_user_account` |
| `getCustomers()` | Fetch owner's active customers | GET `/rest/v1/customers` |
| `getCustomerById()` | Fetch single customer | GET `/rest/v1/customers?id=eq.X` |
| `addCustomer()` | Create customer | POST `/rest/v1/customers` |
| `updateCustomerCreditLimit()` | Update credit limit | PATCH `/rest/v1/customers` |
| `deleteCustomer()` | Delete customer (via RPC or direct delete) | POST `/rest/v1/rpc/delete_customer_auth_account` |
| `getCurrentCustomerProfile()` | Fetch customer's own profile via `auth_user_id` | GET `/rest/v1/customers?auth_user_id=eq.X` |
| `createCustomerCredentials()` | Create customer auth + link to record | POST `/auth/v1/signup` + PATCH `/rest/v1/customers` |
| `getTransactionsForCustomer()` | Fetch customer's transactions | GET `/rest/v1/transactions?customer_id=eq.X` |
| `getAllTransactions()` | Fetch all owner's transactions (inner join) | GET `/rest/v1/transactions?select=*,customers!inner(owner_id)` |
| `addTransaction()` | Create transaction | POST `/rest/v1/transactions` |
| `updateTransaction()` | Edit transaction | PATCH `/rest/v1/transactions` |
| `deleteTransaction()` | Delete transaction | DELETE `/rest/v1/transactions` |
| `getComplaints()` | Fetch owner's complaints | GET `/rest/v1/complaints` |
| `submitComplaint()` | Create complaint | POST `/rest/v1/complaints` |
| `resolveComplaint()` | Update complaint status | PATCH `/rest/v1/complaints` |
| `getNotifications()` | Fetch notifications (RLS filters by role) | GET `/rest/v1/notifications` |
| `markNotificationAsRead()` | Mark notification as read | PATCH `/rest/v1/notifications` |
| `sendNotification()` | Create notification | POST `/rest/v1/notifications` |

---

## 14. Local Storage / Persistence

| Storage Type | Usage | Status |
|---|---|---|
| **Supabase Auth Session** | Supabase Flutter SDK automatically persists the auth session to `SharedPreferences` via its built-in `FlutterAuthClientOptions` | **Implemented** (by SDK) |
| **SharedPreferences (explicit)** | Not used directly by app code | **Not implemented** |
| **Hive** | Not used | **Not implemented** |
| **SQLite** | Not used | **Not implemented** |
| **Secure Storage** | Not used | **Not implemented** |
| **Local Cache** | Not used — all data fetched from Supabase on every screen visit | **Not implemented** |
| **Offline Support** | Not available — app requires network connectivity | **Not implemented** |

**`.env` file**: Loaded as a Flutter asset at runtime via `flutter_dotenv`. Contains Supabase URL and Anon Key. Declared in `pubspec.yaml` under `assets`.

---

## 15. Authentication and Authorization

### Authentication

| Feature | Status | Detail |
|---|---|---|
| **Login (Owner)** | **Implemented** | Email + password via `supabase_flutter` auth |
| **Sign Up (Owner)** | **Implemented** | Email + password with `{role: 'owner'}` user metadata |
| **Login (Customer)** | **Implemented** | Email + password (credentials created by owner) |
| **Sign Up (Customer)** | **Not available by design** | Customers are created by owners; signup toggle hidden for customer role |
| **Logout** | **Implemented** | `SupabaseService.signOut()` → clears session |
| **Password Reset** | **Not implemented** | No UI or service method |
| **Social Login** | **Not implemented** | No OAuth providers configured |
| **Session Persistence** | **Implemented** (by SDK) | Supabase SDK persists session to SharedPreferences |
| **Token Refresh** | **Implemented** (by SDK) | Supabase SDK handles automatic token refresh |

### Authorization

| Feature | Status | Detail |
|---|---|---|
| **Role-Based Routing** | **Implemented** | GoRouter redirect checks `userMetadata['role']` and blocks cross-role access |
| **Role Enforcement on Login** | **Implemented** | `AuthController.signIn()` compares `selectedRoleProvider` to actual role; rejects mismatches |
| **Row Level Security** | **Implemented** | All database tables have RLS policies scoped to `auth.uid()` |
| **Route Guards** | **Implemented** | `RouterNotifier.redirect()` prevents unauthenticated access to protected routes |

### Customer Credential Creation Flow

The owner creates customer credentials through a specialized flow:

1. A temporary `SupabaseClient` is instantiated with `EmptyLocalStorage` and `AuthFlowType.implicit` to avoid overwriting the owner's active session.
2. The temp client signs up the customer with `{role: 'customer'}` metadata.
3. The resulting `auth_user_id` is linked to the customer's record via the owner's authenticated client (RLS-compliant).
4. The temp client is disposed.

This is a non-trivial implementation that solves the problem of creating a new auth user without logging out the current user.

---

## 16. Forms and Validation

### 16.1 Login / Sign Up Form

| Property | Detail |
|---|---|
| **Screen** | `login_screen.dart` |
| **Fields** | Email, Password |
| **Validation** | Email: required (non-empty). Password: required, min 6 characters. |
| **Submit** | Calls `AuthController.signIn()` or `AuthController.signUp()` |
| **Success** | GoRouter redirect navigates to appropriate dashboard |
| **Error** | SnackBar with error message |
| **Status** | **Implemented** — validation is basic (no email format regex) |

### 16.2 Add Customer Dialog

| Property | Detail |
|---|---|
| **Screen** | `customer_list_screen.dart` |
| **Fields** | Name, Phone, Credit Limit (ETB) |
| **Validation** | Name and Phone: required (non-empty). Credit Limit: parsed as double, defaults to 0. |
| **Submit** | Calls `SupabaseService.addCustomer()` |
| **Success** | Dialog closes, providers invalidated, SnackBar confirmation, credential creation dialog auto-opens |
| **Error** | SnackBar with error |
| **Status** | **Implemented** — no phone format validation, no duplicate phone check (handled by DB unique constraint) |

### 16.3 Create Credentials Dialog

| Property | Detail |
|---|---|
| **Screen** | `customer_list_screen.dart` |
| **Fields** | Email, Password |
| **Validation** | Both fields must be non-empty |
| **Status** | **Implemented** — no email format or password strength validation |

### 16.4 Add/Edit Transaction Dialog

| Property | Detail |
|---|---|
| **Screen** | `customer_ledger_screen.dart`, `transaction_screen.dart` |
| **Fields** | Type (dropdown), Title, Amount (ETB prefix), Due Date (date picker, credit only), Note |
| **Validation** | Amount: must parse to double > 0. Payment/refund: cannot exceed outstanding balance. Credit: warns if exceeds credit limit (soft). |
| **Status** | **Implemented** — comprehensive validation for business rules |

### 16.5 Update Credit Limit Dialog

| Property | Detail |
|---|---|
| **Screen** | `customer_list_screen.dart` |
| **Fields** | Credit Limit (ETB) |
| **Validation** | Must parse to double ≥ 0 |
| **Status** | **Implemented** |

### 16.6 Submit Complaint Dialog

| Property | Detail |
|---|---|
| **Screen** | `customer_dashboard_screen.dart` |
| **Fields** | Message (multi-line text field) |
| **Validation** | Must be non-empty |
| **Status** | **Implemented** |

---

## 17. UI/UX and Theme System

### Theme Configuration

**File:** `lib/core/theme/app_theme.dart`

| Property | Value |
|---|---|
| **Theme Mode** | Light only (no dark theme) |
| **Font Family** | Inter (via `google_fonts: ^8.1.0`) |
| **Typography** | Display: bold. Headline: semibold. Body: regular. All use `AppColors.text`. |
| **Button Style** | Rounded corners (12px), 16px vertical / 24px horizontal padding, primary color background |
| **Card Style** | Rounded corners (16px), elevation 4, soft shadow |
| **Input Style** | Filled (white), rounded corners (12px), focused border = primary color (2px), error border = red |
| **AppBar** | Primary color background, white foreground, no elevation, centered title |

### Color Palette

**File:** `lib/core/theme/app_colors.dart`

| Name | Hex | Usage |
|---|---|---|
| `primary` | `#14532D` | Dark green — AppBar, primary buttons, icons, branding |
| `secondary` | `#22C55E` | Bright green — secondary buttons |
| `background` | `#F9FAFB` | Off-white scaffold background |
| `text` | `#111827` | Near-black body text |
| `textLight` | `#6B7280` | Gray — subtitles, hints, secondary text |
| `warning` | `#F59E0B` | Amber — defined but not referenced in theme |
| `error` | `#EF4444` | Red — validation errors, overdue states |
| `info` | `#3B82F6` | Blue — defined but not referenced in theme |
| `white` | `#FFFFFF` | Card backgrounds, button text, AppBar text |

### Reusable Widgets

| Widget | File | Props | Usage |
|---|---|---|---|
| `CustomButton` | `shared/widgets/custom_button.dart` | `text`, `onPressed`, `isLoading`, `isSecondary` | Login, role selection buttons |
| `CustomTextField` | `shared/widgets/custom_text_field.dart` | `label`, `hint`, `controller`, `obscureText`, `keyboardType`, `validator` | Login form fields |

### UI Patterns

- **Dashboard cards** with colored backgrounds for financial KPIs.
- **SliverAppBar** with gradient and customer avatar in Customer Ledger.
- **Status badges** — colored container with rounded border for payment status (Pending/Partial/Paid/Overdue).
- **Popup menus** for contextual actions on customers and transactions.
- **Dialogs** (`AlertDialog` + `StatefulBuilder`) for all create/edit forms.
- **SnackBars** for success/error feedback.
- **Bottom sheet** (draggable scrollable) for notifications.
- **CircleAvatar** with first letter of name for customer list items.
- **Pull-to-refresh** (`RefreshIndicator`) on Customer Ledger and Customer History.

### Known UI Limitations

- No dark mode.
- No responsive/adaptive layout for tablets or web.
- No animations beyond standard Material transitions.
- `warning` and `info` colors are defined but not used in the theme system.
- No accessibility considerations visible (no semantic labels, no high-contrast mode).

---

## 18. Assets and Media

### Declared Assets (`pubspec.yaml`)

| Asset | Declaration | Purpose |
|---|---|---|
| `.env` | `assets: [.env]` | Environment variables file loaded at runtime |

### Undeclared Assets (exist in filesystem but not in `pubspec.yaml`)

| Asset | Path | Description |
|---|---|---|
| 6 JPEG photos | `lib/Images/photo_1_2026-05-10_00-18-23.jpg` through `photo_6_...` | Appear to be app screenshots or design reference images (37-65 KB each). Not declared in `pubspec.yaml`, not referenced in any Dart file. |

### Fonts

No custom font files are bundled. Typography uses **Google Fonts (Inter)** fetched at runtime via the `google_fonts` package. This requires network access on first load; the font is cached by the package after initial download.

### Icons

Material Design Icons (`uses-material-design: true` in `pubspec.yaml`). Cupertino Icons available via `cupertino_icons: ^1.0.8` but not visibly used in the codebase.

---

## 19. Platform Support

| Platform | Folder Exists | Status | Notes |
|---|---|---|---|
| **Android** | ✅ `android/` | **Configured** — build files present (`build.gradle.kts`, `settings.gradle.kts`), `local.properties` exists. Application ID: `com.example.credit_app` (needs confirmation). Likely the primary development target. | Needs confirmation: min SDK, target SDK, signing config |
| **iOS** | ✅ `ios/` | **Configured folder exists** — default Flutter iOS project structure. No evidence of testing or customization. | Needs confirmation: Bundle ID, provisioning profiles |
| **Web** | ✅ `web/` | **Configured folder exists** — default Flutter web project structure. | Not tested. May have issues with Supabase auth flow. |
| **macOS** | ✅ `macos/` | **Configured folder exists** — default Flutter macOS structure. | Not tested. |
| **Windows** | ✅ `windows/` | **Configured folder exists** — default Flutter Windows structure. | Not tested. |
| **Linux** | ✅ `linux/` | **Configured folder exists** — default Flutter Linux structure. | Not tested. |

**Primary Platform:** Android (inferred from `local.properties` and general project context).

---

## 20. Setup Instructions

### Prerequisites

| Requirement | Detail |
|---|---|
| **Flutter SDK** | Dart SDK `^3.11.5` (as per `pubspec.yaml` `environment.sdk`) |
| **Supabase Project** | A Supabase project with the schema deployed |
| **IDE** | Android Studio / VS Code with Flutter plugin |
| **Target Device** | Android emulator/device (primary), iOS simulator (secondary) |

### Step-by-Step Setup

#### 1. Clone the Repository

```bash
git clone <repository-url>
cd smart_credit_manager_app
```

#### 2. Install Flutter Dependencies

```bash
flutter pub get
```

#### 3. Configure Environment Variables

Copy the example `.env` file and fill in your Supabase credentials:

```bash
cp .env.example .env
```

Edit `.env`:

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

> ⚠️ **Never commit the `.env` file.** It is listed in `.gitignore`.

#### 4. Set Up Supabase Database

Run the SQL scripts in your Supabase SQL Editor in this order:

1. **`supabase_schema.sql`** — Creates all tables, RLS policies, and RPCs.
2. **`supabase_migration_update.sql`** — Adds missing columns, complaints table, updated RPCs, refund type.
3. **`supabase_cascade_auth_fix.sql`** — Fixes cascade deletion for auth accounts.

> **Important:** Ensure email confirmation is **disabled** in your Supabase Auth settings (Authentication → Settings → Email Auth → "Confirm Email" toggle). Otherwise, customer credential creation will fail.

#### 5. (Optional) Deploy Edge Function

If you want to use the Supabase Edge Function for customer credential creation instead of the in-app workaround:

```bash
supabase functions deploy create-customer-user
```

Requires `SUPABASE_SERVICE_ROLE_KEY` set in your Supabase function secrets.

#### 6. Run the App

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Analyze code
flutter analyze
```

### Common Commands

| Command | Purpose |
|---|---|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run on connected device/emulator |
| `flutter analyze` | Static code analysis |
| `flutter test` | Run tests (only default stub exists) |
| `flutter build apk` | Build Android APK |
| `flutter build ios` | Build iOS (requires macOS + Xcode) |
| `flutter build web` | Build web app |
| `flutter clean` | Clean build artifacts |

---

## 21. Environment Configuration

### `.env` File

| Variable | Description | Source |
|---|---|---|
| `SUPABASE_URL` | Supabase project REST API URL | Supabase Dashboard → Settings → API |
| `SUPABASE_ANON_KEY` | Supabase anonymous (public) key | Supabase Dashboard → Settings → API |

### `.env.example` File

```
SUPABASE_URL=YOUR_SUPABASE_URL_HERE
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY_HERE
```

### How Environment Variables Are Loaded

1. `.env` is declared as a Flutter asset in `pubspec.yaml`.
2. In `main.dart`, `dotenv.load(fileName: ".env")` loads the file.
3. `EnvConstants` class exposes `supabaseUrl` and `supabaseAnonKey` as static getters.
4. These are used in `Supabase.initialize()` and when creating temporary clients for customer credential creation.

### Security Notes

- `.env` is gitignored (listed in `.gitignore`).
- The Anon Key is a **public** key intended for client-side use. It is safe to include in the app binary but should not be confused with the Service Role Key.
- The `SUPABASE_SERVICE_ROLE_KEY` is only used in the Edge Function and is never included in client code.

---

## 22. Testing and Quality

### Automated Tests

| Type | Status | Detail |
|---|---|---|
| **Widget Tests** | **Not implemented** | Only the default Flutter counter smoke test exists (`test/widget_test.dart`). It tests a counter widget that does not exist in this app — it will fail if run. |
| **Unit Tests** | **Not implemented** | No tests for models, services, or utilities. |
| **Integration Tests** | **Not implemented** | No integration test directory. |

### Static Analysis

| Tool | Config | Status |
|---|---|---|
| **flutter_lints** | `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` | **Configured** — default lint rules active, no custom rules enabled |
| **flutter analyze** | Available via CLI | **Available** |

### Manual Testing Checklist

Based on the app's actual features, here is a recommended manual testing checklist:

- [ ] **Role Selection:** Tap "Continue as Owner" → lands on Owner Login
- [ ] **Role Selection:** Tap "Continue as Customer" → lands on Customer Login
- [ ] **Owner Sign Up:** Create a new owner account → redirects to Owner Dashboard
- [ ] **Owner Login:** Log in with existing owner credentials
- [ ] **Role Mismatch:** Try to log in as Owner with a customer account → error shown
- [ ] **Add Customer:** Create a customer with name, phone, and credit limit → appears in list
- [ ] **Duplicate Phone:** Try to add a customer with a phone already used → error from DB
- [ ] **Create Customer Credentials:** Create login for a customer → no session disruption for owner
- [ ] **Issue Credit:** Add a credit transaction with title, amount, due date → balance updates
- [ ] **Credit Limit Warning:** Issue credit that exceeds limit → warning dialog appears
- [ ] **Record Payment:** Record a payment → balance decreases
- [ ] **Over-Payment Block:** Try to record payment greater than outstanding → error shown
- [ ] **Refund/Discount:** Record a refund → balance decreases
- [ ] **Edit Transaction:** Tap a transaction → edit and save → values update
- [ ] **Delete Transaction:** Delete a transaction → confirmation → removed from list
- [ ] **Dashboard Stats:** Verify Total Outstanding = sum of all customer balances
- [ ] **Overdue Detection:** Create a credit with a past due date → overdue status shown
- [ ] **Reports:** Verify aging analysis categorizes customers correctly
- [ ] **Collection Rate:** Verify percentage = total payments / total credits
- [ ] **Customer Login:** Log in as a customer → sees their balance
- [ ] **Customer History:** View transactions → matches what owner recorded
- [ ] **Notifications:** After owner login, check that reminders are generated for due/overdue credits
- [ ] **Mark Notification Read:** Tap notification → mark as read
- [ ] **Submit Complaint:** Customer submits complaint → owner sees it on Complaints screen
- [ ] **Resolve Complaint:** Owner progresses complaint: Pending → In Progress → Completed
- [ ] **Delete Customer:** Delete a customer → cascade deletes transactions, complaints, notifications
- [ ] **Delete Owner Account:** Delete account → all data removed, redirected to role selection
- [ ] **Logout:** Both roles can log out → redirected to role selection

---

## 23. Build and Deployment

### Build Configuration

| Platform | Build System | Config Files |
|---|---|---|
| **Android** | Gradle (Kotlin DSL) | `android/build.gradle.kts`, `android/app/build.gradle.kts`, `android/settings.gradle.kts` |
| **iOS** | Xcode | `ios/Runner.xcodeproj/`, `ios/Runner.xcworkspace/` |

### Build Commands

```bash
# Android APK (release)
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release

# Web
flutter build web --release
```

### Deployment

**Deployment process is not documented in the current repository.**

- No CI/CD configuration found (no `.github/workflows/`, no `Makefile`, no `Fastlane`, no `codemagic.yaml`).
- No signing configuration visible for Android (no `key.properties`, no keystore references).
- No provisioning profiles or Apple Developer configuration visible for iOS.
- No deployment scripts or release documentation.

---

## 24. Known Issues / Current Limitations

| # | Category | Issue | Severity |
|---|---|---|---|
| 1 | **Navigation** | Deep linking to `/owner/customers/:id` crashes because `state.extra` (CustomerModel) would be null | Medium |
| 2 | **Testing** | Only a default counter test exists — no meaningful test coverage | High |
| 3 | **Validation** | Login form only checks non-empty email — no email format validation | Low |
| 4 | **Validation** | Customer phone field has no format validation | Low |
| 5 | **Validation** | Create Credentials dialog has no email format or password strength validation | Medium |
| 6 | **Search** | No search or filter on any list (customers, transactions, complaints) | Medium |
| 7 | **Pagination** | No pagination — all records fetched at once | Medium (at scale) |
| 8 | **Caching** | No local cache — every screen visit triggers fresh Supabase queries | Medium |
| 9 | **Offline** | App requires network connectivity; no offline fallback | Medium |
| 10 | **Dark Mode** | Only light theme defined | Low |
| 11 | **Localization** | All strings hardcoded in English | Medium |
| 12 | **Currency** | ETB (Ethiopian Birr) hardcoded in `FinancialCalculator.formatCurrency()` | Low (region-specific) |
| 13 | **Responsiveness** | No adaptive layout for tablets, desktop, or web | Medium |
| 14 | **Complaints UX** | No customer name shown on complaint cards — only message and timestamp | Low |
| 15 | **Transactions Screen** | No edit/delete from the All Transactions screen — only from Customer Ledger | Low |
| 16 | **UserModel** | `UserModel` class defined but never imported or used anywhere | Very Low |
| 17 | **Images** | 6 JPEG files in `lib/Images/` are neither declared as assets nor referenced in code | Very Low |
| 18 | **Widget Test** | Default counter test references a non-existent counter widget — will fail if run | Low |
| 19 | **Push Notifications** | Only in-app database notifications exist; no device push notifications | Medium |
| 20 | **Error Handling** | Generic error display via SnackBar; no structured error types or retry logic | Medium |
| 21 | **Password Reset** | No "Forgot Password" flow for either role | Medium |
| 22 | **Profile Management** | No profile editing (name, email, password change) for either role | Low |
| 23 | **Android Config** | Application ID likely still `com.example.credit_app` — needs to be changed before release | High (for release) |

---

## 25. Future Roadmap

### Short-Term Improvements (1-4 weeks)

- [ ] **Fix deep-link crash**: Fetch customer by ID from Supabase if `state.extra` is null in the Customer Ledger route.
- [ ] **Add email format validation** on login and credential creation forms.
- [ ] **Add phone number validation** with format hints.
- [ ] **Remove or update the default widget test** to avoid confusion.
- [ ] **Remove unused `UserModel`** or integrate it into the auth flow.
- [ ] **Clean up `lib/Images/`** — either declare as assets or remove.
- [ ] **Add search/filter** on Customer List and All Transactions screens.
- [ ] **Show customer name on complaint cards** by joining with customer data.
- [ ] **Allow edit/delete on All Transactions screen** (not just from Customer Ledger).
- [ ] **Change Android application ID** from `com.example.credit_app` to a production ID.

### Medium-Term Improvements (1-3 months)

- [ ] **Dark mode** — define `AppTheme.darkTheme` and add a theme toggle.
- [ ] **Password reset flow** — integrate Supabase's `resetPasswordForEmail()` with a UI.
- [ ] **Profile management** — allow owners and customers to change their display name and password.
- [ ] **Local caching / offline support** — use Hive or SQLite to cache data locally with sync.
- [ ] **Pagination** — implement cursor-based or offset pagination for large datasets.
- [ ] **Data export** — PDF or CSV export for transaction ledgers and reports.
- [ ] **Chart visualizations** — integrate `fl_chart` or similar for dashboard and reports.
- [ ] **Push notifications** — Firebase Cloud Messaging for payment reminders.
- [ ] **Add unit tests** for `FinancialCalculator`, `SupabaseService`, and `AuthController`.
- [ ] **Add widget tests** for all screens.

### Long-Term Improvements (3-6 months)

- [ ] **Localization** — support Amharic (am), Oromo (om), and other Ethiopian languages.
- [ ] **Multi-currency support** — allow configurable currency instead of hardcoded ETB.
- [ ] **Responsive layout** — optimize for tablets and web.
- [ ] **Admin dashboard** — web-based admin panel for platform operators.
- [ ] **Payment integration** — integrate with mobile payment systems (e.g., Telebirr, CBE Birr).
- [ ] **Analytics** — integrate Firebase Analytics or Mixpanel.
- [ ] **CI/CD** — set up GitHub Actions for automated build, test, and deploy.
- [ ] **App Store deployment** — configure signing, prepare store listings, submit to Play Store and App Store.
- [ ] **Accessibility** — semantic labels, high-contrast mode, screen reader support.
- [ ] **Performance optimization** — reduce provider invalidation cascades, implement optimistic updates.

---

## 26. Developer Guidelines

### Before You Start

1. **Read this README** entirely before modifying any code.
2. **Set up your `.env`** — never hardcode Supabase credentials.
3. **Run `flutter analyze`** before committing — fix all linter warnings.
4. **Understand the dual-role model** — every feature should work correctly for both Owner and Customer roles.

### Code Standards

1. **Feature-first organization** — new screens go in `lib/features/<role>/<feature>/`.
2. **Models in `data/models/`** — include `fromJson()` and `toJson()` for all models.
3. **Services in `data/services/`** — all Supabase API calls go through `SupabaseService`.
4. **Providers near their screens** — data-fetching providers are defined in the screen files that use them.
5. **Use `autoDispose`** on all `FutureProvider` instances to prevent memory leaks.
6. **Use `ref.invalidate()`** after mutations to refresh dependent providers.
7. **Use existing theme** — reference `AppColors` and `AppTheme` instead of inline colors/styles.
8. **Use existing widgets** — `CustomButton` and `CustomTextField` for form consistency.

### What to Avoid

- ❌ Do not hardcode secrets or API keys anywhere.
- ❌ Do not use `setState` for state that crosses widget boundaries — use Riverpod.
- ❌ Do not create dead-end screens (every screen must have clear navigation back).
- ❌ Do not bypass RLS — always let the Supabase client handle authorization.
- ❌ Do not use `getAllTransactions()` in customer-facing code — scope to the customer's own data.
- ❌ Do not create new `SupabaseClient` instances unless you have a specific session-management reason (see `createCustomerCredentials()` for the justified exception).

### When Adding New Features

1. Update the route table in `routes.dart`.
2. Add appropriate RLS policies in Supabase if new tables are involved.
3. Update this README with the new screen, feature, and any new models.
4. Test both Owner and Customer roles.
5. Run `flutter analyze` and fix all issues.

---

## 27. Screenshot Placeholder Index

| # | Screenshot | Placeholder Path | Page / Feature |
|---|---|---|---|
| 1 | Splash Screen | `docs/images/splash-screen.png` | App loading / entry |
| 2 | Role Selection | `docs/images/role-selection.png` | Owner / Customer role picker |
| 3 | Login Screen | `docs/images/login-screen.png` | Email + password authentication |
| 4 | Owner Dashboard | `docs/images/owner-dashboard.png` | Financial KPIs + quick actions |
| 5 | Customer List | `docs/images/customer-list.png` | Customer management |
| 6 | Customer Ledger | `docs/images/customer-ledger.png` | Per-customer debt detail |
| 7 | All Transactions | `docs/images/all-transactions.png` | Cross-customer transaction list |
| 8 | Reports & Analytics | `docs/images/reports-analytics.png` | Business intelligence |
| 9 | Complaints | `docs/images/complaints.png` | Complaint workflow |
| 10 | Customer Dashboard | `docs/images/customer-dashboard.png` | Customer balance + notifications |
| 11 | Customer History | `docs/images/customer-history.png` | Read-only transaction history |

---

## 28. Glossary

| Term | Definition |
|---|---|
| **Owner** | A business operator (shop keeper, vendor) who extends credit to customers and uses SCM to track debts and payments. |
| **Customer** | A buyer who receives credit from an owner and can optionally log into SCM to view their balance and history. |
| **Credit** | An amount of money owed by a customer to an owner (type `'credit'` in transactions). Functionally equivalent to "debt." |
| **Payment / Repayment** | A cash payment from customer to owner that reduces the outstanding balance (type `'payment'`). |
| **Refund / Discount** | A reduction in the customer's debt issued by the owner (type `'refund'`). Reduces balance like a payment. |
| **Outstanding Balance** | Total Credits − Total Payments − Total Refunds. Cannot be negative. |
| **Credit Limit** | Maximum outstanding balance allowed for a customer. Soft-enforced (warning, not block). |
| **Available Credit** | Credit Limit − Outstanding Balance. Shows how much more credit a customer can receive. |
| **Due Date** | Optional date by which a credit should be repaid. Used for overdue detection and reminders. |
| **Payment Status** | Per-customer or per-transaction status: **Pending** (no payments), **Partial** (some paid), **Paid** (fully paid), **Overdue** (past due date and unpaid). |
| **Aging Analysis** | Categorization of outstanding debt by how long it has been overdue: Current, 1-7 Days, 8-30 Days, 30+ Days. |
| **Collection Rate** | Percentage of total issued credit that has been collected as payments. |
| **RLS** | Row Level Security — PostgreSQL feature that restricts data access based on the authenticated user. |
| **RPC** | Remote Procedure Call — a PostgreSQL function exposed via Supabase's REST API. |
| **ETB** | Ethiopian Birr — the currency used throughout the app. |
| **FIFO** | First In, First Out — the payment application logic used to determine which credits are paid off first. |
| **SCM** | Smart Credit Manager — the app's abbreviation. |
| **Edge Function** | A serverless Deno function hosted on Supabase infrastructure. |

---

## 29. Maintainer Notes

### Stable Parts

- **FinancialCalculator** (`financial_calculator.dart`) — well-structured, pure functions, handles edge cases (floating point near zero, negative balances clamped). This is the most robust utility in the codebase.
- **SupabaseService** — consistent API pattern, clear method signatures, proper null checks.
- **Auth flow** — role enforcement, credential creation with session isolation, and cascade deletion are all well-implemented.
- **GoRouter redirect logic** — handles all edge cases (unauthenticated, authenticated on entry screens, wrong role).

### Fragile Parts

- **Customer Ledger screen** (`customer_ledger_screen.dart`) — at 1087 lines, this is the largest and most complex file. Mixing dialogs, validation, and UI in a single file makes it hard to maintain. Consider extracting dialogs and transaction-form logic into separate widgets/classes.
- **Provider invalidation cascade** — modifying a single transaction invalidates 3+ providers. As the app scales, this could cause performance issues or race conditions.
- **`state.extra` in routing** — passing full model objects via GoRouter `extra` is fragile for deep linking and state restoration.

### Unclear Areas

- **`lib/Images/` folder** — unclear purpose. Contains 6 dated JPEG files that are not referenced anywhere. May be design reference screenshots.
- **`UserModel`** — defined but never imported. Unclear if it was intended for future use or is leftover code.
- **`package.json`** at root — contains `@supabase/supabase-js` and `dotenv` Node dependencies. Likely used during development/testing of Edge Functions, but unclear if it's still needed.

### Parts Needing Refactor

- **Customer Ledger screen** — extract dialog widgets, transaction form, and status badge into separate files.
- **Dashboard stats computation** — `dashboardStatsProvider` runs through all customers and all transactions synchronously. At scale, this should be a server-side computation (Supabase RPC or view).
- **Error handling** — replace generic `catch (e)` + SnackBar with structured error types and centralized error handling.

### Parts Needing Business Confirmation

- **Currency**: Is ETB the only supported currency, or should multi-currency be supported?
- **Credit limit enforcement**: Currently soft (warning) — should it be hard (blocking)?
- **Customer self-registration**: Currently blocked by design — is this permanent?
- **Complaint workflow**: Only three states (pending → in_progress → completed) — is this sufficient?
- **Notification trigger timing**: Reminders are generated on owner login — should they run on a server-side cron instead?

### Parts Needing Design Confirmation

- **Dark mode**: Is it planned?
- **Tablet/web layout**: Is responsive design a priority?
- **Branding**: The splash screen has no logo or branding — is a branded splash planned?
- **Language support**: Is Amharic/Oromo localization planned?

---

## 30. Summary of This Document

| Metric | Count |
|---|---|
| **Sections documented** | 30 |
| **Screens documented** | 11 (Splash, Role Selection, Login, Owner Dashboard, Customer List, Customer Ledger, All Transactions, Reports, Complaints, Customer Dashboard, Customer History) |
| **Major features documented** | 35 (28 implemented, 7 not implemented) |
| **User flows documented** | 7 (Owner Registration, Add Customer + Issue Credit, Record Payment, Customer Login, Submit Complaint, Automated Reminders, Delete Account) |
| **Architecture findings** | Feature-first with shared data/service/utility layers; Riverpod state; GoRouter with auth-aware redirect; single SupabaseService |
| **Data models documented** | 5 (CustomerModel, TransactionModel, ComplaintModel, NotificationModel, UserModel) |
| **Providers documented** | 14 |
| **Screenshot placeholders added** | 11 |
| **Future roadmap items** | 30+ (across short/medium/long-term) |
| **Known limitations found** | 23 |
| **SQL files analyzed** | 3 (schema, migration, auth fix) |
| **Edge Functions analyzed** | 1 (create-customer-user) |
| **Files changed** | 1 (`README.md`) |
| **Folders created** | 1 (`docs/images/`) |
| **Assumptions made** | Android is the primary platform (inferred from `local.properties`). Application ID is `com.example.credit_app` (needs confirmation). ETB is the intentional currency. The 6 JPEG files in `lib/Images/` are not production assets. |
