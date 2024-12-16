import React, { useState } from 'react';
import apiService from '../services/apiService';

function SetSpecialRole() {
    const [norm, setNorm] = useState('');
    const [role, setRole] = useState('');
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');

    const handleSetRole = async () => {
        if (!norm || !role) {
            setError('Пожалуйста, заполните все поля');
            return;
        }
        try {
            await apiService.setSpecialRole(norm, role);
            setMessage('Специальная роль присвоена успешно');
            setError('');
            setNorm('');
            setRole('');
        } catch (err) {
            console.error(err);
            setError('Ошибка присвоения специальной роли');
            setMessage('');
        }
    };

    return (
        <div>
            <h2>Присвоение специальной роли</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {message && <p style={{ color: 'green' }}>{message}</p>}
            <div>
                <label>Пороговое значение (количество сообщений):</label>
                <input 
                    type="number" 
                    value={norm} 
                    onChange={(e) => setNorm(e.target.value)} 
                    placeholder="N"
                />
            </div>
            <div>
                <label>Название роли:</label>
                <input 
                    type="text" 
                    value={role} 
                    onChange={(e) => setRole(e.target.value)} 
                    placeholder="Название роли"
                />
            </div>
            <button onClick={handleSetRole}>Присвоить роль</button>
        </div>
    );
}

export default SetSpecialRole;