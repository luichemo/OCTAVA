-- Removes the test musicians added by test_musicians.sql, together with
-- everything linked to them (profiles, swipes, matches, messages), because
-- every table cascades from auth.users.
delete from auth.users where email like '%@test.octava.invalid';
