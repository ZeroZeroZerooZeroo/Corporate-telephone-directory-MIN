import React, { useEffect, useState } from 'react';
import apiService from '../../services/apiService';

function ChatsManagement() {
    const [chats, setChats] = useState([]);
    const [employees, setEmployees] = useState([]);
    const [selectedChat, setSelectedChat] = useState(null);
    const [selectedEmployees, setSelectedEmployees] = useState([]);
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');

    useEffect(() => {
        fetchChats();
        fetchEmployees();
    }, []);

    const fetchChats = async () => {
        try {
            const response = await apiService.getChats();
            console.log('Chats from API:', response.data);

            // Удаление дубликатов по id_group_chat
            const uniqueChats = Array.from(
                new Map(response.data.map(chat => [chat.id_group_chat, chat])).values()
            );
            setChats(uniqueChats);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения чатов');
        }
    };

    const fetchEmployees = async () => {
        try {
            const response = await apiService.getEmployees();
            setEmployees(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения сотрудников');
        }
    };

    const handleAddEmployeesToChat = async () => {
        if (!selectedChat) {
            setError('Выберите чат');
            return;
        }
        if (selectedEmployees.length === 0) {
            setError('Выберите сотрудников для добавления');
            return;
        }
        try {
            await apiService.addEmployeesToChat(selectedChat.id_group_chat, selectedEmployees);
            setMessage('Сотрудники успешно добавлены в чат');
            setSelectedEmployees([]);
            fetchChats();
        } catch (err) {
            console.error(err);
            setError('Ошибка добавления сотрудников в чат');
        }
    };

    const handleChatSelect = (chat) => {
        setSelectedChat(chat);
        setMessage('');
        setError('');
    };

    const handleEmployeeSelect = (e) => {
        const options = e.target.options;
        const selected = [];
        for (let i = 0; i < options.length; i++) {
            if (options[i].selected) {
                selected.push(parseInt(options[i].value, 10));
            }
        }
        setSelectedEmployees(selected);
    };

    return (
        <div style={styles.container}>
            <h3>Управление Чатами</h3>
            {error && <p className="error">{error}</p>}
            {message && <p className="success">{message}</p>}

            {/* Список чатов */}
            <div style={styles.chatList}>
                <h4>Список Чатов</h4>
                <ul style={styles.ul}>
                    {chats.map(chat => (
                        <li
                            key={chat.id_group_chat} // Убедитесь, что id_group_chat уникален
                            onClick={() => handleChatSelect(chat)}
                            style={{
                                ...styles.chatItem,
                                backgroundColor: selectedChat && selectedChat.id_group_chat === chat.id_group_chat ? '#e0f7fa' : '#ffffff'
                            }}
                        >
                            <strong>{chat.name}</strong>
                            <p>Создано: {new Date(chat.creation_date).toLocaleDateString()}</p>
                        </li>
                    ))}
                </ul>
            </div>

            {/* Форма добавления сотрудников в чат */}
            {selectedChat && (
                <div style={styles.addForm}>
                    <h4>Добавить сотрудников в чат: {selectedChat.name}</h4>
                    <select multiple
                        value={selectedEmployees}
                        onChange={handleEmployeeSelect}
                        style={styles.select}
                    >
                        {employees.map(emp => (
                            <option key={emp.id_employee} value={emp.id_employee}>
                                {emp.full_name} (ID: {emp.id_employee})
                            </option>
                        ))}
                    </select>
                    <button onClick={handleAddEmployeesToChat} style={styles.button}>
                        Добавить
                    </button>
                </div>
            )}
        </div>
    );
}

const styles = {
    container: {
        padding: '20px',
    },
    chatList: {
        marginBottom: '30px',
    },
    ul: {
        listStyleType: 'none',
        padding: 0,
    },
    chatItem: {
        cursor: 'pointer',
        marginBottom: '10px',
        padding: '15px',
        borderRadius: '5px',
        border: '1px solid #ccc',
        transition: 'background-color 0.3s',
    },
    addForm: {
        padding: '20px',
        border: '1px solid #ccc',
        borderRadius: '5px',
        backgroundColor: '#f1f8e9',
        maxWidth: '600px',
        margin: '20px auto',
        textAlign: 'left',
    },
    select: {
        width: '100%',
        height: '150px',
        padding: '10px',
        marginBottom: '10px',
        borderRadius: '4px',
        border: '1px solid #ccc',
        fontSize: '16px',
    },
    button: {
        padding: '10px 20px',
        backgroundColor: '#007bff',
        color: '#fff',
        border: 'none',
        borderRadius: '4px',
        cursor: 'pointer',
        fontSize: '16px',
    },
};

export default ChatsManagement;