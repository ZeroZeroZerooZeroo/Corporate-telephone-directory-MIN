import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';

function Events() {
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
            console.log('Events:', response.data); 
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
            date: event.date.split('T')[0], // Форматирование даты
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
            data.id_event_location = parseInt(data.id_event_location);
            data.id_employee = parseInt(data.id_employee);
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
            data.id_event_location = parseInt(data.id_event_location); 
            data.id_employee = parseInt(data.id_employee); 
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
            <h2>События</h2>
            {message && <p style={{ color: 'green' }}>{message}</p>}
            {error && <p style={{ color: 'red' }}>{error}</p>}

            <button onClick={handleAdd}>Добавить мероприятие</button>

            {/* Форма добавления мероприятия */}
            {showAddForm && (
                <form onSubmit={handleAddSubmit}>
                    <h3>Создать мероприятие</h3>
                    <div>
                        <label>Название:</label>
                        <input
                            type="text"
                            name="name"
                            value={formData.name}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Описание:</label>
                        <textarea
                            name="discription"
                            value={formData.discription}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Дата:</label>
                        <input
                            type="date"
                            name="date"
                            value={formData.date}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
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
                    <div>
                        <label>Создатель мероприятия:</label>
                        <select
                            name="id_employee"
                            value={formData.id_employee}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">--Выберите создателя--</option>
                            {employees.map(emp => (
                                <option key={emp.id_employee} value={emp.id_employee}>
                                    {emp.full_name}</option>
                            ))}
                        </select>
                    </div>
                    <button type="submit">Создать</button>
                    <button type="button" onClick={() => setShowAddForm(false)}>Отмена</button>
                </form>
            )}

            {/* Форма редактирования мероприятия */}
            {showEditForm && currentEvent && (
                <form onSubmit={handleEditSubmit}>
                    <h3>Редактировать мероприятие</h3>
                    <div>
                        <label>Название:</label>
                        <input
                            type="text"
                            name="name"
                            value={formData.name}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Описание:</label>
                        <textarea
                            name="discription"
                            value={formData.discription}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
                        <label>Дата:</label>
                        <input
                            type="date"
                            name="date"
                            value={formData.date}
                            onChange={handleFormChange}
                            required
                        />
                    </div>
                    <div>
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
                    <div>
                        <label>Создатель мероприятия:</label>
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
                    <button type="submit">Обновить</button>
                    <button type="button" onClick={() => setShowEditForm(false)}>Отмена</button>
                </form>
            )}

            <h3>Список мероприятий</h3>
            <ul>
                {events.map(event => (
                    <li key={event.id_event}>
                        <p><strong>{event.name}</strong></p>
                        <p>{event.discription}</p>
                        <p><strong>Дата:</strong> {new Date(event.date).toLocaleDateString()}</p>
                        <p><strong>Место проведения:</strong> {event.event_location_name || 'Не указано'}</p>
                        <p><strong>Создатель:</strong> {event.creator_name || 'Не указан'}</p>
                        <button onClick={() => handleEdit(event)}>Редактировать</button>
                        <button onClick={() => handleDelete(event.id_event)}>Удалить</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}

export default Events;