import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';

function Admin() {
    const [employees, setEmployees] = useState([]);
    const [error, setError] = useState('');

    useEffect(() => {
        const fetchEmployees = async () => {
            try {
                const response = await apiService.getEmployees();
                setEmployees(response.data);
            } catch (err) {
                console.error(err);
                setError('Ошибка получения сотрудников');
            }
        };
        fetchEmployees();
    }, []);

    if (error) return <p style={{ color: 'red' }}>{error}</p>;

    return (
        <div>
            <h2>Админ Панель</h2>
            <h3>Список сотрудников</h3>
            <ul>
                {employees.map(emp => (
                    <li key={emp.id_employee}>
                        {emp.full_name} - {emp.email} - {emp.is_admin ? 'Администратор' : 'Пользователь'}
                        {/* Добавьте кнопки для редактирования и удаления */}
                    </li>
                ))}
            </ul>
            {/* Реализуйте функционал добавления, редактирования и удаления сотрудников */}
        </div>
    );
}

export default Admin;