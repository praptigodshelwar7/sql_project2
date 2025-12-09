SELECT * FROM branch
SELECT * FROM employees
SELECT * FROM books
SELECT * FROM members
SELECT * FROM issued_status
SELECT * FROM return_status



--Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn,book_title,category,rental_price,status,author,publisher)
VALUES ('978-1-60179-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

--Task 2: Update an Existing Member's Address

UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

--Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id='IS121'

--Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

--Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT issued_emp_id,count(issued_id) as total_books FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(issued_id)>1;

--Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

SELECT b.isbn,COUNT(isb.issued_id) AS total_book_issued
FROM books as b
JOIN issued_status as isb
ON isb.issued_book_isbn=b.isbn
GROUP BY b.isbn

--Task 7. Retrieve All Books in a Specific Category:'Classic'

SELECT * FROM books
WHERE category='Classic';

--Task 8: Find Total Rental Income by Category:

SELECT b.category,SUM(b.rental_price) AS total_rental_price,COUNT(*) AS no_of_books_issued
FROM books AS b
JOIN issued_status AS isb
ON b.isbn=isb.issued_book_isbn
GROUP BY b.category

--TASK 9: List Members Who Registered in the Last 800 Days:

SELECT * FROM members
WHERE reg_date > DATEADD(DAY,-800,GETDATE());

--TASK 10: List Employees with Their Branch Manager's Name and their branch details:
--(My data has some error as it as not matching values of emp_id and man_id so i didn't get results )

SELECT e.emp_id,e.emp_name,e.position,e.salary,b.*,e2.emp_name
FROM employees AS e
JOIN branch AS b
ON e.branch_id=b.branch_id
JOIN
employees as e2
ON e2.emp_id = b.manager_id

--Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:

SELECT * 
INTO expensive_books
FROM books 
WHERE rental_price >7;

Select * from expensive_books

--Task 12: Retrieve the List of Books Not Yet Returned

SELECT i.issued_book_name
FROM issued_status AS i
LEFT JOIN return_status AS r
ON i.issued_id=r.issued_id
where r.return_id IS NULL


--SOME OPERATIONS TO BE DONE BEFORE SOLVING MORE QUESTIONS 

ALTER TABLE return_status
ADD book_quality VARCHAR(15) DEFAULT 'Good';
UPDATE return_status
SET book_quality = 'Damaged'
WHERE issued_id IN ('IS112', 'IS117', 'IS118');
UPDATE return_status
SET book_quality = 'Good'
WHERE book_quality IS NULL;
SELECT * FROM return_status;

/*
SQL PROJECT LIBRARY MANAGEMENT SYSTEM (ADVANCED QUERY OPERATIONS):

Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

issued_status += member += books += return_status 
*/

SELECT m.member_id,m.member_name,b.book_title,i.issued_date,DATEDIFF(DAY,issued_date,GETDATE()) AS overdue
FROM issued_status as i
JOIN members as m
ON i.issued_member_id=m.member_id
JOIN books AS b
On b.isbn=i.issued_book_isbn
LEFT JOIN return_status AS r
ON i.issued_id=r.issued_id
WHERE r.return_date IS NULL AND DATEDIFF(DAY,issued_date,GETDATE())>30
ORDER BY m.member_id

/*
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/

ALTER PROCEDURE add_return_records
			@return_id VARCHAR(10),
			@issued_id VARCHAR(10),
			@book_quality VARCHAR(10)
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @isbn VARCHAR(50);
	DECLARE @book_name VARCHAR(80);

	

	SELECT 
			@isbn=issued_book_isbn,
			@book_name=issued_book_name
	FROM issued_status
	WHERE issued_id=@issued_id

	INSERT INTO return_status (return_id,issued_id,return_date,book_quality) 
	VALUES(@return_id,@issued_id,CAST(GETDATE()AS DATE),@book_quality);


	UPDATE books 
	SET status = 'yes'
	WHERE isbn=@isbn;

	PRINT 'Thank you for returning book:'+@book_name;
END;

EXEC add_return_records 'RS138', 'IS135', 'Good';

/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
*/

SELECT 
	b.branch_id,
	b.manager_id,
	COUNT(i.issued_id) AS no_of_books_issued,
	COUNT(r.return_id) AS no_of_books_returned,
	SUM(bk.rental_price) AS total_revenue
INTO branch_reports
FROM issued_status AS i
JOIN employees AS e
	ON e.emp_id=i.issued_emp_id
JOIN branch AS b 
	ON e.branch_id=b.branch_id
LEFT JOIN return_status AS r
	ON r.issued_id=i.issued_id
JOIN books AS bk
	ON bk.isbn=i.issued_book_isbn

GROUP BY 
    b.branch_id,
    b.manager_id;

SELECT * FROM branch_reports

/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.
*/

SELECT *
INTO active_members
FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id
    FROM issued_status
    WHERE issued_date >= DATEADD(MONTH, -2, CAST(GETDATE() AS DATE))
);
SELECT * FROM active_members

/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
*/

SELECT TOP 3
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY e.emp_name,b.branch_id,b.manager_id,b.branch_address,b.contact_no

/*
Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. Description: Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows: The stored procedure should take the book_id as an input parameter. The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/

CREATE PROCEDURE issue_book
    @issued_id VARCHAR(10),
    @issued_member_id VARCHAR(30),
    @issued_book_isbn VARCHAR(30),
    @issued_emp_id VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @status VARCHAR(10);

    --  Check if book is available
    SELECT 
        @status = status
    FROM books
    WHERE isbn = @issued_book_isbn;

    --  If book is available
    IF @status = 'yes'
    BEGIN
        -- Insert issued record
        INSERT INTO issued_status
            (issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
            (@issued_id, @issued_member_id, CAST(GETDATE() AS DATE), 
             @issued_book_isbn, @issued_emp_id);

        -- Mark book as not available
        UPDATE books
        SET status = 'no'
        WHERE isbn = @issued_book_isbn;

        PRINT 'Book issued successfully for ISBN: ' + @issued_book_isbn;
    END
    ELSE
    BEGIN
        PRINT 'Sorry, the requested book is unavailable. ISBN: ' + @issued_book_isbn;
    END
END;
GO
EXEC issue_book 'IS155', 'C108', '978-0-553-29698-2', 'E104';
EXEC issue_book 'IS156', 'C108', '978-0-375-41398-8', 'E104';
