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
        file_extention: '',
        id_document_template: ''
    });

    useEffect(() =>{
        fetchTemplates();
        fetchDocuments();
    }, []);

    const fetchTemplates = async () => {
        try {
            const response = await apiService.getDocumentTemplate();
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
                setMessage('Документ успешно удален');
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
            file_extention: '',
            id_document_template: ''
        });
        setShowAddForm(true);
        setShowEditForm(false);
        setMessage('');
    };

    const handleEdit = (document) => {
        setCurrentDocument(document);
        setFormData({
            title: document.title,
            description: document.description,
            path_file: document.path_file,
            file_extention: document.file_extention,
            id_document_template: document.id_document_template
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
            const data = {
                title: formData.title,
                description: formData.description,
                path_file: formData.path_file,
                file_extention: formData.file_extention,
                id_document_template: parseInt(formData.id_document_template)
            };
            const response = await apiService.createDocument(data);
            setShowAddForm(false);
            fetchDocuments();
            setMessage('Документ успешно создан');
        } catch (err) {
            console.error(err);
            setError('Ошибка добавления документа');
        }
    };

    const handleEditSubmit = async (e) => {
        e.preventDefault();
        try {
            const data = { 
                title: formData.title, 
                description: formData.description, 
                path_file: formData.path_file,
                file_extention: formData.file_extention, 
                id_document_template: formData.id_document_template 
            };
            await apiService.updateDocument(currentDocument.id_document, data);
            setShowEditForm(false);
            fetchDocuments();
            setMessage('Документ успешно обновлен');
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
                            value={formData.id_document_template}
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
                            value={formData.id_document_template}
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
                {documents.map(doc => (<li key={doc.id_document} style={{ marginBottom: '10px' }}>
                        <strong>{doc.title}</strong> - {doc.description} - {doc.file_extention} 
                        <p><strong>Шаблон:</strong> {doc.template_name || 'Не указан'}</p>
                        <p>
                            <strong>Путь к файлу:</strong> {doc.path_file}
                           
                        </p>
                        <button onClick={() => handleEdit(doc)} style={{ marginLeft: '10px' }}>Редактировать</button>
                        <button onClick={() => handleDelete(doc.id_document)} style={{ marginLeft: '5px' }}>Удалить</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}

const styles = {
    buttonGroup: {
        display: 'flex',
        gap: '10px',
        marginBottom: '20px',
        flexWrap: 'wrap',
    },
    reportButton: {
        padding: '10px 15px',
        backgroundColor: '#17a2b8',
        color: '#fff',
        border: 'none',
        borderRadius: '3px',cursor: 'pointer',
        flex: '1 1 200px',
    },
    table: {
        width: '100%',
        borderCollapse: 'collapse',
        marginBottom: '20px',
    },
};

export default Documents;