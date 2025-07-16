# QA Analysis and Test Plan

This document outlines the QA analysis and test plan for the Petugas Pintar application.

## 1. Login Screen (`lib/screens/login_screen.dart`)

### 1.1. Functionality

| # | Test Case | Expected Result |
|---|---|---|
| 1 | **Valid Credentials** | User is successfully logged in and redirected to the home screen. |
| 2 | **Invalid Credentials** | An error message is displayed, and the user remains on the login screen. |
| 3 | **Empty Credentials** | Validation messages for username and password fields are displayed. |
| 4 | **Offline Login** | The app attempts to log in and displays a network error message if it fails. The user should not be left on a frozen screen. |

### 1.2. UI/UX

| # | Test Case | Expected Result |
|---|---|---|
| 1 | **Password Visibility Toggle** | The password text is correctly obscured and revealed when the toggle is pressed. |
| 2 | **Error Message Display** | The error message is clearly visible and understandable. |
| 3 | **Loading Indicator** | A loading indicator is displayed when the login attempt is in progress. |

### 1.3. Gaps and Unhandled Scenarios

- **No "Forgot Password" feature:** There is currently no functionality for users who have forgotten their password.
- **No rate limiting:** The app does not prevent brute-force attacks on the login form.
- **No offline login support:** The app does not allow users to log in with cached credentials when offline.

## 2. Home Screen (`lib/screens/home_screen.dart`)

### 2.1. Functionality

| # | Test Case | Expected Result |
|---|---|---|
| 1 | **Display User Information** | The user's name and a greeting are correctly displayed. |
| 2 | **Display Global Stats** | The total number of reports and reports for the day are correctly displayed. |
| 3 | **Quick Actions Navigation** | Each quick action button navigates to the correct screen. |
| 4 | **Recent Reports Feed** | The three most recent reports are displayed. |
| 5 | **"Lihat Semua" Navigation** | The "Lihat Semua" button navigates to the reports screen. |
| 6 | **Pull-to-Refresh** | The screen data is refreshed when the user pulls down. |
| 7 | **Offline Data** | The screen displays cached data when the device is offline. |

### 2.2. UI/UX

| # | Test Case | Expected Result |
|---|---|---|
| 1 | **Empty State** | A user-friendly message with an illustration is displayed when there are no reports. |
| 2 | **Loading State** | A loading indicator is shown while data is being fetched. |
| 3 | **Layout on Different Devices** | The layout is responsive and looks good on various screen sizes. |

### 2.3. Gaps and Unhandled Scenarios

- **No real-time updates without pull-to-refresh:** The home screen does not automatically update with new reports unless the user manually refreshes.
- **No specific error message for failed refresh:** If the pull-to-refresh action fails, a generic error is shown.

## 3. Reports Screen (`lib/screens/reports_screen.dart`)

### 3.1. Functionality

| # | Test Case | Expected Result |
|---|---|---|
| 1 | **Display All Reports** | A paginated list of all reports is displayed. |
| 2 | **Pagination Controls** | The "Next" and "Previous" buttons correctly navigate through the pages of reports. |
| 3 | **Report Card Navigation** | Tapping on a report card navigates to the report detail screen. |
| 4 | **Pull-to-Refresh** | The list of reports is refreshed when the user pulls down. |
| 5 | **Offline Behavior** | The screen displays cached reports when the device is offline. |

### 3.2. UI/UX

| # | Test Case | Expected Result |
|---|---|---|
| 1 | **Empty State** | A user-friendly message is displayed when there are no reports. |
| 2 | **Loading State** | A loading indicator is shown while reports are being fetched. |
| 3 | **Pagination State** | The current page and total pages are clearly indicated. |

### 3.3. Gaps and Unhandled Scenarios

- **No search or filtering:** Users cannot search for specific reports or filter them by date, type, or status.
- **No indication of which reports are new:** There is no visual indicator for reports that have not been viewed yet.