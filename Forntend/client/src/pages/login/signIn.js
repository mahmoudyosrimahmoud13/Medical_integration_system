import { useState } from "react";
import { useNavigate } from 'react-router-dom';
import sLS from 'react-secure-storage';




import Image from '../../photos/Free Vector _ Detailed doctors and nurses illustration.jpg';
import Swal from 'sweetalert2';

const SignIn = () => {
    const [userName, setValue] = useState('');
    const [password, setValue2] = useState('');
    const [errorMsg, setErrorMsg] = useState(null);


    const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[_#$^+=!*()@%&])[A-Za-z\d_#$^+=!*()@%&]{8,}$/;

    const toggleForm = () => {
        var cnt = document.querySelector('.container');
        cnt.classList.toggle('active');
    }
    const data = { userName, password };
    const navigate = useNavigate();
    



    // Login
    const submit = (e) => {
        e.preventDefault();
        let u = document.querySelector("[name='UN']");
        let p = document.querySelector("[name='PSS']");
        let sp = document.getElementById("sp");

        const fetchData = async () => {
            try {
                const res = await fetch('http://localhost:5225/Auth/Login', {
                    method: "POST",
                    headers: {"Content-Type": "application/json"},
                    body: JSON.stringify(data)
                });
                const loginToken = await res.json();

                if (!res.ok) {
                    if(userName.length === 0){
                        u.style.borderBottom = "red solid 1px";
                        sp.style.visibility = "visible";
                        u.focus();
                        if(password.length === 0){
                            p.style.borderBottom = "red solid 1px";
                            throw new Error(loginToken.message.slice(77, )+loginToken.message.slice(6, 26));
                        }
                        throw new Error(loginToken.message.slice(6, ));
                    }
                    if(userName.length !== 0){
                        u.style.borderBottom = "#ccc solid 1px";
                    }
                    if(password.length === 0){
                        if(u.value !== ""){
                            p.focus();
                        }
                        sp.style.visibility = "visible";
                        throw new Error(loginToken.message.slice(6, 26));
                    }
                    if(password.length !== 0){
                        p.style.border = "white solid 1px";
                        if(password.length < 8){
                            sp.style.visibility = "visible";
                            p.style.borderBottom = "red solid 1px";
                            p.focus();
                            throw new Error(loginToken.message.slice(6, 45));
                        }
                        if(regex.test(password) === false){
                            sp.style.visibility = "visible";
                            p.style.borderBottom = "red solid 1px";
                            p.focus();
                            
                            throw new Error(loginToken.message.slice(6, ));
                        }
                        
                        else{
                            console.log("No");
                        }
                    }
                }
                else if(res.ok){
                    u.style.borderBottom = "#ccc solid 1px";
                    p.style.borderBottom = "#ccc solid 1px";
                    if(loginToken.isLogin === true){
                        const userToken = JSON.stringify(loginToken);
                        sLS.setItem('usertoken', userToken);
                    }
                    if(!loginToken.message){
                        Swal.fire({
                            position: "top",
                            icon: "success",
                            title: "Successful Login",
                            showConfirmButton: false,
                            timer: 1500
                        });
                        sp.style.visibility = "hidden";
                        u.value = "";
                        p.value ="";
                        setErrorMsg(null);
                        
                        
                        navigate('/settings');
                    }
                    else{
                        sp.style.visibility = "visible";
                        throw new Error(loginToken.message);
                    }
                }
                
            } 
            catch (error) {
                setErrorMsg(error.message);  
            }
        };
        fetchData();
    }
        
    return (
        <>
            <div className="user singinBx">
                <div className="imgBx"><img src={Image} alt="not found" /></div>
                <div className="formBx">
                    <form onSubmit={submit}>
                        <h1>log in</h1>
                        <div className="form__group field">
                            <input type="text" name="UN" className="form__field" placeholder="Username or Email" onChange={(e) => setValue(e.target.value)} />
                            <label htmlFor="un" className="form__label">email</label>
                        </div>
                        <div className="form__group field">
                            <input type="password" name="PSS" className="form__field2" placeholder="Username or Email" onChange={(e) => setValue2(e.target.value)} />
                            <label htmlFor="pss" className="form__label2">password</label>
                        </div>
                        <div className="form__group field">
                            <p id="errMsg"><span id="sp">* </span>{errorMsg}</p>
                        </div>
                        <input type="submit" value="Login" id="l" className="send" />
                        <p className="signup">don't have an account ? <a href="#register" id="reg" onClick={() => toggleForm()}>register</a></p>
                        

                    </form>
                </div>
            </div>
            
        </>
    );
}
export default SignIn;