# Tabular data check alerts

Dryad's mission is to enable the open availability and routine reuse of all research data. Data that is inconsistently formatted is inaccessible for reuse, particularly for machine reading and processing. Formatting and structuring inconsistencies also create barriers to the ability to access data with screen readers and other assistive devices.

When you upload files to Dryad, our [tabular data checker](/stash/submission_process#tabular-data-check) will perform automated data validation on many of your data files, generating viewable reports for any inconsistencies found. Correcting inconsistencies increases the accessibility of the data.

<img src="/images/tabular_data_check.png" alt="Screenshot showing an example upload table, with tabular data check alert report links." />

Do you have questions about the alerts our tabular data check has created for your data files? Check the guides below for help evaluating and resolving these messages.
 
## Type Error

<p class="error-example">The value does not match the schema type and format for this field.</p>

### What does this mean?

The tabular data checker attempts to identify the type and format of the data recorded in each cell. This alert indicates that data in a cell does not match the data type identified for the row and column. [Read more about the data types recognized by the tabular data checker](https://specs.frictionlessdata.io/table-schema/#types-and-formats).
  
#### Common causes

- A single CSV file or XSL sheet contains multiple different tables.
- A column contains 98 rows of integers and 2 rows of strings. The strings will be marked as a type error.
- A cell contains mixed numerical and string content, in a column otherwise containing integers. This cell will be marked as a type error.
- A column contains 97 rows of integers (“round” or “whole” numbers) and 3 rows of numbers with decimal places. The decimal numbers will be marked as type errors.
- A CSV file contains multiple rows meant to be read as headings, or additional descriptions of headings, before the start of the data. Any heading rows beyond the first may trigger this alert.


### What should I do?

While you can choose whether to resolve or ignore any tabular data check alerts, some type errors are more obviously problematic than others. This check is especially valuable for highlighting placeholder or other unintentional values that have been left in a data row, which should be replaced or removed. 

Including multiple tables of information in one CSV file is not accessible or machine readable and discourages reuse. Each table should be placed in a separate file.

The difference between integers (round numbers) and decimals is often not critical to understanding data, but it is easier for others to reuse your data, particularly through machine processing, if all numerical data in a column is one or the other. Consistency in the number of decimal places of your data makes reuse even easier.

If you wish to make any changes, correct the file on your machine, remove the version of the file with alerts from the upload screen, and re-upload the corrected version.

<div class="callout">
<h4>An important note for generating and processing Dryad data</h4><p>The tabular data check recognizes the following strings, in addition to blank cells, as indicating a cell with no data: <code>NA</code>, <code>na</code>, <code>N/A</code>, <code>n/a</code>, <code>N.A.</code>, <code>n.a.</code>, <code>-</code>, <code>.</code>, <code>empty</code>, <code>blank</code>
<p>If any of these strings are the cell content in an otherwise non-string column, they will not be highlighted as a data type error. Please indicate null data by leaving a cell blank, or by using one of these strings.
</div>

## Blank Row

<p class="error-example">This row is empty. A row should contain at least one value.</p>

### What does this mean?

An entire row of the table is missing content.

Blank rows can cause dysfunction in machine processing of data, and screen readers may read a series of null values. Sometimes the creators of tabular data include empty rows as a border between data or between different sets of tabular information. Including multiple tables of information in one CSV file or XSL sheet is not accessible or machine readable.

### What should I do?

Empty rows should be removed from the file. If your file contains multiple tables separated by blank rows, each table should be placed in a separate file instead. Correct the file on your machine, remove the version of the file with alerts from the upload screen, and re-upload the corrected version.


## Blank Label

<p class="error-example">A label in the header row is missing a value. Label should be provided and not be blank.</p>

### What does this mean?

A column has been included in a table, but the heading for the column (the cell in the first row) is empty. If the column contains any data, it may be dropped by machine processing. Assistive devices like screen readers can navigate through tables using headings, and can be confused by blank headings.

The entire column may also be blank. Blank columns indicate many of the same issues as [blank rows](#blank-row).

### What should I do?

Empty columns should be removed from the file. If your file contains multiple tables separated by blank columns, each table should be placed in a separate file instead. Correct the file on your machine, remove the version of the file with alerts from the upload screen, and re-upload the corrected version.


## Duplicate Label

<p class="error-example">Two columns in the header row have the same value. Column names should be unique.</p>

### What does this mean?

Multiple cells in the header row (the first row of the table) contain the same label text identifying the data below. The header labels for each column should be unique, or one of the columns may be lost in machine processing. Duplicate headings can make navigation through the table very confusing for assistive devices.

### What should I do?

Correct the file on your machine, remove the version of the file with alerts from the upload screen, and re-upload the corrected version.


## Missing Cell

<p class="error-example">This row has less values compared to the header row (the first row in the data source). A key concept is that all the rows in tabular data must have the same number of columns.</p>

### What does this mean?

In a CSV or TSV file, the row has a different number of cells than the first (header) row (indicated in the plain text file by a different number of comma or tab separators).

#### Common causes

This can be caused by generating a CSV or TSV file incorrectly, giving different rows a different number of cells.

### What should I do?

Correct the file on your machine. If possible, check and correct the code used to generate your data files. Remove the version of the file with alerts from the upload screen, and re-upload the corrected version.


## Extra Cell

<p class="error-example">This row has more values compared to the header row (the first row in the data source). A key concept is that all the rows in tabular data must have the same number of columns.</p>

### What does this mean?

In a CSV or TSV file, the row has a different number of cells than the first (header) row (indicated in the plain text file by a different number of comma or tab separators).

#### Common causes

This can be caused by generating a CSV or TSV file incorrectly, giving different rows a different number of cells.

### What should I do?

Correct the file on your machine. If possible, check and correct the code used to generate your data files. Remove the version of the file with alerts from the upload screen, and re-upload the corrected version.
