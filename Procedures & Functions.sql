CREATE OR REPLACE PROCEDURE CreateUser (in_name IN VARCHAR2, in_email IN VARCHAR2, in_role IN VARCHAR2, in_password  IN VARCHAR2) AS
    v_user_id NUMBER;
    v_salt    RAW(32);
    v_hash    RAW(64);
BEGIN
    SELECT user_id_seq.NEXTVAL INTO v_user_id FROM dual;

    v_salt := DBMS_CRYPTO.RANDOMBYTES(32);
    v_hash := DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(in_password, 'AL32UTF8') || v_salt, DBMS_CRYPTO.HASH_SH512);

    INSERT INTO Users1 (user_id, full_name, email, user_role, pass, pass_salt) VALUES (v_user_id, in_name, in_email, in_role, v_hash, v_salt);
    
END;
/

CREATE OR REPLACE PROCEDURE UpdateUser (in_id IN NUMBER, new_name IN VARCHAR2, new_email IN VARCHAR2, new_role IN VARCHAR2) AS

    v_name   Users1.full_name%TYPE;
    v_mail  Users1.email%TYPE;
    v_role   Users1.user_role%TYPE;

BEGIN
    BEGIN 
        SELECT  full_name, email, user_role INTO v_name, v_mail, v_role FROM Users1 where user_id = in_id;
        EXCEPTION WHEN NO_DATA_FOUND THEN 
            DBMS_OUTPUT.PUT_LINE('No user with the given id found');
            RETURN; 
    END;

    IF new_name IS NOT NULL THEN 
        new_name := v_name;
    END IF;
    
    IF new_email IS NOT NULL THEN 
        new_email := v_mail;
    END IF;
    
    IF new_role IS NOT NULL THEN 
        new_role := v_role;
    END IF;

    UPDATE Users1 SET full_name = new_name, email = new_email, user_role = new_role WHERE user_id = in_id;
END;
/


CREATE OR REPLACE PROCEDURE DeleteUser (in_id IN NUMBER) AS

BEGIN
    IF EXISTS (SELECT 1 FROM Users1 where user_id = in_id) THEN 
        DELETE FROM Users1 where user_id = in_id;
    END IF;  
END;
/

CREATE OR REPLACE PROCEDURE ShowUsers () AS 

BEGIN 
    SELECT * FROM Users1;
END;
/

CREATE OR REPLACE PROCEDURE FindUser (in_id IN NUMBER) AS 

BEGIN 
    SELECT 1 FROM Users1 where user_id = in_id;
END;
/

-- CREATE
CREATE OR REPLACE PROCEDURE create_lab (
    p_labname IN VARCHAR2,
    p_capacity IN NUMBER,
    p_availability IN VARCHAR2
) IS
BEGIN
    INSERT INTO Labs(lab_id, labname, lab_capacity, availability_status)
    VALUES (lab_id_seq.NEXTVAL, p_labname, p_capacity, p_availability);
END;
/

-- READ
CREATE OR REPLACE PROCEDURE get_lab (
    p_lab_id IN NUMBER,
    p_labname OUT VARCHAR2,
    p_capacity OUT NUMBER,
    p_availability OUT VARCHAR2
) IS
BEGIN
    SELECT labname, lab_capacity, availability_status
    INTO p_labname, p_capacity, p_availability
    FROM Labs
    WHERE lab_id = p_lab_id;
END;
/

-- UPDATE
CREATE OR REPLACE PROCEDURE update_lab (
    p_lab_id IN NUMBER,
    p_labname IN VARCHAR2,
    p_capacity IN NUMBER,
    p_availability IN VARCHAR2
) IS
BEGIN
    UPDATE Labs
    SET labname = p_labname,
        lab_capacity = p_capacity,
        availability_status = p_availability
    WHERE lab_id = p_lab_id;
END;
/

-- DELETE
CREATE OR REPLACE PROCEDURE delete_lab (
    p_lab_id IN NUMBER
) IS
BEGIN
    DELETE FROM Labs WHERE lab_id = p_lab_id;
END;
/

-- CREATE
CREATE OR REPLACE PROCEDURE create_project (
    p_title IN VARCHAR2,
    p_desc IN CLOB,
    p_start IN DATE,
    p_end IN DATE,
    p_lab_assigned IN NUMBER,
    p_admin IN NUMBER,
    p_status IN VARCHAR2
) IS
BEGIN
    INSERT INTO Projects(project_id, title, project_desc, start_date, end_date, lab_assigned, project_admin, status)
    VALUES (project_id_seq.NEXTVAL, p_title, p_desc, NVL(p_start, SYSDATE), p_end, p_lab_assigned, p_admin, p_status);
END;
/

-- READ
CREATE OR REPLACE PROCEDURE get_project (
    p_project_id IN NUMBER,
    p_title OUT VARCHAR2,
    p_desc OUT CLOB,
    p_start OUT DATE,
    p_end OUT DATE,
    p_lab OUT NUMBER,
    p_admin OUT NUMBER,
    p_status OUT VARCHAR2
) IS
BEGIN
    SELECT title, project_desc, start_date, end_date, lab_assigned, project_admin, status
    INTO p_title, p_desc, p_start, p_end, p_lab, p_admin, p_status
    FROM Projects WHERE project_id = p_project_id;
END;
/

-- UPDATE
CREATE OR REPLACE PROCEDURE update_project (
    p_project_id IN NUMBER,
    p_title IN VARCHAR2,
    p_desc IN CLOB,
    p_start IN DATE,
    p_end IN DATE,
    p_lab_assigned IN NUMBER,
    p_admin IN NUMBER,
    p_status IN VARCHAR2
) IS
BEGIN
    UPDATE Projects
    SET title = p_title,
        project_desc = p_desc,
        start_date = p_start,
        end_date = p_end,
        lab_assigned = p_lab_assigned,
        project_admin = p_admin,
        status = p_status
    WHERE project_id = p_project_id;
END;
/

-- DELETE
CREATE OR REPLACE PROCEDURE delete_project (
    p_project_id IN NUMBER
) IS
BEGIN
    DELETE FROM Projects WHERE project_id = p_project_id;
END;
/

-- CREATE
CREATE OR REPLACE PROCEDURE add_project_member (
    p_project_id IN NUMBER,
    p_user_id IN NUMBER,
    p_role IN VARCHAR2
) IS
BEGIN
    INSERT INTO ProjectMembers(project_id, user_id, project_role)
    VALUES (p_project_id, p_user_id, p_role);
END;
/

-- READ
CREATE OR REPLACE PROCEDURE get_project_member (
    p_project_id IN NUMBER,
    p_user_id IN NUMBER,
    p_role OUT VARCHAR2
) IS
BEGIN
    SELECT project_role
    INTO p_role
    FROM ProjectMembers
    WHERE project_id = p_project_id AND user_id = p_user_id;
END;
/

-- UPDATE
CREATE OR REPLACE PROCEDURE update_project_member (
    p_project_id IN NUMBER,
    p_user_id IN NUMBER,
    p_role IN VARCHAR2
) IS
BEGIN
    UPDATE ProjectMembers
    SET project_role = p_role
    WHERE project_id = p_project_id AND user_id = p_user_id;
END;
/

-- DELETE
CREATE OR REPLACE PROCEDURE remove_project_member (
    p_project_id IN NUMBER,
    p_user_id IN NUMBER
) IS
BEGIN
    DELETE FROM ProjectMembers
    WHERE project_id = p_project_id AND user_id = p_user_id;
END;
/

-- CREATE
CREATE OR REPLACE PROCEDURE create_funding (
    p_project_id IN NUMBER,
    p_sponsor IN VARCHAR2,
    p_amount IN NUMBER
) IS
BEGIN
    INSERT INTO Funding(funding_id, project_id, sponsor, amount)
    VALUES (funding_id_seq.NEXTVAL, p_project_id, p_sponsor, p_amount);
END;
/

-- READ
CREATE OR REPLACE PROCEDURE get_funding (
    p_funding_id IN NUMBER,
    p_project_id OUT NUMBER,
    p_sponsor OUT VARCHAR2,
    p_amount OUT NUMBER
) IS
BEGIN
    SELECT project_id, sponsor, amount
    INTO p_project_id, p_sponsor, p_amount
    FROM Funding
    WHERE funding_id = p_funding_id;
END;
/

-- UPDATE
CREATE OR REPLACE PROCEDURE update_funding (
    p_funding_id IN NUMBER,
    p_project_id IN NUMBER,
    p_sponsor IN VARCHAR2,
    p_amount IN NUMBER
) IS
BEGIN
    UPDATE Funding
    SET project_id = p_project_id,
        sponsor = p_sponsor,
        amount = p_amount
    WHERE funding_id = p_funding_id;
END;
/

-- DELETE
CREATE OR REPLACE PROCEDURE delete_funding (
    p_funding_id IN NUMBER
) IS
BEGIN
    DELETE FROM Funding WHERE funding_id = p_funding_id;
END;
/

-- CREATE
CREATE OR REPLACE PROCEDURE create_publication (
    p_title IN VARCHAR2,
    p_project_id IN NUMBER,
    p_pub_date IN DATE
) IS
BEGIN
    INSERT INTO Publications(pub_id, title, project_id, publication_date)
    VALUES (pub_id_seq.NEXTVAL, p_title, p_project_id, p_pub_date);
END;
/

-- READ
CREATE OR REPLACE PROCEDURE get_publication (
    p_pub_id IN NUMBER,
    p_title OUT VARCHAR2,
    p_project_id OUT NUMBER,
    p_pub_date OUT DATE
) IS
BEGIN
    SELECT title, project_id, publication_date
    INTO p_title, p_project_id, p_pub_date
    FROM Publications
    WHERE pub_id = p_pub_id;
END;
/

-- UPDATE
CREATE OR REPLACE PROCEDURE update_publication (
    p_pub_id IN NUMBER,
    p_title IN VARCHAR2,
    p_project_id IN NUMBER,
    p_pub_date IN DATE
) IS
BEGIN
    UPDATE Publications
    SET title = p_title,
        project_id = p_project_id,
        publication_date = p_pub_date
    WHERE pub_id = p_pub_id;
END;
/

-- DELETE
CREATE OR REPLACE PROCEDURE delete_publication (
    p_pub_id IN NUMBER
) IS
BEGIN
    DELETE FROM Publications WHERE pub_id = p_pub_id;
END;
/

-- CREATE
CREATE OR REPLACE PROCEDURE add_pub_author (
    p_pub_id IN NUMBER,
    p_user_id IN NUMBER,
    p_role IN VARCHAR2
) IS
BEGIN
    INSERT INTO pub_authors(pub_id, user_id, pub_role)
    VALUES (p_pub_id, p_user_id, p_role);
END;
/

-- READ
CREATE OR REPLACE PROCEDURE get_pub_author (
    p_pub_id IN NUMBER,
    p_user_id IN NUMBER,
    p_role OUT VARCHAR2
) IS
BEGIN
    SELECT pub_role
    INTO p_role
    FROM pub_authors
    WHERE pub_id = p_pub_id AND user_id = p_user_id;
END;
/

-- UPDATE
CREATE OR REPLACE PROCEDURE update_pub_author (
    p_pub_id IN NUMBER,
    p_user_id IN NUMBER,
    p_role IN VARCHAR2
) IS
BEGIN
    UPDATE pub_authors
    SET pub_role = p_role
    WHERE pub_id = p_pub_id AND user_id = p_user_id;
END;
/

-- DELETE
CREATE OR REPLACE PROCEDURE remove_pub_author (
    p_pub_id IN NUMBER,
    p_user_id IN NUMBER
) IS
BEGIN
    DELETE FROM pub_authors
    WHERE pub_id = p_pub_id AND user_id = p_user_id;
END;
/
