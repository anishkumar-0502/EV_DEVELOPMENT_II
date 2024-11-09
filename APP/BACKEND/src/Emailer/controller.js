const nodemailer = require('nodemailer');

// Create a transporter object
let transporter = nodemailer.createTransport({
  host: 'smtppro.zoho.in', // replace with your SMTP server
  port: 465, // 465 for SSL or 587 for TLS
  secure: true, // true for SSL, false for TLS
  auth: {
    user: 'vivek@outdidtech.com', // your email
    pass: 'vivek30091998.', // your email password
  },
});

// Function to send email
async function sendEmail(to, subject, text) {
  try {
    // Define email options
    let info = await transporter.sendMail({
      from: '"EV POWER" <vivek@outdidtech.com>', // sender address
      to: to, // list of receivers
      subject: subject, // Subject line
      text: text, // plain text body
      html: `<p>${text}</p>`, // HTML body
    });

    console.log('Message sent: %s', info.messageId);
    return true;
  } catch (error) {
    console.error('Error sending email:', error);
    return false;
  }
}

async function EmailConfig(email,otp){
    try{
        let sendTo = email;
        let mail_subject = 'EV POWER - FORGET PASSWORD OTP';
        let mail_body = `
            <html>
                <head>
                    <style>
                        body {
                            font-family: Arial, sans-serif;
                            margin: 0;
                            padding: 20px;
                            background-color: #f4f4f4;
                        }
                        .container {
                            background-color: #ffffff;
                            border-radius: 8px;
                            padding: 20px;
                            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
                        }
                        h2 {
                            color: #333;
                        }
                        p {
                            color: #555;
                            line-height: 1.6;
                        }
                        .otp {
                            font-weight: bold;
                            font-size: 1.2em;
                            color: #007BFF; /* Bootstrap primary color */
                            background-color: #e9f5ff; /* Light background for the OTP */
                            padding: 10px;
                            border-radius: 4px;
                            display: inline-block;
                        }
                        .footer {
                            margin-top: 20px;
                            font-size: 0.9em;
                            color: #888;
                        }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h2>Hello ${email},</h2>
                        <p>We received a request to reset your password. Please use the following One-Time Password (OTP) to proceed with the password reset process:</p>
                        <p>Your OTP is: <span class="otp">${otp}</span></p>
                        <p class="footer">Thank you,<br>EV POWER</p>
                    </div>
                </body>
            </html>
        `;
        
        const result = await sendEmail(sendTo, mail_subject, mail_body);
        return result;

    }catch(error){
        console.error('Error sending email:', error);
        return false;
    }
}

module.exports = {EmailConfig}