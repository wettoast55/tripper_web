const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { Resend } = require('resend');

const app = express();
const resend = new Resend('REPLACE_WITH_YOUR_API_KEY'); // Get from resend.com

app.use(cors());
app.use(bodyParser.json());

app.post('/send-survey', async (req, res) => {
  const { email, token } = req.body;

  if (!email || !token) {
    return res.status(400).json({ error: 'Missing email or token' });
  }

  try {
    await resend.emails.send({
      from: 'your@email.com',
      to: email,
      subject: 'You are invited to a Trip!',
      html: `<p>Please fill out this quick survey: <a href="https://yourapp.com/survey?token=${token}">Click here</a></p>`,
    });
    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Failed to send email', details: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
