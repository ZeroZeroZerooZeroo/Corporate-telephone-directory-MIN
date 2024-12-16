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

    // Функция для безопасного форматирования даты
    const formatDate = (dateString) => {
        if (!dateString) return 'Не указано';
        const date = new Date(dateString);
        if (isNaN(date)) {
            return 'Не указано';
        } else {
            return date.toLocaleDateString();
        }
    };

    if (error) return <p style={{ color: 'red' }}>{error}</p>;
    if (!profile) return <p>Загрузка...</p>;

    // Предполагается, что profile включает employee, position и skills
    const employee = profile.employee;
    const position = profile.position || null; // Если позиция не приходит с сервера, устанавливаем значение по умолчанию
    const skills = profile.skills || [];       // Если навыки не приходят, устанавливаем пустой массив

    return (
        <div style={styles.container}>
            <h2>Профиль</h2>
            <div style={styles.section}>
                <h3>Основная информация</h3>
                <p><strong>Полное имя:</strong> {employee.full_name}</p>
                <p><strong>Email:</strong> {employee.email}</p>
                <p><strong>Телефон:</strong> {employee.phone_number}</p>
                <p><strong>Дата трудоустройства:</strong> {formatDate(employee.employment_date)}</p>
                <p><strong>Администратор:</strong> {employee.is_admin ? 'Да' : 'Нет'}</p>
            </div>
            {position && (
                <div style={styles.section}>
                    <h3>Должность</h3>
                    <p><strong>Название должности:</strong> {position.job_title || 'Не назначено'}</p>
                    <p><strong>Отдел:</strong> {position.department || 'Не назначено'}</p>
                    <p><strong>Офис:</strong> {position.office_number || 'Не назначено'}</p>
                    <p><strong>Бизнес Центр:</strong> {position.business_center_address || 'Не назначено'}</p>
                </div>
            )}
            {skills && skills.length > 0 && (
                <div style={styles.section}>
                    <h3>Навыки</h3>
                    <ul>
                        {skills.map((skill, index) => (
                            <li key={index}>
                                {skill.skill_name} - Уровень: {skill.skill_level}
                            </li>
                        ))}
                        </ul>
                </div>
            )}
        </div>
    );
}

const styles = {
    container: {
        padding: '20px',
    },
    section: {
        marginBottom: '20px',
    },
};

export default Profile;