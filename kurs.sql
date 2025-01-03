PGDMP                       |            kurs    16.3    16.3 I   u           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            v           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            w           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            x           1262    17157    kurs    DATABASE     x   CREATE DATABASE kurs WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';
    DROP DATABASE kurs;
                postgres    false            *           1255    17158    check_employee_activity()    FUNCTION     N  CREATE FUNCTION public.check_employee_activity() RETURNS void
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
       public          postgres    false            (           1255    17977 N   create_announcement(character varying, character varying, date, date, integer)    FUNCTION     
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
       public          postgres    false            $           1255    17160 S   create_event(character varying, character varying, date, integer, integer, integer)    FUNCTION        CREATE FUNCTION public.create_event(p_name character varying, p_description character varying, p_date date, p_event_location integer, p_employee_creator integer, p_bot_id integer) RETURNS void
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

    
END;
$$;
 �   DROP FUNCTION public.create_event(p_name character varying, p_description character varying, p_date date, p_event_location integer, p_employee_creator integer, p_bot_id integer);
       public          postgres    false            -           1255    18311 "   find_unique_skills_in_department()    FUNCTION     �  CREATE FUNCTION public.find_unique_skills_in_department() RETURNS TABLE(employee_id integer, employee_name character varying, department_name character varying, skill_name character varying)
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
       public          postgres    false            /           1255    18319 ,   generate_employee_position_document_report()    FUNCTION       CREATE FUNCTION public.generate_employee_position_document_report() RETURNS TABLE(employee_name character varying, employee_email character varying, job_title_name character varying, position_name character varying, document_title character varying, document_description character varying, document_load_date date)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.full_name AS employee_name,
        e.email AS employee_email,
        jt.name AS job_title_name,
        jt.name AS position_name, -- Используем jt.name вместо p.name
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
        jt.name, e.full_name; -- Сортировка по jt.name вместо p.name
END;
$$;
 C   DROP FUNCTION public.generate_employee_position_document_report();
       public          postgres    false                       1255    17163 #   get_employee_contact_chain(integer)    FUNCTION     �  CREATE FUNCTION public.get_employee_contact_chain(employee_id integer) RETURNS TABLE(full_name character varying, job_title character varying, department_name character varying, department_phone_number character varying, internal_phone_number character varying, employee_email character varying)
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
       public          postgres    false                       1255    17164    isannouncementactive(smallint)    FUNCTION     �  CREATE FUNCTION public.isannouncementactive(p_announcement_id smallint) RETURNS boolean
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
       public          postgres    false                       1255    17165    isannouncementactive(integer)    FUNCTION     �  CREATE FUNCTION public.isannouncementactive(p_announcement_id integer) RETURNS boolean
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
       public          postgres    false                       1255    17166    listactiveannouncements()    FUNCTION     �  CREATE FUNCTION public.listactiveannouncements() RETURNS TABLE(title character varying, description character varying, creation_date date, end_date date)
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
       public          postgres    false                        1255    17167    listemployeeswithoutphone()    FUNCTION     Y  CREATE FUNCTION public.listemployeeswithoutphone() RETURNS TABLE(employee_name character varying)
    LANGUAGE plpgsql
    AS $$

BEGIN
    FOR employee_name IN
        SELECT e.full_name
        FROM employee e
        
        WHERE e.phone_number IS NULL OR e.phone_number = '' 
         
    LOOP
        RETURN NEXT;
    END LOOP;
END;
$$;
 2   DROP FUNCTION public.listemployeeswithoutphone();
       public          postgres    false            ,           1255    17955    listtodaysevents()    FUNCTION     �  CREATE FUNCTION public.listtodaysevents() RETURNS TABLE(id_event integer, name character varying, discription character varying, date date, id_event_location integer, id_employee integer, creator_name character varying, event_location_name character varying)
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
       public          postgres    false                       1255    17168    mark_message_as_read(bigint)    FUNCTION     �   CREATE FUNCTION public.mark_message_as_read(p_message_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE messages
    SET id_read_status = 2 -- Статус 2 = прочитано
    WHERE id_message = p_message_id;
END;
$$;
 @   DROP FUNCTION public.mark_message_as_read(p_message_id bigint);
       public          postgres    false            )           1255    17169 S   notify_event(integer, character varying, character varying, date, integer, integer)    FUNCTION     G  CREATE FUNCTION public.notify_event(p_event_id integer, p_event_name character varying, p_description character varying, p_event_date date, p_creator_id integer, p_bot_id integer) RETURNS void
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
       public          postgres    false            +           1255    17170     notify_low_skill_levels(integer)    FUNCTION     ^  CREATE FUNCTION public.notify_low_skill_levels(norm integer) RETURNS void
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
       public          postgres    false            #           1255    17172     notifyinactiveemployees(integer)    FUNCTION     R  CREATE FUNCTION public.notifyinactiveemployees(norm integer) RETURNS void
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
       public          postgres    false            "           1255    17173 1   send_message(integer, integer, character varying)    FUNCTION       CREATE FUNCTION public.send_message(p_sender_id integer, p_requester_id integer, p_content character varying) RETURNS void
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
       public          postgres    false            .           1255    17978 &   trigger_insert_notification_on_event()    FUNCTION     M  CREATE FUNCTION public.trigger_insert_notification_on_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_message_content character varying;
BEGIN
    v_message_content := 'Новое событие: ' || NEW.name || '  Описание: ' || NEW.discription || 
                        '  Дата: ' || NEW.date || '  Создатель события ID: ' || NEW.id_employee;

    -- Insert into notifications for all employees
    INSERT INTO notifications (id_employee, content)
    SELECT id_employee, v_message_content
    FROM employee;

    RETURN NEW;
END;
$$;
 =   DROP FUNCTION public.trigger_insert_notification_on_event();
       public          postgres    false            !           1255    17174 $   validateskilllevel(integer, integer)    FUNCTION     �  CREATE FUNCTION public.validateskilllevel(p_skill_own_id integer, p_threshold integer) RETURNS boolean
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
          public          postgres    false    257                       1259    17292    position    TABLE     �   CREATE TABLE public."position" (
    id_position smallint NOT NULL,
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
       public          postgres    false    268    269    269                        2604    17338    office id_office    DEFAULT     t   ALTER TABLE ONLY public.office ALTER COLUMN id_office SET DEFAULT nextval('public.office_id_office_seq'::regclass);
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
    public          postgres    false    215   �      >          0    17179    announcements 
   TABLE DATA           r   COPY public.announcements (id_announcement, title, discription, creation_date, end_date, id_employee) FROM stdin;
    public          postgres    false    217   8      @          0    17185    business_card 
   TABLE DATA           l   COPY public.business_card (id_business_card, content, creation_date, id_card_type, id_employee) FROM stdin;
    public          postgres    false    219   	      B          0    17191    business_center 
   TABLE DATA           F   COPY public.business_center (id_business_center, address) FROM stdin;
    public          postgres    false    221   ^
      D          0    17197 	   card_type 
   TABLE DATA           7   COPY public.card_type (id_card_type, type) FROM stdin;
    public          postgres    false    223   �
      F          0    17203 
   department 
   TABLE DATA           v   COPY public.department (id_department, name, open_hours, close_hours, department_phone_number, id_office) FROM stdin;
    public          postgres    false    225         H          0    17209    document 
   TABLE DATA           �   COPY public.document (id_document, title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template) FROM stdin;
    public          postgres    false    227          I          0    17214    document_access 
   TABLE DATA           T   COPY public.document_access (id_event_access, id_document, id_employee) FROM stdin;
    public          postgres    false    228         L          0    17219    document_template 
   TABLE DATA           V   COPY public.document_template (id_document_template, name, path_template) FROM stdin;
    public          postgres    false    231   s      O          0    17226    employee 
   TABLE DATA           t   COPY public.employee (id_employee, full_name, email, phone_number, employment_date, is_admin, password) FROM stdin;
    public          postgres    false    234   >      Q          0    17232    event_access 
   TABLE DATA           N   COPY public.event_access (id_event_access, id_event, id_employee) FROM stdin;
    public          postgres    false    236   �      S          0    17236    event_location 
   TABLE DATA           A   COPY public.event_location (id_event_location, name) FROM stdin;
    public          postgres    false    238   7      U          0    17242    events 
   TABLE DATA           c   COPY public.events (id_event, name, discription, date, id_event_location, id_employee) FROM stdin;
    public          postgres    false    240   G      W          0    17248 
   group_chat 
   TABLE DATA           H   COPY public.group_chat (id_group_chat, name, creation_date) FROM stdin;
    public          postgres    false    242   u      Y          0    17254    group_messages 
   TABLE DATA           x   COPY public.group_messages (id_group_message, content, id_group_chat, id_sender, send_time, id_read_status) FROM stdin;
    public          postgres    false    244         [          0    17260    ip_phone 
   TABLE DATA           =   COPY public.ip_phone (id_phone, internal_number) FROM stdin;
    public          postgres    false    246   ,      ]          0    17266 	   job_title 
   TABLE DATA           7   COPY public.job_title (id_job_title, name) FROM stdin;
    public          postgres    false    248   n      _          0    17272    level_skill 
   TABLE DATA           <   COPY public.level_skill (id_level_skill, level) FROM stdin;
    public          postgres    false    250   I      a          0    17276    messages 
   TABLE DATA           k   COPY public.messages (id_message, id_sender, content, send_time, id_read_status, id_requester) FROM stdin;
    public          postgres    false    252   z      r          0    17957    notifications 
   TABLE DATA           c   COPY public.notifications (id_notification, id_employee, content, created_at, is_read) FROM stdin;
    public          postgres    false    269   q      c          0    17282    office 
   TABLE DATA           N   COPY public.office (id_office, office_number, id_business_center) FROM stdin;
    public          postgres    false    254   6      e          0    17288    participation_chats 
   TABLE DATA           j   COPY public.participation_chats (id_participation_chats, id_employee, id_role, id_group_chat) FROM stdin;
    public          postgres    false    256   M6      g          0    17292    position 
   TABLE DATA           w   COPY public."position" (id_position, appointment_date, id_employee, id_job_title, id_phone, id_department) FROM stdin;
    public          postgres    false    258   �6      i          0    17298    read_status 
   TABLE DATA           =   COPY public.read_status (id_read_status, status) FROM stdin;
    public          postgres    false    260   o7      k          0    17302    roles 
   TABLE DATA           .   COPY public.roles (id_role, name) FROM stdin;
    public          postgres    false    262   �7      m          0    17308 
   skill_name 
   TABLE DATA           9   COPY public.skill_name (id_skill_name, name) FROM stdin;
    public          postgres    false    264   �7      o          0    17314 	   skill_own 
   TABLE DATA           i   COPY public.skill_own (id_skill_own, last_check, id_level_skill, id_skill_name, id_employee) FROM stdin;
    public          postgres    false    266   Z8      �           0    0 .   announcement_access_id_announcement_access_seq    SEQUENCE SET     ]   SELECT pg_catalog.setval('public.announcement_access_id_announcement_access_seq', 18, true);
          public          postgres    false    216            �           0    0 !   announcements_id_announcement_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public.announcements_id_announcement_seq', 15, true);
          public          postgres    false    218            �           0    0 "   business_card_id_business_card_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('public.business_card_id_business_card_seq', 13, true);
          public          postgres    false    220            �           0    0 &   business_center_id_business_center_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public.business_center_id_business_center_seq', 2, true);
          public          postgres    false    222            �           0    0    card_type_id_card_type_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.card_type_id_card_type_seq', 2, true);
          public          postgres    false    224            �           0    0    department_id_department_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.department_id_department_seq', 9, true);
          public          postgres    false    226            �           0    0 #   document_access_id_event_access_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.document_access_id_event_access_seq', 27, true);
          public          postgres    false    229            �           0    0    document_id_document_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.document_id_document_seq', 12, true);
          public          postgres    false    230            �           0    0 *   document_template_id_document_template_seq    SEQUENCE SET     X   SELECT pg_catalog.setval('public.document_template_id_document_template_seq', 3, true);
          public          postgres    false    232            �           0    0    document_title_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.document_title_seq', 1, false);
          public          postgres    false    233            �           0    0    employee_id_employee_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.employee_id_employee_seq', 32, true);
          public          postgres    false    235            �           0    0     event_access_id_event_access_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public.event_access_id_event_access_seq', 152, true);
          public          postgres    false    237            �           0    0 $   event_location_id_event_location_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.event_location_id_event_location_seq', 9, true);
          public          postgres    false    239            �           0    0    events_id_event_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.events_id_event_seq', 15, true);
          public          postgres    false    241            �           0    0    group_chat_id_group_chat_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.group_chat_id_group_chat_seq', 9, true);
          public          postgres    false    243            �           0    0 #   group_messages_id_group_message_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.group_messages_id_group_message_seq', 11, true);
          public          postgres    false    245            �           0    0    ip_phone_id_phone_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.ip_phone_id_phone_seq', 9, true);
          public          postgres    false    247            �           0    0    job_title_id_job_title_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.job_title_id_job_title_seq', 9, true);
          public          postgres    false    249            �           0    0    level_skill_id_level_skill_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.level_skill_id_level_skill_seq', 5, true);
          public          postgres    false    251            �           0    0    messages_id_message_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.messages_id_message_seq', 21, true);
          public          postgres    false    253            �           0    0 !   notifications_id_notification_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.notifications_id_notification_seq', 2339, true);
          public          postgres    false    268            �           0    0    office_id_office_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.office_id_office_seq', 9, true);
          public          postgres    false    255            �           0    0 .   participation_chats_id_participation_chats_seq    SEQUENCE SET     ]   SELECT pg_catalog.setval('public.participation_chats_id_participation_chats_seq', 30, true);
          public          postgres    false    257            �           0    0    position_id_position_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.position_id_position_seq', 34, true);
          public          postgres    false    259            �           0    0    read_status_id_read_status_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.read_status_id_read_status_seq', 2, true);
          public          postgres    false    261            �           0    0    roles_id_role_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.roles_id_role_seq', 3, true);
          public          postgres    false    263            �           0    0    skill_name_id_skill_name_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.skill_name_id_skill_name_seq', 9, true);
          public          postgres    false    265            �           0    0    skill_own_id_skill_own_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.skill_own_id_skill_own_seq', 16, true);
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
       public          postgres    false    302    240            �           2620    17397 #   messages trigger_notify_new_message    TRIGGER     �   CREATE TRIGGER trigger_notify_new_message AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.notify_new_message();
 <   DROP TRIGGER trigger_notify_new_message ON public.messages;
       public          postgres    false    252    271            �           2606    18300 '   notifications FK_notifications_employee    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT "FK_notifications_employee" FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 S   ALTER TABLE ONLY public.notifications DROP CONSTRAINT "FK_notifications_employee";
       public          postgres    false    234    269    4893            @           2606    17398 <   announcement_access announcement_access_id_announcement_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 f   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey;
       public          postgres    false    4877    215    217            A           2606    17403 =   announcement_access announcement_access_id_announcement_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey1 FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 g   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey1;
       public          postgres    false    4877    217    215            B           2606    17408 =   announcement_access announcement_access_id_announcement_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey2 FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 g   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey2;
       public          postgres    false    217    215    4877            C           2606    17413 =   announcement_access announcement_access_id_announcement_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey3 FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 g   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey3;
       public          postgres    false    4877    215    217            D           2606    18070 8   announcement_access announcement_access_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 b   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey;
       public          postgres    false    234    215    4893            E           2606    18075 9   announcement_access announcement_access_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey1;
       public          postgres    false    215    4893    234            F           2606    18080 9   announcement_access announcement_access_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey2;
       public          postgres    false    215    4893    234            G           2606    18085 9   announcement_access announcement_access_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey3;
       public          postgres    false    215    4893    234            H           2606    18090 ,   announcements announcements_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey;
       public          postgres    false    4893    217    234            I           2606    18095 -   announcements announcements_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey1;
       public          postgres    false    234    217    4893            J           2606    18100 -   announcements announcements_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey2;
       public          postgres    false    217    234    4893            K           2606    18105 -   announcements announcements_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey3;
       public          postgres    false    234    217    4893            L           2606    17458 -   business_card business_card_id_card_type_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey;
       public          postgres    false    223    4883    219            M           2606    17463 .   business_card business_card_id_card_type_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey1 FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 X   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey1;
       public          postgres    false    219    223    4883            N           2606    17468 .   business_card business_card_id_card_type_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey2 FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 X   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey2;
       public          postgres    false    219    223    4883            O           2606    17473 .   business_card business_card_id_card_type_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey3 FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 X   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey3;
       public          postgres    false    223    4883    219            P           2606    18110 ,   business_card business_card_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey;
       public          postgres    false    234    4893    219            Q           2606    18115 -   business_card business_card_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey1;
       public          postgres    false    4893    219    234            R           2606    18120 -   business_card business_card_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey2;
       public          postgres    false    234    219    4893            S           2606    18125 -   business_card business_card_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey3;
       public          postgres    false    219    234    4893            T           2606    17498 $   department department_id_office_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey;
       public          postgres    false    4913    254    225            U           2606    17503 %   department department_id_office_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey1 FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey1;
       public          postgres    false    4913    225    254            V           2606    17508 %   department department_id_office_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey2 FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey2;
       public          postgres    false    4913    254    225            W           2606    17513 %   department department_id_office_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey3 FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey3;
       public          postgres    false    254    225    4913            `           2606    17518 0   document_access document_access_id_document_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey;
       public          postgres    false    228    4887    227            a           2606    17523 1   document_access document_access_id_document_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey1 FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey1;
       public          postgres    false    228    4887    227            b           2606    17528 1   document_access document_access_id_document_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey2 FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey2;
       public          postgres    false    227    4887    228            c           2606    17533 1   document_access document_access_id_document_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey3 FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey3;
       public          postgres    false    228    227    4887            d           2606    18130 0   document_access document_access_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey;
       public          postgres    false    4893    234    228            e           2606    18135 1   document_access document_access_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey1;
       public          postgres    false    4893    228    234            f           2606    18140 1   document_access document_access_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey2;
       public          postgres    false    228    234    4893            g           2606    18145 1   document_access document_access_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey3;
       public          postgres    false    234    228    4893            X           2606    17558 +   document document_id_document_template_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 U   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey;
       public          postgres    false    227    231    4891            Y           2606    17564 ,   document document_id_document_template_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey1 FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey1;
       public          postgres    false    231    4891    227            Z           2606    17569 ,   document document_id_document_template_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey2 FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey2;
       public          postgres    false    231    4891    227            [           2606    17574 ,   document document_id_document_template_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey3 FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey3;
       public          postgres    false    231    4891    227            \           2606    18150 "   document document_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 L   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey;
       public          postgres    false    4893    227    234            ]           2606    18155 #   document document_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey1;
       public          postgres    false    4893    227    234            ^           2606    18160 #   document document_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey2;
       public          postgres    false    4893    234    227            _           2606    18165 #   document document_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey3;
       public          postgres    false    4893    227    234            h           2606    18170 *   event_access event_access_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 T   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey;
       public          postgres    false    4893    234    236            i           2606    18175 +   event_access event_access_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey1;
       public          postgres    false    4893    234    236            j           2606    18180 +   event_access event_access_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey2;
       public          postgres    false    236    4893    234            k           2606    18185 +   event_access event_access_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey3;
       public          postgres    false    234    236    4893            l           2606    17983 '   event_access event_access_id_event_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 Q   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey;
       public          postgres    false    4899    240    236            m           2606    17988 (   event_access event_access_id_event_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey1 FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey1;
       public          postgres    false    4899    240    236            n           2606    17993 (   event_access event_access_id_event_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey2 FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey2;
       public          postgres    false    240    236    4899            o           2606    17998 (   event_access event_access_id_event_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey3 FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey3;
       public          postgres    false    236    4899    240            p           2606    18190    events events_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 H   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey;
       public          postgres    false    240    4893    234            q           2606    18195    events events_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 I   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey1;
       public          postgres    false    240    234    4893            r           2606    18200    events events_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 I   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey2;
       public          postgres    false    240    4893    234            s           2606    18205    events events_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 I   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey3;
       public          postgres    false    234    240    4893            t           2606    18041 $   events events_id_event_location_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey;
       public          postgres    false    4897    240    238            u           2606    18046 %   events events_id_event_location_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey1 FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey1;
       public          postgres    false    240    238    4897            v           2606    18051 %   events events_id_event_location_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey2 FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey2;
       public          postgres    false    4897    238    240            w           2606    18056 %   events events_id_event_location_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey3 FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey3;
       public          postgres    false    240    238    4897            x           2606    17679 0   group_messages group_messages_id_group_chat_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey;
       public          postgres    false    4901    242    244            y           2606    17684 1   group_messages group_messages_id_group_chat_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey1 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey1;
       public          postgres    false    242    244    4901            z           2606    17689 1   group_messages group_messages_id_group_chat_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey2 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey2;
       public          postgres    false    244    4901    242            {           2606    17694 1   group_messages group_messages_id_group_chat_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey3 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey3;
       public          postgres    false    242    244    4901            |           2606    17950 1   group_messages group_messages_id_read_status_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_read_status_fkey FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status);
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_read_status_fkey;
       public          postgres    false    260    4919    244            }           2606    18295 ,   group_messages group_messages_id_sender_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_sender_fkey FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON DELETE CASCADE;
 V   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_sender_fkey;
       public          postgres    false    244    234    4893            ~           2606    17699 %   messages messages_id_read_status_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey;
       public          postgres    false    4919    260    252                       2606    17704 &   messages messages_id_read_status_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey1 FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey1;
       public          postgres    false    260    4919    252            �           2606    17709 &   messages messages_id_read_status_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey2 FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey2;
       public          postgres    false    252    260    4919            �           2606    17714 &   messages messages_id_read_status_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey3 FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey3;
       public          postgres    false    260    252    4919            �           2606    18210 #   messages messages_id_requester_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey;
       public          postgres    false    252    234    4893            �           2606    18215 $   messages messages_id_requester_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey1 FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey1;
       public          postgres    false    252    234    4893            �           2606    18220 $   messages messages_id_requester_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey2 FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey2;
       public          postgres    false    234    252    4893            �           2606    18225 $   messages messages_id_requester_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey3 FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey3;
       public          postgres    false    252    234    4893            �           2606    18230     messages messages_id_sender_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 J   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey;
       public          postgres    false    234    252    4893            �           2606    18235 !   messages messages_id_sender_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey1 FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey1;
       public          postgres    false    234    252    4893            �           2606    18240 !   messages messages_id_sender_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey2 FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey2;
       public          postgres    false    4893    252    234            �           2606    18245 !   messages messages_id_sender_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey3 FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey3;
       public          postgres    false    4893    252    234            �           2606    17759 %   office office_id_business_center_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey;
       public          postgres    false    4881    254    221            �           2606    17764 &   office office_id_business_center_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey1 FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey1;
       public          postgres    false    221    4881    254            �           2606    17769 &   office office_id_business_center_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey2 FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey2;
       public          postgres    false    221    254    4881            �           2606    17774 &   office office_id_business_center_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey3 FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey3;
       public          postgres    false    254    221    4881            �           2606    18250 8   participation_chats participation_chats_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 b   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey;
       public          postgres    false    256    4893    234            �           2606    18255 9   participation_chats participation_chats_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey1;
       public          postgres    false    4893    234    256            �           2606    18260 9   participation_chats participation_chats_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey2;
       public          postgres    false    4893    234    256            �           2606    18265 9   participation_chats participation_chats_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey3;
       public          postgres    false    4893    256    234            �           2606    17799 :   participation_chats participation_chats_id_group_chat_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 d   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey;
       public          postgres    false    242    4901    256            �           2606    17804 ;   participation_chats participation_chats_id_group_chat_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey1 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 e   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey1;
       public          postgres    false    242    4901    256            �           2606    17809 ;   participation_chats participation_chats_id_group_chat_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey2 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 e   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey2;
       public          postgres    false    256    242    4901            �           2606    17814 ;   participation_chats participation_chats_id_group_chat_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey3 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 e   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey3;
       public          postgres    false    4901    256    242            �           2606    17819 4   participation_chats participation_chats_id_role_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 ^   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey;
       public          postgres    false    256    4921    262            �           2606    17824 5   participation_chats participation_chats_id_role_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey1 FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 _   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey1;
       public          postgres    false    4921    262    256            �           2606    17829 5   participation_chats participation_chats_id_role_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey2 FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 _   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey2;
       public          postgres    false    262    4921    256            �           2606    17834 5   participation_chats participation_chats_id_role_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey3 FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 _   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey3;
       public          postgres    false    4921    262    256            �           2606    17839 $   position position_id_department_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_department_fkey FOREIGN KEY (id_department) REFERENCES public.department(id_department) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_department_fkey;
       public          postgres    false    4885    225    258            �           2606    18270 "   position position_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_employee_fkey;
       public          postgres    false    4893    234    258            �           2606    17849 #   position position_id_job_title_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_job_title_fkey FOREIGN KEY (id_job_title) REFERENCES public.job_title(id_job_title) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_job_title_fkey;
       public          postgres    false    248    4907    258            �           2606    17854    position position_id_phone_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_phone_fkey FOREIGN KEY (id_phone) REFERENCES public.ip_phone(id_phone) ON UPDATE CASCADE ON DELETE RESTRICT;
 K   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_phone_fkey;
       public          postgres    false    246    258    4905            �           2606    18275 $   skill_own skill_own_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey;
       public          postgres    false    4893    234    266            �           2606    18280 %   skill_own skill_own_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey1;
       public          postgres    false    266    234    4893            �           2606    18285 %   skill_own skill_own_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey2;
       public          postgres    false    266    234    4893            �           2606    18290 %   skill_own skill_own_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey3;
       public          postgres    false    234    266    4893            �           2606    17879 '   skill_own skill_own_id_level_skill_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey;
       public          postgres    false    266    250    4909            �           2606    17884 (   skill_own skill_own_id_level_skill_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey1 FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 R   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey1;
       public          postgres    false    266    250    4909            �           2606    17889 (   skill_own skill_own_id_level_skill_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey2 FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 R   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey2;
       public          postgres    false    4909    250    266            �           2606    17894 (   skill_own skill_own_id_level_skill_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey3 FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 R   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey3;
       public          postgres    false    266    4909    250            �           2606    17899 &   skill_own skill_own_id_skill_name_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey;
       public          postgres    false    4923    264    266            �           2606    17904 '   skill_own skill_own_id_skill_name_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey1 FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey1;
       public          postgres    false    264    266    4923            �           2606    17909 '   skill_own skill_own_id_skill_name_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey2 FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey2;
       public          postgres    false    264    266    4923            �           2606    17914 '   skill_own skill_own_id_skill_name_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey3 FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey3;
       public          postgres    false    4923    264    266            <   L   x�˱�0�������%���s ��JQ����4\*l5nmM|�`n�儏F*�/i�v679������Gd      >   �  x��U�n�@]��b���H�d	�5�ذA�B*b���R�jD6TH<�/H�;���?��;~%JAb���̝�s�=3	}�܌h+��L(�m֚̔�<E��Ӊ�����Rd~�RH���Sh>j<r31#sZn��V�b
��9#��]^s��d,:�w����mϭ��SGNW��Bٽ�[�����OޝXz�$,>���|����y%�U�8+�J���� �jF��a϶�S}��hι\Pc3�\4�)S��e\�BB��ksa��4�O5�A�"�"|�~W���Wo�߾n߷�$�2Ӓ���9R�K������4��_(�a������^��%'G�pKȻ�ʰ���*Y�p��[��Y[%R���eNc�7��4TKӼ^K6+a4����3�D�)zd՛�����V�`��3P֯�E@#���
0M����O!-��9
�B�c.�m�.�Ⱥ��&�;ffX ܾ�l]5t����b�ɭ��M�c�l��g媓b�5��ܖir�,:�Q����t�q \5p0�.QCH@�ց9��e��Ғ�E�߯Á�O���.,M{�gr���kv\˅��������9�q��k\�e�:[Aݓ��G<_={|�^y�_�Q|<�o*�=X!h�b/D��N���q��\����&//>T��B�̕�X���v�+w�����]{����5�[����?�j6�
�ܷ��c�~v����8��(��      @   3  x����N�0���S����#!n�\�4 ��pD�����[�
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
�n��ĉ�9�;���kG�R�[	ە�ȡ֢�I㥉rY����6=B���G�HZ�+f�#��L&Ma4ޤ�)^�L�%��_z1�gv��g��`h)�>X*�$      O   7  x����n�@��'O�=��3��� e�M��\�nDY5A����U�	Lۨ!��
�o�9�B*D�?G����K�wx��h�������tv��G����MGp#l�qܖR�$(G9B���TnK~�M�/�h�).�Ey�nX�D��t�o2TJ��X8���7�.���������;��B�F�t��,��p\!#k���5���ȋX_�s�a�����dx���=�cy6��R��>��0����|�W�ʲ|j�G��:Ϛ�}�g��;nE ��\��I�m���p� `n$���u?beT0�)�I:iÐ��}k~�i���5]��|eI��{Ҍ����{Bz�3�Mo�fm��]��.�L0�w�=�j�$#��In&��>�v�Ŏ��O��d����==�!�Y~�?����t}�[�ӠGOv� ]Cܝ��L��l�q�/�.�r�ʼ�ۿ��r�� ��۬��W���!Su#P�r{m#���=«����nCs��w�份qx˖!�.��/�ck����Ӽ�؆q�i�Z��"ԅ      Q   �   x�%��0k4L����d�9r8�D���pl%z�ѫ]Z�ԎKݺ�[��l,eV���$�M!���7F�`W���g�R	��8ē~�9���qk�T�l����~�H`����Z������^0L~_@� \�ߘ��4��6W��|��~$� �*�      S      x�}�=N�@��S��)!���S!��r�$�Q"*$
@��Q,op���F�]�h�g��o�o���h|���:�QS���tz'�Ѳ^�^�U$���X*g��ɹ�;��ݡ�=<Q��#��~v؆S�=��R�u�̕>�S�E��5��\�����RXPF��g���� Kv�� Y�gO�+��N�#��b�C�.�f�\�?%�˵����e���9�>8�N�22�8�c����Ӱ�x{]�홈|�z��      U     x�}SKnA]W��9@��:�}vYpV�Y!J kg,���,�D�O0v�x����o��j��E��]��zݕ㖧XwX3^ٱk�k����k�/�b��om+��G�q����V��9�>�$Jғ89I#J��2�߀�G�ƃQ��5l�1��­v�4����x��M��B��1�A��V'��򝠕
Dh ��I"ʨP9�O�,�00�m�|��ۉ��Ӱ��bvߩ�g��)W=⯐��}o��ʷ��A��s^^?}s���췠����i*����g9�;�����i��R{��ia�=t��M?�ʃ:yNg���;l�E�;4N�lxiG��EG5BȖ`�_�{xS�"��6�,�^E�SA���w&5=f�j�ϛ������c��W�Y�F���ц>�	�)Qqt �̓�g@f���p8��"0�٨������/^�����v��en����Qq�3�u&�@^�8�I�>Pև�D��!�	�Kf둛������j+B�� �Uڏ�.�t�+����g�J�6���      W   �   x��Q1N�0�����l� WBEMMC�DAA�(��!N���`�H��16(*9�wgf�c���_�����4�����0�Gt��WW�TƊSxe�E�Vg�K�
���U��Za�����i�����ᥕg0�yZ�'5r8���N$|�{���`��FaU��=e��>a����ۻ���B�G�Rή��g�X�螫�Mѵ�n"��KX#'�ʦ=�4��&�������5�,k#�"��h�K      Y   �  x���=N�@���)��D޵�tp�H�q�."Q"W�$6	N�\a�F�Y�@�HȒv<߼73J����N�J���5U�-la%�� b�Tⱱ3il�pcs��ç����i���B�Ҿ{J��P�A��4�}�DA ���m!��T�c�@Z�;?%�W�@gn3h�����2��w���E�Υ����6�A����O���KX�Ќ}r�;l�b��,��=B�������v���_^ߏ�;�1��VNшD�I���]c82�yҖ������	rrz�j�+q��s@$Bwb���c�6$?�g���ّ}�*�~$~ę�W����o�N}���q� �iA���r�t�+Z����3���{OK2��H�b,H.�X�5�E�;��s��n��kڻ�{��,k�s      [   2   x�Ź  ��-��6�B�u0�D6l-Õ*H�l�)U�j�:\uy�`{
'      ]   �   x�}�MA��ݧ���VDbe5���0+	�X�ID���pd��3�
�n��͖EWR����:#���`�z6)�p3���<Z"�CfE����r��Κ���]�+�)�8 �9y<z!�5�{#~O<�.�T��1.�2BQ`�͂�SIYx"��i&e��
�}�������R�0ۓ���NV��H;-��!nrO��NI)?i�G      _   !   x�3�4�2�4�2�4�2�4�2�4����� '�      a   �  x�mRKN�@]w��������a�l��)�H�H�	�c{pBl�Pu#^���Dȶ������$��9��kjiI�5�;*��m���s*xN5�9Z�U���Z��j7T����؇��;�ϣ��&�g���#fH P�М�-s��š ~S����ӞW)��H�Ff�fj�/�qT��Ltb24����=�S�Ra����WP��l��:HS"���⊶����i��$��a@�-�	&���I/��_��*3���I��`��I3�,r�؀�fg����'���ѾGM{�� 6����M�D�%߉��F��1��I����k Z��\2+�؏:p��!�~]j�|u1ώ:F�g
1�	1�����Jن�`Š���I��WD���f~�ƭ�j�a)B��{�\p>%vb&��@���p�oW˿�8��:z���������X��=��f&3�<���:�=С�����=0��{�
�鰫��yb��e��      r      x��]�$�U���E;܀H��Q�jWߡ䂏D
v$n�1�@"��w6�pL,� P ����؞��>����s���޷�6�5g[�2�>g�yW}��֪�}hÕ�����'��7����^�������n��o�����?>{��h����G��?j6�G�om����|���7��\����ˮ�}�]��K>����pW�0��a4W�0��a�"q,�G{���U*��r����V�U��㯌_�O6���?�~����7�?|�G7�~��ߎ��?zk�ớ�۞�߿�������������_>�������>��������k�_xw�����9O�����g٦���T��"�����U.}m��U_�|�"��r[�+���K{��p�<���q���?�hb<?�OV��(����{ÿzz8�~3���x��pܽ�YBn�||��tW޿@rr�����_��w���:�����}q����,�������a�0�Z/�_��r̯�K9���k	��\���Y_��r��m򻐷.{��!��gF�~f�sh�8��������j�0dt����>����m�:���4:W��;e�z�oхB���6�2�ؕAF��ӧ��5s�p�w_�S�t��B��)�7s�h�[���$�!u��`���$;�:Q����q2!���>ݰvI+��NZ!D��"H�KZ�}��ֹ�6���f͈rC�f4rC�f$��]3ڪ��:޺��:^�[3z��Y1���k9����,��k9��R���!����3h17'>5�eC�03�O<�q�d�e�)�qeÂ��7�x+�C�x�O<���5î��ա�Ӕ~-�@J��H�W�d�ү�HSz����v��.�iJOҔ�0�)=aHSz¨6�'�V�ғx�)=aHSz�h�Rz"�*�'r�Rz"G���6�'���ȑ��3�O!�yz+͡	C�C�4�ƌN�CF�94�����+͡	C�C�UM�X��D�UM�hsh�����rh"G�C��M.����z����k�>�^3�9��Qw����z�>�^3�9�ћ��k9����-��k9����$�z��C9��о�s�]��a�s�5C�C�3�ϡ׌�s�u�u���x�9���ϡ��z-�4�^�1͡�r
��kH�z�9�Z����|�K~�s׻<3�94aHsh�Є!͡	����[mM��Є!͡1#X��D�U�ȱ�C9�:4�h��bU�&r�u�[FH1�Oқ ͡	C�C�4�ƌ(͡	����[mM��Є!͡	�*�&r�rh"�*�&r�94�hshi�rh"G�C�]궩��܍�4�1�94b�sh�P��kFrv�`�&o�`D�n����\�a@�ve.1}h�G�M/6% �$�C�Δ 9V�w"Ǫ�N�hK��-�H[�}z��������)=
Y��F�N����[sJ��U��N��0�GrSz$�0�Gr�)=��Sz �Sz$G��r���!��!N�!C��C�8��qJ��0ފ��0^qY2�eq��veq(Ǯ,�ؕšuYB�eq�+�C9�8z���eq��А!Ρ��АQq�8���sh��Аa�CC9v94�c�CC9�B�94�$'MZ�.��䶮ws�;9iΊҔ#�+FHV��6_��V���p��*FH�U��V�*Vc��b5V�*V�MT1C��b�U��մW�R#�"�E���&͌\�!�1�bF�.H��I8c��]�Y��v�poS�'�1R	�pưZ��錭�l����E��2�,S�-�A��]8�����2!l|�s�΅m�.�03�a��H*�p�Ѫ�F�2U�2}!޾F���m��0\`x�a���X��h`.�i�9If.@Z�a� �h�� '�r�����p�e$W�0�1|	�p�%�#�0g��v�po��0��ۖ0g���a8cdc�p&�76K9�/���L�/b� ��a8�Dc�p&�16gr��0��a�Bߥ�)F+{3�����Z� ��0 F��50^_�a���a���5�ј('�(�53PN'6�ņBz3À�dgf�Y�������59r��ɑ#dM�!kr�*�y�U69�peM�!kr���^��&G�Ƣɑ��59r��ɑ3,���&G�F��x@�f��6���3yS/kr���59RF�dM��&��*�/�[e��xeM��&��&�r,�/ȱhr� G���!^��xb��xA�E��9�&�FNn�'�zq�#d��!C���&GȨ���[q�#�7��!C��vM�P�]�#�c��娛!D��!vM�P�]�#�3����ͱ�H�K�lJ���rft����ZS��AkJ #��t[��)0q92*���x�}9�بr1��T�P g4��.0,
� ��\A9��tt���CV8Q8�3pP����r�M���N79�x+nr��!C��vM�P�]�#�c��娛!D��!vM�HNk��创�f��v��ui~�ъ�!C����2ę9dT���x+nu��{!C���]�#�c�����;B9�GQw<B�]�#�c��创�ε]��q�#d��#��!C��7=�x+nz��!C��vM�P�]�#�c��娛�W7=B�]�#�c���H���K��]�87���M�"�gDRzF��$�![i�o*������s�vǼ�:�m�D���5� 2�I�Z�!٤I�	�U�C�����aj5��l}�1dXΰi�?���`�˜�'�P�>AD��C�4�!�5���6�������l�:��Q~�7N��7N�Ns��0G̰���X�r�j�����q8x�G�t�#aH;�	�@.�b�����&Go�M�$^i�#aH�	êɑȱjr$r���m�#�h�	Ī��i���i���h|G��ɑ0�M��!mr$i�#aT��H⭶ɑ�+mr$i�#f$�&G"Ǫɑȱjr$r�M��mr$�&G"Ǫɑȑ69v�q~d�m�&�03z�a@�V\��q	2��0@F��0�x+.b�x�El��!�33P�]m����3��R��8��"5������2�aHc�!K';�t�#aH';�t�#aT;�ƛ�:/��.����Z��H|e��H��$��D�Մ#"�j����>D �F!�k�r��9�ю�.�]�[�\��.����ю�!�HQ�J �Ѻ�H��o[�a��vZ� Yk �73@Nv��0@9��0@9Al $��4f��If����y�G�8�~Y�Y	��J�wVB���1|ŝ�0ފ;+a���J�wVB�]g%�c�Y	��uVB9��JQwVB�]g%��:+�qg%x$����2ĝ��!qg%dT�Y	㭸��+qg%bD��J(Ǯ�ʱ묄rԝ�b����5=B9��#5]����Q:ّ0��1��Nv$�dG¨x8���Ɏ$^�dGNv$�ɎD��dG"�j�#����!I;ّ@�&;9V���d����fC?7�%q�#d��!C���GȨ���[q?"���#B��2����~D(Ǯ�Q�#B��B����~D(g��Ë#�w;�0�q���GB��=2�푐!n�����#a��G�x�푐!n����H$'۵GB9v�P��=B��b�	�صGB9��Y�lFF��	�ܠ���l�l C\����60ފ60^q�2�Ȱ+�@9v(Ǯ`�6 �;u�B�
6P�]�ʉ��e%G�j�-#�>��]�!^�2�2�e��e�˂���_N�y��x���3�ܿ,�4��e!'�������Y@�B�e���e!�n�$'8s����|�%�]L��]��P���ʗ_C��c(_~a�Z_~a�����W��c(_~!�hT�ar�
6L��`� ҂�l����cT�ar�F�29ʡ�3#�.�k��Q9�0�s�PN9g�sƨu�9���)�,^�s�PN9g���cT�ar�Ѿa� F&Ǩ`��l��<L�r�#�mv1��$�2�PN+c�2�PN+# �
  ���ie,�Z���x���C9��1�
6L�Q��ɑlDZ�a���cT�!r:����-��ZN(�_���3�q�����)�_�Tƿ,m��`t���E��~����/�_Nٕ�/�Ѵ2&�hZ�#�V� ����h$�c4������BN6�/9��eF�w��v}�og�������Z��Ak^"j�B4�Zn�oN�p�/N��i���l�JMp�+/F���bӂA�Y#�Y��1�HM2sH���C�q��,���qW¯�1r	�r��K8�%c8PX�3��ݳ��j7-g����є�-g��d���d��j2"]M�A�V�!r�^�ar��3P�]3����ι]충K�=2��vC9n�1��vC9n�1j���u�.�7*��2�r�.c#�B�D#�B�4R�B I�_�5�/D�U}�ȱ��9V�@XN��{d�&���P��e�]�P��e�]ƨu�.��ڢ�WZ5"iو0��FXN�*9���hKGbU;"r��GD�U��ȱ*9�q�!�|�5i�|������K�a��*g��r�.A�:i��[�]�r�.A(��Dkd[���ȵ`5YjZ0��z�W�1�b5�ȱ`5F�|5�ȯ`5��GD�3C9]�1��uC9]�1��u���$�\�t]�r�.c(��2��r�L��r�L�t9D�.�� F�!29�ڼ,���E��ڼ@;��N�y����oWP�7�O�;�!}��!}�0�o`��l�h�}^m�٦ն��x��N��ǐwj���P{=Đ��ɶ���	êE�lV�m"GۢM _����!'�6�7|������]�c'u�Ƶ��b�=`������HN��4��K'��t�/aXM�%r�&�9�	��|	�j�/����r^�k�����~*G�Jv�M���}
��!��K�	��!��K�	�����K�v�/�W:��0�|	�j�/�c5����N�%�_���K��f��_�1�/P�7�/P��~t��\>2��#�׏ C\?�q�2���K�v�/�W:�3�t�/aXM�%r�&�9�	����K V|��%��%��l�_r�1o�>\��c���ؿ��Q:�>|���l�����k�����?��n���f:�?�����_���Ǩ��ez��W7�o�6h}<~t��xm�L��7���������]tۜB��];u�y����{o���_Dy��T5������`��ǿ<��ӝ����������(�����9���nߟ�w�����ب�����9o�C��Z������^���hK��tX
���%�{Ϊ�����B=��_�8����{�G�T�*�[s:��s���j��Vi���J�WB���/��'����
���O�ɉ�����~;ޒ���5=��>����t��`<�~5ڢ������FU޼�����+߾����=��e��N��akՍ,�;Kʚ^���񓃥~vs�9ٝh�ܝ����2'�3o������s^��?ѥ����1����ᛇT����=�����h;=�D�xȧn������`|�0���W�䵿���������ͤ`L�����o��� <�'o=���xD�|uLԦ���Ó�!��Y��' 6�m�RNG��n�g���?���`(�0u��mUC����ϖ��}�Ne>��~�ʯ�������g����|���W_5�z�{��o��s�uC��y�������^������0{|�l����>8�����;w��y�j~9�{:�ǻ�?_�t�룛{���f��C��&����L�������w�'���/�9����/�J7'��x�o�%�]p���y)�A�48�nI���)��4��nI��-�S�t�$OÃ��i �ݒ<�[���������0��ni>��t�4wx�w�4�v�[�����ÓĻ�Y<$��m�B;3���!n��q>d���W܀㭸�+n��q>d�5��SS��x19x�&��M��n��&(Ǯ��	vM�P�]�?�����0kEN�#��F[��X����-��2�b���x�SFt��b!Ǜ��rB���������������9��}!�3��/�d��O���o�p; !4N�-Ë�� F�Ĉb��M��ś*�/(�V�_����v��������ڿ �W�	v�ɉv��i��������2���>�!�k;���� ������`�5�vP�5�vP���b�k;�aX�Ar�.H��� ���]�ú���]�ú���7��B�Kݶo\��3C7\�3tÕ8C7\�3tÕ8���J,�M֣��w��5���.�f��u�z⇛n�edݬ'�0�����z�r���8D8�CLf=q9&����YO\�ɬ'.G�8������ו�8CW��]9�3t�,Ψ���㭳���Օ�8CW���r�cR�br���8DX���r�cR��rL�Y\�I9�����$���3�-�8ɱ��B����#�Wz=�?���1���m�[�ǡ[�ǡk!�q��Bηi��<����#ۿu��L�op�lӠ[�ǡ[�ǡ+��8LJ�\��2�|�,�̷Ng.g�u�2�d1W9��(͡����A�rh�a���1y���1y���1y����|g-���;�(�/�/������;�      c   0   x�Ź  ��:�#����s�B���Is�]��r�]��+���
�      e   �   x�-���0D�3���\%�����h��ox������HKͲ�>����Fs��>�m�;q�h�#��.��)��%���#n�Kcd��d�@F܈�(��x#��2������}-o=�}? ~��!�      g   �   x�M��D1ϸV�{Ml��:��Vs�,g0M���B�r�S�Me/2���ڣ4�b�q���I+l�ЕKzز���.�h�ަ�r�g�9+�]V1��c�s��6�wWw	�c�7����]�����9&�      i      x�3�,�2�L����� &      k   M   x�3�0�{.츰����.6\�p��¾�
���\F��9@y���rƜ�\�4c+B'W� �N8X      m   Y   x�3��J,KN.�,(�2��,����2�r�p�p�r:+s�qz����;s�s��'g�qYpz�&�奖�sYr:�s��qqq Մ*      o   j   x�U�K�@е}�T��K��x�(�bœ�p�E\�g:��%�������R�2��(Rg���\EK�����*���_�W�LZ��?6���!yM�!T     