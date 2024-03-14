const SpecialtiesProps = (props) => {
    const specialties = props.specialties;
    return (
        <>
            {specialties.map(specialty => (
                <option value={specialty.id} key={specialty.id}>{specialty.name}</option>
            ))}
        </>
    );
}

export default SpecialtiesProps;
