# FinBud - Finance Manager/ Expense Tracker App

# Swift/ SwiftUI App
- Minimum iOS Build Deployment Target  - iOS 17.6
- For SwiftData using local storage
- To use AI Feature test on device with iOS 26, with Apple Intelligence Turned ON

# How to run the app
- After cloning the repository, open the folder in xcode
- Select a device:
  - Choose an iPhone simulator (e.g., iPhone 17) from the top toolbar
  - OR
  - Connect a real iPhone
  - Click the Run button in Xcode
The app will build and launch automatically on the selected device.
- Cannot provide Testflight, because required paid Apple Developer Membership, and APK not possible for iOS apps.

# Problem Statement
To create a FinTech like app, for user's to manage and track their expenses, with local storage - offline only. Easy transaction entry and history, Gradient Card Header to clearly see their balance, income & expense.

# Solution
Why used SwiftUI?
I know React Native was preferred in the Figma file but I was already building a similar application for myself and learning iOS development, so I had started building it before I got selected for the assignment. Since it was the same topic I continued building it.
Advantage of using Swift - Helps in building modern native iOS applications with speedy perfomance and native features. Apple also slowly migrating all it's application to Swift & SwiftUI

Features Used - 
1. SwiftData - For local in app storage
2. Apple Intelligence - See insights on user's expense
3. Swift Charts - For designing Charts on data, highly efficient and fast

Project Architecture
- Clean Architecture following MVVM - Models, Views, ViewModels
- Models - SwiftData declaration, SwiftDataModels - Entities, FinanceModels - For each struct definition
- Service - FinanceStore - Single Source of truth handling all data operations(CRUD)
- ViewModels - BusinessLogic Layer between UI and Service layer, so business logic is separated between UI and the database functions or API repository
- Views - UI Layer, to create and manage all SwiftUI Views

# Video Demo Link


https://github.com/user-attachments/assets/b044f89c-48b1-49fd-9bc0-cdc0363b7e43

Code - Onboarding Walkthrough
https://drive.google.com/drive/folders/17nzHTRqWZMWwWp6UI8SRHnBihBLC5kxi?usp=sharing

