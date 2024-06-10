import { useState, useEffect } from "react";

const SelectSpecialtie = ({ onGetSpecialId }) => {
    const [specialties, setData] = useState([]);
    

    const url = `http://localhost:5225/Hospital/Specialties`;
    
    const fetchData = async () => {
        try {
            const res = await fetch(url);
            if (!res.ok) {
                throw Error("Error");
            }
            const data = await res.json();
            setData(data);
        } catch (err) {
            
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    const handleSpecialChange = (event) => {
        const selectedSpecialId = event.target.value;
        onGetSpecialId(selectedSpecialId);
    };

    return(
        <select id="special" name="special" className="selectSearch" defaultValue="" onChange={handleSpecialChange}>
            <option value="" disabled>Select the specialty</option>
            {specialties.map(specialtie => (
                <option key={specialtie.id} value={specialtie.id}>{specialtie.name}</option>
            ))}
        </select>
    );
};

export default SelectSpecialtie;
