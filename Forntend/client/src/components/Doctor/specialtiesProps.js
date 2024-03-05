const SpecialtiesProps = (props) => {
    const specialties = props.specialties;
    return (
        <>
            {specialties.map(specialty => (
                <option key={specialty.id}>{specialty.key}</option>
            ))}
        </>
    );
}

export default SpecialtiesProps;
