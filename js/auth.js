// Shared committee login. There is one committee account in Supabase Auth;
// members never see this module do anything (public read only).
const COMMITTEE_EMAIL = 'padel@yorksu.org';

export function initAuth(sb, onSessionChange) {
  sb.auth.onAuthStateChange((_event, session) => onSessionChange(!!session));
  return sb.auth.getSession().then(({ data }) => !!data.session);
}

export async function signInCommittee(sb, password) {
  const { error } = await sb.auth.signInWithPassword({ email: COMMITTEE_EMAIL, password });
  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

export async function signOutCommittee(sb) {
  await sb.auth.signOut();
}
