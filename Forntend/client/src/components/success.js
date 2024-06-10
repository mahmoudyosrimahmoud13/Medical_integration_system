import icon from '../photos/check-mark.png';


const SuccessfullyMsg = () => {
    return(
            <div className='notif' id='notif'>
                <div className='notifBody'>
                    <img src={icon} alt='not found' />
                    <p className='notifText'>your account has been created successfully!</p>
                </div>
                <div className='notifProg' id='prog'></div>
            </div>
    )
}
export default SuccessfullyMsg;