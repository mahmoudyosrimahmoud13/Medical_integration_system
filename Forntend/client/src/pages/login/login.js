import SignIn from "./signIn";
import SignUp from "./signUp";
import SuccessfullyMsg from "../../components/success";


const Login = () => {
    return (
        <section className="login">
            <div className="container">
                <SignIn />
                <SignUp />
            </div>
            <SuccessfullyMsg />
        </section>
    );
}
export default Login;