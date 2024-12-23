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
        password: '',
        position_id: '',
        appointment_date: '', 
        department_id: '',
        skills: []
    });
    const [message, setMessage] = useState('');

    // Новые состояния для положений и навыков
    const [positions, setPositions] = useState([]);
    const [skillsList, setSkillsList] = useState([]);
    const [levels, setLevels] = useState([]);
    const [departments, setDepartments] = useState([]);
    const [businessCenters, setBusinessCenters] = useState([]);

    useEffect(() => {
        fetchEmployees();
        fetchPositions();
        fetchSkills();
        fetchLevels();
        fetchDepartments();
        fetchBusinessCenters();
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

    const fetchPositions = async () => {
        try {
            const response = await apiService.getPositions();
            setPositions(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения должностей');
        }
    };

    const fetchSkills = async () => {
        try {
            const response = await apiService.getSkills();
            setSkillsList(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения навыков');
        }
    };

    const fetchLevels = async () => {
        try {
            const response = await apiService.getLevels();
            setLevels(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения уровней навыков');
        }
    };

    const fetchDepartments = async () => {
        try {
            const response = await apiService.getDepartments();
            setDepartments(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения департаментов');
        }
    };

    const fetchBusinessCenters = async () => {
        try {
            const response = await apiService.getBusinessCenters();
            setBusinessCenters(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения бизнес-центров');
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
            password: '',
            position_id: '',
            appointment_date: '', // Инициализация поля
            department_id: '',
            skills: []
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
            password: '',
            position_id: employee.id_position || '',
            appointment_date: employee.appointment_date ? employee.appointment_date.split('T')[0] : '', // Добавлено
            department_id: employee.id_department || '',
            skills: employee.skills || []
        });
        setShowEditForm(true);
        setShowAddForm(false);
        setMessage('');
    };

    const handleFormChange = (e) => {
        const { name, value, type, checked, options } = e.target;
        if (name === 'skills') {
            const selectedOptions = Array.from(options).filter(option => option.selected).map(option => ({
                id_skill_name: option.value,
                id_level_skill: option.getAttribute('data-level-id') || ''
            }));
            setFormData(prevData => ({
                ...prevData,
                skills: selectedOptions
            }));
        } else if (name === 'is_admin') {
            setFormData(prevData => ({
                ...prevData,
                [name]: checked
            }));
        } else {
            setFormData(prevData => ({
                ...prevData,
                [name]: value
            }));
        }
    };

    const handleSkillLevelChange = (skillId, levelId) => {
        setFormData(prevData => ({
            ...prevData,
            skills: prevData.skills.map(skill => 
                skill.id_skill_name === skillId ? { ...skill, id_level_skill: levelId } : skill
            )
        }));
    };

    const handleAddSubmit = async (e) => {
        e.preventDefault();
        try {
            const data = { 
                full_name: formData.full_name,
                email: formData.email,
                phone_number: formData.phone_number,
                employment_date: formData.employment_date,
                is_admin: formData.is_admin,
                password: formData.password,
                position_id: formData.position_id, // Это должно быть id_job_title
                appointment_date: formData.appointment_date,
                department_id: formData.department_id,
                skills: formData.skills
            };
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
                    <div>
                        <label>Дата вступления в должность:</label> {/* Новое поле */}
                        <input
                            type="date"
                            name="appointment_date"
                            value={formData.appointment_date}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Бизнес-центр:</label>
                        <select
                            name="business_center_id"
                            value={formData.business_center_id || ''}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">Выберите бизнес-центр</option>
                            {businessCenters.map(bc => (
                                <option key={bc.id_business_center} value={bc.id_business_center}>
                                    {bc.address}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div>
                        <label>Отдел:</label>
                        <select
                            name="department_id"
                            value={formData.department_id || ''}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">Выберите отдел</option>
                            {departments.map(dept => (
                                <option key={dept.id_department} value={dept.id_department}>
                                    {dept.department_name}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div>
         <label>Должность:</label>
         <select
    name="position_id"
    value={formData.position_id}
    onChange={handleFormChange}
    required
>
    <option value="">Выберите должность</option>
    {positions.map(pos => (
        <option key={pos.id_job_title} value={pos.id_job_title}>
            {pos.job_title}
        </option>
    ))}
</select>
     </div>
                    <div>
                        <label>Навыки:</label>
                        <div>
                            {skillsList.map(skill => (
<div key={skill.id_skill_name} style={{ marginBottom: '10px' }}>
                                    <label>
                                        <input
                                            type="checkbox"
                                            value={skill.id_skill_name}
                                            checked={formData.skills.some(s => s.id_skill_name === skill.id_skill_name)}
                                            onChange={(e) => {
                                                const isChecked = e.target.checked;
                                                setFormData(prevData => {
                                                    if (isChecked) {
                                                        return {
                                                            ...prevData,
                                                            skills: [...prevData.skills, { id_skill_name: skill.id_skill_name, id_level_skill: '' }]
                                                        };
                                                    } else {
                                                        return {
                                                            ...prevData,
                                                            skills: prevData.skills.filter(s => s.id_skill_name !== skill.id_skill_name)
                                                        };
                                                    }
                                                });
                                            }}
                                        />
                                        {skill.name}
                                    </label>
                                    {formData.skills.some(s => s.id_skill_name === skill.id_skill_name) && (
                                        <select
                                            onChange={(e) => handleSkillLevelChange(skill.id_skill_name, e.target.value)}
                                            required
                                        >
                                            <option value="">Выберите уровень</option>
                                            {levels.map(level => (
                                                <option key={level.id_level_skill} value={level.id_level_skill}>
                                                    {level.level}
                                                </option>
                                            ))}
                                        </select>
                                    )}
                                </div>
                            ))}
                        </div>
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

            {/* Форма редактирования сотрудника */}
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
                    <div>
                        <label>Дата вступления в должность:</label> {/* Новое поле */}
                        <input
                            type="date"
                            name="appointment_date"
                            value={formData.appointment_date}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Бизнес-центр:</label>
                        <select
                            name="business_center_id"
                            value={formData.business_center_id || ''}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">Выберите бизнес-центр</option>
                            {businessCenters.map(bc => (
                                <option key={bc.id_business_center} value={bc.id_business_center}>
                                    {bc.address}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div>
                        <label>Отдел:</label>
                        <select
                            name="department_id"
                            value={formData.department_id || ''}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">Выберите отдел</option>
                            {departments.map(dept => (
                                <option key={dept.id_department} value={dept.id_department}>
                                    {dept.department_name}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div>
         <label>Должность:</label>
         <select
    name="position_id"
    value={formData.position_id}
    onChange={handleFormChange}
    required
>
    <option value="">Выберите должность</option>
    {positions.map(pos => (
        <option key={pos.id_job_title} value={pos.id_job_title}>
            {pos.job_title}
        </option>
    ))}
</select>
     </div>
                    <div>
                        <label>Навыки:</label>
                        <div>
                            {skillsList.map(skill => (
                                <div key={skill.id_skill_name} style={{ marginBottom: '10px' }}>
                                    <label>
                                        <input
                                            type="checkbox"
                                            value={skill.id_skill_name}
                                            checked={formData.skills.some(s => s.id_skill_name === skill.id_skill_name)}
                                            onChange={(e) => {
                                                const isChecked = e.target.checked;
                                                setFormData(prevData => {
                                                    if (isChecked) {
                                                        return {
                                                            ...prevData,
                                                            skills: [...prevData.skills, { id_skill_name: skill.id_skill_name, id_level_skill: '' }]
                                                        };
                                                    } else {
                                                        return {
                                                            ...prevData,
                                                            skills: prevData.skills.filter(s => s.id_skill_name !== skill.id_skill_name)
                                                        };
                                                    }
                                                });
                                            }}
                                        />
                                        {skill.name}
                                    </label>
                                    {formData.skills.some(s => s.id_skill_name === skill.id_skill_name) && (
                                        <select
                                            onChange={(e) => handleSkillLevelChange(skill.id_skill_name, e.target.value)}
                                            required
                                        >
                                            <option value="">Выберите уровень</option>
                                            {levels.map(level => (
                                                <option key={level.id_level_skill} value={level.id_level_skill}>
                                                    {level.level}
                                                </option>
                                            ))}
                                        </select>
                                    )}
                                </div>
                            ))}
                        </div>
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
                        <th>Дата вступления в должность</th> {/* Новая колонка */}
                        <th>Должность</th>
                        <th>Отдел</th>
                        <th>Бизнес-центр</th>
                        <th>Навыки</th>
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
                            <td>{emp.appointment_date ? new Date(emp.appointment_date).toLocaleDateString() : '—'}</td> {/* Новая колонка */}
                            <td>{emp.job_title}</td>
                            <td>{emp.department}</td>
                            <td>{emp.business_center}</td>
                            <td>
                                {emp.skills.length > 0 ? emp.skills.map((skill, index) => (
                                    <span key={index}>{skill.skill_name} ({skill.skill_level}){index < emp.skills.length - 1 ? ', ' : ''}</span>
                                )) : 'Нет навыков'}
                            </td>
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
