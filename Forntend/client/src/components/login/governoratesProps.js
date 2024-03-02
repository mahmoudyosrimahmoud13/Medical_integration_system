import React from 'react';

const GovernoratesProps = (props) => {
    const governorates = props.governorates;
    return (
        <>
            {governorates.map(governorate => (
                <option key={governorate.id}>{governorate.key}</option>
            ))}
        </>
    );
};

export default GovernoratesProps;
