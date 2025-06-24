# Expense Forecasting App
A personal finance tracker built with Flutter. This app lets you log expenses, visualise spending trends, and forecast future expenses using machine learning, all offline.

## 🚀 Features
- **📊 Expense Tracking** – Log and categorise daily expenses.
- **🔮 Forecasting** – Predict future spending with a Random Forest regression model.
- **📈 Analytics Charts** – Visualise your financial habits with clear, interactive charts.
- **📂 CSV Import** – Quickly import your existing data.
- **🗃️ Local Storage** – Uses Isar for fast, offline-first performance.

## ⚙️ Tech Stack
- **Isar** – Lightweight NoSQL database for local storage.
- **Random Forest Regression** – For financial forecasting.
- **Sliding Window Technique** – Applied to improve prediction accuracy.
- **Data Visualisation** – Built-in charts for better insights.

## 🧪 Testing & Challenges
- Optimised for smaller datasets; performance drops slightly with large imports.
- CSVs need to be preprocessed before import.
- Improvements are ongoing in error handling and user feedback loops.

## Installation
Run the following command to clone the repository:
   ```bash
   git clone https://github.com/trippyPhilosopher/FinSight
   cd FinSight
   flutter pub get
   flutter run
  ```

## License
This project is licensed under the AGPL-3.0 license - see the LICENSE file for details.

