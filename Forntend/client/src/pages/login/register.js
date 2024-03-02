import { useState } from "react";
import Image from '../../photos/Médicos e enfermeiras detalhados _ Vetor Grátis.jpg';
import flag from '../../photos/egypt.png';
import GovernoratesProps from "../../components/login/governoratesProps";
import AreasProps from "../../components/login/areasProps";
import FetchHook from "../../components/login/fetchHook";

const Register = () => {
    const [selectedGovernorate, setSelectedGovernorate] = useState('');



    const governorates = FetchHook(`http://localhost:5225/Adress/GetGovernorate`);

    const areas = FetchHook(`http://localhost:5225/Adress/GetAreas?GovermentKey=${selectedGovernorate}`);



    // Post Data
    const [name, setValue3] = useState('');
    const [email, setValue4] = useState('');
    const [password, setValue5] = useState('');
    const [passwordConfirm, setValue6] = useState('');

    const [phone, setValue7] = useState('');
    const [birday, setValue8] = useState('');
    const [area, setValue9] = useState('');
    const [gender, setValue10] = useState('');



    const [errorMsg, setErrorMsg] = useState(null);

    const toggleForm = () => {
        var cnt = document.querySelector('.container');
        cnt.classList.toggle('active');
    }


    // Register
    const register = (e2) => {
        let sp = document.getElementById("sp2");

        e2.preventDefault();
        
        const formData = new FormData();
        const input = {
            name: name,
            email: email,
            password: password,
            passwordConfirm: passwordConfirm,
            phone: phone,
            birday: birday,
            area: area,
            gender: gender,
        };
        formData.append("input", JSON.stringify(input));
        if (password !== passwordConfirm) {
            sp.style.visibility = "visible";
            setErrorMsg("Password and confirm password do not match");
            return;
        }
        const fetchData = async () => {
            try {
                const res = await fetch('http://localhost:5225/Auth/Register', {
                    method: "POST",
                    body: formData
                });

                const errorData = await res.json();
                if (!res.ok) {
                    sp.style.visibility = "visible";
                    throw new Error("Must fill inputs");
                }
                else if(res.ok){
                    if(errorData.message === "Go To Login Page"){
                        sp.style.visibility = "hidden";
                        // setErrorMsg(errorData);
                        window.location.reload();
                    }
                    else{
                        sp.style.visibility = "visible";
                        throw new Error(errorData.message);
                    }
                }
                else{
                    throw new Error(errorData.message);
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
            <div className="user singupBx">
                <div className="formBx">
                    <form onSubmit={register}>
                        <h1>create a new account</h1>
                        <div className="form__group field">
                            <input type="text" name="UNR" className="form__field3" placeholder="Username" onChange={(e) => setValue3(e.target.value)} />
                            <label htmlFor="unr" className="form__label3">username</label>
                        </div>
                        <div className="form__group field">
                            <input type="email" name="EM" className="form__field4" placeholder="Email" onChange={(e) => setValue4(e.target.value)} />
                            <label htmlFor="em" className="form__label4">email</label>
                        </div>
                        <div className="form__group field">
                            <input type="password" name="PSSR" className="form__field5" placeholder="Password" onChange={(e) => setValue5(e.target.value)} />
                            <label htmlFor="pssr" className="form__label5">password</label>
                        </div>
                        <div className="form__group field">
                            <input type="password" name="CPSS" className="form__field6" placeholder="Confirm Password" onChange={(e) => setValue6(e.target.value)} />
                            <label htmlFor="cpss" className="form__label6">confirm password</label>
                        </div>
                        
                        <div className="form__group field">
                            <input type="number" name="TEL" className="form__field7" placeholder="Phone" onChange={(e) => setValue7(e.target.value)} />
                            <label htmlFor="tel" className="form__label7"><img className="eg" src={flag} alt="not found" />+20</label>
                        </div>
                        
                        <div className="form__groupU field">
                            <input className="birthday" type="date" id="birthday" name="birthday" onChange={(e) => setValue8(e.target.value)} />
                            <select id="gender" name="gender" className="selectGender" defaultValue="" onChange={(e) => setValue10(e.target.value)}>
                                        <option value="" disabled>Gender</option>
                                        <option value="true">Male</option>
                                        <option value="false">Female</option>
                            </select>
                        </div>
                        <div className="form__groupF field">
                            {governorates && (
                            <select id="city" name="city" className="selectGov" defaultValue="" onChange={(e) => setSelectedGovernorate(e.target.value)} >
                                <option value="" disabled>Select Your Governorate</option>
                                <GovernoratesProps governorates={governorates} />
                            </select>)}
                            {areas && 
                            <select id="area" name="area" className="selectArea" defaultValue="" onChange={(e) => setValue9(e.target.value)} >
                                <option value="" disabled>Select Your Area</option>
                                <AreasProps areas={areas} />
                            </select>}
                        </div>     
                        <div className="form__group field">
                            <p id="errMsg"><span id="sp2">* </span>{errorMsg}</p>
                        </div>
                        <input type="submit" value="Register" id="r" className="send" />
                        <p className="signup" id="already">already have an account ? <a href="#5545" onClick={ () => toggleForm()}>login</a></p> 
                    </form>
                </div>
                <div className="imgBx"><img src={Image} alt="not found" /></div>
            </div>
        </>
    );
}

export default Register;