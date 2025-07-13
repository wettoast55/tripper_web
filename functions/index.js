/**
 * Import function triggers from their respective submodules:
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
  */

// const {setGlobalOptions} = require("firebase-functions");
// const {onRequest} = require("firebase-functions/https");
// const logger = require("firebase-functions/logger");

const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

// prevents "Too many instances" error
// This is useful when you have multiple functions that can be triggered simultaneously
setGlobalOptions({ maxInstances: 10 });

// configure transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'your@gmail.com',
    pass: 'your-app-password',
  },
});

// Function to send survey email
// This function is triggered when a user submits their trip preferences
// It sends an email to the user with a link to complete their survey
// The link includes a token that identifies the user and their trip preferences
// The email is sent using nodemailer with Gmail as the service
exports.sendSurveyEmail = functions.https.onCall(async (data, context) => {
  const { email, token } = data;
  const surveyUrl = `https://yourapp.com/survey?id=${token}`;

  await transporter.sendMail({
    from: '"TripCliques" <your@gmail.com>',
    to: email,
    subject: 'Fill out your TripCliques survey!',
    html: `
      <p>Click to complete your trip preferences:</p>
      <a href="${surveyUrl}">Complete Survey</a>
    `,
  });

  return { success: true };
});

