const database = require('../../db');
const EmailController = require("../Emailer/controller.js")

const authenticate = async (req) => {
    try {
        const { email_id, password } = req.body;
        // Check if email or password is missing
        if (!email_id || !password) {
            return { error: true, status: 401, message: 'required data not found' };
        }

        const db = await database.connectToDatabase();
        const usersCollection = db.collection('users');

        // Query to get user by email with the role
        const userWithRole = await usersCollection.aggregate([
            { $match: { email_id: email_id, status: true, role_id: 5 } }, // Check user status
            {
                $lookup: {
                    from: 'user_roles',
                    localField: 'role_id',
                    foreignField: 'role_id',
                    as: 'roles'
                }
            },
            { $unwind: '$roles' },
            //{ $match: { 'roles.status': true } }, // Check role status
            { $limit: 1 }
        ]).toArray();

        if (userWithRole.length === 0) {
            return { error: true, status: 401, message: 'Invalid credentials or inactive user/role' };
        }

        const user = userWithRole[0];

        // Ensure both passwords are treated as strings
        //const passwordString = password.toString();
        //const userPasswordString = user.password.toString();

        // Verify the password
        //const passwordMatch = await bcrypt.compare(passwordString, userPasswordString);
        const passwordMatch = (parseInt(password) === user.password);
        if (!passwordMatch) {
            return { error: true, status: 401, message: 'Invalid credentials' };
        }

        // Return user_id and email_id
        return { error: false, user: { user_id: user.user_id, username: user.username, email_id: user.email_id } };

    } catch (error) {
        console.error(error);
        return { error: true, status: 500, message: 'Internal Server Error' };
    }
};

const registerUser = async (req, res, next) => {
    try {
        const { username, password, phone_no, email_id } = req.body;
        if (!username || !password || !phone_no || !email_id) {
            const errorMessage = 'Register - Values undefined';
            return res.status(401).json({ message: errorMessage });
        }

        // Ensure password is a string
        //const passwordString = password.toString();

        const db = await database.connectToDatabase();
        const usersCollection = db.collection('users');
        const userRoleCollection = db.collection('user_roles');

        const checkRole = await userRoleCollection.findOne({ role_id: 5});

        if(!checkRole || checkRole.status === false){
            const errorMessage = 'User registration blocked !';
            console.log(errorMessage)
            return res.status(403).json({ message: errorMessage });
        }


        // Check if the username or email is already taken
        const existingUser = await usersCollection.findOne({
            $or: [
                { username: username },
                { email_id: email_id }
            ]
        });

        if (existingUser && existingUser.status === true) {
            const errorMessage = 'Username or email already registered';
            console.log(errorMessage)
            return res.status(403).json({ message: errorMessage });
        }

        if(existingUser){
            if (existingUser.email_id === email_id && existingUser.status === false) {
                await usersCollection.updateOne(
                    { user_id: existingUser.user_id },
                    { 
                        $set: {
                            //username: username,
                            password: parseInt(password),
                            phone_no: parseInt(phone_no),
                            //email_id: email_id,
                            // wallet_bal: 100.00,
                            status: true,
                            modified_by: username,
                            modified_date: new Date()
                        }
                    }
                );
                return res.status(200).json({ message: 'User Registered successfully' });
            }
        }

        // Hash the password
        //const hashedPassword = await bcrypt.hash(passwordString, 10); // 10 is the salt rounds

        // Use aggregation to fetch the highest user_id
        const lastUser = await usersCollection.find().sort({ user_id: -1 }).limit(1).toArray();
        let newUserId = 1; // Default user_id if no users exist
        if (lastUser.length > 0) {
            newUserId = lastUser[0].user_id + 1;
        }

        // Insert the new user into the database with hashed password
        await usersCollection.insertOne({
            role_id: 5,
            reseller_id: null,
            client_id: null,
            association_id: null,
            user_id: newUserId,
            username: username,
            password: parseInt(password),
            phone_no: parseInt(phone_no),
            email_id: email_id,
            wallet_bal: 100.00,
            autostop_price: null,
            autostop_price_is_checked: null,
            autostop_time: null,
            autostop_time_is_checked: null,
            autostop_unit: null,
            autostop_unit_is_checked: null,
            tag_id: null,
            assigned_association: null,
            created_by: username,
            created_date: new Date(),
            modified_by: null,
            modified_date: null,
            status: true
        });

        // Continue with any additional logic or response
        next();

    } catch (error) {
        console.error(error);
        const errorMessage = 'Internal Server Error';
        return res.status(500).json({ message: errorMessage });
    }
};

// initiate forget password - generate otp and send through mail
const intiateForgetPassword = async (req) => {
    try{
        const {email_id} = req.body;

        // Check if email is missing
        if (!email_id) {
            return { error: true, status: 401, message: 'Email ID is required' };
        }

        const db = await database.connectToDatabase();
        const usersCollection = db.collection('users');

        const checkEmailID = await usersCollection.findOne({ email_id: email_id});

        if(!checkEmailID){
            console.error(`Email ID is not found`);
            return { error: true, status: 401, message: 'Email ID is not found' };
        }

        let otp = await generateOTP();
        console.log('Generated OTP:', otp);

        if(otp){
            const updateresult = await usersCollection.updateOne(
                { user_id: checkEmailID.user_id },
                { 
                    $set: {
                        otp: parseInt(otp),
                        otp_generated_at: new Date(),
                        modified_date: new Date(),
                        modified_by: email_id
                    }
                }
            );

            if (updateresult.modifiedCount === 1) {
                const EmailResult = await EmailController.EmailConfig(email_id, otp);
                
                if(EmailResult === true){
                    return { error: false, status: 200, message: 'Email sent successfully' };
                }else{
                    return { error: true, status: 401, message: 'Email is not sent, Please try again !' };
                }
            }else{
                console.error(`OTP is not updated to database`);
                return { error: true, status: 401, message: 'Something went wrong, Please try again !' };
            }

        }else{
            console.error(`OTP is not generated`);
            return { error: true, status: 401, message: 'OTP is not generated, Please try again !' };
        }

    }catch(error){
        console.error(error);
        return { error: true, status: 500, message: 'Internal Server Error' };
    }
}

// Generate a random number between 100000 and 999999
async function generateOTP() {
    return Math.floor(100000 + Math.random() * 900000);
}

// authenticate the otp, reset password
async function authenticateOTP(req){
    try{
        const {email_id, otp} = req.body;

        // Check if otp & email id is missing
        if (!otp) {
            return { error: true, status: 401, message: 'OTP is required' };
        }else if(!email_id){
            return { error: true, status: 401, message: 'Email ID is required' };
        }

        const db = await database.connectToDatabase();
        const usersCollection = db.collection('users');

        const checkEmailID_OTP = await usersCollection.findOne({ email_id: email_id, otp: parseInt(otp)});

        if(!checkEmailID_OTP){
            console.error(`Email ID / OTP is not found`);
            return { error: true, status: 401, message: 'Email ID / OTP is not found' };
        }else{
            let generated_otp = checkEmailID_OTP.otp;

            if(generated_otp === parseInt(otp)){
                const resetotp = await usersCollection.updateOne(
                    {email_id: email_id},
                    {
                        $set: {
                            otp: null,
                            otp_generated_at: null,
                            modified_date: new Date(),
                            modified_by: email_id
                        }
                    }
                );
                if (resetotp.modifiedCount === 1) {
                    return { error: false, status: 200, message: 'OTP is authenticated successfully.' };
                }else{
                    console.error(`Entered OTP is correct, But database updation is not working please try again`);
                    return { error: true, status: 401, message: 'Something went wrong, Please try again !' }; 
                }
            }else{
                console.error(`Entered OTP is wrong, Please enter valid OTP !`);
                return { error: true, status: 401, message: 'Entered OTP is wrong, Please enter valid OTP !' }; 
            }
        }
    }catch(error){
        console.error(error);
        return { error: true, status: 500, message: 'Internal Server Error' };
    }
}

async function resetPassword(req){
    try{
        const {email_id, NewPassword} = req.body;

        // Check if NewPassword & email id is missing
        if (!NewPassword) {
            return { error: true, status: 401, message: 'New password is required' };
        }else if(!email_id){
            return { error: true, status: 401, message: 'Email ID is required' };
        }

        const db = await database.connectToDatabase();
        const usersCollection = db.collection('users');

        const updateNewPassword = await usersCollection.updateOne(
            {email_id: email_id},
            {
                $set: {
                    password: parseInt(NewPassword),
                    modified_date: new Date(),
                    modified_by: email_id
                }
            }
        );
        if (updateNewPassword.modifiedCount === 1) {
            return { error: false, status: 200, message: 'Password is changed successfully.' };
        }else{
            console.error(`Password is not updated, please try again`);
            return { error: true, status: 401, message: 'Something went wrong, Please try again !' }; 
        }
    }catch(error){
        console.error(error);
        return { error: true, status: 500, message: 'Internal Server Error' };
    }
}

// fetch tag id details for the specific user
async function fetchRFID(req){
    try{
        const { email_id } = req.body;

         // Check if email id is missing
         if (!email_id) {
            return { error: true, status: 401, message: 'Email ID is required' };
        }

        const db = await database.connectToDatabase();
        const usersCollection = db.collection('users');
        const tagIdCollection = db.collection('tag_id');

        const checkEmailID = await usersCollection.findOne({ email_id: email_id});

        if(!checkEmailID){
            console.error(`Email ID is not found`);
            return { error: true, status: 401, message: 'Email ID is not found' };
        }

        const RFID = checkEmailID.tag_id;

        // Check if RFID is null or undefined before querying
        if (!RFID) {
            console.error(`RFID is null`);
            return { error: true, status: 401, message: 'RFID is not assigned yet' };
        }

        const fetchTagID = await tagIdCollection.findOne({ id: RFID});

        if(!fetchTagID){
            console.error(`Tag ID is not found`);
            return { error: true, status: 401, message: 'RFID is not found' };
        }else{
            return { error: false, status: 200, message: fetchTagID };
        }

    }catch(error){
        console.error(error);
        return { error: true, status: 500, message: 'Internal Server Error' };
    }
}

module.exports = { authenticate, registerUser, intiateForgetPassword, authenticateOTP, resetPassword, fetchRFID };
