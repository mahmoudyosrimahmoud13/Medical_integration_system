import React, { useState } from "react";
import sLS from 'react-secure-storage';
import '@mobiscroll/react/dist/css/mobiscroll.min.css';
import { Datepicker, setOptions } from '@mobiscroll/react';

setOptions({
    theme: 'ios',
    themeVariant: 'light'
});

const Prescription = ({ patientEmail, name }) => {
    const [diseaseName, setDiseaseName] = useState('');
    const userToken = sLS.getItem('usertoken');
    const convertToken = JSON.parse(userToken);

    const [drugName, setQuery] = useState('');
    const [drugs, setResults] = useState([]);
    const [drugId, setDrugId] = useState('');
    const [note, setNote] = useState('');

    const [repeatCount, setRepeatCount] = useState();
    const [start, setStart] = useState('');
    const [end, setEnd] = useState('');
    const [persistent, setPersistent] = useState(); 
    const [cured, setCured] = useState();

    const handleDateTimeChange = (event, inst) => {
        const selectedValues = inst.getVal();
        if (selectedValues && selectedValues.length > 0) {
            setStart(selectedValues[0]); 
            setEnd(selectedValues[1]);
        } else {
            setStart(null);
            setEnd(null);
        }
    };

    const repeat = '';

    const arr = {drugId, note, repeat, repeatCount, start, end};
    const repentances = [arr];
    const sessionnote = '';
    const diseasnote = '';

    const data = {sessionnote, diseaseName, patientEmail, repentances, persistent, cured, diseasnote};

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

    const valueMap = {
        one: 1,
        two: 2,
        three: 3
    };

    const handleRepeatChange = (event) => {
        const stringValue = event.target.value;
        const intValue = valueMap[stringValue];
        setRepeatCount(intValue);
    };

    const handlePersistentChange = (e) => {
        setPersistent(e.target.value === 'true'); 
    };

    const handleCuredChange = (e) => {
        setCured(e.target.value === 'true'); 
    };

    const submit = (e) => {
        e.preventDefault();

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
                }
            } catch (error) {
                console.error('Error submitting form:', error);
            }
        };
        fetchData();
    };
    


    return (
        <form className="prescriptionForm" onSubmit={submit}>
            <h1>Prescription for {name}</h1>
            <div className="rowPrForm">
                <input
                    type="text"
                    value={drugName}
                    onChange={handleInputChange}
                    placeholder="Search for a drug..."
                    className="drugSearch"
                />
                <select onChange={(e) => setDrugId(e.target.value)} className="drugSelect" required>
                    {drugs.map((drug) => (
                        <option key={drug.id} value={drug.id}>{drug.name}</option>
                    ))}
                </select>
            </div>
            <div className="rowPrForm">
                <div className="labelInput">
                    <label>Drug note</label>
                    <textarea
                        rows={5}
                        cols={30}
                        type="text"
                        onChange={(e) => setNote(e.target.value)}
                    />
                </div>
                <div className="labelInput">
                    <label>Duration of treatment</label>
                    <Datepicker
                        controls={['calendar', 'time']}
                        select="range"
                        labelStyle="stacked"
                        inputStyle="outline"
                        placeholder="Please Add your Dates..."
                        onChange={handleDateTimeChange}
                    />
                </div>
                <div className="labelInputRadio">
                    <label className="radioL">Repeat</label>
                    <div className="radio-buttons-container">
                        <div className="radio-button">
                            <input
                                name="repeat-group"
                                id="radio1"
                                className="radio-button__input"
                                type="radio"
                                value="one"
                                checked={repeatCount === 1}
                                onChange={handleRepeatChange}
                            />
                            <label htmlFor="radio1" className="radio-button__label">
                                <span className="radio-button__custom"></span>One
                            </label>
                        </div>
                        <div className="radio-button">
                            <input
                                name="repeat-group"
                                id="radio2"
                                className="radio-button__input"
                                type="radio"
                                value="two"
                                checked={repeatCount === 2}
                                onChange={handleRepeatChange}
                            />
                            <label htmlFor="radio2" className="radio-button__label">
                                <span className="radio-button__custom"></span>Two
                            </label>
                        </div>
                        <div className="radio-button">
                            <input
                                name="repeat-group"
                                id="radio3"
                                className="radio-button__input"
                                type="radio"
                                value="three"
                                checked={repeatCount === 3}
                                onChange={handleRepeatChange}
                            />
                            <label htmlFor="radio3" className="radio-button__label">
                                <span className="radio-button__custom"></span>Three
                            </label>
                        </div>
                    </div>
                </div>
            </div>
            <div className="rowPrForm">
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
            <div className="rowPrForm">
                <button type="submit">Save</button>
            </div>
        </form>
    );
};

export default Prescription;
