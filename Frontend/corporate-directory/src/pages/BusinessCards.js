import React, { useEffect, useState } from 'react';
import axios from 'axios';
import authService from '../services/authService';

function BusinessCards() {
    const user = authService.getCurrentUser();
    const [templates, setTemplates] = useState([]);
    const [selectedTemplate, setSelectedTemplate] = useState('');
    const [content, setContent] = useState('');
    const [message, setMessage] = useState('');

    useEffect(() => {
        const fetchTemplates = async () => {
            try {
                const response = await axios.get('http://localhost:5000/api/business_card_templates');
                setTemplates(response.data);
            } catch (err) {
                console.error(err);
            }
        };
        fetchTemplates();
    }, []);

    const handleCreateBusinessCard = async () => {
        try {
            await axios.post('http://localhost:5000/api/business_cards', {
                content: content,
                creation_date: new Date(),
                id_card_type: selectedTemplate.id_card_type,
                id_employee: user.id_employee
            });
            setMessage('Визитка создана успешно');
        } catch (err) {
            console.error(err);
            setMessage('Ошибка создания визитки');
        }
    };

    return (
        <div>
            <h2>Визитки</h2>
            {message && <p>{message}</p>}
            <div>
                <label>Выберите шаблон:</label>
                <select onChange={(e) => setSelectedTemplate(JSON.parse(e.target.value))}>
                    <option value="">--Выберите шаблон--</option>
                    {templates.map(template => (
                        <option key={template.id_card_type} value={JSON.stringify(template)}>
                            {template.type}
                        </option>
                    ))}
                </select>
            </div>
            {selectedTemplate && (
                <div>
                    <label>Содержимое:</label>
                    <textarea 
                        value={content} 
                        onChange={(e) => setContent(e.target.value)} 
                        rows="5" 
                        cols="50" 
                    />
                    <button onClick={handleCreateBusinessCard}>Создать визитку</button>
                </div>
            )}
        </div>
    );
}

export default BusinessCards;