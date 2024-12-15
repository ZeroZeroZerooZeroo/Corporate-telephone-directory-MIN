import React, { useEffect, useState } from 'react';
import axios from 'axios';
import authService from '../services/authService';

function Documents() {
    const user = authService.getCurrentUser();
    const [templates, setTemplates] = useState([]);
    const [selectedTemplate, setSelectedTemplate] = useState('');
    const [content, setContent] = useState('');
    const [message, setMessage] = useState('');

    useEffect(() => {
        const fetchTemplates = async () => {
            try {
                const response = await axios.get('http://localhost:5000/api/document_templates');
                setTemplates(response.data);
            } catch (err) {
                console.error(err);
            }
        };
        fetchTemplates();
    }, []);

    const handleCreateDocument = async () => {
        try {
            await axios.post('http://localhost:5000/api/documents', {
                title: selectedTemplate,
                description: content,
                path_file: '/path/to/file', // Реализуйте логику выбора пути файла
                load_date: new Date(),
                change_date: new Date(),
                file_extention: '.docx', // Определите расширение
                id_employee: user.id_employee,
                id_document_template: selectedTemplate.id_document_template
            });
            setMessage('Документ создан успешно');
        } catch (err) {
            console.error(err);
            setMessage('Ошибка создания документа');
        }
    };

    return (
        <div>
            <h2>Документы</h2>
            {message && <p>{message}</p>}
            <div>
                <label>Выберите шаблон:</label>
                <select onChange={(e) => setSelectedTemplate(JSON.parse(e.target.value))}>
                    <option value="">--Выберите шаблон--</option>
                    {templates.map(template => (
                        <option key={template.id_document_template} value={JSON.stringify(template)}>
                            {template.name}
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
                    rows="10" 
                    cols="50" 
                />
                <button onClick={handleCreateDocument}>Создать документ</button>
            </div>
        )}
    </div>
);
}

export default Documents;