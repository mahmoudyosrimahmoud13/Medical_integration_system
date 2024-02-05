import { useState } from "react";
import Image from '../../photos/Free Vector _ Detailed doctors and nurses illustration.jpg';

const SignIn = () => {
    const [userName, setValue] = useState('');
    const [password, setValue2] = useState('');

    const toggleForm = () => {
        var cnt = document.querySelector('.container');
        cnt.classList.toggle('active');
    }


    // validation
    // let confunl = /(\w+@\d*(gmail|yahoo).com$)|(\w+\d+\W+)|(\d+\w+\W+)|(\w+\W+\d+)|(\w+\d+)|(\w+\W+)|\w+/;  // ($ or text + \b) = End
    
    
    // Login
    const submit = (e) => {
        let u = document.querySelector("[name='UN']");
        let p = document.querySelector("[name='PSS']");
        let valid1 =document.querySelector("#valid");
        let valid2 = document.querySelector("#valid2");
        
        let User = false;
        let Pass = false;
        if(u.value !== "")
        {
            User = true;
            u.style.borderBottom = "gray solid 2px";
            valid1.style.visibility = "hidden";
            
        }
        if(u.value === ""){
            u.focus();
            u.style.borderBottom = "red solid 1px";
            valid1.style.visibility = "visible";
            e.preventDefault();
        }

        if(p.value !== "")
        {
            Pass = true;
            p.style.borderBottom = "gray solid 1px";
            valid2.style.visibility = "hidden";
            
        }
        if(p.value === ""){
            Pass = false;
            p.style.borderBottom = "red solid 1px";
            valid2.style.visibility = "visible";
            e.preventDefault();
        }
        if(User === false || Pass === false)
        {
            e.preventDefault();
        }
        if(User === true && Pass === true){
            const data = {userName, password};
                fetch('http://localhost:5225/Auth/Login',  {
                method: "POST",
                headers: {"Content-Type": "application/json"},
                body: JSON.stringify(data)
                })
                .then(() => {
                    console.log("OK");
                })
                .catch(error => {
                    console.error("Error:", error);
                });
        }
        
    }
    return (
        <>
            <div className="user singinBx">
                <div className="imgBx"><img src={Image} alt="not found" /></div>
                <div className="formBx">
                    <form onSubmit={submit}>
                        <h1>log in</h1>
                        <div className="form__group field">
                            <input type="text" name="UN" className="form__field" placeholder="Username or Email" value={userName} onChange={(e) => setValue(e.target.value)} />
                            <label htmlFor="un" className="form__label">username or email</label>
                            <p className="validation" id="valid">* Fill this field with valid data</p>
                        </div>
                        <div className="form__group field">
                            <input type="password" name="PSS" className="form__field2" placeholder="Username or Email" onChange={(e) => setValue2(e.target.value)} />
                            <label htmlFor="pss" className="form__label2">password</label>
                            <p className="validation" id="valid2">* Fill this field with valid data</p>
                        </div>
                        <input type="submit" value="Login" id="l" className="send" />
                        <p className="signup">don't have an account ? <a href="#111" id="reg" onClick={() => toggleForm()}>register</a></p>
                    </form>
                </div>
            </div>
        </>
    );
}
export default SignIn;