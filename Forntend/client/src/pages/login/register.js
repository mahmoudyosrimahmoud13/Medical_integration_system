import { useState } from "react";
import Image from '../../photos/Médicos e enfermeiras detalhados _ Vetor Grátis.jpg';
import flag from '../../photos/egypt.png';
import Governorates from "./governoratesFetch";
import Areas from "./areasFetch";
import FetchHook from "./fetchHook";

const Register = () => {
    const [selectedGovernorate, setSelectedGovernorate] = useState(null);
    const [selectedArea, setSelectedArea] = useState(null);
    const [phoneNumber, setPhoneNumber] = useState(null);
    const [selectHBD, setHBD] = useState(null);



    const governorates = FetchHook(`http://localhost:5225/Adress/GetGovernorate`);
    const areas = FetchHook(`http://localhost:5225/Adress/GetAreas?GovermentKey=${selectedGovernorate}`);



    // Post Data
    const [userNameR, setValue3] = useState('');
    const [email, setValue4] = useState('');
    const [passwordR, setValue5] = useState('');


    const toggleForm = () => {
        var cnt = document.querySelector('.container');
        cnt.classList.toggle('active');
    }

    // validation
    let confpss = /(\w+\d+\W+)|(\d+\w+\W+)|(\w+\W+\d+)/;
    let confunr = /(\w+\d+\W+)|(\d+\w+\W+)|(\w+\W+\d+)|(\w+\d+)|(\w+\W+)|\w+/;
    let confemail = /(\w+@(gmail|yahoo).com$)/;
    let telNum = 11;

    // Register
    const register = (e2) => {
        let ui = document.querySelector("[name='UNR']");
        let ei = document.querySelector("[name='EM']");
        let pi = document.querySelector("[name='PSSR']");
        let pci = document.querySelector("[name='CPSS']");
        let tel = document.querySelector("[name='TEL']");


        let validR1 =document.querySelector("#validR");
        let validR2 = document.querySelector("#validR2");
        let validR3 = document.querySelector("#validR3");
        let validR4 = document.querySelector("#validR4");
        let validR5 = document.querySelector("#validR5");
        let validR6 = document.querySelector("#validR6");
        let validR7 = document.querySelector("#validR7");

        let usv = false;
        let emv = false;
        let pssv = false;
        let psscv = false;
        let telv = false;


        if(ui.value !== "")
        {
            usv = true;
            ui.style.borderBottom = "gray solid 1px";
            validR1.style.visibility = "hidden";
            if(confunr.test(ui.value) === false || ui.value.match(/^\d+/)){         // (^ or \b + text) = Start
                usv = false;
                e2.preventDefault();
                ui.style.borderBottom = "red solid 1px";
                validR1.style.visibility = "visible";
            }
            if(ui.value.match(/\s+/g)){
            }
        }
        if(ui.value === ""){
            usv = false;
            ui.focus();
            ui.style.borderBottom = "red solid 1px";
            validR1.style.visibility = "visible";
            e2.preventDefault();
        }

        if(ei.value !== "")
        {
            emv = true;
            ei.style.border = "white solid 1px";
            validR2.style.visibility = "hidden";
            if(confemail.test(ei.value) === false || ei.value.match(/^\d+/)){         // (^ or \b + text) = Start
                emv = false;
                e2.preventDefault();
                ei.style.borderBottom = "red solid 1px";
                validR2.style.visibility = "visible";
                ei.focus();
            }
            if(ei.value.match(/\s+/g)){
            }
        }
        if(ei.value === ""){
            if(ui.value !== ""){
                ei.focus();
            }
            emv = false;
            ei.style.borderBottom = "red solid 1px";
            validR2.style.visibility = "visible";
            e2.preventDefault();
        }

        if(pi.value !== "")
        {
            pssv = true;
            pi.style.border = "white solid 1px";
            validR3.style.visibility = "hidden";
            validR4.style.visibility = "hidden";
            if(pi.value.length < 8){
                pssv = false;
                e2.preventDefault();
                validR4.style.visibility = "visible";
                pi.style.borderBottom = "red solid 1px";
                pi.focus();
            }
            if(confpss.test(pi.value) === false){
                pssv = false;
                e2.preventDefault();
                pi.style.borderBottom = "red solid 1px";
                validR3.style.visibility = "visible";
                validR3.innerHTML = "symbols, numbers and letters";
                pi.focus();
            }
        }
        if(pi.value === ""){
            if(ui.value !== "" && ei.value !== ""){
                pi.focus();
            }
            pssv = false;
            pi.style.borderBottom = "red solid 1px";
            validR3.style.visibility = "visible";
            e2.preventDefault();
        }

        if(pci.value !== "" && pci.value === pi.value)
        {
            psscv = true;
            pci.style.borderBottom = "gray solid 1px";
            validR5.style.visibility = "hidden";
            if(ui.value !== "" && ei.value !== "" && pi.value !== "" && pi.value > 8){
                pci.focus();
            }
        }
        if(pci.value === ""){
            psscv = false;
            pci.style.borderBottom = "red solid 1px";
            validR5.style.visibility = "visible";
            e2.preventDefault();
        }
        if(pci.value !== pi.value){
            psscv = false;
            pci.style.borderBottom = "red solid 1px";
            validR5.style.visibility = "visible";
            validR5.innerHTML = "Must equal password";
            e2.preventDefault();
            pci.focus();
        }
        if(tel.value !== "")
        {
            telv = true;
            tel.style.border = "white solid 1px";
            validR6.style.visibility = "hidden";
            validR7.style.visibility = "hidden";
            if(tel.value.length < telNum || tel.value.length > telNum){
                telv = false;
                e2.preventDefault();
                validR7.style.visibility = "visible";
                tel.style.borderBottom = "red solid 1px";
                tel.focus();
            }
        }
        if(tel.value === ""){
            telv = false;
            tel.style.borderBottom = "red solid 1px";
            validR6.style.visibility = "visible";
            e2.preventDefault();
        }
        if(usv === false || emv === false || pssv === false || psscv === false || telv === false)
        {
            e2.preventDefault();
        }
        if(usv === true && emv === true && pssv === true && psscv === true && telv === true){
            const data = {userNameR, email, passwordR, phoneNumber, selectHBD, selectedArea};
                fetch('http://localhost:5225/Auth/Register',  {
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
            console.log(data);
        }
    }
    return (
        <>
            <div className="user singupBx">
                <div className="formBx">
                    <form onSubmit={register}>
                        <h1>create a new account</h1>
                        <div className="form__group field">
                            <input type="text" name="UNR" className="form__field3" placeholder="Username" value={userNameR} onChange={(e) => setValue3(e.target.value)} />
                            <label htmlFor="unr" className="form__label3">username</label>
                            <p className="validation" id="validR">* Fill this field with valid data</p>
                        </div>
                        <div className="form__group field">
                            <input type="email" name="EM" className="form__field4" placeholder="Email" value={email} onChange={(e) => setValue4(e.target.value)} />
                            <label htmlFor="em" className="form__label4">email</label>
                            <p className="validation" id="validR2">* Fill this field with valid data</p>
                        </div>
                        <div className="form__group field">
                            <p className="max" id="validR4">* Minimum 8 character</p>
                            <input type="password" name="PSSR" className="form__field5" placeholder="Password" value={passwordR} onChange={(e) => setValue5(e.target.value)} />
                            <label htmlFor="pssr" className="form__label5">password</label>
                            <p className="validation" id="validR3">* Fill this field with valid data</p>
                        </div>
                        <div className="form__group field">
                            <input type="password" name="CPSS" className="form__field6" placeholder="Confirm Password" />
                            <label htmlFor="cpss" className="form__label6">confirm password</label>
                            <p className="validation" id="validR5">* Fill this field with valid data</p>
                        </div>
                        <div className="form__group field">
                            <p className="max" id="validR7">* Must be 11 numbers</p>
                            <input type="number" name="TEL" className="form__field7" placeholder="Confirm Password" onChange={(e) => setPhoneNumber(e.target.value)} />
                            <label htmlFor="tel" className="form__label7"><img className="eg" src={flag} alt="not found" />+20</label>
                            <p className="validation" id="validR6">* Fill this field with valid data</p>
                        </div>
                        
                        <div className="form__groupU field">
                            <input className="birthday" type="date" id="birthday" name="birthday" onChange={(e) => setHBD(e.target.value)} required />
                            <select id="gender" name="gender" className="selectGender" defaultValue="" required>
                                        <option value="" disabled>Gender</option>
                                        <option value="male">Male</option>
                                        <option value="female">Female</option>
                                        <option value="other">Other</option>
                            </select>
                        </div>
                        <div className="form__groupF field">
                            {governorates && 
                            <select id="city" name="city" className="selectGov" defaultValue="" onChange={(e) => setSelectedGovernorate(e.target.value)} required>
                                <option value="" disabled>Select a City</option>
                                <Governorates governorates={governorates} />
                            </select>}
                            {areas && 
                            <select id="area" name="area" className="selectArea" defaultValue="" onChange={(e) => setSelectedArea(e.target.value)} required>
                                <option value="" disabled>Select an Area</option>
                                <Areas areas={areas} />
                            </select>}
                        </div>
                        <input type="submit" value="Register" id="r" className="send" />
                        <p className="signup" id="already">already have an account ? <a href="#222" onClick={ () => toggleForm()}>login</a></p> 
                    </form>
                </div>
                <div className="imgBx"><img src={Image} alt="not found" /></div>
            </div>
        </>
    );
}

export default Register;