import React from 'react';

const Governorates = (props) => {
    const governorates = props.governorates;
    return (
        // <select id="city" name="city" className="selectGov" defaultValue="" required>
        //     <option value="" disabled>Select a City</option>
        <>
            {governorates.map((governorate) => (
                <option key={governorate.id} value={governorate.key}>{governorate.key}</option>
            ))}
        </>
        // </select>
    );
};

export default Governorates;
