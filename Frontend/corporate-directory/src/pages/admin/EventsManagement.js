import React, { useEffect, useState } from 'react';
import apiService from '../../services/apiService';

function EventsManagement() {
    const [events, setEvents] = useState([]);
    const [eventLocations, setEventLocations] = useState([]);
    const [employees, setEmployees] = useState([]);
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');
    const [showAddForm, setShowAddForm] = useState(false);
    const [showEditForm, setShowEditForm] = useState(false);
    const [currentEvent, setCurrentEvent] = useState(null);
    const [formData, setFormData] = useState({
        name: '',
        discription: '',
        date: '',
        id_event_location: '',
        id_employee: ''
    });

    useEffect(() => {
        fetchEvents();
        fetchEventLocations();
        fetchEmployees();
    }, []);

    const fetchEvents = async () => {
        try {
            const response = await apiService.getEvents();
            setEvents(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения мероприятий');
        }
    };

    const fetchEventLocations = async () => {
        try {
            const response = await apiService.getEventLocations();
            setEventLocations(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения мест проведения мероприятий');
        }
    };

    const fetchEmployees = async () => {
        try {
            const response = await apiService.getEmployees();
            setEmployees(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения списка сотрудников');
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm('Вы уверены, что хотите удалить это мероприятие?')) {
            try {
                await apiService.deleteEvent(id);
                setEvents(events.filter(event => event.id_event !== id));
            } catch (err) {
                console.error(err);
                setError('Ошибка удаления мероприятия');
            }
        }
    };

    const handleAdd = () => {
        setFormData({
            name: '',
            discription: '',
            date: '',
            id_event_location: '',
            id_employee: ''
        });
        setShowAddForm(true);
        setShowEditForm(false);
    };

    const handleEdit = (event) => {
        setCurrentEvent(event);
        setFormData({
            name: event.name,
            discription: event.discription,
            date: event.date.split('T')[0],
            id_event_location: event.id_event_location,
            id_employee: event.id_employee
        });
        setShowEditForm(true);
        setShowAddForm(false);
    };

    const handleFormChange = (e) => {
        const { name, value } = e.target;
        setFormData(prevData => ({
            ...prevData,
            [name]: value
        }));
    };

    const handleAddSubmit = async (e) => {
        e.preventDefault();
        try {
            const data = { ...formData };
            await apiService.createEvent(data);
            setShowAddForm(false);
            fetchEvents();
            setMessage('Мероприятие создано успешно');
        } catch (err) {
            console.error(err);
            setError('Ошибка создания мероприятия');
        }
    };

    const handleEditSubmit = async (e) => {
        e.preventDefault();
        try {
            const data = { ...formData };
            await apiService.updateEvent(currentEvent.id_event, data);
            setShowEditForm(false);
            fetchEvents();
            setMessage('Мероприятие обновлено успешно');
        } catch (err) {
            console.error(err);
            setError('Ошибка обновления мероприятия');
        }
    };

    return (
        <div>
            <h3>Управление Мероприятиями</h3>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {message && <p style={{ color: 'green' }}>{message}</p>}

            <button onClick={handleAdd} style={styles.addButton}>Добавить мероприятие</button>

            {/* Форма добавления мероприятия */}
            {showAddForm && (
                <form onSubmit={handleAddSubmit} style={styles.form}>
                    <h4>Создать мероприятие</h4>
                    <div style={styles.formGroup}>
                        <label>Название:</label>
                        <input
                            type="text"
                            name="name"
                            value={formData.name}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div style={styles.formGroup}>
                        <label>Описание:</label>
                        <textarea
                            name="discription"
                            value={formData.discription}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div style={styles.formGroup}>
                        <label>Дата:</label>
                        <input
                            type="date"
                            name="date"
                            value={formData.date}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div style={styles.formGroup}>
                        <label>Место проведения:</label>
                        <select
                            name="id_event_location"
                            value={formData.id_event_location}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">--Выберите место--</option>
                            {eventLocations.map(location => (
                                <option key={location.id_event_location} value={location.id_event_location}>
                                    {location.name}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div style={styles.formGroup}>
                        <label>Создатель мероприятия (ID):</label>
                        <select
                            name="id_employee"
                            value={formData.id_employee}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">--Выберите создателя--</option>
                            {employees.map(emp => (
                                <option key={emp.id_employee} value={emp.id_employee}>
                                    {emp.full_name}
                                </option>
                            ))}
                        </select>
                    </div>
                    <button type="submit" style={styles.submitButton}>Создать</button>
                    <button type="button" onClick={() => setShowAddForm(false)} style={styles.cancelButton}>Отмена</button>
                </form>
            )}

            {/* Форма редактирования мероприятия */}
            {showEditForm && currentEvent && (
                <form onSubmit={handleEditSubmit} style={styles.form}>
                    <h4>Редактировать мероприятие</h4>
                    <div style={styles.formGroup}>
                        <label>Название:</label>
                        <input
                            type="text"
                            name="name"
                            value={formData.name}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div style={styles.formGroup}>
                        <label>Описание:</label>
                        <textarea
                            name="discription"
                            value={formData.discription}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div style={styles.formGroup}>
                        <label>Дата:</label>
                        <input
                            type="date"
                            name="date"
                            value={formData.date}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div style={styles.formGroup}>
                        <label>Место проведения:</label>
                        <select
                            name="id_event_location"
                            value={formData.id_event_location}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">--Выберите место--</option>
                            {eventLocations.map(location => (
                                <option key={location.id_event_location} value={location.id_event_location}>
                                    {location.name}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div style={styles.formGroup}>
                        <label>Создатель мероприятия (ID):</label>
                        <select
                            name="id_employee"
                            value={formData.id_employee}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">--Выберите создателя--</option>
                            {employees.map(emp => (
                                <option key={emp.id_employee} value={emp.id_employee}>
                                    {emp.full_name}
                                </option>
                            ))}
                        </select>
                    </div>
                    <button type="submit" style={styles.submitButton}>Обновить</button>
                    <button type="button" onClick={() => setShowEditForm(false)} style={styles.cancelButton}>Отмена</button>
                </form>
            )}

            {/* Список мероприятий */}
            <h4>Список мероприятий</h4>
            <table style={styles.table}>
            <thead>
    <tr>
        <th>ID</th>
        <th>Название</th>
        <th>Описание</th>
        <th>Дата</th>
        <th>Местоположение</th>
        <th>ID Сотрудника</th>
        <th>Действия</th>
    </tr>
</thead>
<tbody>
    {events.map(event => (
        <tr key={event.id_event}>
            <td>{event.id_event}</td>
            <td>{event.name}</td>
            <td>{event.description}</td> {/* Исправлено с discription на description */}
            <td>{new Date(event.date).toLocaleDateString()}</td>
            <td>{event.event_location_name || 'Не указано'}</td>
            <td>{event.id_employee}</td>
            <td>
                <button onClick={() => handleEdit(event)} style={styles.editButton}>
                    Редактировать
                </button>
                <button onClick={() => handleDelete(event.id_event)} style={styles.deleteButton}>
                    Удалить
                </button>
            </td>
        </tr>
    ))}
</tbody>
            </table>
        </div>
    );
}

const styles = {
    addButton: {
        padding: '10px 15px',
        marginBottom: '20px',
        backgroundColor: '#28a745',
        color: '#fff',
        border: 'none',
        borderRadius: '3px',
        cursor: 'pointer',
    },
    form: {
        marginBottom: '30px',
        padding: '20px',
        border: '1px solid #ccc',
        borderRadius: '5px',
        backgroundColor: '#f9f9f9',
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
        marginRight: '10px',
    },
    cancelButton: {
        padding: '10px 15px',
        backgroundColor: '#6c757d',
        color: '#fff',
        border: 'none',
        borderRadius: '3px',
        cursor: 'pointer',
    },
    table: {
        width: '100%',
        borderCollapse: 'collapse',
    },
    editButton: {
        padding: '5px 10px',
        marginRight: '5px',
        backgroundColor: '#ffc107',
        border: 'none',
        borderRadius: '3px',
        cursor: 'pointer',
        color: '#343a40',
    },
    deleteButton: {
        padding: '5px 10px',
        backgroundColor: '#dc3545',
        border: 'none',
        borderRadius: '3px',
        cursor: 'pointer',
        color: '#fff',
    },
};

export default EventsManagement;