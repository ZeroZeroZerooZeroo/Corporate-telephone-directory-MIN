import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';
import authService from '../services/authService'; 


function Documents() {
    const user = authService.getCurrentUser();
    const [documents, setDocuments] = useState([]);
    const [templates, setTemplates] = useState([]);
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');
    const [showAddForm, setShowAddForm] = useState(false);
    const [showEditForm, setShowEditForm] = useState(false);
    const [currentDocument, setCurrentDocument] = useState(null);
    const [formData, setFormData] = useState({
        title: '',
        description: '',
        path_file: '',
        load_date: '',
        change_date: '',
        file_extention: '',
        id_employee: user.user.id_employee,
        id_document_template: null
    });

    useEffect(() => {
        fetchTemplates();
        fetchDocuments();
    }, []);

    const fetchTemplates = async () => {
        try {
            const response = await apiService.getDocumentTemplates();
            setTemplates(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения шаблонов документов');
        }
    };

    const fetchDocuments = async () => {
        try {
            const response = await apiService.getDocuments();
            setDocuments(response.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения документов');
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm('Вы уверены, что хотите удалить этот документ?')) {
            try {
                await apiService.deleteDocument(id);
                setDocuments(documents.filter(doc => doc.id_document !== id));
            } catch (err) {
                console.error(err);
                setError('Ошибка удаления документа');
            }
        }
    };

    const handleAdd = () => {
        setFormData({
            title: '',
            description: '',
            path_file: '',
            load_date: '',
            change_date: '',
            file_extention: '',
            id_employee: user.user.id_employee,
            id_document_template: null
        });
        setShowAddForm(true);
        setShowEditForm(false);
    };

    const handleEdit = (document) => {
        setCurrentDocument(document);
        setFormData({
            title: document.title,
            description: document.description,
            path_file: document.path_file,
            load_date: document.load_date,
            change_date: document.change_date,
            file_extention: document.file_extention,
            id_employee: document.id_employee,
            id_document_template: document.id_document_template
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
            data.load_date = new Date();
            data.change_date = new Date();
            data.id_document_template = parseInt(data.id_document_template);
            await apiService.createDocument(data);
            setShowAddForm(false);
            fetchDocuments();
            setMessage('Документ создан успешно');
        } catch (err) {
            console.error(err);
            setError('Ошибка создания документа');
        }
    };

    const handleEditSubmit = async (e) => {
        e.preventDefault();
        try {
            const data = { ...formData };
            data.id_document_template = parseInt(data.id_document_template);
            data.change_date = new Date();
            await apiService.updateDocument(currentDocument.id_document, data);
            setShowEditForm(false);
            fetchDocuments();
            setMessage('Документ обновлен успешно');
        } catch (err) {
            console.error(err);
            setError('Ошибка обновления документа');
        }
    };

    return (
        <div>
            <h2>Документы</h2>
            {message && <p style={{ color: 'green' }}>{message}</p>}
            {error && <p style={{ color: 'red' }}>{error}</p>}

<button onClick={handleAdd}>Добавить документ</button>

{/* Форма добавления документа */}
{showAddForm && (
    <form onSubmit={handleAddSubmit}>
        <h3>Создать документ</h3>
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
                name="description"
                value={formData.description}
                onChange={handleFormChange}
                required
            />
        </div>
        <div>
            <label>Путь к файлу:</label>
            <input
                type="text"
                name="path_file"
                value={formData.path_file}
                onChange={handleFormChange}
                required
            />
        </div>
        <div>
            <label>Расширение файла:</label>
            <input
                type="text"
                name="file_extention"
                value={formData.file_extention}
                onChange={handleFormChange}
                required
            />
        </div>
        <div>
            <label>Шаблон документа:</label>
            <select
                name="id_document_template"
                value={formData.id_document_template || ''}
                onChange={handleFormChange}
                required
            >
                <option value="">--Выберите шаблон--</option>
                {templates.map(template => (
                    <option key={template.id_document_template} value={template.id_document_template}>
                        {template.name}
                    </option>
                ))}
            </select>
        </div>
        <button type="submit">Создать</button>
        <button type="button" onClick={() => setShowAddForm(false)}>Отмена</button>
    </form>
)}

{/* Форма редактирования документа */}
{showEditForm && currentDocument && (
    <form onSubmit={handleEditSubmit}>
        <h3>Редактировать документ</h3>
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
                name="description"
                value={formData.description}
                onChange={handleFormChange}
                required
            />
        </div>
        <div>
            <label>Путь к файлу:</label>
            <input
                type="text"
                name="path_file"value={formData.path_file}
                onChange={handleFormChange}
                required
            />
        </div>
        <div>
            <label>Расширение файла:</label>
            <input
                type="text"
                name="file_extention"
                value={formData.file_extention}
                onChange={handleFormChange}
                required
            />
        </div>
        <div>
            <label>Шаблон документа:</label>
            <select
                name="id_document_template"
                value={formData.id_document_template || ''}
                onChange={handleFormChange}
                required
            >
                <option value="">--Выберите шаблон--</option>
                {templates.map(template => (
                    <option key={template.id_document_template} value={template.id_document_template}>
                        {template.name}
                    </option>
                ))}
            </select>
        </div>
        <button type="submit">Обновить</button>
        <button type="button" onClick={() => setShowEditForm(false)}>Отмена</button>
    </form>
)}

<h3>Список документов</h3>
<ul>
    {documents.map(doc => (
        <li key={doc.id_document}>
            <strong>{doc.title}</strong> - {doc.description} - {doc.file_extention} - {doc.path_file}
            <button onClick={() => handleEdit(doc)}>Редактировать</button>
            <button onClick={() => handleDelete(doc.id_document)}>Удалить</button>
        </li>
    ))}
</ul>
</div>
);
}

export default Documents;