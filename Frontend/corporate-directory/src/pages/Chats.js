import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';
import authService from '../services/authService';

function Chats() {
    const userData = authService.getCurrentUser();
    const user = userData ? userData.user : null;
    const [chats, setChats] = useState([]);
    const [selectedChat, setSelectedChat] = useState(null);
    const [messages, setMessages] = useState([]);
    const [newMessage, setNewMessage] = useState('');
    const [error, setError] = useState('');

    useEffect(() => {
        const fetchChats = async () => {
            try {
                const response = await apiService.getChats(user.id_employee);
                setChats(response.data);
            } catch (err) {
                console.error(err);
                setError('Ошибка получения чатов');
            }
        };
        if (user) {
            fetchChats();
        }
    }, [user]);

    useEffect(() => {
        let interval;
        if (selectedChat) {
            const fetchMessages = async () => {
                try {
                    const response = await apiService.getMessages(selectedChat.id_group_chat);
                    setMessages(response.data);
                } catch (err) {
                    console.error(err);
                    setError('Ошибка получения сообщений');
                }
            };

            fetchMessages();

            interval = setInterval(fetchMessages, 5000); // Обновление каждые 5 секунд
        }
        return () => clearInterval(interval);
    }, [selectedChat]);

    const selectChat = (chat) => {
        setSelectedChat(chat);
    };

    const handleSendMessage = async () => {
        if (!newMessage) return;
        try {
            await apiService.sendMessage(selectedChat.id_group_chat, newMessage);
            setNewMessage('');
            // Обновление списка сообщений
            const response = await apiService.getMessages(selectedChat.id_group_chat);
            setMessages(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка отправки сообщения');
        }
    };

    const handleMarkAsRead = async (messageId) => {
        try {
            await apiService.markMessageAsRead(messageId);
            // Обновление списка сообщений
            const response = await apiService.getMessages(selectedChat.id_group_chat);
            setMessages(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка отметки сообщения');
        }
    };

    return (
        <div style={{ display: 'flex' }}>
            <div style={{ width: '30%', borderRight: '1px solid black', padding: '10px' }}>
                <h3>Список чатов</h3>
                {error && <p style={{ color: 'red' }}>{error}</p>}
                <ul>
                    {chats.map(chat => (
                        <li
                            key={chat.id_group_chat}
                            onClick={() => selectChat(chat)}
                            style={{ cursor: 'pointer', marginBottom: '5px' }}
                        >
                            {chat.name}
                        </li>
                    ))}
                </ul>
            </div>
            <div style={{ width: '70%', padding: '10px' }}>
                {selectedChat ? (
                    <>
                        <h3>Чат: {selectedChat.name}</h3>
                        <div style={{
                            height: '400px',
                            overflowY: 'scroll',
                            border: '1px solid gray',
                            padding: '10px',
                            marginBottom: '10px'
                        }}>
                            {messages.map(msg => (
                                <div
                                    key={msg.id_group_message}
                                    style={{
                                        marginBottom: '10px',
                                        backgroundColor: msg.id_sender === user.id_employee ? '#DCF8C6' : '#FFF',
                                        padding: '5px',
                                        borderRadius: '5px',
                                        maxWidth: '70%'
                                    }}
                                >
                                    <strong>{msg.full_name}:</strong> {msg.content}
                                    <div style={{ fontSize: '0.8em', color: 'gray' }}>
                                        {new Date(msg.send_time).toLocaleString()}
                                    </div>
                                    {msg.id_read_status === 1 && msg.id_sender !== user.id_employee && (
                                        <button onClick={() => handleMarkAsRead(msg.id_group_message)} style={{ fontSize: '0.7em' }}>
                                            Отметить как прочитанное
                                        </button>
                                    )}
                                </div>
                            ))}
                        </div>
                        <div style={{ display: 'flex' }}>
                            <input
                                type="text"
                                value={newMessage}
                                onChange={(e) => setNewMessage(e.target.value)}
                                placeholder="Введите сообщение"
                                style={{ flex: 1, padding: '5px' }}
                            />
                            <button onClick={handleSendMessage} style={{ padding: '5px 10px', marginLeft: '5px' }}>
                                Отправить
                            </button>
                        </div>
                    </>
                ) : (
                    <p>Выберите чат</p>
                )}
            </div>
        </div>
    );
}

export default Chats;