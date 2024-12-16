import React, { useState } from 'react';
import apiService from '../services/apiService';

function CheckEmployeeActivity() {
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');

    const handleCheck = async () => {
        try {
            await apiService.checkEmployeeActivity();
            setMessage('Проверка активности сотрудников выполнена успешно');
            setError('');
        } catch (err) {
            console.error(err);
            setError('Ошибка проверки активности сотрудников');
            setMessage('');
        }
    };

    return (
        <div>
            <h2>Проверка активности сотрудников</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {message && <p style={{ color: 'green' }}>{message}</p>}
            <button onClick={handleCheck}>Выполнить проверку</button>
        </div>
    );
}

export default CheckEmployeeActivity;