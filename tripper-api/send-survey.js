// api/send-survey.js (using Vercel serverless function)
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

export default async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method not allowed');

  const { email, token } = req.body;

  try {
    const result = await resend.emails.send({
      from: 'TripCliques <your@domain.com>',
      to: email,
      subject: 'You’ve been invited to a trip!',
      html: `
        <p>You’ve been invited to plan a trip!</p>
        <a href="https://yourapp.com/survey?token=${token}">Complete Survey</a>
      `,
    });

    return res.status(200).json({ success: true, id: result.id });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Failed to send email' });
  }
};
