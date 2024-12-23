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

    const removeDuplicateChats = (chats) => {
        const uniqueChats = [];
        const chatIds = new Set();

        chats.forEach(chat => {
            if (!chatIds.has(chat.id_group_chat)) {
                uniqueChats.push(chat);
                chatIds.add(chat.id_group_chat);
            }
        });

        return uniqueChats;
    };

    useEffect(() => {
        const fetchChats = async () => {
            try {
                const response = await apiService.getChats(user.id_employee);
                console.log('Полученные чаты:', response.data); 
                const uniqueChats = removeDuplicateChats(response.data);
                setChats(uniqueChats);
            } catch (err) {
                console.error('Ошибка при получении чатов:', err);
                setError('Ошибка получения чатов');
            }
        };
        if (user) {
            fetchChats();
        }
    }, [user]);

    useEffect(() => {
        let interval;
        const fetchMessages = async () => {
            if (selectedChat) {
                try {
                    const response = await apiService.getMessages(selectedChat.id_group_chat);
                    setMessages(response.data);
                } catch (err) {
                    console.error(err);
                    setError('Ошибка получения сообщений');
                }
            }
        };

        if (selectedChat) {
            fetchMessages();
            interval = setInterval(fetchMessages, 5000); // Обновление каждые 5 секунд
        }

        return () => clearInterval(interval);
    }, [selectedChat]);

    const selectChat = (chat) => {
        setSelectedChat(chat);
        setMessages([]);
    };

    const handleSendMessage = async () => {
        if (!newMessage.trim()) return;
        try {
            await apiService.sendMessage(selectedChat.id_group_chat, newMessage.trim());
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
        <div style={{ display: 'flex', height: '80vh' }}>
            <div style={{ width: '30%', borderRight: '1px solid black', padding: '10px', overflowY: 'auto' }}>
                <h3>Список чатов</h3>
                {error && <p style={{ color: 'red' }}>{error}</p>}
                <ul style={{ listStyleType: 'none', padding: 0 }}>
                    {chats.map(chat => (
                        <li
                            key={chat.id_group_chat}
                            onClick={() => selectChat(chat)}
                            style={{ 
                                cursor: 'pointer', 
                                marginBottom: '10px', 
                                padding: '10px', 
                                backgroundColor: selectedChat && selectedChat.id_group_chat === chat.id_group_chat ? '#f0f0f0' : '#fff',
                                borderRadius: '5px'
                            }}
                        >
                            <strong>{chat.name}</strong>
                            <p>Создано: {new Date(chat.creation_date).toLocaleDateString()}</p>
                        </li>
                    ))}
                </ul>
            </div>
            <div style={{ width: '70%', padding: '10px', display: 'flex', flexDirection: 'column' }}>
                {selectedChat ? (
                    <>
                        <h3>Чат: {selectedChat.name}</h3>
                        <div style={{
                            flex: 1,
                            overflowY:'scroll',
                            border: '1px solid gray',
                            padding: '10px',
                            marginBottom: '10px',
                            borderRadius: '5px',
                            backgroundColor: '#fafafa'
                        }}>
                            {messages.map(msg => (
                                <div
                                    key={msg.id_group_message}
                                    style={{
                                        marginBottom: '10px',
                                        backgroundColor: msg.id_sender === user.id_employee ? '#DCF8C6' : '#FFF',
                                        padding: '10px',
                                        borderRadius: '10px',
                                        maxWidth: '70%',
                                        alignSelf: msg.id_sender === user.id_employee ? 'flex-end' : 'flex-start',
                                        boxShadow: '0 1px 1px rgba(0,0,0,0.1)'
                                    }}
                                >
                                    <strong>{msg.full_name}</strong>
                                    <p>{msg.content}</p>
                                    <div style={{ fontSize: '0.8em', color: 'gray' }}>
                                        {new Date(msg.send_time).toLocaleString()}
                                    </div>
                                   
                                </div>
                            ))}
                        </div>
                        <div style={{ display: 'flex' }}>
                            <input
                                type="text"
                                value={newMessage}
                                onChange={(e) => setNewMessage(e.target.value)}
                                placeholder="Введите сообщение"
                                style={{ flex: 1, padding: '10px', borderRadius: '5px', border: '1px solid #ccc' }}
                                onKeyDown={(e) => {
                                    if (e.key === 'Enter') {
                                        handleSendMessage();
                                    }
                                }}
                            />
                            <button 
                                onClick={handleSendMessage} 
                                style={{ 
                                    padding: '10px 20px', 
                                    marginLeft: '10px', 
                                    borderRadius: '5px', 
                                    border: 'none', 
                                    backgroundColor: '#28a745', 
                                    color: '#fff',
                                    cursor: 'pointer' 
                                }}
                            >
                                Отправить
                            </button>
                        </div>
                    </>
                ) : (
                    <p>Выберите чат из списка слева</p>
                )}
            </div>
        </div>
    );
}

export default Chats;