import React, { useEffect, useState } from 'react';
import authService from '../services/authService';
import apiService from '../services/apiService';

function Profile() {
    const userData = authService.getCurrentUser();
    const user = userData ? userData.user : null;
    const [profile, setProfile] = useState(null);
    const [error, setError] = useState('');

    useEffect(() => {
        const fetchProfile = async () => {
            try {
                const response = await apiService.getProfile(user.id_employee);
                setProfile(response.data);
            } catch (err) {
                console.error('Fetch Profile Error:', err);
                setError(err.response?.data?.message || 'Ошибка получения профиля');
            }
        };
        if (user && user.id_employee) {
            fetchProfile();
        } else {
            setError('Пользователь не авторизован');
        }
    }, [user]);

    useEffect(() => {
        const checkActivity = async () => {
            try {
                await apiService.checkEmployeeActivity();
            } catch (err) {
                console.error(err);
            }
        };
        checkActivity();
    }, []);

    if (error) return <p style={{ color: 'red' }}>{error}</p>;
    if (!profile) return <p>Загрузка...</p>;

    return (
        <div>
            <h2>Профиль</h2>
            <p><strong>Полное имя:</strong> {profile.full_name}</p>
            <p><strong>Email:</strong> {profile.email}</p>
            <p><strong>Телефон:</strong> {profile.phone_number}</p>
            <p><strong>Дата трудоустройства:</strong> {new Date(profile.employment_date).toLocaleDateString()}</p>
            <p><strong>Администратор:</strong> {profile.is_admin ? 'Да' : 'Нет'}</p>
            {/*Добавьте дополнительную информацию, например, должность, отдел и т.д. */}
        </div>
    );
}

export default Profile;