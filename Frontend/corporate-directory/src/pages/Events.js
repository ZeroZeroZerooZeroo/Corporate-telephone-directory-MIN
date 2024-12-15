import React, { useEffect, useState } from 'react';
import axios from 'axios';
//import authService from '../services/authService';

function Events() {
//const user = authService.getCurrentUser();
const [events, setEvents] = useState([]);
const [participants, setParticipants] = useState([]);

useEffect(() => {
const fetchEvents = async () => {
    try {
        const response = await axios.get('http://localhost:5000/api/events');
        setEvents(response.data);
    } catch (err) {
        console.error(err);
    }
};
fetchEvents();
}, []);

const viewParticipants = async (eventId) => {
try {
    const response = await axios.get(`http://localhost:5000/api/events/${eventId}/participants`);
    setParticipants(response.data);
} catch (err) {
    console.error(err);
}
};

return (
<div>
    <h2>События</h2>
    <ul>
        {events.map(event => (
            <li key={event.id_event}>
                <p><strong>{event.name}</strong></p>
                <p>{event.discription}</p>
                <p>Дата: {event.date}</p>
                <p>Место: {event.event_location}</p>
                <button onClick={() => viewParticipants(event.id_event)}>Просмотреть участников</button>
            </li>
        ))}
    </ul>
    {participants.length > 0 && (
                <div>
                    <h3>Участники мероприятия</h3>
                    <ul>
                        {participants.map(p => (
                            <li key={p.id_employee}>{p.full_name}</li>
                        ))}
                    </ul>
                </div>
            )}
        </div>
    );
}

export default Events;