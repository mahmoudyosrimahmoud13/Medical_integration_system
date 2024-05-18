import { MultiChatSocket, MultiChatWindow, useMultiChatLogic } from 'react-chat-engine-advanced'
import sLS from 'react-secure-storage';

const Chat = () => {
    const userToken = sLS.getItem('usertoken');
    
    const convertToken = JSON.parse(userToken);
    const projectId = '1ed59673-1fd6-46ed-9eb9-56239a6a4f82';
    const secret = 'pass1234';
    const chatP = useMultiChatLogic(projectId, convertToken.username, secret)
    return(
        <div style={{height: '100vh'}}>
            <MultiChatSocket {...chatP} />
            <MultiChatWindow {...chatP} style={{height: '100%'}} />
        </div>
        
    )
}

export default Chat;