import React, { useEffect, useState } from 'react';
import apiService from '../../services/apiService';

function ActualData() {
    const [activeAnnouncements, setActiveAnnouncements] = useState([]);
    const [error, setError] = useState('');

    useEffect(() => {
        fetchActiveAnnouncements();
    }, []);

    const fetchActiveAnnouncements = async () => {
        try {
            const response = await apiService.getActiveAnnouncements();
            setActiveAnnouncements(response.data);
            setError('');
        } catch (err) {
            console.error(err);
            setError('Ошибка получения активных объявлений');
        }
    };

    return (
        <div>
            <h3>Активные Объявления</h3>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {activeAnnouncements.length === 0 ? (
                <p>Нет активных объявлений на данный момент.</p>
            ) : (
                <ul>
                    {activeAnnouncements.map((announcement) => (<li key={announcement.title} style={{ marginBottom: '10px' }}>
                            <strong>{announcement.title}</strong>
                            <p>{announcement.description}</p>
                            <p><strong>Дата создания:</strong> {new Date(announcement.creation_date).toLocaleDateString()}</p>
                            <p><strong>Дата окончания:</strong> {new Date(announcement.end_date).toLocaleDateString()}</p>
                        </li>
                    ))}
                </ul>
            )}
        </div>
    );
}

export default ActualData;