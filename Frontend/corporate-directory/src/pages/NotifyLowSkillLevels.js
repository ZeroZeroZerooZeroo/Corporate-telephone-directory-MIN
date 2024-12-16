import React, { useState } from 'react';
import apiService from '../services/apiService';

function NotifyLowSkillLevels() {
    const [norm, setNorm] = useState('');
    const [message, setMessage] = useState('');
    const [error, setError] = useState('');

    const handleNotify = async () => {
        if (!norm) {
            setError('Пожалуйста, введите пороговое значение');
            return;
        }
        try {
            await apiService.notifyLowSkillLevels(norm);
            setMessage('Уведомления о низких уровнях навыков отправлены успешно');
            setError('');
            setNorm('');
        } catch (err) {
            console.error(err);
            setError('Ошибка отправки уведомлений');
            setMessage('');
        }
    };

    return (
        <div>
            <h2>Уведомление о низком уровне навыков</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {message && <p style={{ color: 'green' }}>{message}</p>}
            <div>
                <label>Пороговое значение:</label>
                <input 
                    type="number" 
                    value={norm} 
                    onChange={(e) => setNorm(e.target.value)} 
                    placeholder="Минимальный уровень навыка"
                />
                <button onClick={handleNotify}>Отправить уведомления</button>
            </div>
        </div>
    );
}

export default NotifyLowSkillLevels;