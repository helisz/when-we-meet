-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Users Table
create table users (
  id uuid default uuid_generate_v4() primary key,
  username text unique not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Meetings Table
create table meetings (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  description text,
  host_id uuid references users(id) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Meeting Slots Table
create table meeting_slots (
  id uuid default uuid_generate_v4() primary key,
  meeting_id uuid references meetings(id) on delete cascade not null,
  date date not null,
  time_slot text not null, -- e.g., "09:30"
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Availabilities Table
create table availabilities (
  id uuid default uuid_generate_v4() primary key,
  meeting_slot_id uuid references meeting_slots(id) on delete cascade not null,
  user_id uuid references users(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(meeting_slot_id, user_id)
);

-- Suggestions Table
create table suggestions (
  id uuid default uuid_generate_v4() primary key,
  meeting_id uuid references meetings(id) on delete cascade not null,
  user_id uuid references users(id) on delete cascade not null,
  suggestion text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS Policies (Optional but recommended)
alter table users enable row level security;
create policy "Public users are viewable by everyone." on users for select using (true);
create policy "Users can insert their own profile." on users for insert with check (true);
create policy "Users can update own profile." on users for update using (true);

alter table meetings enable row level security;
create policy "Meetings are viewable by everyone." on meetings for select using (true);
create policy "Users can create meetings." on meetings for insert with check (true); -- In real app, check auth.uid()
create policy "Hosts can update their meetings." on meetings for update using (auth.uid() = host_id); -- Requires auth setup, but here we use custom user table. 
-- Since we are using a custom 'users' table and not Supabase Auth for this simple demo (based on "enter username" requirement), 
-- we might need to disable RLS or write policies based on the 'user' state which is harder without JWT.
-- For this prototype, we will DISABLE RLS to ensure it works with the custom user logic provided.

alter table users disable row level security;
alter table meetings disable row level security;
alter table meeting_slots disable row level security;
alter table availabilities disable row level security;
alter table suggestions disable row level security;
