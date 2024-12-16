import React, { useEffect, useState } from 'react';
import apiService from '../../services/apiService';

function Reports() {
    const [employeesReport, setEmployeesReport] = useState([]);
    const [uniqueSkillsReport, setUniqueSkillsReport] = useState([]);
    const [employeesWithoutPhoneReport, setEmployeesWithoutPhoneReport] = useState([]);
    const [error, setError] = useState('');
    const [reportMessage, setReportMessage] = useState('');

    
    const [normInactive, setNormInactive] = useState('');
    const [normRole, setNormRole] = useState('');
    const [roleName, setRoleName] = useState('');
    const [normLowSkills, setNormLowSkills] = useState('');
    const [showEmployeesReport, setShowEmployeesReport] = useState(false);
    const [showUniqueSkillsReport, setShowUniqueSkillsReport] = useState(false);
    const [showEmployeesWithoutPhoneReport, setShowEmployeesWithoutPhoneReport] = useState(false);


    const generateEmployeesReport = async () => {
        try {
            const response = await apiService.getEmployeesReport();
            setEmployeesReport(response.data);
            setUniqueSkillsReport([]);
            setEmployeesWithoutPhoneReport([]);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения отчета по сотрудникам');
        }
    };

    const generateUniqueSkillsReport = async () => {
        try {
            const response = await apiService.getUniqueSkillsReport();
            setUniqueSkillsReport(response.data);
            setEmployeesReport([]);
            setEmployeesWithoutPhoneReport([]);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения отчета по уникальным навыкам');
        }
    };

    const generateEmployeesWithoutPhoneReport = async () => {
        try {
            const response = await apiService.getEmployeesWithoutPhoneReport();
            setEmployeesWithoutPhoneReport(response.data);
            setEmployeesReport([]);
            setUniqueSkillsReport([]);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения списка сотрудников без телефона');
        }
    };

    const handleNotifyInactive = async () => {
        try {
            await apiService.notifyInactiveEmployees(parseInt(normInactive, 10));
            setReportMessage('Уведомления о неактивных сотрудниках отправлены');
        } catch (err) {
            console.error(err);
            setError('Ошибка отправки уведомлений о неактивности');
        }
    };

    const handleAssignRole = async () => {
        try {
            if (!normRole || !roleName) {
                setError('Пожалуйста, заполните все поля для присвоения роли');
                return;
            }
            await apiService.assignRoleToEmployees(parseInt(normRole, 10), roleName);
            setReportMessage('Роли присвоены сотрудникам');
        } catch (err) {
            console.error(err);
            setError('Ошибка присвоения ролей');
        }
    };

    const handleNotifyLowSkills = async () => {
        try {
            await apiService.notifyLowSkillLevels(parseInt(normLowSkills, 10));
            setReportMessage('Уведомления о низких навыках отправлены');
        } catch (err) {
            console.error(err);
            setError('Ошибка отправки уведомлений о низких навыках');
        }
    };

    return (
        <div>
            <h3>Отчеты</h3>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {reportMessage && <p style={{ color: 'green' }}>{reportMessage}</p>}

            <div style={styles.buttonGroup}>
                <button onClick={generateEmployeesReport} style={styles.reportButton}>Отчет по сотрудникам</button>
                <button onClick={generateUniqueSkillsReport} style={styles.reportButton}>Отчет по уникальным навыкам</button>
                <button onClick={generateEmployeesWithoutPhoneReport} style={styles.reportButton}>Сотрудники без телефона</button>
            </div>

            {/* Отображение отчетов */}
            <div style={{ marginTop: '20px' }}>
                {/* Отчет по сотрудникам */}
                {employeesReport.length > 0 && (
                    <div>
                        <h4>Отчет по сотрудникам</h4>
                        <table style={styles.table}>
                            <thead>
                                <tr>
                                    <th>Имя сотрудника</th>
                                    <th>Email</th>
                                    <th>Название должности</th>
                                    <th>Должность</th>
                                    <th>Название документа</th>
                                    <th>Описание документа</th>
                                    <th>Дата загрузки</th>
                                </tr>
                            </thead>
                            <tbody>
                                {employeesReport.map((emp, index) => (
                                    <tr key={index}>
                                        <td>{emp.employee_name}</td>
                                        <td>{emp.employee_email}</td>
                                        <td>{emp.job_title_name}</td>
                                        <td>{emp.position_name}</td>
                                        <td>{emp.document_title}</td>
                                        <td>{emp.document_description}</td>
                                        <td>{new Date(emp.document_load_date).toLocaleDateString()}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}

                {/* Отчет по уникальным навыкам */}
                {uniqueSkillsReport.length > 0 && (
                    <div>
                        <h4>Отчет по уникальным навыкам в отделах</h4>
                        <table style={styles.table}>
                            <thead>
                                <tr>
                                    <th>ID сотрудника</th>
                                    <th>Имя сотрудника</th>
                                    <th>Название отдела</th>
                                    <th>Уникальный навык</th>
                                    </tr>
                            </thead>
                            <tbody>
                                {uniqueSkillsReport.map((skill, index) => (
                                    <tr key={index}>
                                        <td>{skill.employee_id}</td>
                                        <td>{skill.employee_name}</td>
                                        <td>{skill.department_name}</td>
                                        <td>{skill.skill_name}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
                {/* Отчеты */}
            <div style={{ marginTop: '20px' }}>
                {/* Уведомить неактивных сотрудников */}
                <h3>Уведомить неактивных сотрудников</h3>
                <input
                    type="number"
                    placeholder="Норма сообщений"
                    value={normInactive}
                    onChange={(e) => setNormInactive(e.target.value)}
                />
                <button onClick={handleNotifyInactive} style={{ marginLeft: '10px'}}>Отправить уведомления</button>

                {/* Присвоить роль */}
                <h3 style={{ marginTop: '20px' }}>Присвоить роль сотрудникам</h3>
                <input
                    type="number"
                    placeholder="Норма сообщений"
                    value={normRole}
                    onChange={(e) => setNormRole(e.target.value)}
                />
                <input
                    type="text"
                    placeholder="Название роли"
                    value={roleName}
                    onChange={(e) => setRoleName(e.target.value)}
                    style={{ marginLeft: '10px' }}
                />
                <button onClick={handleAssignRole} style={{ marginLeft: '10px' }}>Присвоить роль</button>

                {/* Уведомить о низких навыках */}
                <h3 style={{ marginTop: '20px' }}>Уведомить о низких навыках</h3>
                <input
                    type="number"
                    placeholder="Пороговый уровень навыка"
                    value={normLowSkills}
                    onChange={(e) => setNormLowSkills(e.target.value)}
                />
                <button onClick={handleNotifyLowSkills} style={{ marginLeft: '10px' }}>Отправить уведомления</button>
            </div>
                {/* Отчет: сотрудники без телефона */}
                {employeesWithoutPhoneReport.length > 0 && (
                    <div>
                        <h4>Сотрудники без телефона</h4>
                        <ul>
                            {employeesWithoutPhoneReport.map((emp, index) => (
                                <li key={index}>{emp.employee_name}</li>
                            ))}
                        </ul>
                    </div>
                )}
            </div>
        </div>
    );
}

const styles = {
    buttonGroup: {
        display: 'flex',
        gap: '10px',
        marginBottom: '20px',
    },
    reportButton: {
        padding: '10px 15px',
        backgroundColor: '#17a2b8',
        color: '#fff',
        border: 'none',
        borderRadius: '3px',
        cursor: 'pointer',
    },
    table: {
        width: '100%',
        borderCollapse: 'collapse',
        marginBottom: '20px',
    },
};

export default Reports;