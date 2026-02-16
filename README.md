# Wolfram-Alpha (MAE 213 Honors Contract)

This project is a web-based engineering tool for analyzing structural mechanics concepts like beams, columns, torsion, and trusses.

## 🚀 How to Run

1.  Clone the repository:
    ```bash
    git clone https://github.com/bibitybaqityboo/Wolfram-Alpha.git
    ```
2.  Open `index.html` in your web browser.

## 🤝 Contribution Guidelines

To ensure code stability, please follow these rules when contributing:

### 1. The Golden Rule: Use the `development` Branch
*   **NEVER** push directly to the `main` branch.
*   **ALWAYS** make your changes on the `development` branch or a feature branch off of `development`.

### 2. Workflow for AI Assistants & Humans
1.  **Pull the latest changes:**
    ```bash
    git checkout development
    git pull origin development
    ```
2.  **Create a new branch for your feature:**
    ```bash
    git checkout -b feature/my-new-feature
    ```
3.  **Make your changes and commit them.**
4.  **Push your branch:**
    ```bash
    git push origin feature/my-new-feature
    ```
5.  **Open a Pull Request (PR)** on GitHub to merge your branch into `development`.

## 📂 Project Structure

*   `index.html`: Main entry point for the application.
*   `style.css`: Global styles.
*   `app.js`: Main application logic.
*   `beam.js`, `column.js`, `torsion.js`, `truss.js`: specialized modules for different mechanics calculations.
*   `material.js`: Material property definitions.
