export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Método no permitido' });
  }

  const { email, pin } = req.body;

  if (!email || !pin) {
    return res.status(400).json({ error: 'Faltan datos' });
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ error: 'Email inválido' });
  }

  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'onboarding@resend.dev',
        to: email,
        subject: 'Recuperación de PIN',
        html: `
          <h2>Recuperación de PIN</h2>
          <p>Tu PIN es: <strong>${pin}</strong></p>
          <p>Si no solicitaste esto, ignora este email.</p>
        `
      })
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error('Error al enviar email');
    }

    return res.status(200).json({ success: true });
    
  } catch (error) {
    console.error('Error:', error);
    return res.status(500).json({ error: 'Error al enviar email' });
  }
}