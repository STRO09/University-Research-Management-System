CREATE OR REPLACE PROCEDURE GetUsersByRole(
    p_role IN VARCHAR2
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Users1 WHERE user_role = p_role;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No users found with role: ' || p_role);
        RETURN;
    END IF;

    FOR rec IN (SELECT user_id, full_name, email FROM Users1 WHERE user_role = p_role ORDER BY full_name) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.user_id || ', Name: ' || rec.full_name || ', Email: ' || rec.email);
    END LOOP;
END;
/


CREATE OR REPLACE TRIGGER trg_validate_email_users
BEFORE INSERT OR UPDATE ON Users1
FOR EACH ROW
DECLARE
BEGIN
    IF :NEW.email IS NULL THEN
        RAISE_APPLICATION_ERROR(-20010, 'Email cannot be NULL.');
    END IF;

    IF NOT REGEXP_LIKE(:NEW.email, '^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$') THEN
        RAISE_APPLICATION_ERROR(-20011, 'Invalid email format.');
    END IF;
END;
/



CREATE OR REPLACE PROCEDURE AssignLabToProject(
    p_lab_id      IN NUMBER,
    p_project_id  IN NUMBER,
    action_role   IN VARCHAR2    -- should be 'ADMIN' or 'FACULTY'
) AS
    v_lab_count     NUMBER;
    v_proj_count    NUMBER;
    v_lab_status    Labs.availability_status%TYPE;
    v_current_lab   Projects.lab_assigned%TYPE;
BEGIN
    IF action_role NOT IN ('ADMIN','FACULTY') THEN
        DBMS_OUTPUT.PUT_LINE('Only Admin and Faculty can perform this action');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_lab_count FROM Labs WHERE lab_id = p_lab_id;
    IF v_lab_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Lab not found.');
    END IF;

    SELECT COUNT(*) INTO v_proj_count FROM Projects WHERE project_id = p_project_id;
    IF v_proj_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20013, 'Project not found.');
    END IF;

    SELECT availability_status INTO v_lab_status FROM Labs WHERE lab_id = p_lab_id;

    IF v_lab_status = 'NO' THEN
        RAISE_APPLICATION_ERROR(-20014, 'Lab is not available for assignment.');
    END IF;

    -- If project already has a lab assigned, disallow or reassign? Here we check and raise.
    SELECT lab_assigned INTO v_current_lab FROM Projects WHERE project_id = p_project_id;
    IF v_current_lab IS NOT NULL THEN
        -- If current lab is same as requested, just inform; else disallow (you can change behavior)
        IF v_current_lab = p_lab_id THEN
            DBMS_OUTPUT.PUT_LINE('This lab is already assigned to the project.');
            RETURN;
        ELSE
            RAISE_APPLICATION_ERROR(-20015, 'Project already has a lab assigned. Please release it first or update via UpdateProject.');
        END IF;
    END IF;

    -- Assign lab to project and mark lab unavailable
    UPDATE Projects
    SET lab_assigned = p_lab_id
    WHERE project_id = p_project_id;

    UPDATE Labs
    SET availability_status = 'NO'
    WHERE lab_id = p_lab_id;

    DBMS_OUTPUT.PUT_LINE('Lab ' || p_lab_id || ' assigned to Project ' || p_project_id);
END;
/



CREATE OR REPLACE PROCEDURE ReleaseLab(
    p_lab_id    IN NUMBER,
    action_role IN VARCHAR2
) AS
    v_exists NUMBER;
    v_active_projects NUMBER;
BEGIN
    IF action_role != 'ADMIN' THEN
        DBMS_OUTPUT.PUT_LINE('Only Admin can perform this action');
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_exists FROM Labs WHERE lab_id = p_lab_id;
    IF v_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20016, 'Lab not found.');
    END IF;

    -- Count active projects using this lab (active = not COMPLETED and not CANCELLED)
    SELECT COUNT(*) INTO v_active_projects
    FROM Projects
    WHERE lab_assigned = p_lab_id AND NVL(status,'PLANNED') NOT IN ('COMPLETED', 'CANCELLED');

    IF v_active_projects > 0 THEN
        RAISE_APPLICATION_ERROR(-20017, 'Cannot release lab — it is assigned to active project(s).');
    END IF;

    UPDATE Labs
    SET availability_status = 'YES'
    WHERE lab_id = p_lab_id;

    DBMS_OUTPUT.PUT_LINE('Lab ' || p_lab_id || ' released (availability = YES).');
END;
/


CREATE OR REPLACE PROCEDURE GetActiveProjects(
    p_user_id IN NUMBER
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM ProjectMembers pm
    JOIN Projects p ON pm.project_id = p.project_id
    WHERE pm.user_id = p_user_id
      AND p.status NOT IN ('COMPLETED', 'CANCELLED');

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No active projects found for user id: ' || p_user_id);
        RETURN;
    END IF;

    FOR rec IN (
        SELECT p.project_id, p.title, p.status
        FROM ProjectMembers pm
        JOIN Projects p ON pm.project_id = p.project_id
        WHERE pm.user_id = p_user_id
          AND p.status NOT IN ('COMPLETED', 'CANCELLED')
        ORDER BY p.start_date DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Project ID: ' || rec.project_id || ', Title: ' || rec.title || ', Status: ' || rec.status);
    END LOOP;
END;
/




CREATE OR REPLACE TRIGGER trg_validate_project_dates
BEFORE INSERT OR UPDATE ON Projects
FOR EACH ROW
BEGIN
    IF :NEW.end_date IS NOT NULL AND :NEW.start_date IS NOT NULL THEN
        IF :NEW.end_date < :NEW.start_date THEN
            RAISE_APPLICATION_ERROR(-20020, 'End date cannot be before start date.');
        END IF;
    END IF;
END;
/


CREATE OR REPLACE PROCEDURE GetProjectMembersByRole(
    p_project_id IN NUMBER,
    p_role       IN VARCHAR2
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM ProjectMembers
    WHERE project_id = p_project_id AND project_role = p_role;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No members with role "' || p_role || '" found for project ' || p_project_id);
        RETURN;
    END IF;

    FOR rec IN (
        SELECT pm.user_id, u.full_name, pm.project_role
        FROM ProjectMembers pm
        LEFT JOIN Users1 u ON pm.user_id = u.user_id
        WHERE pm.project_id = p_project_id AND pm.project_role = p_role
        ORDER BY u.full_name
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('User ID: ' || rec.user_id || ', Name: ' || NVL(rec.full_name, 'Unknown') || ', Role: ' || rec.project_role);
    END LOOP;
END;
/



CREATE OR REPLACE PROCEDURE GetProjectFundingSummary(
    p_project_id IN NUMBER
) AS
    v_total NUMBER(12,0);
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Funding WHERE project_id = p_project_id;
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No funding records for project: ' || p_project_id);
        RETURN;
    END IF;

    SELECT NVL(SUM(amount),0) INTO v_total FROM Funding WHERE project_id = p_project_id;

    DBMS_OUTPUT.PUT_LINE('Funding Summary for Project ' || p_project_id || ': Total = ' || v_total);
END;
/


CREATE OR REPLACE TRIGGER trg_prevent_fund_for_cancelled_proj
BEFORE INSERT ON Funding
FOR EACH ROW
DECLARE
    v_status Projects.status%TYPE;
BEGIN
    SELECT status INTO v_status FROM Projects WHERE project_id = :NEW.project_id;

    IF v_status = 'CANCELLED' THEN
        RAISE_APPLICATION_ERROR(-20030, 'Cannot add funding to a cancelled project.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20031, 'Referenced project does not exist.');
END;
/


CREATE OR REPLACE PROCEDURE GetPublicationsByProject(
    p_project_id IN NUMBER
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Publications WHERE project_id = p_project_id;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No publications found for project: ' || p_project_id);
        RETURN;
    END IF;

    FOR rec IN (
        SELECT pub_id, title, TO_CHAR(publication_date,'DD-MON-YYYY') pub_date
        FROM Publications
        WHERE project_id = p_project_id
        ORDER BY publication_date DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Pub ID: ' || rec.pub_id || ', Title: ' || rec.title || ', Date: ' || rec.pub_date);
    END LOOP;
END;
/



CREATE OR REPLACE PROCEDURE GetAuthorsByPublication(
    p_pub_id IN NUMBER
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM pub_authors WHERE pub_id = p_pub_id;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No authors found for publication: ' || p_pub_id);
        RETURN;
    END IF;

    FOR rec IN (
        SELECT pa.user_id, u.full_name, pa.pub_role
        FROM pub_authors pa
        LEFT JOIN Users1 u ON pa.user_id = u.user_id
        WHERE pa.pub_id = p_pub_id
        ORDER BY pa.pub_role, u.full_name
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('User ID: ' || rec.user_id || ', Name: ' || NVL(rec.full_name,'Unknown') || ', Role: ' || rec.pub_role);
    END LOOP;
END;
/


