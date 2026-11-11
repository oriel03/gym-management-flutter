// DESACTIVADO (2026-11-03).
// Este endpoint mandaba por email el PIN que le pasaba el cliente: cualquiera
// podía usarlo para enviar emails a quien quisiera desde tu cuenta de Resend.
// La recuperación ahora la hace Supabase Auth (resetPasswordForEmail).
// Se deja respondiendo 410 para no romper la config de vercel.json; borralo
// junto con la sección "builds" cuando migres el deploy a GitHub Actions.
export default function handler(req, res) {
  return res.status(410).json({ error: 'Endpoint retirado' });
}
