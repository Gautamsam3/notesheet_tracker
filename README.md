# Document Flow Manager

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white)

A modern, role-based application built with Flutter and Supabase to streamline and manage internal submission and approval workflows with real-time status tracking.

---

### Table of Contents
1.  [Introduction](#introduction)
2.  [Key Features](#key-features)
3.  [Workflow](#workflow)
4.  [Technology Stack](#technology-stack)
5.  [Getting Started](#getting-started)
    * [Prerequisites](#prerequisites)
    * [Supabase Setup](#supabase-setup)
    * [Flutter Setup](#flutter-setup)
6.  [Test User Credentials](#test-user-credentials)
7.  [Screenshots](#screenshots)
8.  [Contributing](#contributing)
9.  [License](#license)

---

## Introduction

The Document Flow Manager is designed to replace traditional, manual approval chains with a transparent, efficient, and digital alternative. It provides a clear, multi-level review process for text-based submissions within an organization. The system is built around three distinct user roles—**Submitter**, **Reviewer**, and **Head of Department (HOD)**—each with a tailored dashboard and specific permissions to ensure a secure and focused user experience.

## Key Features

* ✅ **Role-Based Dashboards:** Unique interfaces for Submitters, Reviewers, and the HOD, showing only relevant information and actions.
* ✅ **Text-Based Workflow:** The entire approval process is managed through structured text details, eliminating the complexity of file management.
* ✅ **Real-Time Status Tracking:** Leveraging Supabase's real-time capabilities, status updates (`Under Review`, `Forwarded to HOD`, `Approved`, `Needs Revision`) are instantly reflected across all dashboards.
* ✅ **Secure, Pre-Registered Access:** A secure, invitation-only model where all user accounts are pre-registered, enhancing security by removing public sign-up.
* ✅ **Clean & Modern UI:** Built with Flutter, featuring a professional and intuitive user interface with a teal and indigo color palette for excellent readability.

## Workflow

The application follows a clear, three-step approval process:

1.  **Initiation:** A **Submitter** creates a new request with project details and assigns it to a specific **Reviewer**.
2.  **Initial Review:** The assigned **Reviewer** examines the details and decides to either **Reject** it or **Forward** it to the HOD for final approval.
3.  **Final Decision:** The **HOD** reviews the forwarded request and makes the final decision to **Approve** or **Reject**. The final status is then visible to the Submitter.

## Technology Stack

* **Frontend:** Flutter
* **Backend-as-a-Service (BaaS):** Supabase
    * **Database:** Supabase PostgreSQL
    * **Authentication:** Supabase Auth
    * **Realtime:** Supabase Realtime Subscriptions

---

## Getting Started

Follow these instructions to set up and run the project locally.

### Prerequisites

* [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.0.0 or higher)
* A code editor like [VS Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)
* A free [Supabase](https://supabase.com/) account

### Supabase Setup

1.  **Create a New Project:**
    * Go to your Supabase dashboard and create a new project.

2.  **Run the SQL Script:**
    * Navigate to the **SQL Editor** in your new project.
    * Copy the entire content of the [database setup script](./supabase_setup.sql) and run it. This will create the necessary tables and policies.
    * *(Note: You will need to create a `supabase_setup.sql` file in your project root and paste the SQL script from our conversation into it).*

3.  **Create Users:**
    * Go to the **Authentication** tab in your Supabase project.
    * Manually create the 7 users as specified in the "Test User Credentials" section below. Use the password `123456` for all of them.
    * After creating the users, go back to the **SQL Editor** and run the `INSERT` statements from the setup script to populate the `profiles` table, making sure to use the correct `UUID` for each user.

4.  **Get API Credentials:**
    * Navigate to **Project Settings** > **API**.
    * You will need the **Project URL** and the `anon` **public** key for the next step.

### Flutter Setup

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/your-username/document-flow-manager.git](https://github.com/your-username/document-flow-manager.git)
    cd document-flow-manager
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Add Supabase Credentials:**
    * Open the `lib/main.dart` file.
    * Find the following lines and replace the placeholder values with your actual Supabase URL and Anon Key:
        ```dart
        // --- SUPABASE CONFIGURATION ---
        const String supabaseUrl = 'YOUR_SUPABASE_URL';
        const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
        ```

4.  **Run the Application:**
    ```bash
    flutter run
    ```

---

## Test User Credentials

Use the following pre-registered accounts to test the different roles. The password for all accounts is `123456`.

| Role                | Email Address        |
| ------------------- | -------------------- |
| **Submitter** | `ayu@gmail.com`      |
| **Reviewer 1** | `rev1@gmail.com`     |
| **Reviewer 2** | `rev2@gmail.com`     |
| **Reviewer 3** | `rev3@gmail.com`     |
| **Reviewer 4** | `rev4@gmail.com`     |
| **Reviewer 5** | `rev5@gmail.com`     |
| **Head of Dept.** | `hod@gmail.com`      |

---

## Screenshots

*(Add screenshots of your application here to give a visual overview of the UI.)*

| Login Screen | Submitter Dashboard | Reviewer Dashboard |
| :---: | :---: | :---: |
| ![Login Screen](link-to-your-screenshot.png) | ![Submitter Dashboard](link-to-your-screenshot.png) | ![Reviewer Dashboard](link-to-your-screenshot.png) |


---

## Contributing

Contributions are welcome! If you have suggestions for improvements or find any bugs, please feel free to open an issue or submit a pull request.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.
