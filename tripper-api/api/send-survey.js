// trip-api/api/send-survey.js
export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ message: 'Method not allowed' });
  }

  const { email, token } = req.body;

  if (!email || !token) {
    return res.status(400).json({ message: 'Missing email or token' });
  }

  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer YOUR_RESEND_API_KEY`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'TripCliques <you@yourdomain.com>',
        to: [email],
        subject: 'Trip Survey Invite',
        html: `<p>Click here to fill out your travel survey: <a href="https://yourapp.com/survey?token=${token}">Complete Survey</a></p>`,
      }),
    });

    if (!response.ok) {
      return res.status(500).json({ message: 'Resend error' });
    }

    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ message: 'Internal server error', error });
  }
}
