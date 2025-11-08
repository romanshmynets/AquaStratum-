insert into app.users (email, full_name)
values
  ('demo@example.com', 'Demo User')
on conflict (email) do nothing;
