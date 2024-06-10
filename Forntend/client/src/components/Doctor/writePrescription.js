import Prescription from "../../pages/Doctor/prescriptionForm";
import SuccessfullyMsg from "../success";

const WritePriscription = () => {
    return(
        <div className="priscriptionPage">
            <Prescription  />
            <SuccessfullyMsg />
        </div>
    )
}

export default WritePriscription;