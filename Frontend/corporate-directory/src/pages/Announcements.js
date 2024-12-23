import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';

function Announcements() {
    const [announcements, setAnnouncements] = useState([]);
    const [employees, setEmployees] = useState([]); 
    const [error, setError] = useState('');
    const [showAddForm, setShowAddForm] = useState(false);
    const [showEditForm, setShowEditForm] = useState(false);
    const [currentAnnouncement, setCurrentAnnouncement] = useState(null);
    const [formData, setFormData] = useState({
        title: '',
        discription: '',
        creation_date: '',
        end_date: '',
        id_employee: ''
    });
    const [message, setMessage] = useState('');

    useEffect(() => {
        fetchAnnouncements();
        fetchEmployees(); 
    }, []);

    const fetchAnnouncements = async () => {
        try {
            const response = await apiService.getAllAnnouncements();
            setAnnouncements(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения объявлений');
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
        if (window.confirm('Вы уверены, что хотите удалить это объявление?')) {
            try {
                await apiService.deleteAnnouncement(id);
                setAnnouncements(announcements.filter(ann => ann.id_announcement !== id));
                setMessage('Объявление успешно удалено');
            } catch (err) {
                console.error(err);
                setError('Ошибка удаления объявления');
            }
        }
    };

    const handleAdd = () => {
        setFormData({
            title: '',
            discription: '',
            creation_date: '',
            end_date: '',
            id_employee: ''
        });
        setShowAddForm(true);
        setShowEditForm(false);
        setMessage('');
    };

    const handleEdit = (announcement) => {
        setCurrentAnnouncement(announcement);
        setFormData({
            title: announcement.title,
            discription: announcement.discription,
            creation_date: announcement.creation_date.split('T')[0],
            end_date: announcement.end_date.split('T')[0],
            id_employee: announcement.id_employee
        });
        setShowEditForm(true);
        setShowAddForm(false);
        setMessage('');
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
            await apiService.createAnnouncement(data);
            setShowAddForm(false);
            fetchAnnouncements();
            setMessage('Объявление успешно создано');
        } catch (err) {
            console.error(err);
            setError('Ошибка добавления объявления');
        }
    };

    const handleEditSubmit = async (e) => {
        e.preventDefault();
        try {
            const data = { ...formData };
            await apiService.updateAnnouncement(currentAnnouncement.id_announcement, data);
            setShowEditForm(false);
            fetchAnnouncements();
            setMessage('Объявление успешно обновлено');
        } catch (err) {
            console.error(err);
            setError('Ошибка обновления объявления');
        }
    };

    return (
        <div>
            <h3>Управление Объявлениями</h3>
            {error && <p className="error">{error}</p>}
            {message && <p className="success">{message}</p>}

            <button onClick={handleAdd} style={{ ...styles.button, backgroundColor: '#28a745' }}>Добавить объявление</button>

            {/* Форма добавления объявления */}
            {showAddForm && (
        <form onSubmit={handleAddSubmit} style={styles.form}>
            <h4>Создать объявление</h4>
            <div>
                <label>Название:</label>
                <input
                    type="text"
                    name="title"
                    value={formData.title}
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
                <label>Дата создания:</label>
                <input
                    type="date"
                    name="creation_date"
                    value={formData.creation_date}
                    onChange={handleFormChange}
                    required
                />
            </div>
            <div>
                <label>Дата окончания:</label>
                <input
                    type="date"
                    name="end_date"
                    value={formData.end_date}
                    onChange={handleFormChange}
                    required
                />
            </div>
            <div>
            <label>Создатель объявления:</label>
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
            <button type="submit" style={{ ...styles.button, backgroundColor: '#007bff' }}>Создать</button>
            <button type="button" onClick={() => setShowAddForm(false)} style={{ ...styles.button, backgroundColor: '#6c757d' }}>Отмена</button>
        </form>
    )}

    {/* Форма редактирования объявления */}
    {showEditForm && currentAnnouncement && (
        <form onSubmit={handleEditSubmit} style={styles.form}>
            <h4>Редактировать объявление</h4>
            <div>
                <label>Название:</label>
                <input
                    type="text"
                    name="title"
                    value={formData.title}
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
                <label>Дата создания:</label>
                <input
                    type="date"
                    name="creation_date"
                    value={formData.creation_date}
                    onChange={handleFormChange}
                    required
                />
            </div>
            <div>
                <label>Дата окончания:</label>
                <input
                    type="date"
                    name="end_date"
                    value={formData.end_date}
                    onChange={handleFormChange}
                    required
                />
            </div>
            <div>
                <label>Создатель объявления:</label>
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
            <button type="submit" style={{ ...styles.button, backgroundColor: '#007bff' }}>Обновить</button>
            <button type="button" onClick={() => setShowEditForm(false)} style={{ ...styles.button, backgroundColor: '#6c757d' }}>Отмена</button>
        </form>
    )}

           
            {/* Список объявлений */}
            <h4>Список объявлений</h4>
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Название</th>
                <th>Описание</th>
                <th>Дата создания</th>
                <th>Дата окончания</th>
                <th>Создатель</th>
                <th>Действия</th>
            </tr>
        </thead>
        <tbody>
            {announcements.map(ann => {
                const creator = employees.find(emp => emp.id_employee === ann.id_employee);
                return (<tr key={ann.id_announcement}>
                    <td>{ann.id_announcement}</td>
                    <td>{ann.title}</td>
                    <td>{ann.discription}</td>
                    <td>{new Date(ann.creation_date).toLocaleDateString()}</td>
                    <td>{new Date(ann.end_date).toLocaleDateString()}</td>
                    <td>{creator ? creator.full_name : 'Не указано'}</td>
                    <td>
                        <button onClick={() => handleEdit(ann)} style={{ ...styles.button, backgroundColor: '#ffc107' }}>Редактировать</button>
                        <button onClick={() => handleDelete(ann.id_announcement)} style={{ ...styles.button, backgroundColor: '#dc3545' }}>Удалить</button>
                    </td>
                </tr>
            );
        })}
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
        padding: '10px 15px',
        color: '#fff',
        border: 'none',
        borderRadius: '4px',
        cursor: 'pointer',
        marginRight: '10px',
        fontSize: '14px',
    },
};

export default Announcements;