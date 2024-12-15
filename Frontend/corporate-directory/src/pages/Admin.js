import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';

function Admin() {
    const [employees, setEmployees] = useState([]);
    const [error, setError] = useState('');
    const [showAddForm, setShowAddForm] = useState(false);
    const [showEditForm, setShowEditForm] = useState(false);
    const [currentEmployee, setCurrentEmployee] = useState(null);
    const [formData, setFormData] = useState({
        full_name: '',
        email: '',
        phone_number: '',
        employment_date: '',
        is_admin: false,
        password: ''
    });

    useEffect(() => {
        fetchEmployees();
    }, []);

    const fetchEmployees = async () => {
        try {
            const response = await apiService.getEmployees();
            setEmployees(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения сотрудников');
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm('Вы уверены, что хотите удалить этого сотрудника?')) {
            try {
                await apiService.deleteEmployee(id);
                setEmployees(employees.filter(emp => emp.id_employee !== id));
            } catch (err) {
                console.error(err);
                setError('Ошибка удаления сотрудника');
            }
        }
    };

    const handleAdd = () => {
        setFormData({
            full_name: '',
            email: '',
            phone_number: '',
            employment_date: '',
            is_admin: false,
            password: ''
        });
        setShowAddForm(true);
        setShowEditForm(false);
    };

    const handleEdit = (employee) => {
        setCurrentEmployee(employee);
        setFormData({
            full_name: employee.full_name,
            email: employee.email,
            phone_number: employee.phone_number,
            employment_date: employee.employment_date,
            is_admin: employee.is_admin,
            password: '' // Пароль будет обновляться только при изменении
        });
        setShowEditForm(true);
        setShowAddForm(false);
    };

    const handleFormChange = (e) => {
        const { name, value, type, checked } = e.target;
        setFormData(prevData => ({
            ...prevData,
            [name]: type === 'checkbox' ? checked : value
        }));
    };

    const handleAddSubmit = async (e) => {
        e.preventDefault();
        try {
            const data = { ...formData };
            await apiService.addEmployee(data);
            setShowAddForm(false);
            fetchEmployees();
        } catch (err) {
            console.error(err);
            setError('Ошибка добавления сотрудника');
        }
    };

    const handleEditSubmit = async (e) => {
        e.preventDefault();
        try {
            const data = { ...formData };
            if (data.password === '') {
                // Исключаем пароль, если он не изменен
                delete data.password;
            }
            await apiService.updateEmployee(currentEmployee.id_employee, data);
            setShowEditForm(false);
            fetchEmployees();
        } catch (err) {
            console.error(err);
            setError('Ошибка обновления сотрудника');
        }
    };

    return (
        <div>
            <h2>Админ Панель</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}

            <button onClick={handleAdd}>Добавить сотрудника</button>

            {/* Форма добавления сотрудника */}
            {showAddForm && (
                <form onSubmit={handleAddSubmit}>
                    <h3>Добавить сотрудника</h3>
                    <div>
                        <label>Полное имя:</label>
                        <input
                            type="text"
                            name="full_name"
                            value={formData.full_name}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Email:</label>
                        <input
                            type="email"
                            name="email"
                            value={formData.email}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Телефон:</label>
                        <input
                            type="text"
                            name="phone_number"
                            value={formData.phone_number}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Дата трудоустройства:</label>
                        <input
                            type="date"
                            name="employment_date"
                            value={formData.employment_date}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Администратор:</label>
                        <input
                            type="checkbox"
                            name="is_admin"
                            checked={formData.is_admin}
                            onChange={handleFormChange}
                        />
                    </div>
                    <div>
                        <label>Пароль:</label>
                        <input
                            type="password"
                            name="password"
                            value={formData.password}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <button type="submit">Сохранить</button>
                    <button type="button" onClick={() => setShowAddForm(false)}>Отмена</button>
                </form>
            )}

            {/* Форма редактирования сотрудника */}
            {showEditForm && currentEmployee && (
                <form onSubmit={handleEditSubmit}>
                    <h3>Редактировать сотрудника</h3>
                    <div>
                        <label>Полное имя:</label>
                        <input
                            type="text"
                            name="full_name"
                            value={formData.full_name}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Email:</label>
                        <input
                            type="email"
                            name="email"
                            value={formData.email}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Телефон:</label>
                        <input
                            type="text"
                            name="phone_number"
                            value={formData.phone_number}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Дата трудоустройства:</label>
                        <input
                            type="date"
                            name="employment_date"
                            value={formData.employment_date}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Администратор:</label>
                        <input
                            type="checkbox"
                            name="is_admin"
                            checked={formData.is_admin}
                            onChange={handleFormChange}
                        />
                    </div>
                    <div>
                        <label>Пароль (оставьте пустым, чтобы не менять):</label>
                        <input
                            type="password"
                            name="password"
                            value={formData.password}
                            onChange={handleFormChange}
                        />
                    </div>
                    <button type="submit">Обновить</button>
                    <button type="button" onClick={() => setShowEditForm(false)}>Отмена</button>
                </form>
            )}

            <h3>Список сотрудников</h3>
            <ul>
                {employees.map(emp => (
                    <li key={emp.id_employee}>
                        {emp.full_name} - {emp.email} - {emp.phone_number} - {emp.is_admin ? 'Администратор' : 'Пользователь'}
                        <button onClick={() => handleEdit(emp)}>Редактировать</button>
                        <button onClick={() => handleDelete(emp.id_employee)}>Удалить</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}

export default Admin;