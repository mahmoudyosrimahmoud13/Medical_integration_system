import { useState, useEffect } from "react";
import sLS from 'react-secure-storage';
import { useParams, useNavigate, Link } from 'react-router-dom';
import logo from '../../photos/logo1.png';



const Prescription = () => {
    const [diseaseName, setDiseaseName] = useState('');
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);

    const [drugName, setQuery] = useState('');
    const [drugs, setResults] = useState([]);
    const [selectedDrugs, setSelectedDrugs] = useState([]);
    const [repentances, setRepentances] = useState([]);
    const [color, setColor] = useState('red');
    const { email } = useParams();
    const [persistent, setPersistent] = useState();
    const [cured, setCured] = useState();


    const [msg, setmsg] = useState('');
    const [interact, setInteract] = useState('');

    const nv = useNavigate();
    const handleInputChange = (e) => {
        setQuery(e.target.value);
        fetchDrugs(e.target.value);
    };

    const fetchDrugs = async (drugName) => {
        if (drugName.length < 3) {
            setResults([]);
            return;
        }
        try {
            const response = await fetch(`http://localhost:5225/Hospital/Drug/SerchByName?name=${drugName}`);
            const data = await response.json();
            setResults(data);
        } catch (error) {
            console.error('Error fetching drugs:', error);
        }
    };


    const interaction = document.querySelector('.interaction');

    const checkInteraction = async (selectedDrugIds) => {
        try {
            const res = await fetch(`http://localhost:5225/Hospital/Doctor/MedicalSession/CheackDrugsInteraction?PaientEmail=${email}`, {
                method: "POST",
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${convertToken.token}`
                },
                body: JSON.stringify(selectedDrugIds)
            });
            const data = await res.json();
            if (!res.ok) {
                throw new Error('Failed to fetch drug interactions');
            }
            else if(res.ok){
                if(data.impact === true){
                    setInteract(data.interactionResult[0] + ' !');
                    interaction.style.display = 'block';
                }
                else{
                    setInteract('');
                    interaction.style.display = 'none';
                }
            }
        } catch (error) {
            console.error('Error checking drug interactions:', error);
        }
    };
    const handleDrugSelection = (e) => {
        const selectedDrug = drugs.find(drug => drug.id === e.target.value);
        if (selectedDrug && !selectedDrugs.some(drug => drug.drugId === selectedDrug.id)) {
            setSelectedDrugs([...selectedDrugs, { drugId: selectedDrug.id, note: '', repeatCount: '', start: '', end: '' }]);
        }
        const selectedDrugIds = [...selectedDrugs, { drugId: selectedDrug.id }].map(drug => drug.drugId);
        checkInteraction(selectedDrugIds);
    };

    const handleNoteChange = (index, value) => {
        const updatedDrugs = [...selectedDrugs];
        updatedDrugs[index].note = value;
        setSelectedDrugs(updatedDrugs);
    };

    const handleRepeatChange = (index, value) => {
        const updatedDrugs = [...selectedDrugs];
        updatedDrugs[index].repeatCount = value;
        setSelectedDrugs(updatedDrugs);
    };

    
    const handleStartChange = (index, value) => {
        const updatedDrugs = [...selectedDrugs];
        updatedDrugs[index].start = value;
        setSelectedDrugs(updatedDrugs);
    };

    const handleEndChange = (index, value) => {
        const updatedDrugs = [...selectedDrugs];
        updatedDrugs[index].end = value;
        setSelectedDrugs(updatedDrugs);
    };

    const handlePersistentChange = (e) => {
        setPersistent(e.target.value === 'true');
    };

    const handleCuredChange = (e) => {
        setCured(e.target.value === 'true');
    };

    const submit = (e) => {
        e.preventDefault();
        setRepentances(selectedDrugs);

        const data = {
            sessionnote: '',
            diseaseName,
            patientEmail: email,
            repentances: selectedDrugs,
            persistent,
            cured,
            diseasnote: ''
        };

        const fetchData = async () => {
            try {
                const res = await fetch(`http://localhost:5225/Hospital/Doctor/MedicalSession`, {
                    method: "POST",
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${convertToken.token}`
                    },
                    body: JSON.stringify(data)
                });
                if (!res.ok) {
                }
                if (res.ok) {
                    const m = await res.text();
                    if (m === 'Done') {
                        setmsg("session has been ended successfully!");
                        setColor('#143F6B');
                        let notif = document.getElementById('notif');
                        let prog = document.getElementById('prog');
                        let notifText = document.querySelector('.notifText');
                        notifText.innerHTML = 'Successful session ending!';
                        notif.style.animation= 'fade-in 3s linear';
                        prog.style.animation = 'progress 2.5s 0.3s linear';
                        setTimeout(() => {
                            nv('/doctor');
                        }, 3000);
                    } else if (m === 'Added Before' || m === 'The Patient Must Make A Pre-Bookin') {
                        setmsg('this session has been completed before');
                        let go = document.querySelector('.return');
                        go.style.display = 'block';
                    }
                    else if(!persistent && !cured) {
                        setmsg('* fields required');
                    }
                }
            } catch (error) {
                console.error('Error submitting form:', error);
            }
        };
        fetchData();
    };
    const [usersData, setUsersData] = useState('');
    

    const getUserData = async () => {
        try {
            const res = await fetch(`http://localhost:5225/Auth/GetUser?Email=${email}`, {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
            if (!res.ok) {
                throw new Error("No user found");
            }
            const userData = await res.json();
            setUsersData(userData.name);
        } catch (error) {
            console.error('Error fetching user data:', error);
        }
    };
    useEffect(() => {
        getUserData();
    }, []);
    return (
        <form className="prescriptionForm" onSubmit={submit}>
            <div className="logoPr">
                <img src={logo} alt="not found" />
                <h1>starting {usersData}'<span style={{textTransform: 'lowercase'}}>s</span> sission</h1>
            </div>
            
            <div className="rowPrForm">
                <input
                    type="text"
                    value={drugName}
                    onChange={handleInputChange}
                    placeholder="Search for a drug..."
                    className="drugSearch"
                />
                <select onChange={handleDrugSelection} className="drugSelect" required>
                    <option value="">Select a drug...</option>
                    {drugs.map((drug) => (
                        <option key={drug.id} value={drug.id}>{drug.name}</option>
                    ))}
                </select>
            </div>
            <p className="interaction" style={{color: 'red', letterSpacing: '2px', marginBottom: '5%', fontSize: '1rem', fontWeight: 500, display: 'none'}}>{interact}</p>
            {selectedDrugs.map((drug, index) => (
                <div key={index} className="rowPrForm">
                    <h3>Drug {index + 1}: </h3>
                    <div className="labelInput">
                        <label>Drug note</label>
                        <textarea
                            rows={5}
                            cols={30}
                            value={drug.note}
                            onChange={(e) => handleNoteChange(index, e.target.value)}
                        />
                    </div>
                    <div className="labelInput" style={{display: 'flex', flexDirection: 'row', width: '100%'}}>
                        <div style={{display: 'flex', flexDirection: 'column', width: '50%', alignItems: 'center'}}>
                            <label>Starting of treatment</label>
                            <input style={{width: '300px'}} type="datetime-local" value={selectedDrugs[index].start} onChange={(e) => handleStartChange(index, e.target.value)} />
                        </div>
                        <div style={{display: 'flex', flexDirection: 'column', width: '50%', alignItems: 'center'}}>
                        <label>Ending of treatment</label>
                        <input style={{width: '300px'}} type="datetime-local" value={selectedDrugs[index].end} onChange={(e) => handleEndChange(index, e.target.value)} />
                        </div>
                    </div>
                    <div className="labelInputRadio">
                        <label className="radioL">Repeat</label>
                        <div className="radio-buttons-container">
                            <div className="radio-button">
                                <input
                                    name={`repeat-group-${index}`}
                                    id={`radio1-${index}`}
                                    className="radio-button__input"
                                    type="radio"
                                    value="1"
                                    checked={drug.repeatCount === "1"}
                                    onChange={(e) => handleRepeatChange(index, e.target.value)}
                                />
                                <label htmlFor={`radio1-${index}`} className="radio-button__label">
                                    <span className="radio-button__custom"></span>One
                                </label>
                            </div>
                            <div className="radio-button">
                                <input
                                    name={`repeat-group-${index}`}
                                    id={`radio2-${index}`}
                                    className="radio-button__input"
                                    type="radio"
                                    value="2"
                                    checked={drug.repeatCount === "2"}
                                    onChange={(e) => handleRepeatChange(index, e.target.value)}
                                />
                                <label htmlFor={`radio2-${index}`} className="radio-button__label">
                                    <span className="radio-button__custom"></span>Two
                                </label>
                            </div>
                            <div className="radio-button">
                                <input
                                    name={`repeat-group-${index}`}
                                    id={`radio3-${index}`}
                                    className="radio-button__input"
                                    type="radio"
                                    value="3"
                                    checked={drug.repeatCount === "3"}
                                    onChange={(e) => handleRepeatChange(index, e.target.value)}
                                />
                                <label htmlFor={`radio3-${index}`} className="radio-button__label">
                                    <span className="radio-button__custom"></span>Three
                                </label>
                            </div>
                        </div>
                    </div>
                </div>
            ))}
            <div className="rowPrForm">
                <h3>diagnosis: </h3>
                <div className="labelInput">
                    <label>Disease name</label>
                    <input
                        required
                        type="text"
                        onChange={(e) => setDiseaseName(e.target.value)}
                    />
                </div>
                <div className="labelInputRadio">
                    <label className="radioL">Persistent</label>
                    <div className="radio-buttons-container">
                        <div className="radio-button">
                            <input
                                name="persistent-group"
                                id="radio4"
                                className="radio-button__input"
                                type="radio"
                                value="true"
                                checked={persistent === true}
                                onChange={handlePersistentChange}
                            />
                            <label htmlFor="radio4" className="radio-button__label">
                                <span className="radio-button__custom"></span>True
                            </label>
                        </div>
                        <div className="radio-button">
                            <input
                                name="persistent-group"
                                id="radio5"
                                className="radio-button__input"
                                type="radio"
                                value="false"
                                checked={persistent === false}
                                onChange={handlePersistentChange}
                            />
                            <label htmlFor="radio5" className="radio-button__label">
                                <span className="radio-button__custom"></span>False
                            </label>
                        </div>
                    </div>
                </div>
                <div className="labelInputRadio">
                    <label className="radioL">Cured</label>
                    <div className="radio-buttons-container">
                        <div className="radio-button">
                            <input
                                name="cured-group"
                                id="radio6"
                                className="radio-button__input"
                                type="radio"
                                value="true"
                                checked={cured === true}
                                onChange={handleCuredChange}
                            />
                            <label htmlFor="radio6" className="radio-button__label">
                                <span className="radio-button__custom"></span>True
                            </label>
                        </div>
                        <div className="radio-button">
                            <input
                                name="cured-group"
                                id="radio7"
                                className="radio-button__input"
                                type="radio"
                                value="false"
                                checked={cured === false}
                                onChange={handleCuredChange}
                            />
                            <label htmlFor="radio7" className="radio-button__label">
                                <span className="radio-button__custom"></span>False
                            </label>
                        </div>
                    </div>
                </div>
            </div>
            <button  type="submit">save</button>
            <div style={{ color: color, textTransform: 'capitalize', display: 'flex', columnGap: '5px' }}>{msg}<Link to={'/doctor'} className="return">return !</Link></div>
        </form>
    );
};

export default Prescription;
