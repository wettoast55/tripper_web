const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

const gmailEmail = functions.config().email.user;
const gmailPassword = functions.config().email.pass;

// Configure transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: gmailEmail,
    pass: gmailPassword,
  },
});

// Callable function to send survey email
exports.sendSurveyEmail = functions.https.onCall(async (data, context) => {
  const {email, token} = data;

  if (!email || !token) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing email or token.",
    );
  }

  const surveyLink = `https://yourapp.com/survey?token=${token}`;
  const mailOptions = {
    from: `"TripCliques" <${gmailEmail}>`,
    to: email,
    subject: "You're invited to join a trip!",
    html: `
      <p>Hi there! 🎒</p>
      <p>Your friend invited you to help plan a trip.
      Please fill out this quick survey to share your preferences:</p>
      <p><a href="${surveyLink}">Click here to complete your survey</a></p>
      <p>Thanks,<br/>The TripCliques Team</p>
    `,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log("Email sent: ", info.response);
    return {success: true};
  } catch (error) {
    console.error("Error sending email:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Unable to send email",
    );
  }
});
