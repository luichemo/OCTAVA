/// Connection details for OCTAVA's Supabase project.
///
/// Both values are public by design: every copy of the app contains them, and
/// the database's row-level security rules decide what each user can do.
/// Never put the secret / service_role key or the database password here.
class SupabaseConfig {
  static const url = 'https://nbvcbhnaevkrnpbjhbbj.supabase.co';
  static const publishableKey =
      'sb_publishable_M2INmNsIWAU8iXW77-wLeA_YY1ma98n';
}
