import { useState, useEffect } from "react";
import sLS from 'react-secure-storage';

const SelectArea = ({ onGetAreaId }) => {
    const [areas, setData] = useState([]);
    const token = sLS.getItem('usertoken');
    const convertToken = JSON.parse(token);

    const url = `http://localhost:5225/Adress/GetAreas?GovermentKey=${convertToken.gove}`;
    
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

    const handleAreaChange = (event) => {
        const selectedAreaId = event.target.value;
        onGetAreaId(selectedAreaId);
    };

    return(
        <select id="area" name="area" className="selectSearch" defaultValue="" onChange={handleAreaChange}>
            <option value="" disabled>Select the area</option>
            {areas.map(area => (
                <option key={area.id} value={area.id}>{area.key}</option>
            ))}
        </select>
    );
};

export default SelectArea;
