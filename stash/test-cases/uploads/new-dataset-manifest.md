# New dataset with URL manifest

1. log in
1. select **My Datasets**
1. select **Start New Dataset**
1. enter minimal necessary metadata for submission (title, creator, etc.)
1. select **Upload Files**
1. select **Enter URLs of file locations**
   - ✓ check that the **Validate files** button is disabled
1. enter the following (good) URLs:
   - http://web.mit.edu/ajb/www/tdwarf/tdwarf_data.txt
   - http://mypage.siu.edu/lhartman/phono/source.txt
   - http://user.engineering.uiowa.edu/~xwu3/epsii/Lecture20/source.txt
1. enter the following (bad) URLs:
   - http://httpstat.us/403
   - http://httpstat.us/404
   - http://httpstat.us/418
   - http://httpstat.us/500
   - http://httpstat.us/522
   - http://httpstat.us/524
1. tick the **I confirm…** check box
   - ✓ check that the **Validate files** button is enabled
1. click **Validate files**
   - ✓ check that the URLs all disappear from the **Enter Files** box
   - ✓ check that the bad URLs all appear in the **Validation Status** table
   - ✓ check that the good URLs appear in the **Uploaded Files** table, as follows:

       | Filename | URL | Size | Version | Actions |
       | -------- | --- | ---- | ------- | ------- |
       | source.txt | http://mypage.siu.edu/lhartman/phono/source.txt | 708.25 kB | 1 | <u>Delete</u> |
       | source-2.txt | http://user.engineering.uiowa.edu/~xwu3/epsii/Lecture20/source.txt | 357 B | 1 | <u>Delete</u> |
       | tdwarf_data.txt | http://web.mit.edu/ajb/www/tdwarf/tdwarf_data.txt | 12.14 kB | 1 | <u>Delete</u> |

   - ✓ check that the second `source.txt` has been renamed to `source-2.txt`, as above
   - ✓ check that the total size is correct
1. click **Proceed to Review** or **Review and Submit**
   - ✓ check that only the good files appear under **Review Data Files**
     - *(Q: Should we show the bad files as errors that need to be corrected? —DM)*
1. click **Upload Files** to return to the upload page
   - ✓ check that the **Enter Files** box and **Validation Status** are empty
     - *(Note: Not sure this behavior is good; should we still show old/bad URLs? —DM)*
1. Reenter the bad URLs above and click **Validate files** again
1. on the first bad URL in the **Validation Status** table, click **Edit**
   - ✓ check that the URL disappears from the table
   - ✓ check that the URL reappears in the **Enter Files** box
1. on the other bad URLs in the **Validation Status** table, click **Delete**
   - ✓ check that each URL disappears from the table
1. click **Proceed to Review** or **Review and Submit**
1. tick the **By checking this box, I agree...** (CC-BY) box
1. click **Submit**
1. wait for the dataset’s status to apepar as **published**
1. on the dataset landing page:
   - ✓ check that the files appear, with the correct sizes, under **Data Files**
   - click **Download the dataset**
     - ✓ check that the files appear, with the correct sizes, in the downloaded ZIP file
