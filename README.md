# 📄 Pages & Screens Index

This section documents all the main UI pages/screens in the project, organized by feature. Each entry includes the relative path and a description inferred from the file name and directory structure.

---

## **Global Entry Point**

- **`lib/main.dart`**  
  *The main entry point of the Flutter application. Handles app initialization, theme, routing, and user authentication state.*

---

## **Feature: Authentication**

- **`lib/features/auth/presentation/pages/login_page.dart`**  
  *Login screen for user authentication.*

- **`lib/features/auth/presentation/pages/signup_page.dart`**  
  *Signup/registration screen for new users.*

---

## **Feature: Home**

- **`lib/features/home/presentation/pages/home_page.dart`**  
  *Main dashboard/homepage. Likely routes users to role-specific dashboards after login.*

- **`lib/features/home/presentation/pages/later/marketplace_home_page.dart`**  
  *Marketplace home page, possibly for browsing available jobs or services.*

---

## **Feature: Profile**

- **`lib/features/profile/presentation/pages/profile_page.dart`**  
  *User profile page for viewing and editing personal information.*

- **`lib/features/profile/presentation/pages/profile_completion_page.dart`**  
  *Page prompting users to complete their profile details (e.g., after signup).*

---

## **Feature: Jobs**

- **`lib/features/jobs/presentation/pages/job_details_page.dart`**  
  *Detailed view for a specific job, including description, requirements, and actions.*

---

## **Feature: Driver**

- **`lib/features/driver/presentation/pages/driver_home_page.dart`**  
  *Dashboard for users with the 'driver' role. Shows available jobs, applications, and status updates.*

---

## **Feature: Broker**

- **`lib/features/broker/presentation/pages/broker_home_page.dart`**  
  *Dashboard for users with the 'broker' role. Likely includes stats, driver management, and job oversight.*

- **`lib/features/broker/presentation/pages/manage_drivers_page.dart`**  
  *Page for brokers to manage their associated drivers (add, remove, view status, etc.).*

---

## **Feature: Warehouse**

- **`lib/features/warehouse/presentation/pages/warehouse_home_page.dart`**  
  *Dashboard for users with the 'warehouse_owner' role. Shows posted jobs, job management, and analytics.*

- **`lib/features/warehouse/presentation/pages/post_job_page.dart`**  
  *Form/page for warehouse owners to post new jobs.*

---

## **Widgets (Composite/Utility Screens)**

While not full pages, these widgets may represent major UI components or dashboards:

- **`lib/widgets/error_display_widget.dart`**  
  *Reusable widget for displaying error messages across pages.*

- **`lib/widgets/performance_optimized_widgets.dart`**  
  *Contains optimized widgets for job lists and other high-performance UI elements.*

- **`lib/widgets/session_info_widget.dart`**  
  *Widget for displaying session/user info.*

- **`lib/widgets/session_management_widget.dart`**  
  *Widget for managing user sessions (logout, refresh, etc.).*

- **`lib/widgets/rate_limit_status_widget.dart`**  
  *Widget for showing API rate limit status.*

- **`lib/widgets/fraud_detection_dashboard.dart`**  
  *Dashboard widget for fraud detection analytics (likely for admin or broker roles).*

---

## **How to Use This Index**

- **To find a page:**  
  Search for the file path in your codebase. For example, to find the driver dashboard, go to `lib/features/driver/presentation/pages/driver_home_page.dart`.

- **To add a new page:**  
  Place it in the appropriate `presentation/pages/` directory under the relevant feature.

- **To understand navigation:**  
  The main routing logic is in `lib/main.dart` and each feature's main page (e.g., `home_page.dart`, `driver_home_page.dart`) typically acts as the entry point for that role or feature.

---

## **Conventions**

- **Page files** are named `*_page.dart` and reside in `presentation/pages/` folders.
- **Widgets** that are major UI components but not full pages are in `lib/widgets/`.
- **Role-based dashboards** are in their respective feature folders (driver, broker, warehouse).

---

This index should enable both humans and AI to quickly locate, understand, and retrieve any main UI screen in the project. For more details on each page's implementation, open the file and review the class and widget structure.

---

**If you add or rename pages, please update this section to keep the documentation current.**
