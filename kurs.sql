PGDMP                       |            kurs    16.3    16.3 I   u           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            v           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            w           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            x           1262    17157    kurs    DATABASE     x   CREATE DATABASE kurs WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';
    DROP DATABASE kurs;
                postgres    false            +           1255    17158    check_employee_activity()    FUNCTION     N  CREATE FUNCTION public.check_employee_activity() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec RECORD;
    employment_duration INT;
BEGIN
    FOR rec IN SELECT id_employee, full_name, employment_date FROM employee LOOP
        employment_duration := DATE_PART('year', AGE(NOW(), rec.employment_date));

        IF employment_duration > 5 THEN
            -- Вставляем уведомление
            INSERT INTO notifications (id_employee, content)
            VALUES (
                rec.id_employee,
                'Вы работаете в компании более 5 лет. Рассмотрите возможность повышения или получения дополнительного бонуса.'
            );
        ELSIF employment_duration BETWEEN 2 AND 5 THEN
            INSERT INTO notifications (id_employee, content)
            VALUES (
                rec.id_employee,
                'Вы работаете в компании уже ' || employment_duration || ' лет.'
            );
        ELSE
            INSERT INTO notifications (id_employee, content)
            VALUES (
                rec.id_employee,
                'Вы недавно присоединились к компании. Добро пожаловать!'
            );
        END IF;
    END LOOP;
END;
$$;
 0   DROP FUNCTION public.check_employee_activity();
       public          postgres    false                       1255    17159     countunreadmessagesperemployee()    FUNCTION       CREATE FUNCTION public.countunreadmessagesperemployee() RETURNS TABLE(employee_name character varying, unread_count integer)
    LANGUAGE plpgsql
    AS $$

BEGIN
    FOR employee_name, unread_count IN
        SELECT e.full_name, COUNT(m.id_message)
        FROM employee e
        JOIN messages m ON e.id_employee = m.id_requester
        JOIN read_status rs ON m.id_read_status = rs.id_read_status
        WHERE rs.status = true
        GROUP BY e.full_name
    LOOP
        RETURN NEXT;
    END LOOP;
END;
$$;
 7   DROP FUNCTION public.countunreadmessagesperemployee();
       public          postgres    false            )           1255    17977 N   create_announcement(character varying, character varying, date, date, integer)    FUNCTION     
  CREATE FUNCTION public.create_announcement(p_title character varying, p_discription character varying, p_creation_date date, p_end_date date, p_id_employee integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO announcements (title, discription, creation_date, end_date, id_employee)
    VALUES (p_title, p_discription, p_creation_date, p_end_date, p_id_employee);

    -- Создаем уведомления для всех сотрудников об активном объявлении
    INSERT INTO notifications (id_employee, content)
    SELECT id_employee, CONCAT('Новое объявление: ', p_title, '. ', p_discription, ' Действительно с ', p_creation_date::text, ' по ', p_end_date::text)
    FROM employee;
END;
$$;
 �   DROP FUNCTION public.create_announcement(p_title character varying, p_discription character varying, p_creation_date date, p_end_date date, p_id_employee integer);
       public          postgres    false            (           1255    17160 S   create_event(character varying, character varying, date, integer, integer, integer)    FUNCTION     J  CREATE FUNCTION public.create_event(p_name character varying, p_description character varying, p_date date, p_event_location integer, p_employee_creator integer, p_bot_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_event_id INT;
BEGIN
    -- Добавляем новое событие в таблицу events
    INSERT INTO events (name, discription, date, id_event_location, id_employee)
    VALUES (p_name, p_description, p_date, p_event_location, p_employee_creator)
    RETURNING id_event INTO v_event_id;

    -- Предоставляем доступ всем сотрудникам к этому событию
    INSERT INTO event_access (id_event, id_employee)
    SELECT v_event_id, id_employee
    FROM employee;

    -- Создаем уведомления для всех сотрудников о новом событии
    INSERT INTO notifications (id_employee, content)
    SELECT id_employee, CONCAT('Новое мероприятие: ', p_name, '. ', p_description, ' Запланировано на ', p_date::text)
    FROM employee;
END;
$$;
 �   DROP FUNCTION public.create_event(p_name character varying, p_description character varying, p_date date, p_event_location integer, p_employee_creator integer, p_bot_id integer);
       public          postgres    false            /           1255    18311 "   find_unique_skills_in_department()    FUNCTION     �  CREATE FUNCTION public.find_unique_skills_in_department() RETURNS TABLE(employee_id integer, employee_name character varying, department_name character varying, skill_name character varying)
    LANGUAGE plpgsql
    AS $$

BEGIN
  RETURN QUERY
  SELECT
    e.id_employee AS employee_id,
    e.full_name AS employee_name,
    d.name AS department_name,
    s.name AS skill_name
  FROM
    employee e
  JOIN
    position p ON e.id_employee = p.id_employee
  JOIN
    department d ON p.id_department = d.id_department
  JOIN
    skill_own so ON e.id_employee = so.id_employee
  JOIN
    skill_name s ON so.id_skill_name = s.id_skill_name
  WHERE
    s.id_skill_name IN (
      SELECT
        so2.id_skill_name
      FROM
        skill_own so2
      JOIN
        position p2 ON so2.id_employee = p2.id_employee
      WHERE
        p2.id_department = p.id_department
      GROUP BY
        so2.id_skill_name
      HAVING
        COUNT(so2.id_employee) = 1
    );
END;
$$;
 9   DROP FUNCTION public.find_unique_skills_in_department();
       public          postgres    false                       1255    17162 ,   generate_employee_position_document_report()    FUNCTION     �  CREATE FUNCTION public.generate_employee_position_document_report() RETURNS TABLE(employee_name character varying, employee_email character varying, job_title_name character varying, position_name character varying, document_title character varying, document_description character varying, document_load_date date)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.full_name AS employee_name,
        e.email AS employee_email,
        jt.name AS job_title_name,
        p.name AS position_name,
        d.title::character varying AS document_title,
        d.description AS document_description,
        d.load_date AS document_load_date
    FROM
        "position" p
    JOIN
        "employee" e ON p.id_employee = e.id_employee
    JOIN
        "job_title" jt ON p.id_job_title = jt.id_job_title
    LEFT JOIN
        "document" d ON e.id_employee = d.id_employee
    ORDER BY
        p.name, e.full_name;
END;
$$;
 C   DROP FUNCTION public.generate_employee_position_document_report();
       public          postgres    false                       1255    17163 #   get_employee_contact_chain(integer)    FUNCTION     �  CREATE FUNCTION public.get_employee_contact_chain(employee_id integer) RETURNS TABLE(full_name character varying, job_title character varying, department_name character varying, department_phone_number character varying, internal_phone_number character varying, employee_email character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.full_name,                   -- Имя сотрудника
        jt.name AS job_title,           -- Название должности
        d.name AS department_name,      -- Название отдела
        d.department_phone_number,      -- Номер телефона отдела
        ip.internal_number AS internal_phone_number, -- Внутренний номер телефона сотрудника
        e.email AS employee_email       -- Email сотрудника
    FROM 
        employee e
    JOIN 
        position p ON e.id_employee = p.id_employee
    JOIN 
        job_title jt ON p.id_job_title = jt.id_job_title
    JOIN 
        department d ON p.id_department = d.id_department
    JOIN 
        ip_phone ip ON p.id_phone = ip.id_phone
    WHERE 
        e.id_employee = employee_id;
END;
$$;
 F   DROP FUNCTION public.get_employee_contact_chain(employee_id integer);
       public          postgres    false            %           1255    17971 #   get_employee_notifications(integer)    FUNCTION     y  CREATE FUNCTION public.get_employee_notifications(p_employee_id integer) RETURNS TABLE(id_notification integer, content text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT n.id_notification, n.content, n.created_at
    FROM notifications n
    WHERE n.id_employee = p_employee_id
    ORDER BY n.created_at DESC;
END;
$$;
 H   DROP FUNCTION public.get_employee_notifications(p_employee_id integer);
       public          postgres    false                       1255    17164    isannouncementactive(smallint)    FUNCTION     �  CREATE FUNCTION public.isannouncementactive(p_announcement_id smallint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_creation DATE;
    v_end DATE;
BEGIN
    SELECT creation_date, end_date INTO v_creation, v_end
    FROM announcements
    WHERE id_announcement = p_announcement_id;

    IF CURRENT_DATE BETWEEN v_creation AND v_end THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$;
 G   DROP FUNCTION public.isannouncementactive(p_announcement_id smallint);
       public          postgres    false                       1255    17165    isannouncementactive(integer)    FUNCTION     �  CREATE FUNCTION public.isannouncementactive(p_announcement_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_creation DATE;
    v_end DATE;
BEGIN
    SELECT creation_date, end_date INTO v_creation, v_end
    FROM announcements
    WHERE id_announcement = p_announcement_id;

    IF CURRENT_DATE BETWEEN v_creation AND v_end THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$;
 F   DROP FUNCTION public.isannouncementactive(p_announcement_id integer);
       public          postgres    false                       1255    17166    listactiveannouncements()    FUNCTION     �  CREATE FUNCTION public.listactiveannouncements() RETURNS TABLE(title character varying, description character varying, creation_date date, end_date date)
    LANGUAGE plpgsql
    AS $$
BEGIN
    FOR title, description, creation_date, end_date IN
        SELECT a.title, a.discription, a.creation_date, a.end_date
        FROM announcements a
        WHERE CURRENT_DATE BETWEEN a.creation_date AND a.end_date
    LOOP
        RETURN NEXT;
    END LOOP;
END;
$$;
 0   DROP FUNCTION public.listactiveannouncements();
       public          postgres    false                        1255    17167    listemployeeswithoutphone()    FUNCTION     �  CREATE FUNCTION public.listemployeeswithoutphone() RETURNS TABLE(employee_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    FOR employee_name IN
        SELECT e.full_name
        FROM employee e
        LEFT JOIN position p ON e.id_employee = p.id_employee
        WHERE e.phone_number IS NULL OR e.phone_number = '' 
           OR p.id_phone IS NULL
    LOOP
        RETURN NEXT;
    END LOOP;
END;
$$;
 2   DROP FUNCTION public.listemployeeswithoutphone();
       public          postgres    false            .           1255    17955    listtodaysevents()    FUNCTION     �  CREATE FUNCTION public.listtodaysevents() RETURNS TABLE(id_event integer, name character varying, discription character varying, date date, id_event_location integer, id_employee integer, creator_name character varying, event_location_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id_event, 
        e.name, 
        e.discription, 
        e.date, 
        e.id_event_location, 
        e.id_employee, 
        emp.full_name AS creator_name,
        el.name AS event_location_name
    FROM 
        events e
    LEFT JOIN employee emp ON e.id_employee = emp.id_employee
    LEFT JOIN event_location el ON e.id_event_location = el.id_event_location
    WHERE 
        e.date = CURRENT_DATE;
END;
$$;
 )   DROP FUNCTION public.listtodaysevents();
       public          postgres    false            !           1255    17168    mark_message_as_read(bigint)    FUNCTION     �   CREATE FUNCTION public.mark_message_as_read(p_message_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE messages
    SET id_read_status = 2 -- Статус 2 = прочитано
    WHERE id_message = p_message_id;
END;
$$;
 @   DROP FUNCTION public.mark_message_as_read(p_message_id bigint);
       public          postgres    false            *           1255    17169 S   notify_event(integer, character varying, character varying, date, integer, integer)    FUNCTION     G  CREATE FUNCTION public.notify_event(p_event_id integer, p_event_name character varying, p_description character varying, p_event_date date, p_creator_id integer, p_bot_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
v_message_content character varying;
BEGIN
-- Generate an event message
v_message_content := 'New event: ' || p_event_name || E'\nDescription: ' || p_description ||
E'\nDate: ' || p_event_date || E'\nEvent creator: ' || p_creator_id;

-- Send a message to each employee
 INSERT INTO messages (id_sender, content, send_time, id_read_status, id_requester)
 SELECT p_bot_id, v_message_content, localtimestamp(0), 1, id_employee
 FROM employee;

 -- Write notifications to the notifications table
 INSERT INTO notifications (id_employee, content)
 SELECT id_employee, v_message_content
 FROM employee;
END;
$$;
 �   DROP FUNCTION public.notify_event(p_event_id integer, p_event_name character varying, p_description character varying, p_event_date date, p_creator_id integer, p_bot_id integer);
       public          postgres    false            -           1255    17170     notify_low_skill_levels(integer)    FUNCTION     ^  CREATE FUNCTION public.notify_low_skill_levels(norm integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT
            so.id_employee,
            sn.name AS skill_name,
            so.id_level_skill
        FROM
            skill_own so
        JOIN
            skill_name sn ON so.id_skill_name = sn.id_skill_name
    LOOP
        IF rec.id_level_skill < norm THEN
            -- Вставляем уведомление в таблицу notifications
            INSERT INTO notifications (id_employee, content)
            VALUES (
                rec.id_employee, 
                'Ваш уровень навыка "' || rec.skill_name || '" ниже порога ' || norm || '. Пожалуйста, улучшите свой навык.'
            );
        END IF;
    END LOOP;
END;
$$;
 <   DROP FUNCTION public.notify_low_skill_levels(norm integer);
       public          postgres    false            '           1255    17973     notify_new_announcement(integer)    FUNCTION       CREATE FUNCTION public.notify_new_announcement(p_announcement_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_title VARCHAR;
    v_discription VARCHAR;
    v_creation_date DATE;
    v_end_date DATE;
    v_creator_id INT;
    v_content TEXT;
BEGIN
    SELECT title, discription, creation_date, end_date, id_employee INTO v_title, v_discription, v_creation_date, v_end_date, v_creator_id
    FROM announcements
    WHERE id_announcement = p_announcement_id;
    
    v_content := 'Новое объявление: ' || v_title || E'\nОписание: ' || v_discription || 
                 E'\nС: ' || v_creation_date || E'\nПо: ' || v_end_date;
    
    INSERT INTO notifications (id_employee, content)
    SELECT id_employee, v_content
    FROM employee;
END;
$$;
 I   DROP FUNCTION public.notify_new_announcement(p_announcement_id integer);
       public          postgres    false                       1255    17171    notify_new_message()    FUNCTION     �  CREATE FUNCTION public.notify_new_message() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
-- Notify with recipient ID
PERFORM pg_notify('new_message', NEW.id_requester::character varying);

-- Insert a record into notifications
INSERT INTO notifications (id_employee, content)
VALUES (NEW.id_requester, 'You have a new message from employee ID ' || NEW.id_sender);

RETURN NEW;
END;
$$;
 +   DROP FUNCTION public.notify_new_message();
       public          postgres    false            $           1255    17172     notifyinactiveemployees(integer)    FUNCTION     R  CREATE FUNCTION public.notifyinactiveemployees(norm integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO notifications (id_employee, content)
    SELECT 
        e.id_employee,
        FORMAT('Сотрудник %s (ID: %s) отправил %s сообщений, что меньше нормы %s.', 
               e.full_name, e.id_employee, COUNT(m.id_message), norm)
    FROM 
        employee e
    LEFT JOIN 
        messages m ON m.id_sender = e.id_employee
    GROUP BY 
        e.id_employee, e.full_name
    HAVING 
        COUNT(m.id_message) < norm;
END;
$$;
 <   DROP FUNCTION public.notifyinactiveemployees(norm integer);
       public          postgres    false            #           1255    17173 1   send_message(integer, integer, character varying)    FUNCTION       CREATE FUNCTION public.send_message(p_sender_id integer, p_requester_id integer, p_content character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO messages (id_sender, id_requester, content, send_time, id_read_status)
VALUES (p_sender_id, p_requester_id, p_content, localtimestamp(0), 1); -- Status 1 = unread

-- Write a notification to the message recipient
INSERT INTO notifications (id_employee, content)
VALUES (p_requester_id, 'New message from employee ID ' || p_sender_id);
END;
$$;
 m   DROP FUNCTION public.send_message(p_sender_id integer, p_requester_id integer, p_content character varying);
       public          postgres    false            &           1255    17972     send_notification(integer, text)    FUNCTION     �   CREATE FUNCTION public.send_notification(p_employee_id integer, p_content text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO notifications (id_employee, content)
    VALUES (p_employee_id, p_content);
END;
$$;
 O   DROP FUNCTION public.send_notification(p_employee_id integer, p_content text);
       public          postgres    false            ,           1255    17978 &   trigger_insert_notification_on_event()    FUNCTION     M  CREATE FUNCTION public.trigger_insert_notification_on_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_message_content character varying;
BEGIN
    v_message_content := 'Новое событие: ' || NEW.name || E'nОписание: ' || NEW.discription || 
                        E'nДата: ' || NEW.date || E'nСоздатель события ID: ' || NEW.id_employee;

    -- Insert into notifications for all employees
    INSERT INTO notifications (id_employee, content)
    SELECT id_employee, v_message_content
    FROM employee;

    RETURN NEW;
END;
$$;
 =   DROP FUNCTION public.trigger_insert_notification_on_event();
       public          postgres    false            "           1255    17174 $   validateskilllevel(integer, integer)    FUNCTION     �  CREATE FUNCTION public.validateskilllevel(p_skill_own_id integer, p_threshold integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_level INT;
BEGIN
    SELECT ls.level INTO v_level
    FROM skill_own so
    JOIN level_skill ls ON so.id_level_skill = ls.id_level_skill
    WHERE so.id_skill_own = p_skill_own_id;

    IF v_level >= p_threshold THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$;
 V   DROP FUNCTION public.validateskilllevel(p_skill_own_id integer, p_threshold integer);
       public          postgres    false            �            1259    17175    announcement_access    TABLE     �   CREATE TABLE public.announcement_access (
    id_announcement_access smallint NOT NULL,
    id_employee smallint NOT NULL,
    id_announcement smallint NOT NULL
);
 '   DROP TABLE public.announcement_access;
       public         heap    postgres    false            �            1259    17178 .   announcement_access_id_announcement_access_seq    SEQUENCE     �   CREATE SEQUENCE public.announcement_access_id_announcement_access_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 E   DROP SEQUENCE public.announcement_access_id_announcement_access_seq;
       public          postgres    false    215            y           0    0 .   announcement_access_id_announcement_access_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.announcement_access_id_announcement_access_seq OWNED BY public.announcement_access.id_announcement_access;
          public          postgres    false    216            �            1259    17179    announcements    TABLE     �   CREATE TABLE public.announcements (
    id_announcement smallint NOT NULL,
    title character varying NOT NULL,
    discription character varying NOT NULL,
    creation_date date NOT NULL,
    end_date date NOT NULL,
    id_employee smallint
);
 !   DROP TABLE public.announcements;
       public         heap    postgres    false            �            1259    17184 !   announcements_id_announcement_seq    SEQUENCE     �   CREATE SEQUENCE public.announcements_id_announcement_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE public.announcements_id_announcement_seq;
       public          postgres    false    217            z           0    0 !   announcements_id_announcement_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public.announcements_id_announcement_seq OWNED BY public.announcements.id_announcement;
          public          postgres    false    218            �            1259    17185    business_card    TABLE     �   CREATE TABLE public.business_card (
    id_business_card smallint NOT NULL,
    content character varying NOT NULL,
    creation_date date NOT NULL,
    id_card_type smallint,
    id_employee smallint
);
 !   DROP TABLE public.business_card;
       public         heap    postgres    false            �            1259    17190 "   business_card_id_business_card_seq    SEQUENCE     �   CREATE SEQUENCE public.business_card_id_business_card_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE public.business_card_id_business_card_seq;
       public          postgres    false    219            {           0    0 "   business_card_id_business_card_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE public.business_card_id_business_card_seq OWNED BY public.business_card.id_business_card;
          public          postgres    false    220            �            1259    17191    business_center    TABLE     z   CREATE TABLE public.business_center (
    id_business_center smallint NOT NULL,
    address character varying NOT NULL
);
 #   DROP TABLE public.business_center;
       public         heap    postgres    false            �            1259    17196 &   business_center_id_business_center_seq    SEQUENCE     �   CREATE SEQUENCE public.business_center_id_business_center_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 =   DROP SEQUENCE public.business_center_id_business_center_seq;
       public          postgres    false    221            |           0    0 &   business_center_id_business_center_seq    SEQUENCE OWNED BY     q   ALTER SEQUENCE public.business_center_id_business_center_seq OWNED BY public.business_center.id_business_center;
          public          postgres    false    222            �            1259    17197 	   card_type    TABLE     k   CREATE TABLE public.card_type (
    id_card_type smallint NOT NULL,
    type character varying NOT NULL
);
    DROP TABLE public.card_type;
       public         heap    postgres    false            �            1259    17202    card_type_id_card_type_seq    SEQUENCE     �   CREATE SEQUENCE public.card_type_id_card_type_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.card_type_id_card_type_seq;
       public          postgres    false    223            }           0    0    card_type_id_card_type_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.card_type_id_card_type_seq OWNED BY public.card_type.id_card_type;
          public          postgres    false    224            �            1259    17203 
   department    TABLE       CREATE TABLE public.department (
    id_department smallint NOT NULL,
    name character varying NOT NULL,
    open_hours time without time zone NOT NULL,
    close_hours time without time zone NOT NULL,
    department_phone_number character varying NOT NULL,
    id_office smallint
);
    DROP TABLE public.department;
       public         heap    postgres    false            �            1259    17208    department_id_department_seq    SEQUENCE     �   CREATE SEQUENCE public.department_id_department_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.department_id_department_seq;
       public          postgres    false    225            ~           0    0    department_id_department_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.department_id_department_seq OWNED BY public.department.id_department;
          public          postgres    false    226            �            1259    17209    document    TABLE     R  CREATE TABLE public.document (
    id_document smallint NOT NULL,
    title text NOT NULL,
    description character varying,
    path_file character varying NOT NULL,
    load_date date NOT NULL,
    change_date date NOT NULL,
    file_extention character varying NOT NULL,
    id_employee smallint,
    id_document_template smallint
);
    DROP TABLE public.document;
       public         heap    postgres    false            �            1259    17214    document_access    TABLE     �   CREATE TABLE public.document_access (
    id_event_access smallint NOT NULL,
    id_document smallint NOT NULL,
    id_employee smallint NOT NULL
);
 #   DROP TABLE public.document_access;
       public         heap    postgres    false            �            1259    17217 #   document_access_id_event_access_seq    SEQUENCE     �   CREATE SEQUENCE public.document_access_id_event_access_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 :   DROP SEQUENCE public.document_access_id_event_access_seq;
       public          postgres    false    228                       0    0 #   document_access_id_event_access_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE public.document_access_id_event_access_seq OWNED BY public.document_access.id_event_access;
          public          postgres    false    229            �            1259    17218    document_id_document_seq    SEQUENCE     �   CREATE SEQUENCE public.document_id_document_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.document_id_document_seq;
       public          postgres    false    227            �           0    0    document_id_document_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.document_id_document_seq OWNED BY public.document.id_document;
          public          postgres    false    230            �            1259    17219    document_template    TABLE     �   CREATE TABLE public.document_template (
    id_document_template smallint NOT NULL,
    name character varying NOT NULL,
    path_template character varying
);
 %   DROP TABLE public.document_template;
       public         heap    postgres    false            �            1259    17224 *   document_template_id_document_template_seq    SEQUENCE     �   CREATE SEQUENCE public.document_template_id_document_template_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 A   DROP SEQUENCE public.document_template_id_document_template_seq;
       public          postgres    false    231            �           0    0 *   document_template_id_document_template_seq    SEQUENCE OWNED BY     y   ALTER SEQUENCE public.document_template_id_document_template_seq OWNED BY public.document_template.id_document_template;
          public          postgres    false    232            �            1259    17225    document_title_seq    SEQUENCE     �   CREATE SEQUENCE public.document_title_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.document_title_seq;
       public          postgres    false    227            �           0    0    document_title_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.document_title_seq OWNED BY public.document.title;
          public          postgres    false    233            �            1259    17226    employee    TABLE       CREATE TABLE public.employee (
    id_employee integer NOT NULL,
    full_name character varying NOT NULL,
    email character varying,
    phone_number character varying,
    employment_date date NOT NULL,
    is_admin boolean,
    password character varying
);
    DROP TABLE public.employee;
       public         heap    postgres    false            �            1259    17231    employee_id_employee_seq    SEQUENCE     �   CREATE SEQUENCE public.employee_id_employee_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.employee_id_employee_seq;
       public          postgres    false    234            �           0    0    employee_id_employee_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.employee_id_employee_seq OWNED BY public.employee.id_employee;
          public          postgres    false    235            �            1259    17232    event_access    TABLE     �   CREATE TABLE public.event_access (
    id_event_access smallint NOT NULL,
    id_event smallint NOT NULL,
    id_employee smallint NOT NULL
);
     DROP TABLE public.event_access;
       public         heap    postgres    false            �            1259    17235     event_access_id_event_access_seq    SEQUENCE     �   CREATE SEQUENCE public.event_access_id_event_access_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 7   DROP SEQUENCE public.event_access_id_event_access_seq;
       public          postgres    false    236            �           0    0     event_access_id_event_access_seq    SEQUENCE OWNED BY     e   ALTER SEQUENCE public.event_access_id_event_access_seq OWNED BY public.event_access.id_event_access;
          public          postgres    false    237            �            1259    17236    event_location    TABLE     t   CREATE TABLE public.event_location (
    id_event_location integer NOT NULL,
    name character varying NOT NULL
);
 "   DROP TABLE public.event_location;
       public         heap    postgres    false            �            1259    17241 $   event_location_id_event_location_seq    SEQUENCE     �   CREATE SEQUENCE public.event_location_id_event_location_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ;   DROP SEQUENCE public.event_location_id_event_location_seq;
       public          postgres    false    238            �           0    0 $   event_location_id_event_location_seq    SEQUENCE OWNED BY     m   ALTER SEQUENCE public.event_location_id_event_location_seq OWNED BY public.event_location.id_event_location;
          public          postgres    false    239            �            1259    17242    events    TABLE     �   CREATE TABLE public.events (
    id_event integer NOT NULL,
    name character varying NOT NULL,
    discription character varying,
    date date NOT NULL,
    id_event_location smallint,
    id_employee smallint
);
    DROP TABLE public.events;
       public         heap    postgres    false            �            1259    17247    events_id_event_seq    SEQUENCE     �   CREATE SEQUENCE public.events_id_event_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.events_id_event_seq;
       public          postgres    false    240            �           0    0    events_id_event_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.events_id_event_seq OWNED BY public.events.id_event;
          public          postgres    false    241            �            1259    17248 
   group_chat    TABLE     �   CREATE TABLE public.group_chat (
    id_group_chat smallint NOT NULL,
    name character varying NOT NULL,
    creation_date date NOT NULL
);
    DROP TABLE public.group_chat;
       public         heap    postgres    false            �            1259    17253    group_chat_id_group_chat_seq    SEQUENCE     �   CREATE SEQUENCE public.group_chat_id_group_chat_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.group_chat_id_group_chat_seq;
       public          postgres    false    242            �           0    0    group_chat_id_group_chat_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.group_chat_id_group_chat_seq OWNED BY public.group_chat.id_group_chat;
          public          postgres    false    243            �            1259    17254    group_messages    TABLE       CREATE TABLE public.group_messages (
    id_group_message bigint NOT NULL,
    content character varying NOT NULL,
    id_group_chat smallint NOT NULL,
    id_sender smallint,
    send_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    id_read_status smallint DEFAULT 1
);
 "   DROP TABLE public.group_messages;
       public         heap    postgres    false            �            1259    17259 #   group_messages_id_group_message_seq    SEQUENCE     �   CREATE SEQUENCE public.group_messages_id_group_message_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 :   DROP SEQUENCE public.group_messages_id_group_message_seq;
       public          postgres    false    244            �           0    0 #   group_messages_id_group_message_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE public.group_messages_id_group_message_seq OWNED BY public.group_messages.id_group_message;
          public          postgres    false    245            �            1259    17260    ip_phone    TABLE     q   CREATE TABLE public.ip_phone (
    id_phone smallint NOT NULL,
    internal_number character varying NOT NULL
);
    DROP TABLE public.ip_phone;
       public         heap    postgres    false            �            1259    17265    ip_phone_id_phone_seq    SEQUENCE     �   CREATE SEQUENCE public.ip_phone_id_phone_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.ip_phone_id_phone_seq;
       public          postgres    false    246            �           0    0    ip_phone_id_phone_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.ip_phone_id_phone_seq OWNED BY public.ip_phone.id_phone;
          public          postgres    false    247            �            1259    17266 	   job_title    TABLE     k   CREATE TABLE public.job_title (
    id_job_title smallint NOT NULL,
    name character varying NOT NULL
);
    DROP TABLE public.job_title;
       public         heap    postgres    false            �            1259    17271    job_title_id_job_title_seq    SEQUENCE     �   CREATE SEQUENCE public.job_title_id_job_title_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.job_title_id_job_title_seq;
       public          postgres    false    248            �           0    0    job_title_id_job_title_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.job_title_id_job_title_seq OWNED BY public.job_title.id_job_title;
          public          postgres    false    249            �            1259    17272    level_skill    TABLE     g   CREATE TABLE public.level_skill (
    id_level_skill smallint NOT NULL,
    level smallint NOT NULL
);
    DROP TABLE public.level_skill;
       public         heap    postgres    false            �            1259    17275    level_skill_id_level_skill_seq    SEQUENCE     �   CREATE SEQUENCE public.level_skill_id_level_skill_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.level_skill_id_level_skill_seq;
       public          postgres    false    250            �           0    0    level_skill_id_level_skill_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.level_skill_id_level_skill_seq OWNED BY public.level_skill.id_level_skill;
          public          postgres    false    251            �            1259    17276    messages    TABLE     �   CREATE TABLE public.messages (
    id_message bigint NOT NULL,
    id_sender smallint NOT NULL,
    content character varying NOT NULL,
    send_time timestamp without time zone NOT NULL,
    id_read_status smallint,
    id_requester smallint
);
    DROP TABLE public.messages;
       public         heap    postgres    false            �            1259    17281    messages_id_message_seq    SEQUENCE     �   CREATE SEQUENCE public.messages_id_message_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.messages_id_message_seq;
       public          postgres    false    252            �           0    0    messages_id_message_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.messages_id_message_seq OWNED BY public.messages.id_message;
          public          postgres    false    253                       1259    17957    notifications    TABLE     �   CREATE TABLE public.notifications (
    id_notification integer NOT NULL,
    id_employee smallint NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    is_read boolean DEFAULT false
);
 !   DROP TABLE public.notifications;
       public         heap    postgres    false                       1259    17956 !   notifications_id_notification_seq    SEQUENCE     �   CREATE SEQUENCE public.notifications_id_notification_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE public.notifications_id_notification_seq;
       public          postgres    false    269            �           0    0 !   notifications_id_notification_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public.notifications_id_notification_seq OWNED BY public.notifications.id_notification;
          public          postgres    false    268            �            1259    17282    office    TABLE     �   CREATE TABLE public.office (
    id_office smallint NOT NULL,
    office_number character varying NOT NULL,
    id_business_center smallint
);
    DROP TABLE public.office;
       public         heap    postgres    false            �            1259    17287    office_id_office_seq    SEQUENCE     �   CREATE SEQUENCE public.office_id_office_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.office_id_office_seq;
       public          postgres    false    254            �           0    0    office_id_office_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.office_id_office_seq OWNED BY public.office.id_office;
          public          postgres    false    255                        1259    17288    participation_chats    TABLE     �   CREATE TABLE public.participation_chats (
    id_participation_chats smallint NOT NULL,
    id_employee smallint NOT NULL,
    id_role smallint,
    id_group_chat smallint NOT NULL
);
 '   DROP TABLE public.participation_chats;
       public         heap    postgres    false                       1259    17291 .   participation_chats_id_participation_chats_seq    SEQUENCE     �   CREATE SEQUENCE public.participation_chats_id_participation_chats_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 E   DROP SEQUENCE public.participation_chats_id_participation_chats_seq;
       public          postgres    false    256            �           0    0 .   participation_chats_id_participation_chats_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.participation_chats_id_participation_chats_seq OWNED BY public.participation_chats.id_participation_chats;
          public          postgres    false    257                       1259    17292    position    TABLE        CREATE TABLE public."position" (
    id_position smallint NOT NULL,
    name character varying NOT NULL,
    appointment_date date NOT NULL,
    id_employee smallint NOT NULL,
    id_job_title smallint,
    id_phone smallint,
    id_department smallint
);
    DROP TABLE public."position";
       public         heap    postgres    false                       1259    17297    position_id_position_seq    SEQUENCE     �   CREATE SEQUENCE public.position_id_position_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.position_id_position_seq;
       public          postgres    false    258            �           0    0    position_id_position_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.position_id_position_seq OWNED BY public."position".id_position;
          public          postgres    false    259                       1259    17298    read_status    TABLE     g   CREATE TABLE public.read_status (
    id_read_status smallint NOT NULL,
    status boolean NOT NULL
);
    DROP TABLE public.read_status;
       public         heap    postgres    false                       1259    17301    read_status_id_read_status_seq    SEQUENCE     �   CREATE SEQUENCE public.read_status_id_read_status_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.read_status_id_read_status_seq;
       public          postgres    false    260            �           0    0    read_status_id_read_status_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.read_status_id_read_status_seq OWNED BY public.read_status.id_read_status;
          public          postgres    false    261                       1259    17302    roles    TABLE     b   CREATE TABLE public.roles (
    id_role smallint NOT NULL,
    name character varying NOT NULL
);
    DROP TABLE public.roles;
       public         heap    postgres    false                       1259    17307    roles_id_role_seq    SEQUENCE     �   CREATE SEQUENCE public.roles_id_role_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.roles_id_role_seq;
       public          postgres    false    262            �           0    0    roles_id_role_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.roles_id_role_seq OWNED BY public.roles.id_role;
          public          postgres    false    263                       1259    17308 
   skill_name    TABLE     m   CREATE TABLE public.skill_name (
    id_skill_name smallint NOT NULL,
    name character varying NOT NULL
);
    DROP TABLE public.skill_name;
       public         heap    postgres    false            	           1259    17313    skill_name_id_skill_name_seq    SEQUENCE     �   CREATE SEQUENCE public.skill_name_id_skill_name_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.skill_name_id_skill_name_seq;
       public          postgres    false    264            �           0    0    skill_name_id_skill_name_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.skill_name_id_skill_name_seq OWNED BY public.skill_name.id_skill_name;
          public          postgres    false    265            
           1259    17314 	   skill_own    TABLE     �   CREATE TABLE public.skill_own (
    id_skill_own smallint NOT NULL,
    last_check date NOT NULL,
    id_level_skill smallint,
    id_skill_name smallint,
    id_employee smallint NOT NULL
);
    DROP TABLE public.skill_own;
       public         heap    postgres    false                       1259    17317    skill_own_id_skill_own_seq    SEQUENCE     �   CREATE SEQUENCE public.skill_own_id_skill_own_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.skill_own_id_skill_own_seq;
       public          postgres    false    266            �           0    0    skill_own_id_skill_own_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.skill_own_id_skill_own_seq OWNED BY public.skill_own.id_skill_own;
          public          postgres    false    267            �           2604    17318 *   announcement_access id_announcement_access    DEFAULT     �   ALTER TABLE ONLY public.announcement_access ALTER COLUMN id_announcement_access SET DEFAULT nextval('public.announcement_access_id_announcement_access_seq'::regclass);
 Y   ALTER TABLE public.announcement_access ALTER COLUMN id_announcement_access DROP DEFAULT;
       public          postgres    false    216    215            �           2604    17319    announcements id_announcement    DEFAULT     �   ALTER TABLE ONLY public.announcements ALTER COLUMN id_announcement SET DEFAULT nextval('public.announcements_id_announcement_seq'::regclass);
 L   ALTER TABLE public.announcements ALTER COLUMN id_announcement DROP DEFAULT;
       public          postgres    false    218    217            �           2604    17320    business_card id_business_card    DEFAULT     �   ALTER TABLE ONLY public.business_card ALTER COLUMN id_business_card SET DEFAULT nextval('public.business_card_id_business_card_seq'::regclass);
 M   ALTER TABLE public.business_card ALTER COLUMN id_business_card DROP DEFAULT;
       public          postgres    false    220    219            �           2604    17321 "   business_center id_business_center    DEFAULT     �   ALTER TABLE ONLY public.business_center ALTER COLUMN id_business_center SET DEFAULT nextval('public.business_center_id_business_center_seq'::regclass);
 Q   ALTER TABLE public.business_center ALTER COLUMN id_business_center DROP DEFAULT;
       public          postgres    false    222    221            �           2604    17322    card_type id_card_type    DEFAULT     �   ALTER TABLE ONLY public.card_type ALTER COLUMN id_card_type SET DEFAULT nextval('public.card_type_id_card_type_seq'::regclass);
 E   ALTER TABLE public.card_type ALTER COLUMN id_card_type DROP DEFAULT;
       public          postgres    false    224    223            �           2604    17323    department id_department    DEFAULT     �   ALTER TABLE ONLY public.department ALTER COLUMN id_department SET DEFAULT nextval('public.department_id_department_seq'::regclass);
 G   ALTER TABLE public.department ALTER COLUMN id_department DROP DEFAULT;
       public          postgres    false    226    225            �           2604    17324    document id_document    DEFAULT     |   ALTER TABLE ONLY public.document ALTER COLUMN id_document SET DEFAULT nextval('public.document_id_document_seq'::regclass);
 C   ALTER TABLE public.document ALTER COLUMN id_document DROP DEFAULT;
       public          postgres    false    230    227            �           2604    18312    document title    DEFAULT     p   ALTER TABLE ONLY public.document ALTER COLUMN title SET DEFAULT nextval('public.document_title_seq'::regclass);
 =   ALTER TABLE public.document ALTER COLUMN title DROP DEFAULT;
       public          postgres    false    233    227            �           2604    17326    document_access id_event_access    DEFAULT     �   ALTER TABLE ONLY public.document_access ALTER COLUMN id_event_access SET DEFAULT nextval('public.document_access_id_event_access_seq'::regclass);
 N   ALTER TABLE public.document_access ALTER COLUMN id_event_access DROP DEFAULT;
       public          postgres    false    229    228            �           2604    17327 &   document_template id_document_template    DEFAULT     �   ALTER TABLE ONLY public.document_template ALTER COLUMN id_document_template SET DEFAULT nextval('public.document_template_id_document_template_seq'::regclass);
 U   ALTER TABLE public.document_template ALTER COLUMN id_document_template DROP DEFAULT;
       public          postgres    false    232    231            �           2604    18067    employee id_employee    DEFAULT     |   ALTER TABLE ONLY public.employee ALTER COLUMN id_employee SET DEFAULT nextval('public.employee_id_employee_seq'::regclass);
 C   ALTER TABLE public.employee ALTER COLUMN id_employee DROP DEFAULT;
       public          postgres    false    235    234            �           2604    17329    event_access id_event_access    DEFAULT     �   ALTER TABLE ONLY public.event_access ALTER COLUMN id_event_access SET DEFAULT nextval('public.event_access_id_event_access_seq'::regclass);
 K   ALTER TABLE public.event_access ALTER COLUMN id_event_access DROP DEFAULT;
       public          postgres    false    237    236            �           2604    18038     event_location id_event_location    DEFAULT     �   ALTER TABLE ONLY public.event_location ALTER COLUMN id_event_location SET DEFAULT nextval('public.event_location_id_event_location_seq'::regclass);
 O   ALTER TABLE public.event_location ALTER COLUMN id_event_location DROP DEFAULT;
       public          postgres    false    239    238            �           2604    17980    events id_event    DEFAULT     r   ALTER TABLE ONLY public.events ALTER COLUMN id_event SET DEFAULT nextval('public.events_id_event_seq'::regclass);
 >   ALTER TABLE public.events ALTER COLUMN id_event DROP DEFAULT;
       public          postgres    false    241    240            �           2604    17332    group_chat id_group_chat    DEFAULT     �   ALTER TABLE ONLY public.group_chat ALTER COLUMN id_group_chat SET DEFAULT nextval('public.group_chat_id_group_chat_seq'::regclass);
 G   ALTER TABLE public.group_chat ALTER COLUMN id_group_chat DROP DEFAULT;
       public          postgres    false    243    242            �           2604    17333    group_messages id_group_message    DEFAULT     �   ALTER TABLE ONLY public.group_messages ALTER COLUMN id_group_message SET DEFAULT nextval('public.group_messages_id_group_message_seq'::regclass);
 N   ALTER TABLE public.group_messages ALTER COLUMN id_group_message DROP DEFAULT;
       public          postgres    false    245    244            �           2604    17334    ip_phone id_phone    DEFAULT     v   ALTER TABLE ONLY public.ip_phone ALTER COLUMN id_phone SET DEFAULT nextval('public.ip_phone_id_phone_seq'::regclass);
 @   ALTER TABLE public.ip_phone ALTER COLUMN id_phone DROP DEFAULT;
       public          postgres    false    247    246            �           2604    17335    job_title id_job_title    DEFAULT     �   ALTER TABLE ONLY public.job_title ALTER COLUMN id_job_title SET DEFAULT nextval('public.job_title_id_job_title_seq'::regclass);
 E   ALTER TABLE public.job_title ALTER COLUMN id_job_title DROP DEFAULT;
       public          postgres    false    249    248            �           2604    17336    level_skill id_level_skill    DEFAULT     �   ALTER TABLE ONLY public.level_skill ALTER COLUMN id_level_skill SET DEFAULT nextval('public.level_skill_id_level_skill_seq'::regclass);
 I   ALTER TABLE public.level_skill ALTER COLUMN id_level_skill DROP DEFAULT;
       public          postgres    false    251    250            �           2604    17337    messages id_message    DEFAULT     z   ALTER TABLE ONLY public.messages ALTER COLUMN id_message SET DEFAULT nextval('public.messages_id_message_seq'::regclass);
 B   ALTER TABLE public.messages ALTER COLUMN id_message DROP DEFAULT;
       public          postgres    false    253    252                       2604    17960    notifications id_notification    DEFAULT     �   ALTER TABLE ONLY public.notifications ALTER COLUMN id_notification SET DEFAULT nextval('public.notifications_id_notification_seq'::regclass);
 L   ALTER TABLE public.notifications ALTER COLUMN id_notification DROP DEFAULT;
       public          postgres    false    269    268    269                        2604    17338    office id_office    DEFAULT     t   ALTER TABLE ONLY public.office ALTER COLUMN id_office SET DEFAULT nextval('public.office_id_office_seq'::regclass);
 ?   ALTER TABLE public.office ALTER COLUMN id_office DROP DEFAULT;
       public          postgres    false    255    254                       2604    17339 *   participation_chats id_participation_chats    DEFAULT     �   ALTER TABLE ONLY public.participation_chats ALTER COLUMN id_participation_chats SET DEFAULT nextval('public.participation_chats_id_participation_chats_seq'::regclass);
 Y   ALTER TABLE public.participation_chats ALTER COLUMN id_participation_chats DROP DEFAULT;
       public          postgres    false    257    256                       2604    17340    position id_position    DEFAULT     ~   ALTER TABLE ONLY public."position" ALTER COLUMN id_position SET DEFAULT nextval('public.position_id_position_seq'::regclass);
 E   ALTER TABLE public."position" ALTER COLUMN id_position DROP DEFAULT;
       public          postgres    false    259    258                       2604    17341    read_status id_read_status    DEFAULT     �   ALTER TABLE ONLY public.read_status ALTER COLUMN id_read_status SET DEFAULT nextval('public.read_status_id_read_status_seq'::regclass);
 I   ALTER TABLE public.read_status ALTER COLUMN id_read_status DROP DEFAULT;
       public          postgres    false    261    260                       2604    17342    roles id_role    DEFAULT     n   ALTER TABLE ONLY public.roles ALTER COLUMN id_role SET DEFAULT nextval('public.roles_id_role_seq'::regclass);
 <   ALTER TABLE public.roles ALTER COLUMN id_role DROP DEFAULT;
       public          postgres    false    263    262                       2604    17343    skill_name id_skill_name    DEFAULT     �   ALTER TABLE ONLY public.skill_name ALTER COLUMN id_skill_name SET DEFAULT nextval('public.skill_name_id_skill_name_seq'::regclass);
 G   ALTER TABLE public.skill_name ALTER COLUMN id_skill_name DROP DEFAULT;
       public          postgres    false    265    264                       2604    17344    skill_own id_skill_own    DEFAULT     �   ALTER TABLE ONLY public.skill_own ALTER COLUMN id_skill_own SET DEFAULT nextval('public.skill_own_id_skill_own_seq'::regclass);
 E   ALTER TABLE public.skill_own ALTER COLUMN id_skill_own DROP DEFAULT;
       public          postgres    false    267    266            <          0    17175    announcement_access 
   TABLE DATA           c   COPY public.announcement_access (id_announcement_access, id_employee, id_announcement) FROM stdin;
    public          postgres    false    215   M      >          0    17179    announcements 
   TABLE DATA           r   COPY public.announcements (id_announcement, title, discription, creation_date, end_date, id_employee) FROM stdin;
    public          postgres    false    217   �      @          0    17185    business_card 
   TABLE DATA           l   COPY public.business_card (id_business_card, content, creation_date, id_card_type, id_employee) FROM stdin;
    public          postgres    false    219   e
      B          0    17191    business_center 
   TABLE DATA           F   COPY public.business_center (id_business_center, address) FROM stdin;
    public          postgres    false    221   �      D          0    17197 	   card_type 
   TABLE DATA           7   COPY public.card_type (id_card_type, type) FROM stdin;
    public          postgres    false    223         F          0    17203 
   department 
   TABLE DATA           v   COPY public.department (id_department, name, open_hours, close_hours, department_phone_number, id_office) FROM stdin;
    public          postgres    false    225   c      H          0    17209    document 
   TABLE DATA           �   COPY public.document (id_document, title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template) FROM stdin;
    public          postgres    false    227   j      I          0    17214    document_access 
   TABLE DATA           T   COPY public.document_access (id_event_access, id_document, id_employee) FROM stdin;
    public          postgres    false    228   W      L          0    17219    document_template 
   TABLE DATA           V   COPY public.document_template (id_document_template, name, path_template) FROM stdin;
    public          postgres    false    231   �      O          0    17226    employee 
   TABLE DATA           t   COPY public.employee (id_employee, full_name, email, phone_number, employment_date, is_admin, password) FROM stdin;
    public          postgres    false    234   �      Q          0    17232    event_access 
   TABLE DATA           N   COPY public.event_access (id_event_access, id_event, id_employee) FROM stdin;
    public          postgres    false    236   �      S          0    17236    event_location 
   TABLE DATA           A   COPY public.event_location (id_event_location, name) FROM stdin;
    public          postgres    false    238   d      U          0    17242    events 
   TABLE DATA           c   COPY public.events (id_event, name, discription, date, id_event_location, id_employee) FROM stdin;
    public          postgres    false    240   t      W          0    17248 
   group_chat 
   TABLE DATA           H   COPY public.group_chat (id_group_chat, name, creation_date) FROM stdin;
    public          postgres    false    242   �      Y          0    17254    group_messages 
   TABLE DATA           x   COPY public.group_messages (id_group_message, content, id_group_chat, id_sender, send_time, id_read_status) FROM stdin;
    public          postgres    false    244   �      [          0    17260    ip_phone 
   TABLE DATA           =   COPY public.ip_phone (id_phone, internal_number) FROM stdin;
    public          postgres    false    246   Y      ]          0    17266 	   job_title 
   TABLE DATA           7   COPY public.job_title (id_job_title, name) FROM stdin;
    public          postgres    false    248   �      _          0    17272    level_skill 
   TABLE DATA           <   COPY public.level_skill (id_level_skill, level) FROM stdin;
    public          postgres    false    250   v      a          0    17276    messages 
   TABLE DATA           k   COPY public.messages (id_message, id_sender, content, send_time, id_read_status, id_requester) FROM stdin;
    public          postgres    false    252   �      r          0    17957    notifications 
   TABLE DATA           c   COPY public.notifications (id_notification, id_employee, content, created_at, is_read) FROM stdin;
    public          postgres    false    269   �      c          0    17282    office 
   TABLE DATA           N   COPY public.office (id_office, office_number, id_business_center) FROM stdin;
    public          postgres    false    254   /7      e          0    17288    participation_chats 
   TABLE DATA           j   COPY public.participation_chats (id_participation_chats, id_employee, id_role, id_group_chat) FROM stdin;
    public          postgres    false    256   o7      g          0    17292    position 
   TABLE DATA           }   COPY public."position" (id_position, name, appointment_date, id_employee, id_job_title, id_phone, id_department) FROM stdin;
    public          postgres    false    258   �7      i          0    17298    read_status 
   TABLE DATA           =   COPY public.read_status (id_read_status, status) FROM stdin;
    public          postgres    false    260   "9      k          0    17302    roles 
   TABLE DATA           .   COPY public.roles (id_role, name) FROM stdin;
    public          postgres    false    262   G9      m          0    17308 
   skill_name 
   TABLE DATA           9   COPY public.skill_name (id_skill_name, name) FROM stdin;
    public          postgres    false    264   �9      o          0    17314 	   skill_own 
   TABLE DATA           i   COPY public.skill_own (id_skill_own, last_check, id_level_skill, id_skill_name, id_employee) FROM stdin;
    public          postgres    false    266   :      �           0    0 .   announcement_access_id_announcement_access_seq    SEQUENCE SET     ]   SELECT pg_catalog.setval('public.announcement_access_id_announcement_access_seq', 18, true);
          public          postgres    false    216            �           0    0 !   announcements_id_announcement_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public.announcements_id_announcement_seq', 12, true);
          public          postgres    false    218            �           0    0 "   business_card_id_business_card_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('public.business_card_id_business_card_seq', 13, true);
          public          postgres    false    220            �           0    0 &   business_center_id_business_center_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public.business_center_id_business_center_seq', 2, true);
          public          postgres    false    222            �           0    0    card_type_id_card_type_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.card_type_id_card_type_seq', 2, true);
          public          postgres    false    224            �           0    0    department_id_department_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.department_id_department_seq', 9, true);
          public          postgres    false    226            �           0    0 #   document_access_id_event_access_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.document_access_id_event_access_seq', 27, true);
          public          postgres    false    229            �           0    0    document_id_document_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.document_id_document_seq', 12, true);
          public          postgres    false    230            �           0    0 *   document_template_id_document_template_seq    SEQUENCE SET     X   SELECT pg_catalog.setval('public.document_template_id_document_template_seq', 3, true);
          public          postgres    false    232            �           0    0    document_title_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.document_title_seq', 1, false);
          public          postgres    false    233            �           0    0    employee_id_employee_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.employee_id_employee_seq', 17, true);
          public          postgres    false    235            �           0    0     event_access_id_event_access_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public.event_access_id_event_access_seq', 122, true);
          public          postgres    false    237            �           0    0 $   event_location_id_event_location_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.event_location_id_event_location_seq', 9, true);
          public          postgres    false    239            �           0    0    events_id_event_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.events_id_event_seq', 13, true);
          public          postgres    false    241            �           0    0    group_chat_id_group_chat_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.group_chat_id_group_chat_seq', 9, true);
          public          postgres    false    243            �           0    0 #   group_messages_id_group_message_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.group_messages_id_group_message_seq', 11, true);
          public          postgres    false    245            �           0    0    ip_phone_id_phone_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.ip_phone_id_phone_seq', 9, true);
          public          postgres    false    247            �           0    0    job_title_id_job_title_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.job_title_id_job_title_seq', 9, true);
          public          postgres    false    249            �           0    0    level_skill_id_level_skill_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.level_skill_id_level_skill_seq', 5, true);
          public          postgres    false    251            �           0    0    messages_id_message_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.messages_id_message_seq', 21, true);
          public          postgres    false    253            �           0    0 !   notifications_id_notification_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('public.notifications_id_notification_seq', 945, true);
          public          postgres    false    268            �           0    0    office_id_office_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.office_id_office_seq', 9, true);
          public          postgres    false    255            �           0    0 .   participation_chats_id_participation_chats_seq    SEQUENCE SET     ]   SELECT pg_catalog.setval('public.participation_chats_id_participation_chats_seq', 29, true);
          public          postgres    false    257            �           0    0    position_id_position_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.position_id_position_seq', 18, true);
          public          postgres    false    259            �           0    0    read_status_id_read_status_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.read_status_id_read_status_seq', 2, true);
          public          postgres    false    261            �           0    0    roles_id_role_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.roles_id_role_seq', 3, true);
          public          postgres    false    263            �           0    0    skill_name_id_skill_name_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.skill_name_id_skill_name_seq', 9, true);
          public          postgres    false    265            �           0    0    skill_own_id_skill_own_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.skill_own_id_skill_own_seq', 9, true);
          public          postgres    false    267                       2606    17346 *   announcement_access PK_announcement_access 
   CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT "PK_announcement_access" PRIMARY KEY (id_announcement_access, id_employee, id_announcement);
 V   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT "PK_announcement_access";
       public            postgres    false    215    215    215                       2606    17348    announcements PK_announcements 
   CONSTRAINT     k   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT "PK_announcements" PRIMARY KEY (id_announcement);
 J   ALTER TABLE ONLY public.announcements DROP CONSTRAINT "PK_announcements";
       public            postgres    false    217                       2606    17350    business_card PK_business_card 
   CONSTRAINT     l   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT "PK_business_card" PRIMARY KEY (id_business_card);
 J   ALTER TABLE ONLY public.business_card DROP CONSTRAINT "PK_business_card";
       public            postgres    false    219                       2606    17352 "   business_center PK_business_center 
   CONSTRAINT     r   ALTER TABLE ONLY public.business_center
    ADD CONSTRAINT "PK_business_center" PRIMARY KEY (id_business_center);
 N   ALTER TABLE ONLY public.business_center DROP CONSTRAINT "PK_business_center";
       public            postgres    false    221                       2606    17354    card_type PK_card_type 
   CONSTRAINT     `   ALTER TABLE ONLY public.card_type
    ADD CONSTRAINT "PK_card_type" PRIMARY KEY (id_card_type);
 B   ALTER TABLE ONLY public.card_type DROP CONSTRAINT "PK_card_type";
       public            postgres    false    223                       2606    17356    department PK_department 
   CONSTRAINT     c   ALTER TABLE ONLY public.department
    ADD CONSTRAINT "PK_department" PRIMARY KEY (id_department);
 D   ALTER TABLE ONLY public.department DROP CONSTRAINT "PK_department";
       public            postgres    false    225                       2606    17358    document PK_document 
   CONSTRAINT     ]   ALTER TABLE ONLY public.document
    ADD CONSTRAINT "PK_document" PRIMARY KEY (id_document);
 @   ALTER TABLE ONLY public.document DROP CONSTRAINT "PK_document";
       public            postgres    false    227                       2606    17360 "   document_access PK_document_access 
   CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT "PK_document_access" PRIMARY KEY (id_event_access, id_document, id_employee);
 N   ALTER TABLE ONLY public.document_access DROP CONSTRAINT "PK_document_access";
       public            postgres    false    228    228    228                       2606    17362 &   document_template PK_document_template 
   CONSTRAINT     x   ALTER TABLE ONLY public.document_template
    ADD CONSTRAINT "PK_document_template" PRIMARY KEY (id_document_template);
 R   ALTER TABLE ONLY public.document_template DROP CONSTRAINT "PK_document_template";
       public            postgres    false    231                       2606    18069    employee PK_employee 
   CONSTRAINT     ]   ALTER TABLE ONLY public.employee
    ADD CONSTRAINT "PK_employee" PRIMARY KEY (id_employee);
 @   ALTER TABLE ONLY public.employee DROP CONSTRAINT "PK_employee";
       public            postgres    false    234                       2606    17366    event_access PK_event_access 
   CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT "PK_event_access" PRIMARY KEY (id_event_access, id_event, id_employee);
 H   ALTER TABLE ONLY public.event_access DROP CONSTRAINT "PK_event_access";
       public            postgres    false    236    236    236            !           2606    18040     event_location PK_event_location 
   CONSTRAINT     o   ALTER TABLE ONLY public.event_location
    ADD CONSTRAINT "PK_event_location" PRIMARY KEY (id_event_location);
 L   ALTER TABLE ONLY public.event_location DROP CONSTRAINT "PK_event_location";
       public            postgres    false    238            #           2606    17982    events PK_events 
   CONSTRAINT     V   ALTER TABLE ONLY public.events
    ADD CONSTRAINT "PK_events" PRIMARY KEY (id_event);
 <   ALTER TABLE ONLY public.events DROP CONSTRAINT "PK_events";
       public            postgres    false    240            %           2606    17372    group_chat PK_group_chat 
   CONSTRAINT     c   ALTER TABLE ONLY public.group_chat
    ADD CONSTRAINT "PK_group_chat" PRIMARY KEY (id_group_chat);
 D   ALTER TABLE ONLY public.group_chat DROP CONSTRAINT "PK_group_chat";
       public            postgres    false    242            '           2606    17374     group_messages PK_group_messages 
   CONSTRAINT     }   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT "PK_group_messages" PRIMARY KEY (id_group_message, id_group_chat);
 L   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT "PK_group_messages";
       public            postgres    false    244    244            )           2606    17376    ip_phone PK_ip_phone 
   CONSTRAINT     Z   ALTER TABLE ONLY public.ip_phone
    ADD CONSTRAINT "PK_ip_phone" PRIMARY KEY (id_phone);
 @   ALTER TABLE ONLY public.ip_phone DROP CONSTRAINT "PK_ip_phone";
       public            postgres    false    246            +           2606    17378    job_title PK_job_title 
   CONSTRAINT     `   ALTER TABLE ONLY public.job_title
    ADD CONSTRAINT "PK_job_title" PRIMARY KEY (id_job_title);
 B   ALTER TABLE ONLY public.job_title DROP CONSTRAINT "PK_job_title";
       public            postgres    false    248            -           2606    17380    level_skill PK_level_skill 
   CONSTRAINT     f   ALTER TABLE ONLY public.level_skill
    ADD CONSTRAINT "PK_level_skill" PRIMARY KEY (id_level_skill);
 F   ALTER TABLE ONLY public.level_skill DROP CONSTRAINT "PK_level_skill";
       public            postgres    false    250            /           2606    17382    messages PK_messages 
   CONSTRAINT     g   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT "PK_messages" PRIMARY KEY (id_message, id_sender);
 @   ALTER TABLE ONLY public.messages DROP CONSTRAINT "PK_messages";
       public            postgres    false    252    252            1           2606    17384    office PK_office 
   CONSTRAINT     W   ALTER TABLE ONLY public.office
    ADD CONSTRAINT "PK_office" PRIMARY KEY (id_office);
 <   ALTER TABLE ONLY public.office DROP CONSTRAINT "PK_office";
       public            postgres    false    254            3           2606    17386 *   participation_chats PK_participation_chats 
   CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT "PK_participation_chats" PRIMARY KEY (id_participation_chats, id_employee, id_group_chat);
 V   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT "PK_participation_chats";
       public            postgres    false    256    256    256            5           2606    17388    position PK_position 
   CONSTRAINT     _   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT "PK_position" PRIMARY KEY (id_position);
 B   ALTER TABLE ONLY public."position" DROP CONSTRAINT "PK_position";
       public            postgres    false    258            7           2606    17390    read_status PK_read_status 
   CONSTRAINT     f   ALTER TABLE ONLY public.read_status
    ADD CONSTRAINT "PK_read_status" PRIMARY KEY (id_read_status);
 F   ALTER TABLE ONLY public.read_status DROP CONSTRAINT "PK_read_status";
       public            postgres    false    260            9           2606    17392    roles PK_roles 
   CONSTRAINT     S   ALTER TABLE ONLY public.roles
    ADD CONSTRAINT "PK_roles" PRIMARY KEY (id_role);
 :   ALTER TABLE ONLY public.roles DROP CONSTRAINT "PK_roles";
       public            postgres    false    262            ;           2606    17394    skill_name PK_skill_name 
   CONSTRAINT     c   ALTER TABLE ONLY public.skill_name
    ADD CONSTRAINT "PK_skill_name" PRIMARY KEY (id_skill_name);
 D   ALTER TABLE ONLY public.skill_name DROP CONSTRAINT "PK_skill_name";
       public            postgres    false    264            =           2606    17396    skill_own PK_skill_own 
   CONSTRAINT     m   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT "PK_skill_own" PRIMARY KEY (id_skill_own, id_employee);
 B   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT "PK_skill_own";
       public            postgres    false    266    266            ?           2606    17965     notifications notifications_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id_notification);
 J   ALTER TABLE ONLY public.notifications DROP CONSTRAINT notifications_pkey;
       public            postgres    false    269            �           2620    17979    events trg_notify_on_new_event    TRIGGER     �   CREATE TRIGGER trg_notify_on_new_event AFTER INSERT ON public.events FOR EACH ROW EXECUTE FUNCTION public.trigger_insert_notification_on_event();
 7   DROP TRIGGER trg_notify_on_new_event ON public.events;
       public          postgres    false    300    240            �           2620    17397 #   messages trigger_notify_new_message    TRIGGER     �   CREATE TRIGGER trigger_notify_new_message AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.notify_new_message();
 <   DROP TRIGGER trigger_notify_new_message ON public.messages;
       public          postgres    false    252    271            �           2606    18300 '   notifications FK_notifications_employee    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT "FK_notifications_employee" FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 S   ALTER TABLE ONLY public.notifications DROP CONSTRAINT "FK_notifications_employee";
       public          postgres    false    4893    269    234            @           2606    17398 <   announcement_access announcement_access_id_announcement_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 f   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey;
       public          postgres    false    217    4877    215            A           2606    17403 =   announcement_access announcement_access_id_announcement_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey1 FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 g   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey1;
       public          postgres    false    215    4877    217            B           2606    17408 =   announcement_access announcement_access_id_announcement_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey2 FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 g   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey2;
       public          postgres    false    215    4877    217            C           2606    17413 =   announcement_access announcement_access_id_announcement_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey3 FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 g   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey3;
       public          postgres    false    215    4877    217            D           2606    18070 8   announcement_access announcement_access_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 b   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey;
       public          postgres    false    215    4893    234            E           2606    18075 9   announcement_access announcement_access_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey1;
       public          postgres    false    215    4893    234            F           2606    18080 9   announcement_access announcement_access_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey2;
       public          postgres    false    234    4893    215            G           2606    18085 9   announcement_access announcement_access_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey3;
       public          postgres    false    234    215    4893            H           2606    18090 ,   announcements announcements_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey;
       public          postgres    false    234    4893    217            I           2606    18095 -   announcements announcements_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey1;
       public          postgres    false    217    234    4893            J           2606    18100 -   announcements announcements_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey2;
       public          postgres    false    4893    234    217            K           2606    18105 -   announcements announcements_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey3;
       public          postgres    false    217    234    4893            L           2606    17458 -   business_card business_card_id_card_type_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey;
       public          postgres    false    219    223    4883            M           2606    17463 .   business_card business_card_id_card_type_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey1 FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 X   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey1;
       public          postgres    false    219    223    4883            N           2606    17468 .   business_card business_card_id_card_type_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey2 FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 X   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey2;
       public          postgres    false    4883    223    219            O           2606    17473 .   business_card business_card_id_card_type_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey3 FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 X   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey3;
       public          postgres    false    4883    219    223            P           2606    18110 ,   business_card business_card_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey;
       public          postgres    false    234    4893    219            Q           2606    18115 -   business_card business_card_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey1;
       public          postgres    false    219    234    4893            R           2606    18120 -   business_card business_card_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey2;
       public          postgres    false    234    4893    219            S           2606    18125 -   business_card business_card_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey3;
       public          postgres    false    219    234    4893            T           2606    17498 $   department department_id_office_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey;
       public          postgres    false    254    225    4913            U           2606    17503 %   department department_id_office_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey1 FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey1;
       public          postgres    false    225    254    4913            V           2606    17508 %   department department_id_office_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey2 FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey2;
       public          postgres    false    4913    225    254            W           2606    17513 %   department department_id_office_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey3 FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey3;
       public          postgres    false    254    225    4913            `           2606    17518 0   document_access document_access_id_document_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey;
       public          postgres    false    228    227    4887            a           2606    17523 1   document_access document_access_id_document_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey1 FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey1;
       public          postgres    false    228    227    4887            b           2606    17528 1   document_access document_access_id_document_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey2 FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey2;
       public          postgres    false    4887    228    227            c           2606    17533 1   document_access document_access_id_document_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey3 FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey3;
       public          postgres    false    228    227    4887            d           2606    18130 0   document_access document_access_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey;
       public          postgres    false    234    228    4893            e           2606    18135 1   document_access document_access_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey1;
       public          postgres    false    228    234    4893            f           2606    18140 1   document_access document_access_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey2;
       public          postgres    false    228    234    4893            g           2606    18145 1   document_access document_access_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey3;
       public          postgres    false    234    228    4893            X           2606    17558 +   document document_id_document_template_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 U   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey;
       public          postgres    false    231    227    4891            Y           2606    17564 ,   document document_id_document_template_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey1 FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey1;
       public          postgres    false    227    231    4891            Z           2606    17569 ,   document document_id_document_template_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey2 FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey2;
       public          postgres    false    231    4891    227            [           2606    17574 ,   document document_id_document_template_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey3 FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey3;
       public          postgres    false    4891    231    227            \           2606    18150 "   document document_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 L   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey;
       public          postgres    false    227    234    4893            ]           2606    18155 #   document document_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey1;
       public          postgres    false    4893    227    234            ^           2606    18160 #   document document_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey2;
       public          postgres    false    227    234    4893            _           2606    18165 #   document document_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey3;
       public          postgres    false    227    234    4893            h           2606    18170 *   event_access event_access_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 T   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey;
       public          postgres    false    234    236    4893            i           2606    18175 +   event_access event_access_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey1;
       public          postgres    false    4893    236    234            j           2606    18180 +   event_access event_access_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey2;
       public          postgres    false    4893    236    234            k           2606    18185 +   event_access event_access_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey3;
       public          postgres    false    236    234    4893            l           2606    17983 '   event_access event_access_id_event_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 Q   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey;
       public          postgres    false    236    4899    240            m           2606    17988 (   event_access event_access_id_event_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey1 FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey1;
       public          postgres    false    236    4899    240            n           2606    17993 (   event_access event_access_id_event_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey2 FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey2;
       public          postgres    false    236    4899    240            o           2606    17998 (   event_access event_access_id_event_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey3 FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey3;
       public          postgres    false    236    4899    240            p           2606    18190    events events_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 H   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey;
       public          postgres    false    240    234    4893            q           2606    18195    events events_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 I   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey1;
       public          postgres    false    240    4893    234            r           2606    18200    events events_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 I   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey2;
       public          postgres    false    240    4893    234            s           2606    18205    events events_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 I   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey3;
       public          postgres    false    234    4893    240            t           2606    18041 $   events events_id_event_location_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey;
       public          postgres    false    240    4897    238            u           2606    18046 %   events events_id_event_location_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey1 FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey1;
       public          postgres    false    240    4897    238            v           2606    18051 %   events events_id_event_location_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey2 FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey2;
       public          postgres    false    240    4897    238            w           2606    18056 %   events events_id_event_location_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey3 FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey3;
       public          postgres    false    240    4897    238            x           2606    17679 0   group_messages group_messages_id_group_chat_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey;
       public          postgres    false    242    244    4901            y           2606    17684 1   group_messages group_messages_id_group_chat_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey1 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey1;
       public          postgres    false    4901    244    242            z           2606    17689 1   group_messages group_messages_id_group_chat_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey2 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey2;
       public          postgres    false    244    4901    242            {           2606    17694 1   group_messages group_messages_id_group_chat_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey3 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey3;
       public          postgres    false    244    242    4901            |           2606    17950 1   group_messages group_messages_id_read_status_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_read_status_fkey FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status);
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_read_status_fkey;
       public          postgres    false    244    4919    260            }           2606    18295 ,   group_messages group_messages_id_sender_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_sender_fkey FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON DELETE CASCADE;
 V   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_sender_fkey;
       public          postgres    false    244    234    4893            ~           2606    17699 %   messages messages_id_read_status_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey;
       public          postgres    false    4919    260    252                       2606    17704 &   messages messages_id_read_status_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey1 FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey1;
       public          postgres    false    260    252    4919            �           2606    17709 &   messages messages_id_read_status_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey2 FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey2;
       public          postgres    false    252    4919    260            �           2606    17714 &   messages messages_id_read_status_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey3 FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey3;
       public          postgres    false    252    4919    260            �           2606    18210 #   messages messages_id_requester_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey;
       public          postgres    false    252    4893    234            �           2606    18215 $   messages messages_id_requester_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey1 FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey1;
       public          postgres    false    234    252    4893            �           2606    18220 $   messages messages_id_requester_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey2 FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey2;
       public          postgres    false    252    234    4893            �           2606    18225 $   messages messages_id_requester_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey3 FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey3;
       public          postgres    false    234    4893    252            �           2606    18230     messages messages_id_sender_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 J   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey;
       public          postgres    false    252    234    4893            �           2606    18235 !   messages messages_id_sender_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey1 FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey1;
       public          postgres    false    252    4893    234            �           2606    18240 !   messages messages_id_sender_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey2 FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey2;
       public          postgres    false    252    4893    234            �           2606    18245 !   messages messages_id_sender_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey3 FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey3;
       public          postgres    false    252    4893    234            �           2606    17759 %   office office_id_business_center_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey;
       public          postgres    false    221    254    4881            �           2606    17764 &   office office_id_business_center_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey1 FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey1;
       public          postgres    false    254    4881    221            �           2606    17769 &   office office_id_business_center_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey2 FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey2;
       public          postgres    false    221    4881    254            �           2606    17774 &   office office_id_business_center_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey3 FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey3;
       public          postgres    false    254    4881    221            �           2606    18250 8   participation_chats participation_chats_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 b   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey;
       public          postgres    false    256    234    4893            �           2606    18255 9   participation_chats participation_chats_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey1;
       public          postgres    false    4893    234    256            �           2606    18260 9   participation_chats participation_chats_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey2;
       public          postgres    false    256    4893    234            �           2606    18265 9   participation_chats participation_chats_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey3;
       public          postgres    false    256    4893    234            �           2606    17799 :   participation_chats participation_chats_id_group_chat_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 d   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey;
       public          postgres    false    242    256    4901            �           2606    17804 ;   participation_chats participation_chats_id_group_chat_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey1 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 e   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey1;
       public          postgres    false    256    4901    242            �           2606    17809 ;   participation_chats participation_chats_id_group_chat_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey2 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 e   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey2;
       public          postgres    false    256    4901    242            �           2606    17814 ;   participation_chats participation_chats_id_group_chat_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey3 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 e   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey3;
       public          postgres    false    256    4901    242            �           2606    17819 4   participation_chats participation_chats_id_role_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 ^   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey;
       public          postgres    false    256    4921    262            �           2606    17824 5   participation_chats participation_chats_id_role_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey1 FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 _   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey1;
       public          postgres    false    256    4921    262            �           2606    17829 5   participation_chats participation_chats_id_role_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey2 FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 _   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey2;
       public          postgres    false    256    4921    262            �           2606    17834 5   participation_chats participation_chats_id_role_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey3 FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 _   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey3;
       public          postgres    false    256    4921    262            �           2606    17839 $   position position_id_department_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_department_fkey FOREIGN KEY (id_department) REFERENCES public.department(id_department) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_department_fkey;
       public          postgres    false    258    4885    225            �           2606    18270 "   position position_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_employee_fkey;
       public          postgres    false    4893    234    258            �           2606    17849 #   position position_id_job_title_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_job_title_fkey FOREIGN KEY (id_job_title) REFERENCES public.job_title(id_job_title) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_job_title_fkey;
       public          postgres    false    258    4907    248            �           2606    17854    position position_id_phone_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_phone_fkey FOREIGN KEY (id_phone) REFERENCES public.ip_phone(id_phone) ON UPDATE CASCADE ON DELETE RESTRICT;
 K   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_phone_fkey;
       public          postgres    false    258    4905    246            �           2606    18275 $   skill_own skill_own_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey;
       public          postgres    false    4893    266    234            �           2606    18280 %   skill_own skill_own_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey1;
       public          postgres    false    234    266    4893            �           2606    18285 %   skill_own skill_own_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey2;
       public          postgres    false    4893    234    266            �           2606    18290 %   skill_own skill_own_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey3;
       public          postgres    false    234    266    4893            �           2606    17879 '   skill_own skill_own_id_level_skill_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey;
       public          postgres    false    266    4909    250            �           2606    17884 (   skill_own skill_own_id_level_skill_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey1 FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 R   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey1;
       public          postgres    false    266    4909    250            �           2606    17889 (   skill_own skill_own_id_level_skill_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey2 FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 R   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey2;
       public          postgres    false    266    4909    250            �           2606    17894 (   skill_own skill_own_id_level_skill_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey3 FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 R   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey3;
       public          postgres    false    266    4909    250            �           2606    17899 &   skill_own skill_own_id_skill_name_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey;
       public          postgres    false    266    4923    264            �           2606    17904 '   skill_own skill_own_id_skill_name_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey1 FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey1;
       public          postgres    false    266    4923    264            �           2606    17909 '   skill_own skill_own_id_skill_name_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey2 FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey2;
       public          postgres    false    266    4923    264            �           2606    17914 '   skill_own skill_own_id_skill_name_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey3 FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey3;
       public          postgres    false    266    4923    264            <   L   x�˱�0�������%���s ��JQ����4\*l5nmM|�`n�儏F*�/i�v679������Gd      >   �  x��T�nA<�|��l�Î�#�@��ANH)���r_��x(_`;Yv��^�B�Qݳ�r����LOMuuM���SaG��qa'�Њ�vJw�6�D1��˩�_XH�2D~�VD���Sd?|
;�#{Z��V��.V1����[ �0< b�Q��m?h�^=}u�������5�&nx����c� Qy3j�
N0W�\v9��ئ�F�Y�0�|�v�m�=��=Es�匀�ؙᤡ��Ș��.�R6RJ]�/N�������1�TDX�;>�wi�|������}�*�3����#E��\B�.IE@9���������^Tވ�wcO�r�o��D|�-�#W�dK�^-+��c�񐵴U*��X]�4fzsA�+C�͛��b�F3��q��;CO$��FN�i��o^�
���r~�#�V�iRb<
�h	mΑ�%ʜp�l˥�paG΅N7q�!0;������詡�Fr�-,&w��Rl#f�'=+W�;m� ��6L����Y��D�l�r[�S����D!�[�>��*���~����}E��c��2��IK�3j�츖��c\��F�Q8��{��E�~[aS�ЃG�@={|�^��#�@�Q^�5���+mX�%&1b��-��øU�Umd'�ɫƇl��7D�\Ɉ���^�i�C���_g��      @   3  x����N�0���S����#!n�\�4 ��pD�����[�
��9C���H����َ�<�R��f���{J��	�M��vrps5��/l7�Ja�:����){�ئ�`G@���/#��r
&��`�o-��2�{����<e�n
u
G-+�4�.M�?pT|��'Is$�(�HV(����DZ���n��d�w�a�Sǆf�N�
-lM�MAe�x��u�i�%b
�TA!�=b�s�0�rxb1�e< t��1�:��lH���E�,L���Y��?
3�EV�t���z_��      B   P   x�3�0�¾��v]�ta�������.̾����;�(va���!�v��.l��pa��
@isP	L�W� ��7�      D   K   x�3估��֋��^�q��j�����
6]�qa;P�	$�e�ya��=�5m����6����=... �3�      F   �   x����N�0�继�B��Ď��lH�]ّ��i����P�m���+�y#�C3��l�w���wgE��h���h��zI��)w�<�E������̭*ʉ6�ʒ���_4٣���;4iLM��j��B�N�G��3)��0P��x�=��ri'G%둓xD�kQ6'�f��)"ZA|��W���iGBZTP�v��mp��ü/�4[���r�����j���a�"��*�.���69�O�����      H   �  x���Kr�@��3���hF~����J���`ʖ�4��.�`AU������8_��F�=V��B�V�����-��otK��*��j�����jwB�~P݈�Q��G�(��<�E���|4:�QG��P��}Ih�H�W��-�tK��(�>��'hq�B���y��(Mϒl�L�H7�UG�M����EBɞ�	�L7,�NXҽ��;�B�[{�
۰ږ��B��$+m2��/��i�A��\OD�/��.�)��̮�2Xb|wȰ��Ij�|<6E��>0C��� &b��W�z��F�����)֔6.�</l�xZfWT
�|m TC1�+�C�%�m&�?Z���_���5�w�+��A��bR���l�����0
dC SBa��e�X�/���tɓ��5_9&ڶ�v~�'Vn�2/��&��5��{2�p{~��.2H0�oЮ�TI���Yi�zZ��Zk����?lċ���/��v�      I   V   x����P�b��k�}{q�uN b���`�a{�4<���[���/�ΣA��rӚ�h:�6K�8� ��]T������"      L   �   x�]OK�P[�N�N�Q�cB`\�ĥh�,L���'BD�B�F��QXL�����^g\P�J��lQ��=Q��w���!<��⑑
�n��ĉ�9�;���kG�R�[	ە�ȡ֢�I㥉rY����6=B���G�HZ�+f�#��L&Ma4ޤ�)^�L�%��_z1�gv��g��`h)�>X*�$      O     x�}��n�@��'O�{��w}���P���X���Q�F��&Hp��A !NUy�6jH8���1��P�J���k��Ϸ�L$�<�y���s(&����'�`����� n%^�e���%A���2��
Z
�+��K����S���9a7l`��q9�w*�X�e&�DHZ� ��\N�p�?<����]#V�b��1V��R�������3���"ַ�`J7?����*��z7q���ES
�>|g!g֜�?�gxEU�湥�=���E+rܙ6QĀ���Ҟ�ђ�r�Ve���	7�cV��B*�:��!��F=��9*G��$a%lG�"��٥��)E:�yE��˔�\�7�WT��'�4MY��(d�<3>�l�֌?��;��}}O?�;A�2�d*ԦE4]���%����مyâW��̇w�1�S�빗�.��9�^�|��?n���	]=���U}�?�������ۤA�.��я�t���}[�Ύ�-���7���qAYw��k�kN�C�s���zk�ā�[��_ݝ�      Q   �   x�%��0k4L����d�9r8�D���pl%z�ѫ]Z�ԎKݺ�[��l,eV���$�M!���7F�`W���g�R	��8ē~�9���qk�T�l����~�H`����Z������^0L~_@� \�ߘ��4��6W��|��~$� �*�      S      x�}�=N�@��S��)!���S!��r�$�Q"*$
@��Q,op���F�]�h�g��o�o���h|���:�QS���tz'�Ѳ^�^�U$���X*g��ɹ�;��ݡ�=<Q��#��~v؆S�=��R�u�̕>�S�E��5��\�����RXPF��g���� Kv�� Y�gO�+��N�#��b�C�.�f�\�?%�˵����e���9�>8�N�22�8�c����Ӱ�x{]�홈|�z��      U     x�}SKnA]W��9@��:�}vYpV�Y!J kg,���,�D�O0v�x����o��j��E��]��zݕ㖧XwX3^ٱk�k����k�/�b��om+��G�q����V��9�>�$Jғ89I#J��2�߀�G�ƃQ��5l�1��­v�4����x��M��B��1�A��V'��򝠕
Dh ��I"ʨP9�O�,�00�m�|��ۉ��Ӱ��bvߩ�g��)W=⯐��}o��ʷ��A��s^^?}s���췠����i*����g9�;�����i��R{��ia�=t��M?�ʃ:yNg���;l�E�;4N�lxiG��EG5BȖ`�_�{xS�"��6�,�^E�SA���w&5=f�j�ϛ������c��W�Y�F���ц>�	�)Qqt �̓�g@f���p8��"0�٨������/^�����v��en����Qq�3�u&�@^�8�I�>Pև�D��!�	�Kf둛������j+B�� �Uڏ�.�t�+����g�J�6���      W   �   x��Q1N�0�����l� WBEMMC�DAA�(��!N���`�H��16(*9�wgf�c���_�����4�����0�Gt��WW�TƊSxe�E�Vg�K�
���U��Za�����i�����ᥕg0�yZ�'5r8���N$|�{���`��FaU��=e��>a����ۻ���B�G�Rή��g�X�螫�Mѵ�n"��KX#'�ʦ=�4��&�������5�,k#�"��h�K      Y   �  x���=N�@���)��D޵�tp�H�q�."Q"W�$6	N�\a�F�Y�@�HȒv<߼73J����N�J���5U�-la%�� b�Tⱱ3il�pcs��ç����i���B�Ҿ{J��P�A��4�}�DA ���m!��T�c�@Z�;?%�W�@gn3h�����2��w���E�Υ����6�A����O���KX�Ќ}r�;l�b��,��=B�������v���_^ߏ�;�1��VNшD�I���]c82�yҖ������	rrz�j�+q��s@$Bwb���c�6$?�g���ّ}�*�~$~ę�W����o�N}���q� �iA���r�t�+Z����3���{OK2��H�b,H.�X�5�E�;��s��n��kڻ�{��,k�s      [   2   x�Ź  ��-��6�B�u0�D6l-Õ*H�l�)U�j�:\uy�`{
'      ]   �   x�}�MA��ݧ���VDbe5���0+	�X�ID���pd��3�
�n��͖EWR����:#���`�z6)�p3���<Z"�CfE����r��Κ���]�+�)�8 �9y<z!�5�{#~O<�.�T��1.�2BQ`�͂�SIYx"��i&e��
�}�������R�0ۓ���NV��H;-��!nrO��NI)?i�G      _   !   x�3�4�2�4�2�4�2�4�2�4����� '�      a   �  x�mRKN�@]w��������a�l��)�H�H�	�c{pBl�Pu#^���Dȶ������$��9��kjiI�5�;*��m���s*xN5�9Z�U���Z��j7T����؇��;�ϣ��&�g���#fH P�М�-s��š ~S����ӞW)��H�Ff�fj�/�qT��Ltb24����=�S�Ra����WP��l��:HS"���⊶����i��$��a@�-�	&���I/��_��*3���I��`��I3�,r�؀�fg����'���ѾGM{�� 6����M�D�%߉��F��1��I����k Z��\2+�؏:p��!�~]j�|u1ώ:F�g
1�	1�����Jن�`Š���I��WD���f~�ƭ�j�a)B��{�\p>%vb&��@���p�oW˿�8��:z���������X��=��f&3�<���:�=С�����=0��{�
�鰫��yb��e��      r      x��_�$ŕş�OQ;~��PΈ�YoX26H��/�2F�Y���%�ͬ%�6�ZX�	��63��B�7ڈ���̪����u[��������Y�7n��{Ձ:X~�zo���<^~�|�����I���ly��f�t�x�m|������l����Sf�|�~j~�+m^P��g�.�^�jntc������s�@_`��� �s́ɻD������ �G�k��l���սս�����+=X�~�ٯӃQԓ�Խ�����jO��W�ލ/_u��,������G�?��9{��P�p�@|���W[~�|��y���������	6��gWs��}o�� ��"�K���9���$�ķ��ߋ������(=����-v<j�G�����[�ǧ�Cf<N��l1�@�WF�>P�ʈ�T��`|���6օ5���EC�ˑ�� �#!G.��s� X]�������h�9r�P���#���Z�p"jqY�А��i(,�0Ɔ�Y9mr"�"�9m9mt��h;ں�d��!g�m�%��m���G�b�\B��2Ҷ������ʒ��*�&�,9iH�YrҐPg�IC�ɒ��[|NF��I�h}��4$�,9iHh�s�@���s�P���IC1:ON"�t���;��oվP��/�/O�ǳ�\�Y+�}��3��Y���V���35k'�����[>|~�z'�X\������|�������W�)���Jσ���DӮ¶��w�^?�U�H ��$IU���L:6s�U�֛kS�����w�u�d�0��q|�m/e�����yh\{��Cs�h}\���m��`��O��].��=�S����9�s�B{��V��[w޼�^5t��Z���}��h3�q�"���Mʒ����u-	[���\�Q��R����^d{~�#��E{�>�Ϗ�Թd��3�\�tQ=N2?[�O��ߍN�3x��tv,����L:���`���@�G핯�'��8>�u�ث?�	��\G�J/ ��v��e:�>K���y����}J�0�.�ߋ�)u���f��f<���O��$�M����,l=7�6z�!���r�\����"��[.�*�\��r�em�-��p�e@�b�2���e Ƌ��@L �� ���I>�u��<9i@PyrҀ����Γ�S~NDk��I�h]��4 �<9i@�9i ��Igb�J<'ĨL9i����~i����MM�I�C�I������s�6�������hrN�"��"'%�PrY	��ri	����Pc؉	0l��4��LU.Gj#|��4F49R�O��s�8\Uz���sd�1�Α=�#�=�j�p��q��c��g�cF g���<��+�#r��F芜= B�K���u�	
�k
NP \KNP ��	
 �\�j�\�j������	
0T��(�M�3�ɍ7��z!��7��~!
n���-�
�܄!�m8 ����@j�q 5r�8�v+��zqDM���^u��֎�V�8�i��7{������H�?�<�n޹S� ����L]?�Դ�c<U�S:._:�^HT~������u�8�D-%��r���Į��y$)�]O��H�R��&��$ڮ�y$z)�]��HR�$��HI4�.^{��Go�}�ڄLϔi����5��|��k?����b"����׮��1��|��k/~OLb8����On���_�~]H��w9�v���������i��â6s�����9ߥ��Ko�����R�
W��r�g�����[�G�wĤ��]����R�]��f.k�̫�r����ͅd;B��\A6t!D��.n��..�����B9OR#��Bj�<]H�ӅdO�at�]� {����Br�� �� "lC�lC�mcA��!��m����!5r�1��mC�ml]���zgZ �� �!���lC�m!
���p���pɶ1� ��B�6����Ɛ9�ض]�mc�A��m}:�Β���iȞ1@ [� �`���`�����]l� 8�	��3�1r^1 ��H}�������7��b��W<��|���4�4�O��J��Gm����,���~A�[moׯSp��0z�xʴ��6����B����غW�Z�����!u���+���G]e�ݨ�+��uG]i��9�J+�&<]i���+-��u�%vc����0��1���f�n������������o��:�k;�q��H=X��CF3N�B2�yR�2�8�J���|)%�'E)f���d�qz���6r������t��l$���H9R�v~������7Wy�p������qj��߸��o�D��q1���B�E��CN�MÚ; #��0�:#�3�0��!`8�b���p�c�0�:#��A5b����Q`Xwf�\z���ށa�$���}�(mm�$8B�,Ip��Y������Ẫ�5
We�P#�Β�F�ѐe�v���rWK'�њ�$8Rc���H�˓G�'	���G��;��4v�I%D�TJ`�:�#�f)�PT�FP�Rx��w\�(�w\�(|&� �P�
�[�.��B��Hpty��]$B�߁�6x�J���j��K���M3RC�E���!��Ai�u_�R���Um�nu�j�nu�j���c����0�C��FBU,����)�As��9�QW�A�Q�cn���q��Y�Av�Rӎ�ѝݖ�y�Xw�1f4�$��Pdc�Q+gT� c�l�A�1!���(���-���%c�l�A9cP��1H��1�ac�m�A�1�o)[��A6� ��dcB�MQ��&���ek�.�[�-�[�-��1��3� 5r���m�A�11���P_��P;�a��FP;�aD���p��vV����BP;�a�Tg5�F��V#�Y����j��2e�!Coܘ���ϫ�?u�j���Ə��[2g��v'�{	������l L+;����fa��V*��k�7�Hj1$�؍6�Z�F/I-~�!����ѕ@RK�њ@P��6�HjQ�M
$���N�b��v�b�f�I1�i抈q�h_��{�Y�]`���窪*ozy���� /\����5�h�_��.��o��%���A��D'�=ȫ/��o��%z��A��L�=�s��޷}�2����/\�o��5{�+�/T�7j7R�����NH�ڽ�!]�޽�!]C�{KC��{?C��{3C��{'C��{C���{C����"����"�Z�E��-���7k	oY�xy�/�Ԯp�Z9�K�x#���.��?������.��=��K�x����Lu�.�٥]�=vi�˟]�%�g�v�N�ٵ]�vm�轟]��x��][صvW��`~�k���jך��W���d�޵V'��]�t2��Z���v����w���d�߹.';��d���8W��v�����u8Y�f�����y����G�L�8F�S#�=�0��S#|�Nqn(�)��m�Nq��+�S#��S�����X�r�c5���Gu�cu��)�U���lMm���NAm����	#�m��-�����	#���0B��V#��	��j��p[;a��dXjk����d�6^���jk'��6p�jw���$���$����&An`&A�h�I"\%��%��-�����1�P� ~SS?=Ch��>jk'���v�jk'���vb[;�p}���p���NAm�R�����NX�Tk'����	3���0�:�,"Ԣ��u�L�f=�y"j�(H����j�(H(�q��ؾQ0Zj�(H�v����QP�T�((F�e�p;FA�aD�k�5!}��Za0�j���#�V�(�
��-�
�åZa�VT+FHM9�j���a5RSΰ�3��N9�ꔳ����!�|=�j���#�V�PT+Fk���k���R�0A��`������`5RV��k���24�
�!�����f[a �:�#�S�0�:�#��r��-v��:�#�S�0Bj�TSKM9�j���a5�)g���r��)ga��E��ڙ\� [a�l�A�!�V�(�
�5[aP�d+B��0!g�Aj�XDj�XDj<9 |
  	"F 'A�Ȕ�	�'���K6� ��d;B�A�l�A�1A�� ��'��3� 5r��Ʊm1���� �c�¸y��nT��3!|u�0�<����<�.S��"׳(
���(���[ Q�*�B�E��~�(y��V�.wσV�p�<a�{�(�fe����ŗ��!5r[<�&��x���W��7��-ZR�1�A6� ��1��3� 5r���m�A�10�1�YDJm��)ku���#�=b0��##�=b0��o�0u�#����-��چ#�mh�URmh��64X�T��ۆ3�mh0�j�A^WQ�1A� #���(��U�cp�TcFP�1!e��j�z�`5R=b�n������j��fa��6�rֹ�dB��f�銛gAZq�,Bhn�E���g���,>����W��=p�>ә6x��Y������5\�Z�q���2XjLXjLV�]���
�-ZR�1����cDj���ށ��1X�T����13�c0�m��M����񟏺S5�/���;G���c������ս���vU�&6[-���X�6��1MWHF��+$�٘�+#�V#v�d��I�B2���]!���]!fc����9�WH���+��o���6G�
�h6'���pd�k��ۄA�I�Ԟ4A�I�Ԟ4Qp͌�-��J.�'FP{�`�TO��K���j�z�`5ܞ4���I����{D��]��'[o�l�A��!���(�z�[oP�d�B��7!g�Aj�7H����a/���e�i��U;��k����l���L ���	�3�`�b&��$8�-4	N��Ip�I#Ӫ7@�ު>� �g'ִ�ɳP�O7�H��	5��g'ԛ�'�aM�M�+氦	sX��9�iQ갦�pK��L�˴�`�bZo&B֛	5B֛	5B֛	5T���j��`0�5%D������y�#�Ú&�f`�&���aM�R��M�[갦�p�=i&̞4��4j�z�L��I3��ړf�A�I�5�s�0q���1f�4�L �Ƙ	�3�(�3n�Ƙ�p�Ƙ	�3�2�`5F�3�F�3��j��`P�1�1f�psg����/��L`�b0�i���R=10Z[�%G�t�`��	B~,F����a��#�^�`[a��C��e�g���4�`�g�@0�,L J�4n��&�e�g�@0�3M �z�O���?�F�w?V㩽�'��L�x��0ja��ա�|� [a�l�A�!�V�(�
��-�
��%[a "��0!g�Aj�0H���a[a�m�A�XϺ���>GJv����o9R���H�#D�lE8�P9R��KO��pK�7.s���9Bo�S�X�N�c5A8%��4YR��#R򘡄S�X�JVɎ[�y,O�jzs��Q7u�`6ɞ��9�x�Y#<3�cu�w�_��U�/B���R�iN��f�]0�j+���[�QH����ǈxM�v`8`�V�݁A���������~��Tm8��b�d|��U2FP�d������+p����聚l��3Fͭ�1C�J�jږ9�wך�W�KG��"�8��4��g�ӕ)I���Ę}��3�Y�L߶Kv?��L��0��?uן���g�w�E���C���Ek�^��.���gl��MSY�z����m�7��~��N�B��l��o��~ޮޗ��<���n{���ɬ��r���l�|��;o�\�R�oݺk/X�O�m��o���9򛔖��_�w{�j����j����:@���h�#��E{��G�:u6����K�� �I�g�-�Z���;�m"4�=]\�ON�r�O�sM{�7��Q{*�������N���ϔ�}��i�WJ?m/�_��賔��'��ʭ���۬o�|�������L^ߥ�_q���z-
�|���o���K����;8�h����֎R�������4ߢ�-����3nX�v�����*<=[���e�,Qһq׸>�WK�t�����]����ݼ����~stm���3]���I粟w�v���?�v�m��uec�%��-�n�ӬW���vt?[�k�?z��[b2;���VTJ���y�篈i�������$v��gK�ɍW_��ׯ�	�>z�З�~�ׇ��dv��<[��~���۷��I�>z���B�S3�E���mc�=EP3a�1FP3A��6fb3�p�m̄å6f���!�'V#՘	��j̄�p3a�1d���D>��jT���ʟ!t��<F�9R�ar��1��H�c�+=%������q�!GJ#�)y��pJ�Q�)y�F�䱚:KJ3L��<fX�<VC��c-n��T���G��d� W�A���!W�Qp���-�JFᒫd� W�!W%#5rU2R#W%#5�*1�U�6���d��\%��T�)�\%#�JFr���*!
��Q�W�(\r���* �\����U�H�\��԰�d�`WɈ!W%#5�*��V���2=�\%#�JFr��!?Qp���-�JFᒫd� W�!W%#5rU2R#W%#5�*1�U2`�rU2RC��{�7��r���*!�U2B��d�(�JF�\%�p�U2B��d�0rU2R#W%#5rU2Rî��]%#�\������=���
Ow      c   0   x�Ź  ��:�#����s�B���Is�]��r�]��+���
�      e   }   x�-�K
1ѵ�0a$[��%�?Gz����6<PF�G�I���漏~�b1wl��8�ݸ�|��2��X��`�Fs,���x�踀[� :�Q�G5 �рW� �q"���n��~$� C� �      g     x����J�@��٧���d�\oa'X����]@ED��F���wO_a���wr���$d�3��͈'}LuH��u���黽�uLm��^7|��B[9��t��;�}�)��h��t���Q1���"�z�sO��qR��i[�r�O<���O�)8)I�OK�C]��8+r�]e��3�-�4M��> ({����t�g�T�J'�pZ�7:�Q��B���,5M�>�SQ�Mg@����,�`��Ԙj2}Ư)n+�����s�S���      i      x�3�,�2�L����� &      k   M   x�3�0�{.츰����.6\�p��¾�
���\F��9@y���rƜ�\�4c+B'W� �N8X      m   Y   x�3��J,KN.�,(�2��,����2�r�p�p�r:+s�qz����;s�s��'g�qYpz�&�奖�sYr:�s��qqq Մ*      o   Y   x�E���0���K�@BBv��sԑ�"�8��_�.k�^���^�'E����ɛ:��,�&&W�XX̢�c"�?:����&�Q��     