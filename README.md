# When We Meet

A meeting coordination tool built with Nuxt 3 and Supabase.

## Setup

1.  **Install Dependencies**
    ```bash
    npm install
    ```

2.  **Supabase Setup**
    *   Create a new project on [Supabase](https://supabase.com).
    *   Go to the SQL Editor and run the contents of `db_schema.sql`.
    *   Get your Project URL and Anon Key from Project Settings > API.

3.  **Environment Variables**
    *   Rename `.env` (if it exists) or create one.
    *   Fill in your Supabase credentials:
        ```
        SUPABASE_URL=https://your-project.supabase.co
        SUPABASE_KEY=your-anon-key
        ```

4.  **Run Development Server**
    ```bash
    npm run dev
    ```

## Features

*   **User Identification**: Simple username entry.
*   **Host Meeting**: Select dates and times (multi-select).
*   **Join Meeting**: View meetings, vote on slots.
*   **Results**: View who voted for what slot.
*   **Suggestions**: Suggest alternative dates.
