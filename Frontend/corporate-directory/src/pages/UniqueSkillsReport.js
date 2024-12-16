import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';

function UniqueSkillsReport() {
    const [uniqueSkills, setUniqueSkills] = useState([]);
    const [error, setError] = useState('');

    useEffect(() => {
        const fetchUniqueSkills = async () => {
            try {
                const response = await apiService.getUniqueSkillsReport();
                setUniqueSkills(response.data);
            } catch (err) {
                console.error(err);
                setError('Ошибка получения отчета по уникальным навыкам');
            }
        };
        fetchUniqueSkills();
    }, []);

    return (
        <div>
            <h2>Отчет по Уникальным Навыкам Сотрудников</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {uniqueSkills.length > 0 ? (
                <table border="1">
                    <thead>
                        <tr>
                            <th>ID Сотрудника</th>
                            <th>Имя</th>
                            <th>Отдел</th>
                            <th>Уникальный Навык</th>
                        </tr>
                    </thead>
                    <tbody>
                        {uniqueSkills.map(skill => (
                            <tr key={`${skill.employee_id}-${skill.skill_name}`}>
                                <td>{skill.employee_id}</td>
                                <td>{skill.employee_name}</td>
                                <td>{skill.department_name}</td>
                                <td>{skill.skill_name}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            ) : (
                <p>Нет уникальных навыков для отображения.</p>
            )}
        </div>
    );
}

export default UniqueSkillsReport;