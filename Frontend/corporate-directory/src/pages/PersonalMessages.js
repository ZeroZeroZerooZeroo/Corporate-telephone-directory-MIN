import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';
import authService from '../services/authService';

function PersonalMessages() {
    const userData = authService.getCurrentUser();
    const user = userData ? userData.user : null;
    const [selectedUser, setSelectedUser] = useState(null);
    const [users, setUsers] = useState([]);
    const [messages, setMessages] = useState([]);
    const [newMessage, setNewMessage] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        const fetchUsers = async () => {
            try {
                const response = await apiService.getEmployees();
                setUsers(response.data.filter(emp => emp.id_employee !== user.id_employee));
            } catch (err) {
                console.error(err);
                setError('Ошибка получения списка пользователей');
            }
        };
        if (user) {
            fetchUsers();
        }
    }, [user]);

    useEffect(() => {
        let interval;
        const fetchMessages = async () => {
            if (selectedUser) {
                try {
                    setLoading(true);
                    const response = await apiService.getPersonalMessages(selectedUser.id_employee);
                    setMessages(response.data);
                } catch (err) {
                    console.error(err);
                    setError('Ошибка получения сообщений');
                } finally {
                    setLoading(false);
                }
            }
        };

        if (selectedUser) {
            fetchMessages();
            interval = setInterval(fetchMessages, 5000); // Обновление каждые 5 секунд
        }

        return () => clearInterval(interval);
    }, [selectedUser]);

    const handleSendMessage = async () => {
        if (!newMessage.trim() || !selectedUser) return;
        try {
            await apiService.sendPersonalMessage(selectedUser.id_employee, newMessage.trim());
            setNewMessage('');
            // Обновление списка сообщений
            const response = await apiService.getPersonalMessages(selectedUser.id_employee);
            setMessages(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка отправки сообщения');
        }
    };

    const handleMarkAsRead = async (messageId) => {
        try {
            await apiService.markPersonalMessageAsRead(messageId);
            // Обновление списка сообщений после отметки как прочитанного
            const response = await apiService.getPersonalMessages(selectedUser.id_employee);
            setMessages(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка отметки сообщения');
        }
    };

    const selectUser = (user) => {
        setSelectedUser(user);
        setMessages([]);
    };

    return (
        <div style={{ display: 'flex', height: '80vh' }}>
            <div style={{ width: '30%', borderRight: '1px solid black', padding: '10px', overflowY: 'auto' }}>
                <h3>Список пользователей</h3>
                {error && <p style={{ color: 'red' }}>{error}</p>}
                <ul style={{ listStyleType: 'none', padding: 0 }}>
                    {users.map(u => (
                        <li
                            key={u.id_employee}
                            onClick={() => selectUser(u)}
                            style={{cursor: 'pointer', 
                                marginBottom: '10px', 
                                padding: '10px', 
                                backgroundColor: selectedUser && selectedUser.id_employee === u.id_employee ? '#f0f0f0' : '#fff',
                                borderRadius: '5px'
                            }}
                        >
                            <strong>{u.full_name}</strong>
                            <p>Email: {u.email}</p>
                        </li>
                    ))}
                </ul>
            </div>
            <div style={{ width: '70%', padding: '10px', display: 'flex', flexDirection: 'column' }}>
                {selectedUser ? (
                    <>
                        <h3>Личные сообщения с: {selectedUser.full_name}</h3>
                        {loading ? (
                            <p>Загрузка сообщений...</p>
                        ) : (
                            <div style={{
                                flex: 1,
                                overflowY: 'scroll',
                                border: '1px solid gray',
                                padding: '10px',
                                marginBottom: '10px',
                                borderRadius: '5px',
                                backgroundColor: '#fafafa',
                                display: 'flex',
                                flexDirection: 'column'
                            }}>
                                {messages.map(msg => (
                                    <div
                                        key={msg.id_message}
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
                                        {msg.id_read_status === 1 && msg.id_sender !== user.id_employee && (
                                            <button 
                                                onClick={() => handleMarkAsRead(msg.id_message)} 
                                                style={{ 
                                                    fontSize: '0.7em', 
                                                    marginTop: '5px', 
                                                    padding: '2px 5px',
                                                    cursor: 'pointer' 
                                                }}
                                            >
                                                Отметить как прочитанное
                                            </button>
                                        )}
                                    </div>
                                ))}
                            </div>
                        )}
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
                    <p>Выберите пользователя слева для просмотра личных сообщений</p>
                )}
            </div>
        </div>
    );
}

export default PersonalMessages;