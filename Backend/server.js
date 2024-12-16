const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
const path = require('path');
require('dotenv').config();

const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'kurs',
    password: '2628',
    port: 5432,
});

const app = express();
app.use(cors());
app.use(bodyParser.json());
app.use('/files/documents', express.static(path.join(__dirname, 'uploads/documents')));

// Middleware для проверки JWT-токена
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'Токен не предоставлен' });

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ message: 'Недействительный токен' });
        req.user = user;
        next();
    });
};

// Регистрация
app.post('/api/register', async (req, res) => {
    const { full_name, email, phone_number, employment_date, password } = req.body;
    try {
        const existingUser = await pool.query('SELECT * FROM employee WHERE email = $1', [email]);
        if (existingUser.rows.length > 0) {
            return res.status(400).json({ message: 'Пользователь с таким email уже существует' });
        }

        const result = await pool.query(
            'INSERT INTO employee (full_name, email, phone_number, employment_date, is_admin, password) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
            [full_name, email, phone_number, employment_date, false, password]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка регистрации');
    }
});

// Логин
app.post('/api/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const result = await pool.query(
            'SELECT * FROM employee WHERE email = $1 AND password = $2',
            [email, password]
        );
        const user = result.rows[0];
        if (user) {
            const token = jwt.sign(
                { 
                    id_employee: user.id_employee, 
                    email: user.email, 
                    is_admin: user.is_admin, 
                    full_name: user.full_name 
                },
                process.env.JWT_SECRET,
                { expiresIn: process.env.JWT_EXPIRES_IN }
            );

            res.json({ 
                token, 
                user: { 
                    id_employee: user.id_employee,
                    full_name: user.full_name,
                    email: user.email,
                    phone_number: user.phone_number,
                    employment_date: user.employment_date,
                    is_admin: user.is_admin 
                } 
            });
        } else {
            res.status(401).json({ message: 'Неверный логин или пароль' });
        }
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка авторизации');
    }
});

// Получение профиля
app.get('/api/profile/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;

    /*if (parseInt(id) !== req.user.id_employee && !req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ запрещен' });
    }*/

    try {
        const employeeResult = await pool.query('SELECT * FROM employee WHERE id_employee = $1', [id]);
        if (employeeResult.rows.length === 0) {
            return res.status(404).json({ message: 'Пользователь не найден' });
        }
        const employee = employeeResult.rows[0];

        const positionResult = await pool.query(`
            SELECT p.*, jt.name AS job_title, d.name AS department, o.office_number, bc.address AS business_center_address
            FROM position p
            LEFT JOIN job_title jt ON p.id_job_title = jt.id_job_title
            LEFT JOIN department d ON p.id_department = d.id_department
            LEFT JOIN office o ON d.id_office = o.id_office
            LEFT JOIN business_center bc ON o.id_business_center = bc.id_business_center
            WHERE p.id_employee = $1
            LIMIT 1
        `, [id]);

        const position = positionResult.rows[0] || null;

        const skillsResult = await pool.query(`
            SELECT sn.name AS skill_name, ls.level AS skill_level
            FROM skill_own so
            LEFT JOIN skill_name sn ON so.id_skill_name = sn.id_skill_name
            LEFT JOIN level_skill ls ON so.id_level_skill = ls.id_level_skill
            WHERE so.id_employee = $1
        `, [id]);

        const skills = skillsResult.rows;

        res.json({
            employee,
            position,
            skills
        });
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения профиля');
    }
});

// Получение всех офисов
app.get('/api/offices', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT o.id_office, o.office_number, bc.address AS business_center_address 
            FROM office o
            LEFT JOIN business_center bc ON o.id_business_center = bc.id_business_center
            ORDER BY o.id_office ASC
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения офисов');
    }
});

// Получение всех бизнес-центров
app.get('/api/business_centers', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM business_center ORDER BY id_business_center ASC');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения бизнес-центров');
    }
});

// Получение всех отделов
app.get('/api/departments', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT d.id_department, d.name AS department_name, d.open_hours, d.close_hours, 
                   d.department_phone_number, o.office_number, bc.address AS business_center_address
            FROM department d
            LEFT JOIN office o ON d.id_office = o.id_office
            LEFT JOIN business_center bc ON o.id_business_center = bc.id_business_center
            ORDER BY d.id_department ASC
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения отделов');
    }
});

// Получение всех должностей
app.get('/api/positions', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT p.id_position, p.name AS position_name, p.appointment_date, 
                   jt.name AS job_title, d.name AS department, o.office_number, 
                   bc.address AS business_center_address
            FROM position pLEFT JOIN job_title jt ON p.id_job_title = jt.id_job_title
            LEFT JOIN department d ON p.id_department = d.id_department
            LEFT JOIN office o ON d.id_office = o.id_office
            LEFT JOIN business_center bc ON o.id_business_center = bc.id_business_center
            ORDER BY p.id_position ASC
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения должностей');
    }
});

// Получение всех сотрудников (для админов)
app.get('/api/employees', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }

    try {
        const result = await pool.query('SELECT * FROM employee ORDER BY id_employee ASC');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения сотрудников');
    }
});

// Добавление сотрудника (админ)
app.post('/api/employees', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }

    const { full_name, email, phone_number, employment_date, is_admin, password } = req.body;
    try {
        const result = await pool.query(
            'INSERT INTO employee (full_name, email, phone_number, employment_date, is_admin, password) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
            [full_name, email, phone_number, employment_date, is_admin, password]
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка добавления сотрудника');
    }
});

// Обновление сотрудника (админ)
app.put('/api/employees/:id', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }

    const { id } = req.params;
    const { full_name, email, phone_number, employment_date, is_admin, password } = req.body;
    try {
        const result = await pool.query(
            'UPDATE employee SET full_name = $1, email = $2, phone_number = $3, employment_date = $4, is_admin = $5, password = $6 WHERE id_employee = $7 RETURNING *',
            [full_name, email, phone_number, employment_date, is_admin, password, id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Сотрудник не найден' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка обновления сотрудника');
    }
});

// Удаление сотрудника (админ)
app.delete('/api/employees/:id', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }

    const { id } = req.params;
    try {
        const result = await pool.query('DELETE FROM employee WHERE id_employee = $1 RETURNING *', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Сотрудник не найден' });
        }
        res.sendStatus(204);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка удаления сотрудника');
    }
});

// Получение всех документов
app.get('/api/documents', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT d.id_document, d.title, d.description, d.path_file, d.load_date, d.change_date, 
                   d.file_extention, d.id_employee, dt.name AS template_name
            FROM document d
            LEFT JOIN document_template dt ON d.id_document_template = dt.id_document_template
            ORDER BY d.id_document ASC
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения документов');
    }
});

// Создание документа
app.post('/api/documents', authenticateToken, async (req, res) => {
    const { title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template } = req.body;
    try {
        const result = await pool.query(
            `INSERT INTO document 
             (title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
            [title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка создания документа');
    }
});

// Обновление документа
app.put('/api/documents/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template } = req.body;
    try {
        const result = await pool.query(
            `UPDATE document 
             SET title = $1, description = $2, path_file = $3, load_date = $4, 
                 change_date = $5, file_extention = $6, id_employee = $7, 
                 id_document_template = $8
             WHERE id_document = $9 RETURNING *`,
            [title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template, id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Документ не найден' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка обновления документа');
    }
});

// Удаление документа
app.delete('/api/documents/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query('DELETE FROM document WHERE id_document = $1 RETURNING *', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Документ не найден' });
        }
        res.sendStatus(204);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка удаления документа');
    }
});


// Маршруты отчетов

// 1. Отчет по сотрудникам
app.get('/api/reports/employees', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(`SELECT * FROM generate_employee_position_document_report()`);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения отчета по сотрудникам');
    }
});

// 2. Отчет по уникальным навыкам
app.get('/api/reports/unique-skills', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    try {
        const result = await pool.query(`SELECT * FROM find_unique_skills_in_department()`);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения отчета по уникальным навыкам');
    }
});

// 3. Сотрудники без телефона
app.get('/api/reports/employees-without-phone', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    try {
        const result = await pool.query(`SELECT * FROM ListEmployeesWithoutPhone()`);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения списка сотрудников без телефона');
    }
});

// 4. Уведомить неактивных сотрудников
app.post('/api/reports/notify-inactive', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { norm } = req.body; //Норма сообщений
    try {
        await pool.query(`SELECT NotifyInactiveEmployees($1)`, [norm]);
        res.status(200).json({ message: 'Уведомления отправлены' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка отправки уведомлений о неактивности');
    }
});

// 5. Присвоить роль сотрудникам
app.post('/api/reports/assign-role', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { norm, role } = req.body;
    try {
        await pool.query(`SELECT SetSpecialRole($1, $2)`, [norm, role]);
        res.status(200).json({ message: 'Роли присвоены' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка присвоения ролей');
    }
});

// 6. Уведомить о низких навыках
app.post('/api/reports/notify-low-skills', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { norm } = req.body; // Пороговый уровень навыка
    try {
        await pool.query(`SELECT notify_low_skill_levels($1)`, [norm]);
        res.status(200).json({ message: 'Уведомления о низких навыках отправлены' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка отправки уведомлений о низких навыках');
    }
});



// Получение всех визиток с типами
app.get('/api/business_cards', authenticateToken, async (req, res) => {
   

    try {
        const result = await pool.query(`
            SELECT bc.*, ct.type AS card_type
            FROM business_card bc
            LEFT JOIN card_type ct ON bc.id_card_type = ct.id_card_type
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения визиток');
    }
});




// Добавление визитки (админ)
app.post('/api/business_cards', authenticateToken, async (req, res) => {
   

    const { content, creation_date, id_card_type, id_employee } = req.body;
    try {
        const result = await pool.query(
            'INSERT INTO business_card (content, creation_date, id_card_type, id_employee) VALUES ($1, $2, $3, $4) RETURNING *',
            [content, creation_date, id_card_type, id_employee]
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка добавления визитки');
    }
});



// Обновление визитки (админ)
app.put('/api/business_cards/:id', authenticateToken, async (req, res) => {
    

    const { id } = req.params;
    const { content, creation_date, id_card_type, id_employee } = req.body;
    try {
        const result = await pool.query(
            'UPDATE business_card SET content = $1, creation_date = $2, id_card_type = $3, id_employee = $4 WHERE id_business_card = $5 RETURNING *',
            [content, creation_date, id_card_type, id_employee, id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Визитка не найдена' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка обновления визитки');
    }
});




// Удаление визитки (админ)
app.delete('/api/business_cards/:id', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }

    const { id } = req.params;
    try {
        const result = await pool.query('DELETE FROM business_card WHERE id_business_card = $1 RETURNING *', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Визитка не найдена' });
        }
        res.sendStatus(204);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка удаления визитки');
    }
});


// Получение всех чатов пользователя
app.get('/api/chats', authenticateToken, async (req, res) => {
    const { userId } = req.params;

    

    try {
        const result = await pool.query(`SELECT gc.id_group_chat, gc.name, gc.creation_date
             FROM group_chat gc
             JOIN participation_chats pc ON gc.id_group_chat = pc.id_group_chat
            `
            
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения чатов');
    }
});

app.post('/api/chats/:chatId/add-employees', authenticateToken, async (req, res) => {
    const { chatId } = req.params;
    const { employeeIds } = req.body; // Ожидается массив ID сотрудников

    if (!Array.isArray(employeeIds) || employeeIds.length === 0) {
        return res.status(400).json({ message: 'employeeIds должен быть непустым массивом' });
    }

    try {
        // Проверяем, существует ли чат
        const chatResult = await pool.query('SELECT * FROM group_chat WHERE id_group_chat = $1', [chatId]);
        if (chatResult.rows.length === 0) {
            return res.status(404).json({ message: 'Чат не найден' });
        }

        // Проверяем, существует ли каждый сотрудник и уже не участвует ли он в чате
        const validEmployeeIds = [];
        for (const id of employeeIds) {
            const employeeResult = await pool.query('SELECT * FROM employee WHERE id_employee = $1', [id]);
            if (employeeResult.rows.length === 0) {
                return res.status(404).json({ message: `Сотрудник с ID ${id} не найден` });
            }

            const participationResult = await pool.query(
                'SELECT * FROM participation_chats WHERE id_group_chat = $1 AND id_employee = $2',
                [chatId, id]
            );

            if (participationResult.rows.length === 0) { // Только если сотрудник ещё не участвует
                validEmployeeIds.push(id);
            }
        }

        if (validEmployeeIds.length === 0) {
            return res.status(400).json({ message: 'Все сотрудники уже участвуют в чате' });
        }

        // Добавляем сотрудников в чат
        const insertPromises = validEmployeeIds.map(id => {
            return pool.query(
                'INSERT INTO participation_chats (id_group_chat, id_employee) VALUES ($1, $2)',
                [chatId, id]
            );
        });

        await Promise.all(insertPromises);

        res.status(200).json({ message: 'Сотрудники успешно добавлены в чат', addedEmployeeIds: validEmployeeIds });
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка добавления сотрудников в чат');
    }
});

// Получение всех чатов пользователя
app.get('/api/chats/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;

    

    try {
        const result = await pool.query(`SELECT gc.id_group_chat, gc.name, gc.creation_date
             FROM group_chat gc
             JOIN participation_chats pc ON gc.id_group_chat = pc.id_group_chat
             WHERE pc.id_employee = $1`,
            [userId]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения чатов');
    }
});



// Получение сообщений чата
app.get('/api/chats/:id_group_chat/messages', authenticateToken, async (req, res) => {
    const { id_group_chat } = req.params;
    try {
        const result = await pool.query(`
            SELECT gm.id_group_message, gm.content, gm.send_time, gm.id_sender, e.full_name, gm.id_read_status
             FROM group_messages gm
             JOIN employee e ON gm.id_sender = e.id_employee
             WHERE gm.id_group_chat = $1
             ORDER BY gm.send_time ASC`,
            [id_group_chat]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения сообщений');
    }
});




// Отправка сообщения в чат
app.post('/api/chats/:id_group_chat/messages', authenticateToken, async (req, res) => {
    const { id_group_chat } = req.params;
    const { content } = req.body;
    const senderId = req.user.id_employee;

    try {
        const result = await pool.query(`
            INSERT INTO group_messages (id_group_chat, id_sender, content, send_time, id_read_status)
             VALUES ($1, $2, $3, NOW(), 1)
             RETURNING *`,
            [id_group_chat, senderId, content]
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка отправки сообщения');
    }
});




// Отправка личного сообщения
app.post('/api/messages', authenticateToken, async (req, res) => {
    const { id_requester, content } = req.body;
    const senderId = req.user.id_employee;

    try {
        await pool.query('SELECT send_message($1, $2, $3)', [senderId, id_requester, content]);
        res.status(201).json({ message: 'Сообщение отправлено успешно' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка отправки сообщения');
    }
});



// Получение личных сообщений с конкретным пользователем
app.get('/api/messages/:userId', authenticateToken, async (req, res) => {
    const { userId } = req.params;
    const currentUserId = req.user.id_employee;

    

    try {
        const result = await pool.query(
            `SELECT m.id_message, m.content, m.send_time, m.id_sender, e.full_name, m.id_read_status
             FROM messages m
             JOIN employee e ON m.id_sender = e.id_employee
             WHERE (m.id_sender = $1 AND m.id_requester = $2)
                OR (m.id_sender = $2 AND m.id_requester = $1)
             ORDER BY m.send_time ASC`,
            [currentUserId, userId]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения сообщений');
    }
});




// Отметка личного сообщения как прочитанного
app.post('/api/messages/:id_message/read', authenticateToken, async (req, res) => {
    const { id_message } = req.params;
    try {
        await pool.query('SELECT mark_message_as_read($1)', [id_message]);
        res.status(200).json({ message: 'Сообщение отмечено как прочитанное' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка отметки сообщения');
    }
});




// Получение мероприятий с информацией о создателе и месте проведения
app.get('/api/events', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT e.*, 
                   emp.full_name AS creator_name, 
                   el.name AS event_location_name
            FROM events e
            LEFT JOIN employee emp ON e.id_employee = emp.id_employee
            LEFT JOIN event_location el ON e.id_event_location = el.id_event_location
        `);
        
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения мероприятий');
    }
});




// Создание мероприятия с использованием функции create_event
app.post('/api/events', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }

    const { name, discription, date, id_event_location } = req.body;
    const id_employee_creator = req.user.id_employee;
    const bot_id = 0; // Замените на реальный ID бота, если требуется

    try {
        await pool.query('SELECT create_event($1, $2, $3, $4, $5, $6)', [
            name, 
            discription, 
            date, 
            id_event_location, 
            id_employee_creator, 
            bot_id
        ]);
        res.status(201).json({ message: 'Мероприятие создано успешно' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка добавления мероприятия');
    }
});




app.put('/api/events/:id', authenticateToken, async (req, res) => {
    

    const { id } = req.params;
    const { name, discription, date, id_event_location, id_employee } = req.body;
    try {
        const result = await pool.query(
            'UPDATE events SET name = $1, discription = $2, date = $3, id_event_location = $4, id_employee = $5 WHERE id_event = $6 RETURNING *',
            [name, discription, date, id_event_location, id_employee, id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Мероприятие не найдено' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка обновления мероприятия');
    }
});




app.delete('/api/events/:id', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }

    const { id } = req.params;
    try {
        const result = await pool.query('DELETE FROM events WHERE id_event = $1 RETURNING *', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Мероприятие не найдено' });
        }
        res.sendStatus(204);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка удаления мероприятия');
    }
});




// Маршрут для получения мест проведения мероприятий
app.get('/api/event_locations', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM event_location');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения мест проведения мероприятий');
    }
});




// Получение активных объявлений
app.get('/api/announcements/active', authenticateToken, async (req, res) => {
    try {
        const result = await pool.qu


ery('SELECT * FROM ListActiveAnnouncements()');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения объявлений');
    }
});




// Получение всех объявлений
app.get('/api/announcements/all', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM announcements');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения объявлений');
    }
});





// Маршрут для проверки активности сотрудников
app.post('/api/check_employee_activity', authenticateToken, async (req, res) => {
    try {
        await pool.query('SELECT check_employee_activity()');
        res.sendStatus(200);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка проверки активности сотрудников');
    }
});




// Получение типов визиток
app.get('/api/card_types', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM card_type');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения типов визиток');
    }
});




// Получение шаблонов документов
app.get('/api/document_template', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM public.document_template');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения шаблонов документов');
    }
});



// Получение количества непрочитанных уведомлений
app.get('/api/messages/unread-count', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM CountUnreadMessagesPerEmployee() WHERE id_requester = $1', [req.user.id_employee]);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения количества непрочитанных сообщений');
    }
});




// Маршруты отчетов

// 1. Отчет по сотрудникам
app.get('/api/reports/employees', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(`SELECT * FROM generate_employee_position_document_report()`);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения отчета по сотрудникам');
    }
});

// 2. Отчет по уникальным навыкам
app.get('/api/reports/unique-skills', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    try {
        const result = await pool.query(`SELECT * FROM find_unique_skills_in_department()`);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения отчета по уникальным навыкам');
    }
});

// 3. Сотрудники без телефона
app.get('/api/reports/employees-without-phone', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    try {
        const result = await pool.query(`SELECT * FROM ListEmployeesWithoutPhone()`);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения списка сотрудников без телефона');
    }
});

// 4. Уведомить неактивных сотрудников
app.post('/api/reports/notify-inactive', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { norm } = req.body; //Норма сообщений
    try {
        await pool.query(`SELECT NotifyInactiveEmployees($1)`, [norm]);
        res.status(200).json({ message: 'Уведомления отправлены' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка отправки уведомлений о неактивности');
    }
});

// 5. Присвоить роль сотрудникам
app.post('/api/reports/assign-role', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { norm, role } = req.body;
    try {
        await pool.query(`SELECT SetSpecialRole($1, $2)`, [norm, role]);
        res.status(200).json({ message: 'Роли присвоены' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка присвоения ролей');
    }
});

// 6. Уведомить о низких навыках
app.post('/api/reports/notify-low-skills', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { norm } = req.body; // Пороговый уровень навыка
    try {
        await pool.query(`SELECT notify_low_skill_levels($1)`, [norm]);
        res.status(200).json({ message: 'Уведомления о низких навыках отправлены' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка отправки уведомлений о низких навыках');
    }
});


// Получение всех уведомлений (админ)
app.get('/api/announcements/all', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    try {
        const result = await pool.query('SELECT * FROM announcements ORDER BY id_announcement DESC');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения уведомлений');
    }
});

// Создание нового уведомления (админ)
app.post('/api/announcements', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { title, discription, creation_date, end_date, id_employee } = req.body;
    try {
        const result = await pool.query(
            `INSERT INTO announcements 
             (title, discription, creation_date, end_date, id_employee) 
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [title, discription, creation_date, end_date, id_employee]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка создания уведомления');
    }
});

// Обновление уведомления (админ)
app.put('/api/announcements/:id', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { id } = req.params;
    const { title, discription, creation_date, end_date, id_employee } = req.body;
    try {
        const result = await pool.query(
            `UPDATE announcements 
             SET title = $1, discription = $2, creation_date = $3, end_date = $4, id_employee = $5 
             WHERE id_announcement = $6 RETURNING *`,
            [title, discription, creation_date, end_date, id_employee, id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Уведомление не найдено' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка обновления уведомления');
    }
});

// Удаление уведомления (админ)
app.delete('/api/announcements/:id', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { id } = req.params;
    try {
        const result = await pool.query('DELETE FROM announcements WHERE id_announcement = $1 RETURNING *', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Уведомление не найдено' });
        }
        res.sendStatus(204);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка удаления уведомления');
    }
});


// Получение количества непрочитанных уведомлений
app.get('/api/messages/unread-count', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM CountUnreadMessagesPerEmployee() WHERE id_requester = $1', [req.user.id_employee]);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения количества непрочитанных сообщений');
    }
});


// Создание нового уведомления (админ)
app.post('/api/announcements', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { title, discription, creation_date, end_date, id_employee } = req.body;
    try {
        const result = await pool.query(
            `INSERT INTO announcements 
             (title, discription, creation_date, end_date, id_employee) 
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [title, discription, creation_date, end_date, id_employee]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка создания уведомления');
    }
});

// Обновление уведомления (админ)
app.put('/api/announcements/:id', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { id } = req.params;
    const { title, discription, creation_date, end_date, id_employee } = req.body;
    try {
        const result = await pool.query(
            `UPDATE announcements 
             SET title = $1, discription = $2, creation_date = $3, end_date = $4, id_employee = $5 
             WHERE id_announcement = $6 RETURNING *`,
            [title, discription, creation_date, end_date, id_employee, id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Уведомление не найдено' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка обновления уведомления');
    }
});

// Удаление уведомления (админ)
app.delete('/api/announcements/:id', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }
    const { id } = req.params;
    try {
        const result = await pool.query('DELETE FROM announcements WHERE id_announcement = $1 RETURNING *', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Уведомление не найдено' });
        }
        res.sendStatus(204);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка удаления уведомления');
    }
});

// Запуск сервера
const PORT = 5000;
app.listen(PORT, () => {
    console.log(`Сервер запущен на порту ${PORT}`);
});


