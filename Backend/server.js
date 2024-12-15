const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
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
        // Проверка, существует ли уже пользователь с таким email
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
            'SELECT * FROM public.employee WHERE email = $1 AND password = $2',
            [email, password]
        );
        const user = result.rows[0];
        if (user) {
            // Создание JWT-токена
            const token = jwt.sign(
                { id_employee: user.id_employee, email: user.email, is_admin: user.is_admin, full_name: user.full_name },
                process.env.JWT_SECRET,
                { expiresIn: process.env.JWT_EXPIRES_IN }
            );

            res.json({ token, user: { 
                id_employee: user.id_employee,
                full_name: user.full_name,
                email: user.email,phone_number: user.phone_number,
                employment_date: user.employment_date,
                is_admin: user.is_admin 
            } });
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

    // Проверка, запрашивает ли пользователь только свой профиль или админ запрашивает любой
    if (parseInt(id) !== req.user.id_employee && !req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ запрещен' });
    }

    try {
        const result = await pool.query('SELECT * FROM employee WHERE id_employee = $1', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Пользователь не найден' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения профиля');
    }
});

// Пример защищенного маршрута для получения всех сотрудников (только для админов)
app.get('/api/employees', authenticateToken, async (req, res) => {
    if (!req.user.is_admin) {
        return res.status(403).json({ message: 'Доступ только для администраторов' });
    }

    try {
        const result = await pool.query('SELECT * FROM employee');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения сотрудников');
    }
});
app.post('/api/employees',  authenticateToken, async (req, res) => {
    const { full_name, email, phone_number, employment_date, is_admin } = req.body;
    try {
        const result = await pool.query(
            'INSERT INTO employee (full_name, email, phone_number, employment_date, is_admin) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [full_name, email, phone_number, employment_date, is_admin]
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка добавления сотрудника');
    }
});

app.put('/api/employees/:id',  authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { full_name, email, phone_number, employment_date, is_admin } = req.body;
    try {
        const result = await pool.query(
            'UPDATE employee SET full_name = $1, email = $2, phone_number = $3, employment_date = $4, is_admin = $5 WHERE id_employee = $6 RETURNING *',
            [full_name, email, phone_number, employment_date, is_admin, id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка обновления сотрудника');
    }
});

app.delete('/api/employees/:id',  authenticateToken, async (req, res) => {
    const { id } = req.params;
    try {
        await pool.query('DELETE FROM employee WHERE id_employee = $1', [id]);
        res.sendStatus(204);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка удаления сотрудника');
    }
});

   // CRUD для документов (доступно только администраторам)
app.get('/api/documents',  authenticateToken, async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM document');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения документов');
    }
});

app.post('/api/documents',  authenticateToken, async (req, res) => {
    const { title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template } = req.body;
    try {
        const result = await pool.query(
            `INSERT INTO document 
            (title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
            [title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template]
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка добавления документа');
    }
});

app.put('/api/documents/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template } = req.body;
    try {
        const result = await pool.query(
            `UPDATE document SET 
                title = $1, 
                description = $2, 
                path_file = $3, 
                load_date = $4, 
                change_date = $5, 
                file_extention = $6, 
                id_employee = $7, 
                id_document_template = $8 
            WHERE id_document = $9 RETURNING *`,
            [title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template, id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка обновления документа');
    }
});
app.delete('/api/documents/:id',  authenticateToken, async (req, res) => {
    const { id } = req.params;
    try {
        await pool.query('DELETE FROM document WHERE id_document = $1', [id]);
        res.sendStatus(204);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка удаления документа');
    }
});

    // Пример вызова функции check_employee_activity
/*app.post('/api/check_employee_activity', async (req, res) => {
    try {
        await pool.query('SELECT * public.check_employee_activity()');
        res.sendStatus(200);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка проверки активности сотрудников');
    }
});*/
// Получение всех чатов пользователя
app.get('/api/chats/:userId', async (req, res) => {
    const { userId } = req.params;
    try {
        const result = await pool.query(
            `SELECT gc.id_group_chat, gc.name, gc.creation_date
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
app.get('/api/chats/:id_group_chat/messages', async (req, res) => {
    const { id_group_chat } = req.params;
    try {
        const result = await pool.query(
            `SELECT gm.id_group_message, gm.content, gm.send_time, gm.id_sender, e.full_name
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
app.post('/api/chats/:id_group_chat/messages', async (req, res) => {
    const { id_group_chat } = req.params;
    const { content } = req.body;
    const senderId = req.user.id;

    try {
        const result = await pool.query(
            `INSERT INTO group_messages (id_group_chat, id_sender, content, send_time)
             VALUES ($1, $2, $3, NOW())
             RETURNING *`,
            [id_group_chat, senderId, content]
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка отправки сообщения');
    }
});

// Отметка сообщения как прочитанного
app.post('/api/messages/:id_message/read', async (req, res) => {
    const { id_message } = req.params;
    try {
        await pool.query(
            `UPDATE group_messages
             SET id_read_status = 2
             WHERE id_group_message = $1`,
            [id_message]
        );
        res.sendStatus(200);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка обновления статуса сообщения');
    }
});
app.get('/api/events', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM public.events');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения количества непрочитанных сообщений');
    }
});
app.get('/api/announcements/active', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM ListActiveAnnouncements()');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения объявлений');
    }
});

app.get('/api/announcements/all', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM public.announcements');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения объявлений');
    }
});

// Получение количества непрочитанных сообщений
app.get('/api/messages/unread-count', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM CountUnreadMessagesPerEmployee()');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка получения количества непрочитанных сообщений');
    }
});
// Маршрут дляпроверки активности сотрудников
app.post('/api/check_employee_activity', authenticateToken, async (req, res) => {
    try {
        await pool.query('SELECT check_employee_activity()');
        res.sendStatus(200);
    } catch (err) {
        console.error(err);
        res.status(500).send('Ошибка проверки активности сотрудников');
    }
});

// Запуск сервера
const PORT = 5000;
app.listen(PORT, () => {
    console.log(`Сервер запущен на порту ${PORT}`);
});