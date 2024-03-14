import icon from '../photos/check-mark.png';


const SuccessfullyMsg = () => {
    return(
            <div className='notif' id='notif'>
                <div className='notifBody' id='notifText'>
                    <img src={icon} alt='not found' className='notifIcon' />
                    your account has been created successfully!
                </div>
                <div className='notifProg' id='prog'></div>
            </div>
    )
}
export default SuccessfullyMsg;