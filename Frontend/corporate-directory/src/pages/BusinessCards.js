import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';
import authService from '../services/authService'; 

function BusinessCards() {
    const user = authService.getCurrentUser();
    const [businessCards, setBusinessCards] = useState([]);
    const [types, setTypes] = useState([]);
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');
    const [showAddForm, setShowAddForm] = useState(false);
    const [showEditForm, setShowEditForm] = useState(false);
    const [currentCard, setCurrentCard] = useState(null);
    const [formData, setFormData] = useState({
        content: '',
        creation_date: '',
        id_card_type: '',
        id_employee: user.user.id_employee
    });

    useEffect(() =>{
        fetchTypes();
        fetchBusinessCards();
    }, []);

    const fetchTypes = async () => {
        try {
            const response = await apiService.getCardTypes();
            setTypes(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения типов визиток');
        }
    };

    const fetchBusinessCards = async () => {
        try {
            const response = await apiService.getBusinessCards();
            setBusinessCards(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения визиток');
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm('Вы уверены, что хотите удалить эту визитку?')) {
            try {
                await apiService.deleteBusinessCard(id);
                setBusinessCards(businessCards.filter(card => card.id_business_card !== id));
            } catch (err) {
                console.error(err);
                setError('Ошибка удаления визитки');
            }
        }
    };

    const handleAdd = () => {
        setFormData({
            content: '',
            creation_date: '',
            id_card_type: '',
            id_employee: user.user.id_employee
        });
        setShowAddForm(true);
        setShowEditForm(false);
    };

    const handleEdit = (card) => {
        setCurrentCard(card);
        setFormData({
            content: card.content,
            creation_date: card.creation_date,
            id_card_type: card.id_card_type,
            id_employee: card.id_employee
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
            await apiService.createBusinessCard(data);
            setShowAddForm(false);
            fetchBusinessCards();
            setMessage('Визитка создана успешно');
        } catch (err) {
            console.error(err);
            setError('Ошибка создания визитки');
        }
    };

    const handleEditSubmit = async (e) => {
        e.preventDefault();
        try {
            const data = { ...formData };
            await apiService.updateBusinessCard(currentCard.id_business_card, data);
            setShowEditForm(false);
            fetchBusinessCards();
            setMessage('Визитка обновлена успешно');
        } catch (err) {
            console.error(err);
            setError('Ошибка обновления визитки');
        }
    };

    return (
        <div>
            <h2>Визитки</h2>
            {message && <p style={{ color: 'green' }}>{message}</p>}
            {error && <p style={{ color: 'red' }}>{error}</p>}

            <button onClick={handleAdd}>Добавить визитку</button>

            {/* Форма добавления визитки */}
            {showAddForm && (
                <form onSubmit={handleAddSubmit}>
                    <h3>Создать визитку</h3>
                    <div>
                        <label>Содержание:</label>
                        <textarea
                            name="content"
                            value={formData.content}
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
                        <label>Тип визитки:</label>
                        <select
                            name="id_card_type"
                            value={formData.id_card_type}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">--Выберите тип--</option>
                            {types.map(type => (
                                <option key={type.id_card_type} value={type.id_card_type}>
                                    {type.type}
                                </option>
                            ))}
                        </select>
                    </div>
                    <button type="submit">Создать</button>
                    <button type="button" onClick={() => setShowAddForm(false)}>Отмена</button>
                </form>
            )}

            {/* Форма редактирования визитки */}
            {showEditForm && currentCard && (
                <form onSubmit={handleEditSubmit}>
                    <h3>Редактировать визитку</h3>
                    <div>
                        <label>Содержание:</label>
                        <textarea
                            name="content"
                            value={formData.content}
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
                        <label>Тип визитки:</label>
                        <select
                            name="id_card_type"
                            value={formData.id_card_type}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">--Выберите тип--</option>
                            {types.map(type => (
                                <option key={type.id_card_type} value={type.id_card_type}>
                                    {type.type}
                                </option>
                            ))}
                        </select>
                    </div>
                    <button type="submit">Обновить</button>
                    <button type="button" onClick={() => setShowEditForm(false)}>Отмена</button>
                </form>
            )}

            <h3>Список визиток</h3>
            <ul>
                {businessCards.map(card => (
                    <li key={card.id_business_card} style={{ marginBottom: '10px' }}>
                        <p><strong>Содержание:</strong> {card.content}</p>
                        <p><strong>Дата создания:</strong> {new Date(card.creation_date).toLocaleDateString()}</p>
                        <p><strong>Тип визитки:</strong> {card.card_type}</p>
                        <button onClick={() => handleEdit(card)}>Редактировать</button>
                        <button onClick={() => handleDelete(card.id_business_card)}>Удалить</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}

export default BusinessCards;