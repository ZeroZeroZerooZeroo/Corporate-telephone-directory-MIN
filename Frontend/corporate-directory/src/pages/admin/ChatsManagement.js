import React, { useEffect, useState } from 'react';
import apiService from '../../services/apiService';

function ChatsManagement() {
    const [chats, setChats] = useState([]);
    const [employees, setEmployees] = useState([]);
    const [roles, setRoles] = useState([]);
    const [selectedChat, setSelectedChat] = useState(null);
    const [selectedEmployee, setSelectedEmployee] = useState('');
    const [selectedRole, setSelectedRole] = useState('');
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');

    useEffect(() => {
        fetchChats();
        fetchEmployees();
        fetchRoles();
    }, []);

    const fetchChats = async () => {
        try {
            const response = await apiService.getChats();
            setChats(response.data);
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

    const fetchRoles = async () => {
        try {
            const response = await apiService.getRoles();
            setRoles(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения ролей');
        }
    };

    const handleAddUserToChat = async (e) => {
        e.preventDefault();
        if (!selectedChat || !selectedEmployee || !selectedRole) {
            setError('Пожалуйста, заполните все поля');
            return;
        }
        try {
            await apiService.addUserToChat(selectedChat.id_group_chat, parseInt(selectedEmployee), parseInt(selectedRole));
            setMessage('Сотрудник успешно добавлен в чат');
            setSelectedEmployee('');
            setSelectedRole('');
            fetchChats(); // Обновляем список чатов, если необходимо
        } catch (err) {
            console.error(err);
            setError(err.response?.data?.message || 'Ошибка добавления сотрудника в чат');
        }
    };

    return (
        <div style={styles.container}>
            <h3>Управление Чатами</h3>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {message && <p style={{ color: 'green' }}>{message}</p>}
            <div style={styles.chatList}>
                <h4>Список Чатов</h4>
                <ul style={styles.ul}>
                    {chats.map(chat => (
                        <li
                            key={chat.id_group_chat}
                            onClick={() => setSelectedChat(chat)}
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

            {selectedChat && (
                <div style={styles.addForm}>
                    <h4>Добавить сотрудника в чат: {selectedChat.name}</h4>
                    <form onSubmit={handleAddUserToChat}>
                        <div style={styles.formGroup}>
                            <label>Сотрудник:</label>
                            <select
                                value={selectedEmployee}
                                onChange={(e) => setSelectedEmployee(e.target.value)}
                                required
                            >
                                <option value="">--Выберите сотрудника--</option>
                                {employees.map(emp => (
                                    <option key={emp.id_employee} value={emp.id_employee}>
                                        {emp.full_name} (ID: {emp.id_employee})
                                    </option>
                                ))}
                            </select>
                        </div>
                        <div style={styles.formGroup}>
                            <label>Роль:</label>
                            <select
                                value={selectedRole}
                                onChange={(e) => setSelectedRole(e.target.value)}
                                required
                            >
                                <option value="">--Выберите роль--</option>
                                {roles.map(role => (
                                    <option key={role.id_role} value={role.id_role}>
                                        {role.name}
                                    </option>
                                ))}
                            </select>
                        </div>
                        <button type="submit" style={styles.submitButton}>Добавить</button>
                    </form>
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
    formGroup: {
        marginBottom: '15px',
        display: 'flex',
        flexDirection: 'column',
    },
    submitButton: {
        padding: '10px 15px',
        backgroundColor: '#007bff',
        color: '#fff',
        border: 'none',
        borderRadius: '3px',
        cursor: 'pointer',
    },
};

export default ChatsManagement;