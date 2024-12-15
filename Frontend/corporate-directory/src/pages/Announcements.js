import React, { useEffect, useState } from 'react';
import axios from 'axios';

function Announcements() {
    const [announcements, setAnnouncements] = useState([]);

    useEffect(() => {
        const fetchAnnouncements = async () => {
            try {
                const response = await axios.get('http://localhost:5000/api/announcements/active');
                setAnnouncements(response.data);
            } catch (err) {
                console.error(err);
            }
        };
        fetchAnnouncements();
    }, []);

    return (
        <div>
            <h2>Объявления</h2>
            <ul>
                {announcements.map(announcement => (
                    <li key={announcement.id_announcement}>
                        <h3>{announcement.title}</h3>
                        <p>{announcement.discription}</p>
                        <p>С: {announcement.creation_date} По: {announcement.end_date}</p>
                    </li>
                ))}
            </ul>
        </div>
    );
}

export default Announcements;