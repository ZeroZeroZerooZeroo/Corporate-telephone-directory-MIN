PGDMP                      |            kurs    16.3    16.3 :   a           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            b           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            c           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            d           1262    17157    kurs    DATABASE     x   CREATE DATABASE kurs WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';
    DROP DATABASE kurs;
                postgres    false                       1255    17158    check_employee_activity()    FUNCTION     �  CREATE FUNCTION public.check_employee_activity() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec RECORD;
    employment_duration INT;
BEGIN
    FOR rec IN SELECT id_employee, employment_date FROM employee LOOP
        employment_duration := DATE_PART('year', AGE(NOW(), rec.employment_date));

        IF employment_duration > 5 THEN
            RAISE NOTICE 'Сотрудник ID % работает более 5 лет.', rec.id_employee;
            -- Возможные действия: предложение о повышении
        ELSIF employment_duration BETWEEN 2 AND 5 THEN
            RAISE NOTICE 'Сотрудник ID % работает % лет.', rec.id_employee, employment_duration;
            -- Другая логика
        ELSE
            RAISE NOTICE 'Сотрудник ID % работает менее 2 лет.', rec.id_employee;
            -- Логика для новых сотрудников
        END IF;
    END LOOP;
END;
$$;
 0   DROP FUNCTION public.check_employee_activity();
       public          postgres    false                       1255    17159     countunreadmessagesperemployee()    FUNCTION       CREATE FUNCTION public.countunreadmessagesperemployee() RETURNS TABLE(employee_name character varying, unread_count integer)
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
       public          postgres    false                       1255    17160 S   create_event(character varying, character varying, date, integer, integer, integer)    FUNCTION     �  CREATE FUNCTION public.create_event(p_name character varying, p_description character varying, p_date date, p_event_location integer, p_employee_creator integer, p_bot_id integer) RETURNS void
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

    -- Вызываем функцию для отправки сообщения сотрудникам о новом событии
    PERFORM notify_event(v_event_id, p_name, p_description, p_date, p_employee_creator, p_bot_id);
END;
$$;
 �   DROP FUNCTION public.create_event(p_name character varying, p_description character varying, p_date date, p_event_location integer, p_employee_creator integer, p_bot_id integer);
       public          postgres    false                       1255    17161 "   find_unique_skills_in_department()    FUNCTION     �  CREATE FUNCTION public.find_unique_skills_in_department() RETURNS TABLE(employee_id smallint, employee_name character varying, department_name character varying, skill_name character varying)
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
       public          postgres    false                       1255    17162 ,   generate_employee_position_document_report()    FUNCTION     �  CREATE FUNCTION public.generate_employee_position_document_report() RETURNS TABLE(employee_name character varying, employee_email character varying, job_title_name character varying, position_name character varying, document_title character varying, document_description character varying, document_load_date date)
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
       public          postgres    false                       1255    17163 #   get_employee_contact_chain(integer)    FUNCTION     �  CREATE FUNCTION public.get_employee_contact_chain(employee_id integer) RETURNS TABLE(full_name character varying, job_title character varying, department_name character varying, department_phone_number character varying, internal_phone_number character varying, employee_email character varying)
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
       public          postgres    false                       1255    17164    isannouncementactive(smallint)    FUNCTION     �  CREATE FUNCTION public.isannouncementactive(p_announcement_id smallint) RETURNS boolean
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
       public          postgres    false                        1255    17165    isannouncementactive(integer)    FUNCTION     �  CREATE FUNCTION public.isannouncementactive(p_announcement_id integer) RETURNS boolean
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
       public          postgres    false            !           1255    17166    listactiveannouncements()    FUNCTION     �  CREATE FUNCTION public.listactiveannouncements() RETURNS TABLE(title character varying, description character varying, creation_date date, end_date date)
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
       public          postgres    false            "           1255    17167    listemployeeswithoutphone()    FUNCTION     �  CREATE FUNCTION public.listemployeeswithoutphone() RETURNS TABLE(employee_name character varying)
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
       public          postgres    false            #           1255    17168    mark_message_as_read(bigint)    FUNCTION     �   CREATE FUNCTION public.mark_message_as_read(p_message_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE messages
    SET id_read_status = 2 -- Статус 2 = прочитано
    WHERE id_message = p_message_id;
END;
$$;
 @   DROP FUNCTION public.mark_message_as_read(p_message_id bigint);
       public          postgres    false            $           1255    17169 S   notify_event(integer, character varying, character varying, date, integer, integer)    FUNCTION     a  CREATE FUNCTION public.notify_event(p_event_id integer, p_event_name character varying, p_description character varying, p_event_date date, p_creator_id integer, p_bot_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_message_content character varying;
BEGIN
    -- Формируем сообщение о событии
    v_message_content := 'Новое событие: ' || p_event_name || E'\nОписание: ' || p_description || 
                         E'\nДата: ' || p_event_date || E'\nСоздатель события: ' || p_creator_id;

    -- Отправляем сообщение каждому сотруднику
    INSERT INTO messages (id_sender, content, send_time, id_read_status, id_requester)
    SELECT p_bot_id, v_message_content, localtimestamp(0), 1, id_employee
    FROM employee;
END;
$$;
 �   DROP FUNCTION public.notify_event(p_event_id integer, p_event_name character varying, p_description character varying, p_event_date date, p_creator_id integer, p_bot_id integer);
       public          postgres    false                       1255    17170     notify_low_skill_levels(integer)    FUNCTION     '  CREATE FUNCTION public.notify_low_skill_levels(norm integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN SELECT id_employee, id_skill_name, id_level_skill FROM skill_own LOOP
        IF rec.id_level_skill < norm THEN
            RAISE NOTICE 'Сотрудник ID % имеет низкий уровень навыка ID %.', rec.id_employee, rec.id_skill_name;
            -- Логика уведомления, например, отправка email
        END IF;
    END LOOP;
END;
$$;
 <   DROP FUNCTION public.notify_low_skill_levels(norm integer);
       public          postgres    false                       1255    17171    notify_new_message()    FUNCTION     �   CREATE FUNCTION public.notify_new_message() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM pg_notify('new_message', NEW.id_requester::character varying); -- Уведомляем с ID получателя
    RETURN NEW;
END;
$$;
 +   DROP FUNCTION public.notify_new_message();
       public          postgres    false            %           1255    17172     notifyinactiveemployees(integer)    FUNCTION     �  CREATE FUNCTION public.notifyinactiveemployees(norm integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    emp RECORD;
    amount INT;
BEGIN
    FOR emp IN SELECT id_employee, full_name, email FROM employee LOOP
        -- Считаем количество отправленных сообщений
        SELECT COUNT(*) INTO amount 
        FROM messages 
        WHERE id_sender = emp.id_employee;
        
        -- Проверяем, превышает ли количество сообщений порог
        IF amount < norm THEN
            -- Здесь можно добавить логику отправки уведомления, например, запись в лог
            RAISE NOTICE 'Сотрудник % отправил % сообщений, что не превышает норму %.', 
                emp.full_name, amount, norm;
        END IF;
    END LOOP;
END;
$$;
 <   DROP FUNCTION public.notifyinactiveemployees(norm integer);
       public          postgres    false            &           1255    17173 1   send_message(integer, integer, character varying)    FUNCTION     {  CREATE FUNCTION public.send_message(p_sender_id integer, p_requester_id integer, p_content character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO messages (id_sender, id_requester, content, send_time, id_read_status)
    VALUES (p_sender_id, p_requester_id, p_content, localtimestamp(0), 1); -- Статус 1 = непрочитано
END;
$$;
 m   DROP FUNCTION public.send_message(p_sender_id integer, p_requester_id integer, p_content character varying);
       public          postgres    false            '           1255    17174 $   validateskilllevel(integer, integer)    FUNCTION     �  CREATE FUNCTION public.validateskilllevel(p_skill_own_id integer, p_threshold integer) RETURNS boolean
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
       public          postgres    false    215            e           0    0 .   announcement_access_id_announcement_access_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.announcement_access_id_announcement_access_seq OWNED BY public.announcement_access.id_announcement_access;
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
       public          postgres    false    217            f           0    0 !   announcements_id_announcement_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public.announcements_id_announcement_seq OWNED BY public.announcements.id_announcement;
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
       public          postgres    false    219            g           0    0 "   business_card_id_business_card_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE public.business_card_id_business_card_seq OWNED BY public.business_card.id_business_card;
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
       public          postgres    false    221            h           0    0 &   business_center_id_business_center_seq    SEQUENCE OWNED BY     q   ALTER SEQUENCE public.business_center_id_business_center_seq OWNED BY public.business_center.id_business_center;
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
       public          postgres    false    223            i           0    0    card_type_id_card_type_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.card_type_id_card_type_seq OWNED BY public.card_type.id_card_type;
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
       public          postgres    false    225            j           0    0    department_id_department_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.department_id_department_seq OWNED BY public.department.id_department;
          public          postgres    false    226            �            1259    17209    document    TABLE     V  CREATE TABLE public.document (
    id_document smallint NOT NULL,
    title smallint NOT NULL,
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
       public          postgres    false    228            k           0    0 #   document_access_id_event_access_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE public.document_access_id_event_access_seq OWNED BY public.document_access.id_event_access;
          public          postgres    false    229            �            1259    17218    document_id_document_seq    SEQUENCE     �   CREATE SEQUENCE public.document_id_document_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.document_id_document_seq;
       public          postgres    false    227            l           0    0    document_id_document_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.document_id_document_seq OWNED BY public.document.id_document;
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
       public          postgres    false    231            m           0    0 *   document_template_id_document_template_seq    SEQUENCE OWNED BY     y   ALTER SEQUENCE public.document_template_id_document_template_seq OWNED BY public.document_template.id_document_template;
          public          postgres    false    232            �            1259    17225    document_title_seq    SEQUENCE     �   CREATE SEQUENCE public.document_title_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.document_title_seq;
       public          postgres    false    227            n           0    0    document_title_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.document_title_seq OWNED BY public.document.title;
          public          postgres    false    233            �            1259    17226    employee    TABLE       CREATE TABLE public.employee (
    id_employee smallint NOT NULL,
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
       public          postgres    false    234            o           0    0    employee_id_employee_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.employee_id_employee_seq OWNED BY public.employee.id_employee;
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
       public          postgres    false    236            p           0    0     event_access_id_event_access_seq    SEQUENCE OWNED BY     e   ALTER SEQUENCE public.event_access_id_event_access_seq OWNED BY public.event_access.id_event_access;
          public          postgres    false    237            �            1259    17236    event_location    TABLE     u   CREATE TABLE public.event_location (
    id_event_location smallint NOT NULL,
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
       public          postgres    false    238            q           0    0 $   event_location_id_event_location_seq    SEQUENCE OWNED BY     m   ALTER SEQUENCE public.event_location_id_event_location_seq OWNED BY public.event_location.id_event_location;
          public          postgres    false    239            �            1259    17242    events    TABLE     �   CREATE TABLE public.events (
    id_event smallint NOT NULL,
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
       public          postgres    false    240            r           0    0    events_id_event_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.events_id_event_seq OWNED BY public.events.id_event;
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
       public          postgres    false    242            s           0    0    group_chat_id_group_chat_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.group_chat_id_group_chat_seq OWNED BY public.group_chat.id_group_chat;
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
       public          postgres    false    244            t           0    0 #   group_messages_id_group_message_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE public.group_messages_id_group_message_seq OWNED BY public.group_messages.id_group_message;
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
       public          postgres    false    246            u           0    0    ip_phone_id_phone_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.ip_phone_id_phone_seq OWNED BY public.ip_phone.id_phone;
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
       public          postgres    false    248            v           0    0    job_title_id_job_title_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.job_title_id_job_title_seq OWNED BY public.job_title.id_job_title;
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
       public          postgres    false    250            w           0    0    level_skill_id_level_skill_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.level_skill_id_level_skill_seq OWNED BY public.level_skill.id_level_skill;
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
       public          postgres    false    252            x           0    0    messages_id_message_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.messages_id_message_seq OWNED BY public.messages.id_message;
          public          postgres    false    253            �            1259    17282    office    TABLE     �   CREATE TABLE public.office (
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
       public          postgres    false    254            y           0    0    office_id_office_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.office_id_office_seq OWNED BY public.office.id_office;
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
       public          postgres    false    256            z           0    0 .   participation_chats_id_participation_chats_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.participation_chats_id_participation_chats_seq OWNED BY public.participation_chats.id_participation_chats;
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
       public          postgres    false    258            {           0    0    position_id_position_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.position_id_position_seq OWNED BY public."position".id_position;
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
       public          postgres    false    260            |           0    0    read_status_id_read_status_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.read_status_id_read_status_seq OWNED BY public.read_status.id_read_status;
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
       public          postgres    false    262            }           0    0    roles_id_role_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.roles_id_role_seq OWNED BY public.roles.id_role;
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
       public          postgres    false    264            ~           0    0    skill_name_id_skill_name_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.skill_name_id_skill_name_seq OWNED BY public.skill_name.id_skill_name;
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
       public          postgres    false    266                       0    0    skill_own_id_skill_own_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.skill_own_id_skill_own_seq OWNED BY public.skill_own.id_skill_own;
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
       public          postgres    false    230    227            �           2604    17325    document title    DEFAULT     p   ALTER TABLE ONLY public.document ALTER COLUMN title SET DEFAULT nextval('public.document_title_seq'::regclass);
 =   ALTER TABLE public.document ALTER COLUMN title DROP DEFAULT;
       public          postgres    false    233    227            �           2604    17326    document_access id_event_access    DEFAULT     �   ALTER TABLE ONLY public.document_access ALTER COLUMN id_event_access SET DEFAULT nextval('public.document_access_id_event_access_seq'::regclass);
 N   ALTER TABLE public.document_access ALTER COLUMN id_event_access DROP DEFAULT;
       public          postgres    false    229    228            �           2604    17327 &   document_template id_document_template    DEFAULT     �   ALTER TABLE ONLY public.document_template ALTER COLUMN id_document_template SET DEFAULT nextval('public.document_template_id_document_template_seq'::regclass);
 U   ALTER TABLE public.document_template ALTER COLUMN id_document_template DROP DEFAULT;
       public          postgres    false    232    231            �           2604    17328    employee id_employee    DEFAULT     |   ALTER TABLE ONLY public.employee ALTER COLUMN id_employee SET DEFAULT nextval('public.employee_id_employee_seq'::regclass);
 C   ALTER TABLE public.employee ALTER COLUMN id_employee DROP DEFAULT;
       public          postgres    false    235    234            �           2604    17329    event_access id_event_access    DEFAULT     �   ALTER TABLE ONLY public.event_access ALTER COLUMN id_event_access SET DEFAULT nextval('public.event_access_id_event_access_seq'::regclass);
 K   ALTER TABLE public.event_access ALTER COLUMN id_event_access DROP DEFAULT;
       public          postgres    false    237    236            �           2604    17330     event_location id_event_location    DEFAULT     �   ALTER TABLE ONLY public.event_location ALTER COLUMN id_event_location SET DEFAULT nextval('public.event_location_id_event_location_seq'::regclass);
 O   ALTER TABLE public.event_location ALTER COLUMN id_event_location DROP DEFAULT;
       public          postgres    false    239    238            �           2604    17331    events id_event    DEFAULT     r   ALTER TABLE ONLY public.events ALTER COLUMN id_event SET DEFAULT nextval('public.events_id_event_seq'::regclass);
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
       public          postgres    false    253    252            �           2604    17338    office id_office    DEFAULT     t   ALTER TABLE ONLY public.office ALTER COLUMN id_office SET DEFAULT nextval('public.office_id_office_seq'::regclass);
 ?   ALTER TABLE public.office ALTER COLUMN id_office DROP DEFAULT;
       public          postgres    false    255    254            �           2604    17339 *   participation_chats id_participation_chats    DEFAULT     �   ALTER TABLE ONLY public.participation_chats ALTER COLUMN id_participation_chats SET DEFAULT nextval('public.participation_chats_id_participation_chats_seq'::regclass);
 Y   ALTER TABLE public.participation_chats ALTER COLUMN id_participation_chats DROP DEFAULT;
       public          postgres    false    257    256            �           2604    17340    position id_position    DEFAULT     ~   ALTER TABLE ONLY public."position" ALTER COLUMN id_position SET DEFAULT nextval('public.position_id_position_seq'::regclass);
 E   ALTER TABLE public."position" ALTER COLUMN id_position DROP DEFAULT;
       public          postgres    false    259    258            �           2604    17341    read_status id_read_status    DEFAULT     �   ALTER TABLE ONLY public.read_status ALTER COLUMN id_read_status SET DEFAULT nextval('public.read_status_id_read_status_seq'::regclass);
 I   ALTER TABLE public.read_status ALTER COLUMN id_read_status DROP DEFAULT;
       public          postgres    false    261    260            �           2604    17342    roles id_role    DEFAULT     n   ALTER TABLE ONLY public.roles ALTER COLUMN id_role SET DEFAULT nextval('public.roles_id_role_seq'::regclass);
 <   ALTER TABLE public.roles ALTER COLUMN id_role DROP DEFAULT;
       public          postgres    false    263    262            �           2604    17343    skill_name id_skill_name    DEFAULT     �   ALTER TABLE ONLY public.skill_name ALTER COLUMN id_skill_name SET DEFAULT nextval('public.skill_name_id_skill_name_seq'::regclass);
 G   ALTER TABLE public.skill_name ALTER COLUMN id_skill_name DROP DEFAULT;
       public          postgres    false    265    264            �           2604    17344    skill_own id_skill_own    DEFAULT     �   ALTER TABLE ONLY public.skill_own ALTER COLUMN id_skill_own SET DEFAULT nextval('public.skill_own_id_skill_own_seq'::regclass);
 E   ALTER TABLE public.skill_own ALTER COLUMN id_skill_own DROP DEFAULT;
       public          postgres    false    267    266            *          0    17175    announcement_access 
   TABLE DATA           c   COPY public.announcement_access (id_announcement_access, id_employee, id_announcement) FROM stdin;
    public          postgres    false    215   Q�      ,          0    17179    announcements 
   TABLE DATA           r   COPY public.announcements (id_announcement, title, discription, creation_date, end_date, id_employee) FROM stdin;
    public          postgres    false    217   ��      .          0    17185    business_card 
   TABLE DATA           l   COPY public.business_card (id_business_card, content, creation_date, id_card_type, id_employee) FROM stdin;
    public          postgres    false    219   :�      0          0    17191    business_center 
   TABLE DATA           F   COPY public.business_center (id_business_center, address) FROM stdin;
    public          postgres    false    221   c�      2          0    17197 	   card_type 
   TABLE DATA           7   COPY public.card_type (id_card_type, type) FROM stdin;
    public          postgres    false    223   ��      4          0    17203 
   department 
   TABLE DATA           v   COPY public.department (id_department, name, open_hours, close_hours, department_phone_number, id_office) FROM stdin;
    public          postgres    false    225   �      6          0    17209    document 
   TABLE DATA           �   COPY public.document (id_document, title, description, path_file, load_date, change_date, file_extention, id_employee, id_document_template) FROM stdin;
    public          postgres    false    227   %�      7          0    17214    document_access 
   TABLE DATA           T   COPY public.document_access (id_event_access, id_document, id_employee) FROM stdin;
    public          postgres    false    228   1�      :          0    17219    document_template 
   TABLE DATA           V   COPY public.document_template (id_document_template, name, path_template) FROM stdin;
    public          postgres    false    231   ��      =          0    17226    employee 
   TABLE DATA           t   COPY public.employee (id_employee, full_name, email, phone_number, employment_date, is_admin, password) FROM stdin;
    public          postgres    false    234   t�      ?          0    17232    event_access 
   TABLE DATA           N   COPY public.event_access (id_event_access, id_event, id_employee) FROM stdin;
    public          postgres    false    236   h�      A          0    17236    event_location 
   TABLE DATA           A   COPY public.event_location (id_event_location, name) FROM stdin;
    public          postgres    false    238   ��      C          0    17242    events 
   TABLE DATA           c   COPY public.events (id_event, name, discription, date, id_event_location, id_employee) FROM stdin;
    public          postgres    false    240   ��      E          0    17248 
   group_chat 
   TABLE DATA           H   COPY public.group_chat (id_group_chat, name, creation_date) FROM stdin;
    public          postgres    false    242   �      G          0    17254    group_messages 
   TABLE DATA           x   COPY public.group_messages (id_group_message, content, id_group_chat, id_sender, send_time, id_read_status) FROM stdin;
    public          postgres    false    244   �      I          0    17260    ip_phone 
   TABLE DATA           =   COPY public.ip_phone (id_phone, internal_number) FROM stdin;
    public          postgres    false    246   ��      K          0    17266 	   job_title 
   TABLE DATA           7   COPY public.job_title (id_job_title, name) FROM stdin;
    public          postgres    false    248   ��      M          0    17272    level_skill 
   TABLE DATA           <   COPY public.level_skill (id_level_skill, level) FROM stdin;
    public          postgres    false    250   ��      O          0    17276    messages 
   TABLE DATA           k   COPY public.messages (id_message, id_sender, content, send_time, id_read_status, id_requester) FROM stdin;
    public          postgres    false    252   �      Q          0    17282    office 
   TABLE DATA           N   COPY public.office (id_office, office_number, id_business_center) FROM stdin;
    public          postgres    false    254   �      S          0    17288    participation_chats 
   TABLE DATA           j   COPY public.participation_chats (id_participation_chats, id_employee, id_role, id_group_chat) FROM stdin;
    public          postgres    false    256   H�      U          0    17292    position 
   TABLE DATA           }   COPY public."position" (id_position, name, appointment_date, id_employee, id_job_title, id_phone, id_department) FROM stdin;
    public          postgres    false    258   ��      W          0    17298    read_status 
   TABLE DATA           =   COPY public.read_status (id_read_status, status) FROM stdin;
    public          postgres    false    260   ��      Y          0    17302    roles 
   TABLE DATA           .   COPY public.roles (id_role, name) FROM stdin;
    public          postgres    false    262   �      [          0    17308 
   skill_name 
   TABLE DATA           9   COPY public.skill_name (id_skill_name, name) FROM stdin;
    public          postgres    false    264   r�      ]          0    17314 	   skill_own 
   TABLE DATA           i   COPY public.skill_own (id_skill_own, last_check, id_level_skill, id_skill_name, id_employee) FROM stdin;
    public          postgres    false    266   ��      �           0    0 .   announcement_access_id_announcement_access_seq    SEQUENCE SET     ]   SELECT pg_catalog.setval('public.announcement_access_id_announcement_access_seq', 18, true);
          public          postgres    false    216            �           0    0 !   announcements_id_announcement_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.announcements_id_announcement_seq', 9, true);
          public          postgres    false    218            �           0    0 "   business_card_id_business_card_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public.business_card_id_business_card_seq', 9, true);
          public          postgres    false    220            �           0    0 &   business_center_id_business_center_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public.business_center_id_business_center_seq', 2, true);
          public          postgres    false    222            �           0    0    card_type_id_card_type_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.card_type_id_card_type_seq', 2, true);
          public          postgres    false    224            �           0    0    department_id_department_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.department_id_department_seq', 9, true);
          public          postgres    false    226            �           0    0 #   document_access_id_event_access_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.document_access_id_event_access_seq', 27, true);
          public          postgres    false    229            �           0    0    document_id_document_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.document_id_document_seq', 9, true);
          public          postgres    false    230            �           0    0 *   document_template_id_document_template_seq    SEQUENCE SET     X   SELECT pg_catalog.setval('public.document_template_id_document_template_seq', 3, true);
          public          postgres    false    232            �           0    0    document_title_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.document_title_seq', 1, false);
          public          postgres    false    233            �           0    0    employee_id_employee_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.employee_id_employee_seq', 13, true);
          public          postgres    false    235            �           0    0     event_access_id_event_access_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.event_access_id_event_access_seq', 81, true);
          public          postgres    false    237            �           0    0 $   event_location_id_event_location_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.event_location_id_event_location_seq', 9, true);
          public          postgres    false    239            �           0    0    events_id_event_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.events_id_event_seq', 9, true);
          public          postgres    false    241            �           0    0    group_chat_id_group_chat_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.group_chat_id_group_chat_seq', 9, true);
          public          postgres    false    243            �           0    0 #   group_messages_id_group_message_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.group_messages_id_group_message_seq', 11, true);
          public          postgres    false    245            �           0    0    ip_phone_id_phone_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.ip_phone_id_phone_seq', 9, true);
          public          postgres    false    247            �           0    0    job_title_id_job_title_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.job_title_id_job_title_seq', 9, true);
          public          postgres    false    249            �           0    0    level_skill_id_level_skill_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.level_skill_id_level_skill_seq', 5, true);
          public          postgres    false    251            �           0    0    messages_id_message_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.messages_id_message_seq', 21, true);
          public          postgres    false    253            �           0    0    office_id_office_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.office_id_office_seq', 9, true);
          public          postgres    false    255            �           0    0 .   participation_chats_id_participation_chats_seq    SEQUENCE SET     ]   SELECT pg_catalog.setval('public.participation_chats_id_participation_chats_seq', 27, true);
          public          postgres    false    257            �           0    0    position_id_position_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.position_id_position_seq', 18, true);
          public          postgres    false    259            �           0    0    read_status_id_read_status_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.read_status_id_read_status_seq', 2, true);
          public          postgres    false    261            �           0    0    roles_id_role_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.roles_id_role_seq', 3, true);
          public          postgres    false    263            �           0    0    skill_name_id_skill_name_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.skill_name_id_skill_name_seq', 9, true);
          public          postgres    false    265            �           0    0    skill_own_id_skill_own_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.skill_own_id_skill_own_seq', 9, true);
          public          postgres    false    267            �           2606    17346 *   announcement_access PK_announcement_access 
   CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT "PK_announcement_access" PRIMARY KEY (id_announcement_access, id_employee, id_announcement);
 V   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT "PK_announcement_access";
       public            postgres    false    215    215    215            �           2606    17348    announcements PK_announcements 
   CONSTRAINT     k   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT "PK_announcements" PRIMARY KEY (id_announcement);
 J   ALTER TABLE ONLY public.announcements DROP CONSTRAINT "PK_announcements";
       public            postgres    false    217                       2606    17350    business_card PK_business_card 
   CONSTRAINT     l   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT "PK_business_card" PRIMARY KEY (id_business_card);
 J   ALTER TABLE ONLY public.business_card DROP CONSTRAINT "PK_business_card";
       public            postgres    false    219                       2606    17352 "   business_center PK_business_center 
   CONSTRAINT     r   ALTER TABLE ONLY public.business_center
    ADD CONSTRAINT "PK_business_center" PRIMARY KEY (id_business_center);
 N   ALTER TABLE ONLY public.business_center DROP CONSTRAINT "PK_business_center";
       public            postgres    false    221                       2606    17354    card_type PK_card_type 
   CONSTRAINT     `   ALTER TABLE ONLY public.card_type
    ADD CONSTRAINT "PK_card_type" PRIMARY KEY (id_card_type);
 B   ALTER TABLE ONLY public.card_type DROP CONSTRAINT "PK_card_type";
       public            postgres    false    223                       2606    17356    department PK_department 
   CONSTRAINT     c   ALTER TABLE ONLY public.department
    ADD CONSTRAINT "PK_department" PRIMARY KEY (id_department);
 D   ALTER TABLE ONLY public.department DROP CONSTRAINT "PK_department";
       public            postgres    false    225            	           2606    17358    document PK_document 
   CONSTRAINT     ]   ALTER TABLE ONLY public.document
    ADD CONSTRAINT "PK_document" PRIMARY KEY (id_document);
 @   ALTER TABLE ONLY public.document DROP CONSTRAINT "PK_document";
       public            postgres    false    227                       2606    17360 "   document_access PK_document_access 
   CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT "PK_document_access" PRIMARY KEY (id_event_access, id_document, id_employee);
 N   ALTER TABLE ONLY public.document_access DROP CONSTRAINT "PK_document_access";
       public            postgres    false    228    228    228                       2606    17362 &   document_template PK_document_template 
   CONSTRAINT     x   ALTER TABLE ONLY public.document_template
    ADD CONSTRAINT "PK_document_template" PRIMARY KEY (id_document_template);
 R   ALTER TABLE ONLY public.document_template DROP CONSTRAINT "PK_document_template";
       public            postgres    false    231                       2606    17364    employee PK_employee 
   CONSTRAINT     ]   ALTER TABLE ONLY public.employee
    ADD CONSTRAINT "PK_employee" PRIMARY KEY (id_employee);
 @   ALTER TABLE ONLY public.employee DROP CONSTRAINT "PK_employee";
       public            postgres    false    234                       2606    17366    event_access PK_event_access 
   CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT "PK_event_access" PRIMARY KEY (id_event_access, id_event, id_employee);
 H   ALTER TABLE ONLY public.event_access DROP CONSTRAINT "PK_event_access";
       public            postgres    false    236    236    236                       2606    17368     event_location PK_event_location 
   CONSTRAINT     o   ALTER TABLE ONLY public.event_location
    ADD CONSTRAINT "PK_event_location" PRIMARY KEY (id_event_location);
 L   ALTER TABLE ONLY public.event_location DROP CONSTRAINT "PK_event_location";
       public            postgres    false    238                       2606    17370    events PK_events 
   CONSTRAINT     V   ALTER TABLE ONLY public.events
    ADD CONSTRAINT "PK_events" PRIMARY KEY (id_event);
 <   ALTER TABLE ONLY public.events DROP CONSTRAINT "PK_events";
       public            postgres    false    240                       2606    17372    group_chat PK_group_chat 
   CONSTRAINT     c   ALTER TABLE ONLY public.group_chat
    ADD CONSTRAINT "PK_group_chat" PRIMARY KEY (id_group_chat);
 D   ALTER TABLE ONLY public.group_chat DROP CONSTRAINT "PK_group_chat";
       public            postgres    false    242                       2606    17374     group_messages PK_group_messages 
   CONSTRAINT     }   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT "PK_group_messages" PRIMARY KEY (id_group_message, id_group_chat);
 L   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT "PK_group_messages";
       public            postgres    false    244    244                       2606    17376    ip_phone PK_ip_phone 
   CONSTRAINT     Z   ALTER TABLE ONLY public.ip_phone
    ADD CONSTRAINT "PK_ip_phone" PRIMARY KEY (id_phone);
 @   ALTER TABLE ONLY public.ip_phone DROP CONSTRAINT "PK_ip_phone";
       public            postgres    false    246                       2606    17378    job_title PK_job_title 
   CONSTRAINT     `   ALTER TABLE ONLY public.job_title
    ADD CONSTRAINT "PK_job_title" PRIMARY KEY (id_job_title);
 B   ALTER TABLE ONLY public.job_title DROP CONSTRAINT "PK_job_title";
       public            postgres    false    248                       2606    17380    level_skill PK_level_skill 
   CONSTRAINT     f   ALTER TABLE ONLY public.level_skill
    ADD CONSTRAINT "PK_level_skill" PRIMARY KEY (id_level_skill);
 F   ALTER TABLE ONLY public.level_skill DROP CONSTRAINT "PK_level_skill";
       public            postgres    false    250            !           2606    17382    messages PK_messages 
   CONSTRAINT     g   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT "PK_messages" PRIMARY KEY (id_message, id_sender);
 @   ALTER TABLE ONLY public.messages DROP CONSTRAINT "PK_messages";
       public            postgres    false    252    252            #           2606    17384    office PK_office 
   CONSTRAINT     W   ALTER TABLE ONLY public.office
    ADD CONSTRAINT "PK_office" PRIMARY KEY (id_office);
 <   ALTER TABLE ONLY public.office DROP CONSTRAINT "PK_office";
       public            postgres    false    254            %           2606    17386 *   participation_chats PK_participation_chats 
   CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT "PK_participation_chats" PRIMARY KEY (id_participation_chats, id_employee, id_group_chat);
 V   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT "PK_participation_chats";
       public            postgres    false    256    256    256            '           2606    17388    position PK_position 
   CONSTRAINT     _   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT "PK_position" PRIMARY KEY (id_position);
 B   ALTER TABLE ONLY public."position" DROP CONSTRAINT "PK_position";
       public            postgres    false    258            )           2606    17390    read_status PK_read_status 
   CONSTRAINT     f   ALTER TABLE ONLY public.read_status
    ADD CONSTRAINT "PK_read_status" PRIMARY KEY (id_read_status);
 F   ALTER TABLE ONLY public.read_status DROP CONSTRAINT "PK_read_status";
       public            postgres    false    260            +           2606    17392    roles PK_roles 
   CONSTRAINT     S   ALTER TABLE ONLY public.roles
    ADD CONSTRAINT "PK_roles" PRIMARY KEY (id_role);
 :   ALTER TABLE ONLY public.roles DROP CONSTRAINT "PK_roles";
       public            postgres    false    262            -           2606    17394    skill_name PK_skill_name 
   CONSTRAINT     c   ALTER TABLE ONLY public.skill_name
    ADD CONSTRAINT "PK_skill_name" PRIMARY KEY (id_skill_name);
 D   ALTER TABLE ONLY public.skill_name DROP CONSTRAINT "PK_skill_name";
       public            postgres    false    264            /           2606    17396    skill_own PK_skill_own 
   CONSTRAINT     m   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT "PK_skill_own" PRIMARY KEY (id_skill_own, id_employee);
 B   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT "PK_skill_own";
       public            postgres    false    266    266            �           2620    17397 #   messages trigger_notify_new_message    TRIGGER     �   CREATE TRIGGER trigger_notify_new_message AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.notify_new_message();
 <   DROP TRIGGER trigger_notify_new_message ON public.messages;
       public          postgres    false    252    270            0           2606    17398 <   announcement_access announcement_access_id_announcement_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 f   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey;
       public          postgres    false    215    4863    217            1           2606    17403 =   announcement_access announcement_access_id_announcement_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey1 FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 g   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey1;
       public          postgres    false    217    4863    215            2           2606    17408 =   announcement_access announcement_access_id_announcement_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey2 FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 g   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey2;
       public          postgres    false    217    215    4863            3           2606    17413 =   announcement_access announcement_access_id_announcement_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_announcement_fkey3 FOREIGN KEY (id_announcement) REFERENCES public.announcements(id_announcement) ON UPDATE CASCADE ON DELETE CASCADE;
 g   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_announcement_fkey3;
       public          postgres    false    215    4863    217            4           2606    17418 8   announcement_access announcement_access_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 b   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey;
       public          postgres    false    234    4879    215            5           2606    17423 9   announcement_access announcement_access_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey1;
       public          postgres    false    215    234    4879            6           2606    17428 9   announcement_access announcement_access_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey2;
       public          postgres    false    234    4879    215            7           2606    17433 9   announcement_access announcement_access_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcement_access
    ADD CONSTRAINT announcement_access_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.announcement_access DROP CONSTRAINT announcement_access_id_employee_fkey3;
       public          postgres    false    215    4879    234            8           2606    17438 ,   announcements announcements_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey;
       public          postgres    false    217    4879    234            9           2606    17443 -   announcements announcements_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey1;
       public          postgres    false    4879    217    234            :           2606    17448 -   announcements announcements_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey2;
       public          postgres    false    4879    234    217            ;           2606    17453 -   announcements announcements_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.announcements DROP CONSTRAINT announcements_id_employee_fkey3;
       public          postgres    false    4879    234    217            <           2606    17458 -   business_card business_card_id_card_type_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey;
       public          postgres    false    219    4869    223            =           2606    17463 .   business_card business_card_id_card_type_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey1 FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 X   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey1;
       public          postgres    false    4869    219    223            >           2606    17468 .   business_card business_card_id_card_type_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey2 FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 X   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey2;
       public          postgres    false    219    223    4869            ?           2606    17473 .   business_card business_card_id_card_type_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_card_type_fkey3 FOREIGN KEY (id_card_type) REFERENCES public.card_type(id_card_type) ON UPDATE CASCADE ON DELETE RESTRICT;
 X   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_card_type_fkey3;
       public          postgres    false    219    223    4869            @           2606    17478 ,   business_card business_card_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey;
       public          postgres    false    4879    219    234            A           2606    17483 -   business_card business_card_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey1;
       public          postgres    false    219    234    4879            B           2606    17488 -   business_card business_card_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey2;
       public          postgres    false    4879    234    219            C           2606    17493 -   business_card business_card_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.business_card
    ADD CONSTRAINT business_card_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 W   ALTER TABLE ONLY public.business_card DROP CONSTRAINT business_card_id_employee_fkey3;
       public          postgres    false    219    234    4879            D           2606    17498 $   department department_id_office_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey;
       public          postgres    false    225    254    4899            E           2606    17503 %   department department_id_office_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey1 FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey1;
       public          postgres    false    225    254    4899            F           2606    17508 %   department department_id_office_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey2 FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey2;
       public          postgres    false    225    4899    254            G           2606    17513 %   department department_id_office_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_id_office_fkey3 FOREIGN KEY (id_office) REFERENCES public.office(id_office) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.department DROP CONSTRAINT department_id_office_fkey3;
       public          postgres    false    225    4899    254            P           2606    17518 0   document_access document_access_id_document_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey;
       public          postgres    false    4873    228    227            Q           2606    17523 1   document_access document_access_id_document_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey1 FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey1;
       public          postgres    false    228    4873    227            R           2606    17528 1   document_access document_access_id_document_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey2 FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey2;
       public          postgres    false    4873    228    227            S           2606    17533 1   document_access document_access_id_document_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_document_fkey3 FOREIGN KEY (id_document) REFERENCES public.document(id_document) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_document_fkey3;
       public          postgres    false    4873    228    227            T           2606    17538 0   document_access document_access_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey;
       public          postgres    false    234    228    4879            U           2606    17543 1   document_access document_access_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey1;
       public          postgres    false    234    228    4879            V           2606    17548 1   document_access document_access_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey2;
       public          postgres    false    4879    228    234            W           2606    17553 1   document_access document_access_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document_access
    ADD CONSTRAINT document_access_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.document_access DROP CONSTRAINT document_access_id_employee_fkey3;
       public          postgres    false    4879    228    234            H           2606    17558 +   document document_id_document_template_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 U   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey;
       public          postgres    false    231    227    4877            I           2606    17564 ,   document document_id_document_template_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey1 FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey1;
       public          postgres    false    231    227    4877            J           2606    17569 ,   document document_id_document_template_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey2 FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey2;
       public          postgres    false    227    4877    231            K           2606    17574 ,   document document_id_document_template_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_template_fkey3 FOREIGN KEY (id_document_template) REFERENCES public.document_template(id_document_template) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_document_template_fkey3;
       public          postgres    false    4877    231    227            L           2606    17579 "   document document_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 L   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey;
       public          postgres    false    4879    234    227            M           2606    17584 #   document document_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey1;
       public          postgres    false    4879    227    234            N           2606    17589 #   document document_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey2;
       public          postgres    false    234    227    4879            O           2606    17594 #   document document_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.document DROP CONSTRAINT document_id_employee_fkey3;
       public          postgres    false    234    4879    227            X           2606    17599 *   event_access event_access_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 T   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey;
       public          postgres    false    4879    236    234            Y           2606    17604 +   event_access event_access_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey1;
       public          postgres    false    236    234    4879            Z           2606    17609 +   event_access event_access_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey2;
       public          postgres    false    4879    236    234            [           2606    17614 +   event_access event_access_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_employee_fkey3;
       public          postgres    false    234    4879    236            \           2606    17619 '   event_access event_access_id_event_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 Q   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey;
       public          postgres    false    4885    236    240            ]           2606    17624 (   event_access event_access_id_event_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey1 FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey1;
       public          postgres    false    236    4885    240            ^           2606    17629 (   event_access event_access_id_event_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey2 FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey2;
       public          postgres    false    236    4885    240            _           2606    17634 (   event_access event_access_id_event_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.event_access
    ADD CONSTRAINT event_access_id_event_fkey3 FOREIGN KEY (id_event) REFERENCES public.events(id_event) ON UPDATE CASCADE ON DELETE CASCADE;
 R   ALTER TABLE ONLY public.event_access DROP CONSTRAINT event_access_id_event_fkey3;
       public          postgres    false    4885    236    240            `           2606    17639    events events_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 H   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey;
       public          postgres    false    240    4879    234            a           2606    17644    events events_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 I   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey1;
       public          postgres    false    234    4879    240            b           2606    17649    events events_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 I   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey2;
       public          postgres    false    240    4879    234            c           2606    17654    events events_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 I   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_employee_fkey3;
       public          postgres    false    240    234    4879            d           2606    17659 $   events events_id_event_location_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey;
       public          postgres    false    4883    240    238            e           2606    17664 %   events events_id_event_location_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey1 FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey1;
       public          postgres    false    240    4883    238            f           2606    17669 %   events events_id_event_location_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey2 FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey2;
       public          postgres    false    238    240    4883            g           2606    17674 %   events events_id_event_location_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_event_location_fkey3 FOREIGN KEY (id_event_location) REFERENCES public.event_location(id_event_location) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.events DROP CONSTRAINT events_id_event_location_fkey3;
       public          postgres    false    240    238    4883            h           2606    17679 0   group_messages group_messages_id_group_chat_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey;
       public          postgres    false    4887    242    244            i           2606    17684 1   group_messages group_messages_id_group_chat_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey1 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey1;
       public          postgres    false    244    242    4887            j           2606    17689 1   group_messages group_messages_id_group_chat_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey2 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey2;
       public          postgres    false    242    4887    244            k           2606    17694 1   group_messages group_messages_id_group_chat_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_group_chat_fkey3 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_group_chat_fkey3;
       public          postgres    false    4887    242    244            l           2606    17950 1   group_messages group_messages_id_read_status_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_read_status_fkey FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status);
 [   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_read_status_fkey;
       public          postgres    false    244    260    4905            m           2606    17943 ,   group_messages group_messages_id_sender_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.group_messages
    ADD CONSTRAINT group_messages_id_sender_fkey FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON DELETE CASCADE;
 V   ALTER TABLE ONLY public.group_messages DROP CONSTRAINT group_messages_id_sender_fkey;
       public          postgres    false    234    4879    244            n           2606    17699 %   messages messages_id_read_status_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey;
       public          postgres    false    260    4905    252            o           2606    17704 &   messages messages_id_read_status_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey1 FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey1;
       public          postgres    false    4905    252    260            p           2606    17709 &   messages messages_id_read_status_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey2 FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey2;
       public          postgres    false    252    4905    260            q           2606    17714 &   messages messages_id_read_status_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_read_status_fkey3 FOREIGN KEY (id_read_status) REFERENCES public.read_status(id_read_status) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_read_status_fkey3;
       public          postgres    false    4905    260    252            r           2606    17719 #   messages messages_id_requester_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey;
       public          postgres    false    234    252    4879            s           2606    17724 $   messages messages_id_requester_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey1 FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey1;
       public          postgres    false    252    234    4879            t           2606    17729 $   messages messages_id_requester_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey2 FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey2;
       public          postgres    false    4879    234    252            u           2606    17734 $   messages messages_id_requester_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_requester_fkey3 FOREIGN KEY (id_requester) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_requester_fkey3;
       public          postgres    false    234    252    4879            v           2606    17739     messages messages_id_sender_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 J   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey;
       public          postgres    false    4879    252    234            w           2606    17744 !   messages messages_id_sender_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey1 FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey1;
       public          postgres    false    234    252    4879            x           2606    17749 !   messages messages_id_sender_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey2 FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey2;
       public          postgres    false    234    252    4879            y           2606    17754 !   messages messages_id_sender_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_id_sender_fkey3 FOREIGN KEY (id_sender) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 K   ALTER TABLE ONLY public.messages DROP CONSTRAINT messages_id_sender_fkey3;
       public          postgres    false    252    234    4879            z           2606    17759 %   office office_id_business_center_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey;
       public          postgres    false    221    254    4867            {           2606    17764 &   office office_id_business_center_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey1 FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey1;
       public          postgres    false    4867    221    254            |           2606    17769 &   office office_id_business_center_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey2 FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey2;
       public          postgres    false    221    4867    254            }           2606    17774 &   office office_id_business_center_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_id_business_center_fkey3 FOREIGN KEY (id_business_center) REFERENCES public.business_center(id_business_center) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.office DROP CONSTRAINT office_id_business_center_fkey3;
       public          postgres    false    4867    254    221            ~           2606    17779 8   participation_chats participation_chats_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 b   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey;
       public          postgres    false    234    256    4879                       2606    17784 9   participation_chats participation_chats_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey1;
       public          postgres    false    234    4879    256            �           2606    17789 9   participation_chats participation_chats_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey2;
       public          postgres    false    4879    234    256            �           2606    17794 9   participation_chats participation_chats_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 c   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_employee_fkey3;
       public          postgres    false    256    4879    234            �           2606    17799 :   participation_chats participation_chats_id_group_chat_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 d   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey;
       public          postgres    false    4887    242    256            �           2606    17804 ;   participation_chats participation_chats_id_group_chat_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey1 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 e   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey1;
       public          postgres    false    4887    256    242            �           2606    17809 ;   participation_chats participation_chats_id_group_chat_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey2 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 e   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey2;
       public          postgres    false    242    4887    256            �           2606    17814 ;   participation_chats participation_chats_id_group_chat_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_group_chat_fkey3 FOREIGN KEY (id_group_chat) REFERENCES public.group_chat(id_group_chat) ON UPDATE CASCADE ON DELETE CASCADE;
 e   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_group_chat_fkey3;
       public          postgres    false    4887    256    242            �           2606    17819 4   participation_chats participation_chats_id_role_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 ^   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey;
       public          postgres    false    256    4907    262            �           2606    17824 5   participation_chats participation_chats_id_role_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey1 FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 _   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey1;
       public          postgres    false    256    4907    262            �           2606    17829 5   participation_chats participation_chats_id_role_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey2 FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 _   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey2;
       public          postgres    false    256    262    4907            �           2606    17834 5   participation_chats participation_chats_id_role_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.participation_chats
    ADD CONSTRAINT participation_chats_id_role_fkey3 FOREIGN KEY (id_role) REFERENCES public.roles(id_role) ON UPDATE CASCADE ON DELETE RESTRICT;
 _   ALTER TABLE ONLY public.participation_chats DROP CONSTRAINT participation_chats_id_role_fkey3;
       public          postgres    false    256    262    4907            �           2606    17839 $   position position_id_department_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_department_fkey FOREIGN KEY (id_department) REFERENCES public.department(id_department) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_department_fkey;
       public          postgres    false    258    225    4871            �           2606    17844 "   position position_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE RESTRICT;
 N   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_employee_fkey;
       public          postgres    false    234    4879    258            �           2606    17849 #   position position_id_job_title_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_job_title_fkey FOREIGN KEY (id_job_title) REFERENCES public.job_title(id_job_title) ON UPDATE CASCADE ON DELETE RESTRICT;
 O   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_job_title_fkey;
       public          postgres    false    258    248    4893            �           2606    17854    position position_id_phone_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_id_phone_fkey FOREIGN KEY (id_phone) REFERENCES public.ip_phone(id_phone) ON UPDATE CASCADE ON DELETE RESTRICT;
 K   ALTER TABLE ONLY public."position" DROP CONSTRAINT position_id_phone_fkey;
       public          postgres    false    4891    246    258            �           2606    17859 $   skill_own skill_own_id_employee_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey;
       public          postgres    false    4879    266    234            �           2606    17864 %   skill_own skill_own_id_employee_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey1 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey1;
       public          postgres    false    234    4879    266            �           2606    17869 %   skill_own skill_own_id_employee_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey2 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey2;
       public          postgres    false    266    234    4879            �           2606    17874 %   skill_own skill_own_id_employee_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_employee_fkey3 FOREIGN KEY (id_employee) REFERENCES public.employee(id_employee) ON UPDATE CASCADE ON DELETE CASCADE;
 O   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_employee_fkey3;
       public          postgres    false    234    4879    266            �           2606    17879 '   skill_own skill_own_id_level_skill_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey;
       public          postgres    false    4895    266    250            �           2606    17884 (   skill_own skill_own_id_level_skill_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey1 FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 R   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey1;
       public          postgres    false    250    266    4895            �           2606    17889 (   skill_own skill_own_id_level_skill_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey2 FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 R   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey2;
       public          postgres    false    266    250    4895            �           2606    17894 (   skill_own skill_own_id_level_skill_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_level_skill_fkey3 FOREIGN KEY (id_level_skill) REFERENCES public.level_skill(id_level_skill) ON UPDATE CASCADE ON DELETE RESTRICT;
 R   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_level_skill_fkey3;
       public          postgres    false    4895    266    250            �           2606    17899 &   skill_own skill_own_id_skill_name_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 P   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey;
       public          postgres    false    4909    266    264            �           2606    17904 '   skill_own skill_own_id_skill_name_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey1 FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey1;
       public          postgres    false    264    4909    266            �           2606    17909 '   skill_own skill_own_id_skill_name_fkey2    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey2 FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey2;
       public          postgres    false    266    264    4909            �           2606    17914 '   skill_own skill_own_id_skill_name_fkey3    FK CONSTRAINT     �   ALTER TABLE ONLY public.skill_own
    ADD CONSTRAINT skill_own_id_skill_name_fkey3 FOREIGN KEY (id_skill_name) REFERENCES public.skill_name(id_skill_name) ON UPDATE CASCADE ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY public.skill_own DROP CONSTRAINT skill_own_id_skill_name_fkey3;
       public          postgres    false    266    4909    264            *   L   x�˱�0�������%���s ��JQ����4\*l5nmM|�`n�儏F*�/i�v679������Gd      ,   }  x��T�n�P]�����v�>�T�Y�`�AWH	���R
JՈl��(�/p�������?��\�X�u|gΜ9s����RL[{n��*����2��5��F+���~�
��G���pX�P�/�����!���)��q�ة�:P���?���5�|��@�--k�rK�&@ �t*�� "����7�h9�}��(�بa������~��+y�h�q���O��H�7Qe+Ϙ+"��3�w�b�Zn��g��O8uC+)w�U+�P�J�fM�PL6������x "�$}���+�$�hIw����g}����-�~�PA�Lq%'��r�E԰�E�oE��Mw�����Dтc�#)|������0i]�K9�y�7��ӯ��P{�4*",E��9}���ٛW��%5�=fڎ��P�O!�Q���k�ޜ[�T��^5�H��y-�P�[�bKlqH֓u��
�'��1���Al���+��Lo!HEc�C��<�V�́3E~=w����zFN�Y�.�ײ����X9�J������W���SYxhs�Ư1�[g[.Ņ���n�}`�^
��5_��'��/������ٯ�X!�ݑ��k7�k���5��:�bН��y0��Bx�X?j�� ��Y�      .     x����N1���)��.I�FBlf��J��� #Oמ��{���J�HV�ı��?���7��&-x�1���c�k�^�.N��&��ɍM3����;���0���:oKg��+�GW׷
����SP0��Og���/��^�W�T������y���?�-��W�����"e�"=�E��"A]n��I�vo�?���/*�ME}��8�;��7)o�4P����Qg�4;��FP��H�����eH#���b4d<#u��1�t�و.���#�n      0   P   x�3�0�¾��v]�ta�������.̾����;�(va���!�v��.l��pa��
@isP	L�W� ��7�      2   K   x�3估��֋��^�q��j�����
6]�qa;P�	$�e�ya��=�5m����6����=... �3�      4   �   x����N�0�继�B��Ď��lH�]ّ��i����P�m���+�y#�C3��l�w���wgE��h���h��zI��)w�<�E������̭*ʉ6�ʒ���_4٣���;4iLM��j��B�N�G��3)��0P��x�=��ri'G%둓xD�kQ6'�f��)"ZA|��W���iGBZTP�v��mp��ü/�4[���r�����j���a�"��*�.���69�O�����      6   �  x�u�In�@E��S��9���`Ȗ��"��Ӑi��.+g8#��"E��o��-J$d!��ը����"��'W��y#? Z�Ky��{~�\�_�x/�X|�-H<�#���
;�rE�ad��4y)���E���Jw��6m�².L�Z.�E�a�M���x�G�W��<s.��,���q�{A��-���txH�m8�GO[ ����:[�𹓟�R���ojR��ԛ�q�G],\�z��:�5I��գ�W�@���O�4�D7��U�~��6��܏"滛����m�~��c���ʷJ�*�ܕ�&V�wT�>^O�%�H[���B��0�O}Uy��c��E�����X�6�K�E�{��%i޽����V�ʂ*��CՀj�Po�f������V�?��P[��`(���r1�U1I�T�yvvC�)t�Z� ʆ4$H�)BGw =pYNE$�Lx�ȏ�+���!D�hD�E~���}P�z#���7��ę s؄�Z���u��	ʛ�      7   h   x�͹QQ�Q-�ssQ�q���μ�(��փ�����������^���<���� 3���d96[�C�s	���}Hݐ�V^��;�v��uQ������v��      :   �   x�]OK�P[�N�N�Q�cB`\�ĥh�,L���'BD�B�F��QXL�����^g\P�J��lQ��=Q��w���!<��⑑
�n��ĉ�9�;���kG�R�[	ە�ȡ֢�I㥉rY����6=B���G�HZ�+f�#��L&Ma4ޤ�)^�L�%��_z1�gv��g��`h)�>X*�$      =   �  x�u��n�@��'O�=��3��x�(+���'�b7��� ���@Bܪ��[�&\^���8g29Q�����7�	���ş����|R��|<-��A5�;i�eY ��HP�
E(�����@~�M��a�9.�Ew�4laj�Y5���J)�"��D�
�#ԀD9%�o���+��*��b��Qk���(E��4��5��W�"׷t�.X~�|�y]�'��8�"N�+H����9Ʌ�����~��,���zt�tb���;�cN�3�wU$����l/��l|�u5��=�&I�I�\#���'��_HqjY��N;�i5�LӔ�2�E������"��{E���U���8�QQ�rO����󏄌<3�Eo�v0R�D�K�5�	J{�>���>�o���.�p���������]u/`R�����]&F<tjr�牢â~����_�P���?������{v�@c�����cr��خ���`0�/�p�      ?   i   x����@�b��S��zq�u� 	�Qm<�U����������Q+NP9LI24i�h:�*K�,�t��M^*�W��ɫ�rM�oB�M6j�?�~��      A      x�}�=N�@��S��)!���S!��r�$�Q"*$
@��Q,op���F�]�h�g��o�o���h|���:�QS���tz'�Ѳ^�^�U$���X*g��ɹ�;��ݡ�=<Q��#��~v؆S�=��R�u�̕>�S�E��5��\�����RXPF��g���� Kv�� Y�gO�+��N�#��b�C�.�f�\�?%�˵����e���9�>8�N�22�8�c����Ӱ�x{]�홈|�z��      C     x�}T;n�@�gO��A.E}zw)rW	XH;IMɰC��?e�#��fo�7C�YK�~vwf�g���?q������[n�ћ�����>�op��FPiuy�E�a����O��3��3lH�J���\r��8��F�ㅟ"�w��*l�+?��'K�6\o�'�3�9�Wxނ��B|D��Uy�DS-�!�_��U�J(|��\��b�$��Ɩ՝),�hC�\����/���MF���X��w��[D���{���y�h���
	_��m��R�m��~k\D���p�Xn}���AK~�N�;���&�u�~�NБ1���!�P����g�_d'��w�郣N�Q����S����,Xx�r4��aؕd�=+�i�_��R������M�,�~J�^� <��f���Y�;�w�K���E� 7PT��zX�7Y�F�8��͍$kD��E�Ҙf�͙��?�b��=������^-�jϞV9"9��&�)v4!g��1��j      E   �   x��Q1N�0�����l� WBEMMC�DAA�(��!N���`�H��16(*9�wgf�c���_�����4�����0�Gt��WW�TƊSxe�E�Vg�K�
���U��Za�����i�����ᥕg0�yZ�'5r8���N$|�{���`��FaU��=e��>a����ۻ���B�G�Rή��g�X�螫�Mѵ�n"��KX#'�ʦ=�4��&�������5�,k#�"��h�K      G   �  x���=N�@���)��D޵�tp�H�q�."Q"W�$6	N�\a�F�Y�@�HȒv<߼73J����N�J���5U�-la%�� b�Tⱱ3il�pcs��ç����i���B�Ҿ{J��P�A��4�}�DA ���m!��T�c�@Z�;?%�W�@gn3h�����2��w���E�Υ����6�A����O���KX�Ќ}r�;l�b��,��=B�������v���_^ߏ�;�1��VNшD�I���]c82�yҖ������	rrz�j�+q��s@$Bwb���c�6$?�g���ّ}�*�~$~ę�W����o�N}���q� �iA���r�t�+Z����3���{OK2��H�b,H.�X�5�E�;��s��n��kڻ�{��,k�s      I   2   x�Ź  ��-��6�B�u0�D6l-Õ*H�l�)U�j�:\uy�`{
'      K   �   x�}�MA��ݧ���VDbe5���0+	�X�ID���pd��3�
�n��͖EWR����:#���`�z6)�p3���<Z"�CfE����r��Κ���]�+�)�8 �9y<z!�5�{#~O<�.�T��1.�2BQ`�͂�SIYx"��i&e��
�}�������R�0ۓ���NV��H;-��!nrO��NI)?i�G      M   !   x�3�4�2�4�2�4�2�4�2�4����� '�      O   �  x�mSKN�@]w���w�����;�a��`F���r��b�8!ǉ��nī�q��i��U�zU�P�_*�SNk^ҖW��FCk��n��W�o��|b5���P���(��r��֍kl0�QNY�Hы� 4-���8T��@R�W����F�B5|�b+*���*Ա���+"!�FE��=�R@������_r
(HyyuDv�F=r��(�w�}��M�9��Nɇ`g����/'�w&�S5U���[RT^Ï�<��߾�oA"�w���Y��X\��&���N�T_�KEO�"���N�t�{ax��8Q��}�Z��GƺޠD�Ԭ�~�_���֘V�u?tƓl=���V�0�Ɔ=�L�@�\Ё�vL-��HR,�"�)v�Yd�"�Qs�L|��G!B����^TY��^��C�!Ⱦ:�L���P�����R�8�������>�{Źk��|LT{��K�ٍ ��o�ω��zM��      Q   0   x�Ź  ��:�#����s�B���Is�]��r�]��+���
�      S   r   x���1�3�j s���؞�Xz��*�Iu4{��4c~?Z��;����֍��h(�QP�ƚ��h����q p�@G:
��1 ��c^�?I�*�      U     x����J�@��٧���d�\oa'X����]@ED��F���wO_a���wr���$d�3��͈'}LuH��u���黽�uLm��^7|��B[9��t��;�}�)��h��t���Q1���"�z�sO��qR��i[�r�O<���O�)8)I�OK�C]��8+r�]e��3�-�4M��> ({����t�g�T�J'�pZ�7:�Q��B���,5M�>�SQ�Mg@����,�`��Ԙj2}Ư)n+�����s�S���      W      x�3�,�2�L����� &      Y   M   x�3�0�{.츰����.6\�p��¾�
���\F��9@y���rƜ�\�4c+B'W� �N8X      [   Y   x�3��J,KN.�,(�2��,����2�r�p�p�r:+s�qz����;s�s��'g�qYpz�&�奖�sYr:�s��qqq Մ*      ]   Y   x�E���0���K�@BBv��sԑ�"�8��_�.k�^���^�'E����ɛ:��,�&&W�XX̢�c"�?:����&�Q��     