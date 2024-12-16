import React, { useEffect, useState } from 'react';
import apiService from '../../services/apiService';

function EmployeesManagement() {
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
    const [message, setMessage] = useState('');

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
                setMessage('Сотрудник успешно удален');
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
        setMessage('');
    };

    const handleEdit = (employee) => {
        setCurrentEmployee(employee);
        setFormData({
            full_name: employee.full_name,
            email: employee.email,
            phone_number: employee.phone_number,
            employment_date: employee.employment_date.split('T')[0],
            is_admin: employee.is_admin,
            password: ''
        });
        setShowEditForm(true);
        setShowAddForm(false);
        setMessage('');
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
            setMessage('Сотрудник успешно добавлен');
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
                delete data.password;
            }
            await apiService.updateEmployee(currentEmployee.id_employee, data);
            setShowEditForm(false);
            fetchEmployees();
            setMessage('Сотрудник успешно обновлен');
        } catch (err) {
            console.error(err);
            setError('Ошибка обновления сотрудника');
        }
    };

    return (
        <div>
            <h3>Управление Сотрудниками</h3>
            {error && <p className="error">{error}</p>}
            {message && <p className="success">{message}</p>}

            <button onClick={handleAdd} style={{ ...styles.button, backgroundColor: '#28a745' }}>Добавить сотрудника</button>

            {/* Форма добавления сотрудника */}
            {showAddForm && (
                <form onSubmit={handleAddSubmit} style={styles.form}>
                    <h4>Добавить сотрудника</h4>
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
                    <div style={styles.checkboxGroup}>
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
                    <button type="submit" style={{ ...styles.button, backgroundColor: '#007bff' }}>Сохранить</button>
                    <button type="button" onClick={() => setShowAddForm(false)} style={{ ...styles.button, backgroundColor: '#6c757d' }}>Отмена</button>
                </form>
            )}

            {/* Форма редактирования сотрудника*/}
            {showEditForm && currentEmployee && (
                <form onSubmit={handleEditSubmit} style={styles.form}>
                    <h4>Редактировать сотрудника</h4>
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
                    <div style={styles.checkboxGroup}>
                        <label>Администратор:</label>
                        <input
                            type="checkbox"
                            name="is_admin"
                            checked={formData.is_admin}
                            onChange={handleFormChange}
                        />
                    </div>
                    <div>
                        <label>Пароль (оставьте пустым, если не хотите менять):</label>
                        <input
                            type="password"
                            name="password"
                            value={formData.password}
                            onChange={handleFormChange}
                        />
                    </div>
                    <button type="submit" style={{ ...styles.button, backgroundColor: '#007bff' }}>Обновить</button>
                    <button type="button" onClick={() => setShowEditForm(false)} style={{ ...styles.button, backgroundColor: '#6c757d' }}>Отмена</button>
                </form>
            )}

            {/* Список сотрудников */}
            <h4>Список сотрудников</h4>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Полное имя</th>
                        <th>Email</th>
                        <th>Телефон</th>
                        <th>Дата трудоустройства</th>
                        <th>Админ</th>
                        <th>Действия</th>
                    </tr>
                </thead>
                <tbody>
                    {employees.map(emp => (
                        <tr key={emp.id_employee}>
                            <td>{emp.id_employee}</td>
                            <td>{emp.full_name}</td>
                            <td>{emp.email}</td>
                            <td>{emp.phone_number}</td>
                            <td>{new Date(emp.employment_date).toLocaleDateString()}</td>
                            <td>{emp.is_admin ? 'Да' : 'Нет'}</td>
                            <td>
                                <button onClick={() => handleEdit(emp)} style={{ ...styles.button, backgroundColor: '#ffc107' }}>Редактировать</button>
                                <button onClick={() => handleDelete(emp.id_employee)} style={{ ...styles.button, backgroundColor: '#dc3545' }}>Удалить</button>
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}

const styles = {
    form: {
        marginBottom: '30px',
        padding: '20px',
        border: '1px solid #ccc',
        borderRadius: '5px',
        backgroundColor: '#f9f9f9',
        maxWidth: '600px',
        margin: '20px auto',
        textAlign: 'left',
    },
    button: {
        padding: '8px 12px',
        color: '#fff',
        border: 'none',
        borderRadius: '4px',
        cursor: 'pointer',
        marginRight: '10px',
        fontSize: '14px',
    },
    checkboxGroup: {
        display: 'flex',
        alignItems: 'center',
        marginBottom: '10px',
    }
};

export default EmployeesManagement;