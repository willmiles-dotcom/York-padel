// Two account types share this one Supabase Auth setup:
// - The single shared committee account (COMMITTEE_EMAIL) - full write access.
// - Individual member accounts (@york.ac.uk, enforced server-side by a DB
//   trigger) - read-only, each claiming one existing player profile.
const COMMITTEE_EMAIL = 'padel@yorksu.org';

export function initAuth(sb, onSessionChange) {
  sb.auth.onAuthStateChange((_event, session) => onSessionChange(session));
  return sb.auth.getSession().then(({ data }) => data.session);
}

export function isCommitteeSession(session) {
  return !!(session && session.user && session.user.email === COMMITTEE_EMAIL);
}

export async function signInCommittee(sb, password) {
  const { error } = await sb.auth.signInWithPassword({ email: COMMITTEE_EMAIL, password });
  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

export async function signUpMember(sb, email, password) {
  const { error } = await sb.auth.signUp({ email, password });
  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

export async function signInMember(sb, email, password) {
  const { error } = await sb.auth.signInWithPassword({ email, password });
  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

export async function signOut(sb) {
  await sb.auth.signOut();
}
