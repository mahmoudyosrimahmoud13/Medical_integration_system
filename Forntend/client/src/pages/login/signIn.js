import { useState } from "react";
import { useNavigate } from 'react-router-dom';
import sLS from 'react-secure-storage';
import Image from '../../photos/Free Vector _ Detailed doctors and nurses illustration.jpg';
import Swal from 'sweetalert2';

const SignIn = () => {
    const [userName, setUserName] = useState('');
    const [password, setPassword] = useState('');
    const [errorMsg, setErrorMsg] = useState(null);
    const [userToken, setUserToken] = useState(null);

    const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[_#$^+=!*()@%&])[A-Za-z\d_#$^+=!*()@%&]{8,}$/;

    const navigate = useNavigate();

    const toggleForm = () => {
        document.querySelector('.container').classList.toggle('active');
    }

    const submit = async (e) => {
        e.preventDefault();
        setErrorMsg(null);

        if (!userName || !password) {
            setErrorMsg("Username and Password cannot be empty");
            return;
        }

        if (!regex.test(password)) {
            setErrorMsg("Password must be at least 8 characters long and include uppercase, lowercase, number, and special character");
            return;
        }

        try {
            const res = await fetch('http://localhost:5225/Auth/Login', {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ userName, password })
            });

            const loginToken = await res.json();

            if (!res.ok) {
                setErrorMsg(loginToken.message);
                return;
            }

            if (loginToken.isLogin) {
                const tokenString = JSON.stringify(loginToken);
                sLS.setItem('usertoken', tokenString);
                setUserToken(JSON.parse(tokenString));

                if (loginToken.roles && loginToken.roles[0]) {
                    const role = loginToken.roles[0];
                    if (role === "Doctor") {
                        navigate('/doctor');
                    } else if (role === "Patient") {
                        navigate('/settings');
                    } else if (role === "Admin") {
                        navigate('/applicants');
                    }
                }

                Swal.fire({
                    position: "top",
                    icon: "success",
                    title: "Successful Login",
                    showConfirmButton: false,
                    timer: 1500
                });

                setUserName('');
                setPassword('');
            } else {
                setErrorMsg(loginToken.message);
            }

        } catch (error) {
            setErrorMsg("An error occurred during login. Please try again.");
        }
    }

    return (
        <>
            <div className="user signinBx">
                <div className="imgBx"><img src={Image} alt="Not Found" /></div>
                <div className="formBx">
                    <form onSubmit={submit}>
                        <h1>Log In</h1>
                        <div className="form__group field">
                            <input 
                                type="text" 
                                name="UN" 
                                className="form__field" 
                                placeholder="Username or Email" 
                                value={userName}
                                onChange={(e) => setUserName(e.target.value)} 
                            />
                            <label htmlFor="un" className="form__label">Email</label>
                        </div>
                        <div className="form__group field">
                            <input 
                                type="password" 
                                name="PSS" 
                                className="form__field2" 
                                placeholder="Password" 
                                value={password}
                                onChange={(e) => setPassword(e.target.value)} 
                            />
                            <label htmlFor="pss" className="form__label2">Password</label>
                        </div>
                        {errorMsg && <div className="form__group field">
                            <p id="errMsg"><span id="sp">* </span>{errorMsg}</p>
                        </div>}
                        <input type="submit" value="Login" id="l" className="send" />
                        <p className="signup">Don't have an account? <a href="#register" id="reg" onClick={toggleForm}>Register</a></p>
                    </form>
                </div>
            </div>
        </>
    );
}

export default SignIn;
