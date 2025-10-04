--======================================== CRUD ==============================================




------------------ USER ---------------------------------



CREATE OR REPLACE PROCEDURE CreateUser (in_name IN VARCHAR2, in_email IN VARCHAR2, in_role IN VARCHAR2, in_password  IN VARCHAR2) AS
    v_user_id NUMBER;
    v_salt    RAW(32);
    v_hash    RAW(64);
BEGIN   
    IF EXISTS (SELECT 1 FROM Users1 where email=in_email) THEN
        DBMS_OUTPUT.PUT_LINE('No user with the given id found');
        RETURN; 
    END IF;

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

    UPDATE Users1 SET full_name = NVL(new_name,v_name), email = NVL(new_email, v_mail), user_role = NVL(new_role,v_role) WHERE user_id = in_id;
END;
/


CREATE OR REPLACE PROCEDURE DeleteUser (in_id IN NUMBER) AS

BEGIN
    IF EXISTS (SELECT 1 FROM Users1 where user_id = in_id) THEN 
        DELETE FROM Users1 where user_id = in_id;
        DBMS_OUTPUT.PUT_LINE('User Deleted Successfully');
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No user with the given id found');  
END;
/

CREATE OR REPLACE PROCEDURE ShowUsers (in_role IN VARCHAR2) AS 

BEGIN 
    IF in_role = 'ADMIN' THEN
    SELECT * FROM Users1;
    RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Only Admin can perform this action');
END;
/

CREATE OR REPLACE PROCEDURE GetUser (in_id IN NUMBER) AS 

BEGIN 
    IF EXISTS (SELECT 1 FROM Users1 where user_id = in_id) THEN
        SELECT 1 FROM Users1 where user_id = in_id;
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No user with the given id found');
END;
/










------------------ LABS ---------------------------------





CREATE OR REPLACE PROCEDURE CreateLab (p_labname IN VARCHAR2, p_capacity IN NUMBER, p_availability IN VARCHAR2, in_role IN VARCHAR2) AS
BEGIN

    IF in_role = 'ADMIN' THEN
        INSERT INTO Labs(lab_id, labname, lab_capacity, availability_status)
        VALUES (lab_id_seq.NEXTVAL, p_labname, p_capacity, p_availability);
    RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Only Admin can perform this action');

END;
/

CREATE OR REPLACE PROCEDURE GetLab (p_lab_id IN NUMBER) IS
BEGIN
    IF EXISTS (SELECT 1 FROM Labs where lab_id = p_lab_id) THEN
    SELECT 1 FROM labs where lab_id = p_lab_id;
    RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No Lab with the given id found');
END;
/

CREATE OR REPLACE PROCEDURE UpdateLab ( p_lab_id IN NUMBER, p_labname IN VARCHAR2, p_capacity IN NUMBER, p_availability IN VARCHAR2, in_role) AS

v_labname Labs.labname%TYPE;
v_avl Labs.availability_status%TYPE;
v_cap Labs.lab_capacity%TYPE;
BEGIN
    
    IF in_role != 'ADMIN' THEN
    DBMS_OUTPUT.PUT_LINE('Only Admin can perform this action');
    RETURN;
    END IF;
    
    BEGIN 
        SELECT labname,availabilty_status, lab_capacity INTO v_labname, v_avl, v_cap FROM Labs WHERE lab_id = p_lab_id;
        EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No data found');
        RETURN;
    END;

    UPDATE Labs SET labname = NVL(p_labname, v_labname), lab_capacity = NVL(p_capacity, v_cap), availability_status = NVL(p_availability, v_avl) WHERE lab_id = p_lab_id;
END;
/

CREATE OR REPLACE PROCEDURE DeleteLab ( p_lab_id IN NUMBER , in_role IN VARCHAR2) IS
BEGIN

IF in_role != 'ADMIN' THEN
    DBMS_OUTPUT.PUT_LINE('Only Admin can perform this action');
    RETURN;
END IF;

IF EXISTS (SELECT 1 FROM Labs where lab_id = p_lab_id) THEN
    DELETE FROM Labs WHERE lab_id = p_lab_id;
    RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No Lab with the given id found');
    
END;
/










-------------------- PROJECTS ------------------------------


CREATE OR REPLACE PROCEDURE CreateProject (
    in_title IN VARCHAR2,
    in_desc IN CLOB,
    in_start IN DATE,
    in_end IN DATE,
    in_lab_assigned IN NUMBER,
    in_admin IN NUMBER,
    in_status IN VARCHAR2,
    in_role IN VARCHAR2
) AS
    v_project_id NUMBER;
BEGIN

IF in_role NOT IN ('ADMIN','FACULTY') THEN
    DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
    RETURN;
END IF;

    IF EXISTS (SELECT 1 FROM Projects WHERE title = in_title) THEN
        DBMS_OUTPUT.PUT_LINE('Project with same title already exists');
        RETURN;
    END IF;

    SELECT project_id_seq.NEXTVAL INTO v_project_id FROM dual;

    INSERT INTO Projects(project_id, title, project_desc, start_date, end_date, lab_assigned, project_admin, status)
    VALUES (v_project_id, in_title, in_desc, NVL(in_start, SYSDATE), in_end, in_lab_assigned, in_admin, in_status);

    DBMS_OUTPUT.PUT_LINE('Project Created Successfully with ID: ' || v_project_id);
END;
/



CREATE OR REPLACE PROCEDURE GetProject (in_id IN NUMBER) AS
BEGIN
    IF EXISTS (SELECT 1 FROM Projects WHERE project_id = in_id) THEN
        SELECT 1 FROM Projects WHERE project_id = in_id;
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No project with the given id found');
END;
/



CREATE OR REPLACE PROCEDURE UpdateProject (
    in_id IN NUMBER,
    new_title IN VARCHAR2,
    new_desc IN CLOB,
    new_start IN DATE,
    new_end IN DATE,
    new_lab IN NUMBER,
    new_admin IN NUMBER,
    new_status IN VARCHAR2
) AS
    v_title   Projects.title%TYPE;
    v_desc    Projects.project_desc%TYPE;
    v_start   Projects.start_date%TYPE;
    v_end     Projects.end_date%TYPE;
    v_lab     Projects.lab_assigned%TYPE;
    v_admin   Projects.project_admin%TYPE;
    v_status  Projects.status%TYPE;
BEGIN

IF in_role NOT IN ('ADMIN','FACULTY') THEN
    DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
    RETURN;
END IF;

    BEGIN
        SELECT title, project_desc, start_date, end_date, lab_assigned, project_admin, status
        INTO v_title, v_desc, v_start, v_end, v_lab, v_admin, v_status
        FROM Projects WHERE project_id = in_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No project with the given id found');
            RETURN;
    END;

    UPDATE Projects
    SET title = NVL(new_title, v_title),
        project_desc = NVL(new_desc, v_desc),
        start_date = NVL(new_start, v_start),
        end_date = NVL(new_end, v_end),
        lab_assigned = NVL(new_lab, v_lab),
        project_admin = NVL(new_admin, v_admin),
        status = NVL(new_status, v_status)
    WHERE project_id = in_id;

    DBMS_OUTPUT.PUT_LINE('Project Updated Successfully');
END;
/


CREATE OR REPLACE PROCEDURE DeleteProject (in_id IN NUMBER) AS
BEGIN

    IF in_role NOT IN ('ADMIN','FACULTY') THEN
    DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
    RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM Projects WHERE project_id = in_id) THEN
        DELETE FROM Projects WHERE project_id = in_id;
        DBMS_OUTPUT.PUT_LINE('Project Deleted Successfully');
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No project with the given id found');
END;
/

CREATE OR REPLACE PROCEDURE ShowProjects AS
BEGIN
    SELECT * FROM Projects;
END;
/










-------------------- PROJECT MEMBERS ------------------------------



CREATE OR REPLACE PROCEDURE AddProjectMember (
    in_project_id IN NUMBER,
    in_user_id IN NUMBER,
    in_role IN VARCHAR2,
    action_role IN VARCHAR2
) AS
BEGIN
IF action_role NOT IN ('ADMIN','FACULTY') THEN
    DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
    RETURN;
END IF;

    IF EXISTS (SELECT 1 FROM ProjectMembers WHERE project_id = in_project_id AND user_id = in_user_id) THEN
        DBMS_OUTPUT.PUT_LINE('Project member already exists');
        RETURN;
    END IF;

    INSERT INTO ProjectMembers(project_id, user_id, project_role)
    VALUES (in_project_id, in_user_id, in_role);
END;
/

CREATE OR REPLACE PROCEDURE UpdateProjectMember (
    in_project_id IN NUMBER,
    in_user_id IN NUMBER,
    new_role IN VARCHAR2,
    action_role IN VARCHAR2
) AS
    v_role ProjectMembers.project_role%TYPE;
BEGIN

    IF action_role NOT IN ('ADMIN','FACULTY') THEN
    DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
    RETURN;
    END IF;

    BEGIN
        SELECT project_role INTO v_role
        FROM ProjectMembers
        WHERE project_id = in_project_id AND user_id = in_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No project member with the given ids found');
            RETURN;
    END;

    UPDATE ProjectMembers
    SET project_role = NVL(new_role, v_role)
    WHERE project_id = in_project_id AND user_id = in_user_id;
END;
/

CREATE OR REPLACE PROCEDURE RemoveProjectMember (
    in_project_id IN NUMBER,
    in_user_id IN NUMBER,
    action_role IN VARCHAR2
) AS
BEGIN
    IF in_role NOT IN ('ADMIN','FACULTY') THEN
    DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
    RETURN;
    END IF;
    
    IF EXISTS (SELECT 1 FROM ProjectMembers WHERE project_id = in_project_id AND user_id = in_user_id) THEN
        DELETE FROM ProjectMembers WHERE project_id = in_project_id AND user_id = in_user_id;
        DBMS_OUTPUT.PUT_LINE('Project Member Deleted Successfully');
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No project member with the given ids found');
END;
/


CREATE OR REPLACE PROCEDURE ShowProjectMembers AS
BEGIN
    SELECT * FROM ProjectMembers;
END;
/

CREATE OR REPLACE PROCEDURE GetProjectMember (in_project_id IN NUMBER, in_user_id IN NUMBER) AS
BEGIN
    IF EXISTS (SELECT 1 FROM ProjectMembers WHERE project_id = in_project_id AND user_id = in_user_id) THEN
        SELECT * FROM ProjectMembers WHERE project_id = in_project_id AND user_id = in_user_id;
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No project member with the given ids found');
END;
/













-------------------- FUNDINGS ------------------------------







CREATE OR REPLACE PROCEDURE CreateFunding (
    in_project_id IN NUMBER,
    in_sponsor IN VARCHAR2,
    in_amount IN NUMBER,
    action_role IN VARCHAR2 
) AS
    v_funding_id NUMBER;
BEGIN
    IF action_role NOT IN ('ADMIN') THEN
    DBMS_OUTPUT.PUT_LINE('Only Admin can perform this action');
    RETURN;
    END IF;

    SELECT funding_id_seq.NEXTVAL INTO v_funding_id FROM dual;

    INSERT INTO Funding(funding_id, project_id, sponsor, amount)
    VALUES (v_funding_id, in_project_id, in_sponsor, in_amount);
END;
/

CREATE OR REPLACE PROCEDURE UpdateFunding (
    in_id IN NUMBER,
    new_project_id IN NUMBER,
    new_sponsor IN VARCHAR2,
    new_amount IN NUMBER,
    action_role IN VARCHAR2
) AS
    v_project Funding.project_id%TYPE;
    v_sponsor Funding.sponsor%TYPE;
    v_amount Funding.amount%TYPE;
BEGIN
    IF action_role NOT IN ('ADMIN') THEN
    DBMS_OUTPUT.PUT_LINE('Only Admin can perform this action');
    RETURN;
    END IF;

    BEGIN
        SELECT project_id, sponsor, amount
        INTO v_project, v_sponsor, v_amount
        FROM Funding WHERE funding_id = in_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No funding with the given id found');
            RETURN;
    END;

    UPDATE Funding
    SET project_id = NVL(new_project_id, v_project),
        sponsor = NVL(new_sponsor, v_sponsor),
        amount = NVL(new_amount, v_amount)
    WHERE funding_id = in_id;
END;
/


CREATE OR REPLACE PROCEDURE DeleteFunding (in_id IN NUMBER, action_role IN VARCHAR2) AS
BEGIN
    IF action_role NOT IN ('ADMIN') THEN
        DBMS_OUTPUT.PUT_LINE('Only Admin can perform this action');
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM Funding WHERE funding_id = in_id) THEN
        DELETE FROM Funding WHERE funding_id = in_id;
        DBMS_OUTPUT.PUT_LINE('Funding Deleted Successfully');
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No funding with the given id found');
END;
/

CREATE OR REPLACE PROCEDURE ShowFunding AS
BEGIN
    SELECT * FROM Funding;
END;
/

CREATE OR REPLACE PROCEDURE GetFunding (in_id IN NUMBER) AS
BEGIN
    IF EXISTS (SELECT 1 FROM Funding WHERE funding_id = in_id) THEN
        SELECT * FROM Funding WHERE funding_id = in_id;
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No funding with given id found');
END;
/













-------------------- PUBLICATIONS ------------------------------



CREATE OR REPLACE PROCEDURE CreatePublication (
    in_title IN VARCHAR2,
    in_project_id IN NUMBER,
    in_pub_date IN DATE,
    action_role IN VARCHAR2
) AS
    v_pub_id NUMBER;
    v_date DATE;
BEGIN
    IF action_role NOT IN ('ADMIN','FACULTY') THEN
        DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
        RETURN;
    END IF;
    IF EXISTS (SELECT 1 FROM Publications WHERE title = in_title) THEN
        DBMS_OUTPUT.PUT_LINE('Publication with same title already exists');
        RETURN;
    END IF;

    v_date = NVL(in_pub_date, SYSDATE);
    END IF;

    SELECT pub_id_seq.NEXTVAL INTO v_pub_id FROM dual;

    INSERT INTO Publications(pub_id, title, project_id, publication_date)
    VALUES (v_pub_id, in_title, in_project_id, v_date);
END;
/


CREATE OR REPLACE PROCEDURE UpdatePublication (
    in_id IN NUMBER,
    new_title IN VARCHAR2,
    new_project_id IN NUMBER,
    new_pub_date IN DATE,
    action_role IN VARCHAR2
) AS
    v_title Publications.title%TYPE;
    v_project Publications.project_id%TYPE;
    v_date Publications.publication_date%TYPE;
BEGIN

    IF action_role NOT IN ('ADMIN','FACULTY') THEN
        DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
        RETURN;
    END IF;

    BEGIN
        SELECT title, project_id, publication_date
        INTO v_title, v_project, v_date
        FROM Publications WHERE pub_id = in_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No publication with the given id found');
            RETURN;
    END;

    IF v_date <= SYSDATE THEN
        DBMS_OUTPUT.PUT_LINE('Cannot change publication details after or on publication date');
        RETURN;
    END IF;

    UPDATE Publications
    SET title = NVL(new_title, v_title),
        project_id = NVL(new_project_id, v_project),
        publication_date = NVL(new_pub_date, v_date)
    WHERE pub_id = in_id;
END;
/


CREATE OR REPLACE PROCEDURE DeletePublication (
    in_id IN NUMBER,
    action_role IN VARCHAR2
) AS
    v_pub_date DATE;
BEGIN
    IF action_role NOT IN ('ADMIN','FACULTY') THEN
        DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
        RETURN;
    END IF;
    BEGIN
        SELECT publication_date
        INTO v_pub_date
        FROM Publications
        WHERE pub_id = in_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No publication with the given id found');
            RETURN;
    END;

    IF v_pub_date <= SYSDATE THEN
        DBMS_OUTPUT.PUT_LINE('Cannot delete publication after or on publication date');
        RETURN;
    END IF;

    DELETE FROM Publications WHERE pub_id = in_id;
    DBMS_OUTPUT.PUT_LINE('Publication Deleted Successfully');
END;
/



CREATE OR REPLACE PROCEDURE ShowPublications AS
BEGIN
    SELECT * FROM Publications;
END;
/


CREATE OR REPLACE PROCEDURE GetPublication (in_id IN NUMBER) AS
BEGIN
    IF EXISTS (SELECT 1 FROM Publications WHERE pub_id = in_id) THEN
        SELECT * FROM Publications WHERE pub_id = in_id;
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No publication found');
END;
/













-------------------- Publication_Authors ------------------------------

CREATE OR REPLACE PROCEDURE AddPubAuthor (
    in_pub_id IN NUMBER,
    in_user_id IN NUMBER,
    in_role IN VARCHAR2,
    action_role IN VARCHAR2
) AS
BEGIN

    IF action_role NOT IN ('ADMIN','FACULTY') THEN
        DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
        RETURN;
    END IF;
    
    BEGIN
        SELECT publication_date INTO v_pub_date
        FROM Publications
        WHERE pub_id = in_pub_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Publication not found');
            RETURN;
    END;

    IF v_pub_date <= SYSDATE THEN
        DBMS_OUTPUT.PUT_LINE('Cannot add authors after publication date');
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM pub_authors WHERE pub_id = in_pub_id AND user_id = in_user_id) THEN
        DBMS_OUTPUT.PUT_LINE('Publication author already exists');
        RETURN;
    END IF;

    INSERT INTO pub_authors(pub_id, user_id, pub_role)
    VALUES (in_pub_id, in_user_id, in_role);
END;
/

CREATE OR REPLACE PROCEDURE UpdatePubAuthor (
    in_pub_id IN NUMBER,
    in_user_id IN NUMBER,
    new_role IN VARCHAR2,
    action_role IN VARCHAR2
) AS
    v_role pub_authors.pub_role%TYPE;
BEGIN

    IF action_role NOT IN ('ADMIN','FACULTY') THEN
        DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
        RETURN;
    END IF;

    BEGIN
        SELECT publication_date INTO v_pub_date
        FROM Publications
        WHERE pub_id = in_pub_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Publication not found');
        RETURN;
    END;

    BEGIN
        SELECT pub_role INTO v_role
        FROM pub_authors
        WHERE pub_id = in_pub_id AND user_id = in_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No publication author with the given ids found');
            RETURN;
    END;

    IF v_pub_date <= SYSDATE THEN
        DBMS_OUTPUT.PUT_LINE('Cannot update author details after publication date');
        RETURN;
    END IF;

    UPDATE pub_authors
    SET pub_role = NVL(new_role, v_role)
    WHERE pub_id = in_pub_id AND user_id = in_user_id;
END;
/

CREATE OR REPLACE PROCEDURE DeletePubAuthor (in_pub_id IN NUMBER, in_user_id IN NUMBER, action_role IN VARCHAR2) AS
BEGIN
    IF action_role NOT IN ('ADMIN','FACULTY') THEN
        DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
        RETURN;
    END IF;
    BEGIN
        SELECT publication_date INTO v_pub_date
        FROM Publications
        WHERE pub_id = in_pub_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Publication not found');
            RETURN;
    END;

    IF v_pub_date <= SYSDATE THEN
        DBMS_OUTPUT.PUT_LINE('Cannot delete authors after or on publication date');
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM pub_authors WHERE pub_id = in_pub_id AND user_id = in_user_id) THEN
        DELETE FROM pub_authors WHERE pub_id = in_pub_id AND user_id = in_user_id;
        DBMS_OUTPUT.PUT_LINE('Publication author Deleted Successfully');
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No publication author with the given ids found');
END;
/

CREATE OR REPLACE PROCEDURE ShowPubAuthors AS
BEGIN
    SELECT * FROM pub_authors;
END;
/

CREATE OR REPLACE PROCEDURE GetPubAuthor (in_pub_id IN NUMBER, in_user_id IN NUMBER) AS
BEGIN
    IF EXISTS (SELECT 1 FROM pub_authors WHERE pub_id = in_pub_id AND user_id = in_user_id) THEN
        SELECT * FROM pub_authors WHERE pub_id = in_pub_id AND user_id = in_user_id;
        RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('No publication author found');
END;
/
