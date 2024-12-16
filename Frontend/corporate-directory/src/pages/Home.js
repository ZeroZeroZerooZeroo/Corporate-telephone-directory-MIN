import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';
import authService from '../services/authService';

function Home() {
    const userData = authService.getCurrentUser();
    const user = userData ? userData.user : null;
    const [events, setEvents] = useState([]);
    const [announcements, setAnnouncements] = useState([]);
    const [error, setError] = useState('');

    useEffect(() => {
        const fetchData = async () => {
            try {
                if (user) {
                    // Предполагается, что apiService имеет метод getTodaysEvents
                    const [eventsResponse, announcementsResponse] = await Promise.all([
                        apiService.getTodaysEvents(),
                        apiService.getActiveAnnouncements(),
                    ]);

                    setEvents(eventsResponse.data);
                    setAnnouncements(announcementsResponse.data);
                }
            } catch (err) {
                console.error(err);
                setError('');
            }
        };
        fetchData();
    }, [user]);

    if (!user) return <p>Загрузка...</p>;

    return (
        <div>
            <h2>Добро пожаловать, {user.full_name}</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            <section>
                <h3>События на сегодня</h3>
                {events.length > 0 ? (
                    <ul>
                        {events.map(event => (
                            <li key={event.id_event}>
                                <p><strong>{event.name}</strong> - {new Date(event.date).toLocaleDateString()}</p>
                                <p>{event.discription}</p>
                            </li>
                        ))}
                    </ul>
                ) : (
                    <p>Отсутствуют</p>
                )}
            </section>
            <section>
                <h3>Уведомления на сегодня</h3>
                {announcements.length > 0 ? (
                    <ul>
                        {announcements.map(announcement => (
                            <li key={announcement.id_announcement}>
                                <p><strong>{announcement.title}</strong>: {announcement.discription}</p>
                                <p>С: {new Date(announcement.creation_date).toLocaleDateString()} По: {new Date(announcement.end_date).toLocaleDateString()}</p>
                            </li>
                        ))}
                    </ul>
                ) : (
                    <p>Отсутствуют</p>
                )}
            </section>
            <section>
                <h3>Мероприятия на сегодня</h3>
                {events.length > 0 ? (
                    <ul>
                        {events.map(event => (
                            <li key={event.id_event}>
                                <p><strong>{event.name}</strong> - {new Date(event.date).toLocaleDateString()}</p>
                                <p>{event.discription}</p>
                            </li>
                        ))}
                    </ul>
                ) : (<p>Отсутствуют</p>
                )}
            </section>
        </div>
    );
}

export default Home;