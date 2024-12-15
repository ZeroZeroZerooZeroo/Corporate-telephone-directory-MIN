import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';
import authService from '../services/authService'; 

function BusinessCards() {
    const user = authService.getCurrentUser();
    const [businessCards, setBusinessCards] = useState([]);
    const [templates, setTemplates] = useState([]);
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');
    const [showAddForm, setShowAddForm] = useState(false);
    const [showEditForm, setShowEditForm] = useState(false);
    const [currentCard, setCurrentCard] = useState(null);
    const [formData, setFormData] = useState({
        content: '',
        creation_date: '',
        id_card_type: null,
        id_employee: user.user.id_employee
    });

    useEffect(() => {
        fetchTemplates();
        fetchBusinessCards();
    }, []);

    const fetchTemplates = async () => {
        try {
            const response = await apiService.getCardTypes(); // Предполагается, что есть такой метод
            setTemplates(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения шаблонов визиток');
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
            id_card_type: null,
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
            data.creation_date = new Date();
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
            data.creation_date = new Date();
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

            <button onClick={handleAdd}>Создать визитку</button>

            {/* Форма добавления визитки */}
            {showAddForm && (
                <form onSubmit={handleAddSubmit}>
                    <h3>Создать визитку</h3>
                    <div>
                        <label>Выберите шаблон:</label>
                        <select
                            name="id_card_type"
                            value={formData.id_card_type || ''}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">--Выберите шаблон--</option>
                            {templates.map(template => (
                                <option key={template.id_card_type} value={template.id_card_type}>
                                    {template.type}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div>
                        <label>Содержимое:</label>
                        <textarea
                            name="content"
                            value={formData.content}
                            onChange={handleFormChange}
                            rows="5"
                            cols="50"
                            required
                        />
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
                        <label>Выберите шаблон:</label>
                        <select
                            name="id_card_type"
                            value={formData.id_card_type || ''}
                            onChange={handleFormChange}
                            required
                        >
                            <option value="">--Выберите шаблон--</option>
                            {templates.map(template => (
                                <option key={template.id_card_type} value={template.id_card_type}>
                                    {template.type}
                                </option>
                            ))}
                        </select>
                    </div>
                    <div>
                        <label>Содержимое:</label>
                        <textarea
                            name="content"
                            value={formData.content}
                            onChange={handleFormChange}
                            rows="5"
                            cols="50"
                            required
                        />
                    </div>
                    <button type="submit">Обновить</button>
                    <button type="button" onClick={() => setShowEditForm(false)}>Отмена</button>
                </form>
            )}

            <h3>Список визиток</h3>
            <ul>
                {businessCards.map(card => (
                    <li key={card.id_business_card}>
                        <strong>Тип: {card.id_card_type}</strong> - {card.content} - {new Date(card.creation_date).toLocaleDateString()}
                        <button onClick={() => handleEdit(card)}>Редактировать</button>
                        <button onClick={() => handleDelete(card.id_business_card)}>Удалить</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}

export default BusinessCards;